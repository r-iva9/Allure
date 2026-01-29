# Mounting

We covered that `:mount(object, amplified)` generates a `mount` object - the connection between an Amplified and the object - into the garbage collector.

## Children

But now, that an Amplified is actively connected to an Instance, lots of new benefits arise.

Firstly, Instance values *without a key* are appended as children.

```luau
main:mount(object, main:Amplify {
    Name = "Object",

    Instance.new("TextButton"),
    Instance.new("Frame"),
})
```

The textbutton and frame will appear under the object.

<div class="custom-block tip" style="padding-top: 8px">
Waiting for your garbage:New for instances? Just you wait - we have a lot more to cover in AllureBundle.
</div>

This certainly applies to states:

```luau
local child = main:State(nil)

main:mount(object, main:Amplify {
    Name = "Object",

    child
})

child(Instance.new("TextButton"))
```

And to any kind of values amplifieds can have.

## Reproduction functions

Stylesheets can obviously have instances.

But the problem is - we're applying the *same* stylesheet to multiple amplifieds. And if that stylesheet has instances, those instances will get *reparented* throughout the 2 objects the amplifieds are mounted on.

However, functions are always called whenever they're added as a value.<br>
So we can simply have a function that *produces* an instance whenever it is applied:

```luau
local main = Allure:garbage {}


local stylesheet = {
    BackgroundColor3 = Color3.new(0.3, 0.7, 1),

    -- The "reproduction" function
    function(self)
        return Instance.new("TextButton")
    end
}

local amp1 = main:Amplify {
    Name = "Menu",

    stylesheet
}

local amp2 = main:Amplify {
    Name = "Label",

    stylesheet
}
```

Now these amplifieds have 2 unique textbuttons.