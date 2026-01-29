# States: low-level

Finally, the last bit of customization available for states, are custom attributes.

## `:custom()`

Just as `:connect()`, the first call should pass the name of the attribute, and the second one should pass the value itself.

```luau
local a = trash:State(100)
    :custom("history")({})
```

Customs will not let you override default State methods like `:get()` or `:setter()`

Just as with other methods, you can nest anything:

```luau
local a = trash:State(100)
    :custom("history")({})
    :setter(nil)
    :custom("name")("")
```

Unnecessary brackets can be lifted for syntactic sugar:

```luau
local a = trash:State(100)
    :custom "history" {}
    :setter(nil)
    :custom "name" ("")
```

## The Default State

Let's collect everything we just covered on state customization.

```luau
local a = trash:State(100)
    :getter(function(self)
        return Allure.get(self)
    end)
    :setter(function(self, value)
        if value == Allure.get(self) then
            return value
        end
        Allure.set(self, value)
        self:updater()
        return value
    end)
    :updater(function(self, connections)
        for key, fn in connections do
            fn(self)
        end
    end)
    :deleter(function(self)
        return
    end)
    :custom("example")(nil)
```

You don't have to do anything out of this;
<br>All of this already is preset in the default State.