local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-------------------------
-- CONFIG
-------------------------

local KEY = "SphynHubFree"

local LOADERS = {
    [130342654546662] = "https://raw.githubusercontent.com/sphynx-byte/Sambung-kata/refs/heads/main/Auto%20type.lua", --sambung kata indo
    [129866685202296] = "https://raw.githubusercontent.com/sphynx-byte/Last-letter/refs/heads/main/(kamus)%20last%20letter.lua", --last letter
    [121864768012064] = "https://raw.githubusercontent.com/sphynx-byte/Rusuh-fish-it/refs/heads/main/rusuh%20fishit.lua", --rusuh fish it
    [103188421562819] = "https://raw.githubusercontent.com/sphynx-byte/Sambung-kata/refs/heads/main/(kamus)%20Sambung%20Kata%20Jawa.lua" -- SK Jawa
}

-------------------------
-- PLACE CHECK
-------------------------

local placeId = game.PlaceId

if not LOADERS[placeId] then
    player:Kick("Game Not Supported!")
    return
end


-------------------------
-- UI KEY SYSTEM KEREN
-------------------------

pcall(function()
    CoreGui:FindFirstChild("SphynKeyUI"):Destroy()
end)

local TweenService = game:GetService("TweenService")

local keyScreen = Instance.new("ScreenGui")
keyScreen.Name = "SphynKeyUI"
keyScreen.Parent = CoreGui
keyScreen.ResetOnSpawn = false

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1,0,1,0)
bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
bg.BackgroundTransparency = 0.4
bg.Parent = keyScreen


local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,0,0,0)
frame.Position = UDim2.new(0.5,0,0.5,0)
frame.AnchorPoint = Vector2.new(0.5,0.5)
frame.BackgroundColor3 = Color3.fromRGB(25,30,45)
frame.Parent = keyScreen

Instance.new("UICorner", frame).CornerRadius = UDim.new(0,20)


TweenService:Create(
    frame,
    TweenInfo.new(0.3,Enum.EasingStyle.Back),
    {Size = UDim2.new(0.35,0,0.4,0)}
):Play()


local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0.25,0)
title.BackgroundTransparency = 1
title.Text = "SPHYN HUB"
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(0,170,255)
title.Parent = frame


local note = Instance.new("TextLabel")
note.Size = UDim2.new(1,0,0.2,0)
note.Position = UDim2.new(0,0,0.25,0)
note.BackgroundTransparency = 1
note.Text = "Enter Key to Continue"
note.TextScaled = true
note.Font = Enum.Font.Gotham
note.TextColor3 = Color3.fromRGB(200,200,200)
note.Parent = frame


local input = Instance.new("TextBox")
input.Size = UDim2.new(0.8,0,0.15,0)
input.Position = UDim2.new(0.1,0,0.5,0)
input.PlaceholderText = "Enter Key"
input.Text = ""
input.BackgroundColor3 = Color3.fromRGB(40,45,70)
input.TextColor3 = Color3.new(1,1,1)
input.TextScaled = true
input.Font = Enum.Font.Gotham
input.Parent = frame

Instance.new("UICorner", input).CornerRadius = UDim.new(0,10)


local button = Instance.new("TextButton")
button.Size = UDim2.new(0.6,0,0.15,0)
button.Position = UDim2.new(0.2,0,0.75,0)
button.Text = "Submit"
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.BackgroundColor3 = Color3.fromRGB(0,140,255)
button.TextColor3 = Color3.new(1,1,1)
button.Parent = frame

Instance.new("UICorner", button).CornerRadius = UDim.new(0,12)


-------------------------
-- SUBMIT
-------------------------

button.MouseButton1Click:Connect(function()

    if input.Text ~= KEY then

        title.Text = "Wrong Key!"
        title.TextColor3 = Color3.fromRGB(255,80,80)

        task.wait(1)

        player:Kick("🔐Wrong Key!!🔑")

        return

    end

    keyScreen:Destroy()

    local url = LOADERS[placeId]

    pcall(function()
        loadstring(game:HttpGet(url))()
    end)

end)
