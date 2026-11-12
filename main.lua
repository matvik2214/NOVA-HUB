--[[
    NOVA HUB v3.0  |  Xeno-compatible
    Ключ • ESP • Aimbot (своя кнопка) • Хитбоксы • Fly • Noclip • Invisible • Speed • Jump • FOV

    Ключ по умолчанию: NOVA-2026   (меняется в CONFIG.KEYS ниже)
    Меню: RightShift (кнопку можно поменять в разделе «Прочее»)
    Аимбот: ПКМ по умолчанию (кнопку можно выбрать в разделе «Бой»)
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

---------------------------------------------------------------------
-- НАСТРОЙКИ (меняй тут)
---------------------------------------------------------------------
local CONFIG = {
    VERSION   = "v3.0",
    KEYS      = { "NOVA-2026", "NOVA-VIP" },          -- допустимые ключи
    KEY_LINK  = "https://discord.gg/jJ6tx9hgGH",      -- где получить ключ
    SAVE_FILE = "nova_hub_key.txt",                   -- запоминание ключа
}

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
    esp = false, aim = false, team = false, hitbox = false,
    noclip = false, fly = false, inv = false, ijump = false,
    speedOn = false, jumpOn = false, fovOn = false,

    flySpeed = 60, fov = 150, smooth = 25,
    walkSpeed = 50, jumpPower = 100, camFov = 90,
    hbSize = 10, hbTrans = 70,

    hbPart = "HumanoidRootPart",
    aimPart = "Head",
    aimKey = Enum.UserInputType.MouseButton2,   -- по умолчанию правая кнопка мыши
    menuKey = Enum.KeyCode.RightShift,
}

local connections = {}
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

local ready = false      -- меню готово (после ключа и загрузки)
local setters = {}       -- функции для программного переключения тумблеров
local hintLabels = {}    -- подписи с названиями клавиш

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
local GREEN   = Color3.fromRGB(80, 220, 140)
local RED     = Color3.fromRGB(255, 90, 110)

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

local function keyName(k)
    if typeof(k) ~= "EnumItem" then return "?" end
    if k == Enum.UserInputType.MouseButton1 then return "ЛКМ" end
    if k == Enum.UserInputType.MouseButton2 then return "ПКМ" end
    if k == Enum.UserInputType.MouseButton3 then return "Колёсико" end
    return k.Name
end

local function updateHints()
    local m, a = keyName(state.menuKey), keyName(state.aimKey)
    if hintLabels.pill then hintLabels.pill.Text = m .. "  —  открыть / закрыть" end
    if hintLabels.footer then
        hintLabels.footer.Text = m .. " — меню   •   " .. a .. " (держать) — аимбот   •   WASD + Space / Ctrl — полёт"
    end
    if hintLabels.mini then hintLabels.mini.Text = m .. " — открыть меню" end
    if hintLabels.help then
        hintLabels.help.Text = "  " .. m .. " — открыть / закрыть меню\n  " .. a .. " (держать) — аимбот\n  WASD — полёт, Space — вверх, LeftCtrl — вниз\n  Ползунки: тяни мышкой или жми  –  +\n  Шапку меню можно перетаскивать"
    end
end

local gui = make("ScreenGui", {
    Name = "NovaHub", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
}, nil)
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
gui.Parent = getGuiParent()

---------------------------------------------------------------------
-- Утилиты интерфейса: уведомления, затухание, фон
---------------------------------------------------------------------
local function fadeOut(root, t)
    local info = TweenInfo.new(t or 0.5, Enum.EasingStyle.Quad)
    local function one(d)
        if d:IsA("TextBox") then
            d.PlaceholderText = ""
            TS:Create(d, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
        elseif d:IsA("TextLabel") or d:IsA("TextButton") then
            TS:Create(d, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
        elseif d:IsA("Frame") then
            TS:Create(d, info, { BackgroundTransparency = 1 }):Play()
        elseif d:IsA("UIStroke") then
            TS:Create(d, info, { Transparency = 1 }):Play()
        end
    end
    one(root)
    for _, d in ipairs(root:GetDescendants()) do one(d) end
end

local toastHolder = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14),
    Size = UDim2.fromOffset(340, 10), BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 200,
}, gui)
make("UIListLayout", {
    Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, toastHolder)

local function notify(text)
    local f = make("Frame", {
        Size = UDim2.fromOffset(320, 40), BackgroundColor3 = PANEL,
        BorderSizePixel = 0, ZIndex = 200,
    }, toastHolder)
    corner(f, 12)
    local st = make("UIStroke", { Thickness = 1.5, Color = Color3.new(1, 1, 1) }, f)
    gradient(st, 0)
    local sc = make("UIScale", { Scale = 0 }, f)
    make("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 201,
        Font = Enum.Font.GothamSemibold, TextSize = 14, TextColor3 = TEXT, Text = text,
    }, f)
    TS:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
    task.delay(2.4, function()
        if f.Parent then
            fadeOut(f, 0.4)
            task.wait(0.45)
            f:Destroy()
        end
    end)
end

local function orb(parent, x, y, size, color)
    local o = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y),
        Size = UDim2.fromOffset(size, size), BackgroundColor3 = color,
        BackgroundTransparency = 0.88, BorderSizePixel = 0,
    }, parent)
    corner(o, 999)
    TS:Create(o, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Size = UDim2.fromOffset(size * 1.25, size * 1.25), BackgroundTransparency = 0.93,
    }):Play()
end

local function backdrop(parent)
    make("UIGradient", {
        Color = ColorSequence.new(Color3.fromRGB(10, 8, 24), Color3.fromRGB(4, 14, 28)),
        Rotation = 45,
    }, parent)
    orb(parent, 0.2, 0.25, 320, ACCENT)
    orb(parent, 0.8, 0.75, 380, ACCENT2)
end

---------------------------------------------------------------------
-- ESP
---------------------------------------------------------------------
local espObjs = {}

local function removeESP(p)
    local o = espObjs[p]
    if o then
        pcall(function() o.hl:Destroy() end)
        pcall(function() o.bb:Destroy() end)
        espObjs[p] = nil
    end
end

local function applyESP(p)
    removeESP(p)
    if not state.esp or p == LP then return end
    local c = p.Character
    local head = c and c:FindFirstChild("Head")
    if not head then return end

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

local function refreshESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if state.esp then applyESP(p) else removeESP(p) end
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
-- ХИТБОКСЫ (расширение выбранной части тела у других игроков)
-- Часть остаётся прикреплённой к персонажу, поэтому «ходит» за игроком.
-- Оригинальные свойства запоминаются и возвращаются при выключении.
---------------------------------------------------------------------
local hbOriginal = {}

local function restorePart(part)
    local o = hbOriginal[part]
    hbOriginal[part] = nil
    if o and part and part.Parent then
        pcall(function()
            part.Size = o.Size
            part.Transparency = o.Transparency
            part.CanCollide = o.CanCollide
            part.Massless = o.Massless
            part.Material = o.Material
            part.Color = o.Color
        end)
    end
end

local function restoreAllHitboxes()
    local list = {}
    for part in pairs(hbOriginal) do table.insert(list, part) end
    for _, part in ipairs(list) do restorePart(part) end
end

local function updateHitboxes()
    if not state.hitbox then
        if next(hbOriginal) then restoreAllHitboxes() end
        return
    end

    local s = state.hbSize
    local size = Vector3.new(s, s, s)
    local touched = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local c = p.Character
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            local part = c and c:FindFirstChild(state.hbPart)
            local sameTeam = state.team and p.Team ~= nil and p.Team == LP.Team
            if part and part:IsA("BasePart") and hum and hum.Health > 0 and not sameTeam then
                if not hbOriginal[part] then
                    hbOriginal[part] = {
                        Size = part.Size, Transparency = part.Transparency,
                        CanCollide = part.CanCollide, Massless = part.Massless,
                        Material = part.Material, Color = part.Color,
                    }
                end
                touched[part] = true
                part.Size = size
                part.Transparency = state.hbTrans / 100
                part.CanCollide = false
                part.Massless = true
                part.Material = Enum.Material.Neon
                part.Color = ACCENT
            end
        end
    end

    -- вернуть всё, что больше не подходит (умер, вышел, сменил команду, респавн)
    local stale = {}
    for part in pairs(hbOriginal) do
        if not touched[part] then table.insert(stale, part) end
    end
    for _, part in ipairs(stale) do restorePart(part) end
end

---------------------------------------------------------------------
-- Fly / Noclip / Jump / Invisible
---------------------------------------------------------------------
local flyBV, flyBG

local function stopFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

-- Невидимость: персонаж телепортируется в далёкую точку, там сажается на
-- невидимое сиденье и возвращается обратно. Свой вид НЕ меняется.
local INVIS_SPOT = CFrame.new(-25.95, 84, 3537.55)
local invSeat, invWeld
local invBusy = false

local function cleanupInvis()
    if invWeld then invWeld:Destroy() invWeld = nil end
    if invSeat then invSeat:Destroy() invSeat = nil end
end

local function setInvisible(on)
    if invBusy then
        setters.inv(not on, true)
        return
    end
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))

    if on then
        if not (root and torso) then
            setters.inv(false, true)
            notify("Нет персонажа — подожди респавна")
            return
        end
        invBusy = true
        local ok = pcall(function()
            local saved = root.CFrame
            root.CFrame = INVIS_SPOT
            task.wait(0.15)
            invSeat = make("Seat", {
                Name = "NovaSeat", Anchored = false, CanCollide = false,
                Transparency = 1, Position = INVIS_SPOT.Position,
            }, workspace)
            invWeld = make("Weld", { Part0 = invSeat, Part1 = torso }, invSeat)
            task.wait()
            invSeat.CFrame = saved
        end)
        invBusy = false
        if ok then
            notify("Невидимость включена")
        else
            cleanupInvis()
            setters.inv(false, true)
            notify("Невидимость не сработала")
        end
    else
        cleanupInvis()
        notify("Невидимость выключена")
    end
end

connect(LP.CharacterAdded, function()
    -- после респавна старые объекты исчезли, сбрасываем состояние
    if state.inv then
        cleanupInvis()
        setters.inv(false, true)
    end
    flyBV, flyBG = nil, nil
end)

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

---------------------------------------------------------------------
-- Аимбот (кнопка выбирается в меню)
---------------------------------------------------------------------
local fovCircle = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false,
}, gui)
corner(fovCircle, 999)
make("UIStroke", { Color = ACCENT2, Thickness = 1.5, Transparency = 0.2 }, fovCircle)

local function isAimHeld()
    local k = state.aimKey
    if typeof(k) ~= "EnumItem" then return false end
    if k.EnumType == Enum.UserInputType then
        return UIS:IsMouseButtonPressed(k)
    end
    return UIS:IsKeyDown(k)
end

local function getTarget()
    local best, bestDist = nil, state.fov
    local mouse = UIS:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local part = p.Character:FindFirstChild(state.aimPart) or p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local sameTeam = state.team and p.Team ~= nil and p.Team == LP.Team
            if part and hum and hum.Health > 0 and not sameTeam then
                local pos, vis = Camera:WorldToViewportPoint(part.Position)
                if vis then
                    local d = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    if d < bestDist then best, bestDist = part, d end
                end
            end
        end
    end
    return best
end

---------------------------------------------------------------------
-- Главные циклы
---------------------------------------------------------------------
connect(RS.Heartbeat, function()
    pcall(updateHitboxes)
end)

connect(RS.RenderStepped, function()
    Camera = workspace.CurrentCamera
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    -- ESP: дистанция
    if state.esp and root then
        for p, o in pairs(espObjs) do
            local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if r and o.lbl then
                o.lbl.Text = string.format("%s [%dm]", p.Name, (r.Position - root.Position).Magnitude)
            end
        end
    end

    -- Скорость / прыжок / FOV камеры
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
        if isAimHeld() then
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

---------------------------------------------------------------------
-- МЕНЮ
---------------------------------------------------------------------
local MENU_W, MENU_H = 680, 450

local menu = make("Frame", {
    Name = "Menu", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(MENU_W, MENU_H), BackgroundColor3 = BG,
    BorderSizePixel = 0, Visible = false, ClipsDescendants = true,
}, gui)
corner(menu, 16)
local menuStroke = make("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1) }, menu)
gradient(menuStroke, 45)
local menuScale = make("UIScale", { Scale = 0 }, menu)

-- Шапка
local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = PANEL, BorderSizePixel = 0,
}, menu)
corner(header, 16)
make("Frame", {
    Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -16),
    BackgroundColor3 = PANEL, BorderSizePixel = 0,
}, header)

local title = make("TextLabel", {
    Size = UDim2.fromOffset(150, 30), Position = UDim2.fromOffset(20, 6),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 24,
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1),
    Text = "NOVA HUB",
}, header)
gradient(title, 0)

local verBadge = make("Frame", {
    Position = UDim2.fromOffset(176, 12), Size = UDim2.fromOffset(52, 20),
    BackgroundColor3 = ACCENT, BorderSizePixel = 0,
}, header)
corner(verBadge, 10)
gradient(verBadge, 0)
make("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.new(1, 1, 1),
    Text = CONFIG.VERSION,
}, verBadge)

make("TextLabel", {
    Size = UDim2.fromOffset(220, 14), Position = UDim2.fromOffset(20, 36),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = DIM,
    Text = "Xeno Edition  •  Update",
}, header)

local keyPill = make("Frame", {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -62, 0.5, 0),
    Size = UDim2.fromOffset(250, 30), BackgroundColor3 = ROW, BorderSizePixel = 0,
}, header)
corner(keyPill, 15)
hintLabels.pill = make("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold, TextSize = 13, TextColor3 = TEXT, Text = "",
}, keyPill)

local closeBtn = make("TextButton", {
    Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -48, 0.5, -17),
    BackgroundColor3 = ROW, Font = Enum.Font.GothamBold, TextSize = 18,
    TextColor3 = TEXT, Text = "–",
}, header)
corner(closeBtn, 9)

-- Перетаскивание
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

-- Нижняя панель
local footer = make("Frame", {
    Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 1, -30),
    BackgroundColor3 = PANEL, BorderSizePixel = 0,
}, menu)
hintLabels.footer = make("TextLabel", {
    Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12,
    TextColor3 = DIM, Text = "",
}, footer)

-- Боковая панель и контент
local sidebar = make("Frame", {
    Size = UDim2.fromOffset(150, MENU_H - 108), Position = UDim2.fromOffset(10, 68),
    BackgroundTransparency = 1,
}, menu)
make("UIListLayout", { Padding = UDim.new(0, 8) }, sidebar)

local content = make("Frame", {
    Size = UDim2.fromOffset(MENU_W - 180, MENU_H - 108), Position = UDim2.fromOffset(170, 68),
    BackgroundTransparency = 1,
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
        Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = ACCENT, BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = DIM,
        Text = name, AutoButtonColor = false,
    }, sidebar)
    corner(btn, 10)
    tabButtons[name] = btn

    local page = make("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = ACCENT,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
    }, content)
    make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, page)
    pages[name] = page

    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    return page
end

---------------------------------------------------------------------
-- Элементы интерфейса
---------------------------------------------------------------------
local function section(page, text)
    make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = ACCENT2,
        Text = "  " .. string.upper(text), LayoutOrder = nextOrder(page),
    }, page)
end

local function rowBase(page, name, desc, height)
    local row = make("Frame", {
        Size = UDim2.new(1, 0, 0, height or 48), BackgroundColor3 = ROW,
        LayoutOrder = nextOrder(page),
    }, page)
    corner(row, 10)
    make("TextLabel", {
        Size = UDim2.new(1, -160, 0, 22), Position = UDim2.fromOffset(14, 6),
        BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = TEXT, Text = name,
    }, row)
    if desc then
        make("TextLabel", {
            Size = UDim2.new(1, -160, 0, 14), Position = UDim2.fromOffset(14, 28),
            BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = DIM, Text = desc,
        }, row)
    end
    return row
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

    local function apply(on, silent)
        state[key] = on
        TS:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            Position = on and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
        }):Play()
        TS:Create(sw, TweenInfo.new(0.18), { BackgroundColor3 = on and ACCENT or OFF }):Play()
        if onChange and not silent then task.spawn(onChange, on) end
    end
    setters[key] = apply
    row.MouseButton1Click:Connect(function() apply(not state[key]) end)
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

local function sideButton(row, text, width)
    local b = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(width or 130, 30), BackgroundColor3 = PANEL,
        Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = ACCENT2, Text = text,
        AutoButtonColor = true,
    }, row)
    corner(b, 8)
    make("UIStroke", { Color = OFF, Thickness = 1 }, b)
    return b
end

-- Выбор из списка (нажимаешь — переключается на следующий вариант)
local function cycle(page, name, desc, key, options, onChange)
    local row = rowBase(page, name, desc)
    local btn = sideButton(row, "?", 130)
    local function labelFor(v)
        for _, o in ipairs(options) do if o[1] == v then return o[2] end end
        return "?"
    end
    btn.Text = labelFor(state[key])
    btn.MouseButton1Click:Connect(function()
        local idx = 1
        for n, o in ipairs(options) do if o[1] == state[key] then idx = n end end
        idx = idx % #options + 1
        state[key] = options[idx][1]
        btn.Text = options[idx][2]
        if onChange then onChange(state[key]) end
    end)
end

-- Выбор кнопки: нажми на кнопку в меню, потом нажми нужную клавишу
local listening = nil
local function bind(page, name, desc, key, allowMouse)
    local row = rowBase(page, name, desc)
    local btn = sideButton(row, keyName(state[key]), 130)
    btn.MouseButton1Click:Connect(function()
        if listening then listening.cancel() end
        btn.Text = "нажми кнопку..."
        listening = {
            t = os.clock(),
            allowMouse = allowMouse,
            set = function(k)
                state[key] = k
                btn.Text = keyName(k)
                updateHints()
                notify(name .. ": " .. keyName(k))
            end,
            cancel = function() btn.Text = keyName(state[key]) end,
        }
    end)
end

---------------------------------------------------------------------
-- Вкладки
---------------------------------------------------------------------
local tabVisual = newTab("Визуал")
local tabCombat = newTab("Бой")
local tabMove   = newTab("Движение")
local tabMisc   = newTab("Прочее")

-- Визуал
section(tabVisual, "Игроки")
toggle(tabVisual, "ESP / WH", "Подсветка и ники игроков сквозь стены", "esp", refreshESP)
section(tabVisual, "Камера")
toggle(tabVisual, "Свой FOV камеры", "Включить изменение угла обзора", "fovOn", function(on)
    if not on then workspace.CurrentCamera.FieldOfView = 70 end
end)
slider(tabVisual, "FOV камеры", "camFov", 30, 120, "°")

-- Бой
section(tabCombat, "Аимбот")
toggle(tabCombat, "Aimbot", "Наводится, пока держишь выбранную кнопку", "aim")
bind(tabCombat, "Кнопка аима", "По умолчанию — правая кнопка мыши", "aimKey", true)
cycle(tabCombat, "Цель аима", "Куда наводиться", "aimPart", {
    { "Head", "Голова" }, { "HumanoidRootPart", "Торс" },
})
toggle(tabCombat, "Team Check", "Не целиться и не трогать свою команду", "team")
slider(tabCombat, "Радиус FOV аима", "fov", 50, 500, "")
slider(tabCombat, "Плавность наведения", "smooth", 5, 100, "%")

section(tabCombat, "Хитбоксы")
toggle(tabCombat, "Hitbox", "Увеличивает часть тела у других игроков", "hitbox", function(on)
    if not on then restoreAllHitboxes() end
end)
cycle(tabCombat, "Часть тела", "Что увеличивать", "hbPart", {
    { "HumanoidRootPart", "Торс" }, { "Head", "Голова" },
}, function() restoreAllHitboxes() end)
slider(tabCombat, "Размер хитбокса", "hbSize", 2, 50, "")
slider(tabCombat, "Прозрачность", "hbTrans", 0, 100, "%")

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

-- Прочее
section(tabMisc, "Скрытность")
toggle(tabMisc, "Invisible", "Тебя телепортирует так, что другие не видят; свой вид не меняется", "inv", setInvisible)

section(tabMisc, "Кнопки")
bind(tabMisc, "Кнопка меню", "Открыть / закрыть меню", "menuKey", false)

section(tabMisc, "Управление")
local help = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 110), BackgroundColor3 = ROW,
    Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = TEXT,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true, LayoutOrder = nextOrder(tabMisc), Text = "",
}, tabMisc)
corner(help, 10)
make("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 6) }, help)
hintLabels.help = help

section(tabMisc, "Что нового в " .. CONFIG.VERSION)
local news = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = ROW,
    Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = TEXT,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true, LayoutOrder = nextOrder(tabMisc),
    Text = "  • Новое окно ввода ключа\n  • Аимбот: выбор любой кнопки (по умолчанию ПКМ)\n  • Хитбоксы: размер, прозрачность, часть тела\n  • Хитбоксы возвращаются в норму при выключении\n  • Невидимость не меняет твой вид\n  • Кнопка меню настраивается\n  • Уведомления и обновлённый дизайн",
}, tabMisc)
corner(news, 10)
make("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 6) }, news)

section(tabMisc, "Скрипт")
local unloadBtn = make("TextButton", {
    Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Color3.fromRGB(170, 50, 70),
    Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1, 1, 1),
    Text = "Выгрузить скрипт", LayoutOrder = nextOrder(tabMisc),
}, tabMisc)
corner(unloadBtn, 10)

selectTab("Визуал")

---------------------------------------------------------------------
-- Открытие / закрытие + плашка-подсказка
---------------------------------------------------------------------
local hintPill = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 40),
    Size = UDim2.fromOffset(300, 34), BackgroundColor3 = PANEL, BorderSizePixel = 0,
}, gui)
corner(hintPill, 17)
local hintStroke = make("UIStroke", { Thickness = 1.5, Color = Color3.new(1, 1, 1) }, hintPill)
gradient(hintStroke, 0)
hintLabels.mini = make("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold, TextSize = 13, TextColor3 = TEXT, Text = "",
}, hintPill)

updateHints()

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
    -- режим выбора кнопки
    if listening then
        if os.clock() - listening.t < 0.25 then return end
        local newKey
        if i.UserInputType == Enum.UserInputType.Keyboard then
            if i.KeyCode == Enum.KeyCode.Escape then
                listening.cancel()
                listening = nil
                return
            end
            newKey = i.KeyCode
        elseif listening.allowMouse and (
            i.UserInputType == Enum.UserInputType.MouseButton1 or
            i.UserInputType == Enum.UserInputType.MouseButton2 or
            i.UserInputType == Enum.UserInputType.MouseButton3) then
            newKey = i.UserInputType
        end
        if newKey then
            local l = listening
            listening = nil
            l.set(newKey)
        end
        return
    end

    if ready and not gp and i.KeyCode == state.menuKey then
        showMenu(not menuOpen)
    end
end)

---------------------------------------------------------------------
-- Выгрузка
---------------------------------------------------------------------
local function unload()
    ready = false
    state.fly, state.noclip, state.aim, state.esp, state.ijump = false, false, false, false, false
    state.speedOn, state.jumpOn, state.fovOn, state.hitbox = false, false, false, false
    stopFly()
    pcall(restoreAllHitboxes)
    pcall(function()
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = 16 h.JumpPower = 50 end
        workspace.CurrentCamera.FieldOfView = 70
    end)
    pcall(cleanupInvis)
    state.inv = false
    for p in pairs(espObjs) do removeESP(p) end
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    connections = {}
    pcall(function() gui:Destroy() end)
    env.NovaUnload = nil
end
env.NovaUnload = unload
unloadBtn.MouseButton1Click:Connect(unload)

---------------------------------------------------------------------
-- ЗАГРУЗОЧНЫЙ ЭКРАН
---------------------------------------------------------------------
local function startLoading()
    local splash = make("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 8, 16),
        BorderSizePixel = 0, ZIndex = 50,
    }, gui)
    backdrop(splash)

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
        Text = "Roblox Utility  •  Xeno Edition  •  " .. CONFIG.VERSION .. " UPDATE",
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
        Text = keyName(state.menuKey) .. " — открыть / закрыть меню",
        TextTransparency = 1, ZIndex = 51,
    }, splash)

    task.spawn(function()
        local fadeIn = TweenInfo.new(0.6, Enum.EasingStyle.Quad)
        for _, o in ipairs({ logo, sub, status, keyHint }) do
            TS:Create(o, fadeIn, { TextTransparency = 0 }):Play()
        end
        TS:Create(barBg, fadeIn, { BackgroundTransparency = 0 }):Play()
        TS:Create(barFill, fadeIn, { BackgroundTransparency = 0 }):Play()
        task.wait(0.7)

        local steps = {
            { "Ключ подтверждён", 0.12 },
            { "Загрузка модулей...", 0.30 },
            { "Подготовка ESP и аимбота...", 0.50 },
            { "Настройка хитбоксов...", 0.68 },
            { "Настройка движения...", 0.84 },
            { "Сборка меню...", 0.95 },
            { "Готово!", 1 },
        }
        for _, s in ipairs(steps) do
            status.Text = s[1]
            TS:Create(barFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(s[2], 1) }):Play()
            task.wait(0.5)
        end
        task.wait(0.25)

        fadeOut(splash, 0.6)
        task.wait(0.65)
        splash:Destroy()

        ready = true
        showMenu(true)
        notify("Добро пожаловать в NOVA HUB " .. CONFIG.VERSION)
    end)
end

---------------------------------------------------------------------
-- ОКНО ВВОДА КЛЮЧА
---------------------------------------------------------------------
local function validKey(k)
    k = (tostring(k or ""):gsub("%s+", "")):upper()
    if k == "" then return false end
    for _, v in ipairs(CONFIG.KEYS) do
        if k == v:upper() then return true end
    end
    return false
end

local function loadSavedKey()
    local ok, res = pcall(function()
        if isfile and readfile and isfile(CONFIG.SAVE_FILE) then
            return readfile(CONFIG.SAVE_FILE)
        end
    end)
    return ok and res or nil
end

local function saveKey(k)
    pcall(function()
        if writefile then writefile(CONFIG.SAVE_FILE, k) end
    end)
end

local function showKeyScreen(onSuccess)
    local scr = make("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 8, 16),
        BorderSizePixel = 0, ZIndex = 50,
    }, gui)
    backdrop(scr)

    local card = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(440, 380), BackgroundColor3 = PANEL, BorderSizePixel = 0,
    }, scr)
    corner(card, 20)
    local cardStroke = make("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1) }, card)
    gradient(cardStroke, 45)
    local cardScale = make("UIScale", { Scale = 0 }, card)
    TS:Create(cardScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    local logo = make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 26),
        Size = UDim2.fromOffset(380, 48), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack, TextSize = 40, TextColor3 = Color3.new(1, 1, 1),
        Text = "NOVA HUB",
    }, card)
    gradient(logo, 0)

    local badge = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 78),
        Size = UDim2.fromOffset(96, 22), BackgroundColor3 = ACCENT, BorderSizePixel = 0,
    }, card)
    corner(badge, 11)
    gradient(badge, 0)
    make("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.new(1, 1, 1),
        Text = CONFIG.VERSION .. " UPDATE",
    }, badge)

    make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 120),
        Size = UDim2.fromOffset(380, 22), BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 15, TextColor3 = DIM,
        Text = "Введите ключ доступа",
    }, card)

    local box = make("TextBox", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 150),
        Size = UDim2.fromOffset(360, 48), BackgroundColor3 = ROW, BorderSizePixel = 0,
        Font = Enum.Font.GothamSemibold, TextSize = 17, TextColor3 = TEXT,
        PlaceholderText = "NOVA-XXXX", PlaceholderColor3 = Color3.fromRGB(110, 110, 140),
        Text = "", ClearTextOnFocus = false,
    }, card)
    corner(box, 12)
    local boxStroke = make("UIStroke", { Thickness = 1.5, Color = OFF }, box)

    local verify = make("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 212),
        Size = UDim2.fromOffset(360, 48), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.new(1, 1, 1),
        Text = "Проверить ключ", AutoButtonColor = true,
    }, card)
    corner(verify, 12)
    gradient(verify, 0)

    local getKey = make("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 270),
        Size = UDim2.fromOffset(360, 40), BackgroundColor3 = ROW, BorderSizePixel = 0,
        Font = Enum.Font.GothamSemibold, TextSize = 14, TextColor3 = TEXT,
        Text = "Получить ключ (Discord)", AutoButtonColor = true,
    }, card)
    corner(getKey, 12)

    local status = make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 328),
        Size = UDim2.fromOffset(380, 22), BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = DIM, Text = "",
    }, card)

    connect(box.Focused, function()
        TS:Create(boxStroke, TweenInfo.new(0.2), { Color = ACCENT }):Play()
    end)

    local function shake()
        local base = card.Position
        for _, dx in ipairs({ -12, 12, -8, 8, -4, 4, 0 }) do
            TS:Create(card, TweenInfo.new(0.04), { Position = base + UDim2.fromOffset(dx, 0) }):Play()
            task.wait(0.04)
        end
    end

    local busy = false
    local function submit()
        if busy then return end
        local k = box.Text
        if validKey(k) then
            busy = true
            status.TextColor3 = GREEN
            status.Text = "Ключ принят ✓"
            TS:Create(boxStroke, TweenInfo.new(0.2), { Color = GREEN }):Play()
            saveKey(k)
            task.wait(0.7)
            fadeOut(scr, 0.5)
            task.wait(0.55)
            scr:Destroy()
            onSuccess()
        else
            busy = true
            status.TextColor3 = RED
            status.Text = (tostring(k):match("^%s*$")) and "Введите ключ" or "Неверный ключ"
            TS:Create(boxStroke, TweenInfo.new(0.2), { Color = RED }):Play()
            shake()
            task.wait(0.4)
            busy = false
        end
    end

    verify.MouseButton1Click:Connect(submit)
    connect(box.FocusLost, function(enter)
        if enter then submit() end
    end)

    getKey.MouseButton1Click:Connect(function()
        local ok = pcall(function() setclipboard(CONFIG.KEY_LINK) end)
        status.TextColor3 = ACCENT2
        status.Text = ok and "Ссылка на Discord скопирована" or CONFIG.KEY_LINK
    end)
end

---------------------------------------------------------------------
-- СТАРТ
---------------------------------------------------------------------
if validKey(loadSavedKey()) then
    startLoading()
else
    showKeyScreen(startLoading)
end
