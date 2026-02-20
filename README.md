<p align="center">
  <img width="500" height="250" src="https://github.com/m-at1/Allure/blob/main/images/logo.png?raw=true" alt="Logo">
</p>

<p align="center">
  <b><i>Fully Typesafe Node & Worker Framework for Luau.</i></b> </br>
  <!--<i>Inspired by -->
</p>

<h1></h1>
</br>
<div align="center">
  <a href="https://github.com/m-at1/Allure/blob/main/Installation.md"><img width="65" height="50" src="./images/Install.png" alt="Install"></a>‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ
  <a href="https://github.com/m-at1/Allure/releases"><img width="160" height="50" src="./images/Docs.png" alt="Docs"></a> <!--ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ
  a href="https://github.com/m-at1/Alloy/releases"><img width="130" height="50" src="./images/Benchmarks.png" alt="Benchmarks"></a> -->
</div>

> [!IMPORTANT]
> <h2>Allure is incredibly fresh and new</h2>
> This means that Allure has some unfinished features, documentation, unremoved bloat, and possibly some overlooked issues.

## 📦 Installation
Install via wally:
```
Allure = "r-iva9/allure@1.0.0"
```
(Package description is misleading, sorry for that!)

# 🍃 Nodes and Boilerplate

## 💠 A Node
***Is a modulescript singleton in your game.***
<br>Nodes have metadata: their own name, version, description.

Nodes can 
  - rely on threads,
  - be used as dependencies for other nodes,
  - be used in dependency trees
  - and more!
> ### Minimum boilerplate
```luau
local Allure = require(path.to.Allure)

local module = {}

return Allure:Node()(module) {}
```
> ### Injecting dependencies
```luau
local Allure = require(path.to.Allure)

local dependency1, dependency2 = require(path.to.dependency), require(path.to.dependency)
local module = {}

return Allure:Node(dependency1, dependency2)(module) {}
```
Creating a node like this gives it the necessary additions, dependencies and *metadata*.
<br>You let Allure control the overhead of your singletons, leaving you to only fill them with contents.

For more functionality, you can slowly work on a Node via a NodeWorkspace:

```luau
local Allure = require(path.to.Allure)

local module = Allure:NodeWorkspace() {} {}
local dep1 = module:UseDependency(require(path.to.dep1))
local dep2 = module:UseDependency(require(path.to.dep2))

-- Turn the workspace into a node by calling it like a function:
return module()
```
This workspace already does some necessities for you, like setting `__index` of `module` to `module`.
> ### Multithreading in Nodes

Node workspaces allow you to inject Threads into the Node, enqueue functions, attach hooks, clear the queue, and more.
```luau
local Allure = require(path.to.Allure)

local module = Allure:NodeWorkspace() {} {}

local thread1, thread2 = module:Threads(2)

thread1:Enqueue(function()
  print("This is called on thread1!")

  -- Since yielding coroutines normally doesn't do the thing
  -- for yielding and queries, threads have a custom Yield:
  thread1:Yield(10)
end)

-- Threads allow you to create such functions
-- That when called, the function is automatically enqueued!
module.AsyncFunc = thread2:Function(function(self, a, b)
  return a + b
end)

return module()
```

# 📜 Dependency Trees and Loading
***Allure allows you to create, divide, slice, merge and order Dependency Trees***

Think of dependency trees as instances of loaders:
- You can have a dependency tree for services,
- an another for Packages,
- and an another for Controllers

The point is, you can apply ***different lifecycle hooks*** on different dependency trees, call different functions, order differently, and more!
> ### Basic loader methods
```luau
local Allure = require(path.to.Allure)

local tree = Allure:DependencyTree()

-- Children singletons of these folders are loaded as surface-level nodes of the tree
-- Additionally, the nodes get tagged with Instance = their modulescript
tree:LoadChildren(script.Services)
tree:LoadChildren(script.Providers)

tree:ForEach(function(node)
  node:OnInit()
end)
```
Since you can have multiple trees, the point of singletons still stands:
<br>***A modulescript node, existing in multiple dependency trees, will share all of it's contents, including metadata and <ins>tags</ins>***

> ### Slicing dependency trees
```luau
local Allure = require(path.to.Allure)

local maintree = Allure:DependencyTree():LoadChildren(script.Services)

-- Let's tag each node by how many dependencies it has
maintree:ForEach(function(node)
  node.Tags.DepCount = #node.Dependencies
end)

-- Now let's slice the tree and get a new tree with only those nodes,
-- That have more than 2 dependencies
local depTree = maintree:SlicePredicate(function(self, node)
  return node.Tags.DepCount > 2
end)

-- depTree is a different tree, but it shares nodes with maintree
-- This means exactly what you are thinking of, we can use all the
-- same loader methods on it, too:
depTree:ForEach(function(node)
  --...
end, function(node, err)
  warn("An error", tostring(err), "has occured in", node.Tags.Instance.Name)
end)
--^^ Additionally, you can list a second function for the :ForEach call
-- to act as an Error Handler!
```

## License
Allure is shared and released with the MIT License.
</br>Give me a shoutout if you want!
