# Multi-threading in Nodes

I did not forget about multithreading and workers. It's a Worker framework, you possibly came here because of that.
<br>So here we are.

This is a bonus feature for Nodes, which allows you to create threads, enqueue functions, or make entire master-worker setups with microservices, queues and management of worker workload.

## `:Threads`

This is the last utility given in `NodeWorkspaces` that I specifically didn't tell you about, because I wanted to divide this into an another file for this documentation.

```luau
local module = Allure:NodeWorkspace() {} {}

function module:onInit()
end

local thread1, thread2, thread3 = module:Threads(3) -- [!code highlight]

return module()
```

`nodeWorkspace:Threads(n)` creates `n` amount of threads and returns them.
<br>Specifically, this is a ***custom thread object*** with already set management of queues. Let's dive in.

## Enqueuing functions via `Thread:Enqueue()`

Any Thread has it's own `Thread.Queue` which is an array table of functions.

These functions are sequentially consumed by the `coroutine` thread at the core of the `Thread`.

```luau
local module = Allure:NodeWorkspace() {} {}

local thread1, thread2 = module:Threads(2)

thread1:Enqueue(function()
    print("This is being executed on thread1!")
end)

thread1:Enqueue(function()
    print("This is also executed on thread1!")
end)

return module()
```
::: code-group
``` [Output]
This is being executed on thread1!
This is also executed on thread1!
```
:::

## Yielding inside of threads

The problem is, `task.wait` *will stop* the running task but *will not stop* the queue.
<br>So here we have a custom yielding method that entirely replicates `task.wait` but also sets a flag.

```luau
local module = Allure:NodeWorkspace() {} {}

local thread1, thread2 = module:Threads(2)

thread1:Enqueue(function()
    print("This is being executed on thread1!")
    thread1:Yield(10) -- [!code highlight]
end)

thread1:Enqueue(function()
    print("This is also executed on thread1 after 10 seconds!")
end)

return module()
```

Pretty self-explanatory.

## Hooking functions to the queue

Any Thread has `.Queue` and `.QueueHook`.
<br>All functions within `.QueueHook` are called whenever some task is ***dequeued***.

All hooks are called **on the coroutine thread**.

```luau
local module = Allure:NodeWorkspace() {} {}

local thread1, thread2 = module:Threads(2)

thread1.QueueHook["test"] = function() -- [!code highlight]
    print("Some task was dequeued") -- [!code highlight]
end -- [!code highlight]

thread1:Enqueue(function()
    print("This is the first task for thread1")
end)

return module()
```
::: code-group
``` [Output]
This is the first task for thread1
Some task was dequeued
```
:::

## Killing the Thread

To kill the Thread, simply call `Thread:Kill()`
<br>This will close the `Thread.Coroutine`, empty the `Thread.Queue` and set some flags.

```luau
local module = Allure:NodeWorkspace() {} {}

local thread1 = module:Threads(1)

thread1:Enqueue(function()
    print("This is the first task for thread1")
end)

thread1.QueueHook["consumeAndClose"] = function()
    thread1:Kill() -- [!code highlight]
end

return module()
```

## Threads in Worker Nodes

Threads aren't just some arbitrary utility given.
<br>You can easily create a Worker node by having <ins>*all functions enqueue themselves into threads*</ins>, or a Master node with Worker children nodes, or Microservice Nodes, etc.

We have a shortcut for that.

```luau
local module = Allure:NodeWorkspace() {} {}

local thread1 = module:Threads(1)

module.AsyncFunc = thread1:Function(function(self, a, b) -- [!code highlight]
    print("This is being executed on thread1!") -- [!code highlight]
    return a + b -- [!code highlight]
end) -- [!code highlight]

return module()
```
::: code-group
```luau [Bootstrapper]
local Node = require(path.to.Node)

Node:AsyncFunc(10, 5)
```
:::
::: code-group
``` [Output]
This is being executed on thread1!
```
:::

Very neat.
<br>Type safety also does not go anywhere.