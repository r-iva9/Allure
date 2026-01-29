# Garbage Collectors

No matter what you're doing in Roblox Studio, you're dealing with objects and tasks.

When you connect to a `RBXScriptSignal`, design a frame, or even desynchronize functions, you're creating *objects* that have to be deleted, cleaned up in some way in some future.

## Garbage Collectors are containers that can cleanup their contents.

In allure, cleanup is simply some overhead added to some table.

You can entirely continue using the table as usual, but now with cleanup functionality.

```luau
local trash = Allure.garbage()
```

## Cleanup

Cleanup deletes, cleans up all of the insides of the table.
<br>It calls functions, nullifies normal values, disconnects RBXScriptConnections, destroys *States* and other Allure objects.

For cleanup, simply call the garbage collector:

```luau
trash()
```

After cleanup, the garbage collector can **still be used** just as fresh.

## Methods

Whatever you list inside of the parantheses will be *indisposable* and added to the `garbage collector`.

`Allure` itself is a table, so we can use it, along with an additional table:

```luau
local trash = Allure:garbage {insert = table.insert}

trash:insert(function()
    print("cleanup was called!")
end)

trash() --cleanup was called!
```


The ( ) parantheses in this case can be omitted.
<br>

> [!CAUTION]
> Inserting the garbage collector into itself,
> ```luau
> trash:insert(trash)
> ```
> Will cause recursive cleanup on `trash()`. <br>
> 
> But Allure has cared about this case: recursive cleanup will only occur **6** times. <br>
> You may change this value in the Config.

## Garbage inside of Garbage

Allure itself is a table, and it has the `garbage` function. <br>
So it's a method and we can use it.

And so we can simply use it on our `trash`:

```luau
local innertrash = trash:garbage(Allure)
```

This will create a garbage *inside* of `trash`. It will be cleaned when `trash` is cleaned:

::: code-group

```luau [Example]
innertrash["mess"] = function()
    print("mess is cleaned")
end

trash() --mess is cleaned
```

:::