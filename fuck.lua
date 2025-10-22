-- ===============================
-- 🛡️ Anti-AFK Script (auto chạy luôn)
-- ===============================

local Players = game:GetService('Players')
local VirtualUser = game:GetService('VirtualUser')
local player = Players.LocalPlayer

player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    warn('✅ Anti-AFK: giả lập click chuột, tránh bị kick')
end)

-- 🧩 AUTO HOUSE & EGG MANAGER - TỐC ĐỘ CAO
-- by ChatGPT

-- CONFIG
local PRINT_VERBOSE = true
local SIGN_RECHECK_INTERVAL = 10 -- giây, check sign liên tục
local EGG_DELAY = 1 -- delay giữa mỗi lần mua trứng (giây)
local MAX_EGG_SLOT = 5 -- số house/trứng tối đa

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PLOTS = workspace:WaitForChild('__THINGS'):WaitForChild('Plots')
local Plots_Invoke = ReplicatedStorage:WaitForChild('Network')
    :WaitForChild('Plots_Invoke')
local LocalPlayer = Players.LocalPlayer

-- Helper: chuyển "5.77k", "2.5m" => number
local function parseNumber(str)
    if not str then
        return nil
    end
    str = tostring(str):lower():gsub(',', ''):gsub('%s+', '')
    local n, suffix = str:match('([%d%.]+)([kmbt]?)')
    n = tonumber(n)
    if not n then
        return nil
    end
    local mult = { k = 1e3, m = 1e6, b = 1e9, t = 1e12 }
    return n * (mult[suffix] or 1)
end

-- Extract amount/sec từ text
local function extractAmount(text)
    if not text then
        return nil
    end
    local match = text:lower():match('([%d%.,]+%s*[kmbt]?)%s*/%s*s')
        or text:lower():match('([%d%.,]+%s*[kmbt]?)%s*per')
    if match then
        return parseNumber(match)
    end
    return parseNumber(text)
end

-- Tìm plot của mình + amount
local function findMyPlotAndAmount()
    for _, plot in pairs(PLOTS:GetChildren()) do
        local sign = plot:FindFirstChild('Build')
            and plot.Build:FindFirstChild('Sign')
        if sign then
            for _, gui in pairs(sign:GetDescendants()) do
                if gui:IsA('TextLabel') and gui.Text:find(LocalPlayer.Name) then
                    for _, t in pairs(sign:GetDescendants()) do
                        if
                            t:IsA('TextLabel')
                            and (
                                t.Text:find('/s') or t.Text:lower():find('per')
                            )
                        then
                            local amt = extractAmount(t.Text)
                            if PRINT_VERBOSE then
                                print(
                                    '✅ Tìm plot:',
                                    plot.Name,
                                    '| Amount:',
                                    amt
                                )
                            end
                            return plot, amt
                        end
                    end
                end
            end
        end
    end
end

-- Mở house
local function unlockHouse(plotId, houseId)
    local ok, res = pcall(function()
        return Plots_Invoke:InvokeServer(plotId, 'PurchaseHouse', houseId)
    end)
    if ok then
        print(
            ('🏠 House #%d mở thành công (resp=%s)'):format(
                houseId,
                tostring(res)
            )
        )
    else
        warn(('⚠️ Lỗi mở House #%d: %s'):format(houseId, tostring(res)))
    end
end

-- Mua trứng x3
local function purchaseEgg(plotId, slot)
    local ok, res = pcall(function()
        return Plots_Invoke:InvokeServer(plotId, 'PurchaseEgg', slot, 3)
    end)
    if ok then
        if PRINT_VERBOSE then
            print(
                ('✅ Mua x3 trứng slot #%d (resp=%s)'):format(
                    slot,
                    tostring(res)
                )
            )
        end
    else
        warn(('⚠️ Lỗi mua trứng #%d: %s'):format(slot, tostring(res)))
    end
end

-- THREAD CONTROL
local activeThreads = {}

local function stopAllThreads()
    for _, ctrl in pairs(activeThreads) do
        ctrl.stopFlag = true
    end
    task.wait(0.05)
    activeThreads = {}
end

local function startEggThread(plotId, slot, delay)
    local ctrl = { stopFlag = false }
    activeThreads[slot] = ctrl
    task.spawn(function()
        while not ctrl.stopFlag do
            purchaseEgg(plotId, slot)
            local t = 0
            while t < delay and not ctrl.stopFlag do
                task.wait(0.05)
                t = t + 0.05
            end
        end
        if PRINT_VERBOSE then
            print(('🛑 Dừng thread trứng #%d'):format(slot))
        end
    end)
end

-- TỰ ĐỘNG CHỌN TIER THEO AMOUNT
local function getTier(amount)
    if not amount then
        return 1
    end
    if amount < 1000 then
        return 1
    elseif amount > 2000 then
        return 2
    elseif amount > 4000 then
        return 3
    elseif amount > 8000 then
        return 4
    else
        return 5
    end
end

-- MAIN LOOP
task.spawn(function()
    local currentTier = 0

    while true do
        local plot, amount = findMyPlotAndAmount()
        if not plot then
            print('⏳ Chưa tìm thấy plot, chờ 10s...')
            task.wait(10)
        else
            local plotId = tonumber(plot:GetAttribute('ID'))
                or tonumber(plot.Name)
                or 1
            local tier = getTier(amount)

            if tier ~= currentTier then
                print(
                    ('⚙️ Chuyển sang Tier %d (amount=%.0f)'):format(
                        tier,
                        amount or 0
                    )
                )
                stopAllThreads()

                -- mở house theo tier
                for i = 2, tier do
                    unlockHouse(plotId, i)
                    task.wait(0.1)
                end

                -- mua trứng slot 1 → min(tier,3)
                for slot = 1, math.min(tier, MAX_EGG_SLOT) do
                    startEggThread(plotId, slot, EGG_DELAY)
                end

                currentTier = tier
            end

            task.wait(SIGN_RECHECK_INTERVAL)
        end
    end
end)

-- 🧩 AUTO PET & EGG MANAGER (1-8 = pets, 9-10 = eggs)
local PET_SLOTS = { 1, 2, 3, 4, 5, 6, 7, 8 }
local EGG_SLOTS = { 9, 10 }
local UPDATE_INTERVAL = 0.25

local Rep = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local player = Players.LocalPlayer
local Network = Rep.Network

local Save = require(Rep.Library.Client.Save)
local Items = require(Rep.Library.Items)
local HPillarItems = require(Rep.Library.Directory.HPillarItems)

------------------------------------------------------------
-- 🔢 Chuyển đổi "1.17k", "2.3M", "405" → số thực chuẩn
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

    local multipliers = {
        k = 1e3,
        m = 1e6,
        b = 1e9,
        t = 1e12,
        q = 1e15,
    }

    return num * (multipliers[suffix] or 1)
end

------------------------------------------------------------
-- 🐾 Lấy toàn bộ pet trong balo (theo power)
------------------------------------------------------------
local function getInventoryPets()
    local data = Save.Get()
    local inv = data and data.Inventory and data.Inventory.HPillar
    local pets, mapByUid = {}, {}

    if inv then
        for uid, info in pairs(inv) do
            local id = info.id or (info._data and info._data.id) or uid
            local base
            if type(HPillarItems) == 'function' then
                local ok, res = pcall(HPillarItems, id)
                if ok then
                    base = res
                end
            else
                base = HPillarItems[id]
            end

            if base then
                local power = base.BaseMoneyPerSecond
                    or base.MoneyPerSecond
                    or 0
                local display = base.DisplayName or base.name or id
                local amount = info._am or 1
                local entry = {
                    uid = uid,
                    id = id,
                    name = display,
                    power = power,
                    amount = amount,
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
-- 🧱 Lấy danh sách pet hiện đang đặt
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
                if
                    foundModel:FindFirstChild(uid)
                    and foundModel[uid]:FindFirstChild('HalloweenPet')
                then
                    petModel = foundModel[uid].HalloweenPet
                end

                if petModel then
                    for _, obj in pairs(petModel:GetDescendants()) do
                        if
                            obj:IsA('TextLabel')
                            and (
                                obj.Text:find('/s')
                                or obj.Name:lower():find('rate')
                            )
                        then
                            local rateText = obj.Text:match(
                                '([%d%a%.]+)%s*/%s*s'
                            ) or obj.Text
                            if rateText then
                                rate = parseRate(rateText)
                                break
                            end
                        end
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
-- 🐣 Gỡ pet ở ô 9–10 khi trứng nở
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
-- 🥚 Đặt trứng ngẫu nhiên vào slot trống (9,10)
------------------------------------------------------------
local function autoPlaceEggs()
    local data = Save.Get()
    local invEggs = data and data.Inventory and data.Inventory.EggHalloween
    if not invEggs then
        return
    end

    local eggs = {}
    for uid, egg in pairs(invEggs) do
        local eggId = egg.id or (egg.data and egg.data.id)
        if eggId then
            local amount = (egg._am or (egg.data and egg.data._am)) or 1
            for i = 1, amount do
                table.insert(eggs, eggId)
            end
        end
    end
    if #eggs == 0 then
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
            local pick = eggs[math.random(1, #eggs)]
            print('🥚 Placing new egg:', pick, '→ slot', slot)
            pcall(function()
                Network.HalloweenWorld_PlaceEgg:InvokeServer(slot, pick)
            end)
            task.wait()
        end
    end
end

------------------------------------------------------------
-- 🐾 Đặt hoặc thay pet mạnh nhất
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

    -- Nếu slot trống → đặt pet mạnh nhất
    for _, slot in ipairs(PET_SLOTS) do
        if not placedBySlot[slot] then
            local best = invPets[1]
            if best then
                print(
                    '✨ Placing pet:',
                    best.name,
                    '(' .. best.uid .. ') → slot',
                    slot
                )
                pcall(function()
                    Network.HalloweenWorld_PlacePet:InvokeServer(slot, best.uid)
                end)
                task.wait()
                return
            end
        end
    end

    -- Nếu pet yếu → thay bằng pet mạnh hơn
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
        task.wait(1)
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
