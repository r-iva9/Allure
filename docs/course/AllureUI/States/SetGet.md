# States: low-level

Let's lower the level.
<br>This carries a learning curve, but that's the point - *you can skip this if you don't need it!*

---

# Getter

## Initial value of the state

Any state at any point has a value inside of it.
<br>That value is encapsulated by multiple layers of the State, one of which is the getter.

However, just as you have `rawget` to get the actual value of a table's key,
<br>In Allure you have `Allure.get`:

```luau
local a = trash:State(0)

print(Allure.get(a)) --0
```

The same exists for `rawset` in this analogy: `Allure.set(state, value)`

```luau
local a = trash:State(0)

Allure.set(a, 10)

print(a:get()) --10
print(Allure.get(a)) --10
```

How is this different from `:get()` and simply calling the state?

It uses the *actual* value of the State. You will see the difference in a moment.

## `:getter()`

Whenever you call `:get()` on a State, you don't get it's value, you call the *getter*.

Allure gives us the opportunity to modify state getters.

```luau
local a = trash:State(0)

a:getter(function(self)
    return 10
end)
```

You can nest these methods:

```luau
local a = trash:State(0)
    :getter(function(self)
        return 10
    end)
```

And so, we will now get:

```luau
print(a:get()) --10
```

This is not the actual value of the state.

You might've figured out, the *default getter* of any State, is this:

```luau
local a = trash:State(0)
    :getter(function(self)
        return Allure.get(self)
    end)
```

> [!CAUTION]
> Calling `:get()` inside of `:getter(...)` will cause standard recursion.

# Setter

## State connection hook

Whenever you connect a function to a state, like

```luau
local a = trash:State(0)

a:connect("name")(somefunction)
```

You are adding that function as a value to some table with that key.
<br>All of the functions in that table are called when the value changes. But wait!

That call only happens inside of some layer whenever you're setting the state *normally*.

```luau
local a = trash:State(0)

a:connect("name")(function(self)
    print("New value:", self:get())
end)

a(10)
a(100)

Allure.set(a, 1000)
Allure.set(a, 10000)
```

::: code-group
```luau [Output]
New value: 10
New value: 100
```
:::

As you can clearly see, setting the value directly does not call the connection hook.

Going a bit further, Allure allows you to call the connection hook no matter the conditions:

```luau
a:updater()
a:updater()
```
::: code-group
```luau [Output]
New value: 10000
New value: 10000
```
:::

## :setter()

The same way, whenever you call a State, you don't set it's value, you call the *setter*.

Change the setter of a state like so:

```luau
local a = trash:State(0)
    :setter(function(self, value)
        Allure.set(self, 10)
        return value
    end)
```

This will not call the connection hook, but set the actual value of a state to 10.

You might've figured it out, the default setter of any State is this:

```luau
local a = trash:State(0)
    :setter(function(self, value)
        Allure.set(self, value)
        self:updater()
        return value
    end)
```

It sets the actual value and calls the hook.

Passing `nil` in `:setter()` will make the State read-only.

```luau
local a = trash:State(0)
    :setter(nil)

a(10)
a(100)

print(a:get()) --0
```

---

Summing the default setter and getter for a state, we get

```luau
local a = trash:State(0)
    :getter(function(self)
        return Allure.get(self)
    end)
    :setter(function(self, value)
        Allure.set(self, value)
        self:updater()
        return value
    end)
```

You can nest these methods like so.

## Setter Memoization

The default setter of any State in Allure actually performs memoizing, however only *single-item memoization*.

So the default setter actually looks like this:

```luau
local a = trash:State(0)
    :setter(function(self, value)
        if value == Allure.get(self) then
            return value
        end

        Allure.set(self, value)
        self:updater()
        return value
    end)
```

So whenever you call

```luau
a:connect()(function(self)
    print(a:get())
end)

a(100)
--...
a(100)
```
::: code-group
```luau [Output]
100
```
:::

It will only call the connection hook once.

You can add actual memoization with a *[custom attribute](./Custom.md)*, somewhat along the lines of

```luau
--fn = some function

local a = trash:State(0)
    :custom "memo" {}
    :setter(function(self, value)
        if self.memo[value] == Allure.get(self) then
            return self.memo[value]
        end

        self.memo[value] = self.memo[value] and self.memo[value] or fn()

        Allure.set(self, self.memo[value])
        self:updater()

        return self.memo[value]
    end)
```

Technically, this is how a computed state value is supposed to work.
<br>Actual computeds for high-level people are defined in `AllureBundle` with Fusion inspired syntax.