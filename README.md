<p align="center">
  <img width="500" height="250" src="https://github.com/m-at1/Allure/blob/main/images/logo.png?raw=true" alt="Logo">
</p>

<p align="center">
  <b><i>Reactive Framework of Frameworks for the Roblox Metaverse.</i></b> </br>
  <i>Inspired by Fusion, Vide and Spring</i>
</p>

<h1></h1>
</br>
<div align="center">
  <a href="https://github.com/m-at1/Allure/blob/main/Installation.md"><img width="65" height="50" src="./images/Install.png" alt="Install"></a>‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ
  <a href="https://github.com/m-at1/Allure/releases"><img width="160" height="50" src="./images/Docs.png" alt="Docs"></a> <!--ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ‎‎‎‎‎‎‎‎ㅤ
  <!--- a href="https://github.com/m-at1/Alloy/releases"><img width="130" height="50" src="./images/Benchmarks.png" alt="Benchmarks"></a> /--!>
  
</div>

> [!IMPORTANT]
> <h2>Allure is 0.1.0 software</h2>
> This means that Allure has unfinished documentation, overlooked issues and bugs.
> 
> Modding and utilizing Allure as a "meta-framework" over any UI framework is currently being worked on.<br>
> As of right now, you can use *5 preset frameworks/libraries* within the Allure container.

# 🍃 *AllureUI*
- ## *<ins>Amplified Tables</ins>: The Powerful Core to UI*
  Amplified Tables are an extension that appends tons of state machine features to a standard table. </br>
  Without keys, instances are added as children, functions are called for referencing other keys, and many more. </br>
  When mounted on an instance, produces a `mount` object with it's own deleter and lifecycle. An amplified has a custom setter, deleter, updater, etc.
  
### StyleSheets

> ```luau
> local frameDesign = {
>	  Size = UDim2.fromScale(0.6, 0.7),
>  	Position = UDim2.fromScale(0.5, 0.5),
>
>     -- A "producer" function - when applied, produces an instance
>	  function(self) 
>        return main:New "UIAspectRatioConstraint" {
>	         AspectRatio = 1.6,
>	     },
>     end)
> }
>
> -- garbageCollector:New actually makes the table an amplified and mounts it!
> local frame = main:New "Frame" {
>	  frameDesign,  -- Tables without a key are merged with the amplified
>
>	  main:New "TextButton" {
>		    frameDesign,
>
>         --[[
>             More tables, higher the order
>             Thus this second order table can overwrite the stylesheet
>         ]]
>		    { {  
>			      BackgroundTransparency = 0,
>	      } },
>	  },
> }
>```
  
- ## *<ins>Customizable States</ins>: Low Level*
  Customize the setter, getter, updater, deleter and create custom attributes. </br>
  States are interchangeable with *observables* or amplifieds, since they share all of these capabilities.
### Click Counter
> ```luau
>main:New "TextButton" {
>
>     -- A state for the counter text
>		Text = main:State("Count: 0")
>         -- A custom attribute to have the current count
>			:custom "count"(0)
>         -- And a custom setter to update the count, value and call connections (updater)
>			:setter(function(self, item)
>				self.count = item
>				Allure.set(self, "Count: " .. item)
>  			self:updater()
>			end),
> 
>     -- Whenever it is clicked, set the state to the next number
>     -- This calls the setter, which does everything we need
>		Allure.onEvent "MouseButton1Click"(function(self)
>			self.Text(self.Text.count + 1)
>		end),
>},
>```
  Complex? We're going to optimize it multiple times.

- ## *<ins>Simple Garbage Collection</ins>: Integrated into everything*
  For cleanup, simply call the garbage collector as a function.
  </br> After cleanup the garbage collector still can be used just as fresh.
### GC
> ```luau
>main = Allure:garbage {insert = table.insert}
>
>-- Upon cleanup functions are called, instances are deleted, etc.
>main:insert(function()
>    print("cleanup called!")
>end)
>
>main() -- cleanup called!
>```

# 🍀 *AllureRx*
- ## *<ins>Reactive Observables</ins>: Generating and filtering data streams*
  Generate, filter, subscribe to an observable from anywhere.
### Click Counter on observables

> ```luau
> main:New "TextButton" {
>     TextScaled = true,
>
>     --[[ You can use any key in Amplifieds ]]
>		_count = main:Observable(),
>
>     --[[
>         Whenever it is clicked, simply emit 1.
>         It will be accumulated and turned into a string that we need
>     ]]
>		Allure.onEvent "MouseButton1Click"(function(self)
>			self._count(1)
>		end),
>
>     --[[
>         Since we need _count to exist, to avoid race conditions,
>         use the next order by simply wrapping it in a table:
>     ]]
>		{
>         -- Amplifieds automatically call functions,
>         -- we need this so we can reference _count
>			Text = function(self)
>				return self._count
>                 -- Accumulate the counting value with scan operator
>					:scan(function(self, value, total)
>						return value + (total or 0)
>					end)
> 
>                 -- Turn it into usable text with map operator
>					:map(function(self, item)
>						return "Count: " .. item
>					end)
> 
>                 -- Emit the starting value
>					:emit(0)
>			end,
>		},
>},
>```

# 🔰 *AllureBundle*
- ## *<ins>Stack and Spring</ins>: query, ratelimit and animate*
  Stacks and Springs are made given simple State customization.
  </br>You can easily make them yourself!
  
### Random Color
>```luau
>main:New "TextButton" {
>    BackgroundColor3 = main:Spring(Color3.new(1, 1, 1), 2, 0.8),
>
>    Allure.onEvent "MouseButton1Click"(function(self)
>        -- Spring is just a state with a heavily modified setter,
>        -- so we simply call it with the goal value
>        self.BackgroundColor3(Color3.new(
>            math.random(1, 100) / 100,
>            math.random(1, 100) / 100,
>            math.random(1, 100) / 100
>        ))
>    end),
>}
>```

- ## *<ins>Effect, Computed, Observer</ins>: state needs*
  Inspired by Fusion, however, all of these are also made simply given state customization.
  
### I simplified the click counter
>```luau
>main:New "TextButton" {
>    count = main:State(0),
>
>    Text = function(self)
>        -- An effect that'll update each time self.count updates
>        return main:Effect(function(with, innergarbage)
>            return "Count: " .. with(self.count)
>        end)
>    end,
>
>    Allure.onEvent "MouseButton1Click"(function(self)
>        self.count(self.count:get() + 1)
>    end),
>},
>```

- ## *<ins>Effect Shortcuts</ins>: simpler, faster, easier*
  A lot of simple effects like `with(a) + b`, no matter if a is an observable, state or anything else, can be shortened to simply `a + b`.
  
### I simplified it even more
>```luau
>main:New "TextButton" {
>    count = main:State(0),
>
>    Text = function(self)
>        return "Count: " .. self.count
>    end,
>
>    Allure.onEvent "MouseButton1Click"(function(self)
>        self.count(self.count:get() + 1)
>    end),
>},
>```

# 🎭 *AllureWorker*
- ## *<ins>Asynchronous Thread Handler</ins>: Interface for thread communication*
  A Worker contains it's own thread, resuming which with a function will "consume" that function.
  </br>Which means, defining a worker is defining how you communicate between 2 threads. Add queries, ratelimits, anything.
  
### Consume

>```luau
>local myworker = main:Worker {
>    consume = function(self, fn2)
>        print("This is executed on the main thread")
>
>        coroutine.resume(self.thread, fn2)
>    end,
>}
>
>myworker:consume(function()
>    print("This is executed on the worker's thread")
>end)
>```

---

## License
Allure is shared and released with the MIT License.
</br>Give me a shoutout if you want!
