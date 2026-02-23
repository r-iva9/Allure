# Node Trees

Here we are, at the primary feature of Allure.

---

***Node (Dependency) Trees*** will replace loading and requiring modules in your game.
<br>Unlike a Loader, a `NodeTree` is an object. It's a tree with branches of Nodes, that offers lots of functionality, like handling Nodes, calling functions, tagging nodes, slicing nodes, merging trees, and more.

## Your first NodeTree

NodeTrees can be anywhere, be it a Node or the Bootstrapper.

```luau
local Allure = require(path.to.Allure)

local tree = Allure:NodeTree()
```

NodeTrees have no parent or instance that they are attached to.
<br>They're arbitrary, and nodes you load in can also be anywhere.

## Say I have some module hierarchy

Like this:

```
📂Services
  ├─📂Vehicles
  │   ├─📦VehicleSpawnService.luau
  │   └─📦VehicleService.luau
  ├─📦BattleService.luau 
  │   └─📦Abilities.luau
  └─📦RaceService.luau 
```

All of these are Allure Nodes.
<br>Let's load first children into our NodeTree:

```luau
local tree = Allure:NodeTree()

tree:LoadChildren(script.Services)
```

Our tree now looks like this:
```
🌲Tree
  ├─💠BattleService 
  └─💠RaceService 
```

Because it loaded children nodes.
<br>Let's add some more by loading children of `Vehicles`:

```luau
local tree = Allure:NodeTree()
tree:LoadChildren(script.Services)
tree:LoadChildren(script.Services.Vehicles)
```
```
🌲Tree
  ├─💠BattleService 
  ├─💠RaceService 
  ├─💠VehicleSpawnService
  └─💠VehicleService
```

All nodes that you load are contained like in some storage. They're loaded on the *surface level*.
<br>Nodes branch via Dependencies that they have.

For example, if `VehicleService` has `VehicleSpawnService` as a dependency, that doesn't change anything: we can still load both as surface level node branches.

---

Analogically, you can load all descendants:

```luau
local tree = Allure:NodeTree()
tree:LoadDescendants(script.Services)
```
```
🌲Tree
  ├─💠BattleService 
  ├─💠Abilities
  ├─💠RaceService 
  ├─💠VehicleSpawnService
  └─💠VehicleService
```

Calling `LoadChildren` or `LoadDescendants` also tags each Node with `Instance` = their modulescript.

## Classic loader methods
### ForEach

You can call a function on each surface level node of the tree via `tree:ForEach`

```luau
local tree = Allure:NodeTree()
tree:LoadDescendants(script.Services)

tree:ForEach(function(self, node) -- [!code highlight]
    node:OnInit() -- [!code highlight]
    node.Tags.SomeTag = true -- [!code highlight]
end) -- [!code highlight]
```

Additionally, ForEach supports ***custom error handling***
<br>Pass a second function into ForEach to act as an error handler:

```luau
local tree = Allure:NodeTree()
tree:LoadDescendants(script.Services)

tree:ForEach(function(self, node)
    node.Tags.SomeTag = true
end, function(self, node, error) -- [!code highlight]
    print("Some error occured in node", node.Tags.Instance.Name) -- [!code highlight]
end) -- [!code highlight]
```

### ForAll

Call a function having all nodes of the tree:

```luau
tree:ForAll(function(self, nodes)
    print("Tree has", #nodes, "Nodes")
end)
```

The argument given as `nodes` is identical to `tree.Tree`

```luau
print("Tree has", #tree.Tree, "Nodes")
```

### ForEachTagged

Calls a function on each node with some specific tag

```luau
tree:ForEachTagged("Loaded", function(self, node)
    node:SomeTagSpecificFunction()
    node:OnStart()
end)
```

### ForAllTagged

Calls a function given all nodes with some specific tag

```luau
tree:ForAllTagged("Loaded", function(self, nodes)
    print(#nodes, "have the Loaded tag")
end)
```

## Miscellaneous

The order in which surface-level nodes are present in your tree matters.
<br>You can easily modify that with `:Sort()`

```luau
tree:Sort(function(self, node)
    return #node.Dependencies
end)
```

This will sort the `tree.Tree` array table having some values that your function returns for all nodes.

***Sorting happens by the mimimum --> maximum algorithm*** and moves duplicate values one order higher.

---

This example above will sort values by how many dependencies that they have *on the surface level*.
<br>For all dependencies, you can set a tag during Node creation via `NodeWorkspace:GetDependencyCount`, or use the Priority tag that Allure sets for you.

```luau
tree:Sort(function(self, node)
    return -node.Tags.Priority
end)
```

Priority can be turned into order via negation. It will sort your dependencies by how many Total and nested dependencies it has.

---

Additionally, you can get a Node having it's Instance (if it's present in the tree).
<br>This is practically identical to `require()` but can help if you're eager to entirely build on dependency trees and their safety guidance.

```luau
local module = tree:NodeFromInstance(path.to.module)
```