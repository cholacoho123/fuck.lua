-- ===============================
-- 🧩 ANTI-AFK SYSTEM (FULL + OPTIMIZED)
-- ===============================

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- Hàm chính chống AFK
function doAntiAFK()
    -- 1️⃣ Vô hiệu hóa Idle Tracking (nếu có)
    pcall(function()
        local PlayerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if PlayerScripts and PlayerScripts:FindFirstChild("Core") then
            local Core = PlayerScripts.Core
            local IdleTracking = Core:FindFirstChild("Idle Tracking")
            if IdleTracking then
                IdleTracking.Enabled = false
                warn("[Anti-AFK] Idle Tracking script disabled")
            end
        end
    end)

    -- 2️⃣ Giả lập input để Roblox nghĩ bạn vẫn hoạt động
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.5)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        print("[Anti-AFK] Sent fake input signal to prevent kick.")
    end)
end

-- Hàm click tự động mẫu (nếu bạn có định nghĩa riêng, có thể bỏ)
function doClick()
    -- thực hiện hành động click hoặc tương tác trong game ở đây
end

-- Hàm xoay camera mẫu (nếu bạn có định nghĩa riêng, có thể bỏ)
function doRotateCamera()
    local cam = workspace.CurrentCamera
    if cam then
        cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(15), 0)
    end
end

-- ===============================
-- Main Loop (120s delay)
-- ===============================
spawn(function()
    while true do
        doAntiAFK()
        doClick()
        doRotateCamera()
        wait(120) -- delay 120 giây giữa các lần thực hiện
    end
end)

print('Anti-AFK + Auto Click + Camera Rotation (120s interval) is running...')
