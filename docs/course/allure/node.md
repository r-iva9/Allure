# Why Nodes?

When you componentize your game, branch modulescripts, create modulescripts, you are creating ***singletons*** in each module.
<br>In many cases, you create multiple modulescripts that require some other modulescripts to load. So they need a higher loading order.

Whenever you begin to care, there's no way to locate dependencies and other unnecessary package information in a singleton without creating custom loaders and mess.

## A Node is
> ***A singleton with additional data managed by Allure suited for loader functions***

Let Allure do all the work you need:
- Inject dependencies
- Preserve metadata of your Nodes
- Suit Nodes for Loader functions
- Tag Nodes
- Manage dependency trees
- Run your lifecycle hooks in parallel or synchronously
- And more!

## Creating your first Node

Enter a modulescript and require Allure.
<br>Don't worry, this will not create any dependency loopholes.

---

Here's the only line of boilerplate that you'll need:

```luau
return Allure:Node() {} {} ()
```

What this does, is create an empty Node.
<br>This node, despite being empty, can already be used with Dependencies, tags, as a Class, and is suited for loaders.

It looks like this:

```luau
local node = Allure:Node(dependencies) (contentTable) (meta) 

return node()
```

## Dependencies

Say, you have some service made. And you already required necessary dependencies.
<br>Create the node, while listing them:

```luau
local Allure = require(path.to.Allure)

local module = {}

local dep = require(path.to.dep)
local dep2 = require(path.to.dep2)
local dep3 = require(path.to.dep3)

function module:OnInit()
end

return Allure:Node(dep, dep2, dep3) (module) {} ()
```

These dependencies are then used where Allure needs them to be.

Additionally, if you never wanted to modify the source of your module, you can make it a Node outside:

```luau
local Allure = require(path.to.Allure)
local yourPackage = require(path.to.yourPackage)

Allure:Node() (yourPackage) {} ()
```

`:Node` creates the Node in place of the package and also returns it.

## Meta

For the second call you pass meta.
<br>Meta in Node terms is additional overhead data that Allure appends to your singleton.

```luau
local Allure = require(path.to.Allure)

local module = {}

local dep = require(path.to.dep)
local dep2 = require(path.to.dep2)

function module:OnInit()
end

return Allure:Node(dep, dep2) (module) {
    Name = "TestModule",
    SecretValue = 76234
} ()
```

Like a convention, you can save all the unnecessary data to the source code, in the meta.
<br>Like Name, Version or License.

```luau
Allure:Node() (yourPackage) {
    Name = "YourPackage",
    Version = "1.1.0"
} ()
```

## What are the benefits?

While we go through the features of Allure, we will cover more and more features that are made possible by Nodes.
<br>However even right now, using Nodes very simply, there are benefits.

For example, Allure sets `__index__` of your Node to itself automatically, for classes.

It allows you to see the dependencies via `Node.Dependencies` and tag it via `Node.Tags`

## `Allure:CountDependencies()`

While you can count *surface-level dependencies* via `#Node.Dependencies`, you can also count ***all*** dependencies, including nested ones inside of dependencies.

```luau
local dep = Allure:Node(someDep) {} {} ()
local node = Allure:Node(dep, someDep2) {} {} ()

local order = Allure:CountDependencies(node) -- [!code highlight]

print(order) --3
```

We're going to dwell into the advanced usage of Nodes next. Let's go.