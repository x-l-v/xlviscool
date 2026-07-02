# Frostware UI Library and Docs
this is a modified version of the Frostware source, previously hardcoded code suchas branding(name) IconAsset and UiAccent, but now you can customize them without changing the src file, Enjoy!

- Custom name
```lua
local UIName = "example"
```

- Icon Asset
```lua
local IconAsset = "rbxassetid://10723407389"
```

- Load Library

```lua
local LoaderLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/x-l-v/xlviscool/refs/heads/main/src.lua"))();
local Library = LoaderLibrary();
```
- For Roblox Game

```lua
local rbxLoader = require(script:WaitForChild('rbx.lua'));
local Library = require(script:WaitForChild('src.lua'));

rbxLoader(Library);

local FlowLibrary = Library();
```
- Create Notification

```lua
FlowLibrary.SendNotification({
	title = "Flow UI Library",
	text = "frfr",
	duration = 15
})
```

- Create Window

```lua
local Window = FlowLibrary.new();

Window:load() -- load window
```

- Create Tab

```lua
local tab = Window:create_tab("Tab",'rbxassetid://10723407389');
```

- Create Module

```lua
local newModule = tab:create_module({
	rich = false,
	section = 'right', -- left , right
	--richtext = "better than neuron x", < you need to enable 'rich' before use this!
	title = "Example Module",
	description = "Sofia is femboy",
	flag = "Protected with moon sec",
	callback = function(a)
		print('Section visible =',a)
	end,
});
```

## Main Library

- Create Button

```lua
local Button = newModule:create_button({
	title = "Click to Deobfuscate",
	callback = function()
		print('Click!')
	end,
})
```

- Create Checkbox

```lua
local checkbox = newModule:create_checkbox({
	title = "YEAH",
	flag = "REAL",
	callback = function(a)
		print(a)
	end,
})

--[[
Checkbox
	{
	    ["_state"] = false,
	    ["change_state"] = "function"
	}
]]
```

- Create Dropdown

```lua
-- Normal

local DROPDOWN = newModule:create_dropdown({
	options = {
		"VALUE 1",
		"VALUE 2",
		"VALUE 3",
	},

	--Order = 3,
	--OrderValue = "VALUE 3",

	multi_dropdown = false,
	maximum_options = 1,

	flag = "cc",
	title = "Dropdown",
	callback = function(val)
		print(val)
	end,
})

-- Multi
--Write env optionSkibidi VALUE 3

local DROPDOWN = newModule:create_dropdown({
	options = {
		"VALUE 1",
		"VALUE 2",
		"VALUE 3",
	},

	--Order = 3,
	--OrderValue = "VALUE 3",

	multi_dropdown = true,
	maximum_options = 3,

	flag = "cc2",
	title = "Skbidi",
	callback = function(val,ards)
		print(val,ards)
	end,
})

--[[
Dropdown
	{
	    ["New"] = "function",
	    ["_size"] = 51,
	    ["_state"] = false,
	    ["unfold_settings"] = "function",
	    ["update"] = "function"
	}
]]
```

- Create Paragraph

```lua
local Parahgraph = newModule:create_paragraph({
	--customScale = ???
	title = "Parahgraph - Skbidi",
	--rich = true,
	--richtext = "apwldpalspdlpwa"
	text = "God OF SKIDDING"
})
```

- Create Slider

```lua
local slider = newModule:create_slider({
	title = "Slider - S",
	value = 5,
	round_number = 0.5, -- < idk how it work
	minimum_value = 0,
	maximum_value = 10,
	flag = 'ada-slid',
	callback = function(a)
		print(a)
	end,
});

--[[
Slider
	{
	    ["input"] = "function",
	    ["set_percentage"] = "function",
	    ["update"] = "function"
	}
]]
```

- Create Text

```lua
local text = newModule:create_text({
	--customScale = ???
	--rich = true,
	--richtext = "sas"
	text = "discord.gg/"
})

--[[
Text
	{
    	["Set"] = "function"
 	}
]]
```
- Ui accent

```lua
local AccentToggle = false
local AccentColor = Color3.fromRGB(255, 120, 180)
``` 
