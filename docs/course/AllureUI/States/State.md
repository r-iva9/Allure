# States

State machinery is fundamental to Allure.
<br>Ultimately, because almost anything can be represented as a state.

## Creating states

```luau
local garbage = Allure:garbage {}

local a = garbage:State(true)
```

In the parantheses you specify the starting initial value of the state.

## Setting and getting state values

Set the state by calling it with the new value:

```luau
local a = garbage:State(true)

a(false)
```

And get the state's value by calling `:get()`:

```luau
local a = garbage:State(true)
a(false)

print(a:get())  --false
```

## Connecting to states

Subscribing or connecting in Allure is done in a peculiar way.

To connect a `function` to a `State`, call the `:connect` method on it twice:
> 1. Give the `name` of the connection <br>
> 2. Give the connection itself

```luau
local a = garbage:State(true)

a:connect("myconn")(function(self)
    print("Value has changed")
end)
```

::: code-group

```luau [Example]
a:connect("onset")(function(self)
    print("New value:", self:get())
end)

a(100) --New value: 100
```

:::

Why is this needed? <br>
Well, because we can now disconnect the function without having to know it whatsoever:

```luau
a:connect "myconn"(nil)
```
(The parantheses for the first call can be removed)

## Don't want a connection key?

Simply pass nothing the first time you call `:connect`

```luau
local a = garbage:State(true)

a:connect()(function(self)
    print("Value has changed")
end)
```

The key is not omitted - it's now identical to the `function` itself. <br>
And to disconnect it, we now need that key, a reference to that function which we didn't make. Oops.