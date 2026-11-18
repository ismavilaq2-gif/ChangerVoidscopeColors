
--==================================================
-- VOIDSCOPE CHANGER 2.0
-- PRUEBA EN ROBLOX STUDIO
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ORIGINAL_ID = "rbxassetid://125806303939871"
local RED_ID = "rbxassetid://79908965595599"

local RED = Color3.fromRGB(255, 25, 25)
local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)

local TOTAL_DURATION = 0.20
local STEP_DURATION = TOTAL_DURATION / 6

local enabled = false
local equippedGun = nil
local animationRunning = false

local originalTextures = {}
local originalScriptStates = {}
local originalBeamColors = {}

local clickConnection
local equipConnection
local unequipConnection

--==================================================
-- INTERFAZ
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "VoidscopeChanger"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(300, 245)
main.Position = UDim2.new(0.5, -150, 0.5, -122)
main.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
main.BorderSizePixel = 0
main.Parent = gui

Instance.new("UICorner", main).CornerRadius =
    UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundTransparency = 1
title.Text = "VOIDSCOPE CHANGER 2.0"
title.TextColor3 = WHITE
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = main

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 25)
status.Position = UDim2.fromOffset(10, 205)
status.BackgroundTransparency = 1
status.Text = "Estado: ORIGINAL"
status.TextColor3 = WHITE
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.Parent = main

local function createButton(text, y, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -30, 0, 40)
    button.Position = UDim2.fromOffset(15, y)
    button.BackgroundColor3 = Color3.fromRGB(48, 48, 60)
    button.TextColor3 = WHITE
    button.Text = text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.Parent = main

    Instance.new("UICorner", button).CornerRadius =
        UDim.new(0, 7)

    button.MouseButton1Click:Connect(callback)

    return button
end

--==================================================
-- LOCALIZAR ARMA
--==================================================

local function getGun()
    local character = player.Character
    if not character then return nil end

    return character:FindFirstChild("Gun")
end

local function getBeam(gun)
    if not gun then return nil end

    local handle = gun:FindFirstChild("Handle")
    if not handle then return nil end

    local beam = handle:FindFirstChild("CustomBeam")

    if beam and beam:IsA("Beam") then
        return beam
    end

    return nil
end

local function getOldScript(gun)
    if not gun then return nil end

    local handle = gun:FindFirstChild("Handle")
    if not handle then return nil end

    local beam = handle:FindFirstChild("CustomBeam")
    if not beam then return nil end

    return beam:FindFirstChildWhichIsA("Script")
end

--==================================================
-- TEXTURAS
--==================================================

local function saveTexture(object)
    if originalTextures[object] == nil then
        originalTextures[object] = object.TextureID
    end
end

local function applyTextures()
    local character = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")

    local gun = character and character:FindFirstChild("Gun")
    local backpackGun = backpack and backpack:FindFirstChild("Gun")

    local function changeGun(tool)
        if not tool then return end

        local handle = tool:FindFirstChild("Handle")

        if handle and handle:IsA("MeshPart") then
            saveTexture(handle)
            handle.TextureID = RED_ID
        end
    end

    changeGun(gun)
    changeGun(backpackGun)

    local displays = workspace:FindFirstChild("WeaponDisplays")

    if displays then
        for _, object in ipairs(displays:GetDescendants()) do
            if object:IsA("MeshPart")
                and object.Name == "GunDisplay" then

                saveTexture(object)
                object.TextureID = RED_ID
            end
        end
    end
end

--==================================================
-- DESACTIVAR SCRIPT ANTERIOR
--==================================================

local function disableOldScript(gun)
    local oldScript = getOldScript(gun)

    if not oldScript then return end

    if originalScriptStates[oldScript] == nil then
        originalScriptStates[oldScript] = oldScript.Disabled
    end

    oldScript.Disabled = true
end

--==================================================
-- TITILEO: SEIS ESTADOS
--==================================================

local function animateBeam(beam)
    if not beam or not beam.Parent then
        return
    end

    if animationRunning then
        return
    end

    animationRunning = true

    local sequence = {
        BLACK,
        WHITE,
        BLACK,
        WHITE,
        BLACK,
        WHITE
    }

    for index = 1, 6 do
        if not beam.Parent then
            break
        end

        beam.Color = ColorSequence.new(sequence[index])

        task.wait(STEP_DURATION)
    end

    animationRunning = false
end

--==================================================
-- DETECTAR CLIC
--==================================================

local function disconnectClick()
    if clickConnection then
        clickConnection:Disconnect()
        clickConnection = nil
    end
end

local function connectClick(gun)
    disconnectClick()

    equippedGun = gun

    clickConnection = gun.Activated:Connect(function()
        if not enabled then return end
        if equippedGun ~= gun then return end

        local beam = getBeam(gun)

        if beam then
            animateBeam(beam)
        end
    end)
end

--==================================================
-- EQUIPAR / DESEQUIPAR
--==================================================

local function setupCharacter(character)
    character.ChildAdded:Connect(function(object)
        if object:IsA("Tool") and object.Name == "Gun" then
            if enabled then
                disableOldScript(object)
                connectClick(object)
            end
        end
    end)

    character.ChildRemoved:Connect(function(object)
        if object == equippedGun then
            disconnectClick()
            equippedGun = nil
        end
    end)

    local gun = character:FindFirstChild("Gun")

    if gun and enabled then
        disableOldScript(gun)
        connectClick(gun)
    end
end

--==================================================
-- APLICAR DISEÑO
--==================================================

local function applyDesign()
    enabled = true

    applyTextures()

    local gun = getGun()

    if gun then
        disableOldScript(gun)
        connectClick(gun)
    end

    status.Text = "Estado: ROJO ACTIVADO"
    status.TextColor3 = RED
end

--==================================================
-- RESTAURAR ORIGINAL
--==================================================

local function restoreOriginal()
    enabled = false

    disconnectClick()
    equippedGun = nil

    for object, texture in pairs(originalTextures) do
        if object and object.Parent then
            object.TextureID = texture
        end
    end

    table.clear(originalTextures)

    for oldScript, previousState in pairs(originalScriptStates) do
        if oldScript and oldScript.Parent then
            oldScript.Disabled = previousState
        end
    end

    table.clear(originalScriptStates)

    for beam, previousColor in pairs(originalBeamColors) do
        if beam and beam.Parent then
            beam.Color = previousColor
        end
    end

    table.clear(originalBeamColors)

    status.Text = "Estado: ORIGINAL"
    status.TextColor3 = WHITE
end

--==================================================
-- BOTONES
--==================================================

createButton("APLICAR DISEÑO ROJO", 55, applyDesign)

createButton("RESTAURAR ORIGINAL", 105, restoreOriginal)

createButton("MINIMIZAR", 155, function()
    main.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.G then
        main.Visible = not main.Visible
    end
end)

--==================================================
-- INICIO
--==================================================

if player.Character then
    setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)

print("VOIDSCOPE CHANGER 2.0 iniciado")
