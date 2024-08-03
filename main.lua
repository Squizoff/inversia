local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera

local guiVisible = true -- Флаг для видимости GUI, по умолчанию меню закрыто

-- Создаем GUI
local screenGui = Instance.new("ScreenGui", CoreGui)
screenGui.Name = "InversiaGUI"
screenGui.IgnoreGuiInset = true -- Игнорирование стандартных отступов GUI

-- Полупрозрачный темный фон за меню
local background = Instance.new("Frame", screenGui)
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.new(0, 0, 0)
background.BackgroundTransparency = 0.5
background.Visible = guiVisible

-- Основное меню
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 350, 0, 400)
frame.Position = UDim2.new(0.5, -175, 0.5, -200)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.BorderColor3 = Color3.fromRGB(40, 40, 40) -- Добавление рамки для стиля GameSense
frame.Active = true
frame.Draggable = true
frame.Visible = guiVisible

local titleLabel = Instance.new("TextLabel", frame)
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Text = "Inversia"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.BackgroundTransparency = 0
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Фон заголовка
titleLabel.Font = Enum.Font.SourceSansSemibold
titleLabel.TextSize = 20

-- Создаем вкладки
local tabs = {"Rage", "Visuals", "Misc"}
local tabButtons = {}
local tabFrames = {}

local tabHeight = 30
local tabWidth = frame.Size.X.Offset / #tabs

for i, tabName in ipairs(tabs) do
    local tabButton = Instance.new("TextButton", frame)
    tabButton.Size = UDim2.new(0, tabWidth, 0, tabHeight)
    tabButton.Position = UDim2.new(0, (i-1) * tabWidth, 0, 30)
    tabButton.Text = tabName
    tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    tabButton.BorderSizePixel = 0
    tabButton.Font = Enum.Font.SourceSans
    tabButton.TextSize = 18

    tabButtons[tabName] = tabButton

    local tabFrame = Instance.new("Frame", frame)
    tabFrame.Size = UDim2.new(1, 0, 1, -tabHeight-30)
    tabFrame.Position = UDim2.new(0, 0, 0, tabHeight+30)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = false

    tabFrames[tabName] = tabFrame

    tabButton.MouseButton1Click:Connect(function()
        for name, btn in pairs(tabButtons) do
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end
        for name, frm in pairs(tabFrames) do
            frm.Visible = false
        end
        tabButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        tabFrame.Visible = true
    end)
end

-- Включаем первую вкладку по умолчанию
tabButtons["Rage"].BackgroundColor3 = Color3.fromRGB(70, 70, 70)
tabFrames["Rage"].Visible = true

-- Функция для переключения видимости GUI
local function toggleMenu()
    guiVisible = not guiVisible
    frame.Visible = guiVisible
    background.Visible = guiVisible
end

-- Toggle menu with the Insert key
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if input.KeyCode == Enum.KeyCode.Insert and not gameProcessedEvent then
        toggleMenu()
    end
end)

-- Anti Aim Module
local angle = 45 -- Угол поворота в градусах
local interval = 0.1 -- Интервал между сменой направлений
local jitterActive = false -- Флаг для управления AntiAim

local function createAntiAimSettings(container)
    local enableButton = Instance.new("TextButton", container)
    enableButton.Size = UDim2.new(1, -20, 0, 30)
    enableButton.Position = UDim2.new(0, 10, 0, 10)
    enableButton.Text = "Enable Anti Aim"
    enableButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    enableButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    enableButton.BorderSizePixel = 0
    enableButton.Font = Enum.Font.SourceSans
    enableButton.TextSize = 18

    enableButton.MouseButton1Click:Connect(function()
        jitterActive = not jitterActive
        enableButton.Text = jitterActive and "Disable Anti Aim" or "Enable Anti Aim"
    end)

    local angleLabel = Instance.new("TextLabel", container)
    angleLabel.Size = UDim2.new(1, -20, 0, 30)
    angleLabel.Position = UDim2.new(0, 10, 0, 50)
    angleLabel.Text = "Angle: " .. angle
    angleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    angleLabel.BackgroundTransparency = 1
    angleLabel.Font = Enum.Font.SourceSans
    angleLabel.TextSize = 18

    local angleSlider = Instance.new("Frame", container)
    angleSlider.Size = UDim2.new(1, -20, 0, 30)
    angleSlider.Position = UDim2.new(0, 10, 0, 80)
    angleSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

    local angleThumb = Instance.new("TextButton", angleSlider)
    angleThumb.Size = UDim2.new(0, 10, 1, 0)
    angleThumb.Position = UDim2.new(angle / 180, -5, 0, 0)
    angleThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    angleThumb.Text = ""

    local function updateAngle(newValue)
        angle = newValue
        angleLabel.Text = "Angle: " .. angle
        angleThumb.Position = UDim2.new(newValue / 180, -5, 0, 0)
    end

    local draggingAngleThumb = false

    angleThumb.MouseButton1Down:Connect(function()
        draggingAngleThumb = true
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingAngleThumb = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingAngleThumb and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local frameAbsPos = frame.AbsolutePosition
            local frameAbsSize = frame.AbsoluteSize
            if mousePos.X < frameAbsPos.X or mousePos.X > frameAbsPos.X + frameAbsSize.X or mousePos.Y < frameAbsPos.Y or mousePos.Y > frameAbsPos.Y + frameAbsSize.Y then
                draggingAngleThumb = false
            else
                local sliderAbsPos = angleSlider.AbsolutePosition.X
                local sliderAbsSize = angleSlider.AbsoluteSize.X
                local newValue = math.clamp((mousePos.X - sliderAbsPos) / sliderAbsSize * 180, 0, 180)
                updateAngle(newValue)
            end
        end
    end)

    local intervalLabel = Instance.new("TextLabel", container)
    intervalLabel.Size = UDim2.new(1, -20, 0, 30)
    intervalLabel.Position = UDim2.new(0, 10, 0, 120)
    intervalLabel.Text = "Interval: " .. interval
    intervalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    intervalLabel.BackgroundTransparency = 1
    intervalLabel.Font = Enum.Font.SourceSans
    intervalLabel.TextSize = 18

    local intervalSlider = Instance.new("Frame", container)
    intervalSlider.Size = UDim2.new(1, -20, 0, 30)
    intervalSlider.Position = UDim2.new(0, 10, 0, 150)
    intervalSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

    local intervalThumb = Instance.new("TextButton", intervalSlider)
    intervalThumb.Size = UDim2.new(0, 10, 1, 0)
    intervalThumb.Position = UDim2.new(interval / 1, -5, 0, 0)
    intervalThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    intervalThumb.Text = ""

    local function updateInterval(newValue)
        interval = newValue
        intervalLabel.Text = "Interval: " .. string.format("%.2f", interval)
        intervalThumb.Position = UDim2.new(newValue / 1, -5, 0, 0)
    end

    local draggingIntervalThumb = false

    intervalThumb.MouseButton1Down:Connect(function()
        draggingIntervalThumb = true
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingIntervalThumb = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingIntervalThumb and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local frameAbsPos = frame.AbsolutePosition
            local frameAbsSize = frame.AbsoluteSize
            if mousePos.X < frameAbsPos.X or mousePos.X > frameAbsPos.X + frameAbsSize.X or mousePos.Y < frameAbsPos.Y or mousePos.Y > frameAbsPos.Y + frameAbsSize.Y then
                draggingIntervalThumb = false
            else
                local sliderAbsPos = intervalSlider.AbsolutePosition.X
                local sliderAbsSize = intervalSlider.AbsoluteSize.X
                local newValue = math.clamp((mousePos.X - sliderAbsPos) / sliderAbsSize * 1, 0.01, 1)
                updateInterval(newValue)
            end
        end
    end)
end

-- Вкладка Rage
local rageContainer = Instance.new("Frame", tabFrames["Rage"])
rageContainer.Size = UDim2.new(1, -20, 1, -20)
rageContainer.Position = UDim2.new(0, 10, 0, 10)
rageContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
rageContainer.BorderSizePixel = 0

createAntiAimSettings(rageContainer)

local aimAssistEnabled = false
local aimAssistRadius = 100
local aimAssistSmoothness = 0.1 -- Уровень сглаживания (начальное значение)
local aimAssistKey = Enum.UserInputType.MouseButton2

local function createAimAssistSettings(container)
    -- Enable/Disable Button
    local enableButton = Instance.new("TextButton", container)
    enableButton.Size = UDim2.new(1, -20, 0, 30)
    enableButton.Position = UDim2.new(0, 10, 0, 210)
    enableButton.Text = "Enable Aim Assist"
    enableButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    enableButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    enableButton.BorderSizePixel = 0
    enableButton.Font = Enum.Font.SourceSans
    enableButton.TextSize = 18

    enableButton.MouseButton1Click:Connect(function()
        aimAssistEnabled = not aimAssistEnabled
        enableButton.Text = aimAssistEnabled and "Disable Aim Assist" or "Enable Aim Assist"
    end)

    -- Radius Adjustment
    local radiusLabel = Instance.new("TextLabel", container)
    radiusLabel.Size = UDim2.new(1, -20, 0, 30)
    radiusLabel.Position = UDim2.new(0, 10, 0, 260)
    radiusLabel.Text = "Radius: " .. aimAssistRadius
    radiusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    radiusLabel.BackgroundTransparency = 1
    radiusLabel.Font = Enum.Font.SourceSans
    radiusLabel.TextSize = 18

    local radiusSlider = Instance.new("Frame", container)
    radiusSlider.Size = UDim2.new(1, -20, 0, 30)
    radiusSlider.Position = UDim2.new(0, 10, 0, 280)
    radiusSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

    local radiusThumb = Instance.new("TextButton", radiusSlider)
    radiusThumb.Size = UDim2.new(0, 10, 1, 0)
    radiusThumb.Position = UDim2.new(aimAssistRadius / 200, -5, 0, 0)
    radiusThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    radiusThumb.Text = ""

    local function updateRadius(newValue)
        aimAssistRadius = newValue
        radiusLabel.Text = "Radius: " .. aimAssistRadius
        radiusThumb.Position = UDim2.new(newValue / 200, -5, 0, 0)
    end

    local draggingRadiusThumb = false

    radiusThumb.MouseButton1Down:Connect(function()
        draggingRadiusThumb = true
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingRadiusThumb = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingRadiusThumb and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = input.Position
            local frameAbsPos = radiusSlider.AbsolutePosition
            local frameAbsSize = radiusSlider.AbsoluteSize
            local sliderAbsPos = radiusSlider.AbsolutePosition.X
            local sliderAbsSize = radiusSlider.AbsoluteSize.X

            -- Обработка ограничений по движению ползунка
            local clampedX = math.clamp(mousePos.X - sliderAbsPos, 0, sliderAbsSize)
            local newValue = math.clamp(clampedX / sliderAbsSize * 200, 0, 200)
            updateRadius(newValue)
        end
    end)

    -- Smoothness Adjustment
    local smoothnessLabel = Instance.new("TextLabel", container)
    smoothnessLabel.Size = UDim2.new(1, -20, 0, 30)
    smoothnessLabel.Position = UDim2.new(0, 10, 0, 320)
    smoothnessLabel.Text = "Smoothness: " .. string.format("%.2f", aimAssistSmoothness)
    smoothnessLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    smoothnessLabel.BackgroundTransparency = 1
    smoothnessLabel.Font = Enum.Font.SourceSans
    smoothnessLabel.TextSize = 18

    local smoothnessSlider = Instance.new("Frame", container)
    smoothnessSlider.Size = UDim2.new(1, -20, 0, 30)
    smoothnessSlider.Position = UDim2.new(0, 10, 0, 340)
    smoothnessSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

    local smoothnessThumb = Instance.new("TextButton", smoothnessSlider)
    smoothnessThumb.Size = UDim2.new(0, 10, 1, 0)
    smoothnessThumb.Position = UDim2.new(aimAssistSmoothness * 10 / 10, -5, 0, 0) -- Исправлено деление
    smoothnessThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    smoothnessThumb.Text = ""

    local function updateSmoothness(newValue)
        aimAssistSmoothness = newValue
        smoothnessLabel.Text = "Smoothness: " .. string.format("%.2f", aimAssistSmoothness)
        smoothnessThumb.Position = UDim2.new(newValue * 10 / 10, -5, 0, 0) -- Исправлено деление
    end

    local draggingSmoothnessThumb = false

    smoothnessThumb.MouseButton1Down:Connect(function()
        draggingSmoothnessThumb = true
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSmoothnessThumb = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingSmoothnessThumb and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = input.Position
            local frameAbsPos = smoothnessSlider.AbsolutePosition
            local frameAbsSize = smoothnessSlider.AbsoluteSize
            local sliderAbsPos = smoothnessSlider.AbsolutePosition.X
            local sliderAbsSize = smoothnessSlider.AbsoluteSize.X

            -- Обработка ограничений по движению ползунка
            local clampedX = math.clamp(mousePos.X - sliderAbsPos, 0, sliderAbsSize)
            local newValue = math.clamp(clampedX / sliderAbsSize, 0, 1)
            updateSmoothness(newValue)
        end
    end)
end

-- Создание настроек Aim Assist
createAimAssistSettings(tabFrames["Rage"])

local function isPlayerVisible(player)
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local humanoidRootPart = character.HumanoidRootPart
        local rayOrigin = Camera.CFrame.Position
        local rayDirection = (humanoidRootPart.Position - rayOrigin).unit * 1000 -- Large distance to ensure ray reaches player
        local raycastParams = RaycastParams.new()
        raycastParams.IgnoreWater = true
        raycastParams.FilterDescendantsInstances = {Player.Character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        
        local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        
        return not raycastResult or raycastResult.Instance:IsDescendantOf(character)
    end
    return false
end

local function hasSpawnProtection(player)
    -- Проверяем наличие ForceField у игрока
    local character = player.Character
    return character and character:FindFirstChildOfClass("ForceField") ~= nil
end

local function isFullyVisible(player)
    local character = player.Character
    if not character then
        return false
    end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not humanoidRootPart or not humanoid then
        return false
    end

    -- Проверяем наличие основных частей тела
    local essentialParts = {"Head", "Torso", "HumanoidRootPart"}
    for _, partName in ipairs(essentialParts) do
        if not character:FindFirstChild(partName) then
            return false
        end
    end

    return true
end

local function getClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = aimAssistRadius

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and isPlayerVisible(player) then
            local char = player.Character
            local team = player.Team
            local playerTeam = Player.Team

            if (team ~= playerTeam or playerTeam == nil) then
            --if (team ~= playerTeam or playerTeam == nil) and not hasSpawnProtection(player) and isFullyVisible(player) then
                local screenPoint = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
                local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - UserInputService:GetMouseLocation()).Magnitude

                if distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestPlayer
end

RunService.RenderStepped:Connect(function()
    if aimAssistEnabled and not UserInputService:IsMouseButtonPressed(aimAssistKey) then
        local closestPlayer = getClosestPlayerToCursor()
        if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local aimPart = closestPlayer.Character:FindFirstChild("Head") or closestPlayer.Character:FindFirstChild("HumanoidRootPart")
            if aimPart then
                local targetPosition = aimPart.Position
                local cameraPosition = Camera.CFrame.Position
                local cameraLookAt = (targetPosition - cameraPosition).unit
                local currentLookAt = Camera.CFrame.LookVector
                local newLookAt = currentLookAt:Lerp(cameraLookAt, aimAssistSmoothness)
                Camera.CFrame = CFrame.new(cameraPosition, cameraPosition + newLookAt)
            end
        end
    end
end)

-- Добавляем переменные для triggerbot
local triggerbotEnabled = false -- Флаг для активации triggerbot
local triggerbotKey = Enum.KeyCode.T -- Клавиша для включения/выключения triggerbot
local triggerbotInterval = 0.01 -- Интервал для проверки (в секундах)

local function createTriggerbotSettings(container)
    -- Enable/Disable Button
    local enableButton = Instance.new("TextButton", container)
    enableButton.Size = UDim2.new(1, -20, 0, 30)
    enableButton.Position = UDim2.new(0, 10, 0, 370)
    enableButton.Text = "Enable Triggerbot"
    enableButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    enableButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    enableButton.BorderSizePixel = 0
    enableButton.Font = Enum.Font.SourceSans
    enableButton.TextSize = 18

    enableButton.MouseButton1Click:Connect(function()
        triggerbotEnabled = not triggerbotEnabled
        enableButton.Text = triggerbotEnabled and "Disable Triggerbot" or "Enable Triggerbot"
    end)
end

-- Добавляем Triggerbot в вкладку "Rage"
createTriggerbotSettings(tabFrames["Rage"])

-- Функция для проверки, находится ли игрок в центре экрана
local function isPlayerInCenterScreen(player)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local aimPart = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
        if aimPart then
            local screenPoint, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
            local centerX = Camera.ViewportSize.X / 2
            local centerY = Camera.ViewportSize.Y / 2
            
            -- Определите радиус, в пределах которого игрок считается находящимся в центре экрана
            local radius = 23 -- Пиксели, допустимое отклонение от центра экрана
            
            -- Проверяем, находится ли игрок в пределах радиуса от центра экрана
            return onScreen and math.abs(screenPoint.X - centerX) <= radius and math.abs(screenPoint.Y - centerY) <= radius
        end
    end
    return false
end

-- Функция для автоматического нажатия и отпускания ЛКМ
local function autoClick()
    if triggerbotEnabled then
        local closestPlayer = getClosestPlayerToCursor()
        if closestPlayer then
            if isPlayerInCenterScreen(closestPlayer) then
                wait(0.05)
                if isPlayerInCenterScreen(closestPlayer) then
                    Input.LeftClick()
                    print("123")
                end
            end
        end
    end
end

-- Обновляем RenderStepped функцию для работы с triggerbot
RunService.RenderStepped:Connect(function()
    if aimAssistEnabled and not UserInputService:IsMouseButtonPressed(aimAssistKey) then
        local closestPlayer = getClosestPlayerToCursor()
        if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local aimPart = closestPlayer.Character:FindFirstChild("Head") or closestPlayer.Character:FindFirstChild("HumanoidRootPart")
            if aimPart then
                local targetPosition = aimPart.Position
                local cameraPosition = Camera.CFrame.Position
                local cameraLookAt = (targetPosition - cameraPosition).unit
                local currentLookAt = Camera.CFrame.LookVector
                local newLookAt = currentLookAt:Lerp(cameraLookAt, aimAssistSmoothness)
                Camera.CFrame = CFrame.new(cameraPosition, cameraPosition + newLookAt)
            end
        end
    end

    autoClick() -- Добавляем вызов функции triggerbot
end)

-- Обработка нажатия клавиш для переключения triggerbot
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if input.KeyCode == triggerbotKey and not gameProcessedEvent then
        triggerbotEnabled = not triggerbotEnabled
    end
end)

-- Вкладка Visuals
local visualsContainer = Instance.new("Frame", tabFrames["Visuals"])
visualsContainer.Size = UDim2.new(1, -20, 1, -20)
visualsContainer.Position = UDim2.new(0, 10, 0, 10)
visualsContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
visualsContainer.BorderSizePixel = 0

local visualsLabel = Instance.new("TextLabel", visualsContainer)
visualsLabel.Size = UDim2.new(1, -20, 0, 30)
visualsLabel.Position = UDim2.new(0, 10, 0, 10)
visualsLabel.Text = "Visual Settings"
visualsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
visualsLabel.BackgroundTransparency = 1
visualsLabel.Font = Enum.Font.SourceSans
visualsLabel.TextSize = 18

-- Вкладка Misc
local miscContainer = Instance.new("Frame", tabFrames["Misc"])
miscContainer.Size = UDim2.new(1, -20, 1, -20)
miscContainer.Position = UDim2.new(0, 10, 0, 10)
miscContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
miscContainer.BorderSizePixel = 0

local miscLabel = Instance.new("TextLabel", miscContainer)
miscLabel.Size = UDim2.new(1, -20, 0, 30)
miscLabel.Position = UDim2.new(0, 10, 0, 10)
miscLabel.Text = "Miscellaneous Settings"
miscLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
miscLabel.BackgroundTransparency = 1
miscLabel.Font = Enum.Font.SourceSans
miscLabel.TextSize = 18

local humRoot = Player.Character and Player.Character:WaitForChild("HumanoidRootPart")

local function jitterAntiAim()
    while true do
        if jitterActive then
            local humRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if humRoot then
                Player.Character:WaitForChild("Humanoid").AutoRotate = false
                humRoot.CFrame = humRoot.CFrame * CFrame.Angles(-0.03, math.rad(angle), 0.03)
                task.wait(interval)
                humRoot.CFrame = humRoot.CFrame * CFrame.Angles(0.03, math.rad(-angle), -0.03)
                humRoot.CFrame = humRoot.CFrame * CFrame.Angles(0.03, math.rad(-angle), -0.03)
                task.wait(interval)
                humRoot.CFrame = humRoot.CFrame * CFrame.Angles(-0.03, math.rad(angle), 0.03)
            else
                task.wait(0.1)
            end
        else
            Player.Character:WaitForChild("Humanoid").AutoRotate = true
            task.wait(0.1)
        end
    end
end

task.spawn(jitterAntiAim)

local playerTeamColor = Player.TeamColor and Player.TeamColor.Color

local espEnabled = false -- Флаг включения ESP

local function createDrawing(type, properties)
    local drawing = Drawing.new(type)
    for property, value in pairs(properties) do
        drawing[property] = value
    end
    return drawing
end

local espDrawings = {} -- Таблица для хранения всех ESP-рисунков

-- Функция для получения цвета на основе расстояния
local function getColorByDistance(distance)
    -- Задаем максимальное расстояние для градации
    local maxDistance = 150 -- Можете изменить это значение
    -- Вычисляем коэффициент нормализации
    local factor = math.clamp(distance / maxDistance, 0, 1)
    -- Интерполяция цвета от красного к черному
    local r = 255 * (1 - factor)
    local g = 0
    local b = 0
    return Color3.fromRGB(r, g, b)
end

local function updateESP()
    -- Удаляем старые рисованные элементы
    for _, drawings in pairs(espDrawings) do
        for _, drawing in pairs(drawings) do
            drawing:Remove()
        end
    end
    espDrawings = {}

    if espEnabled then
        local playerPos = Camera.CFrame.Position

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                -- Проверяем, что игрок не из той же команды
                if player.Team ~= Player.Team or player.Team == nil then
                    local hrp = player.Character.HumanoidRootPart
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    local distance = (hrp.Position - playerPos).Magnitude
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

                    if onScreen then
                        local espElements = {}

                        -- Определяем цвет рамки по расстоянию
                        local color = getColorByDistance(distance)

                        -- Получаем позиции верхнего и нижнего края игрока
                        local headPos = Camera:WorldToViewportPoint(player.Character.Head.Position)
                        local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                        -- Вычисляем размер и позицию рамки
                        local boxHeight = (headPos.Y - legPos.Y)
                        local boxWidth = boxHeight / 2
                        local boxPos = Vector2.new(screenPos.X - boxWidth / 2, legPos.Y)

                        -- Рисуем рамку вокруг игрока
                        local box = createDrawing("Square", {
                            Size = Vector2.new(boxWidth, boxHeight),
                            Position = boxPos,
                            Color = color,
                            Thickness = 2,
                            Transparency = 1,
                            Visible = true
                        })
                        table.insert(espElements, box)

                        -- Рисуем имя игрока
                        local nameLabel = createDrawing("Text", {
                            Text = player.Name,
                            Position = Vector2.new(screenPos.X, headPos.Y - 20), -- Позиция над рамкой
                            Color = Color3.fromRGB(255, 255, 255),
                            Size = 14,
                            Center = true,
                            Outline = true,
                            Visible = true
                        })
                        table.insert(espElements, nameLabel)

                        if humanoid then
                            -- Определяем фиксированную ширину полоски здоровья
                            local healthBarWidth = boxHeight / 12

                            -- Рисуем фон для полоски здоровья
                            local healthBarBackground = createDrawing("Square", {
                                Size = Vector2.new(healthBarWidth, healthBarHeight),
                                Position = Vector2.new(boxPos.X, boxPos.Y),
                                Color = Color3.fromRGB(255, 0, 0),
                                Filled = true,
                                Visible = true
                            })
                            table.insert(espElements, healthBarBackground)

                            -- Рисуем саму полоску здоровья
                            local healthBarHeight = boxHeight * (humanoid.Health / humanoid.MaxHealth)
                            local healthBar = createDrawing("Square", {
                                Size = Vector2.new(healthBarWidth, healthBarHeight),
                                Position = Vector2.new(boxPos.X, boxPos.Y),
                                Color = Color3.fromRGB(0, 255, 0),
                                Filled = true,
                                Visible = true
                            })
                            table.insert(espElements, healthBar)
                        end

                        -- Сохраняем рисунки для удаления при следующем обновлении
                        espDrawings[player] = espElements
                    end
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(updateESP)

local function toggleESP()
    espEnabled = not espEnabled
end

-- Установите таймер для обновления ESP каждые 0.4 секунды
local lastUpdate = tick()

RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if espEnabled and (currentTime - lastUpdate > 0.2) then
        lastUpdate = currentTime
        updateESP()
    end
end)

local espButton = Instance.new("TextButton", visualsContainer)
espButton.Size = UDim2.new(1, -20, 0, 30)
espButton.Position = UDim2.new(0, 10, 0, 50)
espButton.Text = "Toggle ESP"
espButton.TextColor3 = Color3.fromRGB(255, 255, 255)
espButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
espButton.BorderSizePixel = 0
espButton.Font = Enum.Font.SourceSans
espButton.TextSize = 18

espButton.MouseButton1Click:Connect(toggleESP)

-- Функция для пересчета размера фрейма, чтобы он охватывал все дочерние элементы
local function updateFrameSize(frame)
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge

    for _, child in pairs(frame:GetChildren()) do
        if child:IsA("GuiObject") and child.Visible then
            local childPos = child.AbsolutePosition
            local childSize = child.AbsoluteSize
            minX = math.min(minX, childPos.X)
            minY = math.min(minY, childPos.Y)
            maxX = math.max(maxX, childPos.X + childSize.X)
            maxY = math.max(maxY, childPos.Y + childSize.Y)
        end
    end

    local newSize = UDim2.new(0, maxX - minX, 0, maxY - minY)
    frame.Size = newSize
end

updateFrameSize(rageContainer)
