--[[
    NOVA HUB v2  |  Xeno-compatible
    ESP • Tracers • Aimbot • Hitbox Expander (с фиксом сброса) • Noclip • Fly • Invisible 
    Infinite Jump • Speed • Jump • FOV • FPS Boost • Fullbright • Anti-AFK • Auto Pickup 
    Anti-Void • Discord Copy • Key System • Splash Loader
    
    Меню: RightShift (открыть / закрыть)
    Аимбот: удерживай ПКМ
    Полёт: WASD + Space (вверх) + LeftCtrl (вниз)
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local VirtualUser = game:GetService("VirtualUser")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

---------------------------------------------------------------------
-- Настройки
---------------------------------------------------------------------
local CORRECT_KEY = "NOVA-KEY-2026" -- Ваш ключ доступа
local DISCORD_LINK = "https://discord.gg/ZZZ228tX5" -- Ссылка на ваш Discord для получения ключа

---------------------------------------------------------------------
-- Защита от повторного запуска
---------------------------------------------------------------------
local env = (getgenv and getgenv()) or _G
if env.NovaUnload then pcall(env.NovaUnload) end

local function getGuiParent()
    local ok, res = pcall(function()
        return (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if ok and res then return res end
    return LP:WaitForChild("PlayerGui")
end

---------------------------------------------------------------------
-- Состояние
---------------------------------------------------------------------
local state = {
    esp = false, aim = false, team = false,
    noclip = false, fly = false, inv = false, ijump = false,
    speedOn = false, jumpOn = false, fovOn = false,
    fpsBoost = false,

    flySpeed = 60,
    fov = 150,
    smooth = 25,
    walkSpeed = 50,
    jumpPower = 100,
    camFov = 90,

    expandHitbox = false, hitboxSize = 8,
    tracers = false,
    fullbright = false,
    antiAfk = false,
    autoPick = false,
    antiVoid = false,
}

local connections = {}
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

---------------------------------------------------------------------
-- Тема и помощники
---------------------------------------------------------------------
local BG      = Color3.fromRGB(14, 14, 22)
local PANEL   = Color3.fromRGB(22, 22, 36)
local ROW     = Color3.fromRGB(32, 32, 50)
local ACCENT  = Color3.fromRGB(140, 90, 255)
local ACCENT2 = Color3.fromRGB(60, 200, 255)
local TEXT    = Color3.fromRGB(235, 235, 250)
local DIM     = Color3.fromRGB(150, 150, 180)
local OFF     = Color3.fromRGB(55, 55, 78)

local function make(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function corner(parent, r)
    return make("UICorner", { CornerRadius = UDim.new(0, r or 8) }, parent)
end
local function gradient(parent, rot)
    return make("UIGradient", { Color = ColorSequence.new(ACCENT, ACCENT2), Rotation = rot or 0 }, parent)
end

local gui = make("ScreenGui", {
    Name = "NovaHub",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
}, nil)
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
gui.Parent = getGuiParent()

---------------------------------------------------------------------
-- HUD: FPS / PING COUNTER
---------------------------------------------------------------------
local statsFrame = make("Frame", {
    Position = UDim2.fromOffset(15, 15),
    Size = UDim2.fromOffset(200, 32),
    BackgroundColor3 = PANEL, BorderSizePixel = 0, ZIndex = 100,
}, gui)
corner(statsFrame, 10)
make("UIStroke", { Color = ACCENT, Thickness = 1 }, statsFrame)

local statsLbl = make("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TEXT,
    Text = "FPS: 60  |  Ping: 0ms  |  Plrs: 0", ZIndex = 101,
}, statsFrame)

local lastCheck, frameCount, currentFps = os.clock(), 0, 60
connect(RS.RenderStepped, function()
    frameCount += 1
    local now = os.clock()
    if now - lastCheck >= 1 then
        currentFps = frameCount
        frameCount = 0
        lastCheck = now
        
        local ping = math.floor((Stats.Network.ServerStatsItem["Data Ping"]:GetValue() or 0))
        local plrCount = #Players:GetPlayers()
        statsLbl.Text = string.format("FPS: %d  |  Ping: %dms  |  Plrs: %d", currentFps, ping, plrCount)
    end
end)

---------------------------------------------------------------------
-- FPS BOOST & FULLBRIGHT ЛОГИКА
---------------------------------------------------------------------
local originalLighting = {
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
}
local optimizedParts = {}

local function setFPSBoost(on)
    if on then
        originalLighting.GlobalShadows = Lighting.GlobalShadows
        originalLighting.FogEnd = Lighting.FogEnd
        originalLighting.Brightness = Lighting.Brightness

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 999999
        Lighting.Brightness = 2

        for _, d in ipairs(Lighting:GetChildren()) do
            if d:IsA("PostEffect") or d:IsA("Atmosphere") or d:IsA("Sky") then
                d.Enabled = false
            end
        end

        local function optimizePart(p)
            if p:IsA("BasePart") then
                optimizedParts[p] = { Material = p.Material, Reflectance = p.Reflectance }
                p.Material = Enum.Material.Plastic
                p.Reflectance = 0
                p.CastShadow = false
            elseif p:IsA("Decal") or p:IsA("Texture") then
                optimizedParts[p] = { Transparency = p.Transparency }
                p.Transparency = 1
            end
        end

        for _, obj in ipairs(workspace:GetDescendants()) do optimizePart(obj) end
        connect(workspace.DescendantAdded, optimizePart)
    else
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.Brightness = originalLighting.Brightness

        for _, d in ipairs(Lighting:GetChildren()) do
            if d:IsA("PostEffect") or d:IsA("Atmosphere") or d:IsA("Sky") then
                d.Enabled = true
            end
        end

        for obj, props in pairs(optimizedParts) do
            if obj and obj.Parent then
                for prop, val in pairs(props) do obj[prop] = val end
            end
        end
        optimizedParts = {}
    end
end

local function setFullbright(on)
    if on then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 3
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = originalLighting.Ambient or Color3.fromRGB(128, 128, 128)
        Lighting.Brightness = originalLighting.Brightness or 1
        Lighting.GlobalShadows = originalLighting.GlobalShadows
    end
end

---------------------------------------------------------------------
-- ESP & TRACERS
---------------------------------------------------------------------
local espObjs = {}
local tracerObjs = {}

local function removeESP(p)
    local o = espObjs[p]
    if o then
        pcall(function() o.hl:Destroy() end)
        pcall(function() o.bb:Destroy() end)
        espObjs[p] = nil
    end
    if tracerObjs[p] then
        pcall(function() tracerObjs[p]:Remove() end)
        tracerObjs[p] = nil
    end
end

local function applyESP(p)
    removeESP(p)
    if p == LP then return end
    local c = p.Character
    local head = c and c:FindFirstChild("Head")
    if not head then return end

    if state.esp then
        local hl = make("Highlight", {
            FillColor = ACCENT, FillTransparency = 0.55,
            OutlineColor = Color3.new(1, 1, 1), OutlineTransparency = 0,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        }, c)
        local bb = make("BillboardGui", {
            Size = UDim2.fromOffset(150, 34), StudsOffset = Vector3.new(0, 2.6, 0),
            AlwaysOnTop = true, Adornee = head,
        }, c)
        local lbl = make("TextLabel", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = TEXT,
            TextStrokeTransparency = 0.3, Text = p.Name,
        }, bb)
        espObjs[p] = { hl = hl, bb = bb, lbl = lbl }
    end

    if state.tracers and Drawing then
        local line = Drawing.new("Line")
        line.Color = ACCENT2
        line.Thickness = 1.5
        line.Transparency = 1
        tracerObjs[p] = line
    end
end

local function refreshESP()
    for _, p in ipairs(Players:GetPlayers()) do
        applyESP(p)
    end
end

local function hookPlayer(p)
    if p == LP then return end
    connect(p.CharacterAdded, function()
        task.wait(0.3)
        applyESP(p)
    end)
end
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
connect(Players.PlayerAdded, hookPlayer)
connect(Players.PlayerRemoving, removeESP)

---------------------------------------------------------------------
-- FLY / NOCLIP / JUMP / INVISIBLE / ANTI-AFK
---------------------------------------------------------------------
local flyBV, flyBG

local function stopFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

local invSeat, invWeld
local savedTransparency = {}

local function setInvisible(on)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
    if not (char and root and torso) then return end

    if on then
        local saved = root.CFrame
        root.CFrame = CFrame.new(-25.95, 84, 3537.55)
        task.wait(0.15)
        invSeat = make("Seat", {
            Name = "NovaSeat", Anchored = false, CanCollide = false,
            Transparency = 1, Position = Vector3.new(-25.95, 84, 3537.55),
        }, workspace)
        invWeld = make("Weld", { Part0 = invSeat, Part1 = torso }, invSeat)
        task.wait()
        invSeat.CFrame = saved

        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("Decal") then
                savedTransparency[d] = d.Transparency
                if d.Name ~= "HumanoidRootPart" then d.Transparency = 0.6 end
            end
        end
    else
        if invWeld then invWeld:Destroy() invWeld = nil end
        if invSeat then invSeat:Destroy() invSeat = nil end
        for part, tr in pairs(savedTransparency) do
            if part and part.Parent then part.Transparency = tr end
        end
        savedTransparency = {}
    end
end

connect(UIS.JumpRequest, function()
    if state.ijump then
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

connect(RS.Stepped, function()
    if state.noclip and LP.Character then
        for _, d in ipairs(LP.Character:GetDescendants()) do
            if d:IsA("BasePart") and d.CanCollide then d.CanCollide = false end
        end
    end
end)

connect(LP.Idled, function()
    if state.antiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end
end)

---------------------------------------------------------------------
-- AIMBOT & HITBOX EXPANDER (С ИСПРАВЛЕНИЕМ БАГА СБРОСА)
---------------------------------------------------------------------
local fovCircle = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false,
}, gui)
corner(fovCircle, 999)
make("UIStroke", { Color = ACCENT2, Thickness = 1.5, Transparency = 0.2 }, fovCircle)

local function getTarget()
    local best, bestDist = nil, state.fov
    local mouse = UIS:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local sameTeam = state.team and p.Team ~= nil and p.Team == LP.Team
            if head and hum and hum.Health > 0 and not sameTeam then
                local pos, vis = Camera:WorldToViewportPoint(head.Position)
                if vis then
                    local d = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    if d < bestDist then best, bestDist = head, d end
                end
            end
        end
    end
    return best
end

-- Функция сброса хитбоксов при выключении
local function resetHitboxes()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            hrp.Size = Vector3.new(2, 2, 1) -- Стандартный размер туловища в Roblox
            hrp.Transparency = 1 -- Стандартная невидимость HRP
            hrp.CanCollide = true
        end
    end
end

---------------------------------------------------------------------
-- ГЛАВНЫЙ ЦИКЛ (RENDER STEPPED / HEARTBEAT)
---------------------------------------------------------------------
connect(RS.RenderStepped, function()
    Camera = workspace.CurrentCamera
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    -- ESP Дистанция & Tracers
    if root then
        for p, o in pairs(espObjs) do
            local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if r and o.lbl then
                o.lbl.Text = string.format("%s [%dm]", p.Name, math.floor((r.Position - root.Position).Magnitude))
            end
        end

        for p, line in pairs(tracerObjs) do
            local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if r and line then
                local pos, vis = Camera:WorldToViewportPoint(r.Position)
                if vis then
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(pos.X, pos.Y)
                    line.Visible = true
                else
                    line.Visible = false
                end
            end
        end
    end

    -- Hitbox Expander логика
    if state.expandHitbox then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = p.Character.HumanoidRootPart
                hrp.Size = Vector3.new(state.hitboxSize, state.hitboxSize, state.hitboxSize)
                hrp.Transparency = 0.7
                hrp.CanCollide = false
            end
        end
    end

    -- Физика персонажа
    if hum then
        if state.speedOn then hum.WalkSpeed = state.walkSpeed end
        if state.jumpOn then
            hum.UseJumpPower = true
            hum.JumpPower = state.jumpPower
        end
    end
    if state.fovOn then Camera.FieldOfView = state.camFov end

    -- Аимбот
    fovCircle.Visible = state.aim
    if state.aim then
        local m = UIS:GetMouseLocation()
        fovCircle.Position = UDim2.fromOffset(m.X, m.Y)
        fovCircle.Size = UDim2.fromOffset(state.fov * 2, state.fov * 2)
        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local t = getTarget()
            if t then
                local goal = CFrame.new(Camera.CFrame.Position, t.Position)
                Camera.CFrame = Camera.CFrame:Lerp(goal, math.clamp(state.smooth / 100, 0.02, 1))
            end
        end
    end

    -- Полёт
    if state.fly and root and hum then
        if not flyBV or flyBV.Parent ~= root then
            if flyBV then flyBV:Destroy() end
            if flyBG then flyBG:Destroy() end
            flyBV = make("BodyVelocity", { MaxForce = Vector3.new(1e9, 1e9, 1e9), Velocity = Vector3.zero }, root)
            flyBG = make("BodyGyro", { MaxTorque = Vector3.new(1e9, 1e9, 1e9), P = 9e4 }, root)
        end
        hum.PlatformStand = true

        local cf = Camera.CFrame
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
        flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * state.flySpeed or Vector3.zero
        flyBG.CFrame = cf
    end
end)

-- Heartbeat (Auto Pickup & Anti Void)
connect(RS.Heartbeat, function()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if state.autoPick then
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
                obj.Handle.CFrame = root.CFrame
            end
        end
    end

    if state.antiVoid then
        if root.Position.Y < (workspace.FallenPartsDestroyHeight + 15) then
            root.Velocity = Vector3.zero
            root.CFrame = CFrame.new(root.Position.X, 50, root.Position.Z)
        end
    end
end)

---------------------------------------------------------------------
-- МЕНЮ
---------------------------------------------------------------------
local MENU_W, MENU_H = 660, 430

local menu = make("Frame", {
    Name = "Menu",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(MENU_W, MENU_H),
    BackgroundColor3 = BG, BorderSizePixel = 0, Visible = false, ClipsDescendants = true,
}, gui)
corner(menu, 16)
local menuStroke = make("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1) }, menu)
gradient(menuStroke, 45)
local menuScale = make("UIScale", { Scale = 0 }, menu)

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = PANEL, BorderSizePixel = 0,
}, menu)
corner(header, 16)
make("Frame", {
    Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -16),
    BackgroundColor3 = PANEL, BorderSizePixel = 0,
}, header)

local title = make("TextLabel", {
    Size = UDim2.fromOffset(200, 30), Position = UDim2.fromOffset(20, 6),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 24,
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1),
    Text = "NOVA HUB",
}, header)
gradient(title, 0)

make("TextLabel", {
    Size = UDim2.fromOffset(200, 14), Position = UDim2.fromOffset(20, 36),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = DIM,
    Text = "v2.0  •  Xeno Edition",
}, header)

local keyPill = make("Frame", {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -62, 0.5, 0),
    Size = UDim2.fromOffset(250, 30), BackgroundColor3 = ROW, BorderSizePixel = 0,
}, header)
corner(keyPill, 15)
make("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold, TextSize = 13, TextColor3 = TEXT,
    Text = "RightShift  —  открыть / закрыть",
}, keyPill)

local closeBtn = make("TextButton", {
    Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -48, 0.5, -17),
    BackgroundColor3 = ROW, Font = Enum.Font.GothamBold, TextSize = 18,
    TextColor3 = TEXT, Text = "–",
}, header)
corner(closeBtn, 9)

do
    local dragging, dragStart, startPos
    connect(header.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, i.Position, menu.Position
        end
    end)
    connect(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            menu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    connect(UIS.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local footer = make("Frame", {
    Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 1, -30),
    BackgroundColor3 = PANEL, BorderSizePixel = 0,
}, menu)
make("TextLabel", {
    Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12,
    TextColor3 = DIM,
    Text = "RightShift — меню   •   ПКМ — аимбот   •   WASD + Space / Ctrl — полёт",
}, footer)

local sidebar = make("Frame", {
    Size = UDim2.fromOffset(150, MENU_H - 58 - 30 - 20),
    Position = UDim2.fromOffset(10, 68), BackgroundTransparency = 1,
}, menu)
make("UIListLayout", { Padding = UDim.new(0, 8) }, sidebar)

local content = make("Frame", {
    Size = UDim2.fromOffset(MENU_W - 150 - 30, MENU_H - 58 - 30 - 20),
    Position = UDim2.fromOffset(170, 68), BackgroundTransparency = 1,
}, menu)

local pages, tabButtons, pageOrder = {}, {}, {}

local function nextOrder(page)
    pageOrder[page] = (pageOrder[page] or 0) + 1
    return pageOrder[page]
end

local function selectTab(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabButtons) do
        local active = (n == name)
        TS:Create(b, TweenInfo.new(0.2), {
            BackgroundTransparency = active and 0 or 1,
            TextColor3 = active and Color3.new(1, 1, 1) or DIM,
        }):Play()
    end
end

local function newTab(name)
    local btn = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = ACCENT, BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = DIM,
        Text = name, AutoButtonColor = false,
    }, sidebar)
    corner(btn, 10)
    tabButtons[name] = btn

    local page = make("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = ACCENT,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, content)
    make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, page)
    pages[name] = page

    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    return page
end

local function section(page, text)
    make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = ACCENT2,
        Text = "  " .. string.upper(text), LayoutOrder = nextOrder(page),
    }, page)
end

local function toggle(page, name, desc, key, onChange)
    local row = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = ROW,
        Text = "", AutoButtonColor = false, LayoutOrder = nextOrder(page),
    }, page)
    corner(row, 10)

    make("TextLabel", {
        Size = UDim2.new(1, -90, 0, 22), Position = UDim2.fromOffset(14, 6),
        BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = TEXT, Text = name,
    }, row)
    make("TextLabel", {
        Size = UDim2.new(1, -90, 0, 14), Position = UDim2.fromOffset(14, 28),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = DIM, Text = desc,
    }, row)

    local sw = make("Frame", {
        Size = UDim2.fromOffset(46, 24), Position = UDim2.new(1, -60, 0.5, -12),
        BackgroundColor3 = OFF, BorderSizePixel = 0,
    }, row)
    corner(sw, 12)
    local knob = make("Frame", {
        Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
    }, sw)
    corner(knob, 9)

    row.MouseButton1Click:Connect(function()
        state[key] = not state[key]
        local on = state[key]
        TS:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            Position = on and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
        }):Play()
        TS:Create(sw, TweenInfo.new(0.18), { BackgroundColor3 = on and ACCENT or OFF }):Play()
        if onChange then task.spawn(onChange, on) end
    end)
end

local function slider(page, name, key, min, max, suffix, onChange)
    suffix = suffix or ""
    local step = math.max(1, math.floor((max - min) / 40))

    local row = make("Frame", {
        Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = ROW, LayoutOrder = nextOrder(page),
    }, page)
    corner(row, 10)

    make("TextLabel", {
        Size = UDim2.new(0.5, 0, 0, 22), Position = UDim2.fromOffset(14, 6),
        BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = TEXT, Text = name,
    }, row)

    local valLbl = make("TextLabel", {
        Size = UDim2.fromOffset(64, 22), Position = UDim2.new(1, -128, 0, 6),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 15,
        TextColor3 = ACCENT2, Text = state[key] .. suffix,
    }, row)

    local hit = make("TextButton", {
        Size = UDim2.new(1, -28, 0, 26), Position = UDim2.fromOffset(14, 30),
        BackgroundTransparency = 1, Text = "",
    }, row)
    local track = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = Color3.fromRGB(50, 50, 72),
        BorderSizePixel = 0,
    }, hit)
    corner(track, 3)
    local fill = make("Frame", {
        Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
    }, track)
    corner(fill, 3)
    gradient(fill, 0)
    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(18, 18),
        Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, ZIndex = 2,
    }, track)
    corner(knob, 9)
    make("UIStroke", { Color = ACCENT, Thickness = 2.5 }, knob)

    local function setValue(v)
        v = math.clamp(math.floor(v + 0.5), min, max)
        state[key] = v
        valLbl.Text = v .. suffix
        local rel = (v - min) / (max - min)
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.fromScale(rel, 0.5)
        if onChange then onChange(v) end
    end
    setValue(state[key])

    local function btn(txt, x, delta)
        local b = make("TextButton", {
            Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, x, 0, 7),
            BackgroundColor3 = PANEL, Font = Enum.Font.GothamBold, TextSize = 16,
            TextColor3 = TEXT, Text = txt,
        }, row)
        corner(b, 7)
        b.MouseButton1Click:Connect(function() setValue(state[key] + delta) end)
    end
    btn("-", -62, -step)
    btn("+", -34, step)

    local dragging = false
    local function fromMouse()
        local x = UIS:GetMouseLocation().X
        local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        setValue(min + rel * (max - min))
    end
    hit.MouseButton1Down:Connect(function() dragging = true fromMouse() end)
    connect(UIS.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    connect(RS.RenderStepped, function() if dragging then fromMouse() end end)
end

---------------------------------------------------------------------
-- Вкладки
---------------------------------------------------------------------
local tabVisual = newTab("Визуал")
local tabCombat = newTab("Бой")
local tabMove   = newTab("Движение")
local tabAuto   = newTab("Авто")
local tabMisc   = newTab("Прочее")

-- Визуал
section(tabVisual, "Игроки")
toggle(tabVisual, "ESP / WH", "Подсветка и ники игроков сквозь стены", "esp", refreshESP)
toggle(tabVisual, "ESP Tracers", "Линии от экрана к игрокам", "tracers", refreshESP)

section(tabVisual, "Оптимизация и Свет")
toggle(tabVisual, "FPS Boost", "Убрать тени, текстуры и эффекты для FPS", "fpsBoost", setFPSBoost)
toggle(tabVisual, "Fullbright", "Убрать темноту и выкрутить яркость", "fullbright", setFullbright)

section(tabVisual, "Камера")
toggle(tabVisual, "Свой FOV камеры", "Включить изменение угла обзора", "fovOn", function(on)
    if not on then workspace.CurrentCamera.FieldOfView = 70 end
end)
slider(tabVisual, "FOV камеры", "camFov", 30, 120, "°")

-- Бой
section(tabCombat, "Аимбот")
toggle(tabCombat, "Aimbot", "Удерживай ПКМ — наведение на голову", "aim")
toggle(tabCombat, "Team Check", "Не целиться в свою команду", "team")
slider(tabCombat, "Радиус FOV аима", "fov", 50, 500, "")
slider(tabCombat, "Плавность наведения", "smooth", 5, 100, "%")

section(tabCombat, "Модификация хитбоксов")
toggle(tabCombat, "Hitbox Expander", "Увеличить размер хитбоксов врагов", "expandHitbox", function(on)
    if not on then resetHitboxes() end
end)
slider(tabCombat, "Размер хитбокса", "hitboxSize", 2, 20, " studs")

-- Движение
section(tabMove, "Полёт")
toggle(tabMove, "Fly", "WASD + Space / LeftCtrl", "fly", function(on)
    if not on then stopFly() end
end)
slider(tabMove, "Скорость полёта", "flySpeed", 10, 300, "")

section(tabMove, "Скорость и прыжок")
toggle(tabMove, "Speed Hack", "Своя скорость бега", "speedOn", function(on)
    if not on then
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = 16 end
    end
end)
slider(tabMove, "Скорость бега", "walkSpeed", 16, 250, "")
toggle(tabMove, "Jump Power", "Своя высота прыжка", "jumpOn", function(on)
    if not on then
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h.JumpPower = 50 end
    end
end)
slider(tabMove, "Сила прыжка", "jumpPower", 50, 400, "")

section(tabMove, "Другое")
toggle(tabMove, "Noclip", "Проход сквозь стены", "noclip")
toggle(tabMove, "Infinite Jump", "Бесконечный прыжок", "ijump")

-- Авто
section(tabAuto, "Автоматизация")
toggle(tabAuto, "Anti-AFK", "Защита от вылета за простоя (20 мин)", "antiAfk")
toggle(tabAuto, "Auto Pickup Tools", "Автоматически подбирать предметы с земли", "autoPick")
toggle(tabAuto, "Anti-Void", "Спасать при падении за карту", "antiVoid")

-- Прочее
section(tabMisc, "Скрытность")
toggle(tabMisc, "Invisible", "Невидимость для других (зависит от игры)", "inv", setInvisible)

section(tabMisc, "Сообщество")
local discordBtn = make("TextButton", {
    Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Color3.fromRGB(88, 101, 242),
    Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1, 1, 1),
    Text = "Скопировать Discord (получить ключ)", LayoutOrder = nextOrder(tabMisc),
}, tabMisc)
corner(discordBtn, 10)
discordBtn.MouseButton1Click:Connect(function()
    pcall(function() setclipboard(DISCORD_LINK) end)
    discordBtn.Text = "Ссылка скопирована в буфер обмена!"
    task.wait(1.5)
    discordBtn.Text = "Скопировать Discord (получить ключ)"
end)

section(tabMisc, "Скрипт")
local unloadBtn = make("TextButton", {
    Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Color3.fromRGB(170, 50, 70),
    Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1, 1, 1),
    Text = "Выгрузить скрипт", LayoutOrder = nextOrder(tabMisc),
}, tabMisc)
corner(unloadBtn, 10)

selectTab("Визуал")

---------------------------------------------------------------------
-- Меню и выгрузка
---------------------------------------------------------------------
local hintPill = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 40),
    Size = UDim2.fromOffset(300, 34), BackgroundColor3 = PANEL, BorderSizePixel = 0,
}, gui)
corner(hintPill, 17)
local hintStroke = make("UIStroke", { Thickness = 1.5, Color = Color3.new(1, 1, 1) }, hintPill)
gradient(hintStroke, 0)
make("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold, TextSize = 13, TextColor3 = TEXT,
    Text = "RightShift — открыть меню",
}, hintPill)

local menuOpen = false
local function showMenu(open)
    menuOpen = open
    if open then
        menu.Visible = true
        TS:Create(menuScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        TS:Create(hintPill, TweenInfo.new(0.25), { Position = UDim2.new(0.5, 0, 1, 40) }):Play()
    else
        local t = TS:Create(menuScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 })
        t:Play()
        TS:Create(hintPill, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 1, -20) }):Play()
        t.Completed:Wait()
        if not menuOpen then menu.Visible = false end
    end
end

closeBtn.MouseButton1Click:Connect(function() showMenu(false) end)
connect(UIS.InputBegan, function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.RightShift then
        showMenu(not menuOpen)
    end
end)

local function unload()
    state.fly, state.noclip, state.aim, state.esp, state.ijump, state.fpsBoost = false, false, false, false, false, false
    state.speedOn, state.jumpOn, state.fovOn, state.tracers, state.expandHitbox = false, false, false, false, false
    state.antiAfk, state.autoPick, state.antiVoid, state.fullbright = false, false, false, false
    stopFly()
    setFPSBoost(false)
    setFullbright(false)
    resetHitboxes()
    pcall(function()
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = 16 h.JumpPower = 50 end
        workspace.CurrentCamera.FieldOfView = 70
    end)
    if state.inv then state.inv = false pcall(setInvisible, false) end
    for p in pairs(espObjs) do removeESP(p) end
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    connections = {}
    pcall(function() gui:Destroy() end)
    env.NovaUnload = nil
end
env.NovaUnload = unload
unloadBtn.MouseButton1Click:Connect(unload)

---------------------------------------------------------------------
-- KEY SYSTEM & SPLASH LOADER
---------------------------------------------------------------------
local function showKeySystem(onSuccess)
    local keyGui = make("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 10, 18),
        BorderSizePixel = 0, ZIndex = 60,
    }, gui)
    
    local keyBoxFrame = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(400, 260), BackgroundColor3 = BG, BorderSizePixel = 0, ZIndex = 61,
    }, keyGui)
    corner(keyBoxFrame, 14)
    make("UIStroke", { Thickness = 2, Color = ACCENT }, keyBoxFrame)

    make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 20),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 22,
        TextColor3 = TEXT, Text = "NOVA HUB | Ввод ключа", ZIndex = 62,
    }, keyBoxFrame)

    make("TextLabel", {
        Size = UDim2.new(1, -40, 0, 20), Position = UDim2.fromOffset(20, 55),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13,
        TextColor3 = DIM, Text = "Введите ключ доступа для запуска скрипта", ZIndex = 62,
    }, keyBoxFrame)

    local textBoxBg = make("Frame", {
        Size = UDim2.fromOffset(340, 42), Position = UDim2.fromOffset(30, 90),
        BackgroundColor3 = ROW, BorderSizePixel = 0, ZIndex = 62,
    }, keyBoxFrame)
    corner(textBoxBg, 8)

    local textBox = make("TextBox", {
        Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 14,
        TextColor3 = TEXT, PlaceholderText = "Вставьте ключ сюда...", PlaceholderColor3 = DIM,
        Text = "", ClearTextOnFocus = false, ZIndex = 63,
    }, textBoxBg)

    local checkBtn = make("TextButton", {
        Size = UDim2.fromOffset(340, 38), Position = UDim2.fromOffset(30, 142),
        BackgroundColor3 = ACCENT, Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = TEXT, Text = "Подтвердить", ZIndex = 62,
    }, keyBoxFrame)
    corner(checkBtn, 8)

    local getDiscordBtn = make("TextButton", {
        Size = UDim2.fromOffset(340, 38), Position = UDim2.fromOffset(30, 188),
        BackgroundColor3 = Color3.fromRGB(88, 101, 242), Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = TEXT, Text = "Получить ключ (Discord)", ZIndex = 62,
    }, keyBoxFrame)
    corner(getDiscordBtn, 8)

    checkBtn.MouseButton1Click:Connect(function()
        if textBox.Text == CORRECT_KEY then
            TS:Create(keyGui, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
            TS:Create(keyBoxFrame, TweenInfo.new(0.4), { Size = UDim2.fromOffset(0, 0) }):Play()
            task.wait(0.4)
            keyGui:Destroy()
            onSuccess()
        else
            textBox.Text = ""
            textBox.PlaceholderText = "Неверный ключ! Попробуйте снова"
        end
    end)

    getDiscordBtn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(DISCORD_LINK) end)
        getDiscordBtn.Text = "Ссылка скопирована!"
        task.wait(1.5)
        getDiscordBtn.Text = "Получить ключ (Discord)"
    end)
end

local function startLoader()
    local splash = make("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 8, 16),
        BorderSizePixel = 0, ZIndex = 50,
    }, gui)
    make("UIGradient", {
        Color = ColorSequence.new(Color3.fromRGB(10, 8, 24), Color3.fromRGB(4, 14, 28)),
        Rotation = 45,
    }, splash)

    local function orb(x, y, size, color)
        local o = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y),
            Size = UDim2.fromOffset(size, size), BackgroundColor3 = color,
            BackgroundTransparency = 0.88, BorderSizePixel = 0, ZIndex = 50,
        }, splash)
        corner(o, 999)
        TS:Create(o, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Size = UDim2.fromOffset(size * 1.25, size * 1.25), BackgroundTransparency = 0.93,
        }):Play()
    end
    orb(0.2, 0.25, 320, ACCENT)
    orb(0.8, 0.75, 380, ACCENT2)

    local logo = make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.40),
        Size = UDim2.fromOffset(500, 90), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack, TextSize = 72, TextColor3 = Color3.new(1, 1, 1),
        Text = "NOVA HUB", TextTransparency = 1, ZIndex = 51,
    }, splash)
    local logoGrad = gradient(logo, 0)
    TS:Create(logoGrad, TweenInfo.new(2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), { Rotation = 90 }):Play()

    local sub = make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47),
        Size = UDim2.fromOffset(500, 24), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 16, TextColor3 = DIM,
        Text = "Roblox Utility  •  Xeno Edition  •  v2.0",
        TextTransparency = 1, ZIndex = 51,
    }, splash)

    local barBg = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.58),
        Size = UDim2.fromOffset(340, 8), BackgroundColor3 = Color3.fromRGB(30, 30, 48),
        BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 51,
    }, splash)
    corner(barBg, 4)
    local barFill = make("Frame", {
        Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 52,
    }, barBg)
    corner(barFill, 4)
    gradient(barFill, 0)

    local status = make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.63),
        Size = UDim2.fromOffset(400, 20), BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = TEXT,
        Text = "", TextTransparency = 1, ZIndex = 51,
    }, splash)

    local keyHint = make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -30),
        Size = UDim2.fromOffset(500, 20), BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = DIM,
        Text = "RightShift — открыть / закрыть меню",
        TextTransparency = 1, ZIndex = 51,
    }, splash)

    task.spawn(function()
        local fadeIn = TweenInfo.new(0.6, Enum.EasingStyle.Quad)
        TS:Create(logo, fadeIn, { TextTransparency = 0 }):Play()
        TS:Create(sub, fadeIn, { TextTransparency = 0 }):Play()
        TS:Create(barBg, fadeIn, { BackgroundTransparency = 0 }):Play()
        TS:Create(barFill, fadeIn, { BackgroundTransparency = 0 }):Play()
        TS:Create(status, fadeIn, { TextTransparency = 0 }):Play()
        TS:Create(keyHint, fadeIn, { TextTransparency = 0 }):Play()
        task.wait(0.7)

        local steps = {
            { "Инициализация...", 0.15 },
            { "Загрузка модулей и FPS Boost...", 0.35 },
            { "Подготовка ESP и аимбота...", 0.58 },
            { "Настройка движения...", 0.80 },
            { "Сборка меню...", 0.94 },
            { "Готово!", 1 },
        }
        for _, s in ipairs(steps) do
            status.Text = s[1]
            TS:Create(barFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(s[2], 1) }):Play()
            task.wait(0.55)
        end
        task.wait(0.25)

        local out = TweenInfo.new(0.6, Enum.EasingStyle.Quad)
        for _, d in ipairs(splash:GetDescendants()) do
            if d:IsA("TextLabel") then
                TS:Create(d, out, { TextTransparency = 1 }):Play()
            elseif d:IsA("Frame") then
                TS:Create(d, out, { BackgroundTransparency = 1 }):Play()
            end
        end
        TS:Create(splash, out, { BackgroundTransparency = 1 }):Play()
        task.wait(0.65)
        splash:Destroy()

        showMenu(true)
    end)
end

---------------------------------------------------------------------
-- Запуск системы
---------------------------------------------------------------------
showKeySystem(function()
    startLoader()
end)
