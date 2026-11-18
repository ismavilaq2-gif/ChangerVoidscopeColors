
--[[
    VOIDSCOPE CHANGER
    Para pruebas en tu propio proyecto de Roblox Studio.

    Textura original: rbxassetid://125806303939871
    Textura personalizada: rbxassetid://79908965595599

    Estela: ROJO - BLANCO - ROJO - BLANCO - ROJO - BLANCO
    Duración aproximada: 0.20 segundos
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- CONFIGURACIÓN
local ORIGINAL_ID = "rbxassetid://125806303939871"
local CUSTOM_ID = "rbxassetid://79908965595599"

local RED = Color3.fromRGB(255, 0, 0)
local WHITE = Color3.fromRGB(255, 255, 255)

local TOTAL_DURATION = 0.20
local STEP_DURATION = TOTAL_DURATION / 6

-- REGISTROS
local records = {}
local connectedTools = {}
local beamTokens = {}

local designApplied = false
local menuVisible = true

-- UTILIDADES
local function isRecorded(object)
    return records[object] ~= nil
end

local function getBeam(object)
    if not object then
        return nil
    end

    if object:IsA("Tool") then
        local handle = object:FindFirstChild("Handle")
        if not handle then
            return nil
        end

        local beam = handle:FindFirstChild("CustomBeam", true)
        if beam and beam:IsA("Beam") then
            return beam
        end
    else
        local beam = object:FindFirstChild("CustomBeam", true)
        if beam and beam:IsA("Beam") then
            return beam
        end
    end

    return nil
end

local function getBeamScript(beam)
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

local function verifyTool(tool)
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

    if isRecorded(handle) then
        return true
    end

    return handle.TextureID == ORIGINAL_ID
end

local function verifyDisplay(display)
    if not display or not display:IsA("MeshPart") then
        return false
    end

    if display.Name ~= "GunDisplay" then
        return false
    end

    if isRecorded(display) then
        return true
    end

    return display.TextureID == ORIGINAL_ID
end

local function saveObject(object)
    if records[object] then
        return
    end

    local record = {
        texture = object.TextureID,
        beam = nil,
        beamColor = nil,
        beamScript = nil,
        scriptDisabled = nil
    }

    local beam = getBeam(object)

    if beam then
        record.beam = beam
        record.beamColor = beam.Color

        local beamScript = getBeamScript(beam)

        if beamScript then
            record.beamScript = beamScript
            record.scriptDisabled = beamScript.Disabled
        end
    end

    records[object] = record
end

-- APLICAR DISEÑO
local function applyObject(object)
    if not object then
        return false
    end

    saveObject(object)

    local record = records[object]
    if not record then
        return false
    end

    object.TextureID = CUSTOM_ID

    if record.beamScript and record.beamScript.Parent then
        record.beamScript.Disabled = true
    end

    return true
end

local function applyToTool(tool)
    if not verifyTool(tool) then
        return false
    end

    local handle = tool:FindFirstChild("Handle")
    if not handle then
        return false
    end

    return applyObject(handle)
end

local function applyToDisplays()
    local folder = workspace:FindFirstChild("WeaponDisplays")
    if not folder then
        return 0
    end

    local count = 0

    for _, object in ipairs(folder:GetDescendants()) do
        if verifyDisplay(object) then
            if applyObject(object) then
                count += 1
            end
        end
    end

    return count
end

local function applyDesign()
    designApplied = true

    local character = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")

    if character then
        for _, object in ipairs(character:GetChildren()) do
            if object:IsA("Tool") then
                applyToTool(object)
            end
        end
    end

    if backpack then
        for _, object in ipairs(backpack:GetChildren()) do
            if object:IsA("Tool") then
                applyToTool(object)
            end
        end
    end

    local displays = applyToDisplays()

    return displays
end

-- RESTAURAR
local function restoreAll()
    designApplied = false

    for beam, token in pairs(beamTokens) do
        beamTokens[beam] = token + 1
    end

    for object, record in pairs(records) do
        if object and object.Parent then
            object.TextureID = record.texture
        end

        if record.beam and record.beam.Parent then
            record.beam.Color = record.beamColor
        end

        if record.beamScript and record.beamScript.Parent then
            record.beamScript.Disabled = record.scriptDisabled
        end
    end

    table.clear(records)
end

-- ANIMACIÓN DE LA ESTELA
local function animateBeam(beam)
    if not designApplied or not beam or not beam.Parent then
        return
    end

    local originalColor = nil

    for _, record in pairs(records) do
        if record.beam == beam then
            originalColor = record.beamColor
            break
        end
    end

    if not originalColor then
        originalColor = beam.Color
    end

    local token = (beamTokens[beam] or 0) + 1
    beamTokens[beam] = token

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
            if not designApplied then
                return
            end

            if not beam.Parent or beamTokens[beam] ~= token then
                return
            end

            beam.Color = ColorSequence.new(color)

            task.wait(STEP_DURATION)
        end

        if beam.Parent and beamTokens[beam] == token then
            beam.Color = originalColor
        end
    end)
end

-- DETECTAR Y CONECTAR EL ARMA
local function connectTool(tool)
    if not verifyTool(tool) then
        return
    end

    if connectedTools[tool] then
        return
    end

    connectedTools[tool] = true

    tool.Activated:Connect(function()
        if not verifyTool(tool) then
            return
        end

        if designApplied then
            local beam = getBeam(tool)
            if beam then
                animateBeam(beam)
            end
        end
    end)

    if designApplied then
        applyToTool(tool)
    end
end

local function scanTools()
    local character = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")

    if character then
        for _, object in ipairs(character:GetChildren()) do
            if object:IsA("Tool") then
                connectTool(object)
            end
        end
    end

    if backpack then
        for _, object in ipairs(backpack:GetChildren()) do
            if object:IsA("Tool") then
                connectTool(object)
            end
        end
    end
end

local function detectVoidscope()
    local foundTool = false
    local foundDisplays = 0

    local character = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")

    if character then
        for _, object in ipairs(character:GetChildren()) do
            if verifyTool(object) then
                foundTool = true
                connectTool(object)
            end
        end
    end

    if backpack then
        for _, object in ipairs(backpack:GetChildren()) do
            if verifyTool(object) then
                foundTool = true
                connectTool(object)
            end
        end
    end

    local folder = workspace:FindFirstChild("WeaponDisplays")

    if folder then
        for _, object in ipairs(folder:GetDescendants()) do
            if verifyDisplay(object) then
                foundDisplays += 1
            end
        end
    end

    return foundTool, foundDisplays
end

-- INTERFAZ
local gui = Instance.new("ScreenGui")
gui.Name = "VoidscopeChanger"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(310, 285)
main.Position = UDim2.new(0.5, -155, 0.5, -142)
main.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 0, 42)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "VOID SCOPE  /  CHANGER"
title.TextColor3 = WHITE
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local function createButton(name, text, y, callback)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, -36, 0, 42)
    button.Position = UDim2.fromOffset(18, y)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = WHITE
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.AutoButtonColor = true
    button.Parent = main

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 7)
    buttonCorner.Parent = button

    button.Activated:Connect(callback)

    return button
end

local detectButton
local applyButton
local restoreButton

detectButton = createButton(
    "DetectButton",
    "DETECTAR VOIDSCOPE",
    55,
    function()
        local foundTool, displays = detectVoidscope()

        if foundTool or displays > 0 then
            detectButton.Text = "VOIDSCOPE DETECTADA"
        else
            detectButton.Text = "NO SE ENCONTRÓ VOIDSCOPE"
        end

        task.delay(2, function()
            if detectButton.Parent then
                detectButton.Text = "DETECTAR VOIDSCOPE"
            end
        end)
    end
)

applyButton = createButton(
    "ApplyButton",
    "APLICAR TEXTURA",
    105,
    function()
        local displays = applyDesign()

        scanTools()

        applyButton.Text = "DISEÑO APLICADO"

        task.delay(2, function()
            if applyButton.Parent then
                applyButton.Text = "APLICAR TEXTURA"
            end
        end)
    end
)

restoreButton = createButton(
    "RestoreButton",
    "RESTAURAR ORIGINAL",
    155,
    function()
        restoreAll()

        restoreButton.Text = "ORIGINAL RESTAURADO"

        task.delay(2, function()
            if restoreButton.Parent then
                restoreButton.Text = "RESTAURAR ORIGINAL"
            end
        end)
    end
)

-- BOTÓN ROJO: MITAD ROJA Y MITAD NEGRA
local redButton = Instance.new("TextButton")
redButton.Name = "RedButton"
redButton.Size = UDim2.new(1, -36, 0, 42)
redButton.Position = UDim2.fromOffset(18, 205)
redButton.BackgroundTransparency = 1
redButton.Text = "ROJO"
redButton.TextColor3 = WHITE
redButton.Font = Enum.Font.GothamBold
redButton.TextSize = 14
redButton.ZIndex = 3
redButton.Parent = main

local redLeft = Instance.new("Frame")
redLeft.Size = UDim2.new(0.5, 0, 1, 0)
redLeft.BackgroundColor3 = RED
redLeft.BorderSizePixel = 0
redLeft.ZIndex = 2
redLeft.Parent = redButton

local blackRight = Instance.new("Frame")
blackRight.Size = UDim2.new(0.5, 0, 1, 0)
blackRight.Position = UDim2.new(0.5, 0, 0, 0)
blackRight.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blackRight.BorderSizePixel = 0
blackRight.ZIndex = 2
blackRight.Parent = redButton

local redCorner = Instance.new("UICorner")
redCorner.CornerRadius = UDim.new(0, 7)
redCorner.Parent = redButton

local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 7)
leftCorner.Parent = redLeft

local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0, 7)
rightCorner.Parent = blackRight

redButton.Activated:Connect(function()
    applyDesign()
    scanTools()
end)

-- MINIMIZAR Y CERRAR
local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(30, 30)
minimize.Position = UDim2.new(1, -72, 0, 6)
minimize.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
minimize.Text = "-"
minimize.TextColor3 = WHITE
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 20
minimize.Parent = main

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 30)
close.Position = UDim2.new(1, -38, 0, 6)
close.BackgroundColor3 = Color3.fromRGB(130, 25, 25)
close.Text = "X"
close.TextColor3 = WHITE
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.Parent = main

local minimized = false

minimize.Activated:Connect(function()
    minimized = not minimized

    for _, object in ipairs(main:GetChildren()) do
        if object ~= title
            and object ~= minimize
            and object ~= close
            and object ~= corner then

            object.Visible = not minimized
        end
    end

    main.Size = minimized
        and UDim2.fromOffset(310, 42)
        or UDim2.fromOffset(310, 285)
end)

close.Activated:Connect(function()
    gui:Destroy()
end)

-- TECLA G: MOSTRAR / OCULTAR
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.G then
        menuVisible = not menuVisible
        main.Visible = menuVisible
    end
end)

-- DETECCIÓN AUTOMÁTICA
local function setupCharacter(character)
    character.ChildAdded:Connect(function(object)
        if object:IsA("Tool") then
            task.wait(0.1)
            connectTool(object)
        end
    end)

    scanTools()
end

player.CharacterAdded:Connect(setupCharacter)

local backpack = player:WaitForChild("Backpack")

backpack.ChildAdded:Connect(function(object)
    if object:IsA("Tool") then
        task.wait(0.1)
        connectTool(object)
    end
end)

if player.Character then
    setupCharacter(player.Character)
end

scanTools()

print("[Voidscope Changer] Cargado correctamente.")
