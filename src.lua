--[[
    Changes:
    - SetBackgroundMedia now respects opacity=0 and restores container background.
    - Added set_text method to button objects for dynamic title updates.
	- More to be coming.
]]--

getgenv().GG = {
    Language = {
        CheckboxEnabled = "Enabled",
        CheckboxDisabled = "Disabled",
        SliderValue = "Value",
        DropdownSelect = "Select",
        DropdownNone = "None",
        DropdownSelected = "Selected",
        ButtonClick = "Click",
        TextboxEnter = "Enter",
        ModuleEnabled = "Enabled",
        ModuleDisabled = "Disabled",
        TabGeneral = "General",
        TabSettings = "Settings",
        Loading = "Loading...",
        Error = "Error",
        Success = "Success"
    }
}

local UIName = "Frostware"
local ConfigFolder = UIName
local AccentToggle = false
local AccentColor = Color3.fromRGB(255, 120, 180)
local DefaultAccentColor = Color3.fromRGB(152, 181, 255)
local UIAccentColor = AccentToggle and AccentColor or DefaultAccentColor
local IconAsset = "rbxassetid://74080484918102"
local IconAnimated = true
local IconSpriteWidth = 60
local IconSpriteHeight = 40
local IconSpriteRows = 2
local IconSpriteColumns = 3
local IconSpriteFrames = 5
local IconSpriteFPS = 10
local DefaultBackgroundMedia = nil

tablein = tablein or table.insert

-- Replace the SelectedLanguage with a reference to GG.Language
local SelectedLanguage = GG.Language

function convertStringToTable(inputString)
    local result = {}
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        tablein(result, trimmedValue)
    end

    return result
end

function convertTableToString(inputTable)
    return table.concat(inputTable, ", ")
end

local UserInputService = cloneref(game:GetService('UserInputService'))
local ContentProvider = cloneref(game:GetService('ContentProvider'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Lighting = cloneref(game:GetService('Lighting'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))

local mouse = Players.LocalPlayer:GetMouse()
local old_Frostware = CoreGui:FindFirstChild(UIName)

if old_Frostware then
    Debris:AddItem(old_Frostware, 0)
end

if not isfolder(ConfigFolder) then
    makefolder(ConfigFolder)
end


local Connections = setmetatable({
    disconnect = function(self, connection)
        if not self[connection] then
            return
        end
    
        self[connection]:Disconnect()
        self[connection] = nil
    end,
    disconnect_all = function(self)
        for _, value in self do
            if typeof(value) == 'function' then
                continue
            end
    
            value:Disconnect()
        end
    end
}, Connections)


local Util = setmetatable({
    map = function(self: any, value: number, in_minimum: number, in_maximum: number, out_minimum: number, out_maximum: number)
        return (value - in_minimum) * (out_maximum - out_minimum) / (in_maximum - in_minimum) + out_minimum
    end,
    viewport_point_to_world = function(self: any, location: any, distance: number)
        local unit_ray = workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)

        return unit_ray.Origin + unit_ray.Direction * distance
    end,
    get_offset = function(self: any)
        local viewport_size_Y = workspace.CurrentCamera.ViewportSize.Y

        return self:map(viewport_size_Y, 0, 2560, 8, 56)
    end
}, Util)


local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur


function AcrylicBlur.new(object: GuiObject)
    local self = setmetatable({
        _object = object,
        _folder = nil,
        _frame = nil,
        _root = nil
    }, AcrylicBlur)

    self:setup()

    return self
end


function AcrylicBlur:create_folder()
    local old_folder = workspace.CurrentCamera:FindFirstChild('AcrylicBlur')

    if old_folder then
        Debris:AddItem(old_folder, 0)
    end

    local folder = Instance.new('Folder')
    folder.Name = 'AcrylicBlur'
    folder.Parent = workspace.CurrentCamera

    self._folder = folder
end


function AcrylicBlur:create_depth_of_fields()
    local depth_of_fields = Lighting:FindFirstChild('AcrylicBlur') or Instance.new('DepthOfFieldEffect')
    depth_of_fields.FarIntensity = 0
    depth_of_fields.FocusDistance = 0.05
    depth_of_fields.InFocusRadius = 0.1
    depth_of_fields.NearIntensity = 1
    depth_of_fields.Name = 'AcrylicBlur'
    depth_of_fields.Parent = Lighting

    for _, object in Lighting:GetChildren() do
        if not object:IsA('DepthOfFieldEffect') then
            continue
        end

        if object == depth_of_fields then
            continue
        end

        Connections[object] = object:GetPropertyChangedSignal('FarIntensity'):Connect(function()
            object.FarIntensity = 0
        end)

        object.FarIntensity = 0
    end
end


function AcrylicBlur:create_frame()
    local frame = Instance.new('Frame')
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = self._object

    self._frame = frame
end


function AcrylicBlur:create_root()
    local part = Instance.new('Part')
    part.Name = 'Root'
    part.Color = Color3.new(0, 0, 0)
    part.Material = Enum.Material.Glass
    part.Size = Vector3.new(1, 1, 0)  -- Use a thin part
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Locked = true
    part.CastShadow = false
    part.Transparency = 0.98
    part.Parent = self._folder

    -- Create a SpecialMesh to simulate the acrylic blur effect
    local specialMesh = Instance.new('SpecialMesh')
    specialMesh.MeshType = Enum.MeshType.Brick  -- Use Brick mesh or another type suitable for the effect
    specialMesh.Offset = Vector3.new(0, 0, -0.000001)  -- Small offset to prevent z-fighting
    specialMesh.Parent = part

    self._root = part  -- Store the part as root
end


function AcrylicBlur:setup()
    self:create_depth_of_fields()
    self:create_folder()
    self:create_root()
    
    self:create_frame()
    self:render(0.001)

    self:check_quality_level()
end


function AcrylicBlur:render(distance: number)
    local positions = {
        top_left = Vector2.new(),
        top_right = Vector2.new(),
        bottom_right = Vector2.new(),
    }

    local function update_positions(size: any, position: any)
        positions.top_left = position
        positions.top_right = position + Vector2.new(size.X, 0)
        positions.bottom_right = position + size
    end

    local function update()
        local top_left = positions.top_left
        local top_right = positions.top_right
        local bottom_right = positions.bottom_right

        local top_left3D = Util:viewport_point_to_world(top_left, distance)
        local top_right3D = Util:viewport_point_to_world(top_right, distance)
        local bottom_right3D = Util:viewport_point_to_world(bottom_right, distance)

        local width = (top_right3D - top_left3D).Magnitude
        local height = (top_right3D - bottom_right3D).Magnitude

        if not self._root then
            return
        end

        self._root.CFrame = CFrame.fromMatrix((top_left3D + bottom_right3D) / 2, workspace.CurrentCamera.CFrame.XVector, workspace.CurrentCamera.CFrame.YVector, workspace.CurrentCamera.CFrame.ZVector)
        self._root.Mesh.Scale = Vector3.new(width, height, 0)
    end

    local function on_change()
        local offset = Util:get_offset()
        local size = self._frame.AbsoluteSize - Vector2.new(offset, offset)
        local position = self._frame.AbsolutePosition + Vector2.new(offset / 2, offset / 2)

        update_positions(size, position)
        task.spawn(update)
    end

    Connections['cframe_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(update)
    Connections['viewport_size_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(update)
    Connections['field_of_view_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('FieldOfView'):Connect(update)

    Connections['frame_absolute_position'] = self._frame:GetPropertyChangedSignal('AbsolutePosition'):Connect(on_change)
    Connections['frame_absolute_size'] = self._frame:GetPropertyChangedSignal('AbsoluteSize'):Connect(on_change)
    
    task.spawn(update)
end


function AcrylicBlur:check_quality_level()
    local game_settings = UserSettings().GameSettings
    local quality_level = game_settings.SavedQualityLevel.Value

    if quality_level < 8 then
        self:change_visiblity(false)
    end

    Connections['quality_level'] = game_settings:GetPropertyChangedSignal('SavedQualityLevel'):Connect(function()
        local game_settings = UserSettings().GameSettings
        local quality_level = game_settings.SavedQualityLevel.Value

        self:change_visiblity(quality_level >= 8)
    end)
end


function AcrylicBlur:change_visiblity(state: boolean)
    self._root.Transparency = state and 0.98 or 1
end


local Config = setmetatable({
    save = function(self: any, file_name: any, config: any)
        if type(writefile) ~= "function" then
            return
        end

        local success_save, result = pcall(function()
            local flags = HttpService:JSONEncode(config)
            writefile(ConfigFolder..'/'..file_name..'.json', flags)
        end)
    
        if not success_save then
            warn('failed to save config', result)
        end
    end,
    load = function(self: any, file_name: any, config: any)
        local success_load, result = pcall(function()
            if type(isfile) ~= "function" or type(readfile) ~= "function" then
                self:save(file_name, config)

                return
            end

            if not isfile(ConfigFolder..'/'..file_name..'.json') then
                self:save(file_name, config)
        
                return
            end
        
            local flags = readfile(ConfigFolder..'/'..file_name..'.json')
        
            if not flags then
                self:save(file_name, config)
        
                return
            end

            return HttpService:JSONDecode(flags)
        end)
    
        if not success_load then
            warn('failed to load config', result)
        end
    
        if type(result) ~= "table" then
            result = {
                _flags = {},
                _keybinds = {},
                _library = {}
            }
        end

        if type(result._flags) ~= "table" then
            result._flags = {}
        end

        if type(result._keybinds) ~= "table" then
            result._keybinds = {}
        end

        if type(result._library) ~= "table" then
            result._library = {}
        end
    
        return result
    end
}, Config)


local Library = {
    _config = Config:load(game.GameId),

    _choosing_keybind = false,
    _device = nil,

    _ui_open = true,
    _ui_scale = 1,
    _ui_loaded = false,
    _ui = nil,

    _dragging = false,
    _drag_start = nil,
    _container_position = nil
}
Library.__index = Library

local function ResolveMethodValue(first, second)
	if first == Library then
		return second
	end

	return first
end

local function ResolveAssetId(asset)
	if typeof(asset) == "number" then
		return "rbxassetid://" .. tostring(asset)
	end

	if typeof(asset) == "string" and asset ~= "" then
		if tonumber(asset) then
			return "rbxassetid://" .. asset
		end

		return asset
	end

	return nil
end

local function Clamp01(value)
	value = tonumber(value)

	if not value then
		return nil
	end

	return math.clamp(value, 0, 1)
end

local function UpdateUIAccentColor()
	UIAccentColor = AccentToggle and AccentColor or DefaultAccentColor
	return UIAccentColor
end

function Library.UIName(first, second)
	local name = ResolveMethodValue(first, second)

	if typeof(name) == "string" and name ~= "" then
		UIName = name
		ConfigFolder = name

		if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(ConfigFolder) then
			makefolder(ConfigFolder)
		end

		Library._config = Config:load(game.GameId)
	end

	return UIName
end

function Library.AccentToggle(first, second)
	AccentToggle = ResolveMethodValue(first, second) == true
	return UpdateUIAccentColor()
end

function Library.AccentColor(first, second)
	local color = ResolveMethodValue(first, second)

	if typeof(color) == "Color3" then
		AccentColor = color
	end

	return UpdateUIAccentColor()
end

function Library.UIAccent(first, second, third)
	local enabled = first
	local color = second

	if first == Library then
		enabled = second
		color = third
	end

	AccentToggle = enabled == true

	if typeof(color) == "Color3" then
		AccentColor = color
	end

	return UpdateUIAccentColor()
end

function Library.IconAsset(first, second)
	local asset = ResolveAssetId(ResolveMethodValue(first, second))

	if typeof(asset) == "string" and asset ~= "" then
		IconAsset = asset
		IconAnimated = false
	end

	return IconAsset
end

Library.CustomIcon = Library.IconAsset

function Library.IconAnimated(first, second)
	IconAnimated = ResolveMethodValue(first, second) == true
	return IconAnimated
end

function Library.IconSprite(first, second, third, fourth, fifth, sixth, seventh, eighth)
	local asset = first
	local width = second
	local height = third
	local rows = fourth
	local columns = fifth
	local frames = sixth
	local fps = seventh

	if first == Library then
		asset = second
		width = third
		height = fourth
		rows = fifth
		columns = sixth
		frames = seventh
		fps = eighth
	end

	asset = ResolveAssetId(asset)

	if typeof(asset) == "string" and asset ~= "" then
		IconAsset = asset
	end

	IconSpriteWidth = tonumber(width) or IconSpriteWidth
	IconSpriteHeight = tonumber(height) or IconSpriteHeight
	IconSpriteRows = tonumber(rows) or IconSpriteRows
	IconSpriteColumns = tonumber(columns) or IconSpriteColumns
	IconSpriteFrames = tonumber(frames) or IconSpriteFrames
	IconSpriteFPS = tonumber(fps) or IconSpriteFPS
	IconAnimated = true

	return IconAsset
end

function Library.BackgroundMedia(first, second)
	DefaultBackgroundMedia = ResolveMethodValue(first, second)
	return DefaultBackgroundMedia
end


function Library.new(settings)
	settings = type(settings) == "table" and settings or {}

	local customName = settings.UIName or settings.uiName or settings.Name or settings.name
	if customName ~= nil then
		Library.UIName(customName)
	end

	local customIcon = settings.CustomIcon or settings.customIcon or settings.Icon or settings.icon
	if customIcon ~= nil then
		Library.IconAsset(customIcon)
	end

	if settings.IconAnimated ~= nil then
		Library.IconAnimated(settings.IconAnimated)
	elseif settings.iconAnimated ~= nil then
		Library.IconAnimated(settings.iconAnimated)
	end

	local customBackground = settings.BackgroundMedia or settings.backgroundMedia or settings.background_media or settings.Background or settings.background or DefaultBackgroundMedia

    local self = setmetatable({
        _loaded = false,
        _tab = 0,
    }, Library)
    
    self:create_ui()

	if customBackground ~= nil then
		task.defer(function()
			if self.SetBackgroundMedia then
				self:SetBackgroundMedia(customBackground)
			end
		end)
	end

    return self
end

-- Create Notification Container
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "RobloxCoreGuis"
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)  -- Fixed width (300px), dynamic height (Y)
NotificationContainer.Position = UDim2.new(0.8, 0, 0, 10)  -- Right side, offset by 10 from top
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false;
NotificationContainer.Parent = game:GetService("CoreGui").RobloxGui:FindFirstChild("RobloxCoreGuis") or Instance.new("ScreenGui", game:GetService("CoreGui").RobloxGui)
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y

-- UIListLayout to arrange notifications vertically
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = NotificationContainer

-- Function to create notifications
function Library.SendNotification(settings)
    -- Create the notification frame (this will be managed by UIListLayout)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 60)  -- Width = 100% of NotificationContainer's width, dynamic height (Y)
    Notification.BackgroundTransparency = 1  -- Outer frame is transparent for layout to work
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = NotificationContainer  -- Parent it to your NotificationContainer (the parent of the list layout)
    Notification.AutomaticSize = Enum.AutomaticSize.Y  -- Allow this frame to resize based on child height

    -- Add rounded corners to outer frame
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Notification

    -- Create the inner frame for the notification's content
    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 0, 60)  -- Start with an initial height, width will adapt
    InnerFrame.Position = UDim2.new(0, 0, 0, 0)  -- Positioned inside the outer notification frame
    InnerFrame.BackgroundColor3 = Color3.fromRGB(32, 38, 51)
    InnerFrame.BackgroundTransparency = 0.1
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Name = "InnerFrame"
    InnerFrame.Parent = Notification
    InnerFrame.AutomaticSize = Enum.AutomaticSize.Y  -- Automatically resize based on its content

    -- Add rounded corners to the inner frame
    local InnerUICorner = Instance.new("UICorner")
    InnerUICorner.CornerRadius = UDim.new(0, 4)
    InnerUICorner.Parent = InnerFrame

    -- Title Label (with automatic size support)
    local Title = Instance.new("TextLabel")
    Title.Text = settings.title or "Notification Title"
    Title.TextColor3 = Color3.fromRGB(210, 210, 210)
    Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Title.TextSize = 14
    Title.Size = UDim2.new(1, -10, 0, 20)  -- Width is 1 (100% of parent width), height is fixed initially
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.TextWrapped = true  -- Enable wrapping
    Title.AutomaticSize = Enum.AutomaticSize.Y  -- Allow the title to resize based on content
    Title.Parent = InnerFrame

    -- Body Text (with automatic size support)
    local Body = Instance.new("TextLabel")
    Body.Text = settings.text or "This is the body of the notification."
    Body.TextColor3 = Color3.fromRGB(180, 180, 180)
    Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Body.TextSize = 12
    Body.Size = UDim2.new(1, -10, 0, 30)  -- Width is 1 (100% of parent width), height is fixed initially
    Body.Position = UDim2.new(0, 5, 0, 25)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Top
    Body.TextWrapped = true  -- Enable wrapping for long text
    Body.AutomaticSize = Enum.AutomaticSize.Y  -- Allow the body text to resize based on content
    Body.Parent = InnerFrame

    -- Force the size to adjust after the text is fully loaded and wrapped
    task.spawn(function()
        wait(0.1)  -- Allow text wrapping to finish
        -- Adjust inner frame size based on content
        local totalHeight = Title.TextBounds.Y + Body.TextBounds.Y + 10  -- Add padding
        InnerFrame.Size = UDim2.new(1, 0, 0, totalHeight)  -- Resize the inner frame
    end)

    -- Use task.spawn to ensure the notification tweening happens asynchronously
    task.spawn(function()
        -- Tween In the Notification (inner frame)
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 10 + NotificationContainer.Size.Y.Offset)
        })
        tweenIn:Play()

        -- Wait for the duration before tweening out
        local duration = settings.duration or 5  -- Default to 5 seconds if not provided
        wait(duration)

        -- Tween Out the Notification (inner frame) to the right side of the screen
        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 310, 0, 10 + NotificationContainer.Size.Y.Offset)  -- Move to the right off-screen
        })
        tweenOut:Play()

        -- Remove the notification after it is done tweening out
        tweenOut.Completed:Connect(function()
            Notification:Destroy()
        end)
    end)
end

function Library:get_screen_scale()
    local viewport_size_x = workspace.CurrentCamera.ViewportSize.X

    self._ui_scale = viewport_size_x / 1400
end


function Library:get_device()
    local device = 'Unknown'

    if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
        device = 'PC'
    elseif UserInputService.TouchEnabled then
        device = 'Mobile'
    elseif UserInputService.GamepadEnabled then
        device = 'Console'
    end

    self._device = device
end


function Library:removed(action: any)
    self._ui.AncestryChanged:Once(action)
end


function Library:flag_type(flag: any, flag_type: any)
    if type(Library._config) ~= "table" then
        Library._config = {
            _flags = {},
            _keybinds = {},
            _library = {}
        }
    end

    if type(Library._config._flags) ~= "table" then
        Library._config._flags = {}
    end

    if not Library._config._flags[flag] then
        return
    end

    return typeof(Library._config._flags[flag]) == flag_type
end


function Library:remove_table_value(__table: any, table_value: string)
    for index, value in __table do
        if value ~= table_value then
            continue
        end

        table.remove(__table, index)
    end
end

function Library:create_ui()
    local old_Frostware = CoreGui:FindFirstChild(UIName)

    if old_Frostware then
        Debris:AddItem(old_Frostware, 0)
    end

    local Frostware = Instance.new('ScreenGui')
    Frostware.ResetOnSpawn = false
    Frostware.Name = UIName
    Frostware.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Frostware.Parent = CoreGui
    
    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0.16
    Container.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = Frostware

    local ContainerGradient = Instance.new("UIGradient")
    ContainerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(21, 21, 23)),
        ColorSequenceKeypoint.new(0.14, Color3.fromRGB(12, 12, 14)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(6, 6, 8))
    }
    ContainerGradient.Rotation = 90
    ContainerGradient.Parent = Container

    local BackgroundMediaHolder = Instance.new("Frame")
    BackgroundMediaHolder.Name = "BackgroundMedia"
    BackgroundMediaHolder.BackgroundTransparency = 1
    BackgroundMediaHolder.ClipsDescendants = true
    BackgroundMediaHolder.Visible = false
    BackgroundMediaHolder.Size = UDim2.fromScale(1, 1)
    BackgroundMediaHolder.Position = UDim2.fromScale(0, 0)
    BackgroundMediaHolder.ZIndex = 0
    BackgroundMediaHolder.Parent = Container

    local BackgroundMediaCorner = Instance.new("UICorner")
    BackgroundMediaCorner.CornerRadius = UDim.new(0, 16)
    BackgroundMediaCorner.Parent = BackgroundMediaHolder

    -- Gradient side bar
    local SideBar = Instance.new("Frame")
    SideBar.Name = "GradientSide"
    SideBar.Parent = Container
    SideBar.Size = UDim2.new(0, 138, 1, 0)
    SideBar.Position = UDim2.new(0, 0, 0, 0)
    SideBar.BackgroundTransparency = 1
    SideBar.BackgroundColor3 = Color3.fromRGB(6, 6, 8)

    -- Side gradient (inverted colors)
    local SideGradient = Instance.new("UIGradient")
    SideGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(13, 13, 16)),
        ColorSequenceKeypoint.new(0.72, Color3.fromRGB(7, 7, 9)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(6, 6, 8))
    }
    SideGradient.Rotation = 90
    SideGradient.Parent = SideBar

    local CenterImage = Instance.new("ImageLabel")
    CenterImage.Name = "CenterImage"
    CenterImage.Parent = Container
    CenterImage.AnchorPoint = Vector2.new(0.5, 0.5)
    CenterImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    CenterImage.Size = UDim2.new(0, 300, 0, 300)
    CenterImage.BackgroundTransparency = 1
    CenterImage.Image = "rbxassetid://YOUR_IMAGE_ID"
    CenterImage.ScaleType = Enum.ScaleType.Fit
    CenterImage.ImageColor3 = UIAccentColor
    CenterImage.ImageTransparency = 1

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 16)
    UICorner.Parent = Container
    
    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(62, 62, 68)
    UIStroke.Transparency = 0.35
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container
    
    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = UDim2.new(0, 620, 0, 400)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handler.Parent = Container
    
    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 118, 0, 325)
    Tabs.Selectable = false
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0, 14, 0, 58)
    Tabs.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler
    
    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 4)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Tabs
    
    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = Color3.fromRGB(245, 245, 247)
    ClientName.TextTransparency = 0
    ClientName.Text = UIName
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 160, 0, 13)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0, 40, 0, 23)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.BorderSizePixel = 0
    ClientName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ClientName.TextSize = 13
    ClientName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.Parent = Handler
    
    local UIGradient = Instance.new('UIGradient')
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 155, 155)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    }
    UIGradient.Parent = ClientName
    
    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0, 14, 0, 66)
    Pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Pin.Size = UDim2.new(0, 3, 0, 18)
    Pin.BorderSizePixel = 0
    Pin.BackgroundColor3 = UIAccentColor
    Pin.Parent = Handler
    
    local UICorner2 = Instance.new('UICorner')
    UICorner2.CornerRadius = UDim.new(1, 0)
    UICorner2.Parent = Pin

        
local Icon = Instance.new('ImageLabel')
Icon.Name = 'Icon'
Icon.Parent = Handler
Icon.ImageColor3 = UIAccentColor
Icon.ScaleType = Enum.ScaleType.Fit
Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
Icon.AnchorPoint = Vector2.new(0, 0.5)
Icon.BackgroundTransparency = 1
Icon.Position = UDim2.new(0, 16, 0, 23)
Icon.Size = UDim2.new(0, 18, 0, 18)
Icon.BorderSizePixel = 0
Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

-- Animation function
local function AnimateGif(ImageLabel, Width, Height, Rows, Columns, NumberOfFrames, ImageID, FPS)
    if ImageID then ImageLabel.Image = ImageID end
    local RobloxMaxImageSize = 2048
    local RealWidth, RealHeight

    if math.max(Width, Height) > RobloxMaxImageSize then
        local Longest = Width > Height and "Width" or "Height"
        if Longest == "Width" then
            RealWidth = RobloxMaxImageSize
            RealHeight = (RealWidth / Width) * Height
        elseif Longest == "Height" then
            RealHeight = RobloxMaxImageSize
            RealWidth = (RealHeight / Height) * Width
        end
    else
        RealWidth, RealHeight = Width, Height
    end

    local FrameSize = Vector2.new(RealWidth / Columns, RealHeight / Rows)
    ImageLabel.ImageRectSize = FrameSize

    local CurrentRow, CurrentColumn = 0, 0
    local Offsets = {}

    for i = 1, NumberOfFrames do
        local CurrentX = CurrentColumn * FrameSize.X
        local CurrentY = CurrentRow * FrameSize.Y
        table.insert(Offsets, Vector2.new(CurrentX, CurrentY))
        CurrentColumn += 1

        if CurrentColumn >= Columns then
            CurrentColumn = 0
            CurrentRow += 1
        end
    end

    local TimeInterval = FPS and 1 / FPS or 0.1
    local Index = 0

    task.spawn(function()
        while task.wait(TimeInterval) and ImageLabel:IsDescendantOf(game) do
            Index += 1
            ImageLabel.ImageRectOffset = Offsets[Index]
            if Index >= NumberOfFrames then
                Index = 0
            end
        end
    end)
end

if IconAnimated then
    AnimateGif(Icon, IconSpriteWidth, IconSpriteHeight, IconSpriteRows, IconSpriteColumns, IconSpriteFrames, IconAsset, IconSpriteFPS)
else
    Icon.Image = IconAsset
end

local BackgroundMediaToken = 0

local function GetMediaExtensionFromSource(source)
	source = tostring(source or ""):lower()

	local clean = source:match("^([^%?#]+)") or source
	local extension = clean:match("%.([%w]+)$")

	if extension and #extension <= 5 then
		return extension
	end

	return nil
end

local function DetectMediaExtension(data, source, contentType)
	local extension = GetMediaExtensionFromSource(source)
	local content = tostring(contentType or ""):lower()

	if content:find("gif", 1, true) then return "gif" end
	if content:find("png", 1, true) then return "png" end
	if content:find("jpeg", 1, true) or content:find("jpg", 1, true) then return "jpg" end
	if content:find("webp", 1, true) then return "webp" end
	if content:find("mp4", 1, true) then return "mp4" end
	if content:find("webm", 1, true) then return "webm" end
	if content:find("quicktime", 1, true) then return "mov" end

	if type(data) == "string" and #data >= 12 then
		if data:sub(1, 6) == "GIF87a" or data:sub(1, 6) == "GIF89a" then return "gif" end
		if data:byte(1) == 137 and data:sub(2, 4) == "PNG" then return "png" end
		if data:byte(1) == 255 and data:byte(2) == 216 and data:byte(3) == 255 then return "jpg" end
		if data:sub(1, 4) == "RIFF" and data:sub(9, 12) == "WEBP" then return "webp" end
		if data:sub(5, 8) == "ftyp" then return extension == "mov" and "mov" or "mp4" end
		if data:byte(1) == 26 and data:byte(2) == 69 and data:byte(3) == 223 and data:byte(4) == 163 then return "webm" end
	end

	return extension or "png"
end

local function GetMediaTypeFromExtension(extension)
	extension = tostring(extension or ""):lower()

	if extension == "mp4" or extension == "webm" or extension == "mov" then
		return "video"
	end

	if extension == "gif" then
		return "gif"
	end

	return "image"
end

local function FetchMedia(source)
	local requestFunction = request or syn and syn.request or http_request

	if type(requestFunction) == "function" then
		local ok, response = pcall(requestFunction, {
			Url = source,
			Method = "GET"
		})

		if ok and type(response) == "table" then
			local body = response.Body or response.body
			local headers = response.Headers or response.headers or {}
			local contentType = headers["Content-Type"] or headers["content-type"] or headers["content-Type"]

			if type(body) == "string" and body ~= "" then
				return body, contentType
			end
		end
	end

	local ok, data = pcall(function()
		return game:HttpGet(source, true)
	end)

	if ok and type(data) == "string" and data ~= "" then
		return data, nil
	end

	return nil, nil
end

local function ResolveBackgroundMediaAsset(source, name)
	source = ResolveAssetId(source)

	if typeof(source) ~= "string" or source == "" then
		return nil, nil
	end

	local localExtension = GetMediaExtensionFromSource(source)

	if not source:match("^https?://") and type(isfile) == "function" and type(getcustomasset) == "function" and isfile(source) then
		local ok, customAsset = pcall(getcustomasset, source)

		if ok and customAsset then
			return customAsset, GetMediaTypeFromExtension(localExtension)
		end
	end

	if source:match("^https?://") and type(writefile) == "function" and type(getcustomasset) == "function" then
		local mediaFolder = ConfigFolder .. "/BackgroundMedia"

		if type(isfolder) == "function" and type(makefolder) == "function" then
			if not isfolder(ConfigFolder) then
				pcall(makefolder, ConfigFolder)
			end

			if not isfolder(mediaFolder) then
				pcall(makefolder, mediaFolder)
			end
		end

		local fileName = tostring(name or "background_media"):gsub("[^%w_%-]", "_")
		local data, contentType = FetchMedia(source)
		local extension = DetectMediaExtension(data, source, contentType)
		local mediaType = GetMediaTypeFromExtension(extension)
		local filePath = mediaFolder .. "/" .. fileName .. "." .. extension

		if type(data) == "string" and data ~= "" then
			local ok = pcall(writefile, filePath, data)

			if not ok and extension ~= "png" then
				extension = "png"
				mediaType = "image"
				filePath = mediaFolder .. "/" .. fileName .. ".png"
				pcall(writefile, filePath, data)
			end
		end

		if type(isfile) == "function" and not isfile(filePath) then
			return nil, nil
		end

		if type(isfile) ~= "function" or isfile(filePath) then
			local ok, customAsset = pcall(getcustomasset, filePath)

			if ok and customAsset then
				return customAsset, mediaType
			end
		end
	end

	return source, GetMediaTypeFromExtension(localExtension)
end

local function ResolveScaleType(value)
	if typeof(value) == "EnumItem" then
		return value
	end

	if typeof(value) == "string" and Enum.ScaleType[value] then
		return Enum.ScaleType[value]
	end

	return Enum.ScaleType.Crop
end

local function ClearBackgroundMedia()
	BackgroundMediaToken += 1
	BackgroundMediaHolder.Visible = false

	for _, child in BackgroundMediaHolder:GetChildren() do
		if child ~= BackgroundMediaCorner then
			child:Destroy()
		end
	end

	-- Restore the container background when media is cleared
	pcall(function()
		Container.BackgroundTransparency = 0.16
		ContainerGradient.Enabled = true
		SideBar.BackgroundTransparency = 1
		SideGradient.Enabled = true
	end)
end

function self:ClearBackgroundMedia()
	ClearBackgroundMedia()
end

function self:SetBackgroundMedia(mediaSettings)
	if mediaSettings == nil or mediaSettings == false then
		ClearBackgroundMedia()
		return false
	end

	if typeof(mediaSettings) ~= "table" then
		mediaSettings = {
			Source = mediaSettings
		}
	end

	if mediaSettings.Enabled == false or mediaSettings.enabled == false then
		ClearBackgroundMedia()
		return false
	end

	local requestedMediaType = mediaSettings.Type or mediaSettings.type or mediaSettings.MediaType or mediaSettings.mediaType or mediaSettings.media_type
	local mediaType = tostring(requestedMediaType or "auto"):lower()

	if mediaType == "none" or mediaType == "off" or mediaType == "clear" then
		ClearBackgroundMedia()
		return false
	end

	local source = mediaSettings.Source or mediaSettings.source or mediaSettings.Asset or mediaSettings.asset or mediaSettings.Url or mediaSettings.url or mediaSettings.Image or mediaSettings.image or mediaSettings.Video or mediaSettings.video
	local asset, detectedMediaType = ResolveBackgroundMediaAsset(source, mediaSettings.SaveAs or mediaSettings.saveAs or mediaSettings.Name or mediaSettings.name)

	if not asset then
		ClearBackgroundMedia()
		return false
	end

	if mediaType == "auto" or mediaType == "" then
		mediaType = detectedMediaType or "image"
	end

	-- Check opacity early; if zero, clear and return (keep container background)
	local opacity = Clamp01(mediaSettings.Opacity or mediaSettings.opacity) or 0.45
	if opacity <= 0 then
		ClearBackgroundMedia()
		return false
	end

	ClearBackgroundMedia()
	BackgroundMediaToken += 1

	local token = BackgroundMediaToken

	local media

	if mediaType == "video" or mediaType == "mp4" or mediaType == "webm" then
		media = Instance.new("VideoFrame")
		media.Video = asset
		media.Looped = mediaSettings.Looped ~= false and mediaSettings.looped ~= false
		media.Volume = tonumber(mediaSettings.Volume or mediaSettings.volume) or 0
		pcall(function()
			media.Transparency = 1 - opacity
		end)
		pcall(function()
			media:Play()
		end)
	else
		media = Instance.new("ImageLabel")
		media.Image = asset
		media.ImageTransparency = 1 - opacity
		media.ImageColor3 = mediaSettings.Color or mediaSettings.color or Color3.fromRGB(255, 255, 255)
		media.ScaleType = ResolveScaleType(mediaSettings.ScaleType or mediaSettings.scaleType)

		if mediaType == "gif" or mediaType == "sprite" then
			local width = tonumber(mediaSettings.Width or mediaSettings.width)
			local height = tonumber(mediaSettings.Height or mediaSettings.height)
			local rows = tonumber(mediaSettings.Rows or mediaSettings.rows)
			local columns = tonumber(mediaSettings.Columns or mediaSettings.columns)
			local frames = tonumber(mediaSettings.Frames or mediaSettings.frames)
			local fps = tonumber(mediaSettings.FPS or mediaSettings.fps)

			if width and height and rows and columns and frames then
				AnimateGif(media, width, height, rows, columns, frames, asset, fps)
			end
		end
	end

	media.Name = "Media"
	media.BackgroundTransparency = 1
	media.BorderSizePixel = 0
	media.Size = UDim2.fromScale(1, 1)
	media.Position = UDim2.fromScale(0, 0)
	media.ZIndex = 0
	media.Parent = BackgroundMediaHolder

	if media:IsA("VideoFrame") then
		pcall(function()
			media.Playing = true
		end)
		pcall(function()
			media:Play()
		end)
	end

	local dimOpacity = Clamp01(mediaSettings.DimOpacity or mediaSettings.dimOpacity or mediaSettings.dim_opacity)

	if dimOpacity and dimOpacity > 0 then
		local dim = Instance.new("Frame")
		dim.Name = "Dim"
		dim.BackgroundColor3 = mediaSettings.DimColor or mediaSettings.dimColor or Color3.fromRGB(0, 0, 0)
		dim.BackgroundTransparency = 1 - dimOpacity
		dim.BorderSizePixel = 0
		dim.Size = UDim2.fromScale(1, 1)
		dim.Position = UDim2.fromScale(0, 0)
		dim.ZIndex = 0
		dim.Parent = BackgroundMediaHolder
	end

	BackgroundMediaHolder.Visible = token == BackgroundMediaToken

	-- Only set container transparent when media is visible (opacity > 0)
	if token == BackgroundMediaToken then
		pcall(function()
			Container.BackgroundTransparency = 1
			ContainerGradient.Enabled = false
			SideBar.BackgroundTransparency = 1
			SideGradient.Enabled = false
		end)
	end

	return true
end

self.set_background_media = self.SetBackgroundMedia
self.clear_background_media = self.ClearBackgroundMedia
self.SetBackgroundImage = self.SetBackgroundMedia
self.set_background_image = self.SetBackgroundMedia
    
    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.25
    Divider.Position = UDim2.new(0, 138, 0, 56)
    Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 316)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Color3.fromRGB(46, 46, 49)
    Divider.Parent = Handler
    
    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler
    
    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.020057305693626404, 0, 0.02922755666077137, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 14
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.Parent = Handler

    local SearchIcon = Instance.new('ImageLabel')
    SearchIcon.Name = 'SearchIcon'
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.Position = UDim2.new(1, -30, 0, 17)
    SearchIcon.Size = UDim2.fromOffset(18, 18)
    SearchIcon.Image = 'rbxassetid://10734943674'
    SearchIcon.ImageColor3 = Color3.fromRGB(185, 185, 190)
    SearchIcon.ImageTransparency = 0.1
    SearchIcon.ScaleType = Enum.ScaleType.Fit
    SearchIcon.Parent = Handler
    
    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container    
    
    self._ui = Frostware
    self._background_media_holder = BackgroundMediaHolder

    local function on_drag(input: InputObject, process: boolean)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            self._dragging = true
            self._drag_start = input.Position
            self._container_position = Container.Position

            Connections['container_input_ended'] = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Connections:disconnect('container_input_ended')
                self._dragging = false
            end)
        end
    end

    local function update_drag(input: any)
        local delta = input.Position - self._drag_start
        local position = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)

        TweenService:Create(Container, TweenInfo.new(0.2), {
            Position = position
        }):Play()
    end

    local function drag(input: InputObject, process: boolean)
        if not self._dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        self._ui = nil
        Connections:disconnect_all()
    end)

    function self:Update1Run(a)
        if a == "nil" then
            Container.BackgroundTransparency = 0.05000000074505806;
        else
            pcall(function()
                Container.BackgroundTransparency = tonumber(a);
            end);
        end;
    end;

    function self:UIVisiblity()
        Frostware.Enabled = not Frostware.Enabled;
    end;

    function self:change_visiblity(state: boolean)
        if state then
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(620, 400)
            }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
        end
    end
    

    function self:load()
        local content = {}
    
        for _, object in Frostware:GetDescendants() do
            if not object:IsA('ImageLabel') then
                continue
            end
    
            table.insert(content, object)
        end
    
        ContentProvider:PreloadAsync(content)
        self:get_device()

        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale
    
            Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
            end)
        end
    
        TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(620, 400)
        }):Play()

        AcrylicBlur.new(Container)
        self._ui_loaded = true
    end

    function self:update_tabs(tab: TextButton)
        for index, object in Tabs:GetChildren() do
            if object.Name ~= 'Tab' then
                continue
            end

            if object == tab then
                if object.BackgroundTransparency ~= 0.5 then
                    local offset = object.LayoutOrder * 42

                    TweenService:Create(Pin, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, 14, 0, 66 + offset)
                    }):Play()    

                    TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.5
                    }):Play()

                    TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0,
                        TextColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()

                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0)
                    }):Play()

                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0,
                        ImageColor3 = UIAccentColor
                    }):Play()
                end

                continue
            end

            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
                
                TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.45,
                    TextColor3 = Color3.fromRGB(170, 170, 176)
                }):Play()

                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(0, 0)
                }):Play()

                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.45,
                    ImageColor3 = Color3.fromRGB(170, 170, 176)
                }):Play()
            end
        end
    end

    function self:update_sections(left_section: ScrollingFrame, right_section: ScrollingFrame)
        for _, object in Sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true

                continue
            end

            object.Visible = false
        end
    end

    function self:create_tab(title: string, icon: string)
        icon = ResolveAssetId(icon)
        local TabManager = {}

        local LayoutOrder = 0;

        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = title
        font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 13
        font_params.Width = 10000

        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not Tabs:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Tab.TextColor3 = Color3.fromRGB(0, 0, 0)
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 110, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
        Tab.Parent = Tabs
        Tab.LayoutOrder = self._tab
        
        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 6)
        UICorner.Parent = Tab
        
        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Color3.fromRGB(170, 170, 176)
        TextLabel.TextTransparency = 0.45
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0, 32, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BorderSizePixel = 0
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.TextSize = 13
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.Parent = Tab
        
        local UIGradient = Instance.new('UIGradient')
        UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(155, 155, 155)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 58, 58))
        }
        UIGradient.Parent = TextLabel
        
        local Icon = Instance.new('ImageLabel')
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.ImageTransparency = 0.45
        Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0, 11, 0.5, 0)
        Icon.Name = 'Icon'
        Icon.Image = icon or ""
        Icon.Size = UDim2.new(0, 12, 0, 12)
        Icon.BorderSizePixel = 0
        Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Icon.Parent = Tab

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.Size = UDim2.new(0, 218, 0, 316)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0)
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0, 155, 0, 70)
        LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LeftSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        LeftSection.BorderSizePixel = 0
        LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        LeftSection.Visible = false
        LeftSection.Parent = Sections
        
        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = LeftSection
        
        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = LeftSection

        local RightSection = Instance.new('ScrollingFrame')
        RightSection.Name = 'RightSection'
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, 218, 0, 316)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0, 385, 0, 70)
        RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RightSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        RightSection.BorderSizePixel = 0
        RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        RightSection.Visible = false
        RightSection.Parent = Sections
        
        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = RightSection
        
        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = RightSection

        self._tab += 1

        if first_tab then
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end)

function TabManager:moduleparagraph(settings: any)

    local LayoutOrderModule = 0;

    local ModuleManager = {
        _size = 0,
        _multiplier = 0
    }

    if settings.section == 'right' then
        settings.section = RightSection
    else
        settings.section = LeftSection
    end

    local Module = Instance.new('Frame')
    Module.ClipsDescendants = true
    Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Module.BackgroundTransparency = 0.18
    Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
    Module.Name = 'ModuleParagraph'
    Module.Size = UDim2.new(0, 218, 0, 70)
    Module.BorderSizePixel = 0
    Module.BackgroundColor3 = Color3.fromRGB(12, 12, 13)
    Module.Parent = settings.section

    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Module
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = Module
    
    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(48, 48, 52)
    UIStroke.Transparency = 0.3
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Module
    
    local Header = Instance.new('Frame')
    Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Header.Name = 'Header'
    Header.Size = UDim2.new(0, 218, 0, 70)
    Header.BorderSizePixel = 0
    Header.BackgroundTransparency = 1
    Header.Parent = Module

    local ModuleName = Instance.new('TextLabel')
    ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ModuleName.TextColor3 = UIAccentColor
    ModuleName.TextTransparency = 0.20000000298023224
    if not settings.rich then
        ModuleName.Text = settings.title or "Paragraph Title"
    else
        ModuleName.RichText = true
        ModuleName.Text = settings.richtext or "<font color='rgb(255,0,0)'>" .. UIName .. "</font> Info"
    end
    ModuleName.Name = 'ModuleName'
    ModuleName.Size = UDim2.new(0, 184, 0, 13)
    ModuleName.AnchorPoint = Vector2.new(0, 0.5)
    ModuleName.Position = UDim2.new(0.0729999989271164, 0, 0.23999999463558197, 0)
    ModuleName.BackgroundTransparency = 1
    ModuleName.TextXAlignment = Enum.TextXAlignment.Left
    ModuleName.BorderSizePixel = 0
    ModuleName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ModuleName.TextSize = 13
    ModuleName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ModuleName.Parent = Header
    
    local Description = Instance.new('TextLabel')
    Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Description.TextColor3 = UIAccentColor
    Description.TextTransparency = 0.699999988079071
    Description.Text = settings.description or "This is a description paragraph."
    Description.Name = 'Description'
    Description.Size = UDim2.new(0, 184, 0, 28)
    Description.AnchorPoint = Vector2.new(0, 0.5)
    Description.Position = UDim2.new(0.0729999989271164, 0, 0.55, 0)
    Description.BackgroundTransparency = 1
    Description.TextXAlignment = Enum.TextXAlignment.Left
    Description.TextYAlignment = Enum.TextYAlignment.Top
    Description.TextWrapped = true
    Description.BorderSizePixel = 0
    Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Description.TextSize = 10
    Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Description.Parent = Header

    return ModuleManager
end

function TabManager:create_image(settings: any)

    if settings.section == 'right' then
        settings.section = RightSection
    else
        settings.section = LeftSection
    end

    local Module = Instance.new('Frame')
    Module.ClipsDescendants = true
    Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Module.BackgroundTransparency = 0.18
    Module.Position = UDim2.new(0.004, 0, 0, 0)
    Module.Name = 'ImageModule'
    Module.Size = UDim2.new(0, 218, 0, 140) 
    Module.BorderSizePixel = 0
    Module.BackgroundColor3 = Color3.fromRGB(12, 12, 13)
    Module.Parent = settings.section

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = Module
    
    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(48, 48, 52)
    UIStroke.Transparency = 0.3
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Module
    
    local Image = Instance.new("ImageLabel")
    Image.Name = "GameImage"
    Image.Parent = Module
    Image.AnchorPoint = Vector2.new(0.5, 0.5) 
    Image.Position = UDim2.new(0.5, 0, 0.5, 0) 
    Image.Size = UDim2.new(0, 215, 0, 120)  
    Image.BackgroundTransparency = 1
    Image.Image = settings.image or "rbxassetid://123456789"

    local ImageCorner = Instance.new("UICorner")
    ImageCorner.CornerRadius = UDim.new(0, 7)  
    ImageCorner.Parent = Image
end

        function TabManager:create_module(settings: any)

            local LayoutOrderModule = 0;

            local ModuleManager = {
                _state = false,
                _size = 0,
                _multiplier = 0
            }

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.18
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 218, 0, 93)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(12, 12, 13)
            Module.Parent = settings.section

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 6)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(48, 48, 52)
            UIStroke.Transparency = 0.3
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            
            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(0, 0, 0)
            Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 218, 0, 93)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Header.Parent = Module
            
            local Icon = Instance.new('ImageLabel')
            Icon.ImageColor3 = UIAccentColor
            Icon.ScaleType = Enum.ScaleType.Fit
            Icon.ImageTransparency = 0.699999988079071
            Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Image = 'rbxassetid://79095934438045'
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0.07100000232458115, 0, 0.8199999928474426, 0)
            Icon.Name = 'Icon'
            Icon.Size = UDim2.new(0, 15, 0, 15)
            Icon.BorderSizePixel = 0
            Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Icon.Parent = Header
            
            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = UIAccentColor
            ModuleName.TextTransparency = 0.20000000298023224
            if not settings.rich then
                ModuleName.Text = settings.title or "Skibidi"
            else
                ModuleName.RichText = true
                ModuleName.Text = settings.richtext or "<font color='rgb(255,0,0)'>" .. UIName .. "</font> user"
            end;
            ModuleName.Name = 'ModuleName'
            ModuleName.Size = UDim2.new(0, 184, 0, 13)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0.0729999989271164, 0, 0.23999999463558197, 0)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.BorderSizePixel = 0
            ModuleName.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ModuleName.TextSize = 13
            ModuleName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ModuleName.Parent = Header
            
            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = UIAccentColor
            Description.TextTransparency = 0.699999988079071
            Description.Text = settings.description
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 184, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0.0729999989271164, 0, 0.41999998688697815, 0)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.BorderSizePixel = 0
            Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Description.TextSize = 10
            Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Description.Parent = Header
            
            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0.699999988079071
            Toggle.Position = UDim2.new(0.8199999928474426, 0, 0.7570000290870667, 0)
            Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Size = UDim2.new(0, 25, 0, 12)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Parent = Header
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Toggle
            
            local Circle = Instance.new('Frame')
            Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0.20000000298023224
            Circle.Position = UDim2.new(0, 0, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Circle.Parent = Toggle
            
            local UICorner2 = Instance.new('UICorner')
            UICorner2.CornerRadius = UDim.new(1, 0)
            UICorner2.Parent = Circle

            function ModuleManager:change_state(state: any)
                if state then
                    Toggle.BackgroundColor3 = UIAccentColor
                    Toggle.BackgroundTransparency = 0.2
                    TweenService:Create(Circle, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        Position = UDim2.new(0.5, 0, 0.5, 0)
                    }):Play()
                else
                    Toggle.BackgroundColor3 = Color3.fromRGB(23, 23, 25)
                    Toggle.BackgroundTransparency = 0.1
                    TweenService:Create(Circle, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        Position = UDim2.new(0, 0, 0.5, 0)
                    }):Play()
                end

                self._state = state
                Library._config._flags[settings.flag] = state

                if settings.callback then
                    settings.callback(state)
                end

                Config:save(game.GameId, Library._config)
            end

            local saved_flag = Library._config._flags[settings.flag]

            if saved_flag then
                ModuleManager:change_state(saved_flag)
            end

            Header.MouseButton1Click:Connect(function()
                ModuleManager:change_state(not self._state)
            end)

            return ModuleManager
        end

        function TabManager:create_checkbox(settings: any)

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.18
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 218, 0, 49)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(12, 12, 13)
            Module.Parent = settings.section

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 6)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(48, 48, 52)
            UIStroke.Transparency = 0.3
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            
            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(0, 0, 0)
            Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 218, 0, 49)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Header.Parent = Module
            
            local Title = Instance.new('TextLabel')
            Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Title.TextColor3 = UIAccentColor
            Title.TextTransparency = 0.30000001192092896
            Title.Text = settings.title or "Checkbox Title"
            Title.Name = 'Title'
            Title.Size = UDim2.new(0, 184, 0, 13)
            Title.AnchorPoint = Vector2.new(0, 0.5)
            Title.Position = UDim2.new(0.0729999989271164, 0, 0.5, 0)
            Title.BackgroundTransparency = 1
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.BorderSizePixel = 0
            Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Title.TextSize = 13
            Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Title.Parent = Header
            
            local Circle = Instance.new('Frame')
            Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0.4000000059604645
            Circle.Position = UDim2.new(0.9200000166893005, 0, 0.5, 0)
            Circle.Size = UDim2.new(0, 14, 0, 14)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Circle.Parent = Header
            
            local UICorner2 = Instance.new('UICorner')
            UICorner2.CornerRadius = UDim.new(1, 0)
            UICorner2.Parent = Circle
            
            local Check = Instance.new('Frame')
            Check.Name = 'Check'
            Check.BackgroundTransparency = 1
            Check.Position = UDim2.new(0.21000000834465027, 0, 0.2199999988079071, 0)
            Check.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Check.Size = UDim2.new(0, 8, 0, 8)
            Check.BorderSizePixel = 0
            Check.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Check.Parent = Circle
            
            local UICorner3 = Instance.new('UICorner')
            UICorner3.CornerRadius = UDim.new(1, 0)
            UICorner3.Parent = Check

            function ModuleManager:change_state(state: any)
                if state then
                    TweenService:Create(Circle, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = UIAccentColor
                    }):Play()

                    TweenService:Create(Check, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()
                else
                    TweenService:Create(Circle, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()

                    TweenService:Create(Check, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()
                end

                self._state = state
                Library._config._flags[settings.flag] = state

                if settings.callback then
                    settings.callback(state)
                end

                Config:save(game.GameId, Library._config)
            end

            local saved_flag = Library._config._flags[settings.flag]

            if saved_flag ~= nil then
                ModuleManager:change_state(saved_flag)
            end

            local ModuleManager = {
                change_state = function(self, state)
                    ModuleManager:change_state(state)
                end,
                _state = self._state
            }

            Header.MouseButton1Click:Connect(function()
                ModuleManager:change_state(not self._state)
            end)

            return ModuleManager
        end

        function TabManager:create_slider(settings: any)

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.18
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 218, 0, 72)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(12, 12, 13)
            Module.Parent = settings.section

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 6)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(48, 48, 52)
            UIStroke.Transparency = 0.3
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            
            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(0, 0, 0)
            Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 218, 0, 72)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Header.Parent = Module
            
            local Title = Instance.new('TextLabel')
            Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Title.TextColor3 = UIAccentColor
            Title.TextTransparency = 0.30000001192092896
            Title.Text = settings.title or "Slider Title"
            Title.Name = 'Title'
            Title.Size = UDim2.new(0, 184, 0, 13)
            Title.AnchorPoint = Vector2.new(0, 0.5)
            Title.Position = UDim2.new(0.0729999989271164, 0, 0.30000001192092896, 0)
            Title.BackgroundTransparency = 1
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.BorderSizePixel = 0
            Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Title.TextSize = 13
            Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Title.Parent = Header
            
            local Value = Instance.new('TextLabel')
            Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Value.TextColor3 = UIAccentColor
            Value.TextTransparency = 0.5
            Value.Text = settings.value or "0"
            Value.Name = 'Value'
            Value.Size = UDim2.new(0, 184, 0, 13)
            Value.AnchorPoint = Vector2.new(0, 0.5)
            Value.Position = UDim2.new(0.0729999989271164, 0, 0.6000000238418579, 0)
            Value.BackgroundTransparency = 1
            Value.TextXAlignment = Enum.TextXAlignment.Right
            Value.BorderSizePixel = 0
            Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Value.TextSize = 13
            Value.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Value.Parent = Header
            
            local Bar = Instance.new('Frame')
            Bar.Name = 'Bar'
            Bar.BackgroundColor3 = Color3.fromRGB(23, 23, 25)
            Bar.BackgroundTransparency = 0.2
            Bar.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Bar.Position = UDim2.new(0.0729999989271164, 0, 0.75, 0)
            Bar.Size = UDim2.new(0.855, 0, 0, 3)
            Bar.BorderSizePixel = 0
            Bar.Parent = Header

            local BarCorner = Instance.new('UICorner')
            BarCorner.CornerRadius = UDim.new(1, 0)
            BarCorner.Parent = Bar
            
            local Filled = Instance.new('Frame')
            Filled.Name = 'Filled'
            Filled.BackgroundColor3 = UIAccentColor
            Filled.BackgroundTransparency = 0.2
            Filled.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Filled.Position = UDim2.new(0.0729999989271164, 0, 0.75, 0)
            Filled.Size = UDim2.new(0.5, 0, 0, 3)
            Filled.BorderSizePixel = 0
            Filled.Parent = Header

            local FilledCorner = Instance.new('UICorner')
            FilledCorner.CornerRadius = UDim.new(1, 0)
            FilledCorner.Parent = Filled

            function ModuleManager:update_value(value: any)
                if not settings.round_number then
                    Value.Text = tostring(value)
                else
                    Value.Text = math.round(value)
                end
            end

            local minimum_value = settings.minimum_value or 0
            local maximum_value = settings.maximum_value or 100
            local flag = settings.flag

            local saved_value = Library._config._flags[flag]

            if saved_value then
                if settings.value then
                    settings.value = saved_value
                else
                    local min = minimum_value
                    local max = maximum_value
                    local value = saved_value

                    if value < min then
                        value = min
                    elseif value > max then
                        value = max
                    end

                    settings.value = value
                end
            end

            local value = settings.value or 0
            local percentage = (value - minimum_value) / (maximum_value - minimum_value)

            Filled.Size = UDim2.new(percentage * 0.855, 0, 0, 3)

            ModuleManager:update_value(value)

            local dragging = false

            Header.MouseButton1Down:Connect(function()
                dragging = true
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if not dragging then
                    return
                end

                if input.UserInputType ~= Enum.UserInputType.MouseMovement then
                    return
                end

                local position = input.Position
                local absolute_position = Header.AbsolutePosition
                local absolute_size = Header.AbsoluteSize

                local x = math.clamp(position.X - absolute_position.X, 0, absolute_size.X)
                local percentage = math.clamp(x / absolute_size.X, 0, 1)
                local value = minimum_value + percentage * (maximum_value - minimum_value)

                if settings.round_number then
                    value = math.round(value)
                end

                settings.value = value
                Filled.Size = UDim2.new(percentage * 0.855, 0, 0, 3)
                ModuleManager:update_value(value)

                Library._config._flags[flag] = value

                if settings.callback then
                    settings.callback(value)
                end

                Config:save(game.GameId, Library._config)
            end)

            local ModuleManager = {
                change_state = function(self, state)
                    self._state = state
                    Library._config._flags[settings.flag] = state
                    Config:save(game.GameId, Library._config)
                end,
                _state = self._state
            }

            return ModuleManager
        end

        function TabManager:create_dropdown(settings: any)

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local options = settings.options or {}
            local multi_dropdown = settings.multi_dropdown or false

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.18
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 218, 0, 36)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(12, 12, 13)
            Module.Parent = settings.section

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 6)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(48, 48, 52)
            UIStroke.Transparency = 0.3
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            
            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(0, 0, 0)
            Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 218, 0, 36)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Header.Parent = Module
            
            local Title = Instance.new('TextLabel')
            Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Title.TextColor3 = UIAccentColor
            Title.TextTransparency = 0.30000001192092896
            Title.Text = settings.title or "Dropdown Title"
            Title.Name = 'Title'
            Title.Size = UDim2.new(0, 184, 0, 13)
            Title.AnchorPoint = Vector2.new(0, 0.5)
            Title.Position = UDim2.new(0.0729999989271164, 0, 0.5, 0)
            Title.BackgroundTransparency = 1
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.BorderSizePixel = 0
            Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Title.TextSize = 13
            Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Title.Parent = Header
            
            local Arrow = Instance.new('ImageLabel')
            Arrow.Name = 'Arrow'
            Arrow.BackgroundTransparency = 1
            Arrow.Size = UDim2.new(0, 12, 0, 12)
            Arrow.AnchorPoint = Vector2.new(1, 0.5)
            Arrow.Position = UDim2.new(0.93, 0, 0.5, 0)
            Arrow.Image = 'rbxassetid://10734943285'
            Arrow.ImageColor3 = UIAccentColor
            Arrow.ImageTransparency = 0.5
            Arrow.ScaleType = Enum.ScaleType.Fit
            Arrow.Parent = Header
            
            local Dropdown = Instance.new('Frame')
            Dropdown.Name = 'Dropdown'
            Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Dropdown.BackgroundTransparency = 0.18
            Dropdown.Position = UDim2.new(0, 0, 0, 36)
            Dropdown.Size = UDim2.new(0, 218, 0, 0)
            Dropdown.ClipsDescendants = true
            Dropdown.BorderSizePixel = 0
            Dropdown.BackgroundColor3 = Color3.fromRGB(12, 12, 13)
            Dropdown.Parent = Module
            
            local UIListLayout2 = Instance.new('UIListLayout')
            UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout2.Parent = Dropdown

            local ModuleManager = {
                _state = false,
                _selected = {},
                _multi = multi_dropdown,
                _options = options,
                _dropdown = Dropdown,
                _arrow = Arrow,
                _header = Header,
                _callback = settings.callback
            }

            -- If multi dropdown, default selected is table; else single string
            local saved_flag = Library._config._flags[settings.flag]

            if saved_flag then
                if multi_dropdown then
                    if type(saved_flag) == "table" then
                        ModuleManager._selected = saved_flag
                    else
                        ModuleManager._selected = {}
                    end
                else
                    if type(saved_flag) == "string" then
                        ModuleManager._selected = saved_flag
                    else
                        ModuleManager._selected = options[1] or "None"
                    end
                end
            else
                if multi_dropdown then
                    ModuleManager._selected = {}
                else
                    ModuleManager._selected = options[1] or "None"
                end
            end

            local function update_title()
                if multi_dropdown then
                    local selected_text = table.concat(ModuleManager._selected, ", ")
                    if selected_text == "" then
                        selected_text = "None"
                    end
                    Title.Text = settings.title .. " (" .. selected_text .. ")"
                else
                    Title.Text = settings.title .. " (" .. tostring(ModuleManager._selected) .. ")"
                end
            end

            -- Create option buttons
            local function create_options()
                for _, child in Dropdown:GetChildren() do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                local max_options = settings.maximum_options or #options
                for index, option in ipairs(options) do
                    if index > max_options then
                        break
                    end

                    local Option = Instance.new('TextButton')
                    Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    Option.TextColor3 = UIAccentColor
                    Option.TextTransparency = 0.5
                    Option.Text = option
                    Option.Size = UDim2.new(1, 0, 0, 24)
                    Option.BackgroundTransparency = 1
                    Option.Name = 'Option'
                    Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    Option.BorderSizePixel = 0
                    Option.TextSize = 12
                    Option.TextXAlignment = Enum.TextXAlignment.Left
                    Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Option.Parent = Dropdown

                    -- Highlight if selected
                    local is_selected = false
                    if multi_dropdown then
                        for _, selected in ipairs(ModuleManager._selected) do
                            if selected == option then
                                is_selected = true
                                break
                            end
                        end
                    else
                        is_selected = (ModuleManager._selected == option)
                    end

                    if is_selected then
                        Option.TextTransparency = 0
                        Option.TextColor3 = UIAccentColor
                    end

                    Option.MouseButton1Click:Connect(function()
                        if multi_dropdown then
                            local found = false
                            for i, selected in ipairs(ModuleManager._selected) do
                                if selected == option then
                                    table.remove(ModuleManager._selected, i)
                                    found = true
                                    break
                                end
                            end
                            if not found then
                                table.insert(ModuleManager._selected, option)
                            end
                        else
                            ModuleManager._selected = option
                        end

                        -- Update highlights
                        for _, child in Dropdown:GetChildren() do
                            if child:IsA("TextButton") then
                                local selected_state = false
                                if multi_dropdown then
                                    for _, selected in ipairs(ModuleManager._selected) do
                                        if selected == child.Text then
                                            selected_state = true
                                            break
                                        end
                                    end
                                else
                                    selected_state = (ModuleManager._selected == child.Text)
                                end

                                if selected_state then
                                    child.TextTransparency = 0
                                    child.TextColor3 = UIAccentColor
                                else
                                    child.TextTransparency = 0.5
                                    child.TextColor3 = UIAccentColor
                                end
                            end
                        end

                        update_title()

                        Library._config._flags[settings.flag] = ModuleManager._selected

                        if ModuleManager._callback then
                            ModuleManager._callback(ModuleManager._selected)
                        end

                        Config:save(game.GameId, Library._config)
                    end)
                end
            end

            create_options()

            -- Toggle dropdown visibility
            Header.MouseButton1Click:Connect(function()
                ModuleManager._state = not ModuleManager._state

                if ModuleManager._state then
                    TweenService:Create(Dropdown, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        Size = UDim2.new(0, 218, 0, math.min(#options, settings.maximum_options or #options) * 24)
                    }):Play()

                    TweenService:Create(Arrow, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        Rotation = 180
                    }):Play()
                else
                    TweenService:Create(Dropdown, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        Size = UDim2.new(0, 218, 0, 0)
                    }):Play()

                    TweenService:Create(Arrow, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        Rotation = 0
                    }):Play()
                end
            end)

            update_title()

            -- Add update method for the dropdown (to change options dynamically)
            function ModuleManager:update(new_options)
                ModuleManager._options = new_options or {}
                options = ModuleManager._options
                -- Reset selected
                if multi_dropdown then
                    ModuleManager._selected = {}
                else
                    ModuleManager._selected = options[1] or "None"
                end
                create_options()
                update_title()
                -- Close dropdown
                ModuleManager._state = false
                Dropdown.Size = UDim2.new(0, 218, 0, 0)
                Arrow.Rotation = 0
                Library._config._flags[settings.flag] = ModuleManager._selected
                Config:save(game.GameId, Library._config)
                if ModuleManager._callback then
                    ModuleManager._callback(ModuleManager._selected)
                end
            end

            return ModuleManager
        end

        function TabManager:create_textbox(settings: any)

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.18
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 218, 0, 56)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(12, 12, 13)
            Module.Parent = settings.section

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 6)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(48, 48, 52)
            UIStroke.Transparency = 0.3
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            
            local Title = Instance.new('TextLabel')
            Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Title.TextColor3 = UIAccentColor
            Title.TextTransparency = 0.30000001192092896
            Title.Text = settings.title or "Textbox"
            Title.Name = 'Title'
            Title.Size = UDim2.new(0, 184, 0, 13)
            Title.AnchorPoint = Vector2.new(0, 0.5)
            Title.Position = UDim2.new(0.0729999989271164, 0, 0.30000001192092896, 0)
            Title.BackgroundTransparency = 1
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.BorderSizePixel = 0
            Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Title.TextSize = 13
            Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Title.Parent = Module
            
            local TextBox = Instance.new('TextBox')
            TextBox.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TextBox.TextColor3 = Color3.fromRGB(155, 155, 160)
            TextBox.Text = settings.placeholder or "Enter text..."
            TextBox.Name = 'TextBox'
            TextBox.Size = UDim2.new(0.855, 0, 0, 22)
            TextBox.AnchorPoint = Vector2.new(0, 0.5)
            TextBox.Position = UDim2.new(0.0729999989271164, 0, 0.7099999785423279, 0)
            TextBox.BackgroundTransparency = 0.2
            TextBox.TextXAlignment = Enum.TextXAlignment.Left
            TextBox.BorderSizePixel = 0
            TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TextBox.TextSize = 12
            TextBox.BackgroundColor3 = Color3.fromRGB(23, 23, 25)
            TextBox.Parent = Module
            
            local UICorner2 = Instance.new('UICorner')
            UICorner2.CornerRadius = UDim.new(0, 4)
            UICorner2.Parent = TextBox

            -- Set saved text
            local saved_flag = Library._config._flags[settings.flag]
            if saved_flag then
                TextBox.Text = tostring(saved_flag)
            end

            TextBox.FocusLost:Connect(function()
                local text = TextBox.Text
                if settings.numeric then
                    local num = tonumber(text)
                    if num then
                        text = tostring(num)
                        TextBox.Text = text
                    else
                        text = ""
                        TextBox.Text = ""
                    end
                end

                Library._config._flags[settings.flag] = text
                if settings.callback then
                    settings.callback(text)
                end
                Config:save(game.GameId, Library._config)
            end)

            local ModuleManager = {
                update_text = function(self, new_text)
                    TextBox.Text = tostring(new_text)
                    Library._config._flags[settings.flag] = TextBox.Text
                    Config:save(game.GameId, Library._config)
                end,
                _state = self._state
            }

            return ModuleManager
        end

        function TabManager:create_button(settings: any)

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.18
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 218, 0, 38)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(12, 12, 13)
            Module.Parent = settings.section

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 6)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(48, 48, 52)
            UIStroke.Transparency = 0.3
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            
            local Button = Instance.new('TextButton')
            Button.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            Button.Text = settings.title or "Button"
            Button.Name = 'Button'
            Button.Size = UDim2.new(0.855, 0, 0, 28)
            Button.AnchorPoint = Vector2.new(0.5, 0.5)
            Button.Position = UDim2.new(0.5, 0, 0.5, 0)
            Button.BackgroundTransparency = 0.2
            Button.BorderSizePixel = 0
            Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Button.TextSize = 13
            Button.BackgroundColor3 = Color3.fromRGB(23, 23, 25)
            Button.Parent = Module
            
            local UICorner2 = Instance.new('UICorner')
            UICorner2.CornerRadius = UDim.new(0, 4)
            UICorner2.Parent = Button

            Button.MouseButton1Click:Connect(function()
                if settings.callback then
                    settings.callback()
                end
            end)

            -- Return a table with method to update button text dynamically
            local ModuleManager = {
                _button = Button,
                set_text = function(self, text)
                    Button.Text = tostring(text or "Button")
                end,
                _state = self._state
            }

            return ModuleManager
        end

        function TabManager:create_text(settings: any)

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.18
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 218, 0, 30)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(12, 12, 13)
            Module.Parent = settings.section

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 6)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(48, 48, 52)
            UIStroke.Transparency = 0.3
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            
            local Text = Instance.new('TextLabel')
            Text.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Text.TextColor3 = UIAccentColor
            Text.TextTransparency = 0.5
            Text.Text = settings.text or "Text"
            Text.Name = 'Text'
            Text.Size = UDim2.new(1, -12, 0, 20)
            Text.AnchorPoint = Vector2.new(0.5, 0.5)
            Text.Position = UDim2.new(0.5, 0, 0.5, 0)
            Text.BackgroundTransparency = 1
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.BorderSizePixel = 0
            Text.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Text.TextSize = 12
            Text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Text.Parent = Module

            return {}
        end

        function TabManager:create_paragraph(settings: any)

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.18
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 218, 0, 50)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(12, 12, 13)
            Module.Parent = settings.section

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 6)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(48, 48, 52)
            UIStroke.Transparency = 0.3
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            
            local Text = Instance.new('TextLabel')
            Text.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Text.TextColor3 = UIAccentColor
            Text.TextTransparency = 0.5
            Text.Text = settings.title or "Paragraph"
            Text.Name = 'Text'
            Text.Size = UDim2.new(1, -12, 0, 40)
            Text.AnchorPoint = Vector2.new(0.5, 0.5)
            Text.Position = UDim2.new(0.5, 0, 0.5, 0)
            Text.BackgroundTransparency = 1
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.TextYAlignment = Enum.TextYAlignment.Top
            Text.TextWrapped = true
            Text.BorderSizePixel = 0
            Text.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Text.TextSize = 11
            Text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Text.Parent = Module

            -- Custom scale if provided
            if settings.customScale then
                local scale = settings.customScale or 40
                Module.Size = UDim2.new(0, 218, 0, scale)
            end

            return {}
        end

        return TabManager
    end

    return self
end

return Library
