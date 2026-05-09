local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local DemoConfig = require(ReplicatedStorage:WaitForChild("SimpleQuestKit"):WaitForChild("Config"):WaitForChild("DemoConfig"))
local Debug = DemoConfig.Debug == true

task.delay(4, function()
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Simple Quest Kit",
            Text = "Step 1: Talk to Guide\nStep 2: Collect Coins\nStep 3: Claim Reward",
            Duration = 7,
        })
    end)
end)

if Debug then
    print("[SimpleQuestKit] OnboardingController loaded")
end
