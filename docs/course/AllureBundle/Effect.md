# Effect

Effect is such a state that holds a calculation, which depends on select states and recalculates whenever those states meaningfully change.

---

Syntax:

```luau
local a = main:State(100)

local comp = main:Effect(function(with, innergarbage)
    return with(a) + 100
end)
```

Practically identical to Computed.

## It's important to know the difference

- ***Computed*** updates itself only if you call `:get()`, and then if the states it depends on did actually change.

- ***Effect*** updates itself whenever any of the states it depends on changes.

So let's take a look:

::: code-group
```luau [Computed]
local a = main:State(100)

local comp = main:Computed(function(with, innergarbage)
    print("Recalculation occured")
    table.insert(innergarbage, function()
        print("Recalculation ending")
    end)

    return with(a) + 100
end)

print("Start")
comp:get()

print("Setting")
a(200)

print("Getting")
comp:get()
```
```luau [Output]
Start
Recalculation occured
Setting
Getting
Recalculation ending
Recalculation occured
```
:::

::: code-group

```luau [Effect]
local a = main:State(100)

local effect = main:Effect(function(with, innergarbage)
    print("Recalculation occured")
    table.insert(innergarbage, function()
        print("Recalculation ending")
    end)

    return with(a) + 100
end)

print("Start")
effect:get()

print("Setting")
a(200)

print("Getting")
effect:get()
```

```luau [Output]
Recalculation occured
Start
Setting
Recalculation ending
Recalculation occured
Getting
```
:::

## Example

We're going to think `component-wise`, providing examples as real components - modules that return reproduction functions of reusable parts of the UI.

```luau
return function(
    garbage,
    scaled: Allure.State<boolean>,

    props: {}?
)
    return garbage:New "Frame" {
        Size = garbage:Effect(function(with, inner)
            return with(scaled) and Udim2.fromScale(0.6, 0.4) or Udim2.fromScale(0.3, 0.2)
        end),
        --...,

        props
    }
end
```

We created a component that needs a `scaled` state.
<br>It returns a frame, the size of which depends on that `scaled` state.

Notice that passing `props` immediately lets the higher-up components pass anything, such as children, stylesheets, states, etc.
<br>More about how Allure helps you in componentization and reusability you can see in the Practices section. But as of right now, we're covering AllureBundle.