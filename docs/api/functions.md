# Functions API

## Node
```luau
Allure:Node(...: P...) -> (content: T & table) -> (meta: table) -> Node & T, P...
```
Creates a new `Node` having it's `content` and `meta`.
<br>Nodes are singletons merged with metadata used by Allure and it's tools.

Allure will add *missing* contents from `meta`, specifically:
```luau
Name = "",
Version = "1.0.0",
Description = "",
Author = "",
License = "",

Dependencies = {},

Tags = {
    Priority = (NodeWorkspace):GetDependencyCount(meta.Dependencies or {}),
}
```

## ZeroNode
```luau
Allure:ZeroNode(...: P...) -> (content: T & table) -> (meta: table) -> Node & T, P...
```
Entirely analogical to `Allure:Node`, however Allure will add, if missing, the values partially:
```luau
Dependencies = {},

Tags = {
    Priority = (NodeWorkspace):GetDependencyCount(meta.Dependencies or {}),
}
```

## NodeWorkspace
```luau
Allure:NodeWorkspace(...: P...) -> (content: T & table) -> (meta: V & table) -> NodeWorkspace<T, V>
```
Creates a new `NodeWorkspace` having `content` and `meta`.
<br>`NodeWorkspaces` aren't fully fledged nodes and have overarching metatables.

Calling a `NodeWorkspace` will finish the process and create a `Node & T`:
```luau
NodeWorkspace() -> Node & T
```

## NodeTree
```luau
Allure:NodeTree() -> NodeTree
```
Creates a new `NodeTree`.
<br>`NodeTrees` allow you to have branches of Nodes and a multitude of utilities given along.