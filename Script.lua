
--==================================================
-- VOIDSCOPE CHANGER 2.3
-- RED + BLUE + WHITE + AQUAMARINE
-- SCROLLABLE COLOR SELECTOR
-- RELOADANIMATION INTEGRATED
-- SPEED SETTINGS + MOBILE TOGGLE
-- KEYBIND ENABLE/DISABLE
-- OLD SHIFTLOCK INTEGRATED
-- UNIFORM BEAM COLOR SYSTEM
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- CONFIGURATION
--==================================================

local ORIGINAL_ID = "rbxassetid://125806303939871"

local COLORS = {
    RED = {
        Texture = "rbxassetid://79908965595599",
        Color = Color3.fromRGB(255, 0, 0)
    },

    BLUE = {
        Texture = "rbxassetid://116708828152021",
        Color = Color3.fromRGB(0, 45, 160)
    },

    WHITE = {
        Texture = "rbxassetid://126161683645981",
        Color = Color3.fromRGB(255, 255, 255),
        DisableBeamScript = true
    },

    AQUAMARINE = {
        Texture = "rbxassetid://118286314935916",
        Color = Color3.fromRGB(127, 255, 212)
    }
}

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)

local SOUND_ID = "rbxassetid://6968135315"
local TARGET_TOOL_NAME = "Gun"
local COOLDOWN_DURATION = 2

local ReloadAnimationEnabled = false

-- Speed settings
local SpeedToggleKey = "R"
local AirSpeed = 250
local SpeedEnabled = false
local KeybindEnabled = true

-- Old Shiftlock settings
local OldShiftlockEnabled = false
local ShiftOffset = Vector3.new(1.2, 0.8, 0)
local NormalOffset = Vector3.new(0, 0, 0)
local ShiftHumanoid = nil
local ShiftConnection = nil

local actionSound = Instance.new("Sound")
actionSound.Name = "ReloadAnimationSound"
actionSound.SoundId = SOUND_ID
actionSound.Volume = 1
actionSound.Parent = SoundService

--==================================================
-- REGISTRIES
--==================================================

local VerifiedObjects = {}
local OriginalStates = {}
local ConnectedTools = {}
local MonitoringTools = {}

local SelectedDesign = nil
local AppliedDesign = nil

local DesignEnabled = false
local MenuVisible = true
local Minimized = false

--==================================================
-- IDENTIFY VOIDSCOPE
--==================================================

local function IsVerifiedMesh(object)

    if not object or not object:IsA("MeshPart") then
        return false
    end

    if VerifiedObjects[object] then
        return true
    end

    if object.TextureID ~= ORIGINAL_ID then
        return false
    end

    VerifiedObjects[object] = true
    return true
end

local function VerifyGun(tool)

    if not tool or not tool:IsA("Tool") then
        return false
    end

    if tool.Name ~= TARGET_TOOL_NAME then
        return false
    end

    local handle = tool:FindFirstChild("Handle")

    if not handle or not IsVerifiedMesh(handle) then
        return false
    end

    return true
end

local function VerifyDisplay(display)

    local folder = workspace:FindFirstChild("WeaponDisplays")

    if not folder then
        return false
    end

    if not display or display.Name ~= "GunDisplay" then
        return false
    end

    if not display:IsA("MeshPart") then
        return false
    end

    if not display:IsDescendantOf(folder) then
        return false
    end

    return IsVerifiedMesh(display)
end

--==================================================
-- LOCATE CUSTOM BEAM
--==================================================

local function GetCustomBeam(object)

    if not object then
        return nil
    end

    local parent = object

    if object:IsA("Tool") then
        parent = object:FindFirstChild("Handle")
    end

    if not parent then
        return nil
    end

    return parent:FindFirstChild("CustomBeam", true)
end

--==================================================
-- LOCATE ALL BEAMS
--==================================================

local function GetBeams(object)

    local customBeam = GetCustomBeam(object)
    local results = {}

    if not customBeam then
        return results
    end

    if customBeam:IsA("Beam") then
        table.insert(results, customBeam)
    end

    for _, descendant in ipairs(customBeam:GetDescendants()) do

        if descendant:IsA("Beam") then
            table.insert(results, descendant)
        end

    end

    return results
end

--==================================================
-- LOCATE ALL BEAM SCRIPTS
--==================================================

local function GetBeamScripts(object)

    local customBeam = GetCustomBeam(object)
    local results = {}

    if not customBeam then
        return results
    end

    for _, descendant in ipairs(customBeam:GetDescendants()) do

        if descendant:IsA("Script")
            or descendant:IsA("LocalScript") then

            table.insert(results, descendant)

        end

    end

    return results
end

--==================================================
-- SAVE ORIGINAL STATE
--==================================================

local function CaptureBeamState(object, state)

    local beams = GetBeams(object)

    for _, beam in ipairs(beams) do

        if not state.Beams[beam] then

            state.Beams[beam] = {
                Color = beam.Color
            }

        end

    end

    local scripts = GetBeamScripts(object)

    for _, scriptObject in ipairs(scripts) do

        if state.Scripts[scriptObject] == nil then
            state.Scripts[scriptObject] = scriptObject.Disabled
        end

    end

end

local function SaveOriginal(object)

    if OriginalStates[object] then
        return
    end

    local state = {
        TextureID = object.TextureID,
        Beams = {},
        Scripts = {}
    }

    OriginalStates[object] = state

    CaptureBeamState(object, state)

end

--==================================================
-- DISABLE BEAM SCRIPTS
-- WHITE ONLY
--==================================================

local function DisableBeamScripts(object, state)

    local scripts = GetBeamScripts(object)

    for _, scriptObject in ipairs(scripts) do

        if state.Scripts[scriptObject] == nil then
            state.Scripts[scriptObject] = scriptObject.Disabled
        end

        scriptObject.Disabled = true

    end

end

--==================================================
-- APPLY UNIFORM BEAM COLOR
--==================================================

local function ApplyUniformBeamColor(beam, color)

    if not beam or not beam.Parent then
        return
    end

    -- Constant color across the entire Beam.
    -- No color gradient is introduced here.
    beam.Color = ColorSequence.new(color, color)

end

--==================================================
-- APPLY TEXTURE AND BEAM COLOR
--==================================================

local function ApplyObject(object)

    if not IsVerifiedMesh(object) then
        return false
    end

    SaveOriginal(object)

    local state = OriginalStates[object]

    object.TextureID = AppliedDesign.Texture

    CaptureBeamState(object, state)

    -- Only WHITE disables scripts inside CustomBeam.
    if AppliedDesign.DisableBeamScript then
        DisableBeamScripts(object, state)
    end

    local beams = GetBeams(object)

    for _, beam in ipairs(beams) do

        if beam.Parent then

            if not AppliedDesign.DisableBeamScript then

                ApplyUniformBeamColor(
                    beam,
                    AppliedDesign.Color
                )

            end

        end

    end

    return true
end

local function ApplyGun(tool)

    if not VerifyGun(tool) then
        return false
    end

    local handle = tool:FindFirstChild("Handle")

    return ApplyObject(handle)
end

--==================================================
-- VERIFY GUN DISPLAY
--==================================================

local function GetVerifiedDisplays()

    local results = {}

    local folder = workspace:FindFirstChild("WeaponDisplays")

    if not folder then
        return results
    end

    for _, object in ipairs(folder:GetDescendants()) do

        if VerifyDisplay(object) then
            table.insert(results, object)
        end

    end

    return results
end

local function ApplyDisplays()

    local displays = GetVerifiedDisplays()
    local count = 0

    for _, display in ipairs(displays) do

        if ApplyObject(display) then
            count += 1
        end

    end

    return count
end

--==================================================
-- CONTINUOUS BEAM MONITORING
--==================================================

local function MonitorVoidscope(tool)

    if not VerifyGun(tool) then
        return
    end

    if MonitoringTools[tool] then
        return
    end

    MonitoringTools[tool] = true

    task.spawn(function()

        while tool.Parent do

            if DesignEnabled and AppliedDesign then

                local handle = tool:FindFirstChild("Handle")

                if handle then

                    local state = OriginalStates[handle]

                    if not state then
                        SaveOriginal(handle)
                        state = OriginalStates[handle]
                    end

                    if state then

                        CaptureBeamState(handle, state)

                        -- Only WHITE disables scripts added later.
                        if AppliedDesign.DisableBeamScript then
                            DisableBeamScripts(handle, state)
                        end

                        local beams = GetBeams(handle)

                        for _, beam in ipairs(beams) do

                            if beam.Parent then

                                if not AppliedDesign.DisableBeamScript then

                                    ApplyUniformBeamColor(
                                        beam,
                                        AppliedDesign.Color
                                    )

                                end

                            end

                        end

                    end

                end

            end

            task.wait(0.02)

        end

        MonitoringTools[tool] = nil

    end)

end

--==================================================
-- APPLY COMPLETE DESIGN
--==================================================

local function ApplyDesign()

    if not SelectedDesign then
        return false, 0, "SELECT_COLOR"
    end

    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")

    local foundGun = false

    if character then

        for _, object in ipairs(character:GetChildren()) do

            if VerifyGun(object) then
                foundGun = true
                break
            end

        end

    end

    if not foundGun and backpack then

        for _, object in ipairs(backpack:GetChildren()) do

            if VerifyGun(object) then
                foundGun = true
                break
            end

        end

    end

    local displays = GetVerifiedDisplays()

    if not foundGun and #displays == 0 then
        return false, 0, "NOT_FOUND"
    end

    AppliedDesign = SelectedDesign
    DesignEnabled = true

    if character then

        for _, object in ipairs(character:GetChildren()) do

            if VerifyGun(object) then
                ApplyGun(object)
                MonitorVoidscope(object)
            end

        end

    end

    if backpack then

        for _, object in ipairs(backpack:GetChildren()) do

            if VerifyGun(object) then
                ApplyGun(object)
                MonitorVoidscope(object)
            end

        end

    end

    local count = ApplyDisplays()

    return true, count, "SUCCESS"
end

--==================================================
-- RESTORE ORIGINAL
--==================================================

local function RestoreOriginal()

    DesignEnabled = false
    AppliedDesign = nil

    for object, state in pairs(OriginalStates) do

        if object and object.Parent then
            object.TextureID = state.TextureID
        end

        for beam, beamState in pairs(state.Beams) do

            if beam and beam.Parent then
                beam.Color = beamState.Color
            end

        end

        for scriptObject, wasDisabled in pairs(state.Scripts) do

            if scriptObject and scriptObject.Parent then
                scriptObject.Disabled = wasDisabled
            end

        end

    end

    table.clear(OriginalStates)
    table.clear(VerifiedObjects)

end

--==================================================
-- RELOADANIMATION SYSTEM
--==================================================

local function SetupReloadAnimation(character)

    local humanoid = character:WaitForChild("Humanoid", 10)
    local animator = humanoid and humanoid:WaitForChild("Animator", 10)

    local lastUnequippedTime = -math.huge

    if animator then

        animator.AnimationPlayed:Connect(function(track)

            if not ReloadAnimationEnabled then
                return
            end

            local tool = character:FindFirstChildOfClass("Tool")
            local isHoldingGun = tool and tool.Name == TARGET_TOOL_NAME

            local timeSinceUnequip = os.clock() - lastUnequippedTime
            local withinCooldown = timeSinceUnequip <= COOLDOWN_DURATION

            if isHoldingGun or withinCooldown then

                if track.Priority == Enum.AnimationPriority.Action then
                    track:Stop()
                end

            end

        end)

    end

    character.ChildAdded:Connect(function(child)

        if child:IsA("Tool") and child.Name == TARGET_TOOL_NAME then
            actionSound:Play()
        end

    end)

    character.ChildRemoved:Connect(function(child)

        if child:IsA("Tool") and child.Name == TARGET_TOOL_NAME then

            actionSound:Play()
            lastUnequippedTime = os.clock()

        end

    end)

end

--==================================================
-- DETECT VOIDSCOPE
--==================================================

local function DetectVoidscope()

    local foundGun = false
    local displayCount = 0

    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")

    if character then

        for _, object in ipairs(character:GetChildren()) do

            if VerifyGun(object) then

                foundGun = true
                MonitorVoidscope(object)

            end

        end

    end

    if backpack then

        for _, object in ipairs(backpack:GetChildren()) do

            if VerifyGun(object) then

                foundGun = true
                MonitorVoidscope(object)

            end

        end

    end

    local displays = GetVerifiedDisplays()
    displayCount = #displays

    return foundGun, displayCount
end

--==================================================
-- CONNECT TOOL
--==================================================

local function ConnectTool(tool)

    if not VerifyGun(tool) then
        return
    end

    if ConnectedTools[tool] then
        return
    end

    ConnectedTools[tool] = true

    if DesignEnabled then
        ApplyGun(tool)
        MonitorVoidscope(tool)
    end

end

--==================================================
-- SPEED SETTINGS
--==================================================

local SpeedHumanoid = nil
local SpeedRootPart = nil
local NormalSpeed = 16
local SpaceHeld = false
local StateConnection = nil

local SpeedToggleButton = nil
local KeybindButton = nil
local OldShiftlockButton = nil

local function UpdateSpeedButton()

    if not SpeedToggleButton then
        return
    end

    if SpeedEnabled then
        SpeedToggleButton.Text = "SPEED GLITCH: ON"
        SpeedToggleButton.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        SpeedToggleButton.Text = "SPEED GLITCH: OFF"
        SpeedToggleButton.TextColor3 = Color3.fromRGB(255, 0, 0)
    end

end

local function UpdateKeybindButton()

    if not KeybindButton then
        return
    end

    if KeybindEnabled then
        KeybindButton.Text = "KEYBIND: ON"
        KeybindButton.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        KeybindButton.Text = "KEYBIND: OFF"
        KeybindButton.TextColor3 = Color3.fromRGB(255, 0, 0)
    end

end

local function CleanupSpeed()

    if StateConnection then
        StateConnection:Disconnect()
        StateConnection = nil
    end

    if SpeedHumanoid and SpeedHumanoid.Parent then
        SpeedHumanoid.WalkSpeed = NormalSpeed
    end

    SpeedHumanoid = nil
    SpeedRootPart = nil

end

local function SetupSpeed(character)

    CleanupSpeed()

    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")

    if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
        return
    end

    SpeedHumanoid = humanoid
    SpeedRootPart = rootPart
    NormalSpeed = humanoid.WalkSpeed

    StateConnection = humanoid.StateChanged:Connect(function(_, state)

        if not SpeedEnabled then
            return
        end

        if state == Enum.HumanoidStateType.Jumping
            or state == Enum.HumanoidStateType.Freefall then

            humanoid.WalkSpeed = AirSpeed

        elseif state == Enum.HumanoidStateType.Landed
            or state == Enum.HumanoidStateType.Running then

            humanoid.WalkSpeed = NormalSpeed

        end

    end)

end

local function ToggleSpeed()

    SpeedEnabled = not SpeedEnabled

    if SpeedEnabled then

        if Player.Character then
            SetupSpeed(Player.Character)
        end

        print("Speed system enabled")

    else

        CleanupSpeed()
        print("Speed system disabled")

    end

    UpdateSpeedButton()

end

local function ToggleKeybind()

    KeybindEnabled = not KeybindEnabled

    if not KeybindEnabled and SpeedEnabled then
        ToggleSpeed()
    end

    UpdateKeybindButton()

end

--==================================================
-- OLD SHIFTLOCK SYSTEM
--==================================================

local function UpdateOldShiftlockButton()

    if not OldShiftlockButton then
        return
    end

    if OldShiftlockEnabled then
        OldShiftlockButton.Text = "OLD SHIFTLOCK: ON"
        OldShiftlockButton.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        OldShiftlockButton.Text = "OLD SHIFTLOCK: OFF"
        OldShiftlockButton.TextColor3 = Color3.fromRGB(255, 0, 0)
    end

end

local function SetupShiftHumanoid(character)

    ShiftHumanoid = character:WaitForChild("Humanoid")

    ShiftHumanoid.CameraOffset = NormalOffset

end

local function ToggleOldShiftlock()

    OldShiftlockEnabled = not OldShiftlockEnabled

    if OldShiftlockEnabled then

        if Player.Character then
            SetupShiftHumanoid(Player.Character)
        end

        if not ShiftConnection then

            ShiftConnection = RunService.RenderStepped:Connect(function()

                if not OldShiftlockEnabled or not ShiftHumanoid then
                    return
                end

                if not ShiftHumanoid.Parent then
                    return
                end

                if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
                    ShiftHumanoid.CameraOffset = ShiftOffset
                else
                    ShiftHumanoid.CameraOffset = NormalOffset
                end

            end)

        end

    else

        if ShiftConnection then
            ShiftConnection:Disconnect()
            ShiftConnection = nil
        end

        if ShiftHumanoid and ShiftHumanoid.Parent then
            ShiftHumanoid.CameraOffset = NormalOffset
        end

    end

    UpdateOldShiftlockButton()

end

--==================================================
-- GUI
--==================================================

local GUI = Instance.new("ScreenGui")
GUI.Name = "VoidscopeChanger"
GUI.ResetOnSpawn = false
GUI.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(310, 665)
Main.Position = UDim2.new(0.5, -155, 0.5, -332)
Main.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = false
Main.Parent = GUI

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 0, 42)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Text = "VOID SCOPE / CHANGER 2.3"
Title.TextColor3 = WHITE
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

--==================================================
-- CREATE BUTTONS
--==================================================

local function CreateButton(name, text, y, callback)

    local button = Instance.new("TextButton")

    button.Name = name
    button.Size = UDim2.new(1, -36, 0, 42)
    button.Position = UDim2.fromOffset(18, y)
    button.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = WHITE
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.Parent = Main

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    button.Activated:Connect(callback)

    return button
end

local DetectButton
local ApplyButton
local RestoreButton
local ReloadAnimationButton

--==================================================
-- DETECT BUTTON
--==================================================

DetectButton = CreateButton(
    "DetectButton",
    "DETECT VOIDSCOPE",
    50,
    function()

        local found, displays = DetectVoidscope()

        if found or displays > 0 then
            DetectButton.Text = "VOIDSCOPE DETECTED"
        else
            DetectButton.Text = "VOIDSCOPE NOT FOUND"
        end

        task.delay(2, function()

            if DetectButton.Parent then
                DetectButton.Text = "DETECT VOIDSCOPE"
            end

        end)

    end
)

--==================================================
-- APPLY TEXTURE BUTTON
--==================================================

ApplyButton = CreateButton(
    "ApplyButton",
    "APPLY TEXTURE",
    100,
    function()

        local success, count, reason = ApplyDesign()

        if success then

            ApplyButton.Text = "DESIGN APPLIED"

        elseif reason == "SELECT_COLOR" then

            ApplyButton.Text = "SELECT A COLOR"

        else

            ApplyButton.Text = "VOIDSCOPE NOT FOUND"

        end

        task.delay(2, function()

            if ApplyButton.Parent then
                ApplyButton.Text = "APPLY TEXTURE"
            end

        end)

    end
)

--==================================================
-- RESTORE ORIGINAL BUTTON
--==================================================

RestoreButton = CreateButton(
    "RestoreButton",
    "RESTORE ORIGINAL",
    150,
    function()

        RestoreOriginal()

        RestoreButton.Text = "ORIGINAL RESTORED"

        task.delay(2, function()

            if RestoreButton.Parent then
                RestoreButton.Text = "RESTORE ORIGINAL"
            end

        end)

    end
)

--==================================================
-- COLOR DROPDOWN
--==================================================

local DropdownButton = Instance.new("TextButton")
DropdownButton.Name = "ColorSelector"
DropdownButton.Size = UDim2.new(1, -36, 0, 42)
DropdownButton.Position = UDim2.fromOffset(18, 205)
DropdownButton.BackgroundTransparency = 1
DropdownButton.Text = ""
DropdownButton.ZIndex = 3
DropdownButton.Parent = Main

local SelectedHalf = Instance.new("Frame")
SelectedHalf.Name = "SelectedHalf"
SelectedHalf.Size = UDim2.new(0.5, 0, 1, 0)
SelectedHalf.BackgroundColor3 = BLACK
SelectedHalf.BorderSizePixel = 0
SelectedHalf.ZIndex = 2
SelectedHalf.Parent = DropdownButton

local BlackHalf = Instance.new("Frame")
BlackHalf.Name = "BlackHalf"
BlackHalf.Size = UDim2.new(0.5, 0, 1, 0)
BlackHalf.Position = UDim2.new(0.5, 0, 0, 0)
BlackHalf.BackgroundColor3 = BLACK
BlackHalf.BorderSizePixel = 0
BlackHalf.ZIndex = 2
BlackHalf.Parent = DropdownButton

local SelectorCorner = Instance.new("UICorner")
SelectorCorner.CornerRadius = UDim.new(0, 7)
SelectorCorner.Parent = DropdownButton

local HalfCorner = Instance.new("UICorner")
HalfCorner.CornerRadius = UDim.new(0, 7)
HalfCorner.Parent = SelectedHalf

local BlackCorner = Instance.new("UICorner")
BlackCorner.CornerRadius = UDim.new(0, 7)
BlackCorner.Parent = BlackHalf

local SelectorText = Instance.new("TextLabel")
SelectorText.Size = UDim2.new(1, 0, 1, 0)
SelectorText.BackgroundTransparency = 1
SelectorText.Text = "SELECT COLOR  ▼"
SelectorText.TextColor3 = WHITE
SelectorText.Font = Enum.Font.GothamBold
SelectorText.TextSize = 13
SelectorText.ZIndex = 4
SelectorText.Parent = DropdownButton

--==================================================
-- SCROLLABLE COLOR MENU
--==================================================

local DropdownMenu = Instance.new("ScrollingFrame")
DropdownMenu.Name = "ColorOptions"
DropdownMenu.Size = UDim2.new(1, -36, 0, 112)
DropdownMenu.Position = UDim2.fromOffset(18, 250)
DropdownMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DropdownMenu.BorderSizePixel = 0
DropdownMenu.Visible = false
DropdownMenu.ZIndex = 10
DropdownMenu.CanvasSize = UDim2.new(0, 0, 0, 0)
DropdownMenu.ScrollingDirection = Enum.ScrollingDirection.Y
DropdownMenu.ScrollBarThickness = 5
DropdownMenu.ScrollBarImageColor3 = WHITE
DropdownMenu.ScrollBarImageTransparency = 0.2
DropdownMenu.AutomaticCanvasSize = Enum.AutomaticSize.None
DropdownMenu.Parent = Main

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 7)
MenuCorner.Parent = DropdownMenu

local MenuPadding = Instance.new("UIPadding")
MenuPadding.PaddingTop = UDim.new(0, 4)
MenuPadding.PaddingBottom = UDim.new(0, 4)
MenuPadding.PaddingLeft = UDim.new(0, 4)
MenuPadding.PaddingRight = UDim.new(0, 4)
MenuPadding.Parent = DropdownMenu

local MenuLayout = Instance.new("UIListLayout")
MenuLayout.FillDirection = Enum.FillDirection.Vertical
MenuLayout.SortOrder = Enum.SortOrder.LayoutOrder
MenuLayout.Padding = UDim.new(0, 4)
MenuLayout.Parent = DropdownMenu

local function UpdateCanvasSize()

    DropdownMenu.CanvasSize = UDim2.new(
        0,
        0,
        0,
        MenuLayout.AbsoluteContentSize.Y + 8
    )

end

MenuLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
    UpdateCanvasSize
)

local function UpdateSelector()

    if not SelectedDesign then

        SelectedHalf.BackgroundColor3 = BLACK
        SelectorText.Text = "SELECT COLOR  ▼"

        return
    end

    SelectedHalf.BackgroundColor3 = SelectedDesign.Color
    SelectorText.Text = "COLOR: " .. SelectedDesign.Name .. "  ▼"

end

local function SelectColor(colorName)

    local colorData = COLORS[colorName]

    if not colorData then
        return
    end

    SelectedDesign = {
        Name = colorName,
        Texture = colorData.Texture,
        Color = colorData.Color,
        DisableBeamScript = colorData.DisableBeamScript or false
    }

    UpdateSelector()
    DropdownMenu.Visible = false

end

local function CreateColorOption(colorName, order)

    local data = COLORS[colorName]

    local option = Instance.new("TextButton")
    option.Name = colorName .. "Option"
    option.Size = UDim2.new(1, -8, 0, 32)
    option.LayoutOrder = order
    option.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
    option.BorderSizePixel = 0
    option.Text = ""
    option.ZIndex = 11
    option.Parent = DropdownMenu

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = option

    local colorSquare = Instance.new("Frame")
    colorSquare.Size = UDim2.fromOffset(18, 18)
    colorSquare.Position = UDim2.fromOffset(9, 7)
    colorSquare.BackgroundColor3 = data.Color
    colorSquare.BorderSizePixel = 0
    colorSquare.ZIndex = 12
    colorSquare.Parent = option

    local squareCorner = Instance.new("UICorner")
    squareCorner.CornerRadius = UDim.new(0, 4)
    squareCorner.Parent = colorSquare

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -42, 1, 0)
    label.Position = UDim2.fromOffset(36, 0)
    label.BackgroundTransparency = 1
    label.Text = colorName
    label.TextColor3 = WHITE
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 12
    label.Parent = option

    option.Activated:Connect(function()
        SelectColor(colorName)
    end)

end

CreateColorOption("RED", 1)
CreateColorOption("BLUE", 2)
CreateColorOption("WHITE", 3)
CreateColorOption("AQUAMARINE", 4)

UpdateCanvasSize()

DropdownButton.Activated:Connect(function()

    DropdownMenu.Visible = not DropdownMenu.Visible

    if DropdownMenu.Visible then

        SelectorText.Text = SelectedDesign
            and ("COLOR: " .. SelectedDesign.Name .. "  ▲")
            or "SELECT COLOR  ▲"

    else

        UpdateSelector()

    end

end)

--==================================================
-- RELOADANIMATION BUTTON
--==================================================

ReloadAnimationButton = CreateButton(
    "ReloadAnimationButton",
    "RELOADANIMATION: OFF",
    370,
    function()

        ReloadAnimationEnabled = not ReloadAnimationEnabled

        if ReloadAnimationEnabled then

            ReloadAnimationButton.Text = "RELOADANIMATION: ON"
            ReloadAnimationButton.TextColor3 = Color3.fromRGB(0, 255, 0)

        else

            ReloadAnimationButton.Text = "RELOADANIMATION: OFF"
            ReloadAnimationButton.TextColor3 = Color3.fromRGB(255, 0, 0)

        end

    end
)

ReloadAnimationButton.TextSize = 11
ReloadAnimationButton.TextColor3 = Color3.fromRGB(255, 0, 0)

--==================================================
-- SPEED SETTINGS UI
--==================================================

local SpeedTitle = Instance.new("TextLabel")
SpeedTitle.Name = "SpeedSettingsTitle"
SpeedTitle.Size = UDim2.new(1, -36, 0, 25)
SpeedTitle.Position = UDim2.fromOffset(18, 420)
SpeedTitle.BackgroundTransparency = 1
SpeedTitle.Text = "SPEED SETTINGS"
SpeedTitle.TextColor3 = WHITE
SpeedTitle.Font = Enum.Font.GothamBold
SpeedTitle.TextSize = 12
SpeedTitle.TextXAlignment = Enum.TextXAlignment.Left
SpeedTitle.Parent = Main

local function CreateSettingRow(name, labelText, defaultText, y)

    local label = Instance.new("TextLabel")
    label.Name = name .. "Label"
    label.Size = UDim2.fromOffset(125, 32)
    label.Position = UDim2.fromOffset(18, y)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = WHITE
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = Main

    local box = Instance.new("TextBox")
    box.Name = name .. "Input"
    box.Size = UDim2.fromOffset(130, 32)
    box.Position = UDim2.fromOffset(160, y)
    box.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
    box.BorderSizePixel = 0
    box.Text = defaultText
    box.PlaceholderText = defaultText
    box.TextColor3 = WHITE
    box.PlaceholderColor3 = Color3.fromRGB(160, 160, 160)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.Parent = Main

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = box

    return box
end

local KeyInput = CreateSettingRow(
    "SpeedKey",
    "TOGGLE KEY",
    "R",
    445
)

local AirSpeedInput = CreateSettingRow(
    "AirSpeed",
    "AIR SPEED",
    "250",
    485
)

KeyInput.FocusLost:Connect(function(enterPressed)

    if not enterPressed then
        KeyInput.Text = SpeedToggleKey
        return
    end

    local newKey = string.upper(
        string.gsub(KeyInput.Text, "%s+", "")
    )

    if #newKey == 1
        and string.match(newKey, "^[A-Z]$")
        and Enum.KeyCode[newKey] then

        SpeedToggleKey = newKey
        KeyInput.Text = newKey

        print("Speed toggle key changed to " .. newKey)

    else

        KeyInput.Text = SpeedToggleKey

    end

end)

AirSpeedInput.FocusLost:Connect(function(enterPressed)

    if not enterPressed then
        AirSpeedInput.Text = tostring(AirSpeed)
        return
    end

    local newSpeed = tonumber(AirSpeedInput.Text)

    if newSpeed and newSpeed > 0 and newSpeed <= 1000 then

        AirSpeed = newSpeed
        AirSpeedInput.Text = tostring(AirSpeed)

        print("AirSpeed changed to " .. tostring(AirSpeed))

    else

        AirSpeedInput.Text = tostring(AirSpeed)

    end

end)

--==================================================
-- KEYBIND ON/OFF BUTTON
--==================================================

KeybindButton = CreateButton(
    "KeybindButton",
    "KEYBIND: ON",
    523,
    function()
        ToggleKeybind()
    end
)

KeybindButton.TextColor3 = Color3.fromRGB(0, 255, 0)

--==================================================
-- SPEED GLITCH ON/OFF BUTTON
--==================================================

SpeedToggleButton = CreateButton(
    "SpeedToggleButton",
    "SPEED GLITCH: OFF",
    570,
    function()
        ToggleSpeed()
    end
)

SpeedToggleButton.TextSize = 12
SpeedToggleButton.TextColor3 = Color3.fromRGB(255, 0, 0)

--==================================================
-- OLD SHIFTLOCK ON/OFF BUTTON
--==================================================

OldShiftlockButton = CreateButton(
    "OldShiftlockButton",
    "OLD SHIFTLOCK: OFF",
    617,
    function()
        ToggleOldShiftlock()
    end
)

OldShiftlockButton.TextSize = 12
OldShiftlockButton.TextColor3 = Color3.fromRGB(255, 0, 0)

--==================================================
-- MINIMIZE AND CLOSE
--==================================================

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(30, 30)
Minimize.Position = UDim2.new(1, -72, 0, 6)
Minimize.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Minimize.Text = "-"
Minimize.TextColor3 = WHITE
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 20
Minimize.Parent = Main

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(30, 30)
Close.Position = UDim2.new(1, -38, 0, 6)
Close.BackgroundColor3 = Color3.fromRGB(130, 25, 25)
Close.Text = "X"
Close.TextColor3 = WHITE
Close.Font = Enum.Font.GothamBold
Close.TextSize = 14
Close.Parent = Main

local SavedVisibility = {}

Minimize.Activated:Connect(function()

    Minimized = not Minimized

    if Minimized then

        table.clear(SavedVisibility)

        for _, object in ipairs(Main:GetChildren()) do

            if object ~= Title
                and object ~= Minimize
                and object ~= Close
                and object ~= MainCorner then

                SavedVisibility[object] = object.Visible
                object.Visible = false

            end

        end

    else

        for object, wasVisible in pairs(SavedVisibility) do

            if object and object.Parent then
                object.Visible = wasVisible
            end

        end

        table.clear(SavedVisibility)

    end

    Main.Size = Minimized
        and UDim2.fromOffset(310, 42)
        or UDim2.fromOffset(310, 665)

end)

Close.Activated:Connect(function()

    RestoreOriginal()
    CleanupSpeed()

    OldShiftlockEnabled = false

    if ShiftConnection then
        ShiftConnection:Disconnect()
        ShiftConnection = nil
    end

    if ShiftHumanoid and ShiftHumanoid.Parent then
        ShiftHumanoid.CameraOffset = NormalOffset
    end

    GUI:Destroy()

end)

--==================================================
-- INPUT HANDLING
--==================================================

UserInputService.InputBegan:Connect(function(input, processed)

    if processed or UserInputService:GetFocusedTextBox() then
        return
    end

    if input.KeyCode == Enum.KeyCode.G then

        MenuVisible = not MenuVisible
        Main.Visible = MenuVisible

        return
    end

    local configuredKey = Enum.KeyCode[SpeedToggleKey]

    if KeybindEnabled
        and configuredKey
        and input.KeyCode == configuredKey then

        ToggleSpeed()
        return
    end

    if input.KeyCode == Enum.KeyCode.Space then

        if SpaceHeld then
            return
        end

        SpaceHeld = true

        if not SpeedEnabled
            or not SpeedHumanoid
            or not SpeedRootPart then

            return
        end

        if SpeedHumanoid.FloorMaterial == Enum.Material.Air then

            local jumpVelocity

            if SpeedHumanoid.UseJumpPower then

                jumpVelocity = SpeedHumanoid.JumpPower

            else

                jumpVelocity = math.sqrt(
                    2 * workspace.Gravity * SpeedHumanoid.JumpHeight
                )

            end

            local velocity = SpeedRootPart.AssemblyLinearVelocity

            SpeedRootPart.AssemblyLinearVelocity = Vector3.new(
                velocity.X,
                jumpVelocity,
                velocity.Z
            )

        end

    end

end)

UserInputService.InputEnded:Connect(function(input)

    if input.KeyCode == Enum.KeyCode.Space then
        SpaceHeld = false
    end

end)

--==================================================
-- CHARACTER SETUP
--==================================================

local function SetupCharacter(character)

    SetupReloadAnimation(character)

    if SpeedEnabled then
        SetupSpeed(character)
    end

    if OldShiftlockEnabled then
        SetupShiftHumanoid(character)
    end

    character.ChildAdded:Connect(function(object)

        if object:IsA("Tool") then

            task.wait(0.1)
            ConnectTool(object)

        end

    end)

    for _, object in ipairs(character:GetChildren()) do

        if object:IsA("Tool") then
            ConnectTool(object)
        end

    end

end

local Backpack = Player:WaitForChild("Backpack")

Backpack.ChildAdded:Connect(function(object)

    if object:IsA("Tool") then

        task.wait(0.1)
        ConnectTool(object)

    end

end)

Player.CharacterAdded:Connect(function(character)

    SpaceHeld = false
    SetupCharacter(character)

end)

if Player.Character then
    SetupCharacter(Player.Character)
end

print("[Voidscope Changer 2.3] Loaded successfully.")
