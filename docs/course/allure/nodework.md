# Node Workspaces

You might've noticed, `:Node` is the last function to be used.
It's not recommended to modify the Node after that.

However, if you've ever felt the need for some utilities to aid you or simply the mutatibility of the Node and metadata in the process, we have a solution.

## `:NodeWorkspace`

Since Nodes are fully-fledged and ***finished*** singletons, we can't create a Node and then modify it right there. 
<br>We need a workspace that can then turn itself into a Node.

```luau
local Allure = require(path.to.Allure)

local module = Allure:NodeWorkspace() {} {} -- [!code highlight]

function module:onInit()
end

-- Finish the creation of the Node by calling it like a function
-- This is also typesafe
return module() -- [!code highlight]
```

Now, the module itself is created by Allure.
<br>Notice, that it ***fully remains typesafe***!

Additionally, Allure helps you, for example in cases, for whenever you're making a Class: it already sets `__index` of your table to itself.

## Dependencies

In the same way, you can list dependencies, but now, you can do that **during** the creation of the Node, and **at the start**:

***They're returned along with the Node, if you've passed them into the first function***
```luau
local module, dep1, dep2 = Allure:NodeWorkspace( -- [!code highlight]
    require(path.to.dep1), require(path.to.dep2) -- [!code highlight]
) {} {} -- [!code highlight]

function module:onInit()
end

return module()
```

***They can be injected later:***
```luau
local module, dep1 = Allure:NodeWorkspace(
    require(path.to.dep1)
) {} {}

local dep2 = module:UseDependency(require(path.to.dep1)) -- [!code highlight]

function module:onInit()
end

return module()
```
This entirely keeps type safety and the types of dependencies.

## Presets

The content table and metadata you pass into `NodeWorkspace` remains there, you create both tables yourself, and then mutate them.
<br>So you can pass something default, like values or secret values

```luau
local module, dep1 = Allure:NodeWorkspace(require(path.to.dep1)) {
    a = 10,
    onInit = function(self)
        print("Module initialized")
    end
} {
    Name = "exampleModule",
    License = "MIT",

    secret = 10,
}

return module()
```

Literally didn't have to use the modulescript normally in this case, I could just do this:

```luau
return Allure:Node(require(path.to.dep1)) {
    a = 10,
    onInit = function(self)
        print("Module initialized")
    end
} {
    Name = "exampleModule",
    License = "MIT",

    secret = 10,
}
```

# Some utilities are also given

You might've noticed that I've used `module:UseDependency`
<br>And no, this function does not exist in the module after creating the node. Not even in the (`nil`) metatable.

So let's cover some other utilities that `NodeWorkspace` gives you

## `.Meta`

If you lost the metadata table, this is the direct reference

```luau
local module = Allure:NodeWorkspace() {} {a = 10}

module.Meta.a += 10
```

## `:ModifyMeta`

You can change the meta in bulk, with a table:

```luau
local module = Allure:NodeWorkspace() {} {a = 10}

module:ModifyMeta {
    b = 100,
    Name = "Module",
    Version = "1.0.1",

    a = module.Meta.a + 20
}
```

## `:GetDependencyCount`

This is one of the most usable utilities that Allure gives you.
<br>This function counts *ALL* dependencies, even dependencies inside of dependencies.

```luau
local module = Allure:NodeWorkspace() {} {a = 10}

module.Tags.AmountDependencies = module:GetDependencyCount()
```

## `:SetPriority`

Usually Priority is a Tag that Allure presets immediately during Node creation.
<br>And it's set by default to `-node:GetDependencyCount()`

But since priority is just a tag, this is just shorthand to changing it.
```luau
local module = Allure:NodeWorkspace() {} {a = 10}

module:SetPriority(-10)
module.Tags.Priority += 10
```

## `:Zero`

If you're in favor of creating nodes without useless metadata, you can use this function to finish, create the node instead of calling the workspace as a function:
```luau
local module, dep1 = Allure:NodeWorkspace(
    require(path.to.dep1)
) {} {
    Name = "Test"
}

local dep2 = module:UseDependency(require(path.to.dep1))

function module:onInit()
end

return module:Zero()
```