--!strict
--!optimize 2
--!native

--[[
    ALLURE: TYPESAFE DI & IoC NODE & WORKER FRAMEWORK and CORE OF ALLURE ECOSYSTEM
    By r-iva9
	1.1.0
	Open source (MIT)
	https://github.com/r-iva9/Allure
]]

------------
-- CONFIG

local CONFIG = {
	-- Warn or error upon finding an unusual type in the usage of nodes
	WarnUnusualNodeTypes = true,

	-- Warn or error upon finding an unusual type when using workers
	WarnWorkerTypes = true,

	-- Warn upon detecting unusual behavior, like slicing an empty tree or injecting a non-node dependency
	-- Technically this is the debug mode
	WarnBehavioralErrors = true,

	-- Default yieldthreshold in seconds for `tree:ForEach` calls
	DEFAULT_YIELD_THRESHOLD = 120,
}

------------
-- TYPES

--- Utility type to fill the luau table type blank
type table = { [any]: any }

--[=[
    Custom Worker object.
	<br>Encapsulates a thread (coroutine) and a queue for task consumption
]=]
export type Worker = {
	--- Returns a function identical to `fn` but with a wrapper that enqueues it
	Function: <A..., R...>(self: Worker, fn: (A...) -> R...) -> (A...) -> (),

	--- Safely enqueue a function
	Enqueue: <A..., R...>(self: Worker, fn: (A...) -> R..., A...) -> Worker,

	--- Dequeues and returns the task under `index` in the Queue, or the last task, if not specified
	Dequeue: <A..., R...>(self: Worker, index: number?) -> (A...) -> R...,

	--- Task (function) queue for coroutine consumption
	Queue: { (...any?) -> ...any? },

	--- Array of functions, all of which are called once any item is __dequeued__
	--- <br>The functions are called on the consumer thread!
	QueueHook: { (...any?) -> ...any? },

	--- Yields the worker thread for `sec` seconds without throttling and sets a flag
	--- <br>Workers yielded via `task.wait` or `coroutine.yield` will consume next tasks immediately
	Yield: (self: Worker, sec: number) -> number,

	--- The underlying coroutine thread of this Worker
	Coroutine: thread,

	--- Closes the coroutine, destroys the queue and Worker
	Kill: (self: Worker) -> (),
}

--[=[
    Node: a singleton merged with utility.
    <br>Generally the type for Nodes is T & Node
]=]
export type Node<T = table> = T & {
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

	--- Calls a function for each node of the tree **in parallel**
	--- <br>If `errhandler` is specified, then all functions are called in safe mode via `xpcall`
	--- <br>If `yieldthreshold`is specified, then the thread, that the function is called in, will be closed if it runs longer than `yieldthreshold` seconds.
	--- In this case, Allure will yield a respective error, however if `errhandler` is specified, then it's called with `Err = true`
	ForEachParallel: (
		self: NodeTree,
		fn: (self: NodeTree, Node: Node) -> ...any?,
		errhandler: nil | <E>(self: NodeTree, Node: Node, Err: E) -> ...any?,
		yieldthreshold: number?
	) -> NodeTree,

	--- Calls a function for each node of the tree
	--- <br>If `errhandler` is specified, then all functions are called in safe mode via `xpcall`
	--- <br>If `yieldthreshold`is specified, then the thread, that the function is called in, will be closed if it runs longer than `yieldthreshold` seconds.
	--- In this case, Allure will yield a respective error, however if `errhandler` is specified, then it's called with `Err = true`
	ForEach: (
		self: NodeTree,
		fn: (self: NodeTree, Node: Node) -> ...any?,
		errhandler: nil | <E>(self: NodeTree, Node: Node, Err: E) -> ...any?,
		yieldthreshold: number?
	) -> NodeTree,

	--- Calls a function for all tree nodes
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

	--- Returns the first `Node` that matches the `predicate` (the function returns true) or `nil`, if none
	NodeFromPredicate: (self: NodeTree, predicate: (self: NodeTree, Node: Node) -> boolean) -> Node?,

	--- Returns a new NodeTree with identical Tree structure
	Clone: (self: NodeTree) -> NodeTree,

	---// Loaders //

	--- Loads the specified `node`
	--- <br>**Warning:** The node will not have `Instance` tag set and thus can yield several errors in multiple other NodeTree methods.
	LoadNode: (self: NodeTree, node: Node) -> NodeTree,

	--- Loads nodes listed in the array
	--- <br>**Warning:** The nodes will not have `Instance` tag set and thus can yield several errors in multiple other NodeTree methods.
	LoadNodes: (self: NodeTree, nodes: { table & Node }) -> NodeTree,

	--- Loads children nodes of an instance into the tree
	LoadChildren: (self: NodeTree, instance: Instance) -> NodeTree,

	--- Loads all descendant nodes of an instance into the tree
	LoadDescendants: (self: NodeTree, instance: Instance) -> NodeTree,

	--- Loads such descendant nodes of an instance, that satisfy the `predicate` (the function returns `true`)
	--- <br>**Notice** that the `predicate` is called with ***Instance***
	LoadDescendantsPredicate: (
		self: NodeTree,
		instance: Instance,
		predicate: (self: NodeTree, Instance: Instance) -> boolean
	) -> NodeTree,

	--- Loads nodes from a different tree
	LoadFromTree: (self: NodeTree, tree: NodeTree) -> NodeTree,

	--- Unloads nodes present in a different tree
	UnloadFromTree: (self: NodeTree, tree: NodeTree) -> NodeTree,

	---// Slicers //

	--- **Changes** the dependency tree by slicing the existing tree nodes having which the function returns false
	SlicePredicate: (self: NodeTree, predicate: (self: NodeTree, Node: Node) -> boolean) -> NodeTree,

	--- **Changes** the dependency tree by slicing the specified node
	SliceNode: (self: NodeTree, Node: Node) -> NodeTree,

	--- **Changes** the dependency tree by slicing node descendants of a specific instance
	SliceFromChild: (self: NodeTree, child: Instance) -> NodeTree,

	--- **Changes** the dependency tree by slicing the existing tree nodes with a specific tag *present* and/or with a *specific type* and/or with a *specific value*
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
local function lowmerge<T, V>(t0: T, t1: V): T & V
	for k, v in t1 :: table do
		(t0 :: any)[k] = v
	end
	return t0
end

--- Counts all dependencies and nested dependencies
local function depcount(dependencies: { any }): number
	local amount = #dependencies
	for _, dep in dependencies do
		amount += dep.Dependencies and depcount(dep.Dependencies) or 0
	end
	return amount
end

--- Returns a typesafe reference to `t`
local function ref<T>(t: T): any
	return t :: any
end

--- Returns a coroutine that calls `callback` in `sec` seconds
local function delayCallback<A..., R...>(sec: number, callback: (A...) -> R..., ...: A...)
	local co = coroutine.create(function(...: A...)
		task.wait(sec)
		callback(...)
	end)
	coroutine.resume(co, ...)
	return co
end

--- Yields the thread till one coroutine out of the provided varargs closes
local function delayTillClosure(...: thread)
	local cos = { ... }
	while task.wait() do
		for _, co in cos do
			if coroutine.status(co) ~= "dead" then
				continue
			end
			return
		end
	end
end

--- Closes unclosed coroutines
local function closeUnclosed(...: thread)
	for _, co in { ... } do
		if coroutine.status(co) ~= "dead" then
			coroutine.close(co)
		end
	end
end

--- Logging
local LogTemplates = {
	BadType = "%s passed to %s has an unusual type: %s (%s expected)",
	WeirdCallBack = "Unusual type of callback (%s) was passed to %s (%s expected)",
	Suppress = "\nIf this is intended, you can suppress this warning via the config.",
}
local Log = {
	Warn = function(...)
		local stack = debug.traceback("\n\n -------\t Stack Traceback \t-------", 2)
		warn(... .. if stack then stack else "")
	end,
	WarnAssert = function(config: boolean, condition: boolean, ...)
		if condition or not config then
			return
		end
		local stack = debug.traceback("\n\n -------\t Stack Traceback \t-------", 2)
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
	@return `UnfinishedNode<T, V>`      &emsp; = &emsp; *A Node with utilities given*

	@return `-> Node & T`      &emsp; = &emsp; *The finished Node*
]=]
function Allure:Node<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S>(
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

	for i, n: Node in Nodes do
		Log.ErrorAssert(
			CONFIG.WarnUnusualNodeTypes,
			typeof(n) == "table",
			Log.Format(
				"BadType",
				tostring(i) .. (i == 1 and "st" or (i == 2 and "nd" or (i == 3 and "rd" or "th"))) .. " dependency",
				"Allure:Node(HERE)()()",
				typeof(n),
				"table"
			)
		)
		Log.WarnAssert(
			CONFIG.WarnBehavioralErrors,
			(ref(n) and ref(n).Dependencies and ref(n).Tags),
			"Unusual type of the "
				.. tostring(i)
				.. (i == 1 and "st" or (i == 2 and "nd" or (i == 3 and "rd" or "th")))
				.. " dependency singleton passed to Allure:Node(HERE)()(): The singleton is not a Node. Use Allure:Node() on the singleton."
				.. LogTemplates.Suppress
		)
	end

	return function<T>(content: T)
		Log.ErrorAssert(
			CONFIG.WarnUnusualNodeTypes,
			typeof(content) == "table",
			Log.Format("BadType", "Content", "Allure:Node()(HERE)()", typeof(content), "table")
		)
		Log.WarnAssert(
			CONFIG.WarnBehavioralErrors,
			not ref(content).Tags and not ref(content).Dependencies,
			"Content passed to Allure:Node()(HERE)() has a 'Dependencies' key and/or 'Tags' key. This will conflict with standard functionality and will be overriden."
				.. LogTemplates.Suppress
		);

		(content :: any).__index = content --for classes, this remains the table unsealed

		return function<V>(meta: V)
			(content :: any).___meta = meta :: any --this remains the table unsealed

			Log.ErrorAssert(
				CONFIG.WarnUnusualNodeTypes,
				typeof(meta) == "table",
				Log.Format("BadType", "Metadata", "Allure:Node()()(HERE)", typeof(meta), "table")
			)

			local metatable = nil :: never
			local hiddenmeta = {
				Dependencies = Nodes :: { Node },
				Tags = {
					Priority = depcount(ref(meta).Dependencies or Nodes), --counts nested dependencies
				},
			}

			setmetatable(meta, {
				__index = hiddenmeta,
			})

			local Node = nil :: never
			Node = setmetatable(content, {
				__Noderef = content :: T,
				__Nodemeta = meta :: V,
				__call = function()
					return lowmerge(
						lowmerge(
							setmetatable(content, metatable) :: T, --1. reference singleton
							hiddenmeta :: never --2. default (hidden) meta
						),
						setmetatable(meta, nil) :: V --3. given meta
					)
				end,
				__index = setmetatable({
					UseDependency = function<S, M>(self: S, singleton: M): M
						Log.WarnAssert(
							CONFIG.WarnUnusualNodeTypes,
							typeof(singleton) == "table",
							Log.Format("BadType", "singleton", "Node:UseDependency(HERE)", typeof(singleton), "table")
								.. LogTemplates.Suppress
						)
						Log.ErrorAssert(
							true,
							meta and ref(meta).Dependencies and typeof(ref(meta).Dependencies) == "table",
							"Node:UseDependency() failed to use node meta and meta.Dependencies. This is most likely because meta and/or Dependencies have been modified. If not, make sure to create an issue on github."
						)
						ref(meta).Dependencies[#ref(meta).Dependencies + 1] = singleton
						return singleton
					end,
					UseTree = function<S>(self: S)
						local tree = Allure:NodeTree():LoadNodes(hiddenmeta.Dependencies)

						hiddenmeta.Dependencies = tree.Tree
						metatable.__index.UseDependency = function<S, M>(self: S, singleton: M): M
							Log.WarnAssert(
								CONFIG.WarnUnusualNodeTypes,
								typeof(singleton) == "table",
								Log.Format(
									"BadType",
									"singleton",
									"Node:UseDependency(HERE)",
									typeof(singleton),
									"table"
								) .. LogTemplates.Suppress
							)
							Log.ErrorAssert(
								true,
								meta and ref(meta).Dependencies and typeof(ref(meta).Dependencies) == "table",
								"Node:UseDependency() failed to use node meta and meta.Dependencies. This is most likely because meta and/or Dependencies have been modified and is not related to Node:UseTree(). If not, make sure to create an issue on github."
							)

							tree:LoadNode(singleton)
							return singleton
						end
						metatable.__index.UseTree = function<S>(self: S): any
							Log.WarnAssert(
								CONFIG.WarnBehavioralErrors,
								false,
								"Attempt to use Node:UseTree twice. If you want to use 2 NodeTrees as node dependencies, merge them."
									.. LogTemplates.Suppress
							)
							return tree
						end

						return tree
					end,
					OverrideMetatable = function<M>(self, mt: M)
						Log.ErrorAssert(
							CONFIG.WarnUnusualNodeTypes,
							typeof(mt) == "table",
							Log.Format("BadType", "mt", "Node:OverrideMetatable(HERE)", typeof(mt), "table")
						)
						lowmerge(metatable, mt)
					end,
					UseMetatable = function<M>(self, mt: M)
						Log.ErrorAssert(
							CONFIG.WarnUnusualNodeTypes,
							typeof(mt) == "table",
							Log.Format("BadType", "mt", "Node:UseMetatable(HERE)", typeof(mt), "table")
						)
						metatable = mt
					end,
					GetMetatable = function<M>(...)
						return metatable
					end,
					Tag = function<S, T, V>(self: S, tag: T, value: V)
						hiddenmeta.Tags[tag] = value
					end,
					GetTag = function<S, T, V>(self: S, tag: T)
						return hiddenmeta.Tags[tag]
					end,
					Meta = meta :: V,
					HiddenMeta = hiddenmeta,
				}, { __index = meta }), --third layer __index to reference metadata
			})
			metatable = getmetatable(Node)

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

--[[
	Creates `amount` amount of Workers: custom objects that encapsulate a coroutine and a queue of functions for task consumption.
]]
function Allure:Workers(amount: number): ...Worker
	Log.ErrorAssert(
		true,
		typeof(amount) == "number",
		Log.Format("BadType", "amount", "Allure:Workers(HERE)", typeof(amount), "number")
	)
	local threads: { Worker } = {}
	for i = 1, amount do
		-- create coroutine
		local Lifecycle = true
		local YieldFlag = false

		--coroutine 1: consumer
		local thread = coroutine.create(function(self: Worker)
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
			Function = function<A..., R...>(self: Worker, fn: (A...) -> R...): (A...) -> ()
				Log.ErrorAssert(
					CONFIG.WarnWorkerTypes,
					typeof(fn) == "function",
					Log.Format("WeirdCallBack", typeof(fn), "Worker:Function(HERE)", "function")
				)
				return function(...: A...)
					self:Enqueue(fn, ...)
				end
			end,
			Enqueue = function<A..., R...>(self: Worker, fn: (A...) -> R..., ...: A...)
				Log.ErrorAssert(
					CONFIG.WarnWorkerTypes,
					typeof(fn) == "function",
					Log.Format("WeirdCallBack", typeof(fn), "Worker:Enqueue(HERE)", "function")
				)

				local pack = { ... }
				table.insert(self.Queue :: table, function()
					ref(fn)(unpack(pack))
				end)

				if coroutine.status(thread) == "suspended" and not YieldFlag then
					coroutine.resume(thread, self)
				end

				return self
			end,
			Dequeue = function<A..., R...>(self: Worker, index: number?): (A...) -> R...
				if #self.Queue == 0 then
					return nil :: any --edge case
				end
				local item = self.Queue[index or #self.Queue]
				table.remove(self.Queue, index or #self.Queue)
				return item :: (...any) -> ...any
			end,

			Queue = {},
			QueueHook = {},

			Yield = function(self: Worker, sec: number)
				Log.ErrorAssert(
					CONFIG.WarnWorkerTypes,
					typeof(sec) == "number",
					Log.Format("WeirdCallBack", typeof(sec), "Worker:Yield(HERE)", "number")
				)
				Log.WarnAssert(
					CONFIG.WarnBehavioralErrors,
					sec > 0 and sec < 1e+4,
					"Attempt to yield a worker for " .. sec .. " seconds." .. LogTemplates.Suppress
				)
				YieldFlag = true
				local t = task.wait(sec)
				YieldFlag = false
				return t
			end,

			Coroutine = thread,
			Kill = function(self: Worker)
				Lifecycle = false
				coroutine.close(self.Coroutine)
				table.clear(self)
				self = nil :: never
			end,
		}

		coroutine.resume(thread, threads[i])
	end

	return table.unpack(threads)
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

		ForEachParallel = function(
			self: NodeTree,
			fn: (self: NodeTree, node: Node) -> ...any?,
			errhandler: nil | <E>(self: NodeTree, Node: Node, Err: E) -> ...any?,
			yieldthreshold: number?
		)
			Log.WarnAssert(
				CONFIG.WarnBehavioralErrors,
				#self.Tree ~= 0,
				"NodeTree:ForEachParallel() was used on an empty tree." .. LogTemplates.Suppress
			)

			--main and threshold coroutines close themselves
			if errhandler then
				for number, node in self.Tree do
					local main, threshold = nil :: never, nil :: never

					main = delayCallback(0, xpcall, function(...)
						fn(self, node)
						coroutine.close(threshold)
					end, function(...)
						coroutine.close(threshold)
						errhandler(self, node, ...)
					end)

					threshold = delayCallback(yieldthreshold or CONFIG.DEFAULT_YIELD_THRESHOLD, function(...)
						coroutine.close(main)
						errhandler(...)
					end, self, node, true :: any)
				end

				return self
			end

			for number, node in self.Tree do
				local main, threshold = nil :: never, nil :: never

				main = delayCallback(0, function(...)
					fn(...)
					coroutine.close(threshold)
				end, self, node)

				threshold = delayCallback(yieldthreshold or CONFIG.DEFAULT_YIELD_THRESHOLD, function()
					coroutine.close(main)
					Log.Error("Yield Threshold has passed in Tree:ForEach() for Node", node)
				end)
			end
			return self
		end,

		ForEach = function(
			self: NodeTree,
			fn: (self: NodeTree, node: Node) -> ...any?,
			errhandler: nil | <E>(self: NodeTree, Node: Node, Err: E) -> ...any?,
			yieldthreshold: number?
		)
			Log.WarnAssert(
				CONFIG.WarnBehavioralErrors,
				#self.Tree ~= 0,
				"NodeTree:ForEach() was used on an empty tree." .. LogTemplates.Suppress
			)
			if errhandler then
				for number, node in self.Tree do
					--fn(self, node)
					local main = task.spawn(xpcall, function(...)
						fn(self, node)
					end, function(...)
						errhandler(self, node, ...)
					end)

					local threshold = delayCallback(
						yieldthreshold or CONFIG.DEFAULT_YIELD_THRESHOLD,
						errhandler,
						self,
						node,
						true :: any
					)
					delayTillClosure(main, threshold)
					closeUnclosed(main, threshold)
				end

				return self
			end

			for number, node in self.Tree do
				--fn(self, node)
				local main = task.spawn(fn, self, node)
				local threshold = delayCallback(
					yieldthreshold or CONFIG.DEFAULT_YIELD_THRESHOLD,
					Log.Error,
					"Yield Threshold has passed in Tree:ForEach() for Node",
					node
				)
				delayTillClosure(main, threshold)
				closeUnclosed(main, threshold)
			end
			return self
		end,

		ForAll = function(self: NodeTree, fn: (self: NodeTree, nodes: { Node }) -> ...any?)
			fn(self, self.Tree)
			return self
		end,

		ForEachTagged = function(self: NodeTree, tag: any, fn: (self: NodeTree, node: Node) -> ...any?)
			Log.WarnAssert(
				CONFIG.WarnBehavioralErrors,
				#self.Tree ~= 0,
				"NodeTree:ForEachTagged() was used on an empty tree." .. LogTemplates.Suppress
			)
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
			Log.WarnAssert(
				CONFIG.WarnBehavioralErrors,
				#self.Tree ~= 0,
				"NodeTree:Sort() was used on an empty tree." .. LogTemplates.Suppress
			)
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

		NodeFromPredicate = function(self: NodeTree, predicate: (self: NodeTree, node: Node) -> boolean): Node?
			for _, node in self.Tree do
				if predicate(self, node) then
					return node
				end
			end
			return nil
		end,

		NodeFromInstance = function(self: NodeTree, instance: Instance)
			Log.WarnAssert(
				CONFIG.WarnBehavioralErrors,
				instance:IsA "ModuleScript",
				"NodeTree:NodeFromInstance() received a non-modulescript instance ("
					.. typeof(instance)
					.. ")"
					.. LogTemplates.Suppress
			)
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

		--// Loaders

		LoadNode = function(self: NodeTree, node: Node)
			if not table.find(self.Tree, node) then
				node.Tags.Instance = nil
				table.insert(self.Tree, node)
			end
			return self
		end,

		LoadNodes = function(self: NodeTree, nodes: { Node })
			for _, node in nodes do
				if not table.find(self.Tree, node) then
					node.Tags.Instance = nil
					table.insert(self.Tree, node)
				end
			end
			return self
		end,

		LoadChildren = function(self: NodeTree, instance: Instance)
			Log.WarnAssert(
				CONFIG.WarnBehavioralErrors,
				#instance:GetChildren() ~= 0,
				"NodeTree:LoadChildren() received an instance with zero children." .. LogTemplates.Suppress
			)
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
			Log.WarnAssert(
				CONFIG.WarnBehavioralErrors,
				#instance:GetDescendants() ~= 0,
				"NodeTree:LoadDescendants() received an instance with zero descendants." .. LogTemplates.Suppress
			)
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

		LoadDescendantsPredicate = function(
			self: NodeTree,
			instance: Instance,
			predicate: (self: NodeTree, Instance: Instance) -> boolean
		): NodeTree
			Log.WarnAssert(
				CONFIG.WarnBehavioralErrors,
				#instance:GetDescendants() ~= 0,
				"NodeTree:LoadDescendantsPredicate() received an instance with zero descendants."
					.. LogTemplates.Suppress
			)
			for i, inst in instance:GetDescendants() do
				if inst:IsA "ModuleScript" and predicate(self, inst) then
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
			Log.WarnAssert(
				CONFIG.WarnBehavioralErrors,
				#tree.Tree ~= 0,
				"NodeTree:UnloadFromTree() received an empty tree." .. LogTemplates.Suppress
			)
			for i, node in tree.Tree do
				if not table.find(self.Tree, node) then
					table.insert(self.Tree, node)
				end
			end
			return self
		end,

		UnloadFromTree = function(self: NodeTree, tree: NodeTree)
			Log.WarnAssert(
				CONFIG.WarnBehavioralErrors,
				#tree.Tree ~= 0,
				"NodeTree:UnloadFromTree() received an empty tree." .. LogTemplates.Suppress
			)
			Log.WarnAssert(
				CONFIG.WarnBehavioralErrors,
				#self.Tree ~= 0,
				"NodeTree:UnloadFromTree() was used on an empty tree." .. LogTemplates.Suppress
			)
			for i, node in tree.Tree do
				local index = table.find(self.Tree, node)
				if index then
					table.remove(self.Tree, index)
				end
			end
			return self
		end,

		--// Slicers

		SliceNode = function(self: NodeTree, node: Node)
			Log.WarnAssert(
				CONFIG.WarnBehavioralErrors,
				#self.Tree ~= 0,
				"NodeTree:SliceNode() was used on an empty tree." .. LogTemplates.Suppress
			)
			table.remove(self.Tree, table.find(self.Tree, node))
			return self
		end,

		SlicePredicate = function(self: NodeTree, predicate: (self: NodeTree, node: Node) -> boolean)
			Log.WarnAssert(
				CONFIG.WarnBehavioralErrors,
				#self.Tree ~= 0,
				"NodeTree:SlicePredicate() was used on an empty tree." .. LogTemplates.Suppress
			)
			local memo = {}

			for i, node in self.Tree do
				if predicate(self, node) then
					table.insert(memo, node)
				end
			end

			self.Tree = memo

			return self
		end,

		SliceTagged = function(self: NodeTree, tag: any, type: string?, value: any?)
			Log.WarnAssert(
				CONFIG.WarnBehavioralErrors,
				#self.Tree ~= 0,
				"NodeTree:SliceTagged() was used on an empty tree." .. LogTemplates.Suppress
			)
			local memo = {}

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
				table.insert(memo, node)
			end
			self.Tree = memo

			return self
		end,

		SliceFromChild = function(self: NodeTree, child: Instance)
			Log.WarnAssert(
				CONFIG.WarnBehavioralErrors,
				#self.Tree ~= 0,
				"NodeTree:SliceFromChild() was used on an empty tree." .. LogTemplates.Suppress
			)
			local memo = {}

			for i, node in self.Tree do
				if node.Tags.Instance and not node.Tags.Instance:IsDescendantOf(child) then
					table.insert(memo, node)
				end
			end
			self.Tree = memo

			return self
		end,
	}

	return NodeTree
end

-- Allure is created via allure
return Allure:Node(nil)(Allure) {
	Name = "Allure",
	Version = "1.1.0",
	Description = "Typesafe (Container DI & IoC) Node & Worker Framework at the core of Allure Ecosystem",
	Author = "r_iva9",
	License = "MIT",
}()
