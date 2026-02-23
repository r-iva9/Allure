# What is a Node?

When you componentize your game, branch modulescripts, create modulescripts, you are creating ***singletons*** in each module.
<br>In many cases, you create multiple modulescripts that require some other modulescripts to load. So they need a higher loading order.

Whenever you begin to care, there's no way to locate dependencies and other unnecessary package information in a singleton without creating custom loaders and mess.

## A Node is
> ***A singleton merged with metadata handled by Allure***

Let Allure do all the work you need:
- Inject dependencies
- Preserve custom metadata for your singletons, like
    - Tagging nodes
    - Name
    - Version 
    - Description

## Creating your first Node

Enter a modulescript and require Allure.
<br>Don't worry, this will not create any dependency loopholes.

---

Here's the only line of boilerplate that you'll need:

```luau
return Allure:Node() {} {}
```

What this does, is create a Node.
<br>Your singleton will be observed and merged with whatever Allure needs.

But what is the point of the syntactical sugar function calls right after?
### This is the content and metadata of your Node.

It looks like this:

```luau
local node = Allure:Node(dependencies) (contentTable) (metadataTable)
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

function module:onInit()
end

return Allure:Node(dep, dep2, dep3) (module) {}
```

These dependencies are then used where Allure needs them to be.

## Metadata

The last call is the metadata. What is this for?
<br>Here you can list the Name, Version, Description, License, Author and many other values so unnecessary that you can leave them be ***readonly***.

```luau
local Allure = require(path.to.Allure)

local module = {}

local dep = require(path.to.dep)
local dep2 = require(path.to.dep2)

function module:onInit()
end

return Allure:Node(dep, dep2) (module) {
    Name = "MyModule",
    Version = "1.0.0",
    Description = "Example module"

    SecretValue = 76234
}
```

Allure fills the rest by itself, if you leave them blank.

Don't need the unnecessary Name, Version, Description, License overhead? 
<br>No problem: use `ZeroNodes`

```luau
local Allure = require(path.to.Allure)

local module = {}

local dep = require(path.to.dep)
local dep2 = require(path.to.dep2)

function module:onInit()
end

return Allure:ZeroNode(dep, dep2) (module) {
    SecretValue = 76234
}
```

This merges your Node with only the obligatory and required metadata that Allure strictly needs to function.