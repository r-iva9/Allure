# Node Trees

Here we are, at the primary feature of Allure.

---

***Node Trees*** will replace loading and orchestrating modules in your game.
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
end, function(self, node, err) -- [!code highlight]
    print("Some error occured in node", node.Tags.Instance.Name) -- [!code highlight]
end) -- [!code highlight]
```

And even more, ForEach supports ***yield thresholds***.
<br>For example and a yield threshold equal to 3 seconds, if the function call for some node is continuing for more than 3 seconds, Allure errors, and skips that node.

```luau
local tree = Allure:NodeTree()
tree:LoadDescendants(script.Services)

tree:ForEach(function(self, node)
    node.Tags.SomeTag = true
end, function(self, node, err)
    print(node, "ran into error", err)
end, 3) -- [!code highlight]
```

If some node yields for longer than yield threshold and an error handler is specified, it will be called with `err` equal to `true`:

```luau
local tree = Allure:NodeTree()
tree:LoadDescendants(script.Services)

tree:ForEach(function(self, node)
    node.Tags.SomeTag = true
end, function(self, node, err)
    if err == true then -- [!code highlight]
        print(node, "has yielded for longer than 3 seconds") -- [!code highlight]
    else -- [!code highlight]
        print(node, "ran into error", err)
    end
end, 3)
```

### ForEachParallel

Entirely analogical to `ForEach`, except everything happens *asynchronously*.
<br>The error handler will also work, and the yield threshold will also work.

ForEachParallel will not yield the main thread that it's called in.

For example, here's the standard setup for OnStart and OnInit lifecycle hooks:

```luau
local tree = Allure:NodeTree()
    :LoadDescendants(script)
    :ForEach(function(self, node)
        node:OnInit()
    end)
    :ForEachParallel(function(self, node)
        node:OnStart()
    end)
```

With error handling:

```luau
local tree = Allure:NodeTree()
    :LoadDescendants(script)
    :ForEach(function(self, node)
        node:OnInit()
        node.Tags.Initialized = true -- [!code highlight]
    end, function(self, node, err) -- [!code highlight]
        warn(node.Tags.Instance.Name, "failed to initialize in 5 seconds!") -- [!code highlight]
        node.Tags.Initialized = false -- [!code highlight]
    end, 5) -- [!code highlight]
    :ForEachParallel(function(self, node)
        if not node.Tags.Initialized then return end -- [!code highlight]
        node:OnStart()
    end, function(self, node, err) -- [!code highlight]
        warn(node.Tags.Instance.Name, "failed to start and ran into", err) -- [!code highlight]
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

### Sort

The order in which surface-level nodes are present in your tree matters.
<br>You can easily modify that with `:Sort()`

```luau
tree:Sort(function(self, node)
    return #node.Dependencies
end)
```

This will sort the `tree.Tree` array table having some values that your function returns for all nodes.

***Sorting happens by the minimum --> maximum algorithm*** and moves duplicate values one order higher.

---

This example above will sort values by how many dependencies that they have *on the surface level*.
<br>For all dependencies, you can set a tag during Node creation via `NodeWorkspace:GetDependencyCount`, or use the Priority tag that Allure sets for you.

```luau
tree:Sort(function(self, node)
    return node.Tags.Priority
end)
```

Priority (number of all dependencies) makes order when put into minimum --> maximum. It will sort your dependencies by how many Total and nested dependencies it has.

### NodeFromInstance

Additionally, you can get a Node having it's Instance (if it's present in the tree).
<br>This is practically identical to `require()` but can help if you're eager to entirely build on dependency trees and their safety guidance.

```luau
local module = tree:NodeFromInstance(path.to.module)
```

### NodeFromPredicate

Sometimes you need to find some *specific* node having some of it's properties.
<br>This function will return the first node out of all, which suits the description (predicate):

```luau
local node = tree:NodeFromPredicate(function(self, node)
    return #node.Dependencies > 2 and node.Tags.Instance:IsDescendantOf(script.Services)
end)
```

### LoadNode and LoadNodes

Quickly load in a new node or nodes in bulk:

```luau
local tree = Allure:NodeTree()
    :LoadNode(require(script.SomeNode))
    :LoadNodes {
        require(script.AnotherNode),
        require(script.TheresMore)
    }
```

> [!WARNING]
> Nodes loaded via `:LoadNode` and `:LoadNodes` will not get tagged with `Instance` because it's impossible to detect.
> <br>This will conflict with multiple other functions of Node Trees.

### LoadDescendantsPredicate

In many cases, for example, in Nodes themselves, you might not want to load in all descendants and children, but some select few, to avoid dependency cycles.
<br>You can actually avoid any dependency cycle with a simple trick, but I'll show that a bit later.

```luau
local tree = Allure:NodeTree()
    :LoadDescendantsPredicate(script.Modules, function(self, instance)
        return string.match(instance.Name, "Service$")
    end)
```

Notice that the argument given to this function is an instance, the modulescript, not a node.

## Throwback to Nodes

I've already mentioned that you can use NodeTrees within Nodes. But whenever you do so, you are loading more nodes, that being identical to dependencies.
<br>But it's difficult to track this down and correlate with actual node dependencies.

So there's a new utility specifically for this:

```luau
local node = Allure:Node() {} {}

local tree = node:UseTree()

return node()
```

This is a NodeTree, entombed into Node.Dependencies by Allure.
<br>If you already had dependencies, they become surface-level nodes of the tree:

```luau
local node, React = Allure:Node(
    require(path.to.React)
) {} {}

local tree = node:UseTree()

print(#tree.Tree) --1
print(#node.Dependencies) --1

return node()
```

Modifying the tree whatsoever reflects on Node.Dependencies:

```luau
local node, React = Allure:Node(
    require(path.to.React)
) {} {}

local tree = node:UseTree()

print(#node.Dependencies) --1

tree:LoadDescendants(script)

print(#node.Dependencies) --3

return node()
```

`Node:UseDependency` becomes `tree:LoadNode`

Using `Node:UseTree()` again will result in nothing, however.

---

This most certainly means that Dependencies can be modified after node finalization, if you have some tree functions used after it.