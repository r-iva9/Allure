# Workers and multi-threading

Allure has "Worker" in it's title, you possibly came here because of that.
<br>It really provides support for workers, and that's a big feature that comes in hand with other parallel features.

This is a bonus feature, which allows you to create workers, enqueue functions, or make entire master-worker setups with microservices, queues and management of worker workload.

## `Allure:Workers`

A worker is a ***specific object*** that wraps a coroutine thread.
<br>It's merged with a queue and some utilities, like enqueuing and dequeuing.

```luau
local worker1, worker2, worker3 = Allure:Workers(3)
```

It creates and returns the specified amount of workers.

## Enqueuing functions

A worker has `Worker.Queue` - a table of functions, tasks to be executed.

Tasks are executed one by one, and you can always add a new task:

```luau
local worker = Allure:Workers(1)

worker:Enqueue(function()
    print("Working!")
end)

worker:Enqueue(function()
    print("Working again!")
end)
```
::: code-group
``` [Output]
Working!
Working again!
```
:::

`:Enqueue` also accepts arguments, if you have some function predefined:

```luau
local fn = function(a, b)
    print(a + b)
end

worker:Enqueue(fn, 10, 15)
worker:Enqueue(fn, 25, -10)
```
::: code-group
``` [Output]
25
15
```
:::

## Dequeuing

Analogically, dequeue the *last enqueued task*:

```luau
local worker = Allure:Workers(1)

worker:Enqueue(function()
    print("Working!")
end)

worker:Dequeue()
```

And dequeue a specific function at position `n` via `:Dequeue(n)`

But the code snippet above possibly won't work, because the function is consumed *immediately*, so nothing will be dequeued.
<br>We need a waiting method.

## Yielding inside of worker tasks

The problem is, `task.wait` *will stop* the running task but *will not stop* the queue.
<br>So here we have a custom yielding method that entirely replicates `task.wait` but also sets a flag.

```luau
local worker = Allure:Workers(1)

worker:Enqueue(function()
    print("Working")
    worker:Yield(5) -- [!code highlight]
end)

worker:Enqueue(function() end)

worker:Dequeue()
```

Now our first task will yield the worker for 5 seconds, and our dequeue will actually find the time to dequeue the second task.

## Hooking functions to the queue

Any Worker has `.Queue` and `.QueueHook`.
<br>All functions within `.QueueHook` are called whenever some task is ***dequeued***.

Notice, all hooks are called **on the coroutine thread**.

```luau
local worker1, worker2 = Allure:Workers(2)

worker1.QueueHook["test"] = function() -- [!code highlight]
    print("Some task was dequeued") -- [!code highlight]
end -- [!code highlight]

worker1:Enqueue(function()
    print("This is the first task for worker1")
end)
```
::: code-group
``` [Output]
This is the first task for worker1
Some task was dequeued
```
:::

## Killing the Worker

To kill the Worker, simply call `Worker:Kill()`
<br>This will close the `Worker.Coroutine`, empty the `Worker.Queue` and set some flags.

```luau
local worker = Allure:Workers(1)

worker:Enqueue(function()
    print("This is the first task for worker")
    worker:Yield(2)
end)

worker.QueueHook["consumeAndClose"] = function()
    worker:Kill() -- [!code highlight]
end
```

## Workers within Nodes

Workers aren't just some arbitrary utility given.
<br>You can easily create a Worker node by having <ins>*all functions enqueue themselves into workers*</ins>, or a Master node with Worker children nodes, or Microservice Nodes, etc.

We have a shortcut for that.

```luau
local module = Allure:Node() {} {}

local worker = module:Workers(1)

module.AsyncFunc = worker:Function(function(self, a, b) -- [!code highlight]
    print("This is being executed on worker!") -- [!code highlight]
    print(a + b) -- [!code highlight]
end) -- [!code highlight]

return module()
```
::: code-group
```luau [Bootstrapper]
local Node = require(path.to.Node)

Node:AsyncFunc(10, 5)
Node:AsyncFunc(7, 14)
```
:::
::: code-group
``` [Output]
This is being executed on worker!
15
This is being executed on worker!
21
```
:::

Very neat.
<br>Type safety also does not go anywhere.