--==================================================
-- VOIDSCOPE CHANGER 2.0
-- ROJO + AZUL + BLANCO / SELECTOR DESPLEGABLE
-- RELOADANIMATION INTEGRADO
-- ESTELA: CONTROL SELECTIVO
-- CONTROL SELECTIVO: CustomBeam.Script
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- CONFIGURACION
--==================================================

local ORIGINAL_ID = "rbxassetid://125806303939871"

local COLORS = {
    ROJO = {
        Texture = "rbxassetid://79908965595599",
        Color = Color3.fromRGB(255, 0, 0)
    },

    AZUL = {
        Texture = "rbxassetid://116708828152021",
        Color = Color3.fromRGB(0, 45, 160)
    },

    BLANCO = {
        Texture = "rbxassetid://126161683645981",
        Color = Color3.fromRGB(255, 255, 255),
        DisableBeamScript = true
    }
}

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)

local SOUND_ID = "rbxassetid://6968135315"
local TARGET_TOOL_NAME = "Gun"
local COOLDOWN_DURATION = 2

local ReloadAnimationEnabled = false

local actionSound = Instance.new("Sound")
actionSound.Name = "ReloadAnimationSound"
actionSound.SoundId = SOUND_ID
actionSound.Volume = 1
actionSound.Parent = SoundService

--==================================================
-- REGISTROS
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
-- IDENTIFICACION DE VOIDSCOPE
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

    if tool.Name ~= "Gun" then
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
-- LOCALIZAR BEAM Y SU SCRIPT
--==================================================

local function GetBeam(object)

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

    local beam = parent:FindFirstChild("CustomBeam", true)

    if beam and beam:IsA("Beam") then
        return beam
    end

    return nil
end

local function GetOriginalBeamScript(beam)

    if not beam then
        return nil
    end

    local scriptObject = beam:FindFirstChild("Script")

    if scriptObject and scriptObject:IsA("Script") then
        return scriptObject
    end

    return nil
end

--==================================================
-- GUARDAR ESTADO ORIGINAL
--==================================================

local function CaptureBeamState(object, state)

    local beam = GetBeam(object)

    if not beam then
        return
    end

    if state.Beam ~= beam then

        state.Beam = beam
        state.BeamColor = beam.Color

        local originalScript = GetOriginalBeamScript(beam)

        state.BeamScript = originalScript
        state.BeamScriptDisabled = originalScript
            and originalScript.Disabled
            or nil

    end

end

local function SaveOriginal(object)

    if OriginalStates[object] then
        return
    end

    local state = {
        TextureID = object.TextureID,
        Beam = nil,
        BeamColor = nil,
        BeamScript = nil,
        BeamScriptDisabled = nil
    }

    OriginalStates[object] = state

    CaptureBeamState(object, state)

end

--==================================================
-- APLICAR TEXTURA Y COLOR
--==================================================

local function ApplyObject(object)

    if not IsVerifiedMesh(object) then
        return false
    end

    SaveOriginal(object)

    local state = OriginalStates[object]

    object.TextureID = AppliedDesign.Texture

    CaptureBeamState(object, state)

    if state.Beam and state.Beam.Parent then

        if state.BeamScript and state.BeamScript.Parent then
            state.BeamScript.Disabled = true
        end

        -- BLANCO: conserva el color original del Beam.
        -- ROJO Y AZUL: aplican el color seleccionado.

        if not AppliedDesign.DisableBeamScript then

            state.Beam.Color = ColorSequence.new(
                AppliedDesign.Color
            )

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
-- VERIFICAR GUNDISPLAY
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
-- DETECCION CONTINUA DEL BEAM
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

                        local beam = GetBeam(handle)

                        if beam then

                            if state.BeamScript
                                and state.BeamScript.Parent then

                                state.BeamScript.Disabled = true

                            end

                            -- BLANCO no modifica Beam.Color.

                            if not AppliedDesign.DisableBeamScript then

                                beam.Color = ColorSequence.new(
                                    AppliedDesign.Color
                                )

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
-- APLICAR DISEÑO COMPLETO
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
-- RESTAURAR ORIGINAL
--==================================================

local function RestoreOriginal()

    DesignEnabled = false
    AppliedDesign = nil

    for object, state in pairs(OriginalStates) do

        if object and object.Parent then
            object.TextureID = state.TextureID
        end

        if state.Beam and state.Beam.Parent then
            state.Beam.Color = state.BeamColor
        end

        if state.BeamScript and state.BeamScript.Parent then
            state.BeamScript.Disabled = state.BeamScriptDisabled
        end

    end

    table.clear(OriginalStates)
    table.clear(VerifiedObjects)

end

--==================================================
-- SISTEMA RELOADANIMATION
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
-- DETECTAR VOIDSCOPE
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
-- CONECTAR HERRAMIENTA
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
-- INTERFAZ
--==================================================

local GUI = Instance.new("ScreenGui")
GUI.Name = "VoidscopeChanger"
GUI.ResetOnSpawn = false
GUI.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(310, 385)
Main.Position = UDim2.new(0.5, -155, 0.5, -192)
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
Title.Text = "VOID SCOPE / CHANGER"
Title.TextColor3 = WHITE
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

--==================================================
-- CREAR BOTONES
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
-- DETECTAR
--==================================================

DetectButton = CreateButton(
    "DetectButton",
    "DETECTAR VOIDSCOPE",
    50,
    function()

        local found, displays = DetectVoidscope()

        if found or displays > 0 then
            DetectButton.Text = "VOIDSCOPE DETECTADA"
        else
            DetectButton.Text = "NO SE ENCONTRO VOIDSCOPE"
        end

        task.delay(2, function()

            if DetectButton.Parent then
                DetectButton.Text = "DETECTAR VOIDSCOPE"
            end

        end)

    end
)

--==================================================
-- APLICAR TEXTURA
--==================================================

ApplyButton = CreateButton(
    "ApplyButton",
    "APLICAR TEXTURA",
    100,
    function()

        local success, count, reason = ApplyDesign()

        if success then

            ApplyButton.Text = "DISEÑO APLICADO"

        elseif reason == "SELECT_COLOR" then

            ApplyButton.Text = "SELECCIONA UN COLOR"

        else

            ApplyButton.Text = "VOIDSCOPE NO DETECTADA"

        end

        task.delay(2, function()

            if ApplyButton.Parent then
                ApplyButton.Text = "APLICAR TEXTURA"
            end

        end)

    end
)

--==================================================
-- RESTAURAR ORIGINAL
--==================================================

RestoreButton = CreateButton(
    "RestoreButton",
    "RESTAURAR ORIGINAL",
    150,
    function()

        RestoreOriginal()

        RestoreButton.Text = "ORIGINAL RESTAURADO"

        task.delay(2, function()

            if RestoreButton.Parent then
                RestoreButton.Text = "RESTAURAR ORIGINAL"
            end

        end)

    end
)

--==================================================
-- SELECTOR DESPLEGABLE DE COLORES
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
SelectorText.Text = "SELECCIONAR COLOR  ▼"
SelectorText.TextColor3 = WHITE
SelectorText.Font = Enum.Font.GothamBold
SelectorText.TextSize = 13
SelectorText.ZIndex = 4
SelectorText.Parent = DropdownButton

--==================================================
-- MENU DE COLORES
--==================================================

local DropdownMenu = Instance.new("Frame")
DropdownMenu.Name = "ColorOptions"
DropdownMenu.Size = UDim2.new(1, -36, 0, 112)
DropdownMenu.Position = UDim2.fromOffset(18, 250)
DropdownMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DropdownMenu.BorderSizePixel = 0
DropdownMenu.Visible = false
DropdownMenu.ZIndex = 10
DropdownMenu.Parent = Main

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 7)
MenuCorner.Parent = DropdownMenu

local function UpdateSelector()

    if not SelectedDesign then

        SelectedHalf.BackgroundColor3 = BLACK
        SelectorText.Text = "SELECCIONAR COLOR  ▼"

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

local function CreateColorOption(colorName, y)

    local data = COLORS[colorName]

    local option = Instance.new("TextButton")
    option.Name = colorName .. "Option"
    option.Size = UDim2.new(1, -8, 0, 32)
    option.Position = UDim2.fromOffset(4, y)
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

CreateColorOption("ROJO", 4)
CreateColorOption("AZUL", 40)
CreateColorOption("BLANCO", 76)

DropdownButton.Activated:Connect(function()

    DropdownMenu.Visible = not DropdownMenu.Visible

    if DropdownMenu.Visible then
        SelectorText.Text = SelectedDesign
            and ("COLOR: " .. SelectedDesign.Name .. "  ▲")
            or "SELECCIONAR COLOR  ▲"
    else
        UpdateSelector()
    end

end)

--==================================================
-- BOTON RELOADANIMATION
--==================================================

ReloadAnimationButton = CreateButton(
    "ReloadAnimationButton",
    "RELOADANIMATION: ACTIVATE",
    335,
    function()

        ReloadAnimationEnabled = not ReloadAnimationEnabled

        if ReloadAnimationEnabled then

            ReloadAnimationButton.Text = "RELOADANIMATION: NOACTIVATE"
            ReloadAnimationButton.TextColor3 = Color3.fromRGB(0, 255, 0)

        else

            ReloadAnimationButton.Text = "RELOADANIMATION: ACTIVATE"
            ReloadAnimationButton.TextColor3 = Color3.fromRGB(255, 0, 0)

        end

    end
)

ReloadAnimationButton.TextSize = 11
ReloadAnimationButton.TextColor3 = Color3.fromRGB(255, 0, 0)

--==================================================
-- MINIMIZAR Y CERRAR
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
        or UDim2.fromOffset(310, 385)

end)

Close.Activated:Connect(function()

    RestoreOriginal()
    GUI:Destroy()

end)

--==================================================
-- TECLA G
--==================================================

UserInputService.InputBegan:Connect(function(input, processed)

    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.G then

        MenuVisible = not MenuVisible
        Main.Visible = MenuVisible

    end

end)

--==================================================
-- DETECCION AUTOMATICA
--==================================================

local function SetupCharacter(character)

    SetupReloadAnimation(character)

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

Player.CharacterAdded:Connect(SetupCharacter)

if Player.Character then
    SetupCharacter(Player.Character)
end

print("[Voidscope Changer 2.0] Cargado correctamente.")
