# Allure API

***Allure*** is a (Container DI & IoC) Node Worker Framework that provides a container for loading modules as `Nodes` via `NodeTrees`.<br>
`NodeWorkspaces` and `NodeTree` workflows are capable of orchestrating many architectures like *MVC*, *Master-Worker*, *Messaging Bus*, etc.

---

# Types

## Node

```luau
type Node = {
	read Name: string,
	read Version: string,
	read Description: string,
	read Author: string,
	read License: string,

	read Dependencies: { unknown },

	Tags: {
		[any]: any,
	},
}
```
Standard Node Contents.<br>
The type of any Node is `Node & T`.

## NodeWorkspace

```luau
type NodeWorkspace<T, V> = setmetatable<
	T,
	{
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
```
This is a *derived* type from the result of `Allure:NodeWorkspace`, because tables have to remain sealed and the type solver cannot solve generic `T` and `V` for `setmetatable<T, V>`
<br>This type can only assist you with strict type casting on NodeWorkspaces.

But since NodeWorkspaces are used ubiquitously, I'll cover the granted methods & props in `__index` here.
### `.Meta`
- > References the node metadata table (not the metatable)

### `:UseDependency`
- > Returns whatever singleton you give it, and adds it into the dependency table.
### `:SetPriority`
- > Shorthand to changing the `Priority` tag in `.Meta.Tags`
### `:ModifyMeta`
- > Merges the table you give it with `.Meta`
### `:Threads`
- > Returns `amount` `Threads`
### `:GetDependencyCount`
- > Counts all of the dependencies, included the nested ones, and returns the number
### `:Zero`
- > Finishes the creation of the Node without any unnecessary metadata merged with `.Meta`, like `()` does

## NodeTree

```luau
type NodeTree = {
	Tree: { Node },

	ForEach: (
		self: NodeTree,
		fn: (self: NodeTree, Node: Node) -> ...any?,
		errhandler: nil | <E>(self: NodeTree, Node: Node, Err: E) -> ...any?
	) -> NodeTree,
	ForAll: (self: NodeTree, fn: (self: NodeTree, Nodes: { Node }) -> ...any?) -> NodeTree,
	ForEachTagged: (self: NodeTree, tag: any, fn: (self: NodeTree, Node: Node) -> ...any?) -> NodeTree,
	ForAllTagged: (self: NodeTree, tag: any, fn: (self: NodeTree, Nodes: { Node }) -> ...any?) -> NodeTree,
	Sort: (self: NodeTree, fn: (self: NodeTree, node: Node, shared: table) -> number) -> NodeTree,
	NodeFromInstance: (self: NodeTree, instance: Instance) -> Node?,
	Clone: (self: NodeTree) -> NodeTree,

	LoadChildren: (self: NodeTree, instance: Instance) -> NodeTree,
	LoadDescendants: (self: NodeTree, instance: Instance) -> NodeTree,
	LoadFromTree: (self: NodeTree, tree: NodeTree) -> NodeTree,
	UnloadFromTree: (self: NodeTree, tree: NodeTree) -> NodeTree,

	SlicePredicate: (self: NodeTree, predicate: (self: NodeTree, Node: Node) -> boolean) -> NodeTree,
	SliceNode: (self: NodeTree, Node: Node) -> NodeTree,
	SliceFromChild: (self: NodeTree, child: Instance) -> NodeTree,
	SliceTagged: (self: NodeTree, tag: any, valueType: string?, value: any?) -> NodeTree,
}
```

The type of NodeTrees.
### `.Tree`
- > Array of `Nodes`: surface-level nodes in the tree

Basic loader methods:

### `:ForEach`
- > Calls a function for each node of the tree.<br>If `errhandler` is specified, then all functions are called in safe mode via `xpcall`

### `:ForAll`
- > Calls a function for all tree nodes

### `:ForEachTagged`
- > Calls a function for each tree node with a specific tag

### `:ForAllTagged`
- > Calls a function for all tree nodes with a specific tag

### `:Sort`
- > Sorts surface level nodes<br>Via *minimum --> maximum* algorithm of the `fn()` returns

### `:NodeFromInstance`
- > Returns a `Node` within the tree from it's instance<br>Returns `nil` if such a Node is not within the tree

### `:Clone`
- > Returns a new NodeTree with identical Tree structure

Methods for loading nodes:

### `:LoadChildren`
- > Loads children nodes of an instance into the tree

### `:LoadDescendants`
- > Loads all descendant nodes of an instance into the tree

### `:LoadFromTree`
- > Loads nodes from a different tree

### `:UnloadFromTree`
- > Unloads nodes present in a different tree

Methods for slicing nodes:

### `:SlicePredicate`
- > Creates a **new** dependency tree by slicing the existing tree nodes having which the function returns false

### `:SliceNode`
- > Creates a **new** dependency tree by slicing the specified node

### `:SliceFromChild`
- > Creates a **new** dependency tree by slicing node descendants of a specific instance

### `:SliceTagged`
- > Creates a **new** dependency tree by slicing the existing tree nodes with a specific tag *present* and/or with a *specific type* and/or with a *specific value*

## Thread

```luau
type Thread = {
	Function: <A..., R...>(self: Thread, fn: (A...) -> R...) -> (A...) -> (),
	Enqueue: <A..., R...>(self: Thread, fn: (A...) -> R...) -> Thread,
	Queue: { (...any?) -> ...any? },
	QueueHook: { (...any?) -> ...any? },
	Yield: (self: Thread, sec: number) -> number,
	Coroutine: thread,
	Kill: (self: Thread) -> (),
}
```
Custom thread object for Worker Nodes.
<br>Encapsulates a thread and a queue for task (function) consumption.

### `.Queue`
- > Task (function) queue for coroutine consumption

### `.QueueHook`
- > Array of functions, all of which are called once an item is ***dequeued***<br>The functions are called on the consumer thread!

### `.Coroutine`
- > The underlying coroutine thread of this Thread

### `:Function`
- > Returns a function identical to `fn` but with a wrapper that enqueues it

### `:Enqueue`
- > Safely enqueue a function

### `:Yield`
- > Yields the thread for `sec` seconds without throttling and sets a flag<br>Threads yielded via `task.wait` or `coroutine.yield` will consume next tasks immediately

### `:Kill`
- > Closes the coroutine, destroys the queue and Thread