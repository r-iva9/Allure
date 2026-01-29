# Computed

Computed is such a state that holds a calculation, which recalculates only if you need the value, and if the dependencies did meaningfully change.

---

The syntax is similar to that of Fusion:

```luau
local a = main:State(100)

local comp = main:Computed(function(with, innergarbage)
    return with(a) + 100
end)
```

## `with()`

Connects the computed state to recalculate and update if any of states passed meaningfully update.

It returns the values in order, no matter if they're a state or not:

```luau
local amount, length, description, owner = with(amountState, 100, "text", ownerState)
```

The computed will recalculate if `amountState` or `ownerState` get an update.

## `innergarbage`

This is a garbage created inside of `main`, the garbage which you create the computed into.

Innergarbage is always cleaned when a recalculation occurs. For example:

```luau
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

::: code-group
```luau{5} [Output]
Start
Recalculation occured
Setting
Getting
Recalculation ending
Recalculation occured
```
:::

> [!NOTE]
> Computed solves only when you get it's value.<br>
> If the dependencies change and you don't need it's value, there's no point to recalculate.

## About it

This Computed is just a modified State. <br>
Which means it can be connected to, set the value of, allows us to get it's value, etc.

```luau
local state = main:State(100)

local comp = main:Computed(function(with, inner)
    return with(state) + 25
end)

print(comp:get()) --25
```

Allure optimizes the Computed in such a way that it doesn't operate until it is needed.
<br>It will only calculate it's first value whenever you first call `:get()`.

> [!NOTE]
> Computed solves only when you get it's value.<br>
> If the dependencies change and you don't need it's value, there's no point to recalculate.<br>
> It is discouraged to use Computed for Amplifieds, since it updates only whenever the value is gotten.

---

It will not rerun whenever you get it's value again without any dependencies (states that it depends on) changing.

```luau
local state = main:State(100)

local comp = main:Computed(function(with, inner)
    print("Recalculating!")
    return with(state) + 25
end)

comp:get()
print(comp:get())
print(comp:get())

state(150)

comp:get()
print(comp:get())
print(comp:get())
```
::: code-group
```luau [Output]
Recalculating!
125
125
Recalculating!
175
175
```
:::