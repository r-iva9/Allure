# Master - Worker design

Nothing stops you from using Node Trees anywhere you want. Use them to handle descendant components for some component, workers for a master, or simply modules for a bootstrapper.

## Realizing Workers integrated into Master

This design can be done in various ways. You can have a single modulescript as a master and contain worker threads within it at the same time.

::: code-group
```luau [Master.luau]
local Allure = require(path.to.Allure)

local module = Allure:NodeWorkspace() {} {
    Name = "Master"
}

local worker1, worker2, worker3 = module:Threads(3)

function module:Work()
    -- Get the worker with minimal workload
    local worker = worker1
    local minimumWorkLoad = #worker1.Queue

    for _, work in {worker2, worker3} do
        if #worker.Queue < minimumWorkLoad then
            worker = work
            minimumWorkLoad = #worker.Queue
        end
    end

    -- Do something
    worker:Enqueue(function()
        print("Worker with minimal workload is working")
    end)
end

return module()
```
:::
```
📂Modules
  └─📦Master.luau 
```

Or actually, what stops us from making even more workers, just storing them in a table?

::: code-group
```luau [Master.luau]
local Allure = require(path.to.Allure)

local module = Allure:NodeWorkspace() {} {
    Name = "Master"
}

local workers = {module:Threads(10)} -- [!code highlight]

function module:Work()
    -- Get the worker with minimal workload
    local worker = nil :: any
    local minimumWorkLoad = 999

    for _, work in workers do
        if #worker.Queue < minimumWorkLoad then
            worker = work
            minimumWorkLoad = #worker.Queue
        end
    end

    -- Do something
    worker:Enqueue(function()
        print("Worker with minimal workload is working")
    end)
end

return module()
```
:::
```
📂Modules
  └─📦Master.luau 
```

But what if we have more than enough, or less than enough workers?
<br>We could make a Worker Factory to regulate the amount.

::: code-group
```luau [Master.luau]
local Allure = require(path.to.Allure)

local module = Allure:NodeWorkspace() {} {
    Name = "Master"
}

local workers = {module:Threads(1)}

function module:Work()
    -- Get the worker with minimal workload
    local worker = nil :: any
    local minimumWorkLoad = 999

    local deniedWorkers = 0
    local maximumWorkLoad = 3

    for _, work in workers do
        local workload = #worker.Queue
        if workload < minimumWorkLoad and workload < maximumWorkLoad then
            worker = work
            minimumWorkLoad = #worker.Queue
        else
            deniedWorkers += 1
        end
    end

    -- Remove workers with 0 workload
    -- if deniedWorkers is less than 75% of all workers
    if deniedWorkers < 0.75 * #workers then
        local memo = {}
        for _, work in workers do
            if #work.Queue ~= 0 then    --Keep it
                table.insert(memo, work)
            else    --Kill it
                work:Kill()
            end
        end
        workers = memo
    end

    -- Add a new worker if we didn't find a good worker 
    -- (if we don't have enough)
    if not worker then 
        worker = module:Threads(1) 
        workers[#workers=1] = worker
    end

    -- Do something
    worker:Enqueue(function()
        print("Worker with minimal workload is working")
    end)
end

return module()
```
:::
```
📂Modules
  └─📦Master.luau 
```

This becomes kind of a mess, especially when you have different workers with different functionality and different needs.
<br>So we should prefer dividing the master and workers into their own Nodes.

## Realizing Master and Worker as Nodes

```
📂Modules
  └─📦Master.luau 
      ├─📦Worker1.luau 
      ├─📦Worker2.luau 
      └─📦Worker3.luau 
```
::: code-group
```luau [Worker1.luau, Worker2.luau, Worker3.luau]
local Allure = require(path.to.Allure)

-- Let's expose the workload of each worker so the master could be aware
local module = Allure:NodeWorkspace() {
    Workload = 0 -- [!code highlight]
} {
    Name = "Worker1"
}

-- The main thread of this Worker Node
local Thread = module:Threads(1)

-- Queue hook to lower workload when a task is finished
Thread.QueueHook.lowerWorkload = function()
    module.Workload -= 1
end

-- Some basic task
module.Calculate = Thread:Function(function(self, a, b)
    self.Workload += 1
    print(a + b)
end)

return module()
```
:::
::: code-group
```luau [Master.luau]
local Allure = require(path.to.Allure)

local module = Allure:NodeWorkspace() {} {
    Name = "Master"
}

local Workers = Allure:NodeTree()
    :LoadChildren(script)

function module:Calculate(a, b)
    --Sort the Workers tree by workload
    Workers:Sort(function(self, node) -- [!code highlight]
        return node.Workload -- [!code highlight]
    end) -- [!code highlight]

    --Give the task to the first worker (with minimal workload)
    Workers.Tree[1]:Calculate(a, b) -- [!code highlight]
end

return module()
```
:::

Additionally, making a Worker Factory with Nodes is easier, because you can clone and delete Worker Nodes.