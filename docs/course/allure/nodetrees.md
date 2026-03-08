# Handling multiple Node Trees

Creating multiple trees allows you to apply tags to different nodes, group nodes, filter nodes, apply different lifecycle hooks to nodes, more and more.
<br>Let's go over merging first.

## Merging Trees

Merging 2 trees is practically loading nodes from one to another.

```luau
local tree1 = Allure:NodeTree():LoadChildren(script.Services)
local tree2 = Allure:NodeTree():LoadChildren(script.Controllers)

---Load Nodes from Controllers into the tree with Nodes from Services
tree1:LoadFromTree(tree2) -- [!code highlight]
```

The resultant tree is practically identical to
```luau
local tree3 = Allure:NodeTree()
    :LoadChildren(script.Services)
    :LoadChildren(script.Controllers)
```

In any case, a tree cannot have 2 instances of the same Node.

You can unload nodes just the same way:

```luau
tree1:UnloadFromTree(tree2)
```

## Slicing Nodes

This is the prominent feature of node trees.

You can filter and group nodes by slicing out the rest.
<br>Whenever you slice a tree, the tree is ***modified***: selected nodes are removed.

The easiest example of this, is slicing a single node:

```luau
local tree = Allure:NodeTree()
    :LoadDescendants(script.Services)

tree:SliceNode(tree:NodeFromInstance(script.Services.BattleService)) -- [!code highlight]
```
Our module hierarchy:
```
📂Services
  ├─📂Vehicles
  │   ├─📦VehicleSpawnService.luau
  │   └─📦VehicleService.luau
  ├─📦BattleService.luau 
  │   └─📦Abilities.luau
  └─📦RaceService.luau 
```
Our tree:
```
🌲tree                                    🌲tree
  ├─💠BattleService                         ├─💠Abilities
  ├─💠Abilities           SliceNode         ├─💠RaceService
  ├─💠RaceService           ---->           ├─💠VehicleSpawnService
  ├─💠VehicleSpawnService                   └─💠VehicleService
  └─💠VehicleService
```

## Slicing nodes with shared ancestry

`VehicleService` and `VehicleSpawnService` share their parent: Vehicles.
<br>If we've loaded too many nodes, we can get rid of descendant nodes of Vehicles without any problems as well.

```luau
local tree = Allure:NodeTree()
    :LoadDescendants(script.Services)

tree:SliceChildren(script.Services.Vehicles) -- [!code highlight]
```
```
📂Services
  ├─📂Vehicles
  │   ├─📦VehicleSpawnService.luau
  │   └─📦VehicleService.luau
  ├─📦BattleService.luau 
  │   └─📦Abilities.luau
  └─📦RaceService.luau 
```
```
🌲tree                                    🌲tree
  ├─💠BattleService                         ├─💠BattleService
  ├─💠Abilities         SliceChildren       ├─💠Abilities
  ├─💠RaceService           ---->           └─💠RaceService
  ├─💠VehicleSpawnService
  └─💠VehicleService
```

This case right here however could be simplified without loading unnecessary nodes firsthand via `tree:LoadDescendantsPredicate`

## Slicing nodes with a specific tag

```luau
local tree = Allure:NodeTree()
    :LoadDescendants(script.Services)

tree:SliceTagged("SomeTag") -- [!code highlight]
```

Additionally, you can slice nodes that have this tag set to some specific value ***type***

```luau
tree:SliceTagged("SomeTag", "string")
```

Or even some specific value.

```luau
tree:SliceTagged("SomeTag", nil, 200)
```

## Slicing nodes from predicate

Slice nodes having some function that returns *true* or *false*, deciding to slice the node or not.

For a straightforward example, let's slice nodes that end on "Service" with their modulescript names.

```luau
local tree = Allure:NodeTree()
    :LoadDescendants(script.Services)

tree:SlicePredicate(function(self, node) -- [!code highlight]
    return not string.match(node.Tags.Instance.Name, "Service$") -- [!code highlight]
end) -- [!code highlight]
```
```
📂Services
  ├─📂Vehicles
  │   ├─📦VehicleSpawnService.luau
  │   └─📦VehicleService.luau
  ├─📦BattleService.luau 
  │   └─📦Abilities.luau
  └─📦RaceService.luau 
```
```
🌲tree                                    🌲tree
  ├─💠BattleService                         └─💠Abilities
  ├─💠Abilities         SlicePredicate
  ├─💠RaceService           ---->
  ├─💠VehicleSpawnService
  └─💠VehicleService
```

This example here could also directly be simplified via `tree:LoadDescendantsPredicate`

## Cloning and Negation

If you need a duplicate tree, you can always clone it

```luau
local tree2 = tree1:Clone()
```

By unloading nodes from a slice, we can negate anything.

```luau
local tree = Allure:NodeTree()
    :LoadDescendants(script.Services)

local tree2 = tree:Clone()
tree2:SliceChildren(script.Services.Vehicles)
```
```
🌲tree                                    🌲tree2
  ├─💠BattleService                         ├─💠BattleService
  ├─💠Abilities             Clone           ├─💠Abilities
  ├─💠RaceService           ---->           ├─💠RaceService
  ├─💠VehicleSpawnService                   ├─💠VehicleSpawnService
  └─💠VehicleService                        └─💠VehicleService
```
```
🌲tree2                                   🌲tree2
  ├─💠BattleService                         ├─💠BattleService
  ├─💠Abilities         SliceChildren       ├─💠Abilities
  ├─💠RaceService           ---->           └─💠RaceService
  ├─💠VehicleSpawnService
  └─💠VehicleService
```

```luau
tree:UnloadFromTree(tree2)
```
```
🌲tree                                    🌲tree2
  ├─💠VehicleSpawnService                   ├─💠BattleService
  └─💠VehicleService    UnloadFromTree      ├─💠Abilities
    ㅤㅤ  ㅤ                <----            └─💠RaceService