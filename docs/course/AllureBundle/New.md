# AllureBundle

AllureBundle serves as a different library: AllureUI is decoupled for states, despite being called UI.
<br>What this library contains are simple extensions based on AllureUI. 

Here we have my favorite `main:New` which is simply mounting and creating a new instance;
<br>`Spring, Computed and Effect` all of which are basic States with modified setters and getters;
<br>And some more.

## `:New`

Operates identically to your local UI library:

```luau
local main = Allure:garbage {}

main:New "TextButton" {
    Name = main:State("Menu")
}
```

The code behind it resembles a simple component:

```luau
return function(
	trash: Allure.garbage,
	object: string
): any
	return function(propTable)
		propTable = Allure.Amplify(trash, propTable)

		return Allure.mount(trash, Instance.new(object), propTable, nil, nil)
	end
end
```

Just makes the table an amplified and mounts it on a freshly created object.
<br>Notice, that I cannot necessarily do `trash:Amplify(propTable)` because I cannot assume that the table is created with Allure contents.

## Nesting and children

Relooking at some past concepts with this new syntax.

```luau
main:New "Frame" {
    
    main:New "TextButton" {
        Text = "Button"
    }
}
```

## Referencing children

Take a look at this case:

```luau
main:New "Folder" {
    
    main:New "Part" {
        Name = "Background"
    },

    main:New "SurfaceGUI" {
        Adornee = ?
    }
}
```

How can we reference the part to set it as the Adornee for the SurfaceGUI?
<br>Now, you can create some variables and references, create the part outside the folder, and whatever else, but, I know that children are instances without a key, or actually, a numeric key.

So I can just assign a numeric key to that part and reference it.

```luau
main:New "Folder" {
    
    [100] = main:New "Part" {
        Name = "Background"
    },

    function(self)
        return main:New "SurfaceGUI" {
            Adornee = self[100]
        }
    end
}
```

`self[100]` references that part.
<br>Maybe sometime in the future versions there'll be a way not to use numeric keys, but as of right now, this is the solution.

## Reproduction

Don't do this:

```luau
local stylesheet = {
    --...

    main:New "Button" { -- [!code error]
        --... -- [!code error]
    } -- [!code error]
}

main:New "Frame" {
    
    stylesheet
}
```

Because the next time you use the stylesheet the button will get reparented.

Again, use a reproduction function to do this:

```luau{4-8}
local stylesheet = {
    --...

    function(self)
        return main:New "Button" {
            --...
        }
    end
}

main:New "Frame" {
    
    stylesheet
}
```