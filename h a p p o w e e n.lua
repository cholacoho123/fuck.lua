repeat
    task.wait()
until game:IsLoaded()

local Workspace = game:GetService('Workspace')
local Terrain = Workspace:WaitForChild('Terrain')
Terrain.WaterReflectance = 0
Terrain.WaterTransparency = 1
Terrain.WaterWaveSize = 0
Terrain.WaterWaveSpeed = 0

local Lighting = game:GetService('Lighting')
Lighting.Brightness = 0
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e100
Lighting.FogStart = 0

sethiddenproperty(Lighting, 'Technology', 2)
sethiddenproperty(Terrain, 'Decoration', false)

local function clearTextures(v)
    if v:IsA('BasePart') and not v:IsA('MeshPart') then
        v.Material = 'Plastic'
        v.Reflectance = 0
    elseif v:IsA('Decal') or v:IsA('Texture') then
        v.Transparency = 1
    elseif v:IsA('ParticleEmitter') or v:IsA('Trail') then
        v.Lifetime = NumberRange.new(0)
    elseif v:IsA('Explosion') then
        v.BlastPressure = 1
        v.BlastRadius = 1
    elseif
        v:IsA('Fire')
        or v:IsA('SpotLight')
        or v:IsA('Smoke')
        or v:IsA('Sparkles')
    then
        v.Enabled = false
    elseif v:IsA('MeshPart') then
        v.Material = 'Plastic'
        v.Reflectance = 0
        v.TextureID = 10385902758728957
    elseif v:IsA('SpecialMesh') then
        v.TextureId = 0
    elseif v:IsA('ShirtGraphic') then
        v.Graphic = 1
    elseif v:IsA('Shirt') or v:IsA('Pants') then
        v[v.ClassName .. 'Template'] = 1
    elseif v.Name == 'Foilage' and v:IsA('Folder') then
        v:Destroy()
    elseif
        string.find(v.Name, 'Tree')
        or string.find(v.Name, 'Water')
        or string.find(v.Name, 'Bush')
        or string.find(v.Name, 'grass')
    then
        task.wait()
        v:Destroy()
    end
end

game:GetService('Lighting'):ClearAllChildren()

for _, v in pairs(Workspace:GetDescendants()) do
    clearTextures(v)
end

Workspace.DescendantAdded:Connect(function(v)
    clearTextures(v)
end)

-- ===================== AUTO TELEPORT =====================
getgenv().AutoTeleportEnabled = true -- Bật / Tắt
local TARGET_PLACE_ID = 131952481663528
local CHECK_INTERVAL = 5 -- kiểm tra mỗi 5 giây

task.spawn(function()
    while true do
        task.wait(CHECK_INTERVAL)
        if
            getgenv().AutoTeleportEnabled
            and game.PlaceId ~= TARGET_PLACE_ID
        then
            pcall(function()
                game:GetService('TeleportService'):Teleport(
                    TARGET_PLACE_ID,
                    game:GetService('Players').LocalPlayer
                )
            end)
        end
    end
end)
--============= ANTI-AFK (Full Safe + Jump Simulation) =======================
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService('VirtualUser')
local VirtualInputManager = game:GetService('VirtualInputManager')

-- 🛡️ Chống AFK cơ bản bằng VirtualUser
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- 🧠 Hàm tạo khoảng thời gian ngẫu nhiên (±30 giây)
local function randomWait(base)
    local variation = math.random(-30, 30)
    return math.max(60, base + variation)
end

-- 🤸 Nhảy mô phỏng mỗi 5 phút ±30s
task.spawn(function()
    while task.wait(randomWait(300)) do
        VirtualUser:CaptureController()
        VirtualUser:SetKeyDown('0x20') -- phím Space
        task.wait(0.5)
        VirtualUser:SetKeyUp('0x20')
    end
end)

-- 💨 Mô phỏng nhấn Space thực bằng VirtualInputManager (song song)
function AFK()
    while task.wait(randomWait(300)) do
        VirtualInputManager:SendKeyEvent(true, 'Space', false, game)
        task.wait(0.5)
        VirtualInputManager:SendKeyEvent(false, 'Space', false, game)
        print('[Anti-AFK] Jumped using VirtualInputManager.')
    end
end

spawn(AFK)

-- 🧩 Tắt Idle Tracking gốc của game
pcall(function()
    game.ReplicatedStorage.Network['Idle Tracking: Stop Timer']:FireServer()
    local scripts = LocalPlayer.PlayerScripts.Scripts.Core
    scripts['Idle Tracking'].Enabled = false
    scripts['Server Closing'].Enabled = false
end)
local Players = game:GetService('Players')
local player = Players.LocalPlayer

-- ⚙️ Cấu hình: Bật/Tắt tính năng xoá player khác
local KEEP_ONLY_LOCALPLAYER = true

-- 🧍‍♂️ Hàm xoá tất cả player khác
local function removeOtherPlayers()
    if not KEEP_ONLY_LOCALPLAYER then
        return
    end
    for _, plr in ipairs(Players:GetChildren()) do
        if plr ~= player then
            pcall(function()
                plr:Destroy()
            end)
        end
    end
end

-- 🚫 Khi có player mới join -> xoá ngay và quét lại toàn bộ
Players.PlayerAdded:Connect(function(plr)
    if not KEEP_ONLY_LOCALPLAYER then
        return
    end
    if plr ~= player then
        pcall(function()
            plr:Destroy()
        end)
    end
    removeOtherPlayers()
end)

-- 🧹 Khi có player rời -> đảm bảo danh sách sạch
Players.PlayerRemoving:Connect(function(_)
    task.defer(removeOtherPlayers)
end)

-- ⏳ Vòng kiểm tra liên tục để đảm bảo không lọt player ẩn
task.spawn(function()
    while task.wait(3) do
        removeOtherPlayers()
    end
end)

-- Chạy lần đầu tiên
removeOtherPlayers()

-- 📝 Danh sách đường dẫn thủ công muốn xoá
local ManualPathsToDelete = {
    'workspace.GardenCoinShop',
    'workspace.Debris',
    'workspace.Interaction.UpdateItems.WitchesBrewEvent.PotionShelf',
    'workspace.Interaction.UpdateItems.WitchesBrewEvent.WitchesBrewLeaderboard',
    'workspace.Interaction.UpdateItems.WitchesBrewEvent.WitchesBrewPlate',
    'workspace.Interaction.UpdateItems.WitchesBrewEvent.Witch.Broom',
    'workspace.Interaction.UpdateItems.HalloweenMarketEvent.Casket',
    "workspace.Interaction.UpdateItems.HalloweenMarketEvent['Devious Pumpkin']",
    'workspace.Interaction.UpdateItems.HalloweenMarketEvent.HalloweenEloise',
    'workspace.Interaction.UpdateItems.HalloweenMarketEvent.HalloweenLights',
    'workspace.Interaction.UpdateItems.HalloweenMarketEvent.HalloweenPlate',
    'workspace.Interaction.UpdateItems.HalloweenMarketEvent.HalloweenSteven',
    'workspace.Interaction.UpdateItems.HalloweenMarketEvent.Model1',
    'workspace.Interaction.UpdateItems.HalloweenMarketEvent.Model2',
    'workspace.Interaction.UpdateItems.HalloweenMarketEvent.PumpkinLight',
    'workspace.Interaction.UpdateItems.HalloweenMarketEvent.CandyCornSpecialCurrencyUIOverlap',
    'workspace.HalloweenOuter',
    'workspace.FlyBorder',
    'workspace.BlockPartyOuter',
    'workspace.__THINGS.Orbs',
}

-- 🌟 Ẩn phần hiển thị của Part nhưng giữ nguyên Prompt + thư mục con
local function hidePartVisualButKeepContents(part)
    part.Transparency = 1
    part.CastShadow = false
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false

    for _, child in ipairs(part:GetChildren()) do
        if
            child:IsA('SpecialMesh')
            or child:IsA('Decal')
            or child:IsA('MeshPart')
            or child:IsA('UnionOperation')
        then
            child:Destroy()
        end
    end
end

-- 🧹 Xoá phần hiển thị folder nhưng giữ Prompt
local function clearFolderVisualButKeepPrompt(folder)
    for _, desc in ipairs(folder:GetDescendants()) do
        if desc:IsA('BasePart') then
            local prompt = desc:FindFirstChildWhichIsA('ProximityPrompt')
            if prompt then
                hidePartVisualButKeepContents(desc)
            else
                desc:Destroy()
            end
        elseif
            desc:IsA('MeshPart')
            or desc:IsA('UnionOperation')
            or desc:IsA('Decal')
        then
            desc:Destroy()
        end
    end
end
local Success, Err = pcall(function()
    local Rep = game:GetService('ReplicatedStorage')

    local NotifItem = require(Rep.Library.Client.NotificationCmds).Item
    local UIReward = require(Rep.Library.Client.UI.BuyMultiple)

    -- Vô hiệu hóa toàn bộ UI thông báo item / reward
    NotifItem.Bottom = function(...) end
    UIReward.Reward = function(...) end
end)

print(Success and '✅ UI Disabled!' or Err)

-- 🌳 Xoá cây & quả
local function clearPlantAndFruits(plant)
    clearFolderVisualButKeepPrompt(plant)
    local fruits = plant:FindFirstChild('Fruits')
    if fruits then
        for _, fruit in ipairs(fruits:GetChildren()) do
            clearFolderVisualButKeepPrompt(fruit)
        end
    end
end

-- 🧼 Xoá đường dẫn thủ công
local function deleteManualPaths()
    for _, path in ipairs(ManualPathsToDelete) do
        local success, target = pcall(function()
            return loadstring('return ' .. path)()
        end)
        if success and target then
            target:Destroy()
        end
    end
end

-- 🧹 Xoá plot người chơi khác
local function deleteOtherPlayerPlots()
    local plots = workspace:FindFirstChild('__THINGS')
        and workspace.__THINGS:FindFirstChild('Plots')
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            local sign = plot:FindFirstChild('Build')
                and plot.Build:FindFirstChild('Sign')
            local isMine = false
            if sign then
                for _, gui in ipairs(sign:GetDescendants()) do
                    if gui:IsA('TextLabel') and gui.Text:find(player.Name) then
                        isMine = true
                        break
                    end
                end
            end
            if not isMine then
                plot:Destroy()
            end
        end
    end
end

-- 🧼 Vòng lặp dọn map cũ liên tục
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            for _, obj in ipairs(game:GetService('Lighting'):GetChildren()) do
                obj:Destroy()
            end
            if workspace:FindFirstChild('Debris') then
                for _, obj in ipairs(workspace.Debris:GetChildren()) do
                    obj:Destroy()
                end
            end
            if workspace:FindFirstChild('Terrain') then
                workspace.Terrain:Clear()
            end
            deleteManualPaths()
            for _, farm in workspace:GetChildren() do
                if farm.Name == 'Farm' then
                    for _, subFarm in ipairs(farm:GetChildren()) do
                        if
                            subFarm.Name == 'Farm'
                            and subFarm:FindFirstChild('Important')
                            and subFarm.Important:FindFirstChild('Data')
                            and subFarm.Important.Data:FindFirstChild('Owner')
                        then
                            local isMine = (
                                subFarm.Important.Data.Owner.Value
                                == player.Name
                            )
                            if not isMine then
                                subFarm:Destroy()
                            else
                                local important = subFarm.Important
                                if
                                    important:FindFirstChild('Plants_Physical')
                                then
                                    for _, plant in
                                        ipairs(
                                            important.Plants_Physical:GetChildren()
                                        )
                                    do
                                        clearPlantAndFruits(plant)
                                    end
                                end
                                for _, folderName in ipairs({
                                    'Decorations',
                                    'Fences',
                                    'Cosmetics',
                                }) do
                                    if important:FindFirstChild(folderName) then
                                        for _, obj in
                                            ipairs(
                                                important[folderName]:GetChildren()
                                            )
                                        do
                                            obj:Destroy()
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            deleteOtherPlayerPlots()
            removeOtherPlayers()
        end)
    end
end)
-- HalloweenDashboard Neon Cyberpunk UI
-- Full integrated UI (auto-scale, neon glow, hover, and original logic preserved)

local Rep = game:GetService('ReplicatedStorage')
local Network = require(Rep.Library.Client.Network)
local Directory = require(Rep.Library.Directory)
local Types = require(Rep.Library.Items.Types)
local Save = require(Rep.Library.Client.Save)
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService('TweenService')

-- ================ Camera / Resolution ================
local camera = workspace.CurrentCamera
local function GetResolution()
    local size = camera.ViewportSize
    return math.floor(size.X), math.floor(size.Y)
end
local width, height = GetResolution()

-- ================ UI ROOT ================
local gui = Instance.new('ScreenGui')
gui.Name = 'HalloweenDashboard'
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999

-- parent only after PlayerGui exists
gui.Parent = LocalPlayer:WaitForChild('PlayerGui')

local overlay = Instance.new('Frame', gui)
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.6
overlay.BorderSizePixel = 0
overlay.ZIndex = 900

-- Toggle button (neon style)
local toggleButton = Instance.new('TextButton', gui)
local function CalcToggleSize()
    return UDim2.new(
        0,
        math.max(40, math.floor(width * 0.035)),
        0,
        math.max(40, math.floor(height * 0.06))
    )
end
toggleButton.Size = CalcToggleSize()
toggleButton.Position = UDim2.new(0, 10, 0.5, -25)
toggleButton.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
toggleButton.Text = '🎃'
toggleButton.TextColor3 = Color3.fromRGB(200, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 22
toggleButton.ZIndex = 1001

local toggleCorner = Instance.new('UICorner', toggleButton)
toggleCorner.CornerRadius = UDim.new(0, 10)
local toggleStroke = Instance.new('UIStroke', toggleButton)
toggleStroke.Thickness = 2
toggleStroke.Color = Color3.fromRGB(0, 225, 255)

-- Hover effect for toggle
toggleButton.MouseEnter:Connect(function()
    TweenService:Create(
        toggleButton,
        TweenInfo.new(0.18, Enum.EasingStyle.Quad),
        { BackgroundColor3 = Color3.fromRGB(255, 0, 255) }
    ):Play()
    TweenService:Create(
        toggleButton,
        TweenInfo.new(0.18, Enum.EasingStyle.Quad),
        { TextSize = 26 }
    ):Play()
end)
toggleButton.MouseLeave:Connect(function()
    TweenService:Create(
        toggleButton,
        TweenInfo.new(0.25, Enum.EasingStyle.Quad),
        { BackgroundColor3 = Color3.fromRGB(12, 12, 16) }
    ):Play()
    TweenService:Create(
        toggleButton,
        TweenInfo.new(0.25, Enum.EasingStyle.Quad),
        { TextSize = 22 }
    ):Play()
end)

-- Overlay visibility toggle
toggleButton.MouseButton1Click:Connect(function()
    overlay.Visible = not overlay.Visible
end)

-- ================ Main Panel (Auto-scale) ================
local main = Instance.new('Frame', overlay)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.Size = UDim2.new(1, 0, 1, 0)
main.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
main.BackgroundTransparency = 0
main.BorderSizePixel = 0
main.ZIndex = 1000

-- Neon corner + stroke + gradient
local mainCorner = Instance.new('UICorner', main)
mainCorner.CornerRadius = UDim.new(0, 12)

local mainStroke = Instance.new('UIStroke', main)
mainStroke.Thickness = 2
mainStroke.Color = Color3.fromRGB(0, 225, 255)
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local strokeGradient = Instance.new('UIGradient', mainStroke)
strokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255)),
})
strokeGradient.Rotation = 45

local bgGradient = Instance.new('UIGradient', main)
bgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 0, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 20)),
})
bgGradient.Rotation = 45

-- Glow image behind panel (soft aura)
local glow = Instance.new('ImageLabel', main)
glow.Size = UDim2.new(1.25, 0, 1.25, 0)
glow.Position = UDim2.new(0.5, 0, 0.5, 0)
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.BackgroundTransparency = 1
glow.Image = 'rbxassetid://4996891970' -- soft glow image
glow.ImageColor3 = Color3.fromRGB(0, 170, 255)
glow.ImageTransparency = 0.78
glow.ZIndex = 995

-- Title
local title = Instance.new('TextLabel', main)
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 6)
title.BackgroundTransparency = 1
title.Text = '🎃 SUCACHEO HUB 🎃'
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(200, 255, 255)
title.TextSize = 20
title.ZIndex = 1001
title.TextStrokeTransparency = 0.5
title.TextStrokeColor3 = Color3.fromRGB(0, 225, 255)

-- Uptime label
local uptimeLabel = Instance.new('TextLabel', main)
uptimeLabel.Size = UDim2.new(1, 0, 0, 28)
uptimeLabel.Position = UDim2.new(0, 12, 0, 60)
uptimeLabel.BackgroundTransparency = 1
uptimeLabel.Font = Enum.Font.Gotham
uptimeLabel.TextSize = 18
uptimeLabel.TextColor3 = Color3.fromRGB(200, 255, 255)
uptimeLabel.Text = '⏱️ Uptime: 00:00:00'
uptimeLabel.ZIndex = 1001
uptimeLabel.TextStrokeTransparency = 0.6

-- Scrolling frame (original layout preserved)
local scroll = Instance.new('ScrollingFrame', main)
scroll.Size = UDim2.new(1, -20, 1, -90)
scroll.Position = UDim2.new(0, 10, 0, 90)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 10)
scroll.ZIndex = 1001

local uiListLayout = Instance.new('UIListLayout', scroll)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 6)

-- Labels container
local labels = { currencies = {}, upgrades = {}, crafting = {} }

-- ================ Utility functions (formatting & data) ================
local function formatNumber(n)
    if not n then
        return '0'
    end
    if n >= 1e9 then
        return string.format('%.2fB', n / 1e9)
    elseif n >= 1e6 then
        return string.format('%.2fM', n / 1e6)
    elseif n >= 1e3 then
        return string.format('%.1fK', n / 1e3)
    else
        return tostring(math.floor(n))
    end
end

local function getData()
    return Save.Get() or {}
end

local function getCurrencies()
    local cur = (getData().Inventory and getData().Inventory.Currency) or {}
    local result = {}
    for _, info in pairs(cur) do
        result[info.id] = info._am or 0
    end
    return result
end

-- ================ Build default UI items (Currencies / Upgrades / Crafting) ================
local currencyList = { 'Diamonds', 'HalloweenCoins', 'Diamonds/M' }

-- Header factory
local function MakeHeader(text)
    local h = Instance.new('TextLabel')
    h.Size = UDim2.new(1, 0, 0, 28)
    h.BackgroundTransparency = 1
    h.Font = Enum.Font.GothamBold
    h.TextSize = 15
    h.Text = text
    h.TextColor3 = Color3.fromRGB(0, 225, 255)
    h.TextStrokeTransparency = 0.6
    h.TextStrokeColor3 = Color3.fromRGB(0, 120, 255)
    h.ZIndex = 1002
    h.Parent = scroll
    return h
end

MakeHeader('💰 [CURRENCY]')

for _, name in ipairs(currencyList) do
    local lbl = Instance.new('TextLabel')
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = '• ' .. name .. ' = 0'
    lbl.TextColor3 = Color3.fromRGB(200, 255, 255)
    lbl.TextStrokeTransparency = 0.7
    lbl.ZIndex = 1002
    lbl.Parent = scroll
    labels.currencies[name] = lbl
end

MakeHeader('⚙️ [UPGRADES]')

local AllUpgrades = {
    'HalloweenCandyMultiplier',
    'HalloweenTrickOrTreatLuck',
    'HalloweenHugeLuck',
    'HalloweenTitanicLuck',
    'HalloweenMoreDiamonds',
    'HalloweenMoreWitchHats',
    'HalloweenEggLuck',
}

for _, name in ipairs(AllUpgrades) do
    local lbl = Instance.new('TextLabel')
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = '• ' .. name .. ' = 0/10'
    lbl.TextColor3 = Color3.fromRGB(200, 255, 255)
    lbl.TextStrokeTransparency = 0.7
    lbl.ZIndex = 1002
    lbl.Parent = scroll
    labels.upgrades[name] = lbl
end

MakeHeader('🎃 [CRAFTING QUEUE]')

local craftLabels = {}

local function updateCraftingUI()
    local allQueue = {}
    -- Lấy thông tin hàng đợi chế tạo từ các máy chế tạo
    for machineId, machineData in pairs(Directory.HalloweenCraftingMachines) do
        local recipes = Network.Invoke(
            'HalloweenCraftingMachine_GetCurrentRecipes',
            machineId
        ) or {}
        local queue = Network.Invoke('HalloweenCraftingMachine_GetQueue') or {}

        for i, recipeData in ipairs(recipes) do
            local recipe = table.clone(recipeData)
            if recipe.Result and recipe.Result.class and recipe.Result.data then
                recipe.Result =
                    Types.From(recipe.Result.class, recipe.Result.data)
            end

            local queuedEntry
            for _, q in ipairs(queue) do
                if q.RecipeIndex == i then
                    queuedEntry = q
                    break
                end
            end

            if queuedEntry and queuedEntry.Remaining > 0 then
                table.insert(
                    allQueue,
                    { Recipe = recipe, Remaining = queuedEntry.Remaining }
                )
            end
        end
    end

    -- Clear old craft labels ordering (we reuse labels table)
    local yCount = 0
    for _, entry in ipairs(allQueue) do
        local recipe = entry.Recipe
        local remaining = entry.Remaining
        if recipe and recipe.Result then
            local itemName = recipe.Result.GetName and recipe.Result:GetName()
                or tostring(recipe.Result)
            local lbl = craftLabels[itemName]

            if not lbl then
                lbl = Instance.new('TextLabel')
                lbl.Size = UDim2.new(1, 0, 0, 24)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 15
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextColor3 = Color3.fromRGB(200, 255, 255)
                lbl.TextStrokeTransparency = 0.7
                lbl.ZIndex = 1002
                lbl.Parent = scroll
                craftLabels[itemName] = lbl
            end

            lbl.Text = '• '
                .. itemName
                .. ' ⏳ Crafting ('
                .. string.format('%.1f', remaining)
                .. 's)'
            yCount = yCount + 1
        end
    end

    -- Update canvas size (UIListLayout handles spacing) but ensure enough space
    local contentSize = uiListLayout.AbsoluteContentSize.Y + 20
    scroll.CanvasSize = UDim2.new(0, 0, 0, contentSize)
end

-- ================ UPDATE UI (DPM, currencies, upgrades, uptime) ================
local startTime = os.clock()
local lastDiamonds = getCurrencies()['Diamonds'] or 0
local dpm = 0
local lastDPMTime = os.clock()

local function updateUI()
    local currencies = getCurrencies()
    local now = os.clock()
    local currentDiamonds = currencies['Diamonds'] or 0

    if now - lastDPMTime >= 60 then
        dpm = currentDiamonds - lastDiamonds
        lastDiamonds = currentDiamonds
        lastDPMTime = now
    end

    for _, name in ipairs(currencyList) do
        local lbl = labels.currencies[name]
        if lbl then
            if name == 'Diamonds/M' then
                lbl.Text =
                    string.format('• %-15s = %s', name, formatNumber(dpm))
            else
                lbl.Text = string.format(
                    '• %-15s = %s',
                    name,
                    formatNumber(currencies[name] or 0)
                )
            end
        end
    end

    -- Upgrades
    local up = getData().EventUpgrades or {}
    for _, name in ipairs(AllUpgrades) do
        local lvl = up[name] or 0
        local lbl = labels.upgrades[name]
        if lbl then
            lbl.Text = string.format('• %-25s = %d/10', name, lvl)
            lbl.TextColor3 = (lvl >= 10) and Color3.fromRGB(0, 255, 128)
                or Color3.fromRGB(200, 255, 255)
        end
    end

    -- Uptime
    local elapsed = os.clock() - startTime
    uptimeLabel.Text = '⏱️ Uptime: '
        .. string.format(
            '%02d:%02d:%02d',
            math.floor(elapsed / 3600),
            math.floor((elapsed % 3600) / 60),
            math.floor(elapsed % 60)
        )

    -- Crafting
    updateCraftingUI()
end

-- ================ Loop updater ================
task.spawn(function()
    while task.wait(2) do
        pcall(updateUI)
    end
end)

updateUI()

-- ================ Auto-resize handler ================
camera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
    width, height = GetResolution()
    main.Size =
        UDim2.new(0, math.floor(width * 0.90), 0, math.floor(height * 0.90))
    toggleButton.Size = CalcToggleSize()
end)

-- ================ Auto-resize handler ================
camera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
    width, height = GetResolution()
    main.Size =
        UDim2.new(0, math.floor(width * 0.90), 0, math.floor(height * 0.90))
    toggleButton.Size = CalcToggleSize()
end)
-- ================== SETTINGS ==================
local HOUSE_DELAYS =
    { [1] = 0.2, [2] = 0.2, [3] = 1, [4] = 60, [5] = 120, [6] = 180 }
local SIGN_RECHECK_INTERVAL = 10
local EGG_DELAY = 0.5
local MAX_EGG_SLOT = 6
local RANDOM_HOP_DELAY = 60
local MIN_HOP_COOLDOWN = 10
local FAIL_LIMIT = 60

-- ================== SERVICES ==================
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local HttpService = game:GetService('HttpService')
local TeleportService = game:GetService('TeleportService')
local LocalPlayer = Players.LocalPlayer
local PLOTS = workspace:WaitForChild('__THINGS'):WaitForChild('Plots')
local Plots_Invoke = ReplicatedStorage:WaitForChild('Network')
    :WaitForChild('Plots_Invoke')

-- ================== SERVER HOP ==================
local hoppedServers = {}
local badServers = {}
local lastHopTime = 0

local function safeWaitCooldown()
    local elapsed = os.clock() - lastHopTime
    if elapsed < MIN_HOP_COOLDOWN then
        task.wait(MIN_HOP_COOLDOWN - elapsed)
    end
end

local function hopRandomServer()
    safeWaitCooldown()
    local servers
    local ok = pcall(function()
        servers = HttpService:JSONDecode(
            game:HttpGet(
                'https://games.roblox.com/v1/games/'
                    .. tostring(game.PlaceId)
                    .. '/servers/Public?sortOrder=Asc&limit=100'
            )
        ).data
    end)
    if not ok or not servers or #servers == 0 then
        warn(
            '⚠️ Không lấy được server, teleport lại chính server'
        )
        task.wait(RANDOM_HOP_DELAY)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
        lastHopTime = os.clock()
        return
    end

    local candidates = {}
    for _, s in ipairs(servers) do
        if
            s.id ~= game.JobId
            and not hoppedServers[s.id]
            and not badServers[s.id]
        then
            table.insert(candidates, s.id)
        end
    end

    if #candidates == 0 then
        warn(
            '⚠️ Không còn server hợp lệ, reset danh sách đã hop...'
        )
        hoppedServers = {}
        for _, s in ipairs(servers) do
            if s.id ~= game.JobId and not badServers[s.id] then
                table.insert(candidates, s.id)
            end
        end
        if #candidates == 0 then
            warn(
                '⚠️ Không còn server nào hợp lệ để hop → đợi ngẫu nhiên'
            )
            task.wait(RANDOM_HOP_DELAY)
            return hopRandomServer()
        end
    end

    local nextServer = candidates[math.random(#candidates)]
    print(
        '⏱ Đang chờ '
            .. RANDOM_HOP_DELAY
            .. ' giây trước khi hop server: '
            .. nextServer
    )
    task.wait(RANDOM_HOP_DELAY)

    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(
            game.PlaceId,
            nextServer,
            LocalPlayer
        )
    end)

    lastHopTime = os.clock()
    if ok then
        print('🎲 Hop server thành công: ' .. nextServer)
        hoppedServers[nextServer] = true
    else
        warn('⚠️ Không vào được server: ' .. nextServer)
        hoppedServers[nextServer] = true
        task.wait(MIN_HOP_COOLDOWN)
        hopRandomServer()
    end
end

local function hopServer(reason)
    print(
        '🚫 Server lỗi ('
            .. tostring(reason)
            .. ') → Hop RANDOM server...'
    )
    hopRandomServer()
end

-- ================== DPS LOGIC ==================
local function checkThreshold(thresholds, amountPerSec)
    for _, t in ipairs(thresholds) do
        t = t:gsub(' ', '')
        if t:match('^>') then
            local val = tonumber(t:match('^>(%d+)'))
            if amountPerSec > val then
                return true
            end
        elseif t:match('^<') then
            local val = tonumber(t:match('^<(%d+)'))
            if amountPerSec < val then
                return true
            end
        elseif t:match('~') then
            local minVal, maxVal = t:match('(%d+)~(%d+)')
            minVal, maxVal = tonumber(minVal), tonumber(maxVal)
            if amountPerSec >= minVal and amountPerSec <= maxVal then
                return true
            end
        end
    end
    return false
end

local function decideHousesByDPS(amountPerSec)
    local housesToUnlock = {}
    local eggQtyPerSlot = {}
    for h = 1, MAX_EGG_SLOT do
        local key = 'HOUSE' .. h
        local thresholds = getgenv().Config.DPS_THRESHOLDS[key]
        if thresholds and checkThreshold(thresholds, amountPerSec) then
            housesToUnlock[h] = true
            eggQtyPerSlot[h] = h <= 2 and 3 or 1
        end
    end
    local finalHouses, finalEggQty = {}, {}
    for h = 1, MAX_EGG_SLOT do
        if housesToUnlock[h] then
            table.insert(finalHouses, h)
        end
        finalEggQty[h] = eggQtyPerSlot[h] or 0
    end
    return finalHouses, finalEggQty
end

-- ================== FIND PLOT ==================
local function findMyPlotAndAmount()
    for _, plot in pairs(PLOTS:GetChildren()) do
        local sign = plot:FindFirstChild('Build')
            and plot.Build:FindFirstChild('Sign')
        if sign then
            for _, gui in pairs(sign:GetDescendants()) do
                if gui:IsA('TextLabel') and gui.Text:find(LocalPlayer.Name) then
                    -- trả 40000 test DPS >30000 để House6 mở luôn
                    return plot, 40000
                end
            end
        end
    end
    return nil, 0
end

-- ================== HOUSE UNLOCK ==================
local function unlockHouseIfNeeded(plotId, houseNumber, amountPerSec)
    local thresholds = getgenv().Config.DPS_THRESHOLDS['HOUSE' .. houseNumber]
    if thresholds and checkThreshold(thresholds, amountPerSec) then
        local success, _ = pcall(function()
            Plots_Invoke:InvokeServer(plotId, 'PurchaseHouse', houseNumber)
        end)
        if success then
            print('[✅ HOUSE ' .. houseNumber .. ']: Mở thành công')
            return true
        else
            warn('[❌ HOUSE ' .. houseNumber .. ']: Mở thất bại')
            return false
        end
    end
    return false
end

-- ================== EGG HANDLER ==================
local lastPurchaseTimes = {}
local consecutiveFail = { [1] = 0, [2] = 0 }
local activeThreads = {}

local function purchaseEgg(plotId, slot, qty)
    qty = qty or 1
    local success, _ = pcall(function()
        return Plots_Invoke:InvokeServer(plotId, 'PurchaseEgg', slot, qty)
    end)
    lastPurchaseTimes[slot] = os.clock()

    if slot == 1 or slot == 2 then
        if success then
            consecutiveFail[1] = 0
            consecutiveFail[2] = 0
            print('[✅ HOUSE ' .. slot .. ']: Mua egg thành công')
        else
            consecutiveFail[slot] = consecutiveFail[slot] + 1
            print(
                '[❌ HOUSE '
                    .. slot
                    .. ' ERROR #'
                    .. consecutiveFail[slot]
                    .. ']'
            )
            if
                consecutiveFail[1] >= FAIL_LIMIT
                and consecutiveFail[2] >= FAIL_LIMIT
            then
                badServers[game.JobId] = true
                hopServer('House1&2 fail limit')
                consecutiveFail[1] = 0
                consecutiveFail[2] = 0
            end
        end
    end
end

local function startEggThread(plotId, slot, delay, qty)
    qty = qty or 1
    local ctrl = { stopFlag = false }
    activeThreads[slot] = ctrl
    task.spawn(function()
        while not ctrl.stopFlag do
            purchaseEgg(plotId, slot, qty)
            local t = 0
            while t < delay and not ctrl.stopFlag do
                task.wait(1)
                t = t + 1
            end
        end
    end)
end

local function stopAllThreads()
    for _, ctrl in pairs(activeThreads) do
        ctrl.stopFlag = true
    end
    task.wait(0.05)
    activeThreads = {}
end

-- ================== MAIN LOOP ==================
local lastPlotId, lastHouses = nil, {}
task.spawn(function()
    while true do
        local plot, amount = findMyPlotAndAmount()
        if plot then
            local plotId = tonumber(plot:GetAttribute('ID'))
                or tonumber(plot.Name)
                or 1
            local housesToUnlock, eggQtyPerSlot = decideHousesByDPS(amount)
            local housesJson = HttpService:JSONEncode(housesToUnlock)
            local lastHousesJson = HttpService:JSONEncode(lastHouses)
            if plotId ~= lastPlotId or housesJson ~= lastHousesJson then
                print(
                    '🔁 Cập nhật thread, DPS thay đổi hoặc plot khác'
                )
                stopAllThreads()
                for _, h in ipairs(housesToUnlock) do
                    -- mở house trực tiếp trước khi mua egg
                    unlockHouseIfNeeded(plotId, h, amount)
                    -- start thread mua egg
                    local qty = eggQtyPerSlot[h] or 0
                    if qty > 0 then
                        local delay = HOUSE_DELAYS[h] or EGG_DELAY
                        startEggThread(plotId, h, delay, qty)
                    end
                end
                lastPlotId, lastHouses = plotId, housesToUnlock
            end
        end
        task.wait(SIGN_RECHECK_INTERVAL)
    end
end)

--============= UTILS ==================
local LOG = { verbose = false }
local function log(...)
    if LOG.verbose then
        print(...)
    end
end
local function warnlog(...)
    warn(...)
end

local function SafeInvoke(obj, method, ...)
    local args = { ... }
    for attempt = 1, 5 do
        local ok, result = pcall(function()
            return obj[method](obj, table.unpack(args))
        end)
        if ok then
            return true, result
        end
        task.wait(math.min(0.25 * (2 ^ (attempt - 1)), 2))
    end
    return false, nil
end

local function RF(obj, ...)
    return SafeInvoke(obj, 'InvokeServer', ...)
end
local function EV(obj, ...)
    return SafeInvoke(obj, 'FireServer', ...)
end
--============= UTILS ==================
local LOG = { verbose = false }
local function log(...)
    if LOG.verbose then
        print(...)
    end
end
local function warnlog(...)
    warn(...)
end

local function SafeInvoke(obj, method, ...)
    local args = { ... }
    for attempt = 1, 5 do
        local ok, result = pcall(function()
            return obj[method](obj, table.unpack(args))
        end)
        if ok then
            return true, result
        end
        task.wait(math.min(0.25 * (2 ^ (attempt - 1)), 2))
    end
    return false, nil
end

local function RF(obj, ...)
    return SafeInvoke(obj, 'InvokeServer', ...)
end
local function EV(obj, ...)
    return SafeInvoke(obj, 'FireServer', ...)
end

--============= SERVICES & PLAYER ==================
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local Rep = game:GetService('ReplicatedStorage')
local Network = Rep:WaitForChild('Network')
local Save = require(Rep.Library.Client.Save)
local HPillarItems = require(Rep.Library.Directory.HPillarItems)

--============= SETTINGS ==================
local UPDATE_INTERVAL = 2.5
local PET_SLOTS = getgenv().Config.plant.PET_SLOTS
local EGG_SLOTS = getgenv().Config.plant.EGG_SLOTS

--============= FUNCTIONS ==================
local function parseRate(text)
    if not text then
        return 0
    end
    text = text:gsub(',', ''):lower()
    local num, suffix = text:match('([%d%.]+)%s*([kmbtq]*)')
    num = tonumber(num)
    if not num then
        return 0
    end
    local mult = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, q = 1e15 }
    return num * (mult[suffix] or 1)
end

local function getCandyMultiplier()
    local upgrades = (Save.Get().EventUpgrades or {})
    local level = upgrades.HalloweenCandyMultiplier or 0
    return 1 + 0.1 * level
end
local CandyMultiplier = getCandyMultiplier()

local function getInventoryPets()
    local data = Save.Get()
    local inv = data and data.Inventory and data.Inventory.HPillar
    local pets, mapByUid = {}, {}
    if inv then
        for uid, info in pairs(inv) do
            local id = info.id
            local base = HPillarItems[id]
            if base then
                local perSec = base.BaseMoneyPerSecond or 0
                local tier = info.pt or 0
                local shiny = info.sh or (info._uq and info._uq.sh)
                local tierMultiplier = { [0] = 1, [1] = 2, [2] = 4, [3] = 6 }
                local shinyMultiplier, sunnyShinyMultiplier = 2, 8
                perSec = perSec * (tierMultiplier[tier] or 1)
                if tier == 3 and shiny then
                    perSec = perSec * sunnyShinyMultiplier / tierMultiplier[3]
                elseif shiny then
                    perSec = perSec * shinyMultiplier
                end
                perSec = perSec * CandyMultiplier
                local entry = {
                    uid = uid,
                    id = id,
                    name = base.DisplayName or id,
                    power = perSec,
                    amount = info._am or 1,
                    tier = tier,
                    shiny = shiny,
                }
                table.insert(pets, entry)
                mapByUid[uid] = entry
            end
        end
    end
    table.sort(pets, function(a, b)
        return a.power > b.power
    end)
    return pets, mapByUid
end

local function getPlayerPlot()
    for _, plot in pairs(workspace.__THINGS.Plots:GetChildren()) do
        local sign = plot:FindFirstChild('Build')
            and plot.Build:FindFirstChild('Sign')
        if sign then
            for _, gui in pairs(sign:GetDescendants()) do
                if gui:IsA('TextLabel') and gui.Text:find(LocalPlayer.Name) then
                    return plot
                end
            end
        end
    end
    return nil
end

local function getPlacedPets(plot)
    local placed = {}
    local pillars =
        plot:WaitForChild('Interactable'):WaitForChild('Pillars'):GetChildren()
    for i, pillar in ipairs(pillars) do
        local base = pillar:FindFirstChild('Base')
        if base then
            local foundModel
            for _, model in pairs(workspace.__DEBRIS:GetChildren()) do
                local part = model:FindFirstChildWhichIsA('BasePart', true)
                if part and (part.Position - base.Position).Magnitude < 3 then
                    foundModel = model
                    break
                end
            end
            if foundModel then
                local uid = foundModel.Name
                local rate
                local petModel = foundModel:FindFirstChild('HalloweenPet')
                    or foundModel
                for _, obj in pairs(petModel:GetDescendants()) do
                    if
                        obj:IsA('TextLabel')
                        and (
                            obj.Text:find('/s')
                            or obj.Name:lower():find('rate')
                        )
                    then
                        rate = parseRate(
                            obj.Text:match('([%d%a%.]+)%s*/%s*s') or obj.Text
                        )
                        break
                    end
                end
                table.insert(
                    placed,
                    { slot = i, model = foundModel, uid = uid, power = rate }
                )
            end
        end
    end
    return placed
end

local function findWeakestPlaced(placed, invMap)
    local weakest, minPower = nil, math.huge
    for _, p in ipairs(placed) do
        local invEntry = invMap[p.uid]
        local power = invEntry and invEntry.power or p.power or 0
        if power < minPower then
            minPower = power
            weakest = { slot = p.slot, uid = p.uid, power = power }
        end
    end
    return weakest, minPower
end

--============= AUTO EGG & PET ==================
local function handleHatchedEggs(plot)
    local placed = getPlacedPets(plot)
    for _, p in ipairs(placed) do
        for _, eggSlot in ipairs(EGG_SLOTS) do
            if p.slot == eggSlot then
                local hasEggText = false
                for _, obj in pairs(p.model:GetDescendants()) do
                    if
                        obj:IsA('TextLabel') and obj.Text:lower():find('egg')
                    then
                        hasEggText = true
                        break
                    end
                end
                if not hasEggText then
                    RF(Network.HalloweenWorld_PickUp, eggSlot)
                    task.wait()
                end
            end
        end
    end
end

local EGG_PRIORITY = {
    Mythical = { 'Coffin Egg' },
    Legendary = { 'Reaper Egg', 'Spider Egg' },
    Rare = { 'Bat Egg', 'Grave Egg' },
    Epic = { 'Ghost Egg', 'Cauldron Egg' },
    Basic = { 'Pumpkin Egg' },
}
local EGG_ORDER = { 'Mythical', 'Legendary', 'Rare', 'Epic', 'Basic' }

local function autoPlaceEggs()
    local data = Save.Get()
    local invEggs = data and data.Inventory and data.Inventory.EggHalloween
    if not invEggs then
        return
    end
    local eggs = {}
    for _, eggInfo in pairs(invEggs) do
        eggs[eggInfo.id] = eggInfo._am or 1
    end
    if next(eggs) == nil then
        return
    end
    local plot = getPlayerPlot()
    if not plot then
        return
    end
    local placed = getPlacedPets(plot)
    local occupied = {}
    for _, p in ipairs(placed) do
        occupied[p.slot] = true
    end
    for _, slot in ipairs(EGG_SLOTS) do
        if not occupied[slot] then
            local pick
            for _, rarity in ipairs(EGG_ORDER) do
                for _, eid in ipairs(EGG_PRIORITY[rarity] or {}) do
                    if eggs[eid] and eggs[eid] > 0 then
                        pick = eid
                        eggs[eid] -= 1
                        break
                    end
                end
                if pick then
                    break
                end
            end
            if pick then
                RF(Network.HalloweenWorld_PlaceEgg, slot, pick)
                task.wait(0.1)
            end
        end
    end
end

local function autoEquipPets()
    local plot = getPlayerPlot()
    if not plot then
        return
    end
    local invPets, invMap = getInventoryPets()
    local placed = getPlacedPets(plot)
    local placedBySlot = {}
    for _, p in ipairs(placed) do
        placedBySlot[p.slot] = p
    end
    for _, slot in ipairs(PET_SLOTS) do
        if not placedBySlot[slot] then
            local best = invPets[1]
            if best then
                RF(Network.HalloweenWorld_PlacePet, slot, best.uid)
                task.wait()
                return
            end
        end
    end
    local weakest, weakPower = findWeakestPlaced(placed, invMap)
    local best = invPets[1]
    if weakest and best and best.power > weakPower then
        RF(Network.HalloweenWorld_PickUp, weakest.slot)
        task.wait(0.5)
        RF(Network.HalloweenWorld_PlacePet, weakest.slot, best.uid)
        task.wait()
    end
end

--============= MAIN LOOPS ==================
task.spawn(function()
    while task.wait(UPDATE_INTERVAL) do
        local ok, err = pcall(function()
            local plot = getPlayerPlot()
            if not plot then
                return
            end
            handleHatchedEggs(plot)
            autoPlaceEggs()
            autoEquipPets()
        end)
        if not ok and LOG.verbose then
            warnlog('Loop error:', err)
        end
    end
end)

task.spawn(function()
    while task.wait(5) do
        for i = 1, 10 do
            task.spawn(function()
                RF(Network.HalloweenWorld_Claim, i)
            end)
        end
    end
end)

--==================--
--      SCRIPT      --
--==================--
local HttpService = game:GetService('HttpService')
local player = game.Players.LocalPlayer
local DATA_FILE = player.Name .. '_SEND.json'

repeat
    task.wait()
until game:IsLoaded()

local Config = getgenv().Config
local Network = require(game.ReplicatedStorage.Library.Client.Network)
local Save = require(game.ReplicatedStorage.Library.Client.Save)

----------------------------------------------------------
-- 📄 Load/Save trạng thái gửi
----------------------------------------------------------
local function loadStatus()
    if isfile(DATA_FILE) then
        return HttpService:JSONDecode(readfile(DATA_FILE))
    else
        return { SENT_PET = {}, SENT_DIAMONDS = {}, SENT_ITEM = {} }
    end
end

local function saveStatus(status)
    writefile(DATA_FILE, HttpService:JSONEncode(status))
end

local status = loadStatus()

----------------------------------------------------------
-- 📝 Hàm kiểm tra player có bị chặn không
----------------------------------------------------------
local function isPlayerBlocked(list)
    for _, name in ipairs(list) do
        if name == player.Name then
            return true
        end
    end
    return false
end

----------------------------------------------------------
-- 📝 Lấy người tiếp theo chưa gửi
----------------------------------------------------------
local function getNextUser(usernames, sentList)
    for _, u in ipairs(usernames) do
        if not table.find(sentList, u) then
            return u
        end
    end
    return nil
end

----------------------------------------------------------
-- 🎁 AUTO SEND PET
----------------------------------------------------------
task.spawn(function()
    if isPlayerBlocked(Config.SEND_PET.Usernames) then
        print('⚠️ Player nằm trong danh sách không gửi PET')
        return
    end

    while task.wait(Config.SEND_PET.PetSendInterval or 60) do
        local saveInv = Save.Get()
        local inv = saveInv and saveInv.Inventory and saveInv.Inventory.Pet
        if not inv then
            continue
        end

        local TitanicPetList = {}
        for UID, Data in pairs(inv) do
            if Data.id and string.find(Data.id, 'Huge') then
                table.insert(TitanicPetList, { UID = UID, data = Data })
            end
        end

        if #TitanicPetList == 0 then
            print('✅ Không còn Titanic/Huge pet để gửi.')
            break
        end

        local toUser = getNextUser(Config.SEND_PET.Usernames, status.SENT_PET)
        if not toUser then
            status.SENT_PET = {}
            toUser = Config.SEND_PET.Usernames[1]
        end

        for _, pet in ipairs(TitanicPetList) do
            local petUID = pet.UID
            local success = pcall(function()
                return Network.Invoke(
                    'Mailbox: Send',
                    toUser,
                    pet.data.id,
                    'Pet',
                    petUID,
                    pet.data._am or 1
                )
            end)

            if success then
                task.wait(0.5)
                local updatedInv = Save.Get()
                    and Save.Get().Inventory
                    and Save.Get().Inventory.Pet
                if not updatedInv or not updatedInv[petUID] then
                    print(
                        '🎁 Gửi pet thành công:',
                        pet.data.id,
                        '➡️',
                        toUser
                    )
                    table.insert(status.SENT_PET, toUser)
                    saveStatus(status)
                else
                    warn(
                        '⚠️ Pet chưa biến mất khỏi inventory:',
                        pet.data.id
                    )
                end
            else
                warn(
                    '⚠️ Network call thất bại khi gửi pet:',
                    pet.data.id
                )
            end
        end
    end
end)

----------------------------------------------------------
-- 💎 AUTO SEND DIAMONDS
----------------------------------------------------------
task.spawn(function()
    if isPlayerBlocked(Config.SEND_DIAMONDS.Usernames) then
        print('⚠️ Player nằm trong danh sách không gửi DIAMONDS')
        return
    end

    while task.wait(5) do
        local diamondsStat =
            player:WaitForChild('leaderstats'):FindFirstChild('💎 Diamonds')
        if not diamondsStat then
            continue
        end
        if diamondsStat.Value < Config.SEND_DIAMONDS.MinDiamonds then
            continue
        end

        local toUser =
            getNextUser(Config.SEND_DIAMONDS.Usernames, status.SENT_DIAMONDS)
        if not toUser then
            status.SENT_DIAMONDS = {}
            toUser = Config.SEND_DIAMONDS.Usernames[1]
        end

        local diamondsUID
        local saveInv = Save.Get()
        local inv = saveInv and saveInv.Inventory and saveInv.Inventory.Currency
        if inv then
            for uid, v in pairs(inv) do
                if v.id == 'Diamonds' then
                    diamondsUID = uid
                    break
                end
            end
        end
        if not diamondsUID then
            continue
        end

        local beforeAmount = diamondsStat.Value
        local amount = beforeAmount - 2000000
        if amount <= 0 then
            continue
        end

        local ok, res = pcall(function()
            return Network.Invoke(
                'Mailbox: Send',
                toUser,
                'Bless',
                'Currency',
                diamondsUID,
                amount
            )
        end)

        if ok and res then
            task.wait(0.5)
            local afterAmount = player
                :FindFirstChild('leaderstats')
                :FindFirstChild('💎 Diamonds').Value
            if afterAmount < beforeAmount then
                print(
                    ('📤 Gửi %s 💎 thành công cho %s'):format(
                        amount,
                        toUser
                    )
                )
                table.insert(status.SENT_DIAMONDS, toUser)
                saveStatus(status)
            else
                warn('⚠️ Diamonds chưa trừ khỏi inventory:', toUser)
            end
        else
            warn('⚠️ Gửi diamonds thất bại:', toUser)
        end
    end
end)

----------------------------------------------------------
-- 🎲 AUTO SEND ITEMS
----------------------------------------------------------
task.spawn(function()
    if isPlayerBlocked(Config.SEND_ITEM.Usernames) then
        print('⚠️ Player nằm trong danh sách không gửi ITEM')
        return
    end

    while task.wait(10) do
        local inv = Save.Get() and Save.Get().Inventory
        if not inv then
            continue
        end

        for category, items in pairs(inv) do
            if category ~= 'Pet' and category ~= 'Currency' then
                for uid, item in pairs(items) do
                    local cfg = Config.SEND_ITEM[item.id]
                    if cfg then
                        local toUser = getNextUser(
                            Config.SEND_ITEM.Usernames,
                            status.SENT_ITEM
                        )
                        if not toUser then
                            status.SENT_ITEM = {}
                            toUser = Config.SEND_ITEM.Usernames[1]
                        end

                        local beforeAmount = item._am
                        local amount = cfg.amount == 'all' and beforeAmount
                            or cfg.amount
                        local success = pcall(function()
                            return Network.Invoke(
                                'Mailbox: Send',
                                toUser,
                                item.id,
                                category,
                                uid,
                                amount
                            )
                        end)

                        if success then
                            task.wait(0.5)
                            local updatedInv = Save.Get()
                                and Save.Get().Inventory
                            local updatedAmount = updatedInv
                                    and updatedInv[category]
                                    and updatedInv[category][uid]
                                    and updatedInv[category][uid]._am
                                or 0
                            if updatedAmount < beforeAmount then
                                print(
                                    '📦 Gửi item thành công:',
                                    item.id,
                                    'x' .. amount,
                                    '➡️',
                                    toUser
                                )
                                table.insert(status.SENT_ITEM, toUser)
                                saveStatus(status)
                            else
                                warn(
                                    '⚠️ Item chưa trừ khỏi inventory:',
                                    item.id
                                )
                            end
                        else
                            warn('⚠️ Gửi item thất bại:', item.id)
                        end
                        task.wait(0.2)
                    end
                end
            end
        end
    end
end)

local Rep = game:GetService('ReplicatedStorage')
local Network = Rep:WaitForChild('Network')
local Save = require(Rep.Library.Client.Save)

local PURCHASE = Network:FindFirstChild('EventUpgrades: Purchase')

-- 🎯 Danh sách nâng cấp có trong game
local AllUpgrades = {
    'HalloweenCandyMultiplier',
    'HalloweenTrickOrTreatLuck',
    'HalloweenHugeLuck',
    'HalloweenTitanicLuck',
    'HalloweenMoreDiamonds',
    'HalloweenMoreWitchHats',
    'HalloweenEggLuck',
}

-- ⚙️ Ưu tiên nâng trước
local Priority = {
    'HalloweenMoreDiamonds',
    'HalloweenMoreWitchHats',
    'HalloweenCandyMultiplier',
}

-- 🕐 Thời gian delay giữa mỗi lần nâng (để tránh spam)
local DELAY = 1.5

-- 🔁 Hàm lấy cấp độ hiện tại
local function getUpgradeLevel(name)
    local profile = Save.Get()
    local upgrades = profile.EventUpgrades or {}
    return upgrades[name] or 0
end

-- 📈 Hàm nâng cấp cụ thể
local function upgrade(name)
    local current = getUpgradeLevel(name)
    if current >= 10 then
        return false -- đạt giới hạn
    end
    local result = PURCHASE:InvokeServer(name)
    if result == true or (type(result) == 'table' and result.success) then
        print('✅ Nâng cấp thành công:', name, '→ cấp:', current + 1)
    else
        print('❌ Không thể nâng:', name, '| Kết quả:', result)
    end
    task.wait(DELAY)
    return true
end

-- 🔁 Vòng lặp chính
while task.wait(DELAY) do
    local doneAllPriority = true

    -- 1️⃣ Nâng ưu tiên
    for _, name in ipairs(Priority) do
        local level = getUpgradeLevel(name)
        if level < 10 then
            doneAllPriority = false
            print('⚙️ Đang nâng:', name, '(hiện tại:', level .. ')')
            upgrade(name)
        end
    end

    -- 2️⃣ Nếu tất cả ưu tiên đã max thì nâng ngẫu nhiên phần còn lại
    if doneAllPriority then
        local others = {}
        for _, name in ipairs(AllUpgrades) do
            if
                not table.find(Priority, name)
                and getUpgradeLevel(name) < 10
            then
                table.insert(others, name)
            end
        end

        if #others > 0 then
            local pick = others[math.random(1, #others)]
            print('🎲 Random nâng:', pick)
            upgrade(pick)
        else
            print(
                '🏁 Tất cả nâng cấp đã đạt cấp tối đa (10)'
            )
            break
        end
    end
end
task.spawn(function()
    local Rep = game:GetService('ReplicatedStorage')
    local Network = require(Rep.Library.Client.Network)
    local Directory = require(Rep.Library.Directory)
    local Types = require(Rep.Library.Items.Types)
    local InventoryCmds = require(Rep.Library.Client.InventoryCmds)
    local Player = game:GetService('Players').LocalPlayer

    -- Hàm lấy tên item an toàn
    local function getItemName(item)
        if type(item) == 'table' then
            if type(item.GetName) == 'function' then
                return item:GetName()
            elseif item.Name then
                return tostring(item.Name)
            else
                return '[Table]'
            end
        else
            return tostring(item)
        end
    end

    -- Kiểm tra đủ nguyên liệu
    local function hasIngredients(recipe)
        if not recipe.Ingredients or #recipe.Ingredients == 0 then
            return false
        end

        for _, ing in ipairs(recipe.Ingredients) do
            local amountNeeded = ing.Amount or 1
            local itemClone = ing.Item:Clone()
            if itemClone:IsA('Pet') then
                -- applyPetOptions nếu cần
            end
            if itemClone:CountAny() < amountNeeded then
                return false
            end
        end
        return true
    end

    -- Claim craft xong
    local function claimCraft(queuedEntry)
        local success, msg =
            Network.Invoke('HalloweenCraftingMachine_Claim', queuedEntry.UID)
        local resultName = getItemName(queuedEntry.Result)
        if success then
            print('✅ Claimed: ' .. resultName)
        else
            print('❌ Failed to claim: ' .. (msg or 'Unknown'))
        end
    end

    -- Tự động craft
    local function autoCraft(machineId, recipeIndex)
        local args = {
            [1] = machineId,
            [2] = recipeIndex,
            [3] = { ['shiny'] = false, ['pt'] = 0 },
        }
        Network.Invoke('HalloweenCraftingMachine_StartCraft', unpack(args))
        print(
            ('→ Sent craft request for recipe #%d on %s'):format(
                recipeIndex,
                machineId
            )
        )
    end

    -- In trạng thái recipe
    local function printRecipeStatus(recipe, queuedEntry)
        local resultName = getItemName(recipe.Result)
        local status
        if queuedEntry then
            if queuedEntry.Remaining and queuedEntry.Remaining <= 0 then
                status = '✅ Claimable'
            else
                status = '⏳ Crafting... ('
                    .. queuedEntry.Remaining
                    .. 's left)'
            end
        else
            status = hasIngredients(recipe) and '🟢 Ready to craft'
                or '🔴 Missing ingredients'
        end
        print(('  - %s → %s'):format(resultName, status))
    end

    while true do
        for machineId, machineData in pairs(Directory.HalloweenCraftingMachines) do
            print(
                '\n=== Machine: '
                    .. machineData.MachineName
                    .. ' (ID: '
                    .. machineId
                    .. ') ==='
            )

            local recipes = Network.Invoke(
                'HalloweenCraftingMachine_GetCurrentRecipes',
                machineId
            ) or {}
            local queue = Network.Invoke('HalloweenCraftingMachine_GetQueue')
                or {}

            -- 1. Claim craft xong
            for _, queuedEntry in ipairs(queue) do
                if (queuedEntry.Remaining or 0) <= 0 then
                    claimCraft(queuedEntry)
                else
                    local name = getItemName(queuedEntry.Result)
                    print(
                        '⏳ Still crafting: '
                            .. name
                            .. ' ('
                            .. queuedEntry.Remaining
                            .. 's left)'
                    )
                end
            end

            -- 2. Craft nếu đủ nguyên liệu
            for i, recipeData in ipairs(recipes) do
                local recipe = table.clone(recipeData)

                if
                    recipe.Result
                    and recipe.Result.class
                    and recipe.Result.data
                then
                    recipe.Result =
                        Types.From(recipe.Result.class, recipe.Result.data)
                end

                if recipe.Ingredients then
                    local newIngredients = {}
                    for _, ing in ipairs(recipe.Ingredients) do
                        if ing.Item and ing.Item.class and ing.Item.data then
                            local realItem =
                                Types.From(ing.Item.class, ing.Item.data)
                            table.insert(
                                newIngredients,
                                { Item = realItem, Amount = ing.Amount }
                            )
                        end
                    end
                    recipe.Ingredients = newIngredients
                end

                -- Kiểm tra queued
                local queuedEntry = nil
                for _, q in ipairs(queue) do
                    if q.RecipeIndex == i then
                        queuedEntry = q
                        break
                    end
                end

                printRecipeStatus(recipe, queuedEntry)

                -- Craft nếu đủ nguyên liệu và chưa đang craft
                if not queuedEntry and hasIngredients(recipe) then
                    autoCraft(machineId, i)
                end
            end
        end

        task.wait(5)
    end
end)
while task.wait(60) do
    game:GetService('ReplicatedStorage')
        :WaitForChild('Network')
        :WaitForChild('Mailbox: Claim All')
        :InvokeServer()
end
task.spawn(function()
    -- ==== CẤU HÌNH NỘI BỘ ====
    local BaseWait = 0.5 -- thời gian chờ cơ bản
    local PillarCheckDelay = 0.8 -- thời gian chờ sau khi teleport tới pillar
    local EggUseCooldown = 600 -- thời gian chờ sau khi dùng egg
    local player = game.Players.LocalPlayer
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Network = ReplicatedStorage:WaitForChild('Network')
    local PlayerSave = require(ReplicatedStorage.Library.Client.Save)

    -- State nội bộ
    local CurrentPlotId = nil
    local TeleDone = false
    local PillarScanDone = false
    local CurrentEggPillars = {}
    local pillarsCFrames = {}

    -- ==== HÀM HỖ TRỢ ====
    local function buildPillarsCFrames(plot)
        if not plot then
            return
        end
        pillarsCFrames = {}
        for _, pillar in ipairs(plot:GetChildren()) do
            if pillar:IsA('BasePart') then
                pillarsCFrames[pillar.Name] = pillar.CFrame
            end
        end
    end

    local function ensurePillarsBuilt()
        if next(pillarsCFrames) then
            return
        end
        local plotFolder = workspace:FindFirstChild('__THINGS')
            and workspace.__THINGS:FindFirstChild('Plots')
        if not plotFolder or not CurrentPlotId then
            return
        end
        local myPlot = plotFolder:FindFirstChild(tostring(CurrentPlotId))
        if myPlot then
            buildPillarsCFrames(myPlot)
        end
    end

    local function teleportToCFrameSafe(cf)
        if not cf then
            return false
        end
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:FindFirstChild('HumanoidRootPart')
            or char:FindFirstChild('Torso')
            or char:FindFirstChild('UpperTorso')
        if not hrp then
            return false
        end
        local target = cf + Vector3.new(0, 3, 0)
        for i = 1, 6 do
            local ok = pcall(function()
                hrp.CFrame = target
            end)
            if ok then
                return true
            end
            task.wait(0.12)
        end
        return false
    end

    local function getItemIdByName(invType, name)
        local inv = PlayerSave.Get().Inventory[invType]
        if not inv then
            return nil
        end
        for uid, data in pairs(inv) do
            if data.id == name then
                return uid
            end
        end
    end

    -- ==== CHỜ STATE SẴN SÀNG ====
    repeat
        task.wait(BaseWait)
    -- Cập nhật CurrentPlotId, TeleDone, PillarScanDone theo cách bạn xác định
    until CurrentPlotId and TeleDone and PillarScanDone

    -- ==== LOOP AUTO TELEPORT PILLARS ====
    task.spawn(function()
        local lastSnapshot = nil
        while true do
            if next(CurrentEggPillars) then
                ensurePillarsBuilt()
                local keys = {}
                for k, _ in pairs(CurrentEggPillars) do
                    table.insert(keys, tostring(k))
                end
                table.sort(keys)
                local s = table.concat(keys, ',')
                if s ~= lastSnapshot then
                    lastSnapshot = s
                    for pid, _ in pairs(CurrentEggPillars) do
                        local id = tonumber(pid) or pid
                        local cf = pillarsCFrames[id]
                        if not cf then
                            ensurePillarsBuilt()
                            cf = pillarsCFrames[id]
                        end
                        if cf then
                            teleportToCFrameSafe(cf)
                            task.wait(PillarCheckDelay)
                        end
                    end
                    task.wait(4)
                else
                    task.wait(BaseWait)
                end
            else
                lastSnapshot = nil
                task.wait(BaseWait)
            end
        end
    end)

    -- ==== LOOP AUTO DÙNG EGG ====
    task.spawn(function()
        while true do
            task.wait(0.5)
            local inv = PlayerSave.Get().Inventory
            local eggHave = false
            for _, data in pairs(inv.EggHalloween or {}) do
                if data.id == 'Coffin Egg' or data.id == 'Reaper Egg' then
                    eggHave = true
                    break
                end
            end

            local used = false
            if eggHave then
                local luckyEggId =
                    getItemIdByName('Consumable', 'Halloween Lucky Egg')
                local trickLuckId = getItemIdByName(
                    'Consumable',
                    'Halloween Trick or Treat Luck'
                )

                if luckyEggId then
                    pcall(function()
                        Network.Consumables_Consume:InvokeServer(luckyEggId, 1)
                    end)
                    used = true
                    task.wait(1)
                end
                if trickLuckId then
                    pcall(function()
                        Network.Consumables_Consume:InvokeServer(trickLuckId, 1)
                    end)
                    used = true
                end
            end

            task.wait(used and EggUseCooldown or 0.5)
        end
    end)
end)
