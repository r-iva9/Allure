# Amplified Tables

We covered changing a key to `Allure.onSet` and tracking changes for specific and nonspecific keys.

## State Keys

An amplified itself is a state table!
<br>It tracks anything inside of it.

So a normal key, or a state key, it literally does not matter!

```luau
local state = main:State(100)

local myamplified = main:Amplify {
    value = state,

    onvalue = Allure.onSet "value" (function(self)
        print("value changed to", self.value)
    end)
}

state(500)

-- We are referencing the state
myamplified.value(100)

-- We are removing the state from the key -- value's no longer a state, it's 10.
myamplified.value = 10

-- state is not tied to the value; the state will change, the key will not.
state(100)
```
::: code-group
```luau [Output]
value changed to 500
value changed to 100
value changed to 10
```
:::

We literally connected an amplified's key to a state, and disconnected it.
For an amplified it entirely does not matter if the key's a state or a value.

In all of those cases it also calls the connections.

## Unique state values

Take notice: if we change a state, we change the amplified's key.

But that means we can set the state to whatever `Allure.onSet` gives us!

```luau
local state = main:State(nil)

local myamplified = main:Amplify {
    value = 100,

    onvalue = state
}

myamplified.value = 10
myamplified.value = 25

state(
    --self is not state, self is the Amplified
    Allure.onSet "value" (function(self)
        print("value changed to", self.value)
    end)
)

myamplified.value = 50
myamplified.value = 75

state(
    nil
)

myamplified.value = 100
```
::: code-group
```luau [Output]
value changed to 50
value changed to 75
```
:::

The state now literally cares for the `onSet` connection.
<br>This means we can set-up a state to connect some connections whenever it is true, and remove them whenever it is false.