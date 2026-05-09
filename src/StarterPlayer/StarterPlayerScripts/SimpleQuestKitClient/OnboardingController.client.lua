local StarterGui = game:GetService("StarterGui")

task.delay(4, function()
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Simple Quest Kit",
            Text = "Open Quests or talk to the Guide NPC to begin.",
            Duration = 5,
        })
    end)
end)

print("[SimpleQuestKit] OnboardingController loaded")
