# States: low-level

## Updater

You already know that the updater is the connection hook.
<br>Calling `:updater()` will call all connections. But only by default.

Allure lets you change the updater the same way as setter and deleter:

```luau
local a = trash:State(0)
    :updater(function(self, connections)
        for key, fn in connections do
            fn(self)
        end
    end)
```

Whenever you call `:updater()`, the actual *updater* is called with the connections given.

Now this gives us the ability to *select* connections we need by their key.

## Deleter

Anything in Allure can be integrated with garbage collectors.
<br>So anything can be cleaned up in some way.

As you know, garbage collectors upon cleanup delete Allure objects.
<br>And now, you can control that!

```luau
local a = trash:State(0)
    :deleter(function(self)
        print("The state is cleaned up")
    end)
```

Allure will always delete the object automatically, though, you can hook this function to that process.
<br>An object's `deleter` will always be called before the actual procedural deletion.

::: code-group
```luau [Example]
local trash = Allure:garbage {}

trash:State(100)
    :deleter(function(self)
        print("mess is cleaned")
    end)

trash() --mess is cleaned
```
:::

---

Summing up updaters and deleters, we get the following for the default State:

```luau
local a = trash:State(0)
    :deleter(function(self)
        --The default deleter is an empty function!
    end)
    :updater(function(self, connections)
        for key, fn in connections do
            fn(self)
        end
    end)
```