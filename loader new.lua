local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-------------------------
-- CONFIG
-------------------------

local WEBHOOK = "https://discord.com/api/webhooks/1485503062532689991/QbEgmFTj_lN6qxQ7aIpoen8h5cLScPgHtqOhYJ5rvyCsIlC68LfiHDvCmEYA48YuiKay"
local KEY = "SphynHub"

local LOADERS = {
    [130342654546662] = "https://raw.githubusercontent.com/sphynx-byte/Sambung-kata/refs/heads/main/(kamus)%20sambung%20kata.lua", -- Sambung kata
    [129866685202296] = "https://raw.githubusercontent.com/sphynx-byte/Last-letter/refs/heads/main/(kamus)%20last%20letter.lua", -- Last letter
    [121864768012064] = "https://raw.githubusercontent.com/sphynx-byte/Rusuh-fish-it/refs/heads/main/rusuh%20fishit.lua" -- Fish it
}

-------------------------
-- WEBHOOK
-------------------------

local function sendWebhook(text)

    if WEBHOOK == "" then return end

    local data = {
        content = "",
        embeds = {{
            title = "Loader executed",
            description = text,
            color = 65280
        }}
    }

    pcall(function()
        HttpService:PostAsync(
            WEBHOOK,
            HttpService:JSONEncode(data),
            Enum.HttpContentType.ApplicationJson
        )
    end)

end


-------------------------
-- PLACE CHECK
-------------------------

local placeId = game.PlaceId

if not LOADERS[placeId] then

    player:Kick("Wrong Game")
    return

end


-------------------------
-- GUI KEY
-------------------------

local keyScreen = Instance.new("ScreenGui")
keyScreen.Name = "KiraKeyScreen"
keyScreen.Parent = CoreGui
keyScreen.ResetOnSpawn = false

local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0.45,0,0.4,0)
keyFrame.Position = UDim2.new(0.275,0,0.3,0)
keyFrame.BackgroundColor3 = Color3.fromRGB(20,35,70)
keyFrame.Parent = keyScreen

Instance.new("UICorner", keyFrame)

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1,0,0.25,0)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "Enter Key"
keyTitle.TextScaled = true
keyTitle.Parent = keyFrame

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(0.8,0,0.15,0)
keyInput.Position = UDim2.new(0.1,0,0.55,0)
keyInput.PlaceholderText = "Enter key"
keyInput.Parent = keyFrame

Instance.new("UICorner", keyInput)

local submit = Instance.new("TextButton")
submit.Size = UDim2.new(0.6,0,0.15,0)
submit.Position = UDim2.new(0.2,0,0.75,0)
submit.Text = "Submit"
submit.Parent = keyFrame

Instance.new("UICorner", submit)

-------------------------
-- SUBMIT
-------------------------

submit.MouseButton1Click:Connect(function()

    if keyInput.Text ~= KEY then

        keyTitle.Text = "Wrong Key"

        task.wait(1)

        player:Kick("Wrong Key")

        return

    end

    keyScreen:Destroy()

    sendWebhook(
        "Player: "..player.Name..
        "\nUserId: "..player.UserId..
        "\nPlaceId: "..placeId
    )

    local url = LOADERS[placeId]

    local ok,err = pcall(function()

        loadstring(game:HttpGet(url))()

    end)

end)