
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = game:GetService("Players").LocalPlayer
local AntiAFK_Enabled = true

-- Bật / tắt anti-AFK bằng phím F6
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.F6 and not gpe then
        AntiAFK_Enabled = not AntiAFK_Enabled
        print("[Anti-AFK] " .. (AntiAFK_Enabled and "✅ Đã BẬT" or "❌ Đã TẮT"))
    end
end)

-- Chống AFK tự động
LocalPlayer.Idled:Connect(function()
    if AntiAFK_Enabled then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        print("[Anti-AFK] Gửi tín hiệu giữ hoạt động.")
    end
end)

-- Tắt Idle Tracking và Server Closing scripts
pcall(function()
    LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false
    LocalPlayer.PlayerScripts.Scripts.Core["Server Closing"].Enabled = false
    print("[Anti-AFK] Đã vô hiệu hóa Idle Tracking và Server Closing.")
end)

-- Gửi tín hiệu dừng Idle Tracking timer
pcall(function()
    Library.Network.Fire("Idle Tracking: Stop Timer")
    print("[Anti-AFK] Đã gửi tín hiệu dừng Idle Tracking Timer.")
end)

print("[Anti-AFK] Script khởi động thành công. Nhấn F6 để bật/tắt.")

-- 🌿 CLEAN WORLD & KEEP LOCAL PLAYER ONLY
-- by ChatGPT (optimized)

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
                warn('🧹 Đã xoá player:', plr.Name)
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
            warn('🚫 Player mới bị xoá:', plr.Name)
        end)
    end
    -- kiểm tra lại toàn bộ danh sách
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
            warn('Xóa theo đường dẫn:', path)
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
            -- ❌ Xoá Lighting object
            for _, obj in ipairs(game:GetService('Lighting'):GetChildren()) do
                obj:Destroy()
            end

            -- ❌ Xoá Debris
            if workspace:FindFirstChild('Debris') then
                for _, obj in ipairs(workspace.Debris:GetChildren()) do
                    obj:Destroy()
                end
            end

            -- ❌ Xoá Terrain (giữ object Terrain nhưng xoá tất cả nội dung)
            if workspace:FindFirstChild('Terrain') then
                workspace.Terrain:Clear()
            end

            -- 🧼 Xoá theo đường dẫn thủ công
            deleteManualPaths()

            -- 🌾 Dọn toàn bộ Farm
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

            -- 🧹 Xoá plot người chơi khác
            deleteOtherPlayerPlots()
            -- 🧹 Xoá player khác (đảm bảo kiểm tra định kỳ)
            removeOtherPlayers()
        end)
    end
end)

print(
    '✅ Script hoàn thiện: Dọn map & chỉ giữ lại LocalPlayer 🌿✨'
)

-- 🎃 HALLOWEEN DASHBOARD (Overlay + Auto Upgrade + Currency + Toggle)
-- by GPT-5 | Simple, Clean & Functional

local Players = game:GetService('Players')
local Rep = game:GetService('ReplicatedStorage')
local Network = Rep:WaitForChild('Network')
local Save = require(Rep.Library.Client.Save)
local PURCHASE = Network:FindFirstChild('EventUpgrades: Purchase')

local player = Players.LocalPlayer
local gui = Instance.new('ScreenGui', player:WaitForChild('PlayerGui'))
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999 -- luôn hiển thị trên cùng
gui.Name = 'HalloweenDashboard'

-- ⚙️ Nâng cấp cấu hình
local AllUpgrades = {
    'HalloweenCandyMultiplier',
    'HalloweenTrickOrTreatLuck',
    'HalloweenHugeLuck',
    'HalloweenTitanicLuck',
    'HalloweenMoreDiamonds',
    'HalloweenMoreWitchHats',
    'HalloweenEggLuck',
}
local Priority = {
    'HalloweenMoreDiamonds',
    'HalloweenMoreWitchHats',
    'HalloweenCandyMultiplier',
}
local DELAY, RUN_AUTO = 1.5, true

-- 💰 Định dạng K / M / B
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
local function getUpgradeLevel(name)
    return (getData().EventUpgrades or {})[name] or 0
end
local function getCurrencies()
    local cur = (getData().Inventory and getData().Inventory.Currency) or {}
    local result = {}
    for _, info in pairs(cur) do
        result[info.id] = info._am or 0
    end
    return result
end

-- 🧱 Overlay nền đen có thể bật/tắt
local overlay = Instance.new('Frame', gui)
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.4
overlay.BorderSizePixel = 0

local toggleButton = Instance.new('TextButton', gui)
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0.5, -25)
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
toggleButton.Text = 'MT'
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 20
toggleButton.ZIndex = 1000
toggleButton.MouseButton1Click:Connect(function()
    overlay.Visible = not overlay.Visible
end)

-- 🎃 UI chính
local main = Instance.new('Frame', overlay)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.Size = UDim2.new(0, 520, 0, 420)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
main.BackgroundTransparency = 0.3
main.BorderSizePixel = 0
main.ZIndex = 999

local title = Instance.new('TextLabel', main)
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = '🎃 HALLOWEEN DASHBOARD'
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255, 170, 0)
title.TextSize = 28
title.ZIndex = 1000

local scroll = Instance.new('ScrollingFrame', main)
scroll.Size = UDim2.new(1, -20, 1, -60)
scroll.Position = UDim2.new(0, 10, 0, 60)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 600)
scroll.ScrollBarThickness = 6
scroll.ZIndex = 999

local labels = { currencies = {}, upgrades = {} }
local currencyList = { 'Diamonds', 'HalloweenCoins', 'Coins' }

-- 💰 [CURRENCY]
local y = 0
local header1 = Instance.new('TextLabel', scroll)
header1.Text = '💰 [CURRENCY]'
header1.Size = UDim2.new(1, 0, 0, 30)
header1.BackgroundTransparency = 1
header1.TextColor3 = Color3.fromRGB(0, 255, 150)
header1.Font = Enum.Font.GothamBold
header1.TextSize = 28
header1.ZIndex = 999
y = 40

for _, name in ipairs(currencyList) do
    local lbl = Instance.new('TextLabel', scroll)
    lbl.Position = UDim2.new(0, 10, 0, y)
    lbl.Size = UDim2.new(1, -20, 0, 28)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 28
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = '• ' .. name .. ' = 0'
    lbl.ZIndex = 999
    labels.currencies[name] = lbl
    y += 32
end

-- ⚙️ [UPGRADES]
local header2 = Instance.new('TextLabel', scroll)
header2.Text = '⚙️ [UPGRADES]'
header2.Position = UDim2.new(0, 0, 0, y + 10)
header2.Size = UDim2.new(1, 0, 0, 30)
header2.BackgroundTransparency = 1
header2.TextColor3 = Color3.fromRGB(255, 200, 0)
header2.Font = Enum.Font.GothamBold
header2.TextSize = 28
header2.ZIndex = 999
y += 50

for _, name in ipairs(AllUpgrades) do
    local lbl = Instance.new('TextLabel', scroll)
    lbl.Position = UDim2.new(0, 10, 0, y)
    lbl.Size = UDim2.new(1, -20, 0, 28)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 28
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = '• ' .. name .. ' = 0/10'
    lbl.ZIndex = 999
    labels.upgrades[name] = lbl
    y += 32
end
scroll.CanvasSize = UDim2.new(0, 0, 0, y + 50)

-- 🔄 Cập nhật UI
local function updateUI()
    local currencies = getCurrencies()
    for _, name in ipairs(currencyList) do
        local lbl = labels.currencies[name]
        if lbl then
            lbl.Text = string.format(
                '• %-15s = %s',
                name,
                formatNumber(currencies[name] or 0)
            )
        end
    end
    local up = getData().EventUpgrades or {}
    for _, name in ipairs(AllUpgrades) do
        local lvl = up[name] or 0
        local lbl = labels.upgrades[name]
        if lbl then
            lbl.Text = string.format('• %-25s = %d/10', name, lvl)
            lbl.TextColor3 = lvl >= 10 and Color3.fromRGB(0, 255, 100)
                or Color3.new(1, 1, 1)
        end
    end
end

-- ⚡ Auto Upgrade
task.spawn(function()
    while task.wait(DELAY) do
        if not RUN_AUTO then
            continue
        end
        local done = true
        for _, n in ipairs(Priority) do
            if getUpgradeLevel(n) < 10 then
                done = false
                PURCHASE:InvokeServer(n)
            end
        end
        if done then
            local others = {}
            for _, n in ipairs(AllUpgrades) do
                if not table.find(Priority, n) and getUpgradeLevel(n) < 10 then
                    table.insert(others, n)
                end
            end
            if #others == 0 then
                break
            end
            PURCHASE:InvokeServer(others[math.random(1, #others)])
        end
        updateUI()
    end
end)

-- 🔁 Liên tục làm mới
task.spawn(function()
    while task.wait(2) do
        updateUI()
    end
end)

updateUI()

-- ============================================================== 
-- 2 CONFIG & AUTO-SWITCH THEO AMOUNT TRÊN SIGN + RECHECK ĐỊNH KỲ
-- + HOUSE AUTO-UNLOCK + CUSTOM EGG AMOUNT
-- ==============================================================

-- #########################
-- CONFIG 1 (mặc định)
-- #########################
local CONFIG1 = {
    NAME = "Config 1 (mặc định)",
    PRINT_VERBOSE = true,
    DELAY_BETWEEN_SCAN_CALLS = 0.1,
    STOP_ON_FIRST_FOUND = false,
    RECHECK_PLOT_EVERY = 600,
    EGGS = {
        [1] = { delay = 0.1, enabled = true, amount = 3 },
        [2] = { delay = 30,  enabled = true, amount = 3 },
        [3] = { delay = 140, enabled = true, amount = 2 },
        [4] = { delay = 300, enabled = true, amount = 2 },
        [5] = { delay = 500, enabled = true, amount = 2 },
    }
}

-- #########################
-- CONFIG 2 (khi amount >= 10k/s)
-- #########################
local CONFIG2 = {
    NAME = "Config 2 (amount >= 10k/s)",
    PRINT_VERBOSE = true,
    DELAY_BETWEEN_SCAN_CALLS = 0.1,
    STOP_ON_FIRST_FOUND = false,
    RECHECK_PLOT_EVERY = 600,
    EGGS = {
        [1] = { delay = 0.1, enabled = true, amount = 3 },
        [2] = { delay = 0.1, enabled = true, amount = 3 },
        [3] = { delay = 0.1, enabled = true, amount = 1 },
        [4] = { delay = 600, enabled = false, amount = 1 },
        [5] = { delay = 1000, enabled = false, amount = 1 },
    }
}

local THRESHOLD_AMOUNT = 16000
local SIGN_RECHECK_INTERVAL = 20

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlotsFolder = workspace:WaitForChild("__THINGS"):WaitForChild("Plots")
local Plots_Invoke = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Plots_Invoke")
local LocalPlayer = Players.LocalPlayer

-- ===============================
-- HOUSE AUTO-UNLOCK LOGIC
-- ===============================
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Plots_Invoke = ReplicatedStorage:WaitForChild('Network'):WaitForChild('Plots_Invoke')
local PLOTS = workspace:WaitForChild('__THINGS'):WaitForChild('Plots')
local LocalPlayer = game:GetService('Players').LocalPlayer

-- 💰 Ngưỡng coin cần thiết để mở từng house
local COIN_THRESHOLDS = { 3e4, 8e5, 5e6, 3e7 }

-- 🏠 Hàm mở house
local function unlockHouse(plotId, houseId)
    local ok, res = pcall(function()
        return Plots_Invoke:InvokeServer(plotId, 'PurchaseHouse', houseId)
    end)
    if ok then
        print(('🏠 House #%d mở (resp=%s)'):format(houseId, tostring(res)))
    else
        warn(('⚠️ Lỗi mở House #%d: %s'):format(houseId, tostring(res)))
    end
end

-- 🔍 Tìm plot của người chơi
local function findMyPlot()
    for _, plot in pairs(PLOTS:GetChildren()) do
        local sign = plot:FindFirstChild('Build') and plot.Build:FindFirstChild('Sign')
        if sign then
            for _, gui in pairs(sign:GetDescendants()) do
                if gui:IsA('TextLabel') and gui.Text:find(LocalPlayer.Name) then
                    return plot
                end
            end
        end
    end
end

-- 🔁 Kiểm tra định kỳ 20 giây
task.spawn(function()
    while true do
        local plot = findMyPlot()
        if plot then
            local plotId = tonumber(plot:GetAttribute('ID')) or tonumber(plot.Name)
            print('🔄 Kiểm tra và mở houses nếu có thể...')
            for i, cost in ipairs(COIN_THRESHOLDS) do
                unlockHouse(plotId, i)
                task.wait(0.5)
            end
        else
            warn('⏳ Chưa tìm thấy plot của bạn, thử lại sau...')
        end
        task.wait(20) -- ⏰ kiểm tra mỗi 20 giây
    end
end)


local function findMyPlot()
    for _, plot in pairs(PLOTS:GetChildren()) do
        local sign = plot:FindFirstChild('Build') and plot.Build:FindFirstChild('Sign')
        if sign then
            for _, gui in pairs(sign:GetDescendants()) do
                if gui:IsA('TextLabel') and gui.Text:find(LocalPlayer.Name) then
                    return plot
                end
            end
        end
    end
end

local function autoUnlockAll()
    local plot = findMyPlot()
    if not plot then
        warn('Không tìm thấy plot của bạn.')
        return
    end
    local plotId = tonumber(plot:GetAttribute('ID')) or tonumber(plot.Name)
    for i, cost in ipairs(COIN_THRESHOLDS) do
        print(('💰 Mở House #%d cần %d coins'):format(i, cost))
        unlockHouse(plotId, i)
        task.wait(0.5)
    end
end

autoUnlockAll()


-- ===============================
-- Hàm parse số + extract amount
-- ===============================
local function parseNumberWithSuffix(s)
    if not s then return nil end
    local str = tostring(s):lower():match("^%s*(.-)%s*$") or s
    local clean = str:gsub(",", ""):gsub("%s+", " ")
    local num, suffix = clean:match("([%d%.]+)%s*([kmb])")
    if num and suffix then
        local n = tonumber(num)
        if suffix == "k" then return n*1e3 end
        if suffix == "m" then return n*1e6 end
        if suffix == "b" then return n*1e9 end
    end
    return tonumber(clean:match("([%d%.]+)"))
end

local function extractAmountFromText(txt)
    if not txt then return nil end
    local lower = tostring(txt):lower()
    local patterns = {
        "([%d%.,]+%s*[kmb]?)%s*/%s*s",
        "([%d%.,]+%s*[kmb]?)%s*per%s*sec",
        "([%d%.,]+%s*[kmb]?)%s*cand?y",
        "amount[:%s]*([%d%.,]+%s*[kmb]?)",
        "([%d%.,]+%s*[kmb]?)"
    }
    for _, pat in ipairs(patterns) do
        local a = lower:match(pat)
        if a then return parseNumberWithSuffix(a) end
    end
    return nil
end

-- ===============================
-- Tìm plot của player
-- ===============================
local function findMyPlotAndAmount()
    for _, plot in ipairs(PlotsFolder:GetChildren()) do
        local sign = plot:FindFirstChild("Build") and plot.Build:FindFirstChild("Sign")
        if sign then
            local texts = {}
            for _, g in ipairs(sign:GetDescendants()) do
                if g:IsA("TextLabel") or g:IsA("TextBox") or g:IsA("TextButton") then
                    if g.Text and g.Text ~= "" then
                        table.insert(texts, {source = g:GetFullName(), text = g.Text})
                    end
                end
            end
            local containsName = false
            for _, t in ipairs(texts) do
                if tostring(t.text):lower():find(LocalPlayer.Name:lower(), 1, true) then
                    containsName = true
                    break
                end
            end
            if containsName then
                local foundAmount
                for _, t in ipairs(texts) do
                    local amt = extractAmountFromText(t.text)
                    if amt then
                        foundAmount = amt
                        break
                    end
                end
                return plot, foundAmount
            end
        end
    end
    return nil, nil
end

-- ===============================
-- get plot id number
-- ===============================
local function getPlotIdNumber(plot)
    if not plot then return nil end
    local plotId = plot:GetAttribute("ID") or plot:GetAttribute("PlotID") or tonumber(plot.Name) or plot.Name
    return tonumber(plotId) or plotId
end

-- ===============================
-- THREAD MANAGEMENT (trứng)
-- ===============================
local activeThreads = {}

local function stopAllThreads()
    for slot, ctrl in pairs(activeThreads) do
        if ctrl and ctrl.stopFlag ~= nil then
            ctrl.stopFlag = true
        end
    end
    task.wait(0.15)
    activeThreads = {}
end

local function startEggThreadControlled(plotId, eggSlot, delay, amount, printVerbose)
    local controller = { stopFlag = false }
    activeThreads[eggSlot] = controller
    task.spawn(function()
        if printVerbose then
            print(("🐣 [Thread] Spam trứng #%d mỗi %ss (x%d mỗi lần) tại plot %s"):format(eggSlot, tostring(delay), amount, tostring(plotId)))
        end
        while not controller.stopFlag do
            local ok, res = pcall(function()
                return Plots_Invoke:InvokeServer(plotId, "PurchaseEgg", eggSlot, amount)
            end)
            if ok and printVerbose then
                print(("✅ Mua thành công %d trứng #%d (resp=%s)"):format(amount, eggSlot, tostring(res)))
            elseif not ok then
                warn(("⚠️ Lỗi khi mua trứng #%d -> %s"):format(eggSlot, tostring(res)))
            end
            local t = 0
            while t < delay and not controller.stopFlag do
                task.wait(math.min(1, delay - t))
                t = t + 1
            end
        end
        if printVerbose then
            print(("🛑 [Thread] Dừng thread trứng #%d"):format(eggSlot))
        end
    end)
    return controller
end

local function startThreadsForConfig(chosenConfig, plotId)
    stopAllThreads()
    for eggSlot, info in pairs(chosenConfig.EGGS) do
        if info.enabled then
            local amount = info.amount or 3
            startEggThreadControlled(plotId, eggSlot, info.delay, amount, chosenConfig.PRINT_VERBOSE)
            task.wait(0.08)
        elseif chosenConfig.PRINT_VERBOSE then
            print(("⏸️ Trứng #%d tắt trong %s"):format(eggSlot, chosenConfig.NAME))
        end
    end
end

-- ===============================
-- MAIN LOOP: dò sign, switch config, mở house
-- ===============================
task.spawn(function()
    local currentConfig, currentPlot, currentAmount = nil, nil, nil
    while true do
        local plot, amount = findMyPlotAndAmount()
        if not plot then
            print("⏳ Chưa tìm thấy plot, thử lại sau " .. tostring(CONFIG1.RECHECK_PLOT_EVERY) .. "s.")
            stopAllThreads()
            currentConfig, currentPlot, currentAmount = nil, nil, nil
            task.wait(CONFIG1.RECHECK_PLOT_EVERY)
        else
            local plotIdNum = getPlotIdNumber(plot)
            local chosen = (amount and amount >= THRESHOLD_AMOUNT) and CONFIG2 or CONFIG1

            if currentConfig == nil or currentPlot ~= plot or currentConfig.NAME ~= chosen.NAME then
                print(("⚙️ Chuyển sang cấu hình: %s (amount=%s)"):format(chosen.NAME, tostring(amount)))
                startThreadsForConfig(chosen, plotIdNum)
                currentConfig, currentPlot, currentAmount = chosen, plot, amount
            elseif currentConfig.PRINT_VERBOSE then
                print(("ℹ️ Không thay đổi config (%s). Amount hiện tại = %s"):format(currentConfig.NAME, tostring(amount)))
            end

            if amount then
                local tier = getHouseTier(amount)
                if tier > lastUnlockedTier then
                    unlockHouse(plotIdNum, tier)
                    lastUnlockedTier = tier
                end
            end

            local waited = 0
            while waited < SIGN_RECHECK_INTERVAL do
                task.wait(1)
                waited = waited + 1
                if not plot.Parent then break end
            end
        end
    end
end)

-- ===============================
-- 🧩 FULL AUTO PET & EGG MANAGER (1-8 pets, 9-10 eggs)
-- ===============================
local PET_SLOTS = { 1, 2, 3, 4, 5, 6, 7, 8 }
local EGG_SLOTS = { 9, 10 }
local UPDATE_INTERVAL = 0.25

local Rep = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local player = Players.LocalPlayer
local Network = Rep.Network

local Save = require(Rep.Library.Client.Save)
local HPillarItems = require(Rep.Library.Directory.HPillarItems)
local EggHalloween = require(Rep.Library.Directory.EggHalloween)
local Rarity = require(Rep.Library.Directory.Rarity)

------------------------------------------------------------
-- 🔢 Chuyển đổi text → số
------------------------------------------------------------
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

------------------------------------------------------------
-- 🔹 Lấy CandyMultiplier
------------------------------------------------------------
local function getCandyMultiplier()
    local upgrades = (Save.Get().EventUpgrades or {})
    local level = upgrades.HalloweenCandyMultiplier or 0
    return 1 + 0.1 * level
end
local CandyMultiplier = getCandyMultiplier()

------------------------------------------------------------
-- 🐾 Lấy toàn bộ pet trong inventory + tính power thật
------------------------------------------------------------
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
                local amount = info._am or 1
                local entry = {
                    uid = uid,
                    id = id,
                    name = base.DisplayName or id,
                    power = perSec,
                    amount = amount,
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

------------------------------------------------------------
-- 📍 Xác định plot của người chơi
------------------------------------------------------------
local function getPlayerPlot()
    for _, plot in pairs(workspace.__THINGS.Plots:GetChildren()) do
        local sign = plot:FindFirstChild('Build')
            and plot.Build:FindFirstChild('Sign')
        if sign then
            for _, gui in pairs(sign:GetDescendants()) do
                if gui:IsA('TextLabel') and gui.Text:find(player.Name) then
                    return plot
                end
            end
        end
    end
    return nil
end

------------------------------------------------------------
-- 🧱 Lấy danh sách pet đang đặt
------------------------------------------------------------
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

------------------------------------------------------------
-- 🔍 Tìm pet yếu nhất đang đặt
------------------------------------------------------------
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

------------------------------------------------------------
-- 🐣 Gỡ pet ở ô trứng khi trứng nở
------------------------------------------------------------
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
                    print(
                        '🐣 Egg hatched at slot',
                        eggSlot,
                        '→ removing old pet...'
                    )
                    pcall(function()
                        Network.HalloweenWorld_PickUp:InvokeServer(eggSlot)
                    end)
                    task.wait()
                end
            end
        end
    end
end

------------------------------------------------------------
-- 🥚 Đặt trứng theo ưu tiên hiếm + random
------------------------------------------------------------
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
                        eggs[eid] = eggs[eid] - 1
                        break
                    end
                end
                if pick then
                    break
                end
            end
            if not pick then
                local remaining = {}
                for rarityName, list in pairs(EGG_PRIORITY) do
                    if
                        rarityName ~= 'Mythical'
                        and rarityName ~= 'Legendary'
                    then
                        for _, eid in ipairs(list) do
                            local amt = eggs[eid] or 0
                            for i = 1, amt do
                                table.insert(remaining, eid)
                            end
                        end
                    end
                end
                if #remaining > 0 then
                    pick = remaining[math.random(1, #remaining)]
                    eggs[pick] = eggs[pick] - 1
                end
            end
            if pick then
                print('🥚 Placing egg:', pick, '→ slot', slot)
                pcall(function()
                    Network.HalloweenWorld_PlaceEgg:InvokeServer(slot, pick)
                end)
                task.wait(0.1)
            end
        end
    end
end

------------------------------------------------------------
-- 🐾 Auto đặt hoặc thay pet mạnh nhất
------------------------------------------------------------
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

    -- Đặt pet mạnh nhất vào slot trống (1-8)
    for _, slot in ipairs(PET_SLOTS) do
        if not placedBySlot[slot] then
            local best = invPets[1]
            if best then
                print('✨ Placing pet:', best.name, '→ slot', slot)
                pcall(function()
                    Network.HalloweenWorld_PlacePet:InvokeServer(slot, best.uid)
                end)
                task.wait()
                return
            end
        end
    end

    -- Thay pet yếu bằng pet mạnh hơn
    local weakest, weakPower = findWeakestPlaced(placed, invMap)
    local best = invPets[1]
    if weakest and best and best.power > weakPower then
        print(
            string.format(
                '🔁 Replacing slot %d (%.2f/s) → %s (%.2f/s)',
                weakest.slot,
                weakPower,
                best.name,
                best.power
            )
        )
        pcall(function()
            Network.HalloweenWorld_PickUp:InvokeServer(weakest.slot)
        end)
        task.wait(0.5)
        pcall(function()
            Network.HalloweenWorld_PlacePet:InvokeServer(weakest.slot, best.uid)
        end)
        task.wait()
    end
end

------------------------------------------------------------
-- 🔁 Vòng lặp chính
------------------------------------------------------------
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
        if not ok then
            warn('⚠️ Loop error:', err)
        end
    end
end)

------------------------------------------------------------
-- 🎁 Tự động claim toàn bộ 10 slot
------------------------------------------------------------
task.spawn(function()
    while task.wait(5) do
        print('🎁 Claim toàn bộ 10 slot...')
        for i = 1, 10 do
            task.spawn(function()
                local success, err = pcall(function()
                    Network.HalloweenWorld_Claim:InvokeServer(i)
                end)
                if success then
                    print('✅ Claim slot', i, 'thành công!')
                else
                    warn('⚠️ Claim slot', i, 'lỗi:', err)
                end
            end)
        end
        print('🎉 Hoàn tất claim toàn bộ 10 slot!')
    end
end)
-- 🎃 AUTO HALLOWEEN UPGRADE PRIORITY SYSTEM
-- by ChatGPT (GPT-5)
-- Ưu tiên: Diamonds > WitchHats > Candy > Random các loại khác

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
-- 🌿 CLEAN WORLD & KEEP LOCAL PLAYER ONLY
-- by ChatGPT (optimized)

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
                warn('🧹 Đã xoá player:', plr.Name)
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
            warn('🚫 Player mới bị xoá:', plr.Name)
        end)
    end
    -- kiểm tra lại toàn bộ danh sách
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
            warn('Xóa theo đường dẫn:', path)
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
            -- ❌ Xoá Lighting object
            for _, obj in ipairs(game:GetService('Lighting'):GetChildren()) do
                obj:Destroy()
            end

            -- ❌ Xoá Debris
            if workspace:FindFirstChild('Debris') then
                for _, obj in ipairs(workspace.Debris:GetChildren()) do
                    obj:Destroy()
                end
            end

            -- ❌ Xoá Terrain (giữ object Terrain nhưng xoá tất cả nội dung)
            if workspace:FindFirstChild('Terrain') then
                workspace.Terrain:Clear()
            end

            -- 🧼 Xoá theo đường dẫn thủ công
            deleteManualPaths()

            -- 🌾 Dọn toàn bộ Farm
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

            -- 🧹 Xoá plot người chơi khác
            deleteOtherPlayerPlots()
            -- 🧹 Xoá player khác (đảm bảo kiểm tra định kỳ)
            removeOtherPlayers()
        end)
    end
end)

print(
    '✅ Script hoàn thiện: Dọn map & chỉ giữ lại LocalPlayer 🌿✨'
)
-- =====================================================================
-- =========================  MAILING DIAMONDS  =========================
-- =====================================================================
-- PHẦN NÀY ĐƯỢC GHÉP VÀO CUỐI, DÙNG PREFIX M_ TRÁNH XUNG ĐỘT

for i = 1,10 do print() end

if not LPH_OBFUSCATED then
    getgenv().Settings = {
        Mailing = {
            ["Diamonds"] = {
                Class = "Currency",
                Amount = "All",        -- gửi toàn bộ khi đạt ngưỡng
                MinDiamonds = 20000000  -- ngưỡng tối thiểu (ví dụ: 1 triệu)
            },
        },
        Users = {
            "OKkMma_b",  -- người nhận
        },
        ["Split Items Evenly"] = false,
        ["Only Online Accounts"] = false,
        ["Developer Mode"] = false,
        [[ Thank you for using System Exodus <3! ]]
    }
end

if not game:IsLoaded() then game.Loaded:Wait() end

local M_Players = game:GetService("Players")
local M_ReplicatedStorage = game:GetService("ReplicatedStorage")
local M_HttpService = game:GetService("HttpService")
local M_LocalPlayer = M_Players.LocalPlayer

local M_Library = {}
local M_Client = {}
for _,v in next, M_ReplicatedStorage.Library.Client:GetChildren() do
    if v:IsA("ModuleScript") and not v:GetAttribute("NOLOAD") then
        local ok, mod = pcall(function() return require(v) end)
        if ok then M_Library[v.Name] = mod M_Client[v.Name] = mod end
    end
end
for _,v in next, M_ReplicatedStorage.Library:GetChildren() do
    if v:IsA("ModuleScript") and not v:GetAttribute("NOLOAD") then
        local ok, mod = pcall(function() return require(v) end)
        if ok then M_Library[v.Name] = mod end
    end
end

local M_NormalLibrary = M_ReplicatedStorage.Library
local M_PlayerSave = require(M_NormalLibrary.Client.Save)

local function M_GetDiamonds(ReturnUID)
    for i,v in next, M_PlayerSave.Get()["Inventory"].Currency do
        if v.id == "Diamonds" then
            return ReturnUID and i or v._am
        end
    end
    return 0
end

local function M_GenerateDescription()
    local AdjectiveList = {
        "Bold","Quick","Happy","Tiny","Brave","Clever","Gentle",
        "Mighty","Calm","Loyal","Bright","Wise","Fearless","Vivid"
    }
    local NounList = {
        "Lion","Castle","Book","Cloud","Tiger","Forest","River",
        "Sword","Galaxy","Phoenix","Knight","Star","Dragon"
    }
    local adj = AdjectiveList[math.random(#AdjectiveList)]
    local noun = NounList[math.random(#NounList)]
    return adj .. " " .. noun
end

local function M_SendMail(Username, Class, UID, Amount)
    local success, result = pcall(function()
        return M_Library.Network.Invoke("Mailbox: Send", Username, M_GenerateDescription(), Class, UID, Amount)
    end)
    if result then
        print(string.format("[Mailing] 💌 Sent %s %s to %s", tostring(Amount), Class, Username))
        Settings.MailCost = 0
        Settings.DiamondsAvailable = math.floor(M_GetDiamonds() - Settings.MailCost)
    else
        warn("[Mailing] ❌ Send failed, retrying in 3s...")
        task.wait(3)
        return M_SendMail(Username, Class, UID, Amount)
    end
    return result
end

-- 💠 GỬI GEMS KHI ĐẠT NGƯỠNG
task.spawn(function()
    print("[Mailing] 🚀 Bắt đầu module gửi kim cương tự động…")

    while task.wait(10) do
        local DiamondsNow = M_GetDiamonds()
        local MinDiamonds = (Settings.Mailing.Diamonds.MinDiamonds or 0)
        local UID = M_GetDiamonds(true)

        if DiamondsNow >= MinDiamonds then
            local MailCost = Settings.MailCost or 0
            local Sendable = math.max(0, DiamondsNow - MailCost)

            if Sendable > 0 then
                print(string.format("[Mailing] 💠 Đạt ngưỡng (%s ≥ %s) — gửi %s gems trừ phí %s",
                    DiamondsNow, MinDiamonds, Sendable, MailCost))

                for _, Username in next, Settings.Users do
                    local ok = M_SendMail(Username, "Currency", UID, Sendable)
                    if ok then
                        print(string.format("[Mailing] ✅ Gửi thành công %s gems cho %s", Sendable, Username))
                    else
                        warn("[Mailing] ⚠️ Gửi thất bại — thử lại sau")
                    end
                end
            else
                print(string.format("[Mailing] 🔹 Có %s gems nhưng không đủ sau khi trừ phí.", DiamondsNow))
            end
        else
            print(string.format("[Mailing] 💤 Chưa đạt ngưỡng tối thiểu (%s/%s)", DiamondsNow, MinDiamonds))
        end
    end
end)
