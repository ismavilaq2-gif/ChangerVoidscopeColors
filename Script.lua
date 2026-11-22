--==================================================
-- VOIDSCOPE CHANGER 2.6
-- RED + BLUE + WHITE + AQUAMARINE + NEW COLORS
-- WHITE PLASTIC GUN INTEGRATED
-- SCROLLABLE MAIN INTERFACE
-- RELOADANIMATION INTEGRATED
-- ORIGINAL SPEED SYSTEM
-- AIR BACKWARD SPEED GLITCH
-- OLD SHIFTLOCK INTEGRATED
-- UNIFORM BEAM COLOR SYSTEM
-- CUSTOMBEAM SCRIPTS DISABLED FOR ALL COLORS
-- SCOPE SELECTOR (VOIDSCOPE / MATRIXSCOPE)
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

local SCOPES = {
    VOIDSCOPE = {
        Name = "VOIDSCOPE",
        TextureId = "rbxassetid://125806303939871"
    },
    MATRIXSCOPE = {
        Name = "MATRIXSCOPE",
        TextureId = "rbxassetid://115264692533866"
    }
}

local SelectedScope = "VOIDSCOPE"
local ORIGINAL_ID = SCOPES[SelectedScope].TextureId

local COLORS = {
    RED = {
        Texture = "rbxassetid://79908965595599",
        Color = Color3.fromRGB(255, 0, 0),
        DisableBeamScript = true
    },

    BLUE = {
        Texture = "rbxassetid://116708828152021",
        Color = Color3.fromRGB(0, 45, 160),
        DisableBeamScript = true
    },

    WHITE = {
        Texture = "rbxassetid://126161683645981",
        Color = Color3.fromRGB(255, 255, 255),
        DisableBeamScript = true,
        PreserveBeamColor = true
    },

    AQUAMARINE = {
        Texture = "rbxassetid://118286314935916",
        Color = Color3.fromRGB(127, 255, 212),
        DisableBeamScript = true
    },

    DARK_BLUE = {
        Texture = "rbxassetid://135557446714129",
        Color = Color3.fromRGB(16, 43, 99),
        DisableBeamScript = true
    },

    LIGHT_PINK = {
        Texture = "rbxassetid://76296142295658",
        Color = Color3.fromRGB(247, 182, 210),
        DisableBeamScript = true
    },

    LIGHT_BLUE = {
        Texture = "rbxassetid://86452393442703",
        Color = Color3.fromRGB(135, 206, 250),
        DisableBeamScript = true
    },

    FOREST_GREEN = {
        Texture = "rbxassetid://122652485385373",
        Color = Color3.fromRGB(20, 83, 45),
        DisableBeamScript = true
    },

    PINK = {
        Texture = "rbxassetid://94064058591379",
        Color = Color3.fromRGB(255, 105, 180),
        DisableBeamScript = true
    },

    FUCHSIA = {
        Texture = "rbxassetid://79322010219289",
        Color = Color3.fromRGB(255, 0, 255),
        DisableBeamScript = true
    },

    VIVID_LIGHT_GREEN = {
        Texture = "rbxassetid://94440027009198",
        Color = Color3.fromRGB(124, 252, 0),
        DisableBeamScript = true
    },

    DARK_BURGUNDY = {
        Texture = "rbxassetid://119300256162924",
        Color = Color3.fromRGB(75, 16, 28),
        DisableBeamScript = true
    }
}

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)

local SOUND_ID = "rbxassetid://6968135315"
local TARGET_TOOL_NAME = "Gun"
local COOLDOWN_DURATION = 2

local ReloadAnimationEnabled = false

-- Original speed settings
local SpeedToggleKey = "R"
local AirSpeed = 250
local SpeedEnabled = false
local KeybindEnabled = true

-- Air backward settings
local BackwardGlitchEnabled = false
local BackwardGlitchSpeed = 100
local MIN_BACKWARD_SPEED = 1
local MAX_BACKWARD_SPEED = 1000
local CAMERA_THRESHOLD = 0.25

local BackwardHumanoid = nil
local BackwardRootPart = nil
local BackwardOriginalSpeed = 16
local BackwardConnection = nil
local BackwardUsedThisJump = false
local BackwardWasAirborne = false
local PreviousCameraDirection = nil
local BackwardChangedSpeed = false

-- Old Shiftlock settings
local OldShiftlockEnabled = false
local ShiftOffset = Vector3.new(1.2, 0.8, 0)
local NormalOffset = Vector3.new(0, 0, 0)
local ShiftHumanoid = nil
local ShiftConnection = nil

-- WHITE PLASTIC CONFIGURATION
local WHITE_PLASTIC_CONFIG = {
    Color = Color3.fromRGB(255, 255, 255),
    Transparency = 0.5,
    Material = Enum.Material.Plastic,
    UpdateInterval = 0.25
}

local WhitePlasticEnabled = false
local WhitePlasticLastUpdate = 0
local WhitePlasticTargets = {}
local WhitePlasticButton = nil

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
-- WHITE PLASTIC TARGET CHECK
--==================================================

local function IsWhitePlasticTarget(object)

    return WhitePlasticEnabled
        and WhitePlasticTargets[object] ~= nil

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
-- DISABLE ALL CUSTOMBEAM SCRIPTS
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

    beam.Color = ColorSequence.new(color, color)

end

--==================================================
-- APPLY TEXTURE AND BEAM COLOR
--==================================================

local function ApplyObject(object)

    if not IsVerifiedMesh(object) then
        return false
    end

    -- WHITE PLASTIC has priority
    if IsWhitePlasticTarget(object) then
        return true
    end

    SaveOriginal(object)

    local state = OriginalStates[object]

    object.TextureID = AppliedDesign.Texture

    CaptureBeamState(object, state)

    if AppliedDesign.DisableBeamScript then
        DisableBeamScripts(object, state)
    end

    if not AppliedDesign.PreserveBeamColor then

        local beams = GetBeams(object)

        for _, beam in ipairs(beams) do

            if beam.Parent then

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
-- WHITE PLASTIC: FIND NEAREST DISPLAY
--==================================================

local function FindNearestWhitePlasticDisplay(character)

    local root = character:FindFirstChild("HumanoidRootPart")

    if not root then
        return nil
    end

    local folder = workspace:FindFirstChild("WeaponDisplays")

    if not folder then
        return nil
    end

    local nearest = nil
    local shortestDistance = math.huge

    for _, object in ipairs(folder:GetDescendants()) do

        if object.Name == "GunDisplay"
            and object:IsA("MeshPart")
            and VerifyDisplay(object) then

            local distance =
                (object.Position - root.Position).Magnitude

            if distance < shortestDistance then
                shortestDistance = distance
                nearest = object
            end

        end

    end

    return nearest
end

--==================================================
-- WHITE PLASTIC: FIND EQUIPPED HANDLE
--==================================================

local function GetWhitePlasticHandle(character)

    local gun = character:FindFirstChild("Gun")

    if not gun or not gun:IsA("Tool") then
        return nil
    end

    local handle = gun:FindFirstChild("Handle")

    if not handle or not handle:IsA("MeshPart") then
        return nil
    end

    if not IsVerifiedMesh(handle) then
        return nil
    end

    return handle
end

--==================================================
-- WHITE PLASTIC: SAVE STATE
--==================================================

local function SaveWhitePlasticState(part)

    local state = WhitePlasticTargets[part]

    if state then
        return state
    end

    state = {
        Color = part.Color,
        Material = part.Material,
        MaterialVariant = part.MaterialVariant,
        Transparency = part.Transparency,

        TextureID = part:IsA("MeshPart")
            and part.TextureID or nil,

        Beams = {},
        RemovedAppearance = {}
    }

    WhitePlasticTargets[part] = state

    return state
end

--==================================================
-- WHITE PLASTIC: REMOVE APPEARANCE
--==================================================

local function RemoveWhitePlasticAppearance(part, state)

    for _, item in ipairs(part:GetDescendants()) do

        if item:IsA("SurfaceAppearance")
            or item:IsA("Decal")
            or item:IsA("Texture") then

            local success, clone = pcall(function()
                return item:Clone()
            end)

            if success and clone then

                table.insert(state.RemovedAppearance, {
                    Parent = item.Parent,
                    Clone = clone
                })

            end

            item:Destroy()

        end

    end

    if part:IsA("MeshPart") then
        part.TextureID = ""
    end

end

--==================================================
-- WHITE PLASTIC: APPLY
--==================================================

local function ApplyWhitePlasticPart(part)

    if not part or not part.Parent then
        return
    end

    if not part:IsA("BasePart") then
        return
    end

    local state = SaveWhitePlasticState(part)

    RemoveWhitePlasticAppearance(part, state)

    part.Color = WHITE_PLASTIC_CONFIG.Color
    part.Material = WHITE_PLASTIC_CONFIG.Material
    part.MaterialVariant = ""
    part.Transparency = WHITE_PLASTIC_CONFIG.Transparency

    -- Change every Beam inside CustomBeam
    local beams = GetBeams(part)

    for _, beam in ipairs(beams) do

        if beam.Parent then

            if not state.Beams[beam] then
                state.Beams[beam] = beam.Color
            end

            beam.Color = ColorSequence.new(
                WHITE_PLASTIC_CONFIG.Color
            )

        end

    end

end

--==================================================
-- WHITE PLASTIC: RESTORE TARGET
--==================================================

local function RestoreWhitePlasticPart(part, reapplyDesign)

    local state = WhitePlasticTargets[part]

    if not state then
        return
    end

    if part and part.Parent then

        part.Color = state.Color
        part.Material = state.Material
        part.MaterialVariant = state.MaterialVariant
        part.Transparency = state.Transparency

        if part:IsA("MeshPart") and state.TextureID ~= nil then
            part.TextureID = state.TextureID
        end

        -- Restore removed appearances
        for _, saved in ipairs(state.RemovedAppearance) do

            if saved.Parent
                and saved.Parent.Parent
                and saved.Clone then

                saved.Clone.Parent = saved.Parent

            end

        end

        -- Restore Beam colors
        for beam, originalColor in pairs(state.Beams) do

            if beam and beam.Parent then
                beam.Color = originalColor
            end

        end

    end

    WhitePlasticTargets[part] = nil

    -- Reapply the currently selected design
    if reapplyDesign
        and DesignEnabled
        and AppliedDesign
        and part
        and part.Parent
        and IsVerifiedMesh(part) then

        ApplyObject(part)

    end

end

--==================================================
-- WHITE PLASTIC: UPDATE TARGETS
--==================================================

local function UpdateWhitePlastic()

    local character = Player.Character

    if not character then
        return
    end

    local desiredTargets = {}

    local handle = GetWhitePlasticHandle(character)
    local display = FindNearestWhitePlasticDisplay(character)

    if handle then
        desiredTargets[handle] = true
    end

    if display then
        desiredTargets[display] = true
    end

    -- Restore targets no longer selected
    local oldTargets = {}

    for part in pairs(WhitePlasticTargets) do

        if not desiredTargets[part] then
            table.insert(oldTargets, part)
        end

    end

    for _, part in ipairs(oldTargets) do
        RestoreWhitePlasticPart(part, true)
    end

    -- Apply White Plastic to current targets
    for part in pairs(desiredTargets) do
        ApplyWhitePlasticPart(part)
    end

end

--==================================================
-- WHITE PLASTIC: DISABLE
--==================================================

local function DisableWhitePlastic(reapplyDesign)

    WhitePlasticEnabled = false

    local targets = {}

    for part in pairs(WhitePlasticTargets) do
        table.insert(targets, part)
    end

    for _, part in ipairs(targets) do
        RestoreWhitePlasticPart(part, reapplyDesign)
    end

end

--==================================================
-- WHITE PLASTIC: BUTTON
--==================================================

local function UpdateWhitePlasticButton()

    if not WhitePlasticButton then
        return
    end

    if WhitePlasticEnabled then

        WhitePlasticButton.Text = "WHITE PLASTIC GUN: ON"
        WhitePlasticButton.TextColor3 = Color3.fromRGB(0, 255, 0)

    else

        WhitePlasticButton.Text = "WHITE PLASTIC GUN: OFF"
        WhitePlasticButton.TextColor3 = Color3.fromRGB(255, 0, 0)

    end

end

local function ToggleWhitePlastic()

    WhitePlasticEnabled = not WhitePlasticEnabled

    if WhitePlasticEnabled then
        UpdateWhitePlastic()
    else
        DisableWhitePlastic(true)
    end

    UpdateWhitePlasticButton()

end

--==================================================
-- WHITE PLASTIC: UPDATE LOOP
--==================================================

RunService.Heartbeat:Connect(function()

    if not WhitePlasticEnabled then
        return
    end

    if os.clock() - WhitePlasticLastUpdate
        < WHITE_PLASTIC_CONFIG.UpdateInterval then

        return
    end

    WhitePlasticLastUpdate = os.clock()

    UpdateWhitePlastic()

end)

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

                if handle and not IsWhitePlasticTarget(handle) then

                    local state = OriginalStates[handle]

                    if not state then
                        SaveOriginal(handle)
                        state = OriginalStates[handle]
                    end

                    if state then

                        CaptureBeamState(handle, state)

                        if AppliedDesign.DisableBeamScript then
                            DisableBeamScripts(handle, state)
                        end

                        if not AppliedDesign.PreserveBeamColor then

                            local beams = GetBeams(handle)

                            for _, beam in ipairs(beams) do

                                if beam.Parent then

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

    -- First restore temporary White Plastic changes
    if WhitePlasticEnabled then
        DisableWhitePlastic(false)
    end

    UpdateWhitePlasticButton()

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
-- DETECT SCOPE (VOIDSCOPE / MATRIXSCOPE)
--==================================================

local function DetectScope()

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

local function SetActiveScope(scopeName)

    local scopeData = SCOPES[scopeName]
    if not scopeData then
        return
    end

    SelectedScope = scopeName
    ORIGINAL_ID = scopeData.TextureId

    table.clear(VerifiedObjects)

    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")

    if character then
        for _, object in ipairs(character:GetChildren()) do
            if VerifyGun(object) then
                MonitorVoidscope(object)
                if DesignEnabled and AppliedDesign then
                    ApplyGun(object)
                end
            end
        end
    end

    if backpack then
        for _, object in ipairs(backpack:GetChildren()) do
            if VerifyGun(object) then
                MonitorVoidscope(object)
                if DesignEnabled and AppliedDesign then
                    ApplyGun(object)
                end
            end
        end
    end

    if DesignEnabled and AppliedDesign then
        ApplyDisplays()
    end

    if WhitePlasticEnabled then
        UpdateWhitePlastic()
    end

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
local BackwardGlitchButton = nil

local ToggleBackwardGlitch

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

        if BackwardGlitchEnabled and ToggleBackwardGlitch then
            ToggleBackwardGlitch()
        end

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
-- AIR BACKWARD SPEED GLITCH
--==================================================

local function UpdateBackwardGlitchButton()

    if not BackwardGlitchButton then
        return
    end

    if BackwardGlitchEnabled then
        BackwardGlitchButton.Text = "AIR BACKWARD: ON"
        BackwardGlitchButton.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        BackwardGlitchButton.Text = "AIR BACKWARD: OFF"
        BackwardGlitchButton.TextColor3 = Color3.fromRGB(255, 0, 0)
    end

end

local function CleanupBackwardGlitch()

    if BackwardConnection then
        BackwardConnection:Disconnect()
        BackwardConnection = nil
    end

    if BackwardHumanoid and BackwardHumanoid.Parent then

        if BackwardChangedSpeed then
            BackwardHumanoid.WalkSpeed = BackwardOriginalSpeed
        end

    end

    BackwardHumanoid = nil
    BackwardRootPart = nil
    PreviousCameraDirection = nil
    BackwardUsedThisJump = false
    BackwardWasAirborne = false
    BackwardChangedSpeed = false

end

local function SetupBackwardGlitch(character)

    CleanupBackwardGlitch()

    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")

    BackwardHumanoid = humanoid
    BackwardRootPart = rootPart
    BackwardOriginalSpeed = humanoid.WalkSpeed

    local camera = workspace.CurrentCamera

    if camera then
        PreviousCameraDirection = camera.CFrame.LookVector
    end

    BackwardConnection = RunService.RenderStepped:Connect(function()

        if not BackwardGlitchEnabled
            or not BackwardHumanoid
            or not BackwardRootPart then

            return
        end

        if not BackwardHumanoid.Parent
            or not BackwardRootPart.Parent then

            return
        end

        local currentCamera = workspace.CurrentCamera

        if not currentCamera then
            return
        end

        local cameraDirection = currentCamera.CFrame.LookVector

        if not PreviousCameraDirection then
            PreviousCameraDirection = cameraDirection
            return
        end

        local cameraChange =
            (cameraDirection - PreviousCameraDirection).Magnitude

        PreviousCameraDirection = cameraDirection

        local airborne =
            BackwardHumanoid.FloorMaterial == Enum.Material.Air

        if not airborne then

            if BackwardWasAirborne then

                if BackwardChangedSpeed then
                    BackwardHumanoid.WalkSpeed = BackwardOriginalSpeed
                    BackwardChangedSpeed = false
                end

            end

            BackwardUsedThisJump = false
            BackwardWasAirborne = false

            return
        end

        BackwardWasAirborne = true

        local movingBackward =
            BackwardHumanoid.MoveDirection:Dot(
                BackwardRootPart.CFrame.LookVector
            ) < -0.1

        if airborne
            and movingBackward
            and cameraChange >= CAMERA_THRESHOLD
            and not BackwardUsedThisJump then

            BackwardUsedThisJump = true
            BackwardHumanoid.WalkSpeed = BackwardGlitchSpeed
            BackwardChangedSpeed = true

        end

    end)

end

ToggleBackwardGlitch = function()

    BackwardGlitchEnabled = not BackwardGlitchEnabled

    if BackwardGlitchEnabled then

        if SpeedEnabled then
            ToggleSpeed()
        end

        if Player.Character then
            SetupBackwardGlitch(Player.Character)
        end

        print("Air Backward enabled")

    else

        CleanupBackwardGlitch()
        print("Air Backward disabled")

    end

    UpdateBackwardGlitchButton()

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
Main.Size = UDim2.fromOffset(310, 500)
Main.Position = UDim2.new(0.5, -155, 0.5, -250)
Main.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true
Main.Parent = GUI

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

--==================================================
-- MAIN SCROLLING AREA
--==================================================

local MainScroll = Instance.new("ScrollingFrame")
MainScroll.Name = "MainScroll"
MainScroll.Size = UDim2.new(1, 0, 1, -42)
MainScroll.Position = UDim2.fromOffset(0, 42)
MainScroll.BackgroundTransparency = 1
MainScroll.BorderSizePixel = 0
MainScroll.CanvasSize = UDim2.new(0, 0, 0, 980)
MainScroll.ScrollingDirection = Enum.ScrollingDirection.Y
MainScroll.ScrollBarThickness = 5
MainScroll.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
MainScroll.ScrollBarImageTransparency = 0.15
MainScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
MainScroll.Parent = Main

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 0, 980)
Content.BackgroundTransparency = 1
Content.Parent = MainScroll

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 0, 42)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Text = "VOID SCOPE / CHANGER 2.6"
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
    button.Parent = Content

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
-- DETECT BUTTON + SCOPE DROPDOWN
--==================================================

local SCOPE_MENU_OPEN_HEIGHT = 80
local SCOPE_SHIFT_Y = SCOPE_MENU_OPEN_HEIGHT + 8

local ScopeDropdownButton = Instance.new("TextButton")
local ScopeSelectedHalf = Instance.new("Frame")
local ScopeBlackHalf = Instance.new("Frame")
local ScopeSelectorText = Instance.new("TextLabel")
local ScopeDropdownMenu = Instance.new("ScrollingFrame")

local ApplyButtonY = 195
local RestoreButtonY = 245
local ColorDropdownY = 300
local ColorMenuY = 345
local ReloadButtonY = 465
local SpeedTitleY = 515
local KeyInputY = 540
local AirSpeedY = 580
local KeybindButtonY = 618
local SpeedToggleButtonY = 665
local OldShiftlockButtonY = 712
local BackwardTitleY = 760
local BackwardGlitchButtonY = 790
local BackwardSpeedRowY = 840
local BackwardSliderY = 890
local WhitePlasticButtonY = 930
local BASE_CANVAS_HEIGHT = 990

local function UpdateScopeSelector(isOpen)
    local arrow = isOpen and "  ▲" or "  ▼"
    ScopeSelectedHalf.BackgroundColor3 = SelectedScope == "MATRIXSCOPE"
        and Color3.fromRGB(0, 170, 255)
        or Color3.fromRGB(90, 45, 160)
    ScopeSelectorText.Text = "SCOPE: " .. SelectedScope .. arrow
end

local function RefreshMenuLayout()
    local scopeOpen = ScopeDropdownMenu.Visible
    local shift = scopeOpen and SCOPE_SHIFT_Y or 0

    ApplyButton.Position = UDim2.fromOffset(18, ApplyButtonY + shift)
    RestoreButton.Position = UDim2.fromOffset(18, RestoreButtonY + shift)

    local colorDropdown = Content:FindFirstChild("ColorSelector")
    local colorMenu = Content:FindFirstChild("ColorOptions")
    if colorDropdown then
        colorDropdown.Position = UDim2.fromOffset(18, ColorDropdownY + shift)
    end
    if colorMenu then
        colorMenu.Position = UDim2.fromOffset(18, ColorMenuY + shift)
    end

    if ReloadAnimationButton then
        ReloadAnimationButton.Position = UDim2.fromOffset(18, ReloadButtonY + shift)
    end

    local speedTitle = Content:FindFirstChild("SpeedSettingsTitle")
    if speedTitle then
        speedTitle.Position = UDim2.fromOffset(18, SpeedTitleY + shift)
    end

    local speedKeyLabel = Content:FindFirstChild("SpeedKeyLabel")
    local speedKeyInput = Content:FindFirstChild("SpeedKeyInput")
    if speedKeyLabel then
        speedKeyLabel.Position = UDim2.fromOffset(18, KeyInputY + shift)
    end
    if speedKeyInput then
        speedKeyInput.Position = UDim2.fromOffset(160, KeyInputY + shift)
    end

    local airSpeedLabel = Content:FindFirstChild("AirSpeedLabel")
    local airSpeedInput = Content:FindFirstChild("AirSpeedInput")
    if airSpeedLabel then
        airSpeedLabel.Position = UDim2.fromOffset(18, AirSpeedY + shift)
    end
    if airSpeedInput then
        airSpeedInput.Position = UDim2.fromOffset(160, AirSpeedY + shift)
    end

    if KeybindButton then
        KeybindButton.Position = UDim2.fromOffset(18, KeybindButtonY + shift)
    end
    if SpeedToggleButton then
        SpeedToggleButton.Position = UDim2.fromOffset(18, SpeedToggleButtonY + shift)
    end
    if OldShiftlockButton then
        OldShiftlockButton.Position = UDim2.fromOffset(18, OldShiftlockButtonY + shift)
    end

    local backwardTitle = Content:FindFirstChild("AirBackwardTitle")
    if backwardTitle then
        backwardTitle.Position = UDim2.fromOffset(18, BackwardTitleY + shift)
    end
    if BackwardGlitchButton then
        BackwardGlitchButton.Position = UDim2.fromOffset(18, BackwardGlitchButtonY + shift)
    end

    local backwardSpeedLabel = Content:FindFirstChild("BackwardSpeedLabel")
    local backwardSpeedInput = Content:FindFirstChild("BackwardSpeedInput")
    if backwardSpeedLabel then
        backwardSpeedLabel.Position = UDim2.fromOffset(18, BackwardSpeedRowY + shift)
    end
    if backwardSpeedInput then
        backwardSpeedInput.Position = UDim2.fromOffset(160, BackwardSpeedRowY + shift)
    end

    local backwardSlider = Content:FindFirstChild("BackwardSpeedSlider")
    if backwardSlider then
        backwardSlider.Position = UDim2.fromOffset(18, BackwardSliderY + shift)
    end

    if WhitePlasticButton then
        WhitePlasticButton.Position = UDim2.fromOffset(18, WhitePlasticButtonY + shift)
    end

    local totalHeight = BASE_CANVAS_HEIGHT + shift
    Content.Size = UDim2.new(1, 0, 0, totalHeight)
    MainScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

DetectButton = CreateButton(
    "DetectButton",
    "DETECT",
    50,
    function()

        local found, displays = DetectScope()

        if found or displays > 0 then
            DetectButton.Text = SelectedScope .. " DETECTED"
        else
            DetectButton.Text = SelectedScope .. " NOT FOUND"
        end

        task.delay(2, function()

            if DetectButton.Parent then
                DetectButton.Text = "DETECT"
            end

        end)

    end
)

ScopeDropdownButton.Name = "ScopeSelector"
ScopeDropdownButton.Size = UDim2.new(1, -36, 0, 42)
ScopeDropdownButton.Position = UDim2.fromOffset(18, 100)
ScopeDropdownButton.BackgroundTransparency = 1
ScopeDropdownButton.Text = ""
ScopeDropdownButton.ZIndex = 3
ScopeDropdownButton.Parent = Content

ScopeSelectedHalf.Name = "SelectedHalf"
ScopeSelectedHalf.Size = UDim2.new(0.5, 0, 1, 0)
ScopeSelectedHalf.BackgroundColor3 = Color3.fromRGB(90, 45, 160)
ScopeSelectedHalf.BorderSizePixel = 0
ScopeSelectedHalf.ZIndex = 2
ScopeSelectedHalf.Parent = ScopeDropdownButton

ScopeBlackHalf.Name = "BlackHalf"
ScopeBlackHalf.Size = UDim2.new(0.5, 0, 1, 0)
ScopeBlackHalf.Position = UDim2.new(0.5, 0, 0, 0)
ScopeBlackHalf.BackgroundColor3 = BLACK
ScopeBlackHalf.BorderSizePixel = 0
ScopeBlackHalf.ZIndex = 2
ScopeBlackHalf.Parent = ScopeDropdownButton

local ScopeSelectorCorner = Instance.new("UICorner")
ScopeSelectorCorner.CornerRadius = UDim.new(0, 7)
ScopeSelectorCorner.Parent = ScopeDropdownButton

local ScopeHalfCorner = Instance.new("UICorner")
ScopeHalfCorner.CornerRadius = UDim.new(0, 7)
ScopeHalfCorner.Parent = ScopeSelectedHalf

local ScopeBlackCorner = Instance.new("UICorner")
ScopeBlackCorner.CornerRadius = UDim.new(0, 7)
ScopeBlackCorner.Parent = ScopeBlackHalf

ScopeSelectorText.Size = UDim2.new(1, 0, 1, 0)
ScopeSelectorText.BackgroundTransparency = 1
ScopeSelectorText.Text = "SCOPE: VOIDSCOPE  ▼"
ScopeSelectorText.TextColor3 = WHITE
ScopeSelectorText.Font = Enum.Font.GothamBold
ScopeSelectorText.TextSize = 12
ScopeSelectorText.ZIndex = 4
ScopeSelectorText.Parent = ScopeDropdownButton

ScopeDropdownMenu.Name = "ScopeOptions"
ScopeDropdownMenu.Size = UDim2.new(1, -36, 0, SCOPE_MENU_OPEN_HEIGHT)
ScopeDropdownMenu.Position = UDim2.fromOffset(18, 145)
ScopeDropdownMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ScopeDropdownMenu.BorderSizePixel = 0
ScopeDropdownMenu.Visible = false
ScopeDropdownMenu.ZIndex = 10
ScopeDropdownMenu.CanvasSize = UDim2.new(0, 0, 0, 0)
ScopeDropdownMenu.ScrollingDirection = Enum.ScrollingDirection.Y
ScopeDropdownMenu.ScrollBarThickness = 5
ScopeDropdownMenu.ScrollBarImageColor3 = WHITE
ScopeDropdownMenu.ScrollBarImageTransparency = 0.2
ScopeDropdownMenu.AutomaticCanvasSize = Enum.AutomaticSize.None
ScopeDropdownMenu.Parent = Content

local ScopeMenuCorner = Instance.new("UICorner")
ScopeMenuCorner.CornerRadius = UDim.new(0, 7)
ScopeMenuCorner.Parent = ScopeDropdownMenu

local ScopeMenuPadding = Instance.new("UIPadding")
ScopeMenuPadding.PaddingTop = UDim.new(0, 4)
ScopeMenuPadding.PaddingBottom = UDim.new(0, 4)
ScopeMenuPadding.PaddingLeft = UDim.new(0, 4)
ScopeMenuPadding.PaddingRight = UDim.new(0, 4)
ScopeMenuPadding.Parent = ScopeDropdownMenu

local ScopeMenuLayout = Instance.new("UIListLayout")
ScopeMenuLayout.FillDirection = Enum.FillDirection.Vertical
ScopeMenuLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScopeMenuLayout.Padding = UDim.new(0, 4)
ScopeMenuLayout.Parent = ScopeDropdownMenu

local function CreateScopeOption(scopeName, accentColor, order)

    local option = Instance.new("TextButton")
    option.Name = scopeName .. "Option"
    option.Size = UDim2.new(1, -8, 0, 32)
    option.LayoutOrder = order
    option.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
    option.BorderSizePixel = 0
    option.Text = ""
    option.ZIndex = 11
    option.Parent = ScopeDropdownMenu

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = option

    local colorSquare = Instance.new("Frame")
    colorSquare.Size = UDim2.fromOffset(18, 18)
    colorSquare.Position = UDim2.fromOffset(9, 7)
    colorSquare.BackgroundColor3 = accentColor
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
    label.Text = scopeName
    label.TextColor3 = WHITE
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 12
    label.Parent = option

    option.Activated:Connect(function()
        SetActiveScope(scopeName)
        ScopeDropdownMenu.Visible = false
        UpdateScopeSelector(false)
        RefreshMenuLayout()
    end)

end

CreateScopeOption("VOIDSCOPE", Color3.fromRGB(90, 45, 160), 1)
CreateScopeOption("MATRIXSCOPE", Color3.fromRGB(0, 170, 255), 2)

ScopeDropdownMenu.CanvasSize = UDim2.new(
    0,
    0,
    0,
    ScopeMenuLayout.AbsoluteContentSize.Y + 8
)

ScopeDropdownButton.Activated:Connect(function()
    ScopeDropdownMenu.Visible = not ScopeDropdownMenu.Visible
    UpdateScopeSelector(ScopeDropdownMenu.Visible)
    RefreshMenuLayout()
end)

--==================================================
-- APPLY TEXTURE BUTTON
--==================================================

ApplyButton = CreateButton(
    "ApplyButton",
    "APPLY TEXTURE",
    ApplyButtonY,
    function()

        local success, count, reason = ApplyDesign()

        if success then

            ApplyButton.Text = "DESIGN APPLIED"

        elseif reason == "SELECT_COLOR" then

            ApplyButton.Text = "SELECT A COLOR"

        else

            ApplyButton.Text = SelectedScope .. " NOT FOUND"

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
    RestoreButtonY,
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
DropdownButton.Position = UDim2.fromOffset(18, ColorDropdownY)
DropdownButton.BackgroundTransparency = 1
DropdownButton.Text = ""
DropdownButton.ZIndex = 3
DropdownButton.Parent = Content

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
DropdownMenu.Position = UDim2.fromOffset(18, ColorMenuY)
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
DropdownMenu.Parent = Content

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
        DisableBeamScript = colorData.DisableBeamScript or false,
        PreserveBeamColor = colorData.PreserveBeamColor or false
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
CreateColorOption("DARK_BLUE", 5)
CreateColorOption("LIGHT_PINK", 6)
CreateColorOption("LIGHT_BLUE", 7)
CreateColorOption("FOREST_GREEN", 8)
CreateColorOption("PINK", 9)
CreateColorOption("FUCHSIA", 10)
CreateColorOption("VIVID_LIGHT_GREEN", 11)
CreateColorOption("DARK_BURGUNDY", 12)

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
    ReloadButtonY,
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
SpeedTitle.Position = UDim2.fromOffset(18, SpeedTitleY)
SpeedTitle.BackgroundTransparency = 1
SpeedTitle.Text = "SPEED SETTINGS"
SpeedTitle.TextColor3 = WHITE
SpeedTitle.Font = Enum.Font.GothamBold
SpeedTitle.TextSize = 12
SpeedTitle.TextXAlignment = Enum.TextXAlignment.Left
SpeedTitle.Parent = Content

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
    label.Parent = Content

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
    box.Parent = Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = box

    return box
end

local KeyInput = CreateSettingRow(
    "SpeedKey",
    "TOGGLE KEY",
    "R",
    KeyInputY
)

local AirSpeedInput = CreateSettingRow(
    "AirSpeed",
    "AIR SPEED",
    "250",
    AirSpeedY
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
    KeybindButtonY,
    function()
        ToggleKeybind()
    end
)

KeybindButton.TextColor3 = Color3.fromRGB(0, 255, 0)

--==================================================
-- ORIGINAL SPEED GLITCH BUTTON
--==================================================

SpeedToggleButton = CreateButton(
    "SpeedToggleButton",
    "SPEED GLITCH: OFF",
    SpeedToggleButtonY,
    function()
        ToggleSpeed()
    end
)

SpeedToggleButton.TextSize = 12
SpeedToggleButton.TextColor3 = Color3.fromRGB(255, 0, 0)

--==================================================
-- OLD SHIFTLOCK BUTTON
--==================================================

OldShiftlockButton = CreateButton(
    "OldShiftlockButton",
    "OLD SHIFTLOCK: OFF",
    OldShiftlockButtonY,
    function()
        ToggleOldShiftlock()
    end
)

OldShiftlockButton.TextSize = 12
OldShiftlockButton.TextColor3 = Color3.fromRGB(255, 0, 0)

--==================================================
-- AIR BACKWARD SETTINGS
--==================================================

local BackwardTitle = Instance.new("TextLabel")
BackwardTitle.Name = "AirBackwardTitle"
BackwardTitle.Size = UDim2.new(1, -36, 0, 25)
BackwardTitle.Position = UDim2.fromOffset(18, BackwardTitleY)
BackwardTitle.BackgroundTransparency = 1
BackwardTitle.Text = "AIR BACKWARD SETTINGS"
BackwardTitle.TextColor3 = WHITE
BackwardTitle.Font = Enum.Font.GothamBold
BackwardTitle.TextSize = 12
BackwardTitle.TextXAlignment = Enum.TextXAlignment.Left
BackwardTitle.Parent = Content

BackwardGlitchButton = CreateButton(
    "BackwardGlitchButton",
    "AIR BACKWARD: OFF",
    BackwardGlitchButtonY,
    function()
        ToggleBackwardGlitch()
    end
)

BackwardGlitchButton.TextSize = 12
BackwardGlitchButton.TextColor3 = Color3.fromRGB(255, 0, 0)

local BackwardSpeedLabel = Instance.new("TextLabel")
BackwardSpeedLabel.Name = "BackwardSpeedLabel"
BackwardSpeedLabel.Size = UDim2.fromOffset(125, 32)
BackwardSpeedLabel.Position = UDim2.fromOffset(18, BackwardSpeedRowY)
BackwardSpeedLabel.BackgroundTransparency = 1
BackwardSpeedLabel.Text = "BACKWARD SPEED"
BackwardSpeedLabel.TextColor3 = WHITE
BackwardSpeedLabel.Font = Enum.Font.GothamBold
BackwardSpeedLabel.TextSize = 10
BackwardSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
BackwardSpeedLabel.Parent = Content

local BackwardSpeedInput = Instance.new("TextBox")
BackwardSpeedInput.Name = "BackwardSpeedInput"
BackwardSpeedInput.Size = UDim2.fromOffset(130, 32)
BackwardSpeedInput.Position = UDim2.fromOffset(160, BackwardSpeedRowY)
BackwardSpeedInput.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
BackwardSpeedInput.BorderSizePixel = 0
BackwardSpeedInput.Text = tostring(BackwardGlitchSpeed)
BackwardSpeedInput.TextColor3 = WHITE
BackwardSpeedInput.Font = Enum.Font.GothamBold
BackwardSpeedInput.TextSize = 12
BackwardSpeedInput.ClearTextOnFocus = false
BackwardSpeedInput.Parent = Content

local BackwardInputCorner = Instance.new("UICorner")
BackwardInputCorner.CornerRadius = UDim.new(0, 6)
BackwardInputCorner.Parent = BackwardSpeedInput

--==================================================
-- BACKWARD SPEED SLIDER
--==================================================

local BackwardSlider = Instance.new("Frame")
BackwardSlider.Name = "BackwardSpeedSlider"
BackwardSlider.Size = UDim2.new(1, -36, 0, 12)
BackwardSlider.Position = UDim2.fromOffset(18, BackwardSliderY)
BackwardSlider.BackgroundColor3 = Color3.fromRGB(65, 65, 75)
BackwardSlider.BorderSizePixel = 0
BackwardSlider.Parent = Content

local BackwardSliderCorner = Instance.new("UICorner")
BackwardSliderCorner.CornerRadius = UDim.new(0, 6)
BackwardSliderCorner.Parent = BackwardSlider

local BackwardFill = Instance.new("Frame")
BackwardFill.Size = UDim2.new(
    BackwardGlitchSpeed / MAX_BACKWARD_SPEED,
    0,
    1,
    0
)
BackwardFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
BackwardFill.BorderSizePixel = 0
BackwardFill.Parent = BackwardSlider

local BackwardFillCorner = Instance.new("UICorner")
BackwardFillCorner.CornerRadius = UDim.new(0, 6)
BackwardFillCorner.Parent = BackwardFill

local BackwardSliderButton = Instance.new("TextButton")
BackwardSliderButton.Size = UDim2.new(1, 0, 1, 18)
BackwardSliderButton.Position = UDim2.new(0, 0, 0, -9)
BackwardSliderButton.BackgroundTransparency = 1
BackwardSliderButton.Text = ""
BackwardSliderButton.Parent = BackwardSlider

local BackwardDragging = false

local function UpdateBackwardSlider(x)

    local percent = math.clamp(
        (x - BackwardSlider.AbsolutePosition.X)
        / BackwardSlider.AbsoluteSize.X,
        0,
        1
    )

    BackwardGlitchSpeed = math.clamp(
        math.floor(percent * MAX_BACKWARD_SPEED),
        MIN_BACKWARD_SPEED,
        MAX_BACKWARD_SPEED
    )

    BackwardFill.Size = UDim2.new(
        BackwardGlitchSpeed / MAX_BACKWARD_SPEED,
        0,
        1,
        0
    )

    BackwardSpeedInput.Text = tostring(BackwardGlitchSpeed)

end

BackwardSliderButton.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        BackwardDragging = true
        UpdateBackwardSlider(input.Position.X)

    end

end)

UserInputService.InputChanged:Connect(function(input)

    if BackwardDragging
        and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then

        UpdateBackwardSlider(input.Position.X)

    end

end)

UserInputService.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        BackwardDragging = false

    end

end)

BackwardSpeedInput.FocusLost:Connect(function(enterPressed)

    local newSpeed = tonumber(BackwardSpeedInput.Text)

    if enterPressed and newSpeed then

        BackwardGlitchSpeed = math.clamp(
            math.floor(newSpeed),
            MIN_BACKWARD_SPEED,
            MAX_BACKWARD_SPEED
        )

    end

    BackwardSpeedInput.Text = tostring(BackwardGlitchSpeed)

    BackwardFill.Size = UDim2.new(
        BackwardGlitchSpeed / MAX_BACKWARD_SPEED,
        0,
        1,
        0
    )

end)

--==================================================
-- WHITE PLASTIC GUN BUTTON
--==================================================

WhitePlasticButton = CreateButton(
    "WhitePlasticButton",
    "WHITE PLASTIC GUN: OFF",
    WhitePlasticButtonY,
    function()
        ToggleWhitePlastic()
    end
)

WhitePlasticButton.TextSize = 11
WhitePlasticButton.TextColor3 = Color3.fromRGB(255, 0, 0)

UpdateWhitePlasticButton()

--==================================================
-- UPDATE MAIN CANVAS
--==================================================

RefreshMenuLayout()

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

Minimize.Activated:Connect(function()

    Minimized = not Minimized

    if Minimized then

        MainScroll.Visible = false
        Main.Size = UDim2.fromOffset(310, 42)
        Minimize.Text = "+"

    else

        MainScroll.Visible = true
        Main.Size = UDim2.fromOffset(310, 500)
        Minimize.Text = "-"

    end

end)

Close.Activated:Connect(function()

    RestoreOriginal()
    CleanupSpeed()
    CleanupBackwardGlitch()

    SpeedEnabled = false
    BackwardGlitchEnabled = false

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
            or not SpeedRoot
