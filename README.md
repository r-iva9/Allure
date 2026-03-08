<p align="center">
  <img width="500" height="250" src="https://github.com/m-at1/Allure/blob/main/images/logo.png?raw=true" alt="Logo">
</p>

<p align="center">
  <b><i>Fully Typesafe DI IoC Node & Worker Framework for Luau.<br>The loader core of the Allure Ecosystem.</i></b> </br>
  <!--<i>Inspired by -->
</p>

<h1></h1>
</br>
<div align="center">
  <a href="https://r-iva9.github.io/Allure/course/introduction/gettingstarted.html"><img width="65" height="50" src="./images/Install.png" alt="Install"></a>‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ
  <a href="https://r-iva9.github.io/Allure/"><img width="160" height="50" src="./images/Docs.png" alt="Docs"></a> <!--ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ
  a href="https://github.com/m-at1/Alloy/releases"><img width="130" height="50" src="./images/Benchmarks.png" alt="Benchmarks"></a> -->
</div>

> [!IMPORTANT]
> <h2>Allure is fresh and new</h2>
> This means that Allure possibly has some unfinished features and overlooked issues.
>
> ***Allure has a long way to go and will be tied to the Allure Ecosystem. There be dragons.***

## 📦 Installation
Install via wally:
```
Allure = "r-iva9/allure@1.1.0"
```

# 🍃 Nodes and Boilerplate

### 💠 *A Node is a singleton in your game with added overhead, suited for Allure.*

Nodes can 
  - rely on Workers,
  - be used as dependencies for other nodes,
  - be used in dependency trees,
  - be tagged,
  - inject dependencies,
  - use NodeTrees inside,
  - and more!

### Minimum boilerplate
Is none! You can successfuly use Allure without any boilerplate inside of modulescripts.
<br>But if you want to setup singletons firsthand, you can make them nodes right there:
```luau
local Allure = require(path.to.Allure)

local module = {}

return Allure:Node()(module){} ()
```

### Injecting dependencies
```luau
local Allure = require(path.to.Allure)

local module, dep1, dep2 = Allure:Node(
  require(path.to.dep1), require(path.to.dep2)
) {} {}

local dep3 = module:UseDependency(require(path.to.dep3))

return module()
```
Creating a node like this gives it the necessary additions, dependencies and *meta*.
<br>You let Allure control the overhead of your singletons, leaving you to only fill them with contents.

Nodes are suited for workflows, such as classes, with boilerplate already set up.

### Workers

Workers as a bonus feature allow you to easily use multi-threading.
<br>And not just inside of Nodes.

```luau
local Allure = require(path.to.Allure)

local module = Allure:Node() {} {}

local worker1, worker2 = module:Workers(2)

worker1:Enqueue(function()
  print("This is called on thread1!")

  -- Since yielding coroutines normally doesn't do the thing
  -- for yielding and queries, workers have a custom Yield:
  worker1:Yield(10)
end)

-- Workers allow you to create such functions
-- That when called, the function is automatically enqueued!
module.AsyncFunc = worker2:Function(function(self, a, b)
  return a + b
end)

return module()
```

# 📜 NodeTrees and Loading
***Allure allows you to create, divide, slice, merge and order Node Trees***

Think of Node Trees as instances of loaders:
- You can have a node tree for services,
- an another for Packages,
- and an another for Controllers

The point is, you can apply ***different lifecycle hooks*** on different node trees, call different functions, order differently, and more!
### Classic Framework Ignition
```luau
local Allure = require(path.to.Allure)

local tree = Allure:NodeTree()
  :LoadDescendants(script)  -- Load all descendant modules
  :ForEach(
    function(self, node)  -- Initialize them sequentially
      node:OnInit()
    end,
    function(self, node, err) -- with an error handler
      warn(node, "ran into an error during OnInit", err)
    end,
  5) -- and a yield threshold of 5 seconds
  :ForEachParallel(
    function(self, node)  -- Start them in parallel
      node:OnStart()
    end,
    function(self, node, err) -- with an error handler
      warn(node, "ran into an error during OnStart", err)
    end)
```

### Slicing, Merging, Cloning NodeTrees
```luau
local Allure = require(path.to.Allure)

local maintree = Allure:NodeTree()
  :LoadChildren(script.Services)

-- Let's tag each node by how many dependencies it has
maintree:ForEach(function(node)
  node.Tags.DepCount = #node.Dependencies
end)

-- Now let's clone the tree and slice it so it has only such nodes,
-- that have more than 2 dependencies
local depTree = maintree:Clone()
depTree:SlicePredicate(function(self, node)
  return node.Tags.DepCount > 2
end)

-- depTree is a different tree, but it shares nodes with maintree
-- We can use all the same loader methods on it, too:
depTree:ForEach(function(node)
  node:OnInit()
end, function(node, err)
  warn("An error has occured in", node.Tags.Instance.Name)
end)
```

## License
Allure is shared and released with the MIT License.
</br>Give me a shoutout if you want!

*Version 1.1.0<br>Latest edit: 03/08/26 (mm/dd/yy)*

<p align="center">
  <img width="170" height="150" src="https://github.com/m-at1/Allure/blob/main/images/shortlogo.png?raw=true" alt="Logo">
</p>
