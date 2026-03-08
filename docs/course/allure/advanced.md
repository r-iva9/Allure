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

This utility function being present is in no way messing up your content table and meta. It just exists there as an addon while you are making the node.

## References

`node.Meta` references the meta, if you've needed the reference:

```luau
local node = Allure:Node() {} {
    Name = "MyNode"
}

local Promise = node:UseDependency(require(path.to.Promise))

print(node.Meta.Name) -- [!code highlight]

function node:OnInit()
end

return node()
```

Actually, we can already reference `Name` from Meta normally via

```luau
print(node.Name)
```

So this is starting the reference chain:

```luau
Content -> Meta
```

We've also got utilities here:

```luau
Content -> Utilities -> Meta
```

---

`node.HiddenMeta` is a peculiar sight. This table is also meta, but it does not appear in the end type of the node, and it originally is made by Allure:
```luau
{
    Dependencies = {...},
    Tags = {
        Priority = Allure:CountDependencies(...)
    }
}
```

When you finalize the node it also becomes a part of the node.

And before that, you can also reference the contents remotely:

```luau
print(node.Tags.Priority)
```

So we're continuing our reference chain:

```luau
Content -> Utilities -> Meta -> HiddenMeta
```

`node.HiddenMeta` can be useful when you need a secret to hide from the typesolver, or just modify whatever Allure set up.

## Tagging

As you've seen, Tags are within `HiddenMeta`, so to tag an instance, create a new tag within `node.HiddenMeta.Tags`.
<br>But we all need shortcuts.

Add or change a tag:
```luau
local node = Allure:Node() {} {}

node:Tag("Children", 10)
node:Tag("Instance", script)

node:Tag("SomeTagForRemoval", nil)

return node()
```

Get a tag:
```luau
local node = Allure:Node() {} {}

node:Tag("Children", 10)
node:Tag("Instance", script)

print(node:GetTag("Children")) --10

return node()
```

## Metatables

Skip this part, if you're unfamiliar with metatables.

You could tell, these utilities and the reference chain is achieved via metatables.
<br>Setting a metatable for our node, to appear after finalization becomes a challenge.

No more: finalization sets the metatable to a specific value, originally `nil`.

This value can be modified via our utilities, again:

Setting the metatable of the future node:
```luau
local node = Allure:Node() {} {}

node:UseMetatable {
    __index = rawget,
    __newindex = rawset
}

return node()
```

Overriding it in bulk:
```luau
local node = Allure:Node() {} {}

node:UseMetatable {
    __newindex = rawset
}

node:OverrideMetatable {
    __index = {
        Calculate = function(self, a, b) end
    },
}

return node()
```

Getting it:
```luau
local node = Allure:Node() {} {}

node:UseMetatable {
    __newindex = rawset
}

local mt = node:GetMetatable()

return node()
```

This metatable ***is not present before finalization*** and will be applied only upon then.