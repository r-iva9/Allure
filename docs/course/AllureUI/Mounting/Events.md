# Mounting

We covered `:mount(object, amplified)` - a `mount` object, and children - Instances as values without keys.

## Classic Signals

Connecting functions to signals in Allure is done via a yet another ***special value***, `Allure.onEvent`.

```luau
local amplified = main:mount(object, main:Amplify {
    Name = "Button",
    Text = "Click me!",

    myevent = Allure.onEvent "MouseButton1Click" (function(self, object, ...)
        self.Text = "Don't click me!"
    end)

}, function(self, amplified, object)
    --Remember the return function? We need the amplified
    
    return amplified
end)
```

When the signal fires connections, the function is called firstly with the amplified, then with the object it's mounted to, then with additional arguments passed by the signal.

That key is optional.
<br>It's simply easier to disconnect the event by setting it to nil:
```luau
amplified.myevent = nil
```
And it will disconnect itself.

## Tracking changes

The `:GetPropertyChangedSignal(property)` is encapsulated as a different *special value*: `Allure.onChange`.

```luau
local amplified = main:mount(object, main:Amplify {
    Name = "Button",
    BackgroundTransparency = 0.5,

    myevent = Allure.onChange "Text" (function(self, object, ...)
        print("Somebody changed the text!")
    end)

}, function(self, amplified, object)
    return amplified
end)
```

---

Let's repeat the syntax for all special values:

```luau
myevent = Allure.onSet "Value" (function(self)
    print("Value was changed")
end)

myevent = Allure.onEvent "MouseButton1Click" (function(self, object, ...)
    self.Text = "Don't click me!"
end)

myevent = Allure.onChange "Text" (function(self, object, ...)
    print("Somebody changed the text!")
end)
```

---

And that's it for AllureUI!<br>
This library mainly was focused on state machinery, so for the actual useful stuff and derivations take a look at AllureBundle.