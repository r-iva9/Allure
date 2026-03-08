# Allure API

***Allure*** is a (Container DI, IoC) Node & Worker Framework that provides a container for loading modules as `Nodes` via `NodeTrees`.<br>
`Node` and `NodeTree` workflows are capable of orchestrating many architectures like *MVC*, *Master-Worker*, *Messaging Bus*, etc.

---

# Types

## Node

```luau
type Node<T=table> = T & {
	read Dependencies: { unknown },

	Tags: {
		[any]: any,
	},
}
```
Standard Node Contents derived from default HiddenMeta.<br>
The type of any Node is `Node` or `Node<T>`.

## NodeTree

```luau
type NodeTree = {
	Tree: { Node },

	ForEachParallel: (
		self: NodeTree,
		fn: (self: NodeTree, Node: Node) -> ...any?,
		errhandler: nil | <E>(self: NodeTree, Node: Node, Err: E) -> ...any?,
		yieldthreshold: number?
	) -> NodeTree,
	ForEach: (
		self: NodeTree,
		fn: (self: NodeTree, Node: Node) -> ...any?,
		errhandler: nil | <E>(self: NodeTree, Node: Node, Err: E) -> ...any?,
		yieldthreshold: number?
	) -> NodeTree,
	ForAll: (self: NodeTree, fn: (self: NodeTree, Nodes: { Node }) -> ...any?) -> NodeTree,
	ForEachTagged: (self: NodeTree, tag: any, fn: (self: NodeTree, Node: Node) -> ...any?) -> NodeTree,
	ForAllTagged: (self: NodeTree, tag: any, fn: (self: NodeTree, Nodes: { Node }) -> ...any?) -> NodeTree,
	Sort: (self: NodeTree, fn: (self: NodeTree, node: Node, shared: table) -> number) -> NodeTree,
	NodeFromInstance: (self: NodeTree, instance: Instance) -> Node?,
	NodeFromPredicate: (self: NodeTree, predicate: (self: NodeTree, Node: Node) -> boolean) -> Node?,
	Clone: (self: NodeTree) -> NodeTree,

	LoadNode: (self: NodeTree, node: Node) -> NodeTree,
	LoadNodes: (self: NodeTree, nodes: { table & Node }) -> NodeTree,
	LoadChildren: (self: NodeTree, instance: Instance) -> NodeTree,
	LoadDescendants: (self: NodeTree, instance: Instance) -> NodeTree,
	LoadDescendantsPredicate: (self: NodeTree, instance: Instance, predicate: (self: NodeTree, Instance: Instance) -> boolean) -> NodeTree,
	LoadFromTree: (self: NodeTree, tree: NodeTree) -> NodeTree,
	UnloadFromTree: (self: NodeTree, tree: NodeTree) -> NodeTree,

	SlicePredicate: (self: NodeTree, predicate: (self: NodeTree, Node: Node) -> boolean) -> NodeTree,
	SliceNode: (self: NodeTree, Node: Node) -> NodeTree,
	SliceFromChild: (self: NodeTree, child: Instance) -> NodeTree,
	SliceTagged: (self: NodeTree, tag: any, valueType: string?, value: any?) -> NodeTree,
}
```
The type of NodeTrees.

## Worker

```luau
type Worker = {
	Function: <A..., R...>(self: Thread, fn: (A...) -> R...) -> (A...) -> (),
	Enqueue: <A..., R...>(self: Thread, fn: (A...) -> R...) -> Thread,
	Dequeue: <A..., R...>(self: Thread, index: number?) -> (A...) -> R...,
	Queue: { (...any?) -> ...any? },
	QueueHook: { (...any?) -> ...any? },
	Yield: (self: Thread, sec: number) -> number,
	Coroutine: thread,
	Kill: (self: Thread) -> (),
}
```
Custom thread object for Worker Nodes.
<br>Encapsulates a thread and a queue for task (function) consumption.