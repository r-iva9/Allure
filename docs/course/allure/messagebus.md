# Message Bus Architecture

We can have Masters, we can have Workers, we can have Factories, we need the message bus.
<br>A message bus is the communication provider between your modules. I'll try to realize some models like Publish/Subscribe. 

None of this is boilerplated! This is only to give you an idea of what's easy with Allure.

## Event Driven

If we're realizing a message bus for this, then we need a simple module through which I can communicate a task and some arguments.

```
📜Main.server.luau 
  ├─📦MessageBus.luau 
  └─📂Modules
      ├─📦Calculator.luau 
      └─📦Multiplicator.luau 
```
::: code-group
```luau [MessageBus.luau]
local Allure = require(path.to.Allure)

local module = Allure:NodeWorkspace() {} {
    Name = "Message Bus"
}

local Tree = nil :: any

-- We need initialization with the tree 
-- because we can't cause a dependendy cycle
function module:OnInit(tree: Allure.NodeTree)
    Tree = tree
end

function module:Event(serviceName: string, taskName: string, ...)
    assert(Tree, "Message Bus not initialized!")
    return Tree
        :SlicePredicate(function(self, node) --Get nodes by name
            return node.Name == serviceName 
                or node.Tags.Instance.Name == serviceName
        end)
        .Tree[1][taskName](...) --Call the task
end 

return module()
```
:::
Then we have a simple boostrapper:

::: code-group
```luau [Main.server.luau]
local Allure = require(path.to.Allure)

local tree = Allure:NodeTree()
    :LoadDescendants(script)
    :ForEach(function(self, node)
        node:OnInit(self, self:NodeFromInstance(script.MessageBus))
    end)
```
:::

And it's easy to use by the descendant modules:

Our modules though will need initialization now with given `tree` and `messagebus`

::: code-group
```luau [Calculator.luau]
local Allure = require(path.to.Allure)

return Allure:Node() {
    OnInit = function(self, tree, messagebus)
        self.Tree = tree
        self.MessageBus = messagebus
    end,
    Calculate = function(self, a, b)
        return a + b
    end,
    Multiply = function(self, a, b) -- [!code highlight]
        return self.MessageBus:Event("Multiplicator", "Multiply", a, b) -- [!code highlight]
    end -- [!code highlight]
} {}
```
```luau [Multiplicator.luau]
local Allure = require(path.to.Allure)

return Allure:Node() {
    OnInit = function(self, tree, messagebus)
        self.Tree = tree
        self.MessageBus = messagebus
    end,
    Calculate = function(self, a, b) -- [!code highlight]
        return self.MessageBus:Event("Calculator", "Calculate", a, b) -- [!code highlight]
    end, -- [!code highlight]
    Multiply = function(self, a, b)
        return a * b
    end
} {}
```
:::

This solves dependency cycles and 2 modules can use each other. Isn't this neat?

## Consumer - Producer (Publish/Subscribe)

Consumers and Producers can be 2 different types of Nodes.
<br>Our message bus can be a *wrapper* of Allure's `Node` and `NodeWorkspace`.

Or we can make it even simpler by making the standard `:Subscribe` and `:Publish`.

```
📜Main.server.luau 
  ├─📦MessageBus.luau 
  └─📂Modules
      ├─📦VehicleService.luau 
      └─📦RaceService.luau 
```
::: code-group
```luau [MessageBus.luau]
local Allure = require(path.to.Allure)

return Allure:Node() {
    Tree = nil :: any,
    Subscribers = {},  --[string]: function

    OnInit = function(self, tree)
        self.Tree = tree
    end,
    OnStart = function(...) end,

    Subscribe = function(self, topic, func)
        -- Create the topic if it doesn't exist
        if not self.Subscribers[topic] then self.Subscribers[topic] = {} end

        -- Add function to the list of subscribers (hooks)
        table.insert(self.Subscribers[topic], func)

        -- Return an unsubscribe function
        return function()
            table.remove(self.Subscribers[topic], func)
        end
    end,
    Publish = function(self, topic, ...)
        -- Call all subscribers of this topic
        for _, subscriber in self.Subscribers[topic] or {} do
            subscriber(...)
        end
    end
} {}
```
:::

The Bootstrapper remains the same, but now we have an OnStart phase:

::: code-group
```luau [Main.server.luau]
local Allure = require(path.to.Allure)

local tree = Allure:NodeTree()
    :LoadDescendants(script)
    :ForEach(function(self, node)
        node:OnInit(self, self:NodeFromInstance(script.MessageBus))
    end)
    :ForEach(function(self, node)
        node:OnStart()
    end)
```
:::
::: code-group
```luau [VehicleService.luau]
local Allure = require(path.to.Allure)

return Allure:Node() {
    OnInit = function(self, tree, messagebus)
        self.Tree = tree
        self.MessageBus = messagebus
    end,
    OnStart = function(self)
        local desubscribe = self.MessageBus:Subscribe("spawnVehicle", function(name, pos) -- [!code highlight]
            self:SpawnVehicle(name, pos) -- [!code highlight]
            --... [!code highlight]
        end) -- [!code highlight]
    end,

    SpawnVehicle = function(self, name, position)
        --...
    end
} {}
```
```luau [Multiplicator.luau]
local Allure = require(path.to.Allure)

return Allure:Node() {
    OnInit = function(self, tree, messagebus)
        self.Tree = tree
        self.MessageBus = messagebus
    end,
    OnStart = function(self)
        local desubscribe = self.MessageBus:Subscribe("BeginRace", function()
            self:BeginRace()
            --...
        end)
    end,

    BeginRace = function(self)
        self.MessageBus:Publish( -- [!code highlight]
            "VehicleSpawn", "SomeVehicleName", -- [!code highlight]
            Vector3.new(10, 10, 10)) -- [!code highlight]
        --...
    end
} {}
```
:::

### Enjoy Allure!

Thank you for paying attention and taking your time to read these docs or even trying out Allure, despite a very early version and many features lacking.
<br>Allure is one of my first published open source projects and it has a very long way to go!