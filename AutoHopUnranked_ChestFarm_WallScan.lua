-- AutoHopUnranked_ChestFarm_WallScan (obf-ready, clean ASCII)
local LOADER_URL  = "https://raw.githubusercontent.com/genryu442/test3/refs/heads/main/AutoHopUnranked_ChestFarm_WallScan.lua"
local LOADER_CODE = 'loadstring(game:HttpGet("' .. LOADER_URL .. '"))()'

local function isStopFlag()
    if getgenv and getgenv().AutoHopLoopStop == true then return true end
    if _G and _G.AutoHopLoopStop == true then return true end
    if _G and _G.__KillSwitch == true then return true end
    return false
end

local function setStopFlag()
    if getgenv then getgenv().AutoHopLoopStop = true end
    _G.AutoHopLoopStop = true
end

local LOOP_MODE = not isStopFlag()
if not LOOP_MODE then
    warn("[Loop] AutoHopLoopStop = true -> mode loop OFF. Diam di lobby.")
end

local QOT = nil
do
    if type(queue_on_teleport) == "function" then QOT = queue_on_teleport
    elseif type(queueonteleport) == "function" then QOT = queueonteleport
    elseif syn and type(syn.queue_on_teleport) == "function" then QOT = syn.queue_on_teleport
    elseif fluxus and type(fluxus.queue_on_teleport) == "function" then QOT = fluxus.queue_on_teleport
    elseif Krnl and type(Krnl.queue_on_teleport) == "function" then QOT = Krnl.queue_on_teleport
    elseif delta and type(delta.queue_on_teleport) == "function" then QOT = delta.queue_on_teleport
    elseif Delta and type(Delta.queue_on_teleport) == "function" then QOT = Delta.queue_on_teleport
    elseif ArceusX and type(ArceusX.queue_on_teleport) == "function" then QOT = ArceusX.queue_on_teleport
    elseif Hydrogen and type(Hydrogen.queue_on_teleport) == "function" then QOT = Hydrogen.queue_on_teleport
    elseif Codex and type(Codex.queue_on_teleport) == "function" then QOT = Codex.queue_on_teleport
    elseif Vega and type(Vega.queue_on_teleport) == "function" then QOT = Vega.queue_on_teleport
    elseif Solara and type(Solara.queue_on_teleport) == "function" then QOT = Solara.queue_on_teleport
    elseif Wave and type(Wave.queue_on_teleport) == "function" then QOT = Wave.queue_on_teleport
    end
end

local lastRequeue = 0
local function requeueSelf()
    if not LOOP_MODE then
        print("[Loop] LOOP_MODE = false -> skip requeue.")
        return false
    end
    if isStopFlag() then
        print("[Loop] STOP aktif (live) -> skip requeue.")
        return false
    end
    if os.clock() - lastRequeue < 1.0 then
        print("[Loop] Anti-dobel: requeue < 1s, skip.")
        return false
    end
    if not QOT then
        warn("[Loop] queue_on_teleport TIDAK tersedia.")
        return false
    end
    local ok, err = pcall(QOT, LOADER_CODE)
    if not ok then
        warn("[Loop] queue_on_teleport gagal: " .. tostring(err))
        return false
    end
    lastRequeue = os.clock()
    print("[Loop] Self requeued via URL.")
    return true
end

if LOOP_MODE then
    requeueSelf()
end

task.spawn(function()
    pcall(function()
        local lp = game:GetService("Players").LocalPlayer
        lp.OnTeleport:Connect(function(state)
            if state == Enum.TeleportState.Started then
                if isStopFlag() then
                    print("[Loop] Teleport STARTED tapi STOP aktif -> skip requeue.")
                    return
                end
                print("[Loop] Teleport STARTED -> requeue.")
                requeueSelf()
            end
        end)
    end)
end)

local function isLobbyPlace()
    if game.PlaceId == 101906032112547 then
        return true
    end
    local ok, svc = pcall(function()
        return game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.4.6"].knit.Services.TeleportManagerService
    end)
    if ok and svc then
        local ok2, v = pcall(function() return svc.RF.IsLobby:InvokeServer() end)
        if ok2 then return v == true end
    end
    return false
end

local IN_LOBBY = isLobbyPlace()

if IN_LOBBY and not LOOP_MODE then
    warn("[AutoHopUnranked] Di Lobby tapi LOOP_MODE = false -> DIAM.")
end

if IN_LOBBY and LOOP_MODE then
    local Players = game:GetService("Players")
    local CollectionService = game:GetService("CollectionService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LP = Players.LocalPlayer

    task.spawn(function()
        while LOOP_MODE and not isStopFlag() do
            local done = false
            pcall(function()
                local sid = LP:GetAttribute("PendingSessionId")
                local ui = LP.PlayerGui:FindFirstChild("UI")
                local fr = ui and ui:FindFirstChild("Frames")
                local rej = fr and fr:FindFirstChild("SessionRejoin")
                if rej and rej.Visible and type(sid) == "string" then
                    print("[LobbyFix] SessionRejoin macet, EndSession langsung: " .. sid)
                    local svc = ReplicatedStorage.Packages._Index["sleitnick_knit@1.4.6"].knit.Services.TeleportManagerService
                    local rf = svc.RF:WaitForChild("EndSession", 5)
                    local s, r = pcall(function() return rf:InvokeServer(sid) end)
                    print("[LobbyFix] EndSession invoke: " .. tostring(s) .. " " .. tostring(r))
                    task.wait(1)
                    for _, n in ipairs({"SessionRejoin", "RejoinConfirm"}) do
                        local f = fr and fr:FindFirstChild(n)
                        if f then f.Visible = false end
                    end
                    done = true
                end
            end)
            task.wait(2)
        end
    end)

    local function log(txt)
        print("[AutoHopUnranked] " .. tostring(txt))
    end

    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    if hrp then
        local function findUnrankedZone()
            local zones = CollectionService:GetTagged("PartyZone")
            for _, z in ipairs(zones) do
                if z:GetAttribute("Ranked") == false
                    and (z:GetAttribute("State") == 0)
                    and ((z:GetAttribute("PlayerCount") or 0) == 0) then
                    return z
                end
            end
            for _, z in ipairs(zones) do
                if z:GetAttribute("Ranked") == false then
                    return z
                end
            end
            return nil
        end

        local zone = findUnrankedZone()
        if zone then
            log("Target: " .. zone:GetFullName())
            hrp.CFrame = zone.CFrame + Vector3.new(0, 3, 0)
            log("Teleport ke Unranked zone...")
            task.wait(2)

            local function isUnrankedSelected(partyUI)
                local ok, v = pcall(function()
                    local icon = partyUI.MapSelect.Unranked:FindFirstChild("SelectIcon", true)
                    return icon and icon.Visible == true
                end)
                return ok and v == true
            end

            pcall(function()
                local pg = LP:WaitForChild("PlayerGui", 5)
                local partyUI = pg:WaitForChild("UI", 5).Frames:WaitForChild("PartyCreate", 5)
                local deadline = os.clock() + 10
                while not partyUI.Visible and os.clock() < deadline do
                    task.wait(0.25)
                end
                pcall(function()
                    partyUI.PartySize.CountFrame.TextBox.Text = "1"
                end)
                if isUnrankedSelected(partyUI) then
                    log("Unranked sudah kepilih.")
                else
                    local mapSelect = partyUI:FindFirstChild("MapSelect")
                    if mapSelect then
                        local unranked = mapSelect:FindFirstChild("Unranked")
                        local ranked = mapSelect:FindFirstChild("Ranked")
                        local selectedWhite = Color3.fromRGB(255, 255, 255)
                        local unselectedGray = Color3.fromRGB(120, 120, 120)
                        for _, btn in ipairs({ unranked, ranked }) do
                            if btn and btn:IsA("ImageButton") then
                                local isUn = (btn == unranked)
                                local icon = btn:FindFirstChild("SelectIcon", true)
                                if icon then icon.Visible = isUn end
                                local shadow = btn:FindFirstChild("UIShadow")
                                if shadow then pcall(function() shadow.Enabled = isUn end) end
                                local stroke = btn:FindFirstChildOfClass("UIStroke")
                                if stroke then stroke.Color = isUn and selectedWhite or unselectedGray end
                            end
                        end
                        log("UI dipaksa ke Unranked.")
                    end
                end
            end)
            task.wait(0.5)

            local place = zone:GetAttribute("Place") or "Earth"
            local svcFolder = ReplicatedStorage.Packages._Index["sleitnick_knit@1.4.6"].knit.Services.TeleportManagerService
            local createdRF = svcFolder:WaitForChild("RF"):WaitForChild("CreatedZone")
            log("CreatedZone solo Unranked...")

            if LOOP_MODE then requeueSelf() end

            local ok, res = pcall(function()
                return createdRF:InvokeServer(zone, 1, place, false)
            end)
            log("CreatedZone ok=" .. tostring(ok) .. " res=" .. tostring(res))
        else
            log("Tidak ada PartyZone Unranked.")
        end
    end
end

if not IN_LOBBY then
    -- Reset state inisialisasi (kecuali stop flag, biar tidak nimpa kill switch manual)
    _G.ChestFarm = false
    _G.TrackScan = false
    task.wait(1.5)
    _G.__FarmRunning = false
    _G.__ScanRunning = false
    _G.__SkipRunning = false
    _G.__DialogRunning = false
    _G.__LobbySent = false
    _G.SafeMode = false
    _G.ScanNoClip = false
    _G.Firing = false
    if not isStopFlag() then
        _G.__KillSwitch = false
    end
    _G.ChestFarm = false
    _G.TrackScan = true

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local GuiService = game:GetService("GuiService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local player = Players.LocalPlayer
    local guiParent = player:WaitForChild("PlayerGui")

    local LOW_POLY = true
    local LOW_POLY_STRIP = {
        "ParticleEmitter", "Trail", "Smoke", "Fire", "Sparkles",
        "Beam", "Decal", "Texture", "SurfaceAppearance",
        "PointLight", "SpotLight", "SurfaceLight",
        "Atmosphere", "Sky",
    }

    local chestCache = setmetatable({}, {__mode = "k"})
    local function isInChest(inst)
        if chestCache[inst] ~= nil then return chestCache[inst] end
        local chain = {}
        local cur = inst
        local result = false
        local depth = 0
        while cur and depth < 20 do
            table.insert(chain, cur)
            if chestCache[cur] ~= nil then
                result = chestCache[cur]
                break
            end
            if cur:IsA("Model") then
                local ok, v = pcall(function() return cur:GetAttribute("RuntimeChestModel") end)
                if ok and v then result = true break end
                local n = string.lower(cur.Name)
                if string.find(n, "chest", 1, true) then result = true break end
            end
            cur = cur.Parent
            depth += 1
        end
        for _, c in ipairs(chain) do chestCache[c] = result end
        return result
    end

    local function isInLocalChar(inst)
        local char = player.Character
        if not char then return false end
        return inst == char or inst:IsDescendantOf(char)
    end

    local function stripOne(inst)
        if not LOW_POLY then return end
        if isInChest(inst) then return end
        if isInLocalChar(inst) then return end
        for _, cls in ipairs(LOW_POLY_STRIP) do
            if inst:IsA(cls) then
                pcall(function() inst:Destroy() end)
                return
            end
        end
        if inst:IsA("BasePart") and inst.CastShadow then
            pcall(function() inst.CastShadow = false end)
        end
    end

    local function applyLowPoly()
        if not LOW_POLY then return end
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function() settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01 end)

        local lighting = game:GetService("Lighting")
        pcall(function()
            lighting.GlobalShadows = false
            lighting.FogEnd = 500
            lighting.Brightness = 1
            lighting.EnvironmentDiffuseScale = 0
            lighting.EnvironmentSpecularScale = 0
            lighting.Outlines = false
        end)
        for _, child in ipairs(lighting:GetChildren()) do
            if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
                pcall(function() child:Destroy() end)
            end
        end
        for _, d in ipairs(workspace:GetDescendants()) do
            stripOne(d)
        end
        workspace.DescendantAdded:Connect(function(d)
            if not LOW_POLY then return end
            for _, cls in ipairs(LOW_POLY_STRIP) do
                if d:IsA(cls) then
                    task.defer(function()
                        if not isInChest(d) and not isInLocalChar(d) then
                            pcall(function() d:Destroy() end)
                        end
                    end)
                    return
                end
            end
            if d:IsA("BasePart") then
                task.defer(function()
                    if d.CastShadow and not isInChest(d) and not isInLocalChar(d) then
                        pcall(function() d.CastShadow = false end)
                    end
                end)
            end
        end)
        lighting.DescendantAdded:Connect(function(d)
            if LOW_POLY and (d:IsA("PostEffect") or d:IsA("Atmosphere")) then
                task.defer(function() pcall(function() d:Destroy() end) end)
            end
        end)
        print("[LowPoly] ON - chest tetap utuh.")
    end
    applyLowPoly()

    local old = guiParent:FindFirstChild("ChestFarmMenu")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "ChestFarmMenu"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 999
    sg.Parent = guiParent

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.new(0, 220, 0, 222)
    frame.Position = UDim2.new(0, 10, 0, 100)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 28)
    title.BackgroundTransparency = 1
    title.Text = "Chest Farm"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Parent = frame

    local scanBtn = Instance.new("TextButton")
    scanBtn.Name = "Scan"
    scanBtn.Size = UDim2.new(1, -20, 0, 36)
    scanBtn.Position = UDim2.new(0, 10, 0, 36)
    scanBtn.BackgroundColor3 = Color3.fromRGB(60, 90, 180)
    scanBtn.Text = "SCAN: OFF"
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.TextSize = 15
    scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanBtn.Parent = frame
    Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 8)

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -20, 0, 140)
    status.Position = UDim2.new(0, 10, 0, 80)
    status.BackgroundTransparency = 1
    status.Text = "Status: FARM\nLoot: 0 | Skip: 0\nLocked: 0\nScan: -"
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.TextWrapped = true
    status.Parent = frame

    local FIRE_HOLD = 0
    local FIRE_REPEATS = 2
    local FIRE_REPEAT_GAP = 0.05
    local GONE_CHECK_WAIT = 0.25
    local SCAN_WAIT = 3
    local MAX_OPEN_RETRY = 3
    local RETRY_GAP = 0.3
    local HP_STOP_FRAC = 0.10
    local SAFE_HP_ENTER = 0.30
    local SAFE_HP_EXIT  = 0.60
    local SAFE_FLOAT_STUDS = 100
    local SAFE_POLL     = 0.25
    local SCAN_STEP = 200
    local SCAN_END_DIST = 37000
    local SCAN_LOOT_R = 1200
    local SCAN_WAIT_STREAM = 0.8

    local SKIP_MIMIC = true
    local mimicSkipped = 0
    local function isMimic(model)
        if not model then return false end
        local ok, n = pcall(function() return model.Name end)
        if ok and n and string.find(string.lower(tostring(n)), "mimic", 1, true) then
            return true
        end
        return false
    end

    local AUTO_SKIP_CUTSCENE = true
    local SKIP_POLL = 0.2
    local cutSkipped = 0
    local AUTO_SKIP_DIALOGUE = true
    local DIALOGUE_POLL = 0.5
    local DIALOGUE_MAX = 40
    local dialogSkipped = 0
    local AUTO_LOBBY_FINISH = true
    local looted, skipped, lockedSeen = 0, 0, 0
    local doneDup = 0
    local coresStart = nil
    local refresh
    _G.ScanInfo = "-"

    local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    if not IS_MOBILE then
        FIRE_REPEATS = 3
        FIRE_REPEAT_GAP = 0.02
        SCAN_STEP = 150
        SAFE_POLL = 0.15
        SCAN_WAIT_STREAM = 0.6
        print("[Detect] PC mode.")
    else
        print("[Detect] Mobile mode.")
    end

    local BLACKLIST_TIME = 300
    local openedModel = {}
    local openedPos = {}
    local function posKey(pos, name)
        return tostring(name) .. "|" .. math.floor(pos.X / 10) .. "_" .. math.floor(pos.Y / 10) .. "_" .. math.floor(pos.Z / 10)
    end
    local function isOpened(model, pos, name)
        local now = os.clock()
        if openedModel[model] then
            if now - openedModel[model] < BLACKLIST_TIME then return true end
            openedModel[model] = nil
        end
        local k = posKey(pos, name)
        if openedPos[k] then
            if now - openedPos[k] < BLACKLIST_TIME then return true end
            openedPos[k] = nil
        end
        return false
    end
    local function markOpened(model, pos, name)
        openedModel[model] = os.clock()
        openedPos[posKey(pos, name)] = os.clock()
    end

    local function isLocked(model)
        local lock = model:FindFirstChild("LockGui", true)
        if not lock then return false end
        local ok, en = pcall(function() return lock.Enabled end)
        if ok and en == false then return false end
        for _, d in ipairs(lock:GetDescendants()) do
            if d:IsA("ImageLabel") then
                local ok2 = pcall(function() return d.Visible end)
                local transp = 0
                pcall(function() transp = d.ImageTransparency end)
                if ok2 and d.Visible and (tonumber(transp) or 0) < 0.5 then
                    return true
                end
            end
        end
        if ok and en == true then return true end
        return false
    end

    local function say(m) print("[ChestFarm] " .. tostring(m)) end
    local function hrp()
        local c = player.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
    local function hum()
        local c = player.Character
        return c and c:FindFirstChildOfClass("Humanoid")
    end
    local function hpFrac()
        local h = hum()
        if not h or h.MaxHealth <= 0 then return 0 end
        return h.Health / h.MaxHealth
    end

    local function getCores()
        local ok, v = pcall(function() return player:GetAttribute("Cores") end)
        if ok and type(v) == "number" then return v end
        if ok and tonumber(tostring(v)) then return tonumber(tostring(v)) end
        local ok2, v2 = pcall(function()
            for _, d in ipairs(player.PlayerGui:GetDescendants()) do
                if d:IsA("TextLabel") and d.Name == "Amount" then
                    local fn = d:GetFullName()
                    if fn:find("TopBar") and fn:find("Cores") then
                        return tonumber((d.Text or ""):gsub("[^%d]", ""))
                    end
                end
            end
            return -1
        end)
        if ok2 and type(v2) == "number" then return v2 end
        return -1
    end

    local noclipOriginals = {}
    local noclipConn = nil
    local function applyNoClip()
        local c = player.Character
        if not c then return end
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") then
                if noclipOriginals[d] == nil then
                    noclipOriginals[d] = d.CanCollide
                end
                if d.CanCollide then
                    d.CanCollide = false
                end
            end
        end
    end
    local function restoreNoClip()
        for part, val in pairs(noclipOriginals) do
            if part and part.Parent then
                pcall(function() part.CanCollide = val end)
            end
        end
        table.clear(noclipOriginals)
    end
    local function startNoClip()
        if noclipConn then return end
        noclipOriginals = {}
        noclipConn = RunService.Stepped:Connect(function()
            if not _G.SafeMode and not _G.ScanNoClip then
                restoreNoClip()
                if noclipConn then noclipConn:Disconnect() noclipConn = nil end
                say("NOCLIP OFF.")
                return
            end
            applyNoClip()
        end)
        say("NOCLIP ON.")
    end
    local function startScanNoClip()
        if _G.ScanNoClip then return end
        _G.ScanNoClip = true
        startNoClip()
        say("SCAN-NOCLIP ON (masuk wall).")
    end
    local function stopScanNoClip()
        if not _G.ScanNoClip then return end
        _G.ScanNoClip = false
        if not _G.SafeMode then
            task.defer(function()
                task.wait(0.2)
                -- Stepped akan restore + disconnect sendiri kalau SafeMode & ScanNoClip false.
            end)
        end
        say("SCAN-NOCLIP OFF (ke chest).")
    end

    player.CharacterAdded:Connect(function(c)
        task.wait(0.3)
        if _G.SafeMode or _G.ScanNoClip then
            noclipOriginals = {}
        end
    end)

    local function ensureStanding()
        local h = hum()
        if h and h.Sit then
            pcall(function() h.Sit = false; h.Jump = true end)
            task.wait(0.4)
            local h2 = hum()
            if h2 and h2.Sit then
                pcall(function() h2.Sit = false end)
                task.wait(0.3)
            end
            say("Dismounted from seat.")
            return true
        end
        return false
    end

    local seatedConn = nil
    local function bindAutoUnseat(char)
        char = char or player.Character
        if not char then return end
        local h = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
        if not h then return end
        if seatedConn then seatedConn:Disconnect() seatedConn = nil end
        seatedConn = h.Seated:Connect(function(active)
            if active then
                task.wait(0.1)
                if h.Sit and not _G.SafeMode then
                    pcall(function() h.Sit = false; h.Jump = true end)
                    say("Auto-dismounted.")
                end
            end
        end)
    end
    bindAutoUnseat(player.Character)

    local safePos = nil
    local hpConn = nil
    local function bindInstantSafe(char)
        char = char or player.Character
        if not char then return end
        local h = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
        if not h then return end
        if hpConn then hpConn:Disconnect() hpConn = nil end
        hpConn = h.HealthChanged:Connect(function(newHp)
            if h.MaxHealth > 0 and newHp / h.MaxHealth < SAFE_HP_ENTER then
                if (_G.ChestFarm or _G.TrackScan) and not _G.SafeMode then
                    task.spawn(function()
                        local r = hrp()
                        if r then
                            _G.SafeMode = true
                            safePos = r.Position + Vector3.new(0, SAFE_FLOAT_STUDS, 0)
                            pcall(function()
                                r.AssemblyLinearVelocity = Vector3.zero
                                r.CFrame = CFrame.new(safePos)
                                r.Anchored = true
                            end)
                            startNoClip()
                            say(string.format("INSTANT-SAFE HP %.0f%%.", newHp / h.MaxHealth * 100))
                            refresh()
                        end
                    end)
                end
            end
        end)
    end
    bindInstantSafe(player.Character)
    player.CharacterAdded:Connect(function(c)
        task.wait(0.3)
        bindAutoUnseat(c)
        bindInstantSafe(c)
        _G.SafeMode = false
    end)

    function refresh()
        pcall(function()
            local mode = "IDLE"
            if _G.SafeMode then mode = "SAFE"
            elseif _G.ChestFarm then mode = "FARM"
            elseif _G.TrackScan then mode = "SCAN"
            end
            local cc = getCores()
            if coresStart == nil and cc and cc >= 0 then coresStart = cc end
            local gainTxt = ""
            if cc and cc >= 0 and coresStart then
                local g = cc - coresStart
                gainTxt = "\nCores: " .. cc .. " (+" .. g .. ")"
            end
            status.Text = "Status: " .. mode
                .. "\nLoot: " .. looted .. " | Skip: " .. skipped .. " (Mimic:" .. mimicSkipped .. ") | Done: " .. doneDup
                .. "\nLocked: " .. lockedSeen
                .. gainTxt
                .. "\nScan: " .. tostring(_G.ScanInfo or "-")
        end)
    end

    local function promptOf(model)
        local cp = model:FindFirstChild("Chest", true)
        if cp then
            local p = cp:FindFirstChildOfClass("ProximityPrompt")
            if p then return p end
        end
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("ProximityPrompt") then return d end
        end
        return nil
    end

    local function simpleWait(totalTime)
        local t = 0
        while t < totalTime do
            if not (_G.ChestFarm or _G.TrackScan) then break end
            if isStopFlag() then break end
            if _G.SafeMode then break end
            if hpFrac() < SAFE_HP_ENTER then break end
            task.wait(0.25)
            t += 0.25
        end
    end

    local function nearestChest(maxDist)
        local r = hrp()
        local rp = r and r.Position or nil
        local best, bestD = nil, maxDist or 1e9
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("Model") then
                local ok, v = pcall(function() return d:GetAttribute("RuntimeChestModel") end)
                if ok and v and not isLocked(d) then
                    if not (SKIP_MIMIC and isMimic(d)) then
                        local ok2, cf = pcall(function() return d:GetPivot() end)
                        if ok2 and cf then
                            if not isOpened(d, cf.Position, d.Name) then
                                local dist = rp and (cf.Position - rp).Magnitude or 0
                                if dist < bestD then best, bestD = { Model = d, Pos = cf.Position, Dist = dist }, dist end
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local function allChests()
        local r = hrp()
        local rp = r and r.Position or nil
        local out = {}
        lockedSeen = 0
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("Model") then
                local ok, v = pcall(function() return d:GetAttribute("RuntimeChestModel") end)
                if ok and v then
                    if SKIP_MIMIC and isMimic(d) then
                        local okm, cfm = pcall(function() return d:GetPivot() end)
                        if okm and cfm and not isOpened(d, cfm.Position, d.Name) then
                            markOpened(d, cfm.Position, d.Name)
                            mimicSkipped += 1
                            skipped += 1
                        end
                    elseif isLocked(d) then
                        lockedSeen += 1
                    else
                        local ok2, cf = pcall(function() return d:GetPivot() end)
                        if ok2 and cf then
                            if isOpened(d, cf.Position, d.Name) then
                                doneDup += 1
                            else
                                local pr = promptOf(d)
                                if pr and not pr.Enabled then
                                    markOpened(d, cf.Position, d.Name)
                                    doneDup += 1
                                else
                                    table.insert(out, { Model = d, Pos = cf.Position, Dist = rp and (cf.Position - rp).Magnitude or 0 })
                                    if #out >= 60 then break end
                                end
                            end
                        end
                    end
                end
            end
        end
        table.sort(out, function(a, b) return a.Dist < b.Dist end)
        refresh()
        return out
    end

    local function enterSafeMode()
        if _G.SafeMode then return end
        _G.SafeMode = true
        local r = hrp()
        if r then
            safePos = r.Position + Vector3.new(0, SAFE_FLOAT_STUDS, 0)
            pcall(function()
                r.AssemblyLinearVelocity = Vector3.zero
                r.CFrame = CFrame.new(safePos)
                r.Anchored = true
            end)
        end
        startNoClip()
        say(string.format("HP %.0f%% - SAFE MODE.", hpFrac()*100))
        refresh()
    end

    local function exitSafeMode()
        if not _G.SafeMode then return end
        _G.SafeMode = false
        local r = hrp()
        if r then
            pcall(function() r.Anchored = false end)
        end
        say(string.format("HP recovered (%.0f%%).", hpFrac()*100))
        refresh()
    end

    local function waitRecovery()
        enterSafeMode()
        while _G.SafeMode do
            if not (_G.ChestFarm or _G.TrackScan) then
                exitSafeMode()
                return false
            end
            if isStopFlag() then
                exitSafeMode()
                return false
            end
            if hpFrac() >= SAFE_HP_EXIT then
                exitSafeMode()
                return true
            end
            local r = hrp()
            if r and not r.Anchored then
                pcall(function()
                    if safePos then r.CFrame = CFrame.new(safePos) end
                    r.Anchored = true
                end)
            end
            task.wait(SAFE_POLL)
        end
        return false
    end

    local function hardStopAll()
        print("[Kill] Hard stop all loops + release anchor.")
        _G.ChestFarm = false
        _G.TrackScan = false
        _G.__KillSwitch = true
        setStopFlag()

        local r = hrp()
        if r then
            pcall(function() r.Anchored = false end)
        end

        pcall(function()
            restoreNoClip()
            if noclipConn then
                noclipConn:Disconnect()
                noclipConn = nil
            end
        end)

        _G.SafeMode = false
        _G.ScanNoClip = false
    end

    local function endSessionV3()
        hardStopAll()
        task.wait(0.5)

        local sessionId = player:GetAttribute("PendingSessionId")
        print("[ES] step 1 start")
        print("[ES] step 2 session:", sessionId)

        if typeof(sessionId) ~= "string" then
            warn("[ES] STOP: PendingSessionId bukan string")
            return false
        end

        local index = ReplicatedStorage:FindFirstChild("Packages")
            and ReplicatedStorage.Packages:FindFirstChild("_Index")
        print("[ES] step 3 index:", index and "ketemu" or "HILANG")
        if not index then return false end

        local kb = nil
        for _, f in ipairs(index:GetChildren()) do
            if string.find(f.Name, "sleitnick_knit") then kb = f break end
        end
        print("[ES] step 4 knit:", kb and kb.Name or "HILANG")
        if not kb then return false end

        local ok, rf = pcall(function()
            return kb:WaitForChild("knit", 5)
                :WaitForChild("Services", 5)
                :WaitForChild("TeleportManagerService", 5)
                :WaitForChild("RF", 5)
                :WaitForChild("EndSession", 5)
        end)
        print("[ES] step 5 rf:", ok, rf and rf:GetFullName() or rf)
        if not ok or not rf then return false end

        print("[ES] step 6 invoke, tunggu max 65 detik...")
        local s, r = pcall(function()
            return rf:InvokeServer(sessionId)
        end)
        print("[ES] step 7 selesai. ok:", s, "res:", r)

        if s then
            print("[ES] BERHASIL - session ditutup.")
            return true
        else
            warn("[ES] GAGAL invoke:", r)
            return false
        end
    end

    local function gotoLobbyFinish()
        if not AUTO_LOBBY_FINISH then return end
        if _G.__LobbySent then return end
        _G.__LobbySent = true
        say("SCAN GARIS AKHIR -> teleport lobby.")
        refresh()
        _G.ChestFarm = false
        _G.TrackScan = false
        task.wait(0.5)

        local teleportOK = false
        local svc = nil
        local ok, s = pcall(function()
            return ReplicatedStorage.Packages._Index["sleitnick_knit@1.4.6"].knit.Services.TeleportManagerService
        end)
        if ok and s then svc = s end

        if svc then
            for attempt = 1, 5 do
                if isStopFlag() then
                    say("[Loop] Stop flag aktif di tengah retry -> abort.")
                    break
                end
                local ok2, res = pcall(function() return svc.RF.TeleportToLobby:InvokeServer() end)
                say(string.format("TeleportToLobby attempt %d/5: ok=%s res=%s", attempt, tostring(ok2), tostring(res)))
                if ok2 then
                    teleportOK = true
                    break
                end
                task.wait(1)
            end
        else
            say("TeleportManagerService tidak ketemu!")
        end

        if teleportOK then
            if LOOP_MODE and not isStopFlag() then
                requeueSelf()
                say("Teleport normal sukses -> loop tetap jalan (requeue).")
            end
            return
        end

        say("[Fallback] TeleportToLobby gagal 5x -> EndSession v3 + STOP LOOP.")
        endSessionV3()

        say("Menunggu auto-teleport ke lobby...")
        local t0 = os.clock()
        while os.clock() - t0 < 30 do
            task.wait(1)
            local ok2, svc2 = pcall(function()
                return ReplicatedStorage.Packages._Index["sleitnick_knit@1.4.6"].knit.Services.TeleportManagerService
            end)
            if ok2 and svc2 then
                local ok3, v = pcall(function() return svc2.RF.IsLobby:InvokeServer() end)
                if ok3 and v == true then
                    say("[OK] Sudah di Lobby. Script DIAM (loop mati).")
                    return
                end
            end
        end
        say("Selesai. Untuk loop lagi: getgenv().AutoHopLoopStop = false lalu re-execute.")
    end

    local function fireInstant(prompt)
        if not prompt then return end
        local hasFPP = (type(fireproximityprompt) == "function")
        for i = 1, FIRE_REPEATS do
            if hasFPP then
                pcall(function()
                    if FIRE_HOLD > 0 then
                        fireproximityprompt(prompt, FIRE_HOLD)
                    else
                        fireproximityprompt(prompt)
                    end
                end)
            else
                pcall(function() prompt:InputHoldBegin() end)
                task.wait(FIRE_HOLD > 0 and FIRE_HOLD or 0.1)
                pcall(function() prompt:InputHoldEnd() end)
                pcall(function()
                    local oldEnabled = prompt.Enabled
                    local oldHold = prompt.HoldDuration
                    prompt.Enabled = true
                    prompt.HoldDuration = 0
                    prompt:InputHoldBegin()
                    task.wait(0.05)
                    prompt:InputHoldEnd()
                    prompt.Enabled = oldEnabled
                    prompt.HoldDuration = oldHold
                end)
            end
            if i < FIRE_REPEATS then task.wait(FIRE_REPEAT_GAP) end
        end
    end

    local function openChest(entry)
        if _G.SafeMode then return "safe-mode" end
        if isStopFlag() then return "stop-flag" end
        if entry.Model and SKIP_MIMIC and isMimic(entry.Model) then
            markOpened(entry.Model, entry.Pos, entry.Model.Name)
            mimicSkipped += 1
            skipped += 1
            say("SKIP mimic: " .. entry.Model.Name)
            refresh()
            return "skip-mimic"
        end
        if entry.Model and entry.Model.Parent and isOpened(entry.Model, entry.Pos, entry.Model.Name) then
            return "already-opened"
        end
        local r = hrp()
        if not r then return "no-hrp" end
        local mname0 = entry.Model and entry.Model.Name or "?"

        for attempt = 1, MAX_OPEN_RETRY do
            if _G.SafeMode then return "safe-mode" end
            if isStopFlag() then return "stop-flag" end
            if hpFrac() < SAFE_HP_ENTER then return "low-hp" end
            r = hrp()
            if not r then return "no-hrp" end
            ensureStanding()
            pcall(function()
                r.AssemblyLinearVelocity = Vector3.zero
                r.CFrame = CFrame.new(entry.Pos + Vector3.new(0, 3, 2), entry.Pos)
            end)
            task.wait(0.2)

            local fresh = nearestChest(20)
            local model = (fresh and fresh.Model) or entry.Model
            if not (model and model.Parent) then
                markOpened(entry.Model, entry.Pos, mname0)
                doneDup += 1
                refresh()
                return "gone"
            end
            if isLocked(model) then return "locked" end
            if isOpened(model, entry.Pos, model.Name) then return "already-opened" end

            local prompt = promptOf(model)
            if not prompt then
                task.wait(RETRY_GAP)
            elseif not prompt.Enabled then
                markOpened(model, entry.Pos, model.Name)
                doneDup += 1
                refresh()
                return "opened-disabled"
            else
                local mname = model.Name
                local coresBefore = getCores()
                _G.Firing = true
                fireInstant(prompt)
                _G.Firing = false
                task.wait(GONE_CHECK_WAIT)
                local coresAfter = getCores()
                local gotCores = (coresBefore >= 0 and coresAfter >= 0 and coresAfter > coresBefore)
                local gone = not model.Parent
                local pr2 = promptOf(model)
                local disabled = (not pr2) or (pr2 and not pr2.Enabled)
                if gotCores or gone or disabled then
                    markOpened(model, entry.Pos, mname)
                    looted += 1
                    if gotCores then
                        say("Looted CORES: " .. mname)
                    else
                        say("Looted: " .. mname)
                    end
                    refresh()
                    return "ok"
                else
                    say("Belum dapat cores " .. mname .. " -> TP + buka lagi.")
                    if attempt < MAX_OPEN_RETRY then
                        task.wait(RETRY_GAP)
                    end
                end
            end
        end
        say("Gagal buka " .. mname0 .. ".")
        refresh()
        return "failed"
    end

    local function setScanBtn()
        pcall(function()
            if _G.TrackScan then
                scanBtn.Text = "SCAN: ON"
                scanBtn.BackgroundColor3 = Color3.fromRGB(50, 170, 80)
            else
                scanBtn.Text = "SCAN: OFF"
                scanBtn.BackgroundColor3 = Color3.fromRGB(60, 90, 180)
            end
        end)
        refresh()
    end

    local function getTrackDirection(pos)
        for _, name in ipairs({"Track", "Rail", "Rails", "Path", "Road"}) do
            local obj = workspace:FindFirstChild(name)
            if obj then
                local ok, cf = pcall(function() return obj:GetPivot() end)
                if ok and cf then
                    local dir = (cf.Position - pos)
                    dir = Vector3.new(dir.X, 0, dir.Z)
                    if dir.Magnitude > 5 then
                        return dir.Unit
                    end
                end
            end
        end
        local r = hrp()
        if r then
            local look = r.CFrame.LookVector
            look = Vector3.new(look.X, 0, look.Z)
            if look.Magnitude > 0.01 then
                return look.Unit
            end
        end
        return Vector3.new(1, 0, 0)
    end

    local function trackStart()
        local dr = workspace:FindFirstChild("Drill")
        if dr then
            local ok, cf = pcall(function() return dr:GetPivot() end)
            if ok and cf then return cf.Position end
        end
        local r = hrp()
        return r and r.Position or Vector3.new(-740, 20, -771.5)
    end

    local function scanTrack()
        if _G.__ScanRunning then return end
        _G.__ScanRunning = true

        local start = trackStart()
        local direction = getTrackDirection(start)

        local distance = 0
        if type(_G.ScanDist) == "number" and _G.ScanDist >= 0 and _G.ScanDist <= SCAN_END_DIST then
            distance = _G.ScanDist
            say("Resuming scan from dist=" .. math.floor(distance) .. ".")
        else
            _G.ScanDist = 0
        end

        local homeY = start.Y
        say(string.format("START scan dari AWAL rel dir=(%.2f,%.2f) -> %.0f studs, step %d.",
            direction.X, direction.Z, SCAN_END_DIST, SCAN_STEP))

        local function lootAtRail(scanPos, label)
            local found = {}
            for _, e in ipairs(allChests()) do
                if (e.Pos - scanPos).Magnitude <= SCAN_LOOT_R then
                    table.insert(found, e)
                end
            end
            if #found > 0 and label then
                say(string.format("%s: %d chests.", label, #found))
            end
            for _, e in ipairs(found) do
                if not _G.TrackScan or isStopFlag() then break end
                if hpFrac() < SAFE_HP_ENTER then
                    if not waitRecovery() then break end
                end
                if e.Model.Parent
                    and not isLocked(e.Model)
                    and not isOpened(e.Model, e.Pos, e.Model.Name) then
                    stopScanNoClip()
                    task.wait(0.15)
                    local ok, res = pcall(openChest, e)
                    if not ok then say("Error: " .. tostring(res)) end
                    if _G.TrackScan and not isStopFlag() then
                        startScanNoClip()
                        local rBack = hrp()
                        if rBack then
                            pcall(function()
                                rBack.AssemblyLinearVelocity = Vector3.zero
                                rBack.CFrame = CFrame.new(scanPos, scanPos + direction)
                            end)
                        end
                        task.wait(0.1)
                    end
                end
                task.wait(0.15)
            end
            return #found
        end

        startScanNoClip()

        while _G.TrackScan and not isStopFlag() do
            if hpFrac() < SAFE_HP_ENTER then
                if not waitRecovery() then break end
            end

            local h0 = hum()
            if not h0 or h0.Health <= 0 then
                say("Dead - waiting respawn, scan continues...")
                pcall(function() player.CharacterAdded:Wait() end)
                task.wait(1.5)
                _G.SafeMode = false
            else
                if hpFrac() < HP_STOP_FRAC then
                    say("HP critically low - retreat + regen, not stop.")
                    waitRecovery()
                end

                if distance > SCAN_END_DIST then
                    say("Scan COMPLETE (end of line).")
                    _G.ScanDist = nil
                    _G.TrackScan = false
                    _G.ScanInfo = "-"
                    setScanBtn()
                    gotoLobbyFinish()
                    break
                end

                local r = hrp()
                if not r then
                    task.wait(1)
                else
                    ensureStanding()

                    if (math.floor(distance / SCAN_STEP) % 3) == 0 then
                        local newDir = getTrackDirection(r.Position)
                        direction = direction:Lerp(newDir, 0.5).Unit
                    end

                    local scanPos = Vector3.new(
                        start.X + direction.X * distance,
                        homeY,
                        start.Z + direction.Z * distance
                    )

                    startScanNoClip()
                    pcall(function()
                        r.AssemblyLinearVelocity = Vector3.zero
                        r.CFrame = CFrame.new(scanPos, scanPos + direction)
                    end)

                    _G.ScanInfo = "dist=" .. math.floor(distance) .. "/" .. SCAN_END_DIST
                    refresh()

                    simpleWait(SCAN_WAIT_STREAM)

                    lootAtRail(scanPos, "dist=" .. math.floor(distance))

                    local r2 = hrp()
                    if r2 then
                        pcall(function()
                            startScanNoClip()
                            r2.AssemblyLinearVelocity = Vector3.zero
                            r2.CFrame = CFrame.new(scanPos, scanPos + direction)
                        end)
                    end
                    simpleWait(0.2)

                    distance += SCAN_STEP
                    _G.ScanDist = distance
                end
            end
            task.wait(0.1)
        end

        _G.__ScanRunning = false
        _G.ScanInfo = "-"
        pcall(function() stopScanNoClip() end)
        if _G.SafeMode then exitSafeMode() end
        setScanBtn()
        say("STOP scan.")
    end

    local function farmLoop()
        if _G.__FarmRunning then return end
        _G.__FarmRunning = true
        say("START farm.")
        local r0 = hrp()
        local safeSpot = r0 and r0.CFrame or nil
        local idle = 0

        while _G.ChestFarm and not isStopFlag() do
            if hpFrac() < SAFE_HP_ENTER then
                if not waitRecovery() then break end
            end
            local hf = hum()
            if not hf or hf.Health <= 0 then
                say("Dead - waiting respawn...")
                pcall(function() player.CharacterAdded:Wait() end)
                task.wait(1.5)
                _G.SafeMode = false
            elseif hpFrac() < HP_STOP_FRAC then
                say("HP low - retreat.")
                waitRecovery()
            end
            local chests = allChests()
            if #chests == 0 then
                idle += 1
                if lockedSeen > 0 then
                    say("Scan " .. idle .. ": 0 unlocked, " .. lockedSeen .. " LOCKED.")
                else
                    say("Scan " .. idle .. ": no chest.")
                end
                if idle >= 40 then say("STOP after 40 empty scans."); _G.ChestFarm = false break end
                local rIdle = hrp()
                if rIdle then
                    simpleWait(SCAN_WAIT)
                else
                    task.wait(SCAN_WAIT)
                end
            else
                idle = 0
                for _, e in ipairs(chests) do
                    if not _G.ChestFarm or isStopFlag() then break end
                    if hpFrac() < SAFE_HP_ENTER then
                        if not waitRecovery() then break end
                    end
                    task.wait(0.1)
                    local ok, res = pcall(openChest, e)
                    if not ok then say("Error: " .. tostring(res)) end
                    task.wait(0.15)
                end
                task.wait(0.3)
            end
        end
        _G.__FarmRunning = false
        if _G.SafeMode then exitSafeMode() end
        refresh()
        say("STOP farm.")
    end

    scanBtn.MouseButton1Click:Connect(function()
        _G.TrackScan = not _G.TrackScan
        if _G.TrackScan then
            _G.ChestFarm = false
        else
            exitSafeMode()
            pcall(function() stopScanNoClip() end)
        end
        setScanBtn()
        refresh()
        if _G.TrackScan then
            task.spawn(scanTrack)
        else
            say("Scan OFF.")
        end
    end)

    local function tapButton(btn)
        if not btn then return false end
        local ok = pcall(function()
            GuiService.SelectedObject = btn
            task.wait(0.1)
            local vim = game:GetService("VirtualInputManager")
            if vim then
                pcall(function() vim:SendKeyEvent(true, Enum.KeyCode.ButtonA, false, game) end)
                task.wait(0.05)
                pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.ButtonA, false, game) end)
                task.wait(0.05)
                pcall(function() vim:SendKeyEvent(true, Enum.KeyCode.Return, false, game) end)
                task.wait(0.05)
                pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Return, false, game) end)
            end
            pcall(function() btn.MouseButton1Click:Fire() end)
            pcall(function() btn.MouseButton1Down:Fire() end)
        end)
        return ok
    end

    local SKIP_ROUNDS = 20
    local voteSkipRF = nil
    local voteSkipPrivRF = nil
    pcall(function()
        for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
            if d:IsA("RemoteFunction") then
                local fn = d:GetFullName()
                if fn:find("CutSceneService") then
                    if d.Name == "VoteSkip" then voteSkipRF = d
                    elseif d.Name == "VoteSkipPrivate" then voteSkipPrivRF = d end
                end
            end
        end
    end)

    local function skipVisible()
        local ok, v = pcall(function()
            local ui = player.PlayerGui:FindFirstChild("CutSceneUI")
            if not ui or not ui.Enabled then return false end
            local sk = ui:FindFirstChild("Skip")
            return sk ~= nil and sk.Visible == true
        end)
        return ok and v
    end

    local function pressSkipBtn()
        pcall(function()
            local sk = player.PlayerGui.CutSceneUI.Skip
            if sk and sk.Visible then
                tapButton(sk)
            end
        end)
    end

    local function autoSkipLoop()
        if not AUTO_SKIP_CUTSCENE then return end
        if _G.__SkipRunning then return end
        _G.__SkipRunning = true
        say("Auto-skip ON.")
        while AUTO_SKIP_CUTSCENE and not isStopFlag() do
            if skipVisible() then
                say("Cutscene skippable.")
                for i = 1, SKIP_ROUNDS do
                    if not skipVisible() or isStopFlag() then
                        cutSkipped += 1
                        say("Cutscene ke-skip (" .. cutSkipped .. ").")
                        break
                    end
                    if voteSkipRF then pcall(function() voteSkipRF:InvokeServer() end) end
                    if voteSkipPrivRF then pcall(function() voteSkipPrivRF:InvokeServer() end) end
                    pressSkipBtn()
                    task.wait(0.6)
                end
                if skipVisible() then
                    say("Skip gagal.")
                end
                task.wait(2)
            else
                task.wait(SKIP_POLL)
            end
        end
        _G.__SkipRunning = false
    end

    local function dialogueActive()
        local ok, v = pcall(function()
            local ui = player.PlayerGui:FindFirstChild("CutSceneUI")
            if not ui or not ui.Enabled then return false end
            local db = ui:FindFirstChild("DialogueBox")
            return db ~= nil and db.Visible == true
        end)
        return ok and v
    end

    local function dialogueSpeaker()
        local ok, v = pcall(function()
            local sp = player.PlayerGui.CutSceneUI.DialogueBox:FindFirstChild("Speaker")
            if sp and sp.Visible then return tostring(sp.Text) end
            return ""
        end)
        if ok then return v else return "" end
    end

    local function pressAdvance()
        pcall(function()
            local ui = player.PlayerGui:FindFirstChild("CutSceneUI")
            if not ui then return end
            local db = ui:FindFirstChild("DialogueBox")
            if not db then return end

            local btnNames = { "Next", "Continue", "Advance", "OK", "Button" }
            for _, name in ipairs(btnNames) do
                local b = db:FindFirstChild(name, true)
                if b and b.Visible and (b:IsA("TextButton") or b:IsA("ImageButton")) then
                    tapButton(b)
                    task.wait(0.15)
                    return
                end
            end

            local vim = game:GetService("VirtualInputManager")
            if vim then
                for _, key in ipairs({ Enum.KeyCode.Space, Enum.KeyCode.E, Enum.KeyCode.Return }) do
                    pcall(function() vim:SendKeyEvent(true, key, false, game) end)
                    task.wait(0.05)
                    pcall(function() vim:SendKeyEvent(false, key, false, game) end)
                    task.wait(0.05)
                end
            end
        end)
    end

    local function dialogueSkipLoop()
        if not AUTO_SKIP_DIALOGUE then return end
        if _G.__DialogRunning then return end
        _G.__DialogRunning = true
        say("Dialogue-skip ON.")
        while AUTO_SKIP_DIALOGUE and not isStopFlag() do
            if dialogueActive() then
                local sp = dialogueSpeaker()
                say("Dialogue terdeteksi (" .. (sp ~= "" and sp or "?") .. ").")
                if voteSkipRF then pcall(function() voteSkipRF:InvokeServer() end) end
                if voteSkipPrivRF then pcall(function() voteSkipPrivRF:InvokeServer() end) end
                for i = 1, DIALOGUE_MAX do
                    if not dialogueActive() or isStopFlag() then
                        dialogSkipped += 1
                        say("Dialogue selesai (" .. dialogSkipped .. ").")
                        break
                    end
                    pressAdvance()
                    task.wait(0.3)
                end
                if dialogueActive() then
                    say("Dialogue masih jalan.")
                end
                task.wait(1.5)
            else
                task.wait(DIALOGUE_POLL)
            end
        end
        _G.__DialogRunning = false
    end

    setScanBtn()
    task.spawn(farmLoop)
    task.spawn(autoSkipLoop)
    task.spawn(dialogueSkipLoop)

    if _G.TrackScan and not _G.__ScanRunning then
        task.spawn(scanTrack)
        say("Auto-ON SCAN di Earth.")
    end

    say("Menu OK. LOW POLY ON. SCAN AUTO-ON. NO-DODGE/AIM (anti lag). SafeMode ON. EndSession v3 + HARD STOP.")
end
