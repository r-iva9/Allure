--!strict
--!optimize 2
--!native

--[[
    ALLURE ACTOR METAFRAMEWORK
    By r_iva9

    API

    Types

    ...

    Functions

    ...
]]

------------
-- TYPES

--- Utility type to fill the luau table type blank
type table = { [any]: any }

--- Utility type fuction to merge 2 table types
type function Merge(a: type, b: type)
	if not b:is "table" then
		return a
	end

	local result = types.newtable()

	local indexer = b:indexer()
	if indexer ~= nil then
		result:setreadindexer(indexer.index, indexer.readresult)
		result:setwriteindexer(indexer.index, indexer.writeresult)
	end

	for key, prop in a:properties() do
		if prop.read ~= prop.write then
			result:setreadproperty(key, prop.read)
			result:setwriteproperty(key, prop.write)
		else
			result:setproperty(key, prop.read)
		end
	end

	for key, prop in b:properties() do
		if prop.read ~= prop.write then
			result:setreadproperty(key, prop.read)
			result:setwriteproperty(key, prop.write)
		else
			result:setproperty(key, prop.read)
		end
	end

	return result
end

--- Utility type function that lets type functions reference the table type
--- <br>Sort of a hack
type tabler<A> = table

--[=[
    This is the type of unregistered Nodes.
	<br>However as the tables have to remain unsealed this is not used and can only assist in custom type checking.

    Format: `UnregisteredNode<Content, Metadata>`
]=]
export type UnregisteredNode<T, V> = setmetatable<
	T,
	{ --T & {__index: T}, {
		__Noderef: T,
		__Nodemeta: V,
		__index: setmetatable<{
			UseDependency: <S, M>(self: S, singleton: M) -> M,
			SetPriority: <S>(self: S, priority: number) -> S,
			ModifyMeta: <S>(self: S, override: table) -> S,
			GetDependencyCount: <S>(self: S) -> number,
		}, { __index: V }>,
	}
>

--[=[
    Registered Node metadata.
    <br>Generally the type for registered Nodes is T & Node
]=]
export type Node = {
	read Name: string,
	read Version: string,
	read Description: string,
	read Author: string,
	read License: string,

	read Dependencies: { unknown },
	read Priority: number,

	--- Decides whether the client can require() the Node or have it as a dependency
	read Client: boolean,

	--- Mutable tags of the Node
	Tags: { [any]: any },

	--- Children Nodes
	Nodes: { [Instance]: Node },

	Instance: Instance,
}

--[=[
    The type of each and any dependency tree
	<br>Node tree nodes have the Node type
]=]
export type NodeTree = {
	Parent: Instance,
	Tree: { [Instance]: Node },

	---// Basic Methods //

	--- Returns all modulescript nodes in the tree without nests and folder nodes
	--- To apply basic tree methods use SliceNonmodules
	GetModuleNodes: (self: NodeTree) -> { [Instance]: Node },

	--- Returns all folder nodes in the tree
	--- To apply basic tree methods use SliceNonfolders
	GetFolderNodes: (self: NodeTree) -> { [Instance]: Node },

	--- Calls a function for each node of the tree.
	ForEach: (self: NodeTree, fn: (self: NodeTree, Node: Node) -> ...any?) -> NodeTree,

	--- Calls a function for all tree nodes.
	ForAll: (self: NodeTree, fn: (self: NodeTree, Nodes: { [Instance]: Node }) -> ...any?) -> NodeTree,

	--- Calls a function for each tree node with a specific tag
	ForEachTagged: (self: NodeTree, tag: any, fn: (self: NodeTree, Node: Node) -> ...any?) -> NodeTree,

	--- Calls a function for all tree nodes with a specific tag
	ForAllTagged: (
		self: NodeTree,
		tag: any,
		fn: (self: NodeTree, Nodes: { [Instance]: Node }) -> ...any?
	) -> NodeTree,

	--- Sorts surface level nodes by setting their indices to whatever the function on the node returns
	Sort: (self: NodeTree, fn: (node: Node, shared: table) -> number) -> NodeTree,

	---// Loader Methods //

	--- Loads children nodes into the tree
	LoadChildren: (self: NodeTree) -> NodeTree,

	--- Loads nodes from a different tree
	LoadFromTree: (self: NodeTree, tree: NodeTree) -> NodeTree,

	---// Merging //

	--- Merges 2 dependency trees.
	Merge: (self: NodeTree, merger: NodeTree) -> NodeTree,

	---// Slicing //

	--- Creates a **new** dependency tree by slicing the existing tree nodes having which the function returns false
	SlicePredicate: (self: NodeTree, predicate: (self: NodeTree, node: Node) -> boolean) -> NodeTree,

	--- Creates a **new** dependency tree with all of the modules at the surface level
	SliceNonModules: (self: NodeTree) -> NodeTree,

	--- Creates a **new** dependency tree with all of the folders at the surface level
	SliceNonFolders: (self: NodeTree) -> NodeTree,

	--- Creates a **new** dependency tree by slicing the specified node
	SliceNode: (self: NodeTree, node: Node) -> NodeTree,

	--- Creates a **new** dependency tree by slicing the existing tree nodes parented above a specific child
	SliceFromChild: (self: NodeTree, child: Instance) -> NodeTree,

	--- Creates a **new** dependency tree by slicing the existing tree nodes with a specific tag *present* and/or with a *specific type* and/or with a *specific value*
	SliceTagged: (self: NodeTree, tag: any, valueType: string?, value: any?) -> NodeTree,
}

---//
---//    CONTENT
---//

------------
-- UTILITY

--[[
    Utility table merger.
    <br>Takes 2 tables, modifies and returns the first one

    Does not perform cloning or deepcloning
    <br>This becomes suitable for dependencies hence the singletons
]]
function lowmerge<T, V>(t0: T, t1: V): T & V --Merge<T, V>
	for k, v in pairs(t1) do
		(t0 :: any)[k] = v
	end
	return t0
end

--- Counts all dependencies and nested dependencies within t0
function depcount<T>(dependencies: { any }): number
	local amount = #dependencies
	for _, dep in dependencies do
		amount += dep.Dependencies and depcount(dep.Dependencies) or 0
	end
	return amount
end

--- Logging
local Log = {
	Warn = function(...)
		local stack =
			debug.traceback("\n\n\t\t---------\t--------- \t\t\tStack Traceback\t\t\t ---------\t---------\t", 2)
		warn(... .. if stack then stack else "")
	end,
	Error = error,
}

------------
-- ALLURE

local RegisteredNodes: { [Instance]: Node } = {}

local Allure = {}

--[=[
    Creates a workspace for Node creation and modification.
    <br>Returns an unregistered Node that can be registered.

    This Node cannot be used in dependencies of other Nodes, has a utility metatable and mutable metadata.

    This is a triple function to segregate parameters and syntactic sugar.

	---

	@param ... &emsp; `(Nodes)` &emsp; = &emsp; *Dependency Nodes*
	@param -> content &emsp; `(table)` &emsp; = &emsp; *For the second function, pass the content table. This table remains unsealed*
	@param -> -> meta &emsp; `(table)` &emsp; = &emsp; *For the third function, pass the initial metadata. It is mutable before registration*
	@return `UnregisteredNode<typeof(content), V>`      &emsp; = &emsp; *Unregistered Node: a workspace for Node creation with utilities*
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
) --: <V>(V & table) -> (UnregisteredNode<{}, V>, P...)
	local Nodes = { A, B, C, D, E, F, G, H, I, J, K, L, M, M, O, P, Q, R, S }

	return function<T>(content: T)
		(content :: any).__index = content --for classes, this remains the table unsealed

		return function<V>(meta: V & table) --: (UnregisteredNode<{}, V>, P...)
			(content :: any).___meta = meta --this remains the table unsealed

			local Node = setmetatable( --: UnregisteredNode<{}, V>
				content,
				{
					__Noderef = content,
					__Nodemeta = lowmerge(meta, { --modifies meta
						Dependencies = Nodes,
					}) :: V,
					__call = function()
						return content
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
						GetDependencyCount = function<S>(self: S): number
							return depcount(meta.Dependencies)
						end,
					}, { __index = meta }), --third layer __index to reference metadata
				}
			)

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
				S :: S --table.unpack(Nodes)
		end
	end
end

--- moonwave docs cannot handle more than 3 lines of text to render @param and @return

--[[
    Registers an unregistered Node's dependency tree node
	<br> Returns the Node merged with readonly immutable metadata

    ---
    @param Node      `(UnregisteredNode)` &emsp; = &emsp; *The unregistered Node*

    @return `Node<T>`      &emsp; = &emsp; *Node*
]]
function Allure:Register(Node)
	local instance = (Node :: any).___meta.Instance

	local childrenNodes = {}
	for _, inst in instance:GetChildren() do
		childrenNodes[inst] = Allure:Node(inst)
	end

	local registered = lowmerge(
		lowmerge(
			--lowmerge({}, Node :: T), --1. reference singleton
			Node,
			{
				Name = script.Name, --2. default metadata
				Version = "1.0.0",
				Description = "",
				Author = "",
				License = "",

				Dependencies = {},
				Priority = -depcount((Node :: any).___meta.Dependencies or {} :: table), --counts nested dependencies

				Client = true,

				Tags = {},
				Nodes = childrenNodes,

				Instance = instance,
			} :: never
		),
		table.freeze((Node :: any).___meta) :: Node --3. given metadata
	)

	RegisteredNodes[instance] = registered

	return registered
end

--[[
    Registers an unregistered Node.
    <br>A registered Node has immutable metadata, which is merged with the singleton, and can be used as a dependency.

    ---
    @param `Node`      `(UnregisteredNode)` &emsp; = &emsp; *The unregistered Node*

    @return `Node<T>`      &emsp; = &emsp; *Registered Node*
]]
function Allure:NodeTree(parent: Instance): NodeTree
	local NodeTree: NodeTree

	NodeTree = {
		Parent = parent,
		Tree = {},

		GetModuleNodes = function(self: NodeTree)
			local nodes = {}
			for instance, node in self.Tree do
				if node.Instance:IsA "ModuleScript" then
					nodes[instance] = node
				end
			end
			return nodes
		end,

		GetFolderNodes = function(self: NodeTree)
			local nodes = {}
			for instance, node in self.Tree do
				if node.Instance:IsA "Folder" then
					nodes[instance] = node
				end
			end
			return nodes
		end,

		ForEach = function(self: NodeTree, fn: (self: NodeTree, node: Node) -> ...any?)
			for inst, node in self.Tree do
				fn(self, node)
			end
			return self
		end,

		ForAll = function(self: NodeTree, fn: (self: NodeTree, nodes: { [Instance]: Node }) -> ...any?)
			fn(self, self.Tree)
			return self
		end,

		ForEachTagged = function(self: NodeTree, tag: any, fn: (self: NodeTree, nodes: Node) -> ...any?)
			for inst, node in self.Tree do
				if node.Tags[tag] then
					fn(self, node)
				end
			end
			return self
		end,

		ForAllTagged = function(self: NodeTree, tag: any, fn: (self: NodeTree, nodes: { [Instance]: Node }) -> ...any?)
			local tagged = {}
			for inst, node in self.Tree do
				tagged[inst] = node.Tags[tag] and node or nil
			end

			fn(self, tagged)
			return self
		end,

		Sort = nil :: any,

		LoadChildren = nil :: any,
		LoadFromTree = nil :: any,

		Merge = nil :: any,

		SliceNonModules = nil :: any,
		SliceNonFolders = nil :: any,

		SliceNode = nil :: any,

		SlicePredicate = nil :: any,
		SliceTagged = nil :: any,
		SliceFromChild = nil :: any,
	}

	return NodeTree
end

return Allure
