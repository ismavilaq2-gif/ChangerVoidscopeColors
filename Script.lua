
--==================================================
-- VOIDSCOPE CHANGER
-- VERSION: 2.1
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- CONFIGURACION
local ORIGINAL_ID = "rbxassetid://125806303939871"
local CUSTOM_ID = "rbxassetid://79908965595599"

local RED = Color3.fromRGB(255, 0, 0)
local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)

local TRAIL_DURATION = 0.20
local STEP_DURATION = TRAIL_DURATION / 6

-- REGISTROS DE OBJETOS VERIFICADOS
local VerifiedObjects = {}
local OriginalStates = {}
local ConnectedTools = {}
local AnimationTokens = {}

local DesignEnabled = false

--==================================================
-- VERIFICACION DE VOIDSCOPE
--==================================================

local function IsVerified(object)
    if not object then
        return false
    end

    if VerifiedObjects[object] then
        return true
    end

    if not object:IsA("MeshPart") then
        return false
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

    if not handle or not handle:IsA("MeshPart") then
        return false
    end

    return IsVerified(handle)
end

local function VerifyDisplay(display)
    if not display or display.Name ~= "GunDisplay" then
        return false
    end

    return IsVerified(display)
end

--==================================================
-- LOCALIZAR CUSTOMBEAM
--==================================================

local function GetBeam(object)
    if not object then
        return nil
    end

    local beam

    if object:IsA("Tool") then
        local handle = object:FindFirstChild("Handle")
        if not handle then
            return nil
        end

        beam = handle:FindFirstChild("CustomBeam", true)
    else
        beam = object:FindFirstChild("CustomBeam", true)
    end

    if beam and beam:IsA("Beam") then
        return beam
    end

    return nil
end

local function GetBeamScript(beam)
    if not beam then
        return nil
    end

    for _, child in ipairs(beam:GetChildren()) do
        if child:IsA("Script") then
            return child
        end
    end

    return nil
end

--==================================================
-- GUARDAR ESTADO ORIGINAL
--==================================================

local function SaveOriginal(object)
    if OriginalStates[object] then
        return
    end

    local state = {
        TextureID = object.TextureID,
        Beam = nil,
        BeamColor = nil,
        BeamScript = nil,
        ScriptDisabled = nil
    }

    local beam = GetBeam(object)

    if beam then
        state.Beam = beam
        state.BeamColor = beam.Color

        local beamScript = GetBeamScript(beam)

        if beamScript then
            state.BeamScript = beamScript
            state.ScriptDisabled = beamScript.Disabled
        end
    end

    OriginalStates[object] = state
end

--==================================================
-- APLICAR TEXTURA
--==================================================

local function ApplyObject(object)
    if not IsVerified(object) then
        return false
    end

    SaveOriginal(object)

    local state = OriginalStates[object]

    object.TextureID = CUSTOM_ID

    if state.BeamScript and state.BeamScript.Parent then
        state.BeamScript.Disabled = true
    end

    return true
end

local function ApplyGun(tool)
    if not VerifyGun(tool) then
        return false
    end

    local handle = tool:FindFirstChild("Handle")

    if not handle then
        return false
    end

    return ApplyObject(handle)
end

local function ApplyDisplays()
    local folder = workspace:FindFirstChild("WeaponDisplays")

    if not folder then
        return 0
    end

    local count = 0

    for _, display in ipairs(folder:GetDescendants()) do
        if VerifyDisplay(display) then
            if ApplyObject(display) then
                count += 1
            end
        end
    end

    return count
end

local function ApplyDesign()
    DesignEnabled = true

    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")

    if character then
        for _, object in ipairs(character:GetChildren()) do
            if object:IsA("Tool") then
                ApplyGun(object)
            end
        end
    end

    if backpack then
        for _, object in ipairs(backpack:GetChildren()) do
            if object:IsA("Tool") then
                ApplyGun(object)
            end
        end
    end

    return ApplyDisplays()
end

--==================================================
-- RESTAURAR ORIGINAL
--==================================================

local function RestoreOriginal()
    DesignEnabled = false

    for beam, token in pairs(AnimationTokens) do
        AnimationTokens[beam] = token + 1
    end

    for object, state in pairs(OriginalStates) do
        if object and object.Parent then
            object.TextureID = state.TextureID
        end

        if state.Beam and state.Beam.Parent then
            state.Beam.Color = state.BeamColor
        end

        if state.BeamScript and state.BeamScript.Parent then
            state.BeamScript.Disabled = state.ScriptDisabled
        end
    end

    table.clear(OriginalStates)
    table.clear(VerifiedObjects)
end

--==================================================
-- ANIMACION ROJO / BLANCO
--==================================================

local function AnimateTrail(beam)
    if not DesignEnabled or not beam or not beam.Parent then
        return
    end

    local originalColor = beam.Color

    for _, state in pairs(OriginalStates) do
        if state.Beam == beam then
            originalColor = state.BeamColor
            break
        end
    end

    local token = (AnimationTokens[beam] or 0) + 1
    AnimationTokens[beam] = token

    local colors = {
        RED,
        WHITE,
        RED,
        WHITE,
        RED,
        WHITE
    }

    task.spawn(function()
        for _, color in ipairs(colors) do
            if not DesignEnabled then
                return
            end

            if not beam.Parent or AnimationTokens[beam] ~= token then
                return
            end

            beam.Color = ColorSequence.new(color)
            task.wait(STEP_DURATION)
        end

        if beam.Parent and AnimationTokens[beam] == token then
            beam.Color = originalColor
        end
    end)
end

--==================================================
-- CONECTAR DISPARO
--==================================================

local function ConnectTool(tool)
    if not VerifyGun(tool) then
        return
    end

    if ConnectedTools[tool] then
        return
    end

    ConnectedTools[tool] = true

    tool.Activated:Connect(function()
        if not DesignEnabled then
            return
        end

        if not VerifyGun(tool) then
            return
        end

        local beam = GetBeam(tool)

        if beam then
            AnimateTrail(beam)
        end
    end)

    if DesignEnabled then
        ApplyGun(tool)
    end
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
                ConnectTool(object)
            end
        end
    end

    if backpack then
        for _, object in ipairs(backpack:GetChildren()) do
            if VerifyGun(object) then
                foundGun = true
                ConnectTool(object)
            end
        end
    end

    local folder = workspace:FindFirstChild("WeaponDisplays")

    if folder then
        for _, display in ipairs(folder:GetDescendants()) do
            if VerifyDisplay(display) then
                displayCount += 1
            end
        end
    end

    return foundGun, displayCount
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
Main.Size = UDim2.fromOffset(310, 300)
Main.Position = UDim2.new(0.5, -155, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
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

ApplyButton = CreateButton(
    "ApplyButton",
    "APLICAR TEXTURA",
    100,
    function()
        local found, displays = DetectVoidscope()

        if not found and displays == 0 then
            ApplyButton.Text = "VOIDSCOPE NO DETECTADA"

            task.delay(2, function()
                if ApplyButton.Parent then
                    ApplyButton.Text = "APLICAR TEXTURA"
                end
            end)

            return
        end

        ApplyDesign()
        ApplyButton.Text = "DISEÑO APLICADO"

        task.delay(2, function()
            if ApplyButton.Parent then
                ApplyButton.Text = "APLICAR TEXTURA"
            end
        end)
    end
)

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
-- BOTON ROJO MITAD ROJO / MITAD NEGRO
--==================================================

local RedButton = Instance.new("TextButton")
RedButton.Name = "RedButton"
RedButton.Size = UDim2.new(1, -36, 0, 42)
RedButton.Position = UDim2.fromOffset(18, 205)
RedButton.BackgroundTransparency = 1
RedButton.Text = "ROJO"
RedButton.TextColor3 = WHITE
RedButton.Font = Enum.Font.GothamBold
RedButton.TextSize = 14
RedButton.ZIndex = 3
RedButton.Parent = Main

local RedHalf = Instance.new("Frame")
RedHalf.Size = UDim2.new(0.5, 0, 1, 0)
RedHalf.BackgroundColor3 = RED
RedHalf.BorderSizePixel = 0
RedHalf.ZIndex = 2
RedHalf.Parent = RedButton

local BlackHalf = Instance.new("Frame")
BlackHalf.Size = UDim2.new(0.5, 0, 1, 0)
BlackHalf.Position = UDim2.new(0.5, 0, 0, 0)
BlackHalf.BackgroundColor3 = BLACK
BlackHalf.BorderSizePixel = 0
BlackHalf.ZIndex = 2
BlackHalf.Parent = RedButton

local RedButtonCorner = Instance.new("UICorner")
RedButtonCorner.CornerRadius = UDim.new(0, 7)
RedButtonCorner.Parent = RedButton

local RedHalfCorner = Instance.new("UICorner")
RedHalfCorner.CornerRadius = UDim.new(0, 7)
RedHalfCorner.Parent = RedHalf

local BlackHalfCorner = Instance.new("UICorner")
BlackHalfCorner.CornerRadius = UDim.new(0, 7)
BlackHalfCorner.Parent = BlackHalf

RedButton.Activated:Connect(function()
    local found, displays = DetectVoidscope()

    if not found and displays == 0 then
        RedButton.Text = "NO ES VOIDSCOPE"

        task.delay(2, function()
            if RedButton.Parent then
                RedButton.Text = "ROJO"
            end
        end)

        return
    end

    ApplyDesign()
end)

--==================================================
-- MINIMIZAR / CERRAR
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

local Minimized = false

Minimize.Activated:Connect(function()
    Minimized = not Minimized

    for _, object in ipairs(Main:GetChildren()) do
        if object ~= Title
            and object ~= Minimize
            and object ~= Close
            and object ~= MainCorner then

            object.Visible = not Minimized
        end
    end

    Main.Size = Minimized
        and UDim2.fromOffset(310, 42)
        or UDim2.fromOffset(310, 300)
end)

Close.Activated:Connect(function()
    GUI:Destroy()
end)

--==================================================
-- TECLA G
--==================================================

local MenuVisible = true

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

print("[Voidscope Changer 2.1] Cargado.")
