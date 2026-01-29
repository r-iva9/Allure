# Mounting

You created `prop tables` in other UI frameworks to `mount` them on Instances.
<br>In allure, amplifieds have multiple roles and shape entire workflows. But their primary use - is mounting on an instance.

## `:mount()`

Mounting in Allure is also tied to garbage collection.
<br>Uniquely - in Allure mounting generates a "mount" object, it's the connection between an Amplified and the object.

Whenever the `mount` object is deleted, the object and the Amplified are kept, but they're not connected.

```luau
local object = Instance.new("Frame")

main:mount(object, main:Amplify {
    Name = "My Frame"
})
```
The first parameter is the instance, second is the amplified itself.

Now, the `name` of that frame is set to My Frame.

---

Whenever an amplified table is mounted on an instance, lots of things happen.
<br>Mainly, the properties are applied.

But Allure does not bound you: you're **not** supposed to have keys match properties.

```luau
main:mount(
    Instance.new("Frame"), main:Amplify {
        Name = "My Frame",
        value = 100
    }
)
```

Whenever a key does not match a property, nothing happens.
<br>You need optimization? Allure *memoizes* that fact and does not recheck if the key is compatible again, whenever you change that key.

## Connections

The `mount` object actively connects the Amplified to the Instance.
<br>Whenever anything occurs within the Amplified, `mount` is the first to react.

```luau
local amp = main:Amplify {
    Name = "My Frame"
}

main:mount(object, amp)

amp.Name = "Template"
```

The name of the frame will change.

---

```luau
local name = main:State("My Frame")

local amp = main:Amplify {
    Name = name
}

main:mount(object, amp)

name("Template")
```

The name of the frame will change.


## Returning

That's not all - Allure allows you to control whatever the mount operation should return.

To do so, attach a function as the third parameter. `:mount` returns whatever the function returns.

```luau
local name = main:State("My Frame")

local amp = main:Amplify {
    Name = name
}

object = main:mount(object, amp, function(self, amplified, object)
    return object
end)

name("Template")
```

Since the function is called with 3 parameters: the `mount` object itself, the amplified, the instance,
<br>It allows you to get the mount object.

The main advantages of having the mount object, is the ability to delete it, the reference to the amplified and one to the object that it connects.

The object secretly contains a `.__deleter` function inside; properties `.Amplified` and `.Object`.

## Remounting

Unlike other UI libraries, AllureUI does not think of mounting as a one-way trip, it's the opposite, some kind of decoupled process that can happen on it's own.

That brings us to mounting multiple amplifieds on the same object, multiple objects to the same amplified, and more cases out there.

```luau
local object = Instance.new("Frame")

local amp1 = main:Amplify {
    Name = "Menu"
}

local amp2 = main:Amplify {
    Name = "Board"
}

main:mount(object, amp1)
```

The name of the frame is Menu.

```luau
main:mount(object, amp2)
```

The name of the frame is now Board.

```luau
amp1.Name = "Frame"
amp2.Name = "Label"
```

Now it'll change to Frame and then to Label.

You can tell, the `mount` objects are "fighting" over the object.
<br>All updates and connections across both amplifieds are applied.

## Lifetime

The `mount` function looks like this:

`.mount(garbage, object, amplified, returns)`

The `garbage` parameter we used to give by simply calling `:mount` as a method on garbage collectors, and the `returns` param is optional.

However there's a fifth, also optional one: AllureUI allows you to attach *lifetime functions* to the `mount` object.
<br>This function will be called asynchronously and killed when the mount object is destroyed.

```luau
local amp1 = main:Amplify {
    Name = "Menu"
}

main:mount(object, amp, nil, function(self, amplified, object)
    while task.wait(1) do
        --...
    end
end)
```

---

Collectively:

`.mount(garbage, object, amplified, returns, lifetime)`