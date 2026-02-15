--!strict
--!optimize 2
--!native

--[[
    ALLURE: NODE WORKER FRAMEWORK
    By r_iva9
	Open source (MIT)
]]

------------
-- CONFIG

local CONFIG = {
	-- Warn upon finding an unusual type during creation of nodes
	WarnUnusualNodeTypes = true,
}

------------
-- TYPES

--- Utility type to fill the luau table type blank
type table = { [any]: any }

--[=[
    Custom thread object for Worker Nodes.
	<br>Encapsulates a thread and a queue for task consumption
]=]
export type Thread = {
	--- Returns a function identical to `fn` but with a wrapper that enqueues it
	Function: <A..., R...>(self: Thread, fn: (A...) -> R...) -> (A...) -> (),

	--- Safely enqueue a function
	Enqueue: <A..., R...>(self: Thread, fn: (A...) -> R...) -> Thread,

	--- Task (function) queue for coroutine consumption
	Queue: { (...any?) -> ...any? },

	--- Array of functions, all of which are called once any item is __dequeued__
	--- <br>The functions are called on the consumer thread!
	QueueHook: { (...any?) -> ...any? },

	--- Yields the thread for `sec` seconds without throttling and sets a flag
	--- <br>Threads yielded via `task.wait` or `coroutine.yield` will consume next tasks immediately
	Yield: (self: Thread, sec: number) -> number,

	--- The underlying coroutine thread of this Thread
	Coroutine: thread,

	--- Closes the coroutine, destroys the queue and Thread
	Kill: (self: Thread) -> (),
}

--[=[
    This is the type of Node workspaces.
	<br>However as the tables have to remain unsealed this is not used and can only assist in custom type checking.
]=]
export type NodeWorkspace<T, V> = setmetatable<
	T,
	{ --T & {__index: T}, {
		__Noderef: T,
		__Nodemeta: V,
		__index: setmetatable<{
			UseDependency: <S, M>(self: S, singleton: M) -> M,
			SetPriority: <S>(self: S, priority: number) -> S,
			ModifyMeta: <S>(self: S, override: table) -> S,
			Meta: V,
			Threads: <S>(self: S, amount: number) -> ...Thread,
			GetDependencyCount: <S>(self: S) -> number,
			Zero: () -> Node,
		}, { __index: V }>,
	}
>

--[=[
    Node: a singleton merged with utility.
    <br>Generally the type for Nodes is T & Node
]=]
export type Node = {
	read Name: string,
	read Version: string,
	read Description: string,
	read Author: string,
	read License: string,

	read Dependencies: { unknown },

	--- Mutable tags of the Node
	Tags: {
		[any]: any,
	},
}

--[=[
    NodeTree: A tree of loaded nodes with branches of dependencies
	<br>Allows to tag nodes, slice and divide trees, sort nodes, call functions for nodes, etc.
]=]
export type NodeTree = {
	Tree: { Node },

	---// Basic Methods //

	--- Calls a function for each node of the tree.
	--- <br>If `errhandler` is specified, then all functions are called in safe mode via `xpcall`
	ForEach: (
		self: NodeTree,
		fn: (self: NodeTree, Node: Node) -> ...any?,
		errhandler: nil | <E>(self: NodeTree, Node: Node, Err: E) -> ...any?
	) -> NodeTree,

	--- Calls a function for all tree nodes.
	ForAll: (self: NodeTree, fn: (self: NodeTree, Nodes: { Node }) -> ...any?) -> NodeTree,

	--- Calls a function for each tree node with a specific tag
	ForEachTagged: (self: NodeTree, tag: any, fn: (self: NodeTree, Node: Node) -> ...any?) -> NodeTree,

	--- Calls a function for all tree nodes with a specific tag
	ForAllTagged: (self: NodeTree, tag: any, fn: (self: NodeTree, Nodes: { Node }) -> ...any?) -> NodeTree,

	--- Sorts surface level nodes
	--- <br>Via *minimum --> maximum* algorithm of the `fn()` returns
	Sort: (self: NodeTree, fn: (self: NodeTree, node: Node, shared: table) -> number) -> NodeTree,

	--- Returns a `Node` within the tree from it's instance
	--- <br>Returns `nil` if such a Node is not within the tree
	NodeFromInstance: (self: NodeTree, instance: Instance) -> Node?,

	--- Returns a new NodeTree with identical Tree structure
	Clone: (self: NodeTree) -> NodeTree,

	---// Loader Methods //

	--- Loads children nodes of an instance into the tree
	LoadChildren: (self: NodeTree, instance: Instance) -> NodeTree,

	--- Loads all descendant nodes of an instance into the tree
	LoadDescendants: (self: NodeTree, instance: Instance) -> NodeTree,

	--- Loads nodes from a different tree
	LoadFromTree: (self: NodeTree, tree: NodeTree) -> NodeTree,

	--- Unloads nodes present in a different tree
	UnloadFromTree: (self: NodeTree, tree: NodeTree) -> NodeTree,

	---// Slicing //

	--- Creates a **new** dependency tree by slicing the existing tree nodes having which the function returns false
	SlicePredicate: (self: NodeTree, predicate: (self: NodeTree, Node: Node) -> boolean) -> NodeTree,

	--- Creates a **new** dependency tree by slicing the specified node
	SliceNode: (self: NodeTree, Node: Node) -> NodeTree,

	--- Creates a **new** dependency tree by slicing node descendants of a specific instance
	SliceFromChild: (self: NodeTree, child: Instance) -> NodeTree,

	--- Creates a **new** dependency tree by slicing the existing tree nodes with a specific tag *present* and/or with a *specific type* and/or with a *specific value*
	SliceTagged: (self: NodeTree, tag: any, valueType: string?, value: any?) -> NodeTree,
}

---//    CONTENT

------------
-- UTILITY

--[[
	Utility table merger.
	<br>Takes 2 tables, modifies and returns the first one

	Does not perform cloning or deepcloning
	<br>This becomes suitable for dependencies hence the singletons
]]
function lowmerge<T, V>(t0: T, t1: V): T & V
	for k, v in t1 :: table do
		(t0 :: any)[k] = v
	end
	return t0
end

--- Counts all dependencies and nested dependencies
function depcount(dependencies: { any }): number
	local amount = #dependencies
	for _, dep in dependencies do
		amount += dep.Dependencies and depcount(dep.Dependencies) or 0
	end
	return amount
end

--- Logging
local LogTemplates = {
	BadType = "%s passed to %s has an unusual type: %s (%s expected)",
	Suppress = "\nIf this is intended, you can suppress this warning via the config.",
}
local Log = {
	Warn = function(...)
		local stack =
			debug.traceback("\n\n\t\t---------\t--------- \t\t\tStack Traceback\t\t\t ---------\t---------\t", 2)
		warn(... .. if stack then stack else "")
	end,
	WarnAssert = function(config: boolean, condition: boolean, ...)
		if condition or not config then
			return
		end
		local stack =
			debug.traceback("\n\n\t\t---------\t--------- \t\t\tStack Traceback\t\t\t ---------\t---------\t", 2)
		warn("[Allure] " .. ... .. if stack then stack else "")
	end,
	Error = function(...)
		error("[Allure] " .. ...)
	end,
	ErrorAssert = function(config: boolean, condition: boolean, ...)
		if not config then
			return
		end
		assert(condition, "[Allure] " .. ...)
	end,
	Format = function(key, ...)
		return string.format(LogTemplates[key] :: any, ...) :: string
	end,
}

------------
-- ALLURE

local Allure = {}

--- Counts all node dependencies and nested dependencies
function Allure:CountDependencies(node: Node)
	return depcount(node.Dependencies)
end

--[=[
    Creates a Node workspace for Node creation and modification.
    <br>This Node cannot be used in dependencies of other Nodes, has a utility metatable and mutable metadata.

    To create the node, call it as a function.

	---

	@param ... &emsp; `(tables)` &emsp; = &emsp; *1st function: dependency singletons (nodes)*
	@param -> content &emsp; `(table)` &emsp; = &emsp; *2nd function: the content table. It remains unsealed*
	@param -> -> meta &emsp; `(table)` &emsp; = &emsp; *3rd function: the initial metadata. It remains mutable*
	@return `NodeWorkspace<typeof(content), V>`      &emsp; = &emsp; *A workspace for Node creation with utilities*
]=]
function Allure:NodeWorkspace<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S>(
	A: A?,
	B: B?,
	C: C?,
	D: D?,
	E: E?,
	F: F?,
	G: G?,
	H: H?,
	I: I?,
	J: J?,
	K: K?,
	L: L?,
	M: M?,
	N: N?,
	O: O?,
	P: P?,
	Q: Q?,
	R: R?,
	S: S?
)
	local Nodes = { A, B, C, D, E, F, G, H, I, J, K, L, M, M, O, P, Q, R, S }

	return function<T>(content: T)
		Log.ErrorAssert(
			CONFIG.WarnUnusualNodeTypes,
			typeof(content) == "table",
			Log.Format("BadType", "Content", "Allure:NodeWorkspace()(HERE)()", typeof(content), "table")
		);

		(content :: any).__index = content --for classes, this remains the table unsealed

		return function<V>(meta: V & table)
			(content :: any).___meta = meta --this remains the table unsealed

			Log.ErrorAssert(
				CONFIG.WarnUnusualNodeTypes,
				typeof(meta) == "table",
				Log.Format("BadType", "Metadata", "Allure:NodeWorkspace()()(HERE)", typeof(meta), "table")
			)

			local Node = setmetatable(content, {
				__Noderef = content,
				__Nodemeta = lowmerge(meta, { --modifies meta
					Dependencies = Nodes,
				}) :: V,
				__call = function()
					return lowmerge(
						lowmerge(
							setmetatable(content, nil) :: T, --1. reference singleton
							{
								Name = "", --2. default metadata
								Version = "1.0.0",
								Description = "",
								Author = "",
								License = "",

								Dependencies = {},

								Tags = {
									Priority = -depcount(meta.Dependencies or {} :: table), --counts nested dependencies
								},
							} :: never
						),
						meta :: Node --3. given metadata
					)
				end,
				__index = setmetatable({
					UseDependency = function<S, M>(self: S, singleton: M): M
						meta.Dependencies[#meta.Dependencies + 1] = singleton
						return singleton
					end,
					SetPriority = function<S>(self: S, priority: number): S
						meta.Priority = priority
						return self
					end,
					ModifyMeta = function<S>(self: S, override: table): S
						lowmerge(meta, override)
						return self
					end,
					Meta = meta,
					GetDependencyCount = function<S>(self: S): number
						return depcount(meta.Dependencies)
					end,
					Threads = function<S>(self: S, amount: number): ...Thread
						local threads: { Thread } = {}
						for i = 1, amount do
							-- create coroutine
							local Lifecycle = true
							local YieldFlag = false

							--coroutine 1: consumer
							local thread = coroutine.create(function(self: Thread)
								while Lifecycle do
									if not self.Queue[1] then
										coroutine.yield()
									end

									self.Queue[1]()

									table.remove(self.Queue, 1)
									for _, fn in self.QueueHook do
										fn(self)
									end
								end
							end)

							--create Thread
							threads[i] = {
								Function = function<A..., R...>(self: Thread, fn: (A...) -> R...): (A...) -> ()
									return function(...)
										local pack = { ... }
										self:Enqueue(function()
											fn(table.unpack(pack))
										end)
									end
								end,
								Enqueue = function(self: Thread, fn: (...any?) -> ...any?)
									table.insert(self.Queue, fn)

									if coroutine.status(thread) == "suspended" and not YieldFlag then
										coroutine.resume(thread, self)
									end

									return self
								end,

								Queue = {},
								QueueHook = {},

								Yield = function(self: Thread, sec: number)
									YieldFlag = true
									local t = task.wait(sec)
									YieldFlag = false
									return t
								end,

								Coroutine = thread,
								Kill = function(self: Thread)
									Lifecycle = false
									coroutine.close(self.Coroutine)
									table.clear(self)
									self = nil :: never
								end,
							}

							coroutine.resume(thread, threads[i])
						end

						return table.unpack(threads)
					end,
					Zero = function()
						return lowmerge(
							lowmerge(
								setmetatable(content, nil), --1. reference singleton
								{ --2. default metadata
									Dependencies = {},

									Tags = {
										Priority = -depcount(meta.Dependencies or {} :: table), --counts nested dependencies
									},
								} :: never
							),
							meta :: Node --3. given metadata
						)
					end,
				}, { __index = meta }), --third layer __index to reference metadata
			})

			return Node,
				A :: A,
				B :: B,
				C :: C,
				D :: D,
				E :: E,
				F :: F,
				G :: G,
				H :: H,
				I :: I,
				J :: J,
				K :: K,
				L :: L,
				M :: M,
				N :: N,
				O :: O,
				P :: P,
				Q :: Q,
				R :: R,
				S :: S
		end
	end
end

--[=[
    Creates a Node.
	
	Nodes are modular architectural units with content and metadata.

	---

	@param ... &emsp; `(tables)` &emsp; = &emsp; *1st function: dependency tables via require()*
	@param -> content &emsp; `(table)` &emsp; = &emsp; *2nd function: the content table*
	@param -> -> meta &emsp; `(table)` &emsp; = &emsp; *3rd function: the metadata table*
	@return `Node & typeof(content)`      &emsp; = &emsp; *Node*
]=]
function Allure:Node<P...>(...: P...)
	local dependencies = { ... }

	return function<T>(content: T)
		Log.ErrorAssert(
			CONFIG.WarnUnusualNodeTypes,
			typeof(content) == "table",
			Log.Format("BadType", "Content", "Allure:Node()(HERE)()", typeof(content), "table")
		)

		return function<V>(meta: V & table)
			Log.ErrorAssert(
				CONFIG.WarnUnusualNodeTypes,
				typeof(meta) == "table",
				Log.Format("BadType", "Metadata", "Allure:Node()()(HERE)", typeof(meta), "table")
			)
			return lowmerge(
				lowmerge(
					content,
					{
						Name = "", --2. default metadata
						Version = "1.0.0",
						Description = "",
						Author = "",
						License = "",

						Dependencies = dependencies,

						Tags = {
							Priority = -depcount(dependencies), --counts nested dependencies
						},
					} :: Node
				),
				meta
			)
		end
	end
end

--[=[
    Creates a Node with the minimum required metadata overhead.
	
	Nodes are modular architectural units with content and metadata.

	---

	@param ... &emsp; `(tables)` &emsp; = &emsp; *1st function: dependency tables via require()*
	@param -> content &emsp; `(table)` &emsp; = &emsp; *2nd function: the content table*
	@param -> -> meta &emsp; `(table)` &emsp; = &emsp; *3rd function: the metadata table*
	@return `Node & typeof(content)`      &emsp; = &emsp; *Node*
]=]
function Allure:ZeroNode<P...>(...: P...)
	local dependencies = { ... }

	return function<T>(content: T)
		Log.ErrorAssert(
			CONFIG.WarnUnusualNodeTypes,
			typeof(content) == "table",
			Log.Format("BadType", "Content", "Allure:ZeroNode()(HERE)()", typeof(content), "table")
		)
		return function<V>(meta: V & table)
			Log.ErrorAssert(
				CONFIG.WarnUnusualNodeTypes,
				typeof(meta) == "table",
				Log.Format("BadType", "Metadata", "Allure:ZeroNode()()(HERE)", typeof(meta), "table")
			)
			return lowmerge(
				lowmerge(
					content,
					{
						Dependencies = dependencies,

						Tags = {
							Priority = -depcount(dependencies), --counts nested dependencies
						},
					} :: Node
				),
				meta
			)
		end
	end
end

--[[
    Creates a node dependency tree.<br>Loaded nodes are located on the surface level and branch via `Dependencies`

    ---

    @return NodeTree      &emsp; = &emsp; *The node tree*
]]
function Allure:NodeTree(): NodeTree
	local NodeTree: NodeTree

	NodeTree = {
		Tree = {},

		ForEach = function(
			self: NodeTree,
			fn: (self: NodeTree, node: Node) -> ...any?,
			errhandler: nil | <E>(self: NodeTree, Node: Node, Err: E) -> ...any?
		)
			if errhandler then
				for number, node in self.Tree do
					xpcall(function(...)
						fn(self, node)
					end, function(...)
						errhandler(self, node, ...)
					end)
				end
				return self
			end

			for number, node in self.Tree do
				fn(self, node)
			end
			return self
		end,

		ForAll = function(self: NodeTree, fn: (self: NodeTree, nodes: { Node }) -> ...any?)
			fn(self, self.Tree)
			return self
		end,

		ForEachTagged = function(self: NodeTree, tag: any, fn: (self: NodeTree, node: Node) -> ...any?)
			for number, node in self.Tree do
				if node.Tags[tag] then
					fn(self, node)
				end
			end
			return self
		end,

		ForAllTagged = function(self: NodeTree, tag: any, fn: (self: NodeTree, nodes: { Node }) -> ...any?)
			local tagged = {}
			for number, node in self.Tree do
				tagged[number] = node.Tags[tag] and node or nil
			end

			fn(self, tagged)
			return self
		end,

		Sort = function(self: NodeTree, fn: (self: NodeTree, node: Node, shared: table) -> number)
			local cache: { Node } = {}
			local sharedtable = {}

			for i, node in self.Tree do
				local val = fn(self, node, sharedtable)
				while cache[val] do --handling identical cases
					val += 1e-4
				end

				cache[val] = node
			end

			table.clear(self.Tree)
			for i, node in cache do
				--order of a = 1 + amount of numbers lower than a

				local order = 1
				for k, othernode in cache do
					order += k < i and 1 or 0
				end
				self.Tree[order] = node
			end

			return self
		end,

		NodeFromInstance = function(self: NodeTree, instance: Instance)
			for k, n in self.Tree do
				if n.Tags.Instance == instance then
					return n
				end
			end

			return nil
		end,

		Clone = function(self: NodeTree)
			return Allure:NodeTree():LoadFromTree(self)
		end,

		LoadChildren = function(self: NodeTree, instance: Instance)
			for i, inst in instance:GetChildren() do
				if inst:IsA "ModuleScript" then
					local node = require(inst) :: Node
					if not table.find(self.Tree, node) then
						node.Tags.Instance = inst
						table.insert(self.Tree, node)
					end
				end
			end

			return self
		end,

		LoadDescendants = function(self: NodeTree, instance: Instance)
			for i, inst in instance:GetDescendants() do
				if inst:IsA "ModuleScript" then
					local node = require(inst) :: Node
					if not table.find(self.Tree, node) then
						node.Tags.Instance = inst
						table.insert(self.Tree, node)
					end
				end
			end

			return self
		end,

		LoadFromTree = function(self: NodeTree, tree: NodeTree)
			for i, node in tree.Tree do
				if not table.find(self.Tree, node) then
					table.insert(self.Tree, node)
				end
			end
			return self
		end,

		UnloadFromTree = function(self: NodeTree, tree: NodeTree)
			for i, node in tree.Tree do
				local index = table.find(self.Tree, node)
				if index then
					table.remove(self.Tree, index)
				end
			end
			return self
		end,

		SliceNode = function(self: NodeTree, node: Node)
			local newTree = Allure:NodeTree():LoadFromTree(self)

			table.remove(newTree.Tree, table.find(newTree.Tree, node))

			return newTree
		end,

		SlicePredicate = function(self: NodeTree, predicate: (self: NodeTree, node: Node) -> boolean)
			local newTree = Allure:NodeTree()

			for i, node in self.Tree do
				if predicate(newTree, node) then
					table.insert(newTree.Tree, node)
				end
			end

			return newTree
		end,

		SliceTagged = function(self: NodeTree, tag: any, type: string?, value: any?)
			local newTree = Allure:NodeTree()

			for i, node in self.Tree do
				if not node.Tags[tag] then
					continue
				end
				if type and typeof(node.Tags[tag]) ~= type then
					continue
				end
				if value and node.Tags[tag] ~= value then
					continue
				end
				table.insert(newTree.Tree, node)
			end

			return newTree
		end,

		SliceFromChild = function(self: NodeTree, child: Instance)
			local newTree = Allure:NodeTree()

			for i, node in self.Tree do
				if node.Tags.Instance and not node.Tags.Instance:IsDescendantOf(child) then
					table.insert(newTree.Tree, node)
				end
			end

			return newTree
		end,
	}

	return NodeTree
end

-- Allure is created via allure
return Allure:Node()(Allure) {
	Name = "Allure",
	Version = "0.1.0",
	Description = "Node Worker Framework",
	Author = "r_iva9",
	License = "MIT",
}
