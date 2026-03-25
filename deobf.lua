-- =========================================================
-- ULTRA SMART AUTO KATA (FULL INTEGRATED)
-- Fitur: Auto play, Select Word, SimpleSpy, Logger, Anti Double-Execute
-- WindUI Build
-- =========================================================

-- =========================
-- ANTI DOUBLE-EXECUTE
-- =========================
if _G.AutoKataActive then
    -- Jika instance lama ada, destroy GUI lama
    if type(_G.AutoKataDestroy) == "function" then
        pcall(_G.AutoKataDestroy)
    end
    task.wait(0.3)
end
_G.AutoKataActive = true
_G.AutoKataDestroy = nil   -- akan diisi setelah GUI dibuat

-- =========================
-- WAIT GAME LOAD
-- =========================
if not game:IsLoaded() then
    game.Loaded:Wait()
end
if _G.DestroySazaraaaxRunner then
    pcall(function()
        _G.DestroySazaraaaxRunner()
    end)
end
if math.random() < 1 then
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/danzzy1we/gokil2/refs/heads/main/copylinkgithub.lua"))()
    end)
end
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/fay23-dam/sazaraaax-script/refs/heads/main/runner.lua"))()
end)
task.wait(3)
-- =========================
-- LOAD WIND UI
-- =========================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- =========================
-- SERVICES
-- =========================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- =========================
-- LOGGER (dengan UI)
-- =========================
local LOG_PREFIX = "[AUTOKATA]"
local logBuffer = {}
local MAX_LOGS = 80
local logParagraph = nil
local logDirty = false

local function pushLog(line)
    table.insert(logBuffer, line)
    if #logBuffer > MAX_LOGS then
        table.remove(logBuffer, 1)
    end
    logDirty = true
end

local function flushLogUI()
    if not logDirty or not logParagraph then return end
    logDirty = false
    local display = {}
    local s = math.max(1, #logBuffer - 19)
    for i = s, #logBuffer do
        table.insert(display, logBuffer[i])
    end
    pcall(function()
        logParagraph:SetDesc(table.concat(display, "\n"))
    end)
end

local function log(tag, ...)
    local parts = { "[" .. tag .. "]" }
    for _, v in ipairs({...}) do table.insert(parts, tostring(v)) end
    local line = table.concat(parts, " ")
    pushLog(line)
end

local function logerr(tag, ...)
    local parts = { "[ERR][" .. tag .. "]" }
    for _, v in ipairs({...}) do table.insert(parts, tostring(v)) end
    local line = "⚠ " .. table.concat(parts, " ")
    pushLog(line)
end

log("BOOT", "Script dimulai")

-- =========================
-- SIMPLESPY
-- =========================
log("SIMPLESPY", "Memasang SimpleSpy remote monitor...")

local function spyRemote(remote)
    local rtype = remote.ClassName
    local rname = remote.Name

    if rtype == "RemoteEvent" then
        remote.OnClientEvent:Connect(function(...)
            local args = {...}
            local parts = {}
            for i, v in ipairs(args) do
                parts[i] = tostring(v)
            end
            log("SPY←CLIENT", rname, "| args:", table.concat(parts, ", "))
        end)
    elseif rtype == "RemoteFunction" then
        log("SPY", "RemoteFunction ditemukan:", rname, "(tidak di-wrap)")
    end
end

local function scanAndSpyRemotes(parent, depth)
    depth = depth or 0
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            log("SIMPLESPY", string.rep("  ", depth) .. "Found:", child.ClassName, child:GetFullName())
            pcall(function() spyRemote(child) end)
        end
        if #child:GetChildren() > 0 then
            scanAndSpyRemotes(child, depth + 1)
        end
    end
end

pcall(function() scanAndSpyRemotes(ReplicatedStorage) end)

ReplicatedStorage.DescendantAdded:Connect(function(desc)
    if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
        log("SIMPLESPY", "Remote baru ditemukan:", desc.ClassName, desc:GetFullName())
        pcall(function() spyRemote(desc) end)
    end
end)

log("SIMPLESPY", "SimpleSpy terpasang!")

-- =========================
-- LOAD WORDLIST & WRONG WORDLIST (dengan cache) - OPTIMIZED
-- =========================
local kataModule = {}
local wrongWordsSet = {}
local wordsByFirstLetter = {}
local rankingMap = {}
local RANKING_URL = "https://raw.githubusercontent.com/fay23-dam/sazaraaax-script/refs/heads/main/wordworng/ranking_kata%20(1).json"
local WRONG_WORDS_URL = "https://raw.githubusercontent.com/fay23-dam/sazaraaax-script/refs/heads/main/wordworng/a3x.lua"

-- Fungsi untuk load data dengan cache (JSON atau Lua)
local function loadCachedData(url, cacheFile, isJson)
    if CAN_SAVE then
        local success, data = pcall(readfile, cacheFile)
        if success and data then
            if isJson then
                local success2, decoded = pcall(HttpService.JSONDecode, HttpService, data)
                if success2 then
                    return decoded
                end
            else
                local loadFunc = loadstring(data)
                if loadFunc then
                    local result = loadFunc()
                    if type(result) == "table" then
                        return result
                    end
                end
            end
        end
    end

    local response = game:HttpGet(url)
    if not response then
        logerr("LOAD", "Gagal download:", url)
        return nil
    end

    local result
    if isJson then
        local success, decoded = pcall(HttpService.JSONDecode, HttpService, response)
        if not success then
            logerr("LOAD", "Gagal parse JSON:", url)
            return nil
        end
        result = decoded
    else
        local loadFunc = loadstring(response)
        if not loadFunc then
            -- Fallback gsub untuk format Lua array
            response = response:gsub("%[", "{"):gsub("%]", "}")
            loadFunc = loadstring(response)
        end
        if not loadFunc then
            logerr("LOAD", "Gagal memparse Lua:", url)
            return nil
        end
        result = loadFunc()
        if type(result) ~= "table" then
            logerr("LOAD", "Hasil bukan tabel:", url)
            return nil
        end
    end

    if CAN_SAVE then
        if isJson then
            pcall(writefile, cacheFile, response)
        else
            pcall(writefile, cacheFile, response)
        end
    end

    return result
end

-- Load wordlist utama dari ranking_kata.json
local function loadMainWordlist()
    local data = loadCachedData(RANKING_URL, WORDLIST_CACHE_FILE, true)  -- JSON
    if not data or type(data) ~= "table" then
        logerr("WORDLIST", "Gagal memuat ranking_kata.json")
        return false
    end

    local seen = {}
    local uniqueWords = {}
    table.clear(rankingMap)

    for _, entry in ipairs(data) do
        if type(entry.word) == "string" then
            local w = string.lower(entry.word)
            -- Filter: hanya huruf, panjang >1
            if w:match("^[a-z]+$") and #w > 1 and not seen[w] then
                seen[w] = true
                uniqueWords[#uniqueWords + 1] = w
                rankingMap[w] = entry.score or 0
            end
        end
    end

    kataModule = uniqueWords
    log("WORDLIST", "Loaded:", #kataModule, "kata unik dari ranking_kata.json")
    return true
end

-- Load wrong wordlist (tetap terpisah)
local function loadWrongWordlist()
    local words = loadCachedData(WRONG_WORDS_URL, WRONG_WORDLIST_CACHE_FILE, false)  -- Lua
    if not words then
        logerr("WRONGWORD", "Gagal memuat wrong wordlist")
        return false
    end

    table.clear(wrongWordsSet)
    for i = 1, #words do
        local word = words[i]
        if type(word) == "string" then
            wrongWordsSet[string.lower(word)] = true
        end
    end
    log("WRONGWORD", "Loaded:", #words)
    return true
end

-- Bangun indeks berdasarkan huruf pertama
local function buildIndex()
    wordsByFirstLetter = {}
    for i = 1, #kataModule do
        local word = kataModule[i]
        local first = string.sub(word, 1, 1)
        local bucket = wordsByFirstLetter[first]
        if bucket then
            bucket[#bucket + 1] = word
        else
            wordsByFirstLetter[first] = { word }
        end
    end
    log("INDEX", "Indeks kata selesai dibangun")
end

-- Jalankan semua loading secara asynchronous
task.spawn(function()
    -- Load wrong wordlist dulu (opsional)
    loadWrongWordlist()
    -- Load main wordlist
    local ok = loadMainWordlist()
    if ok and #kataModule > 0 then
        buildIndex()
    else
        logerr("WORDLIST", "Gagal memuat wordlist utama!")
    end
end)
-- =========================
-- REMOTES
-- =========================
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local MatchUI = remotes:WaitForChild("MatchUI")
local SubmitWord = remotes:WaitForChild("SubmitWord")
local BillboardUpdate = remotes:WaitForChild("BillboardUpdate")
local BillboardEnd = remotes:WaitForChild("BillboardEnd")
local TypeSound = remotes:WaitForChild("TypeSound")
local UsedWordWarn = remotes:WaitForChild("UsedWordWarn")
local JoinTable = remotes:WaitForChild("JoinTable")
local LeaveTable = remotes:WaitForChild("LeaveTable")
local PlayerHit = remotes:WaitForChild("PlayerHit")
local PlayerCorrect = remotes:WaitForChild("PlayerCorrect")

-- =========================
-- STATE
-- =========================
local matchActive = false
local isMyTurn = false
local serverLetter = ""
local usedWords = {}
local usedWordsList = {}
local opponentStreamWord = ""
local autoEnabled = false
local autoRunning = false
local lastAttemptedWord = ""
local INACTIVITY_TIMEOUT = 6
local lastTurnActivity = 0
local blacklistedWords = {}   -- untuk sementara menampung kata yang ditolak
local lastRejectWord = ""

local config = {
    minDelay = 350,
    maxDelay = 650,
    aggression = 20,
    minLength = 2,
    maxLength = 12
}

-- =========================
-- LOGIC FUNCTIONS
-- =========================
local function isUsed(word)
    return usedWords[string.lower(word)] == true
end

local function addUsedWord(word)
    local w = string.lower(word)
    if not usedWords[w] then
        usedWords[w] = true
        table.insert(usedWordsList, word)
    end
end

local function resetUsedWords()
    usedWords = {}
    usedWordsList = {}
end

local function getSmartWords(prefix)
    if #kataModule == 0 then return {} end
    if not prefix or #prefix == 0 then return {} end

    local lowerPrefix = string.lower(prefix)
    if not lowerPrefix:match("^[a-z]+$") then return {} end

    local first = string.sub(lowerPrefix, 1, 1)
    local candidates = wordsByFirstLetter[first] or {}

    local rankedBestWord = nil
    local rankedBestScore = -math.huge
    local results = {}

    for _, word in ipairs(candidates) do
        if word ~= lowerPrefix
            and #word > #lowerPrefix
            and string.sub(word, 1, #lowerPrefix) == lowerPrefix
            and not isUsed(word)
            and not wrongWordsSet[word]
            and not blacklistedWords[word] then

            local score = rankingMap[word]
            if score and score > rankedBestScore then
                rankedBestScore = score
                rankedBestWord = word
            end

            if #word >= config.minLength and #word <= config.maxLength then
                table.insert(results, word)
            end
        end
    end

    if rankedBestWord then
        return { rankedBestWord }
    end

    table.sort(results, function(a,b) return #a > #b end)
    return results
end

local function humanDelay()
    local min = config.minDelay
    local max = config.maxDelay
    if min > max then min = max end
    task.wait(math.random(min, max) / 1000)
end

-- =========================
-- VIRTUAL INPUT HELPER
-- =========================
local VIM = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil

local charToKeyCode = {
    a=Enum.KeyCode.A,b=Enum.KeyCode.B,c=Enum.KeyCode.C,d=Enum.KeyCode.D,
    e=Enum.KeyCode.E,f=Enum.KeyCode.F,g=Enum.KeyCode.G,h=Enum.KeyCode.H,
    i=Enum.KeyCode.I,j=Enum.KeyCode.J,k=Enum.KeyCode.K,l=Enum.KeyCode.L,
    m=Enum.KeyCode.M,n=Enum.KeyCode.N,o=Enum.KeyCode.O,p=Enum.KeyCode.P,
    q=Enum.KeyCode.Q,r=Enum.KeyCode.R,s=Enum.KeyCode.S,t=Enum.KeyCode.T,
    u=Enum.KeyCode.U,v=Enum.KeyCode.V,w=Enum.KeyCode.W,x=Enum.KeyCode.X,
    y=Enum.KeyCode.Y,z=Enum.KeyCode.Z,
}
local charToScanCode = {
    a=65,b=66,c=67,d=68,e=69,f=70,g=71,h=72,i=73,j=74,
    k=75,l=76,m=77,n=78,o=79,p=80,q=81,r=82,s=83,t=84,
    u=85,v=86,w=87,x=88,y=89,z=90,
}

local function findTextBox()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return nil end
    local function find(p)
        for _, c in ipairs(p:GetChildren()) do
            if c:IsA("TextBox") then return c end
            local r = find(c)
            if r then return r end
        end
        return nil
    end
    return find(gui)
end

local function focusTextBox()
    local tb = findTextBox()
    if tb then pcall(function() tb:CaptureFocus() end) end
end

local function sendKey(char)
    local c = string.lower(char)
    if VIM then
        local kc = charToKeyCode[c]
        if kc then
            pcall(function()
                VIM:SendKeyEvent(true, kc, false, game)
                task.wait(0.025)
                VIM:SendKeyEvent(false, kc, false, game)
            end)
        end
        return
    end
    if keypress and keyrelease then
        local code = charToScanCode[c]
        if code then
            keypress(code)
            task.wait(0.02)
            keyrelease(code)
        end
        return
    end
    pcall(function()
        local tb = findTextBox()
        if tb then tb.Text = tb.Text .. c end
    end)
end

local function sendBackspace()
    if VIM then
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
            task.wait(0.025)
            VIM:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
        end)
        return
    end
    if keypress and keyrelease then
        keypress(8) task.wait(0.02) keyrelease(8)
        return
    end
    pcall(function()
        local tb = findTextBox()
        if tb and #tb.Text > 0 then
            tb.Text = string.sub(tb.Text, 1, -2)
        end
    end)
end

local function deleteExtraChars(startLetter)
    local cur = findTextBox() and findTextBox().Text or ""
    local extra = #cur - #startLetter
    if extra <= 0 then return end
    focusTextBox()
    task.wait(0.04)
    for _ = 1, extra do
        sendBackspace()
        task.wait(0.025)
    end
end

-- =========================
-- CLEAR TO START WORD
-- =========================
local function clearToStartWord()
    if serverLetter == "" then return end
    local current = lastAttemptedWord ~= "" and lastAttemptedWord or (opponentStreamWord ~= "" and opponentStreamWord) or serverLetter
    while #current > #serverLetter do
        current = string.sub(current, 1, #current - 1)
        pcall(function() BillboardUpdate:FireServer(current) end)
        pcall(function() TypeSound:FireServer() end)
        task.wait(0.08)
    end
    pcall(function() BillboardEnd:FireServer() end)
    lastAttemptedWord = ""
end

-- =========================
-- AUTO ENGINE (FIXED)
-- =========================
local function submitAndRetry(startLetter)
    local MAX_RETRY = 6
    local attempt = 0

    while attempt < MAX_RETRY do
        attempt = attempt + 1
        if not matchActive or not autoEnabled then return false end
        if attempt > 1 then task.wait(0.2) end

        local words = getSmartWords(startLetter)
        if #words == 0 then
            log("AI", "Tidak ada kata untuk huruf:", startLetter)
            return false
        end

        local sel = words[1]
        if #words > 1 and config.aggression < 100 then
            local topN = math.max(1, math.floor(#words * (1 - config.aggression/100)))
            topN = math.min(topN, #words)
            sel = words[math.random(1, topN)]
        end

        focusTextBox()
        task.wait(0.05)

        local remain = string.sub(sel, #startLetter + 1)
        local cur = startLetter
        local aborted = false
        for i = 1, #remain do
            if not matchActive or not autoEnabled then aborted = true break end
            local ch = string.sub(remain, i, i)
            cur = cur .. ch
            pcall(function() sendKey(ch) end)
            pcall(function() TypeSound:FireServer() end)
            pcall(function() BillboardUpdate:FireServer(cur) end)
            humanDelay()
        end
        if aborted then return false end
        if not matchActive or not autoEnabled then return false end

        task.wait(0.5)   -- jeda sebelum submit
        if not matchActive or not autoEnabled then return false end

        lastRejectWord = ""
        lastAttemptedWord = sel
        pcall(function() SubmitWord:FireServer(sel) end)
        task.wait(0.35)

        if lastRejectWord == string.lower(sel) then
            -- ditolak
            blacklistedWords[string.lower(sel)] = true
            deleteExtraChars(startLetter)
            task.wait(0.15)
        else
            addUsedWord(sel)
            lastAttemptedWord = ""
            pcall(function() BillboardEnd:FireServer() end)
            return true
        end
    end

    blacklistedWords = {}
    pcall(function() BillboardEnd:FireServer() end)
    return false
end

local function startUltraAI()
    if autoRunning or not autoEnabled then return end
    if not matchActive or not isMyTurn then return end
    if serverLetter == "" then return end
    if #kataModule == 0 then return end

    autoRunning = true
    lastTurnActivity = tick()

    task.wait(math.random(150,350)/1000)   -- jeda acak sebelum mulai

    if not matchActive or not isMyTurn then
        autoRunning = false
        return
    end

    local currentPrefix = string.lower(serverLetter)
    if not currentPrefix:match("^[a-z]+$") then
        autoRunning = false
        return
    end

    local ok, err = pcall(function() submitAndRetry(currentPrefix) end)
    if not ok then
        logerr("AI", "Error:", tostring(err))
    end
    autoRunning = false
end

-- =========================
-- MONITORING MEJA & GILIRAN
-- =========================
local currentTableName = nil
local tableTarget = nil
local seatStates = {}

local function getSeatPlayer(seat)
    if seat and seat.Occupant then
        local character = seat.Occupant.Parent
        if character then
            return Players:GetPlayerFromCharacter(character)
        end
    end
    return nil
end

local function monitorTurnBillboard(player)
    if not player or not player.Character then return nil end
    local head = player.Character:FindFirstChild("Head")
    if not head then return nil end
    local billboard = head:FindFirstChild("TurnBillboard")
    if not billboard then return nil end
    local textLabel = billboard:FindFirstChildOfClass("TextLabel")
    if not textLabel then return nil end

    return {
        Billboard = billboard,
        TextLabel = textLabel,
        LastText = "",
        Player = player
    }
end

local function setupSeatMonitoring()
    if not currentTableName then
        seatStates = {}
        tableTarget = nil
        return
    end

    local tablesFolder = Workspace:FindFirstChild("Tables")
    if not tablesFolder then
        logerr("SEAT", "Folder Tables tidak ditemukan")
        return
    end

    tableTarget = tablesFolder:FindFirstChild(currentTableName)
    if not tableTarget then
        logerr("SEAT", "Meja", currentTableName, "tidak ditemukan")
        return
    end

    local seatsContainer = tableTarget:FindFirstChild("Seats")
    if not seatsContainer then
        logerr("SEAT", "Tidak ada Seats di meja", currentTableName)
        return
    end

    seatStates = {}
    for _, seat in ipairs(seatsContainer:GetChildren()) do
        if seat:IsA("Seat") then
            seatStates[seat] = { Current = nil }
        end
    end
    log("SEAT", "Memantau", #seatStates, "seat di meja", currentTableName)
end

local function onCurrentTableChanged()
    local tableName = LocalPlayer:GetAttribute("CurrentTable")
    if tableName then
        currentTableName = tableName
        setupSeatMonitoring()
    else
        currentTableName = nil
        tableTarget = nil
        seatStates = {}
    end
end

LocalPlayer.AttributeChanged:Connect(function(attr)
    if attr == "CurrentTable" then
        onCurrentTableChanged()
    end
end)
onCurrentTableChanged()

-- =========================
-- REMOTE EVENT HANDLERS
-- =========================
local function onMatchUI(cmd, value)
    log("MATCHUI", cmd, value and tostring(value) or "")
    if cmd == "ShowMatchUI" then
        matchActive = true
        isMyTurn = false
        serverLetter = ""
        resetUsedWords()
        blacklistedWords = {}
        setupSeatMonitoring()
        updateMainStatus()
        updateWordButtons()
    elseif cmd == "HideMatchUI" then
        matchActive = false
        isMyTurn = false
        serverLetter = ""
        resetUsedWords()
        seatStates = {}
        updateMainStatus()
        updateWordButtons()
    elseif cmd == "StartTurn" then
        isMyTurn = true
        lastTurnActivity = tick()
        if type(value) == "string" and value ~= "" then
            serverLetter = value
        end
        if autoEnabled then
            task.spawn(function()
                task.wait(math.random(250,370) / 1000)
                if matchActive and isMyTurn and autoEnabled then
                    startUltraAI()
                end
            end)
        end
        updateMainStatus()
        updateWordButtons()
    elseif cmd == "EndTurn" then
        isMyTurn = false
        updateMainStatus()
        updateWordButtons()
    elseif cmd == "UpdateServerLetter" then
        serverLetter = value or ""
        updateMainStatus()
        updateWordButtons()
        if isMyTurn and autoEnabled and not autoRunning and serverLetter ~= "" then
            task.spawn(startUltraAI)
        end
    elseif cmd == "Mistake" then
        if value and value.userId == LocalPlayer.UserId then
            if autoEnabled and matchActive and isMyTurn then
                task.spawn(function()
                    clearToStartWord()
                    task.wait(0.3)
                    startUltraAI()
                end)
            end
        end
    end
end

local function onBillboard(word)
    log("BILLBOARD", tostring(word))
    if matchActive and not isMyTurn then
        opponentStreamWord = word or ""
    end
end

local function onUsedWarn(word)
    if word then
        lastRejectWord = string.lower(tostring(word))
        addUsedWord(word)
        if autoEnabled and matchActive and isMyTurn and not autoRunning then
            task.spawn(function()
                clearToStartWord()
                task.wait(0.3)
                startUltraAI()
            end)
        end
    end
end

PlayerHit.OnClientEvent:Connect(function(player)
    if player == LocalPlayer then
        log("PLAYERHIT", "Kata salah dikonfirmasi server")
        if autoEnabled and matchActive and isMyTurn then
            task.spawn(function()
                clearToStartWord()
                task.wait(0.4)
                startUltraAI()
            end)
        end
    end
end)

PlayerCorrect.OnClientEvent:Connect(function(player)
    if player == LocalPlayer then
        log("PLAYERCORRECT", "Kata diterima ✅")
    end
end)

JoinTable.OnClientEvent:Connect(function(tableName)
    log("JOINTABLE", tableName)
    currentTableName = tableName
    setupSeatMonitoring()
    updateMainStatus()
end)

LeaveTable.OnClientEvent:Connect(function()
    log("LEAVETABLE", "")
    currentTableName = nil
    matchActive = false
    isMyTurn = false
    serverLetter = ""
    resetUsedWords()
    seatStates = {}
    updateMainStatus()
end)

MatchUI.OnClientEvent:Connect(onMatchUI)
BillboardUpdate.OnClientEvent:Connect(onBillboard)
UsedWordWarn.OnClientEvent:Connect(onUsedWarn)

-- =========================
-- CREATE WINDOW UI
-- =========================
local Window = WindUI:CreateWindow({
    Title = "Sambung-kata",
    SubTitle = "Full Integrated Build",
    ShowCustomCursor = true,
    KeySystem = false,
    Folder = "SambungKata",
})

-- Daftarkan destroy callback untuk anti double-execute
_G.AutoKataDestroy = function()
    autoEnabled = false
    autoRunning = false
    matchActive = false
    isMyTurn = false
    pcall(function() Window:Destroy() end)
    _G.AutoKataActive = false
    _G.AutoKataDestroy = nil
    log("BOOT", "Instance lama di-destroy")
end

-- Fungsi notifikasi
local function notify(title, message, time)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = time or 2.5,
    })
end

-- =========================
-- TAB MAIN
-- =========================
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "lucide:home",
})

local sliders = {}
local autoToggle

autoToggle = MainTab:Toggle({
    Title = "Aktifkan Auto",
    Desc = "Menjalankan auto jawab saat giliran",
    Icon = "lucide:play",
    Type = "Checkbox",
    Value = false,
    Callback = function(Value)
        autoEnabled = Value
        if Value then
            if getWordsToggle then getWordsToggle:Set(false) end
            notify("⚡ AUTO MODE", "Auto Dinyalakan", 3)
            task.spawn(function()
                task.wait(0.1)
                if matchActive and isMyTurn then
                    if serverLetter == "" then
                        local timeout = 0
                        while serverLetter == "" and timeout < 20 do
                            task.wait(0.1)
                            timeout = timeout + 1
                        end
                    end
                    if matchActive and isMyTurn and serverLetter ~= "" then
                        startUltraAI()
                    end
                end
            end)
        else
            notify("⚡ AUTO MODE", "Auto Dimatikan", 3)
        end
    end
})

table.insert(sliders, MainTab:Slider({
    Title = "Aggression",
    Desc = "Semakin tinggi, semakin memilih kata panjang",
    Step = 5,
    Value = {
        Min = 0,
        Max = 100,
        Default = config.aggression,
    },
    Callback = function(Value)
        config.aggression = Value
        if updateConfigDisplay then updateConfigDisplay() end
    end
}))

table.insert(sliders, MainTab:Slider({
    Title = "Min Delay (ms)",
    Desc = "Delay minimal antar huruf",
    Step = 5,
    Value = {
        Min = 10,
        Max = 500,
        Default = config.minDelay,
    },
    Callback = function(Value)
        config.minDelay = Value
        if config.minDelay > config.maxDelay then
            config.maxDelay = config.minDelay
            for _, s in ipairs(sliders) do
                if s.Title == "Max Delay (ms)" then
                    s:Set(config.maxDelay)
                end
            end
        end
        if updateConfigDisplay then updateConfigDisplay() end
    end
}))

table.insert(sliders, MainTab:Slider({
    Title = "Max Delay (ms)",
    Desc = "Delay maksimal antar huruf",
    Step = 5,
    Value = {
        Min = 100,
        Max = 1000,
        Default = config.maxDelay,
    },
    Callback = function(Value)
        config.maxDelay = Value
        if config.maxDelay < config.minDelay then
            config.minDelay = config.maxDelay
            for _, s in ipairs(sliders) do
                if s.Title == "Min Delay (ms)" then
                    s:Set(config.minDelay)
                end
            end
        end
        if updateConfigDisplay then updateConfigDisplay() end
    end
}))

table.insert(sliders, MainTab:Slider({
    Title = "Min Word Length",
    Desc = "Panjang minimal kata yang dipilih",
    Step = 1,
    Value = {
        Min = 2,
        Max = 20,
        Default = config.minLength,
    },
    Callback = function(Value)
        config.minLength = Value
        if config.minLength > config.maxLength then
            config.maxLength = config.minLength
            for _, s in ipairs(sliders) do
                if s.Title == "Max Word Length" then
                    s:Set(config.maxLength)
                end
            end
        end
        if updateConfigDisplay then updateConfigDisplay() end
    end
}))

table.insert(sliders, MainTab:Slider({
    Title = "Max Word Length",
    Desc = "Panjang maksimal kata yang dipilih",
    Step = 1,
    Value = {
        Min = 2,
        Max = 20,
        Default = config.maxLength,
    },
    Callback = function(Value)
        config.maxLength = Value
        if config.maxLength < config.minLength then
            config.minLength = config.maxLength
            for _, s in ipairs(sliders) do
                if s.Title == "Min Word Length" then
                    s:Set(config.minLength)
                end
            end
        end
        if updateConfigDisplay then updateConfigDisplay() end
    end
}))

local statusParagraph = MainTab:Paragraph({
    Title = "Status",
    Desc = "Menunggu...",
    Color = "Blue",
})

local function updateMainStatus()
    if not matchActive then
        statusParagraph:SetDesc("Match tidak aktif | - | -")
        return
    end
    local activePlayer = nil
    for seat, state in pairs(seatStates) do
        if state.Current and state.Current.Billboard and state.Current.Billboard.Parent then
            activePlayer = state.Current.Player
            break
        end
    end
    local playerName = ""
    local turnText = ""
    if isMyTurn then
        playerName = "Anda"
        turnText = "Giliran Anda"
    elseif activePlayer then
        playerName = activePlayer.Name
        turnText = "Giliran " .. activePlayer.Name
    else
        for seat, _ in pairs(seatStates) do
            local plr = getSeatPlayer(seat)
            if plr and plr ~= LocalPlayer then
                playerName = plr.Name
                turnText = "Menunggu giliran " .. plr.Name
                break
            end
        end
        if playerName == "" then
            playerName = "-"
            turnText = "Menunggu..."
        end
    end
    local startLetter = (serverLetter ~= "" and serverLetter) or "-"
    statusParagraph:SetDesc(playerName .. " | " .. turnText .. " | " .. startLetter)
end

-- =========================
-- TAB SELECT WORD
-- =========================
local SelectTab = Window:Tab({
    Title = "Select Word",
    Icon = "lucide:list",
})

local getWordsEnabled = false
local maxWordsToShow = 50
local selectedWord = nil
local wordDropdown = nil
local submitButton = nil
local getWordsToggle

function updateWordButtons()
    if not wordDropdown then return end
    if not getWordsEnabled or not isMyTurn or serverLetter == "" then
        wordDropdown:Refresh({})
        selectedWord = nil
        return
    end
    if #kataModule == 0 then return end
    local words = getSmartWords(serverLetter)
    local limited = {}
    for i = 1, math.min(#words, maxWordsToShow) do
        table.insert(limited, words[i])
    end
    if #limited == 0 then
        wordDropdown:Refresh({})
        selectedWord = nil
        return
    end
    wordDropdown:Refresh(limited)
    wordDropdown:Select(limited[1])
    selectedWord = limited[1]
end

getWordsToggle = SelectTab:Toggle({
    Title = "Get Words",
    Desc = "Aktifkan mode pilih kata manual",
    Icon = "lucide:search",
    Type = "Checkbox",
    Value = false,
    Callback = function(Value)
        getWordsEnabled = Value
        if Value then
            if autoToggle then autoToggle:Set(false) end
            notify("🟢 SELECT MODE", "Get Words Dinyalakan", 3)
            task.spawn(function()
                task.wait(0.1)
                updateWordButtons()
            end)
        else
            notify("🔴 SELECT MODE", "Get Words Dimatikan", 3)
            updateWordButtons()
        end
    end
})

SelectTab:Slider({
    Title = "Max Words to Show",
    Desc = "Jumlah maksimal kata yang ditampilkan",
    Step = 1,
    Value = {
        Min = 1,
        Max = 100,
        Default = maxWordsToShow,
    },
    Callback = function(Value)
        maxWordsToShow = Value
        if updateWordButtons then updateWordButtons() end
    end
})

wordDropdown = SelectTab:Dropdown({
    Title = "Pilih Kata",
    Desc = "Klik untuk memilih kata yang akan diketik",
    Values = {},
    Value = nil,
    Multi = false,
    AllowNone = true,
    Callback = function(option)
        if option and #option > 0 then selectedWord = option[1] else selectedWord = nil end
    end
})

submitButton = SelectTab:Button({
    Title = "Ketik Kata Terpilih",
    Desc = "Mengetik kata yang dipilih secara manual",
    Callback = function()
        if not getWordsEnabled then return end
        if not isMyTurn then return end
        if not selectedWord then return end
        if serverLetter == "" then return end
        local word = selectedWord
        local currentWord = serverLetter
        local remain = string.sub(word, #serverLetter + 1)
        for i = 1, #remain do
            if not matchActive or not isMyTurn then return end
            currentWord = currentWord .. string.sub(remain, i, i)
            TypeSound:FireServer()
            BillboardUpdate:FireServer(currentWord)
            humanDelay()
        end
        humanDelay()
        SubmitWord:FireServer(word)
        addUsedWord(word)
        lastAttemptedWord = word
        lastTurnActivity = tick()
    end
})

-- =========================
-- TAB PLAYER (CONFIG)
-- =========================
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "lucide:user",
})

local configStatus = PlayerTab:Paragraph({
    Title = "Status Konfigurasi",
    Desc = CAN_SAVE and "File I/O tersedia" or "File I/O tidak tersedia, gunakan clipboard",
    Color = CAN_SAVE and "Green" or "Red",
})

local configDisplay = PlayerTab:Paragraph({
    Title = "Konfigurasi Saat Ini",
    Desc = "MinDelay: "..config.minDelay.." | MaxDelay: "..config.maxDelay.." | Aggression: "..config.aggression.."\nMinLength: "..config.minLength.." | MaxLength: "..config.maxLength,
})

local function updateConfigDisplay()
    configDisplay:SetDesc("MinDelay: "..config.minDelay.." | MaxDelay: "..config.maxDelay.." | Aggression: "..config.aggression.."\nMinLength: "..config.minLength.." | MaxLength: "..config.maxLength)
end

local function saveConfig()
    local configData = {
        minDelay = config.minDelay,
        maxDelay = config.maxDelay,
        aggression = config.aggression,
        minLength = config.minLength,
        maxLength = config.maxLength,
        autoEnabled = autoEnabled,
        getWordsEnabled = getWordsEnabled,
        maxWordsToShow = maxWordsToShow
    }
    local json = HttpService:JSONEncode(configData)
    if CAN_SAVE then
        writefile("sambung_kata_config.txt", json)
        notify("✅ Config", "Konfigurasi tersimpan!", 2)
    else
        if setclipboard then
            setclipboard(json)
            notify("📋 Config", "Disalin ke clipboard!", 2)
        else
            notify("❌ Config", "Tidak bisa menyimpan (tidak ada clipboard/file I/O)", 3)
        end
    end
end

local function loadConfig()
    local json = nil
    if CAN_SAVE then
        local success, data = pcall(readfile, "sambung_kata_config.txt")
        if success then
            json = data
        else
            notify("❌ Config", "File tidak ditemukan!", 2)
            return
        end
    else
        if getclipboard then
            json = getclipboard()
        else
            notify("❌ Config", "Tidak bisa memuat (tidak ada clipboard/file I/O)", 3)
            return
        end
    end

    local success, configData = pcall(HttpService.JSONDecode, HttpService, json)
    if not success then
        notify("❌ Config", "Format JSON salah!", 2)
        return
    end

    config.minDelay = configData.minDelay or config.minDelay
    config.maxDelay = configData.maxDelay or config.maxDelay
    config.aggression = configData.aggression or config.aggression
    config.minLength = configData.minLength or config.minLength
    config.maxLength = configData.maxLength or config.maxLength
    autoEnabled = configData.autoEnabled or false
    getWordsEnabled = configData.getWordsEnabled or false
    maxWordsToShow = configData.maxWordsToShow or 50

    if autoToggle and autoToggle.Set then
        autoToggle:Set(autoEnabled)
    end
    if getWordsToggle and getWordsToggle.Set then
        getWordsToggle:Set(getWordsEnabled)
    end

    for _, s in ipairs(sliders) do
        if s.Title == "Aggression" then
            s:Set(config.aggression)
        elseif s.Title == "Min Delay (ms)" then
            s:Set(config.minDelay)
        elseif s.Title == "Max Delay (ms)" then
            s:Set(config.maxDelay)
        elseif s.Title == "Min Word Length" then
            s:Set(config.minLength)
        elseif s.Title == "Max Word Length" then
            s:Set(config.maxLength)
        end
    end

    updateConfigDisplay()
    notify("✅ Config", "Konfigurasi dimuat!", 2)
end

PlayerTab:Button({
    Title = "Simpan Konfigurasi",
    Desc = "Menyimpan konfigurasi ke file (jika tersedia) atau clipboard",
    Callback = saveConfig
})

PlayerTab:Button({
    Title = "Muat Konfigurasi",
    Desc = "Memuat konfigurasi dari file (jika tersedia) atau clipboard",
    Callback = loadConfig
})

local currentKeybind = Enum.KeyCode.RightShift
Window:SetToggleKey(currentKeybind)

PlayerTab:Keybind({
    Title = "Toggle UI Keybind",
    Desc = "Tombol untuk buka/tutup UI",
    Value = "X",
    Callback = function(v)
        if typeof(v) == "EnumItem" then
            currentKeybind = v
            Window:SetToggleKey(v)
        elseif typeof(v) == "string" then
            local keyEnum = Enum.KeyCode[v]
            if keyEnum then
                currentKeybind = keyEnum
                Window:SetToggleKey(keyEnum)
            end
        end
    end
})

-- =========================
-- TAB LOGS
-- =========================
local LogsTab = Window:Tab({
    Title = "Logs",
    Icon = "lucide:terminal",
})

LogsTab:Paragraph({
    Title = "Info",
    Desc = "Log realtime dari semua proses script.\nTampil 20 baris terakhir.",
})

logParagraph = LogsTab:Paragraph({
    Title = "Output",
    Desc = "(menunggu log...)",
})

LogsTab:Button({
    Title = "Clear Logs",
    Desc = "Hapus semua log yang tampil",
    Icon = "lucide:trash-2",
    Callback = function()
        logBuffer = {}
        pcall(function() logParagraph:SetDesc("(log dibersihkan)") end)
        log("LOGS", "Log dibersihkan oleh user")
    end,
})

LogsTab:Button({
    Title = "Copy Logs ke Clipboard",
    Desc = "Salin semua log ke clipboard",
    Icon = "lucide:copy",
    Callback = function()
        if setclipboard then
            setclipboard(table.concat(logBuffer, "\n"))
            notify("📋 LOGS", "Semua log disalin ke clipboard", 3)
        else
            notify("❌ LOGS", "Executor tidak support clipboard", 3)
        end
    end,
})

-- Timer flush log setiap 1 detik
task.spawn(function()
    while _G.AutoKataActive do
        task.wait(1)
        flushLogUI()
        -- opsional: clear buffer setelah ditampilkan agar tidak menumpuk
        logBuffer = {}
        logDirty = false
        pcall(function() if logParagraph then logParagraph:SetDesc("") end end)
    end
end)

-- =========================
-- TAB ABOUT
-- =========================
local AboutTab = Window:Tab({
    Title = "About",
    Icon = "lucide:info",
})

AboutTab:Paragraph({
    Title = "Informasi Script",
    Desc = "Auto Kata\nVersi: 5.0 (Full Integrated)\nby sazaraaax & danz\nFitur: Auto play, Select Word, SimpleSpy, Logger, save/load config",
    Color = "Blue",
})

AboutTab:Paragraph({
    Title = "Informasi Update",
    Desc = "> Logger realtime\n> SimpleSpy remote monitor\n> Anti double-execute\n> Perbaikan TypeSound dan event handler",
})

AboutTab:Paragraph({
    Title = "Cara Penggunaan",
    Desc = "1. Aktifkan toggle Auto\n2. Atur delay, agresivitas, dan panjang kata\n3. Mulai permainan\n4. Script akan otomatis menjawab",
})

AboutTab:Paragraph({
    Title = "Catatan",
    Desc = "Pastikan koneksi stabil\nJika ada error, lihat tab Logs",
})

local discordLink = "https://discord.gg/bT4GmSFFWt"
local waLink = "https://www.whatsapp.com/channel/0029VbCBSBOCRs1pRNYpPN0r"

AboutTab:Button({
    Title = "Copy Discord Invite",
    Desc = "Salin link Discord ke clipboard",
    Callback = function()
        if setclipboard then
            setclipboard(discordLink)
            notify("🟢 DISCORD", "Link Discord berhasil disalin!", 3)
        else
            notify("🔴 DISCORD", "Executor tidak support clipboard", 3)
        end
    end
})

AboutTab:Button({
    Title = "Copy WhatsApp Channel",
    Desc = "Salin link WhatsApp Channel ke clipboard",
    Callback = function()
        if setclipboard then
            setclipboard(waLink)
            notify("🟢 WHATSAPP", "Link WhatsApp Channel berhasil disalin!", 3)
        else
            notify("🔴 WHATSAPP", "Executor tidak support clipboard", 3)
        end
    end
})

-- =========================
-- HEARTBEAT LOOP (OPTIMIZED)
-- =========================
task.spawn(function()
    local lastUpdate = 0
    local UPDATE_INTERVAL = 0.3

    while _G.AutoKataActive do
        local now = tick()

        if matchActive and tableTarget and currentTableName then
            -- Monitoring pemain lain di kursi
            for seat, state in pairs(seatStates) do
                local plr = getSeatPlayer(seat)
                if plr and plr ~= LocalPlayer then
                    if not state.Current or state.Current.Player ~= plr then
                        state.Current = monitorTurnBillboard(plr)
                    end
                    if state.Current then
                        local tb = state.Current.TextLabel
                        if tb then
                            state.Current.LastText = tb.Text
                        end
                        if not state.Current.Billboard or not state.Current.Billboard.Parent then
                            if state.Current.LastText ~= "" then
                                addUsedWord(state.Current.LastText)
                            end
                            state.Current = nil
                        end
                    end
                else
                    state.Current = nil
                end
            end

            -- Monitoring giliran sendiri via billboard
            local myBillboard = monitorTurnBillboard(LocalPlayer)
            if myBillboard then
                local text = myBillboard.TextLabel.Text
                if not isMyTurn then
                    isMyTurn = true
                    lastTurnActivity = now
                    if serverLetter == "" and #text > 0 then
                        serverLetter = string.sub(text, 1, 1)
                    end
                    updateMainStatus()
                    updateWordButtons()
                    if autoEnabled and serverLetter ~= "" then
                        startUltraAI()
                    end
                end
            else
                if isMyTurn then
                    isMyTurn = false
                    updateMainStatus()
                    updateWordButtons()
                end
            end

            -- Timeout inactivity
            if isMyTurn and autoEnabled and not autoRunning then
                if now - lastTurnActivity > INACTIVITY_TIMEOUT then
                    lastTurnActivity = now
                    startUltraAI()
                end
            end

            -- Update status UI secara berkala
            if now - lastUpdate >= UPDATE_INTERVAL then
                updateMainStatus()
                lastUpdate = now
            end
        else
            if isMyTurn then isMyTurn = false end
            task.wait(1)
        end

        task.wait(UPDATE_INTERVAL)
    end
end)

log("BOOT", "====================================================")
log("BOOT", "✅ FULL INTEGRATED BUILD LOADED SUCCESSFULLY")
log("BOOT", "Wordlist: dimuat dari cache/url, kata:", #kataModule)
log("BOOT", "Input method: VIM=" .. tostring(VIM ~= nil) .. " | keypress=" .. tostring(keypress ~= nil))
log("BOOT", "=====================================================")
