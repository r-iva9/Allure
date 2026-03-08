# Functions API

## Node
```luau
Allure:Node(...: P...) -> (content: T & table) -> (meta: V) -> a, P...
```
The type of `a`:
```luau
{
    @metatable {
        __Noderef: T,
        __Nodemeta: V,
        __call: () -> T & V,
        __index = {
            @metatable {
                __index: H
            },
            Meta: V,
            HiddenMeta: H,
            UseDependency: <S, M>(self: S, singleton: M): M,
            UseTree: <S>(self: S) -> NodeTree,
            OverrideMetatable: <S, M>(self: S, mt: M),
            UseMetatable: <S, M>(self: S, mt: M),
            GetMetatable: <S, M>(self: S) -> M,
            Tag: <S, T, V>(self: S, tag: T, value: V) -> S,
            GetTag: <S, T, V>(self: S, tag: T) -> V
        }
    }
}
```
Creates a new `Node` having it's `content` and `meta`.
<br>Nodes are singletons merged with Meta and HiddenMeta suited for Allure and it's tools.

Default HiddenMeta:
```luau
Dependencies = {...},

Tags = {
    Priority = Allure:CountDependencies(meta.Dependencies or {...}),
}
```

### `.Meta`
- > References the node meta
### `.HiddenMeta`
- > References the hiddenmeta
### `:UseDependency`
- > Returns whatever singleton you give it, and adds it into the Dependencies.
- > Loads a new node into the NodeTree if `:UseTree` was used.
### `:UseTree`
- > Creates and returns a new NodeTree, replaces Dependencies with it.
### `:OverrideMetatable`
- > Merges the future metatable that will be applied after finalization (`__call`) with the passed table
### `:UseMetatable`
- > Replaces the future metatable that will be applied after finalization (`__call`) entirely with the passed table
### `:GetMetatable`
- > Returns the future metatable that will be applied after finalization (`__call`)
### `:Tag`
- > Shorthand to setting a new key to a value of `HiddenMeta.Tags`
### `:GetTag`
- > Shorthand to getting a value from a key inside of `HiddenMeta.Tags`

```luau
local Allure = require(path.to.Allure)

local module, React = Allure:Node(
    require(path.to.React)
) {} {
    Name = "TestNode"
}

module:Tag("SERVICE", true)

function module:OnInit()
end

function module:OnStart()
end

return module()
```

## CountDependencies
```luau
Allure:CountDependencies(dependencies: {Node}) -> number
```
Counts ***all*** dependencies, included those nested in dependencies of dependencies.

## NodeTree
```luau
Allure:NodeTree() -> NodeTree
```
Creates a new `NodeTree`.
<br>`NodeTrees` allow you to have branches of Nodes and a multitude of utilities given along.

### `.Tree`
- > Array of `Nodes`: surface-level nodes in the tree

Basic loader methods:

### `:ForEachParallel`
- > Calls a function for each node of the tree **in parallel**
- > If `errhandler` is specified, then all functions are called in safe mode via `xpcall`
- > If `yieldthreshold`is specified, then the thread, that the function is called in, will be closed if it runs longer than `yieldthreshold` seconds.
- > In this case, Allure will yield a respective error, however if `errhandler` is specified, then it's called with `Err = true`
### `:ForEach`
- > Calls a function for each node of the tree synchronously
- > If `errhandler` is specified, then all functions are called in safe mode via `xpcall`
- > If `yieldthreshold`is specified, then the thread, that the function is called in, will be closed if it runs longer than `yieldthreshold` seconds.
- > In this case, Allure will yield a respective error, however if `errhandler` is specified, then it's called with `Err = true`
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
### `:NodeFromPredicate`
- > Calls the predicate for each `Node` of the tree and returns the first Node, having which, the predicate returned `true`
### `:Clone`
- > Returns a new NodeTree with identical Tree structure

Loaders:

### `:LoadNode`
- > Loads the specified node (singleton) into the tree
### `:LoadNodes`
- > Loads nodes (singletons) from the table in bulk into the tree
### `:LoadChildren`
- > Loads children nodes of an instance into the tree
### `:LoadDescendants`
- > Loads all descendant nodes of an instance into the tree
### `:LoadDescendantsPredicate`
- > Calls a predicate for all descendant modulescripts of the specified instance and loads such nodes, having which, the predicate returns `true`
### `:LoadFromTree`
- > Loads nodes from a different tree
### `:UnloadFromTree`
- > Unloads nodes present in a different tree

Slicers:

### `:SlicePredicate`
- > Slices the existing tree nodes having which the function returns false
### `:SliceNode`
- > Slices the specified node
### `:SliceFromChild`
- > Slices node descendants of a specific instance
### `:SliceTagged`
- > Slices the existing tree nodes with a specific tag *present* and/or with a *specific type* and/or with a *specific value*

## Workers

```luau
Allure:Workers(amount: number) -> ...Worker
```

### `.Queue`
- > Task (function) queue for coroutine consumption
### `.QueueHook`
- > Array of functions, all of which are called once an item is ***dequeued***<br>The functions are called on the consumer thread!
### `.Coroutine`
- > The underlying coroutine thread of this Worker
### `:Function`
- > Returns a function identical to `fn` but with a wrapper that enqueues it
### `:Enqueue`
- > Safely enqueue a function into the queue
### `:Dequeue`
- > Safely dequeue the last enqueued function from the queue, or a specific one, if index is specified
### `:Yield`
- > Yields the thread for `sec` seconds without throttling and sets a flag<br>Workers yielded via `task.wait` or `coroutine.yield` will consume next tasks immediately
### `:Kill`
- > Closes the coroutine, destroys the queue and Worker