# Amplified Tables

We covered setting a key to a value, the correlation key = state = value, special values that act as connections.

## Table values

Amplified Tables are suited for your workflow.

Whenever you add a non-key table into an amplified, it's *merged* with the amplified itself.

```luau
local myamp = main:Amplify {
    value = main:State(100),

    {
        name = "text",
        added = main:State(true)
    }
}

print(myamp.added:get())
print(myamp.name)
```
::: code-group
```luau [Output]
true
text
```
:::

This can act in any way like a stylesheet:

```luau
local stylesheet = {
    styleText = "Welcome",
    styleColor = Color3.new(1, 1, 1)
}

local amp1 = main:Amplify {
    value = main:State(100),

    stylesheet
}

local amp2 = main:Amplify {
    value = main:State(false),

    stylesheet
}

print(amp1.styleText)
print(amp2.styleColor)
```
::: code-group
```luau [Output]
Welcome
1, 1, 1
```
:::

Whatever is in the stylesheet now exists across both amplifieds, `amp1` and `amp2`.

## Amplified Tables as values

Amplifieds are a state, which means the magic will apply to amplifieds as values, too.

```luau
local amp = main:Amplify {
    value = main:State(false),

    inneramp = main:Amplify {
        value = main:State(100),
    }
}

print(amp.value:get())
print(amp.inneramp.value:get())
```
::: code-group
```luau [Output]
false
100
```
:::

They're not merged with the outer amplified, but exist as tables within, that also call connections.

## Function values

Amplifieds will call all function values inside of it.

```luau
local amp = main:Amplify {
    value = function()
        return main:State(100)
    end
}

print(amp.value:get())
```
::: code-group
```luau [Output]
100
```
:::

The main purpose of this is referencing other keys.
<br>All functions are called with the `self` parameter:

```luau
local amp = main:Amplify {
    count = 1,

    text = function(self)
        return "Count:" .. self.count
    end
}

print(amp.text)
```
::: code-group
```luau [Output]
Count: 1
```
:::

## Race Conditions

There's no presupposition that the function will be called before `self.count` is assigned.

To battle those race conditions, merged tables are rethought of as *orders*.

Specifically, you can wrap something in a table, and that table will be merged with the outer amplified on the next order.

```luau
local amp = main:Amplify {
    count = 1,

    {
        text = function(self)
            return "Count:" .. self.count
        end
    }
}

print(amp.text)
```
::: code-group
```luau [Output]
Count: 1
```
:::

You can nest any amount of orders inside of Amplfieds.