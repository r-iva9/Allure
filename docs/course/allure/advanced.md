# Advanced Nodes

You might've noticed, I haven't explained the last call after meta.

```luau
local node = Allure:Node(deps) {content} {meta} ()
```

This call *finalizes* the node and packs everything together.
<br>Before we finalize the node, we have a lot of stuff we can do. That gives us the advanced usage of Nodes.

## `Usage`

You are recommended to create the node, and finalize it as the last line of your modules:

```luau
local node = Allure:Node() {} {}

return node()
```

The returned result of such, is a very interesting construction.
<br>I sometimes call it a half-node, or a node workspace if you will.

At this step it has already defined hidden meta, meta, dependencies, etc.

---

It does not only return the half-node, but also throws back your dependencies:

```luau
local node, React, Promise = Allure:Node(
    require(path.to.React),
    require(path.to.Promise)
) {} {}

return node()
```

In the exact same order.
<br>***All of them are kept fully type-safe.*** Including the node, just look:

```luau
local node, React = Allure:Node(require(path.to.React)) {} {}

function node:OnInit()
end

return node()
```

This function, OnInit, <ins>*has been catched*</ins> by the type solver, because `node` is an unsealed table, *it's fully typesafe.*
<br>The finalization, `node()` also entirely keeps it typesafe.

## Injecting dependencies via `:UseDependency`

We're starting to go over the utilities given within the half-node.
This is not just a table, or your content table with meta, it's a big construction with utilities.

Inject a dependency by simply calling the function:

```luau
local node, React = Allure:Node(require(path.to.React)) {} {}

local Promise = node:UseDependency(require(path.to.Promise))

function node:OnInit()
end

return node()
```

This utility function present is in no way messing up your content table and meta. It just exists there as an addon.

## References

`node.Meta` references the meta, if you've needed the reference:

```luau
local node = Allure:Node() {} {
    Name = "MyNode"
}

local Promise = node:UseDependency(require(path.to.Promise))

node.Meta.Name = "NotMyNode" 

function node:OnInit()
end

return node()
```

---

`node.HiddenMeta` is a peculiar sight. This table is also meta, but it does not appear in the end type of the node, and it originally is set by Allure:
```luau
{
    Dependencies = {...},
    Tags = {
        Priority = Allure:CountDependencies(...)
    }
}
```

When you finalize the node it also becomes a part of the node.

And before that, you can already reference the contents remotely:

```luau
print(node.Tags.Priority)
```

The reference chain is as so:

```luau
Content -> Utilities -> Meta -> HiddenMeta
```

The resultant node has the type

```luau
Content & Meta
```

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