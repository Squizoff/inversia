local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local MainWindow = Rayfield:CreateWindow({
    Name = "Inversia",
    Theme = "Ocean",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by sqzof",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "Inversia"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "Inversia",
        Subtitle = "Key System",
        Note = "Key: Inversia",
        FileName = "InversiaKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = "Inversia"
    }
})

-- Combat Tab
local CombatTab = MainWindow:CreateTab("Combat", 4483362458)

-- Combat Section for Aimbot Settings
local CombatSection = CombatTab:CreateSection("Aimbot Settings")

-- Aimbot State Variables
local AimbotEnabled = false
local TeamCheckEnabled = false
local WallCheckEnabled = false
local SpawnProtectEnabled = false
local TargetBodyParts = {} -- Default target part
local MaxDistance = 500 -- Default max distance for aimbot
local FOVRadius = 150

-- Aimbot Toggle
local AimbotToggle = CombatTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(enabled)
        AimbotEnabled = enabled
    end,
    Section = CombatSection -- Place this in the combat section
})

-- Team Check Toggle
local TeamCheckToggle = CombatTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "TeamCheckToggle",
    Callback = function(enabled)
        TeamCheckEnabled = enabled
    end,
    Section = CombatSection -- Place this in the combat section
})

-- Wall Check Toggle
local WallCheckToggle = CombatTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Flag = "WallCheckToggle",
    Callback = function(enabled)
        WallCheckEnabled = enabled
    end,
    Section = CombatSection -- Place this in the combat section
})

local BodyPartDropdown = CombatTab:CreateDropdown({
    Name = "Target Body Parts",
    Options = {"Head", "Body", "Arms", "Legs"},
    MultipleOptions = true,  -- Allow multiple selections
    Flag = "BodyPartDropdown",
    Callback = function(selectedOptions)
        -- Update TargetBodyParts based on selection
        TargetBodyParts = {}
        
        for _, option in ipairs(selectedOptions) do
            if option == "Head" then
                table.insert(TargetBodyParts, "Head")
            elseif option == "Body" then
                table.insert(TargetBodyParts, "UpperTorso")
                table.insert(TargetBodyParts, "LowerTorso")
            elseif option == "Arms" then
                table.insert(TargetBodyParts, "LeftUpperArm")
                table.insert(TargetBodyParts, "LeftLowerArm")
                table.insert(TargetBodyParts, "RightUpperArm")
                table.insert(TargetBodyParts, "RightLowerArm")
            elseif option == "Legs" then
                table.insert(TargetBodyParts, "LeftLowerLeg")
                table.insert(TargetBodyParts, "RightLowerLeg")
                table.insert(TargetBodyParts, "LeftUpperLeg")
                table.insert(TargetBodyParts, "RightUpperLeg")
                table.insert(TargetBodyParts, "LeftFoot")
                table.insert(TargetBodyParts, "RightFoot")
            end
        end
    end,
    Section = CombatSection -- Place this in the combat section
})

local IgnoreDropdown = CombatTab:CreateDropdown({
    Name = "Ignore Players",
    Options = {"SpawnProtect"},
    MultipleOptions = true,  -- Allow multiple selections
    Flag = "IgnoreDropdown",
    Callback = function(selectedOptions)
        if table.find(selectedOptions, "SpawnProtect") then
            SpawnProtectEnabled = true
        else
            SpawnProtectEnabled = false
        end
    end,
    Section = CombatSection -- Place this in the combat section
})

local FOVSlider = CombatTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {0, 1000}, -- Максимальный радиус FOV
    Increment = 10,
    Suffix = "Pixels",
    CurrentValue = FOVRadius,
    Flag = "FOVSlider",
    Callback = function(value)
        FOVRadius = value
    end,
    Section = CombatSection -- Place this in the combat section
})

-- Distance Slider
local DistanceSlider = CombatTab:CreateSlider({
    Name = "Aimbot Max Distance",
    Range = {0, 3000},
    Increment = 10,
    Suffix = "Studs",
    CurrentValue = MaxDistance,
    Flag = "DistanceSlider",
    Callback = function(value)
        MaxDistance = value
    end,
    Section = CombatSection -- Place this in the combat section
})
local closestPlayer, shortestDistance = nil, math.huge

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.new(1, 0, 0) -- Красный цвет круга
FOVCircle.Filled = false
FOVCircle.Radius = FOVRadius

game:GetService("RunService").RenderStepped:Connect(function()
    local localPlayer = game.Players.LocalPlayer
    local camera = game.Workspace.CurrentCamera
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    -- Обновление FOV круга
    if FOVCircle then
        FOVCircle.Position = screenCenter
        FOVCircle.Radius = FOVRadius
        FOVCircle.Visible = AimbotEnabled -- Круг виден только если включен Aimbot
    end

    if not AimbotEnabled then return end

    local closestPlayer, shortestDistance = nil, math.huge

    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                continue
            end

            -- Игнорирование игрока с защитой от спавна
            local forcefield = player.Character:FindFirstChild("ForceField")
            if SpawnProtectEnabled and forcefield then
                continue
            end

            -- Проверка на команду
            if TeamCheckEnabled and player.Team == localPlayer.Team then
                continue
            end

            -- Проверка стены
            if WallCheckEnabled then
                local origin = camera.CFrame.Position
                local target = player.Character.HumanoidRootPart.Position
                local direction = (target - origin).Unit
                local distance = (target - origin).Magnitude

                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                raycastParams.FilterDescendantsInstances = {localPlayer.Character, camera}

                -- Filter out accessories and tools from being hit by the ray
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("Accessory") or part:IsA("Tool") then
                        table.insert(raycastParams.FilterDescendantsInstances, part)
                    end
                end

                raycastParams.IgnoreWater = true

                local raycastResult = game.Workspace:Raycast(origin, direction * distance, raycastParams)
                if raycastResult and not raycastResult.Instance:IsDescendantOf(player.Character) then
                    continue
                end
            end

            -- Проверка на направление камеры (не проверяем цели, которые находятся "за спиной")
            local cameraLookVector = camera.CFrame.LookVector
            local targetDirection = (player.Character.HumanoidRootPart.Position - camera.CFrame.Position).Unit
            local dotProduct = cameraLookVector:Dot(targetDirection)

            -- Игнорируем игрока, если он не в поле зрения (угол > 90 градусов)
            if dotProduct < 0 then
                continue
            end

            -- Проверка на расстояние и FOV
            local screenPosition, onScreen = camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            local distanceFromCenter = (Vector2.new(screenPosition.X, screenPosition.Y) - screenCenter).Magnitude

            if distanceFromCenter <= FOVRadius then
                local distance = (localPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                if distance < MaxDistance and distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    -- Наведение на ближайшего игрока
    if closestPlayer and TargetBodyParts then
        for _, bodyPartName in ipairs(TargetBodyParts) do
            local targetPart = closestPlayer.Character:FindFirstChild(bodyPartName)
            if targetPart then
                camera.CFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
                break -- Наведение на первую найденную часть тела
            end
        end
    end
end)

-- Visuals Tab
local VisualsTab = MainWindow:CreateTab("Visuals", 4483362458)

local ESPSection = VisualsTab:CreateSection("ESP Settings")

local settings = {
    defaultcolor = Color3.fromRGB(255,0,0),
    teamcheck = false,
    teamcolor = true,
    showBox = true,         -- Show Box
    showName = true,        -- Show Name
    showHealthBar = true    -- Show Health Bar
 };

-- services
local runService = game:GetService("RunService");
local players = game:GetService("Players");

-- variables
local localPlayer = players.LocalPlayer;
local camera = workspace.CurrentCamera;

-- functions
local newVector2, newColor3, newDrawing = Vector2.new, Color3.new, Drawing.new;
local tan, rad = math.tan, math.rad;
local round = function(...) local a = {}; for i,v in next, table.pack(...) do a[i] = math.round(v); end return unpack(a); end;
local wtvp = function(...) local a, b = camera.WorldToViewportPoint(camera, ...) return newVector2(a.X, a.Y), b, a.Z end;

local espCache = {};
local espEnabled = false; -- ESP state

local function createEsp(player)
    local drawings = {};
 
    drawings.box = newDrawing("Square");
    drawings.box.Thickness = 1;
    drawings.box.Filled = false;
    drawings.box.Color = settings.defaultcolor;
    drawings.box.Visible = false;
    drawings.box.ZIndex = 2;
 
    drawings.boxoutline = newDrawing("Square");
    drawings.boxoutline.Thickness = 3;
    drawings.boxoutline.Filled = false;
    drawings.boxoutline.Color = newColor3();
    drawings.boxoutline.Visible = false;
    drawings.boxoutline.ZIndex = 1;
 
    drawings.name = newDrawing("Text");
    drawings.name.Text = player.Name; -- Set the player's name
    drawings.name.Color = settings.teamcolor and player.TeamColor.Color or settings.defaultcolor;
    drawings.name.Visible = false;
    drawings.name.Center = true;
    drawings.name.Outline = true;
    drawings.name.OutlineColor = Color3.fromRGB(0, 0, 0);
    drawings.name.ZIndex = 3;
 
    drawings.healthBar = newDrawing("Square");
    drawings.healthBar.Thickness = 1;
    drawings.healthBar.Filled = true;
    drawings.healthBar.Color = Color3.fromRGB(0, 255, 0); -- Green color for health
    drawings.healthBar.Visible = false;
    drawings.healthBar.ZIndex = 3;
 
    -- Health bar outline
    drawings.healthBarOutline = newDrawing("Square");
    drawings.healthBarOutline.Thickness = 2;
    drawings.healthBarOutline.Filled = false;
    drawings.healthBarOutline.Color = Color3.fromRGB(0, 0, 0); -- Black outline
    drawings.healthBarOutline.Visible = false;
    drawings.healthBarOutline.ZIndex = 2;
 
    espCache[player] = drawings;
 end

local function removeEsp(player)
   if rawget(espCache, player) then
       for _, drawing in next, espCache[player] do
           drawing:Remove();
       end
       espCache[player] = nil;
   end
end

local function updateEsp(player, esp)
    local character = player and player.Character
    if character then
        -- Team Check: Пропускаем игроков из той же команды
        if settings.teamcheck and player.Team == localPlayer.Team then
            esp.box.Visible = false
            esp.boxoutline.Visible = false
            esp.name.Visible = false
            esp.healthBar.Visible = false
            esp.healthBarOutline.Visible = false
            return
        end

        local cframe = character:GetModelCFrame()
        local position, visible, depth = wtvp(cframe.Position)
        esp.box.Visible = visible and settings.showBox
        esp.boxoutline.Visible = visible and settings.showBox
        esp.name.Visible = visible and settings.showName
        esp.healthBar.Visible = visible and settings.showHealthBar
        esp.healthBarOutline.Visible = visible and settings.showHealthBar

        if cframe and visible then
            local scaleFactor = 1 / (depth * math.tan(math.rad(camera.FieldOfView / 2)) * 2) * 1000
            local width, height = math.round(4 * scaleFactor), math.round(5 * scaleFactor)
            local x, y = math.round(position.X), math.round(position.Y)

            esp.box.Size = Vector2.new(width, height)
            esp.box.Position = Vector2.new(math.round(x - width / 2), math.round(y - height / 2))
            esp.box.Color = settings.teamcolor and player.TeamColor.Color or settings.defaultcolor

            esp.boxoutline.Size = esp.box.Size
            esp.boxoutline.Position = esp.box.Position

            esp.name.Position = Vector2.new(math.round(x), math.round(y - height / 2 - 18))
            esp.name.Size = math.max(10, math.floor(20 / depth))

            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                local health = math.max(humanoid.Health, 0)
                local healthBarHeight = height * (health / humanoid.MaxHealth)

                -- Устанавливаем цвет шкалы здоровья в зависимости от текущего здоровья
                local healthBarColor = Color3.fromRGB(0, 255, 0)
                if health / humanoid.MaxHealth <= 0.25 then
                    healthBarColor = Color3.fromRGB(255, 0, 0)  -- Красный для низкого здоровья
                elseif health / humanoid.MaxHealth <= 0.5 then
                    healthBarColor = Color3.fromRGB(255, 255, 0)  -- Желтый для среднего здоровья
                end

                esp.healthBar.Size = Vector2.new(3.5, healthBarHeight)
                esp.healthBar.Position = Vector2.new(x - width / 2 - 11, y - height / 2 + (height - healthBarHeight))
                esp.healthBar.Color = healthBarColor

                esp.healthBarOutline.Size = Vector2.new(3.7, height)
                esp.healthBarOutline.Position = Vector2.new(x - width / 2 - 11, y - height / 2)
            end
        end
    else
        esp.box.Visible = false
        esp.boxoutline.Visible = false
        esp.name.Visible = false
        esp.healthBar.Visible = false
        esp.healthBarOutline.Visible = false
    end
end

-- Toggle ESP on or off
local ESPToggle = VisualsTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Flag = "ESP_Toggle",
    Callback = function(enabled)
        espEnabled = enabled;
        if espEnabled then
            for _, player in pairs(players:GetPlayers()) do
                if player ~= localPlayer then
                    createEsp(player);
                end
            end
        else
            for _, player in pairs(players:GetPlayers()) do
                if player ~= localPlayer then
                    removeEsp(player);
                end
            end
        end
    end,
    Section = ESPSection -- Place this in the visuals section
 }) 

 local ESPSettingsDropdown = VisualsTab:CreateDropdown({
    Name = "ESP Elements",
    Options = {"Box", "Name", "Healthbar"},
    MultipleOptions = true,  -- Allow multiple selections
    Flag = "ESPSettingsDropdown",
    Callback = function(selectedOptions)
        settings.showBox = table.find(selectedOptions, "Box") ~= nil
        settings.showName = table.find(selectedOptions, "Name") ~= nil
        settings.showHealthBar = table.find(selectedOptions, "Healthbar") ~= nil
    end,
    Section = ESPSection -- Place this in the visuals section
})

-- Событие для удаления ESP, когда игрок уходит
players.PlayerRemoving:Connect(function(player)
    if espCache[player] then
        removeEsp(player);
    end
end)

-- Событие для добавления ESP, когда игрок присоединяется
players.PlayerAdded:Connect(function(player)
    if espEnabled and player ~= localPlayer then
        createEsp(player);
    end
end)

-- Подключение RenderStepped для обновления ESP
runService.RenderStepped:Connect(function()
    if espEnabled then
        for _, player in pairs(players:GetPlayers()) do
            if player ~= localPlayer then
                local esp = espCache[player];
                if esp then
                    updateEsp(player, esp);
                end
            end
        end
    end
end)

-- ESP Settings: Configure Team Check and Color
local TeamCheckToggle = VisualsTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = settings.teamcheck,
   Flag = "TeamCheckToggle",
   Callback = function(enabled)
       settings.teamcheck = enabled;
   end,
   Section = ESPSection -- Place this in the visuals section
})

local TeamColorToggle = VisualsTab:CreateToggle({
   Name = "Team Color ESP",
   CurrentValue = settings.teamcolor,
   Flag = "TeamColorToggle",
   Callback = function(enabled)
       settings.teamcolor = enabled;
   end,
   Section = ESPSection -- Place this in the visuals section
})

-- Visuals Section for Highlight Settings
local VisualsSection = VisualsTab:CreateSection("Highlight Settings")

-- Highlight Toggle
local HighlightToggle = VisualsTab:CreateToggle({
    Name = "Enable Highlights",
    CurrentValue = false,
    Flag = "HighlightToggle",
    Callback = function(enabled) end,
    Section = VisualsSection -- Place this in the visuals section
})

game:GetService("RunService").RenderStepped:Connect(function()
    local localPlayer = game.Players.LocalPlayer
    for _, v in pairs(game.Players:GetChildren()) do
        if v ~= localPlayer and v.Character then -- Исключаем LocalPlayer
            if HighlightToggle.CurrentValue then
                if not v.Character:FindFirstChild("Highlight") then
                    local highlight = Instance.new("Highlight")
                    highlight.Parent = v.Character
                    highlight.FillTransparency = 0
                    highlight.FillColor = Color3.fromRGB(0,255,255)
                end
            else
                if v.Character:FindFirstChild("Highlight") then
                    v.Character.Highlight:Destroy()
                end
            end
        end
    end
end)
