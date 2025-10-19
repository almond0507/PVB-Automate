local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local function getSeedsList()
    local seeds = {}
    local seedsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Seeds")
    local Util = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Utility"):WaitForChild("Util"))
    
    for _, seed in ipairs(seedsFolder:GetChildren()) do
        local seedEntry = Util:GetSeedEntry(seed.Name)
        if seedEntry and not seedEntry.Hidden then
            table.insert(seeds, seed.Name)
        end
    end
    table.sort(seeds) 
    return seeds
end

local function getGearsList()
    local gears = {}
    local gearsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Gears")
    for _, gear in ipairs(gearsFolder:GetChildren()) do
        if gear:GetAttribute("Price") then
            table.insert(gears, gear.Name)
        end
    end
    table.sort(gears) 
    return gears
end

-- Configuration - Automatically updated from game
local gearList = getGearsList()
local seedList = getSeedsList()

print("> Loaded " .. #seedList .. " seeds and " .. #gearList .. " gears from shop")

local buyingSeedsActive = false
local buyingGearsActive = false
local equipBrainrotActive = false
local brainrotInterval = 60

local TOGGLE_KEY = Enum.KeyCode.RightControl

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoBuyGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 260)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MinButton = Instance.new("TextButton")
MinButton.Name = "MinButton"
MinButton.Size = UDim2.new(0, 50, 0, 50)
MinButton.Position = UDim2.new(0, 10, 0.5, -25)
MinButton.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
MinButton.Text = "PVB"
MinButton.TextColor3 = Color3.fromRGB(100, 150, 255)
MinButton.TextSize = 14
MinButton.Font = Enum.Font.GothamBold
MinButton.Visible = false
MinButton.Parent = ScreenGui

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 10)
MinCorner.Parent = MinButton

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleCover = Instance.new("Frame")
TitleCover.Size = UDim2.new(1, 0, 0, 12)
TitleCover.Position = UDim2.new(0, 0, 1, -12)
TitleCover.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
TitleCover.BorderSizePixel = 0
TitleCover.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -85, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "PVB Auto Buy"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 35, 0, 28)
MinBtn.Position = UDim2.new(1, -75, 0.5, -14)
MinBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
MinBtn.Text = "_"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.AutoButtonColor = false
MinBtn.Parent = TitleBar

local MinBtnCorner = Instance.new("UICorner")
MinBtnCorner.CornerRadius = UDim.new(0, 7)
MinBtnCorner.Parent = MinBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 28)
CloseBtn.Position = UDim2.new(1, -35, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 55, 55)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 7)
CloseBtnCorner.Parent = CloseBtn

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -30, 1, -60)
Content.Position = UDim2.new(0, 15, 0, 52)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local function createButton(text, position, callback, defaultColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.Position = position
    btn.BackgroundColor3 = defaultColor or Color3.fromRGB(60, 120, 210)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamSemibold
    btn.AutoButtonColor = false
    btn.Parent = Content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    local originalColor = defaultColor or Color3.fromRGB(60, 120, 210)
    
    btn.MouseEnter:Connect(function()
        local c = btn.BackgroundColor3
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(
                math.min(255, c.R * 255 * 1.15),
                math.min(255, c.G * 255 * 1.15),
                math.min(255, c.B * 255 * 1.15)
            )
        }):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        if not (btn.Text:find("Stop") or btn.Text:find("Active")) then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
        end
    end)
    
    btn.MouseButton1Click:Connect(callback)
    
    return btn, originalColor
end

local buyAllSeedsBtn, seedsOriginalColor
local buyAllGearsBtn, gearsOriginalColor

seedsOriginalColor = Color3.fromRGB(60, 120, 210)
buyAllSeedsBtn = createButton("Buy All Seeds", UDim2.new(0, 0, 0, 0), function()
    buyingSeedsActive = not buyingSeedsActive
    if buyingSeedsActive then
        buyAllSeedsBtn.Text = "Stop Buying Seeds"
        TweenService:Create(buyAllSeedsBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 55, 55)}):Play()
    else
        buyAllSeedsBtn.Text = "Buy All Seeds"
        TweenService:Create(buyAllSeedsBtn, TweenInfo.new(0.2), {BackgroundColor3 = seedsOriginalColor}):Play()
    end
end, seedsOriginalColor)

gearsOriginalColor = Color3.fromRGB(60, 120, 210)
buyAllGearsBtn = createButton("Buy All Gears", UDim2.new(0, 0, 0, 52), function()
    buyingGearsActive = not buyingGearsActive
    if buyingGearsActive then
        buyAllGearsBtn.Text = "Stop Buying Gears"
        TweenService:Create(buyAllGearsBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 55, 55)}):Play()
    else
        buyAllGearsBtn.Text = "Buy All Gears"
        TweenService:Create(buyAllGearsBtn, TweenInfo.new(0.2), {BackgroundColor3 = gearsOriginalColor}):Play()
    end
end, gearsOriginalColor)

local brainrotFrame = Instance.new("Frame")
brainrotFrame.Size = UDim2.new(1, 0, 0, 80)
brainrotFrame.Position = UDim2.new(0, 0, 0, 104)
brainrotFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
brainrotFrame.Parent = Content

local brainrotCorner = Instance.new("UICorner")
brainrotCorner.CornerRadius = UDim.new(0, 8)
brainrotCorner.Parent = brainrotFrame

local brainrotLabel = Instance.new("TextLabel")
brainrotLabel.Size = UDim2.new(1, -20, 0, 24)
brainrotLabel.Position = UDim2.new(0, 10, 0, 8)
brainrotLabel.BackgroundTransparency = 1
brainrotLabel.Text = "Equip Best Brainrot"
brainrotLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
brainrotLabel.TextSize = 13
brainrotLabel.Font = Enum.Font.GothamSemibold
brainrotLabel.TextXAlignment = Enum.TextXAlignment.Left
brainrotLabel.Parent = brainrotFrame

local intervalLabel = Instance.new("TextLabel")
intervalLabel.Size = UDim2.new(1, -20, 0, 18)
intervalLabel.Position = UDim2.new(0, 10, 0, 30)
intervalLabel.BackgroundTransparency = 1
intervalLabel.Text = "Interval (seconds):"
intervalLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
intervalLabel.TextSize = 11
intervalLabel.Font = Enum.Font.Gotham
intervalLabel.TextXAlignment = Enum.TextXAlignment.Left
intervalLabel.Parent = brainrotFrame

local brainrotInput = Instance.new("TextBox")
brainrotInput.Size = UDim2.new(0, 80, 0, 28)
brainrotInput.Position = UDim2.new(0, 10, 1, -36)
brainrotInput.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
brainrotInput.Text = "60"
brainrotInput.TextColor3 = Color3.fromRGB(255, 255, 255)
brainrotInput.TextSize = 13
brainrotInput.Font = Enum.Font.Gotham
brainrotInput.Parent = brainrotFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 7)
inputCorner.Parent = brainrotInput

brainrotInput.FocusLost:Connect(function()
    local num = tonumber(brainrotInput.Text)
    if num and num > 0 then
        brainrotInterval = num
    else
        brainrotInput.Text = tostring(brainrotInterval)
    end
end)

local brainrotBtn = Instance.new("TextButton")
brainrotBtn.Size = UDim2.new(0, 180, 0, 28)
brainrotBtn.Position = UDim2.new(1, -190, 1, -36)
brainrotBtn.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
brainrotBtn.Text = "Start"
brainrotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
brainrotBtn.TextSize = 13
brainrotBtn.Font = Enum.Font.GothamSemibold
brainrotBtn.AutoButtonColor = false
brainrotBtn.Parent = brainrotFrame

local brainrotBtnCorner = Instance.new("UICorner")
brainrotBtnCorner.CornerRadius = UDim.new(0, 7)
brainrotBtnCorner.Parent = brainrotBtn

brainrotBtn.MouseButton1Click:Connect(function()
    equipBrainrotActive = not equipBrainrotActive
    if equipBrainrotActive then
        brainrotBtn.Text = "Stop"
        TweenService:Create(brainrotBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 55, 55)}):Play()
    else
        brainrotBtn.Text = "Start"
        TweenService:Create(brainrotBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 150, 70)}):Play()
    end
end)

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 20)
infoLabel.Position = UDim2.new(0, 0, 1, -20)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Press Right Control to minimize"
infoLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
infoLabel.TextSize = 10
infoLabel.Font = Enum.Font.Gotham
infoLabel.Parent = Content

local function toggleMinimize()
    if MainFrame.Visible then
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 0, 0, 0)}):Play()
        wait(0.3)
        MainFrame.Visible = false
        MinButton.Visible = true
    else
        MainFrame.Visible = true
        MinButton.Visible = false
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 320, 0, 260)}):Play()
    end
end

MinBtn.MouseButton1Click:Connect(toggleMinimize)
MinButton.MouseButton1Click:Connect(toggleMinimize)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == TOGGLE_KEY then toggleMinimize() end
end)

local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local minDragging, minDragInput, minDragStart, minStartPos
MinButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        minDragging = true
        minDragStart = input.Position
        minStartPos = MinButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then minDragging = false end
        end)
    end
end)

MinButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then minDragInput = input end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == minDragInput and minDragging then
        local delta = input.Position - minDragStart
        MinButton.Position = UDim2.new(minStartPos.X.Scale, minStartPos.X.Offset + delta.X, minStartPos.Y.Scale, minStartPos.Y.Offset + delta.Y)
    end
end)

task.spawn(function()
    while true do
        if buyingSeedsActive then
            for _, seed in ipairs(seedList) do
                if not buyingSeedsActive then break end
                
                local buyDuration = math.random(30, 50) / 100 
                local startTime = tick()
                
                while (tick() - startTime) < buyDuration do
                    if not buyingSeedsActive then break end
                    task.spawn(function()
                        pcall(function()
                            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuyItem"):FireServer(seed, true)
                        end)
                    end)
                    task.wait(0.3) 
                end
                
                if buyingSeedsActive then
                    task.wait(0.5)
                end
            end
        else
            task.wait(0.1)
        end
    end
end)

task.spawn(function()
    while true do
        if buyingGearsActive then
            for _, gear in ipairs(gearList) do
                if not buyingGearsActive then break end
                
                
                local buyDuration = math.random(30, 50) / 100 
                local startTime = tick()
                
                while (tick() - startTime) < buyDuration do
                    if not buyingGearsActive then break end
                    task.spawn(function()
                        pcall(function()
                            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuyGear"):FireServer(gear, true)
                        end)
                    end)
                    task.wait(0.3) 
                end
                
                if buyingGearsActive then
                    task.wait(0.5)
                end
            end
        else
            task.wait(0.1)
        end
    end
end)

task.spawn(function()
    while true do
        if equipBrainrotActive then
            pcall(function()
                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EquipBestBrainrots"):FireServer()
            end)
            task.wait(brainrotInterval)
        else
            task.wait(1)
        end
    end
end)

print("Plant Vs Brainrot Loaded Successfully!")
