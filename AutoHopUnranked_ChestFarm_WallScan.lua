-- ============================================================
-- AutoHopUnrankedSolo + AutoScan (1x inject, survive teleport)
-- ============================================================

--[[ GANTI: URL raw script ini (GitHub/Pastebin) biar bisa reload tiap teleport ]]
local URL_SCRIPT = "https://raw.githubusercontent.com/USER/REPO/main/AutoHopUnrankedSolo.lua"

--[[ GANTI: PlaceId lobby & planet (kalau kamu tahu) ]]
local PLACE_LOBBY  = 0   -- 0 = auto-detect via IsLobby
local PLACE_PLANET = 0   -- 0 = auto-detect via IsPlanet

-- ============================================================
-- UTIL
-- ============================================================
local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local function log(txt) print("[Loop] " .. tostring(txt)) end

-- state persisten antar-teleport
local STATE_FILE = "autohop_state.txt"
local function saveState(v) if writefile then pcall(writefile, STATE_FILE, tostring(v)) end end
local function loadState()
    if readfile and isfile and isfile(STATE_FILE) then
        local ok, v = pcall(readfile, STATE_FILE)
        if ok then return v == "true" end
    end
    return false
end

-- ============================================================
-- DETEKSI STATE (sesuaikan kalau kamu punya flag IsLobby / IsPlanet)
-- ============================================================
local function diLobby()
    if PLACE_LOBBY ~= 0 then return game.PlaceId == PLACE_LOBBY end
    -- heuristik: lobby punya PartyZone tags
    return #CollectionService:GetTagged("PartyZone") > 0
end

local function diPlanet()
    if PLACE_PLANET ~= 0 then return game.PlaceId == PLACE_PLANET end
    -- heuristik: planet = bukan lobby
    return not diLobby()
end

-- ============================================================
-- BAGIAN A: LOBBY -> START UNRANKED SOLO (dari script kamu)
-- ============================================================
local function startUnrankedSolo()
    log("== Mode LOBBY: start unranked solo ==")

    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart", 10)
    if not hrp then log("HRP tidak ada, batal.") ; return false end

    -- cari PartyZone unranked kosong
    local function findZone()
        local zones = CollectionService:GetTagged("PartyZone")
        for _, z in ipairs(zones) do
            if z:GetAttribute("Ranked") == false
                and (z:GetAttribute("State") == 0)
                and ((z:GetAttribute("PlayerCount") or 0) == 0) then
                return z
            end
        end
        for _, z in ipairs(zones) do
            if z:GetAttribute("Ranked") == false then return z end
        end
    end

    local zone = findZone()
    if not zone then log("Tidak ada PartyZone Unranked.") ; return false end
    log("Target: " .. zone:GetFullName())

    hrp.CFrame = zone.CFrame + Vector3.new(0, 3, 0)
    task.wait(2)

    -- pilih Unranked di UI
    pcall(function()
        local pg = LP:WaitForChild("PlayerGui", 5)
        local partyUI = pg:WaitForChild("UI", 5).Frames:WaitForChild("PartyCreate", 5)
        local deadline = os.clock() + 10
        while not partyUI.Visible and os.clock() < deadline do task.wait(0.25) end

        pcall(function() partyUI.PartySize.CountFrame.TextBox.Text = "1" end)

        local mapSelect = partyUI:FindFirstChild("MapSelect")
        if mapSelect then
            local unranked = mapSelect:FindFirstChild("Unranked")
            local ranked   = mapSelect:FindFirstChild("Ranked")
            local selectedWhite   = Color3.fromRGB(255, 255, 255)
            local unselectedGray  = Color3.fromRGB(120, 120, 120)
            for _, btn in ipairs({ unranked, ranked }) do
                if btn and btn:IsA("ImageButton") then
                    local isU = (btn == unranked)
                    local icon = btn:FindFirstChild("SelectIcon", true)
                    if icon then icon.Visible = isU end
                    local sh = btn:FindFirstChild("UIShadow")
                    if sh then pcall(function() sh.Enabled = isU end) end
                    local st = btn:FindFirstChildOfClass("UIStroke")
                    if st then st.Color = isU and selectedWhite or unselectedGray end
                end
            end
        end
    end)
    task.wait(0.5)

    local place = zone:GetAttribute("Place") or "Earth"

    -- invoke remote CreatedZone
    local ok, res = pcall(function()
        local svcFolder = ReplicatedStorage.Packages._Index["sleitnick_knit@1.4.6"]
            .knit.Services.TeleportManagerService
        local rf = svcFolder:WaitForChild("RF"):WaitForChild("CreatedZone")
        return rf:InvokeServer(zone, 1, place, false)
    end)
    log("CreatedZone ok=" .. tostring(ok) .. " res=" .. tostring(res))
    return ok and res and true or false
end

-- ============================================================
-- BAGIAN B: PLANET -> AUTO SCAN
-- ============================================================
local function autoScanInPlanet()
    log("== Mode PLANET: aktifkan auto scan ==")

    -- aktifkan flag global kalau game-nya baca _G
    _G.AutoScanInPlanet = true

    -- panggil track scan kalau ada
    if _G.TrackScan and type(_G.TrackScan) == "function" then
        pcall(_G.TrackScan)
        log("TrackScan dipanggil.")
    end

    -- fallback: klik tombol SCAN kalau muncul di UI
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        local btn = pg:FindFirstChild("SCAN", true)
        if btn and btn:IsA("GuiButton") and btn.Visible then
            pcall(function() btn:Activate() end)
            log("Tombol SCAN ditekan.")
        end
    end

    -- (opsional) loop cek terus kalau scan perlu diulang
    -- task.spawn(function()
    --     while diPlanet() do
    --         task.wait(5)
    --         if _G.TrackScan then pcall(_G.TrackScan) end
    --     end
    -- end)
end

-- ============================================================
-- QUEUE TELEPORT: reload script ini setiap pindah place
-- ============================================================
local function queueDiriSendiri()
    if not queue_on_teleport then
        warn("[Loop] queue_on_teleport tidak ada. Pakai autoexec executor.")
        return
    end
    if URL_SCRIPT == "" or URL_SCRIPT:find("USER/REPO") then
        warn("[Loop] URL_SCRIPT belum diisi. Script tidak akan reload otomatis.")
        return
    end
    queue_on_teleport(([[
        loadstring(game:HttpGet("%s"))()
    ]]):format(URL_SCRIPT))
    log("Queued reload untuk teleport berikutnya.")
end

-- ============================================================
-- MAIN
-- ============================================================
queueDiriSendiri()

if diLobby() then
    log("Terdeteksi di LOBBY.")
    saveState(false)
    task.wait(1)
    local ok = startUnrankedSolo()
    if ok then
        saveState(true)
        log("Solo unranked dimulai, tunggu teleport ke planet...")
    else
        log("Gagal start solo unranked.")
    end

elseif diPlanet() then
    log("Terdeteksi di PLANET.")
    if not loadState() then
        -- fresh masuk planet (bukan reload dobel) -> jalankan scan
        autoScanInPlanet()
        saveState(true)
    else
        log("Sudah pernah scan di sesi ini, skip (reset saat ke lobby).")
    end

else
    warn("[Loop] State tidak dikenali (bukan lobby, bukan planet).")
end
