-- AutoHopUnranked_ChestFarm.lua
-- Gabungan: (1) AutoHop Unranked Solo + (2) Chest Farm
-- CARA PAKAI: execute 1x di Lobby. Loop selamanya:
-- buat room Unranked 1 slot -> farm -> selesai -> balik lobby -> buat room lagi.
-- Berhenti sendiri kalau keluar ke menu Roblox.
-- GUI Chest Farm hanya muncul + auto-ON kalau IsPlanet=true (di Earth).

-- ============================================================
-- PERSIST: auto re-execute antar teleport (Lobby <-> Earth)
-- ============================================================
_G.AutoHopUnranked_URL = _G.AutoHopUnranked_URL or ""

pcall(function()
    local q = queue_on_teleport
        or queueonteleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
    local function tryRead(n)
        local ok, s = pcall(readfile, n)
        if ok and type(s) == "string" and #s > 100 then return s end
        return nil
    end
    -- Patch 1: dukung .lua, .luau, .lua.txt, .txt
    local src = tryRead("AutoHopUnranked_ChestFarm.lua")
        or tryRead("AutoHopUnranked_ChestFarm.luau")
        or tryRead("AutoHopUnranked_ChestFarm.lua.txt")
        or tryRead("AutoHopUnranked_ChestFarm.txt")
        or tryRead("workspace/AutoHopUnranked_ChestFarm.lua")
        or tryRead("workspace/AutoHopUnranked_ChestFarm.lua.txt")
    local method = "file"
    if not src then
        pcall(function()
            local ok, files = pcall(listfiles, "")
            if ok and type(files) == "table" then
                for _, f in ipairs(files) do
                    if type(f) == "string" and string.lower(f):find("autohopunranked_chestfarm") then
                        src = tryRead(f)
                        if src then break end
                    end
                end
            end
        end)
    end
    if not src and type(_G.AutoHopUnranked_URL) == "string" and #_G.AutoHopUnranked_URL > 10 then
        src = "loadstring(game:HttpGet('" .. _G.AutoHopUnranked_URL .. "'))()"
        method = "url"
    end
    -- Patch 4: pesan error lebih jelas
    local msg
    if q and src then
        q(src)
        msg = "[Persist] Aktif (" .. method .. "): sekali execute, ikut teleport."
    elseif src and not q then
        msg = "[Persist] queue_on_teleport TIDAK DIDUKUNG executor. Taruh file di folder autoexec/ supaya loop jalan."
    else
        msg = "[Persist] GAGAL (queue=" .. tostring(q ~= nil) .. ", src=" .. tostring(src ~= nil) .. "). Rename file ke .lua atau isi _G.AutoHopUnranked_URL."
    end
    print(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "AutoHop", Text = msg:sub(1, 90), Duration = 6 })
    end)
end)

-- ============================================================
-- BAGIAN 1: AutoHop Unranked Solo (hanya jalan di Lobby)
-- ============================================================
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

if IN_LOBBY then
    local Players = game:GetService("Players")
    local CollectionService = game:GetService("CollectionService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LP = Players.LocalPlayer

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

        -- AUTO END SESSION
        _G.AutoEndSession = true
        task.spawn(function()
            local fails = 0
            while _G.AutoEndSession do
                local acted = false
                pcall(function()
                    local frames = LP.PlayerGui:FindFirstChild("UI")
                    frames = frames and frames:FindFirstChild("Frames")
                    local jr = frames and frames:FindFirstChild("SessionRejoin")
                    if jr and jr.Visible then
                        local btn = jr:FindFirstChild("Options")
                        btn = btn and btn:FindFirstChild("RejoinConfirm")
                        if btn and btn:IsA("GuiButton") then
                            game:GetService("GuiService").SelectedObject = btn
                            task.wait(0.3)
                            local vim = game:GetService("VirtualInputManager")
                            vim:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                            task.wait(0.1)
                            vim:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                            print("[AutoEndSession] Tombol End Session dipilih.")
                            acted = true
                        end
                    end
                end)
                if acted then
                    task.wait(4)
                    local still = false
                    pcall(function()
                        local jr = LP.PlayerGui.UI.Frames:FindFirstChild("SessionRejoin")
                        still = jr and jr.Visible or false
                    end)
                    if still then
                        fails += 1
                        if fails >= 2 then
                            pcall(function()
                                local sid = LP:GetAttribute("PendingSessionId")
                                local svc = ReplicatedStorage.Packages._Index["sleitnick_knit@1.4.6"].knit.Services.TeleportManagerService
                                local ok, res = svc.RF.EndSession:InvokeServer(sid)
                                print("[AutoEndSession] Fallback RF.EndSession ok=" .. tostring(ok) .. " res=" .. tostring(res))
                            end)
                            fails = 0
                        end
                    else
                        fails = 0
                    end
                else
                    task.wait(1)
                end
            end
        end)

        for attempt = 1, 999 do
            char = LP.Character or LP.CharacterAdded:Wait()
            hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then
                task.wait(3)
            else
            local zone = findUnrankedZone()
            if not zone then
                if attempt == 1 or attempt % 12 == 0 then log("Belum ada zone Unranked kosong (coba " .. attempt .. ")...") end
                task.wait(5)
            else
            log("Target: " .. zone:GetFullName())
            hrp.CFrame = zone.CFrame + Vector3.new(0, 3, 0)
            log("Teleport ke Unranked zone, tunggu panel...")
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
                    log("Unranked sudah kepilih -> langsung mulai.")
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
            log("CreatedZone solo Unranked (1, " .. tostring(place) .. ", false)...")
            local ok, res = pcall(function()
                return createdRF:InvokeServer(zone, 1, place, false)
            end)
            log("CreatedZone ok=" .. tostring(ok) .. " res=" .. tostring(res))
                if ok and res then
                    log("Room Unranked jadi, menunggu teleport ke Earth...")
                    break
                end
                task.wait(5)
            end
            end
        end
    end
    print("[AutoHopUnranked_ChestFarm] Keluar lobby loop (room jadi / batas coba).")
end

-- ============================================================
-- BAGIAN 2: Chest Farm (GUI hanya muncul + auto-ON kalau IsPlanet=true)
-- ============================================================
do
-- ==== GUARD IsPlanet ====
local function isPlanet()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LP = game:GetService("Players").LocalPlayer
    local function readAttr()
        for _, obj in ipairs({ workspace, ReplicatedStorage, LP }) do
            if obj then
                local v = obj:GetAttribute("IsPlanet")
                if v ~= nil then return v end
            end
        end
        return nil
    end
    local v = readAttr()
    if v == nil then
        local deadline = os.clock() + 2
        repeat
            task.wait(0.2)
            v = readAttr()
        until v ~= nil or os.clock() >= deadline
    end
    if v ~= nil then return v == true end
    return not IN_LOBBY
end

local IN_PLANET = isPlanet()

if not IN_PLANET then
    print("[ChestFarm] IsPlanet=false (lobby) -> GUI tidak dibuat, tunggu teleport ke planet.")
else
-- ==== END GUARD ====

_G.ChestFarm = false
_G.TrackScan = false
task.wait(1.5)
_G.__FarmRunning = false
_G.__ScanRunning = false
_G.__SkipRunning = false
_G.__DialogRunning = false
_G.__AimRunning = false
_G.__LobbySent = false
_G.SafeMode = false
_G.Firing = false

-- Patch 2: pilih satu mode, jangan rebutan teleport
--   "SCAN" = sapu garis X sistematis
--   "FARM" = kejar chest terdekat acak
local MODE = "SCAN"
_G.ChestFarm = (MODE == "FARM")
_G.TrackScan  = (MODE == "SCAN")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local guiParent = player:WaitForChild("PlayerGui")

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
frame.Position = UDim2.new(0, 20, 0, 120)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundTransparency = 1
title.Text = "🟣 Chest Farm"
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
status.Text = "Status: FARM 🟢\nLoot: 0 | Skip: 0\nLocked: 0\nScan: -"
status.Font = Enum.Font.Gotham
status.TextSize = 13
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextWrapped = true
status.Parent = frame

-- ===== config =====
local SKIP_MIMIC = false
local SAFE_RADIUS = 80
local MIMIC_RADIUS = 30
local FIRE_HOLD = 0
local FIRE_REPEATS = 3
local FIRE_REPEAT_GAP = 0.02
local GONE_CHECK_WAIT = 0.25
local SCAN_WAIT = 3
local MAX_OPEN_RETRY = 3
local RETRY_GAP = 0.3
local HP_STOP_FRAC = 0.10
local SAFE_HP_ENTER = 0.30
local SAFE_HP_EXIT  = 0.60
local SAFE_FLOAT_STUDS = 100
local SAFE_POLL     = 0.15
local SCAN_STEP = 150
local SCAN_END_X = 36000
local SCAN_LOOT_R = 1200
local SCAN_WAIT_STREAM = 0.6
local DODGE_ON = true
local DODGE_OFFSET = 16
local DODGE_THREAT_R = 90
local DODGE_TICK = 0.1
local DODGE_Y_JITTER = 4
local AIM_ON = true
local AIM_RANGE = 150
local AIM_COS = 0.96
local AIM_DODGE_OFFSET = 20
local AIM_COOLDOWN = 0.6
local HOSTILE_KEYS = {"goblin","brute","spider","bat","mimic","skeleton","orc","bandit","boss","demon","zombie","golem","slime","shooter","gunner","archer","turret","assassin","cultist","raider"}
local AUTO_SKIP_CUTSCENE = true
local SKIP_POLL = 0.5
local cutSkipped = 0
local AUTO_SKIP_DIALOGUE = true
local DIALOGUE_POLL = 0.8
local DIALOGUE_MAX = 40
local dialogSkipped = 0
local AUTO_LOBBY_FINISH = true
local looted, skipped, lockedSeen = 0, 0, 0
local doneDup = 0
local coresStart = nil
local refresh
_G.ScanInfo = "-"

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

local function isMimicChest(model)
  if not model then return false end
  local okName, nm = pcall(function() return model.Name end)
  if okName and type(nm) == "string" and string.find(string.lower(nm), "mimic", 1, true) then
    return true
  end
  local ok, v = pcall(function()
    return model:GetAttribute("IsMimic") or model:GetAttribute("Mimic") or model:GetAttribute("MimicChest")
  end)
  return ok and v == true
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
    if not _G.SafeMode then
      restoreNoClip()
      if noclipConn then noclipConn:Disconnect() noclipConn = nil end
      say("NOCLIP OFF.")
      return
    end
    applyNoClip()
  end)
  say("NOCLIP ON (safe mode).")
end

player.CharacterAdded:Connect(function(c)
  task.wait(0.3)
  if _G.SafeMode then
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
    say("Dismounted from train seat.")
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
        say("Auto-dismounted from seat.")
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
            say(string.format("INSTANT-SAFE HP %.0f%% - shooter burst, float up.", newHp / h.MaxHealth * 100))
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
    if _G.SafeMode then mode = "SAFE ⛑️ REGEN"
    elseif _G.ChestFarm then mode = "FARM 🟢"
    elseif _G.TrackScan then mode = "SCAN 🟢"
    end
    local cc = getCores()
    if coresStart == nil and cc and cc >= 0 then coresStart = cc end
    local gainTxt = ""
    if cc and cc >= 0 and coresStart then
      local g = cc - coresStart
      gainTxt = "\nCores: " .. cc .. " (+" .. g .. ")"
    end
    status.Text = "Status: " .. mode
      .. "\nLoot: " .. looted .. " | Skip: " .. skipped .. " | Done: " .. doneDup
      .. "\nLocked (needs boss): " .. lockedSeen
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

local function threatsNear(pos, radius)
  local list = {}
  for _, m in ipairs(workspace:GetDescendants()) do
    if m:IsA("Model") and m ~= player.Character then
      local h = m:FindFirstChildOfClass("Humanoid")
      if h and h.Health > 0 then
        local ok, cf = pcall(function() return m:GetPivot() end)
        if ok and (cf.Position - pos).Magnitude <= radius then
          table.insert(list, { Model = m, Name = m.Name })
        end
      end
    end
  end
  return list
end

local function dodgeStep(anchorPos)
  if not DODGE_ON then return anchorPos end
  if _G.SafeMode then return anchorPos end
  local r = hrp()
  if not r then return anchorPos end
  local threats = threatsNear(r.Position, DODGE_THREAT_R)
  if #threats == 0 then return anchorPos end
  local rp = r.Position
  local away = Vector3.new(0, 0, 0)
  for _, t in ipairs(threats) do
    local ok, cf = pcall(function() return t.Model:GetPivot() end)
    if ok then
      local d = rp - cf.Position
      d = Vector3.new(d.X, 0, d.Z)
      if d.Magnitude > 0.5 then
        away += d.Unit
      end
    end
  end
  local dir
  if away.Magnitude > 0.1 then
    local fwd = away.Unit
    if math.random() < 0.5 then
      dir = fwd
    else
      local side = Vector3.new(-fwd.Z, 0, fwd.X)
      if math.random() < 0.5 then side = -side end
      dir = (fwd * 0.4 + side * 0.9).Unit
    end
  else
    local a = math.random() * math.pi * 2
    dir = Vector3.new(math.cos(a), 0, math.sin(a))
  end
  local yJit = (math.random() * 2 - 1) * DODGE_Y_JITTER
  local dodgePos = Vector3.new(
    anchorPos.X + dir.X * DODGE_OFFSET,
    anchorPos.Y + yJit,
    anchorPos.Z + dir.Z * DODGE_OFFSET
  )
  pcall(function()
    r.AssemblyLinearVelocity = Vector3.zero
    r.CFrame = CFrame.new(dodgePos, dodgePos + Vector3.new(0, 1, 0))
  end)
  return dodgePos
end

local function fleeFrom(pos, radius)
  local threats = threatsNear(pos, radius)
  if #threats == 0 then return pos end
  local away = Vector3.new(0, 0, 0)
  for _, t in ipairs(threats) do
    local ok, cf = pcall(function() return t.Model:GetPivot() end)
    if ok then
      local d = Vector3.new(pos.X - cf.Position.X, 0, pos.Z - cf.Position.Z)
      if d.Magnitude > 0.5 then away += d.Unit end
    end
  end
  if away.Magnitude < 0.1 then return pos end
  return Vector3.new(
    pos.X + away.Unit.X * (DODGE_OFFSET * 1.5),
    pos.Y,
    pos.Z + away.Unit.Z * (DODGE_OFFSET * 1.5)
  )
end

local function dodgeWait(anchorPos, totalTime)
  local t = 0
  local pos = anchorPos
  while t < totalTime do
    if not (_G.ChestFarm or _G.TrackScan) then break end
    if _G.SafeMode then break end
    if hpFrac() < SAFE_HP_ENTER then break end
    pos = dodgeStep(pos)
    task.wait(DODGE_TICK)
    t += DODGE_TICK
  end
  return pos
end

local function isHostile(m)
  local ok, armed = pcall(function()
    for _, d in ipairs(m:GetDescendants()) do
      if d:IsA("Tool") then return true end
    end
    return false
  end)
  if ok and armed then return true end
  local n = string.lower(m.Name)
  for _, k in ipairs(HOSTILE_KEYS) do
    if string.find(n, k, 1, true) then return true end
  end
  return false
end

local function aimDodge(enemyPos)
  local r = hrp()
  if not r then return end
  local rp = r.Position
  local away = Vector3.new(rp.X - enemyPos.X, 0, rp.Z - enemyPos.Z)
  if away.Magnitude < 0.5 then
    local a0 = math.random() * math.pi * 2
    away = Vector3.new(math.cos(a0), 0, math.sin(a0))
  end
  away = away.Unit
  local side = Vector3.new(-away.Z, 0, away.X)
  if math.random() < 0.5 then side = -side end
  local p1 = Vector3.new(
    rp.X + side.X * AIM_DODGE_OFFSET,
    rp.Y + (math.random() * 2 - 1) * DODGE_Y_JITTER,
    rp.Z + side.Z * AIM_DODGE_OFFSET
  )
  pcall(function()
    r.AssemblyLinearVelocity = Vector3.zero
    r.CFrame = CFrame.new(p1)
  end)
  task.wait(0.05)
  local r2 = hrp()
  if not r2 then return end
  local rp2 = r2.Position
  local a = math.random() * math.pi * 2
  local p2 = Vector3.new(
    rp2.X + away.X * 14 + math.cos(a) * 6,
    rp2.Y + (math.random() * 2 - 1) * DODGE_Y_JITTER,
    rp2.Z + away.Z * 14 + math.sin(a) * 6
  )
  pcall(function()
    r2.AssemblyLinearVelocity = Vector3.zero
    r2.CFrame = CFrame.new(p2)
  end)
end

local aimLastModel = nil
local aimLastTick = 0
local aimStreak = 0
local aimCooldownUntil = 0
local function aimWatch()
  if _G.__AimRunning then return end
  _G.__AimRunning = true
  say("Aim-dodge ON (blink saat dibidik).")
  while AIM_ON do
    if not AIM_ON then break end
    if not _G.SafeMode and not _G.Firing then
      local r = hrp()
      if r then
        local rp = r.Position
        local now = os.clock()
        if now >= aimCooldownUntil then
          local found = nil
          for _, t in ipairs(threatsNear(rp, AIM_RANGE)) do
            local m = t.Model
            if m.Parent and isHostile(m) then
              local ok, cf = pcall(function() return m:GetPivot() end)
              if ok then
                local d = (rp - cf.Position).Magnitude
                if d <= AIM_RANGE and d > 1 then
                  local toMe = Vector3.new(rp.X - cf.Position.X, 0, rp.Z - cf.Position.Z)
                  local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
                  if toMe.Magnitude > 0.5 and fwd.Magnitude > 0.01
                    and fwd.Unit:Dot(toMe.Unit) >= AIM_COS then
                    found = { Model = m, Pos = cf.Position, Dist = d }
                    break
                  end
                end
              end
            end
          end
          if found then
            if aimLastModel and aimLastModel.Parent and aimLastModel == found.Model
              and (now - aimLastTick) < 0.35 then
              aimStreak += 1
            else
              aimStreak = 1
            end
            aimLastModel = found.Model
            aimLastTick = now
            if aimStreak >= 2 then
              say("Aim-dodge! " .. found.Model.Name .. " membidik (" .. math.floor(found.Dist) .. " studs) -> blink!")
              aimDodge(found.Pos)
              aimCooldownUntil = os.clock() + AIM_COOLDOWN
              aimStreak = 0
              aimLastModel = nil
            end
          else
            aimStreak = 0
            aimLastModel = nil
          end
        end
      end
    end
    task.wait(0.1)
  end
  _G.__AimRunning = false
end

local function nearestChest(maxDist)
  local r = hrp()
  local rp = r and r.Position or nil
  local best, bestD = nil, maxDist or 1e9
  for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("Model") then
      local ok, v = pcall(function() return d:GetAttribute("RuntimeChestModel") end)
      if ok and v and not isLocked(d) and not isMimicChest(d) then
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
        if isMimicChest(d) then
          -- skip mimic
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
  say(string.format("HP %.0f%% - SAFE MODE, floated %d studs up + regen.", hpFrac()*100, SAFE_FLOAT_STUDS))
  refresh()
end

local function exitSafeMode()
  if not _G.SafeMode then return end
  _G.SafeMode = false
  local r = hrp()
  if r then
    pcall(function() r.Anchored = false end)
  end
  say(string.format("HP recovered (%.0f%%) - resuming.", hpFrac()*100))
  refresh()
end

local function waitRecovery()
  enterSafeMode()
  while _G.SafeMode do
    if not (_G.ChestFarm or _G.TrackScan) then
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

local function gotoLobbyFinish()
  if not AUTO_LOBBY_FINISH then return end
  if _G.__LobbySent then return end
  _G.__LobbySent = true
  say("SCAN GARIS AKHIR -> teleport lobby.")
  refresh()
  _G.ChestFarm = false
  _G.TrackScan = false
  task.wait(0.5)
  local ok, svc = pcall(function()
    return game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.4.6"].knit.Services.TeleportManagerService
  end)
  if ok and svc then
    local ok2, res = pcall(function() return svc.RF.TeleportToLobby:InvokeServer() end)
    say("TeleportToLobby: " .. tostring(ok2) .. " " .. tostring(res))
  else
    say("TeleportManagerService tidak ketemu!")
  end
end

local function fireInstant(prompt)
  if not prompt then return end
  for i = 1, FIRE_REPEATS do
    pcall(function()
      if FIRE_HOLD > 0 then
        fireproximityprompt(prompt, FIRE_HOLD)
      else
        fireproximityprompt(prompt)
      end
    end)
    if i < FIRE_REPEATS then task.wait(FIRE_REPEAT_GAP) end
  end
end

local function openChest(entry)
  if _G.SafeMode then return "safe-mode" end
  if entry.Model and isMimicChest(entry.Model) then
    return "mimic-skip"
  end
  if entry.Model and entry.Model.Parent and isOpened(entry.Model, entry.Pos, entry.Model.Name) then
    return "already-opened"
  end
  local r = hrp()
  if not r then return "no-hrp" end
  local mname0 = entry.Model and entry.Model.Name or "?"

  for attempt = 1, MAX_OPEN_RETRY do
    if _G.SafeMode then return "safe-mode" end
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
          say("Looted CORES: " .. mname .. " (cores " .. coresBefore .. "->" .. coresAfter .. ", attempt " .. attempt .. ", blacklisted)")
        else
          say("Looted: " .. mname .. " (attempt " .. attempt .. ", blacklisted)")
        end
        refresh()
        return "ok"
      else
        say("Belum dapat cores " .. mname .. " (cores " .. tostring(coresBefore) .. ", attempt " .. attempt .. "/" .. MAX_OPEN_RETRY .. ") -> TP + buka lagi.")
        if attempt < MAX_OPEN_RETRY then
          task.wait(RETRY_GAP)
        end
      end
    end
  end
  say("Gagal buka " .. mname0 .. " setelah " .. MAX_OPEN_RETRY .. "x -> coba lagi lain waktu (tidak di-blacklist).")
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
  local x, z = start.X, start.Z
  if type(_G.ScanX) == "number" and _G.ScanX >= x and _G.ScanX <= SCAN_END_X then
    x = _G.ScanX
    say("Resuming scan from x=" .. math.floor(x) .. ".")
  else
    _G.ScanX = x
  end
  local r0 = hrp()
  local homeY = (r0 and r0.Position.Y) or 20
  say(string.format("START scan x=%.0f -> %.0f, step %d", x, SCAN_END_X, SCAN_STEP))
  while _G.TrackScan do
    if hpFrac() < SAFE_HP_ENTER then
      if not waitRecovery() then break end
    end
    local h0 = hum()
    if not h0 or h0.Health <= 0 then
      say("Dead - waiting respawn, scan lanjut...")
      local ok = pcall(function() player.CharacterAdded:Wait() end)
      task.wait(1.5)
      _G.SafeMode = false
    else
    if hpFrac() < HP_STOP_FRAC then
      say("HP critically low - retreat + regen, bukan stop.")
      waitRecovery()
    end
    if x > SCAN_END_X then
      say("Scan COMPLETE (garis akhir).")
      _G.ScanX = nil
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
      local scanPos = Vector3.new(x, homeY, z)
      pcall(function()
        r.AssemblyLinearVelocity = Vector3.zero
        r.CFrame = CFrame.new(scanPos)
      end)
      _G.ScanInfo = "x=" .. math.floor(x) .. "/" .. SCAN_END_X
      refresh()
      scanPos = dodgeWait(scanPos, SCAN_WAIT_STREAM)
      local found = {}
      for _, e in ipairs(allChests()) do
        if (e.Pos - scanPos).Magnitude <= SCAN_LOOT_R then
          table.insert(found, e)
        end
      end
      if #found > 0 then
        say("x=" .. math.floor(x) .. ": " .. #found .. " chests matched -> teleporting to loot...")
        for _, e in ipairs(found) do
          if not _G.TrackScan then break end
          if hpFrac() < SAFE_HP_ENTER then
            if not waitRecovery() then break end
          end
          if e.Model.Parent and not isLocked(e.Model) and not isOpened(e.Model, e.Pos, e.Model.Name) then
            local threats = threatsNear(e.Pos, SAFE_RADIUS)
            if #threats > 0 then
              skipped += 1
              say("SKIP " .. e.Model.Name .. ": " .. #threats .. " enemies nearby.")
              refresh()
              local rF = hrp()
              if rF then
                local fp = fleeFrom(rF.Position, SAFE_RADIUS)
                pcall(function()
                  rF.AssemblyLinearVelocity = Vector3.zero
                  rF.CFrame = CFrame.new(fp, fp + Vector3.new(0, 1, 0))
                end)
              end
            else
              dodgeStep(e.Pos)
              task.wait(0.1)
              local ok, res = pcall(openChest, e)
              if not ok then say("Error: " .. tostring(res)) end
            end
          end
          task.wait(0.15)
        end
        local r2 = hrp()
        if r2 then
          pcall(function()
            r2.AssemblyLinearVelocity = Vector3.zero
            r2.CFrame = CFrame.new(scanPos)
          end)
        end
        scanPos = dodgeWait(scanPos, 0.2)
      end
      x += SCAN_STEP
      _G.ScanX = x
    end
    end
    task.wait(0.1)
  end
  _G.__ScanRunning = false
  _G.ScanInfo = "-"
  if _G.SafeMode then exitSafeMode() end
  setScanBtn()
  say("STOP scan.")
end

local function farmLoop()
  if _G.__FarmRunning then return end
  _G.__FarmRunning = true
  say("START farm (auto). 0 boss attacks.")
  local r0 = hrp()
  local safeSpot = r0 and r0.CFrame or nil
  local idle = 0
  while _G.ChestFarm do
    if hpFrac() < SAFE_HP_ENTER then
      if not waitRecovery() then break end
    end
    local hf = hum()
    if not hf or hf.Health <= 0 then
      say("Dead - waiting respawn, farm lanjut...")
      pcall(function() player.CharacterAdded:Wait() end)
      task.wait(1.5)
      _G.SafeMode = false
    elseif hpFrac() < HP_STOP_FRAC then
      say("HP critically low - retreat + regen, bukan stop.")
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
      if idle >= 40 then say("Farm selesai (40x kosong) -> balik lobby, buat room lagi."); _G.ChestFarm = false; if not IN_LOBBY then gotoLobbyFinish() end; break end
      local rIdle = hrp()
      if rIdle then
        dodgeWait(rIdle.Position, SCAN_WAIT)
      else
        task.wait(SCAN_WAIT)
      end
    else
      idle = 0
      for _, e in ipairs(chests) do
        if not _G.ChestFarm then break end
        if hpFrac() < SAFE_HP_ENTER then
          if not waitRecovery() then break end
        end
        local threats = threatsNear(e.Pos, SAFE_RADIUS)
        if #threats > 0 then
          skipped += 1
          say("SKIP " .. e.Model.Name .. ": " .. #threats .. " enemies nearby.")
          refresh()
          local rS = hrp()
          if rS then
            local fp = fleeFrom(rS.Position, SAFE_RADIUS)
            pcall(function()
              rS.AssemblyLinearVelocity = Vector3.zero
              rS.CFrame = CFrame.new(fp, fp + Vector3.new(0, 1, 0))
            end)
          end
        else
          dodgeStep(e.Pos)
          task.wait(0.1)
          local ok, res = pcall(openChest, e)
          if not ok then say("Error: " .. tostring(res)) end
        end
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
  end
  setScanBtn()
  refresh()
  if _G.TrackScan then
    task.spawn(scanTrack)
  else
    say("Scan OFF.")
  end
end)

-- Patch 3: grace period 8 detik
local SKIP_GRACE = 8
local SKIP_ROUNDS = 15
local voteSkipRF = nil
local voteSkipPrivRF = nil
pcall(function()
  for _, d in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
    if d:IsA("RemoteFunction") then
      local fn = d:GetFullName()
      if fn:find("CutSceneService") then
        if d.Name == "VoteSkip" then voteSkipRF = d
        elseif d.Name == "VoteSkipPrivate" then voteSkipPrivRF = d end
      end
    end
  end
end)
local bootTime = os.clock()
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
      game:GetService("GuiService").SelectedObject = sk
      task.wait(0.2)
      local vim = game:GetService("VirtualInputManager")
      vim:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
      task.wait(0.1)
      vim:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end
  end)
end
local function autoSkipLoop()
  if not AUTO_SKIP_CUTSCENE then return end
  if _G.__SkipRunning then return end
  _G.__SkipRunning = true
  say("Auto-skip cutscene ON (aman: hanya saat tombol Skip ada).")
  while AUTO_SKIP_CUTSCENE do
    if os.clock() - bootTime >= SKIP_GRACE and skipVisible() then
      say("Cutscene skippable -> vote + tekan Skip.")
      for i = 1, SKIP_ROUNDS do
        if not skipVisible() then
          cutSkipped += 1
          say("Cutscene ke-skip (" .. cutSkipped .. ").")
          break
        end
        if voteSkipRF then pcall(function() voteSkipRF:InvokeServer() end) end
        if voteSkipPrivRF then pcall(function() voteSkipPrivRF:InvokeServer() end) end
        pressSkipBtn()
        task.wait(2)
      end
      if skipVisible() then
        say("Skip gagal (kuorum kurang?) - tombol dibiarkan untuk manual.")
      end
      task.wait(5)
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
    local vim = game:GetService("VirtualInputManager")
    for _, key in ipairs({ Enum.KeyCode.Space, Enum.KeyCode.E, Enum.KeyCode.Return }) do
      vim:SendKeyEvent(true, key, false, game)
      task.wait(0.05)
      vim:SendKeyEvent(false, key, false, game)
      task.wait(0.05)
    end
  end)
end
local function dialogueSkipLoop()
  if not AUTO_SKIP_DIALOGUE then return end
  if _G.__DialogRunning then return end
  _G.__DialogRunning = true
  say("Dialogue-skip ON (Crazy Zack).")
  while AUTO_SKIP_DIALOGUE do
    if os.clock() - bootTime >= SKIP_GRACE and dialogueActive() then
      local sp = dialogueSpeaker()
      say("Dialogue terdeteksi (" .. (sp ~= "" and sp or "?") .. ") -> majukan...")
      if voteSkipRF then pcall(function() voteSkipRF:InvokeServer() end) end
      if voteSkipPrivRF then pcall(function() voteSkipPrivRF:InvokeServer() end) end
      for i = 1, DIALOGUE_MAX do
        if not dialogueActive() then
          dialogSkipped += 1
          say("Dialogue selesai (" .. dialogSkipped .. ").")
          break
        end
        pressAdvance()
        task.wait(DIALOGUE_POLL)
      end
      if dialogueActive() then
        say("Dialogue masih jalan setelah " .. DIALOGUE_MAX .. "x - biarkan manual.")
      end
      task.wait(3)
    else
      task.wait(DIALOGUE_POLL)
    end
  end
  _G.__DialogRunning = false
end

setScanBtn()
if _G.ChestFarm then
  task.spawn(farmLoop)
elseif _G.TrackScan then
  task.spawn(scanTrack)
end
task.spawn(autoSkipLoop)
task.spawn(dialogueSkipLoop)
task.spawn(aimWatch)
say("Menu OK. Mode=" .. MODE .. ". Auto-dismount + Safe Mode + NoClip + Leave-on-loot + Blacklist + AutoSkip + AimDodge + DialogSkip.")
end -- tutup guard IsPlanet (else branch)
end -- tutup do Bagian 2
