--[[
    NOVA HUB v4.1  |  Xeno-compatible
    Ключ • ESP • Aimbot • Хитбоксы • Fly • Noclip • Невидимость • Speed • Jump • FOV

    Ключ: NOVA-4X7K-9QM2   (меняется в CONFIG.KEYS ниже)
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
    VERSION   = "v4.1",
    KEYS      = { "NOVA-4X7K-9QM2" },                 -- допустимые ключи
    KEY_LINK  = "https://discord.gg/jJ6tx9hgGH",      -- где получить ключ
    SAVE_FILE = "nova_hub_key_v4.txt",                -- запоминание ключа
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
    wallCheck = false, sticky = true, showFov = true,

    flySpeed = 60, fov = 150, aimSpeed = 40, predict = 40,
    walkSpeed = 50, jumpPower = 100, camFov = 90,
    hbSize = 10, hbTrans = 75, ghostSpeed = 60,

    hbPart = "HumanoidRootPart",
    hbMode = "follow",
    aimPart = "Head",
    aimMode = "cursor",
    invMode = "ghost",
    aimKey = Enum.UserInputType.MouseButton2,
    menuKey = Enum.KeyCode.RightShift,
}

local connections = {}
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

local ready = false
local setters = {}
local hintLabels = {}

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
local function gradient(parent, rot, c1, c2)
    return make("UIGradient", {
        Color = ColorSequence.new(c1 or ACCENT, c2 or ACCENT2), Rotation = rot or 0,
    }, parent)
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
        hintLabels.help.Text = "  " .. m .. " — открыть / закрыть меню\n  " .. a .. " (держать) — аимбот\n  WASD — полёт, Space — вверх, LeftCtrl — вниз\n  Призрак: WASD, Space / Ctrl, Shift — быстрее, ПКМ — осмотр\n  Ползунки: тяни мышкой или жми  –  +"
    end
end

local gui = make("ScreenGui", {
    Name = "NovaHub", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
}, nil)
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
gui.Parent = getGuiParent()

---------------------------------------------------------------------
-- Утилиты интерфейса
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

-- soft = true: очень тусклый фон (для окна ключа)
local function orb(parent, x, y, size, color, soft)
    local from = soft and 0.95 or 0.88
    local to = soft and 0.975 or 0.93
    local o = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y),
        Size = UDim2.fromOffset(size, size), BackgroundColor3 = color,
        BackgroundTransparency = from, BorderSizePixel = 0,
    }, parent)
    corner(o, 999)
    TS:Create(o, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Size = UDim2.fromOffset(size * 1.2, size * 1.2), BackgroundTransparency = to,
    }):Play()
end

local function backdrop(parent, soft)
    if soft then
        make("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(11, 10, 17), Color3.fromRGB(7, 10, 16)),
            Rotation = 45,
        }, parent)
        orb(parent, 0.2, 0.25, 300, Color3.fromRGB(80, 62, 140), true)
        orb(parent, 0.8, 0.75, 340, Color3.fromRGB(45, 95, 120), true)
    else
        make("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(10, 8, 24), Color3.fromRGB(4, 14, 28)),
            Rotation = 45,
        }, parent)
        orb(parent, 0.2, 0.25, 320, ACCENT)
        orb(parent, 0.8, 0.75, 380, ACCENT2)
    end
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
-- ХИТБОКСЫ
-- Режим «Следует за игроком»: настоящая часть тела не трогается, к персонажу
-- добавляется большая коробка, которая каждый кадр повторяет её положение —
-- поэтому она всегда двигается вместе с человеком.
-- Режим «Реальная часть»: увеличивается сама часть (без Massless, чтобы
-- не ломалась физика), всё возвращается при выключении.
---------------------------------------------------------------------
local hbOriginal = {}
local hbProxies = {}

local function restorePart(part)
    local o = hbOriginal[part]
    hbOriginal[part] = nil
    if o and part and part.Parent then
        pcall(function()
            part.Size = o.Size
            part.Transparency = o.Transparency
            part.CanCollide = o.CanCollide
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

local function removeProxy(p)
    local o = hbProxies[p]
    if o then
        hbProxies[p] = nil
        pcall(function() o.proxy:Destroy() end)
    end
end

local function clearProxies()
    local list = {}
    for p in pairs(hbProxies) do table.insert(list, p) end
    for _, p in ipairs(list) do removeProxy(p) end
end

local function clearHitboxes()
    clearProxies()
    restoreAllHitboxes()
end

local function syncProxies()
    for _, o in pairs(hbProxies) do
        if o.src and o.src.Parent and o.proxy.Parent then
            o.proxy.CFrame = o.src.CFrame
        end
    end
end

local function updateHitboxes()
    if not state.hitbox then
        if next(hbProxies) or next(hbOriginal) then clearHitboxes() end
        return
    end

    local s = state.hbSize
    local size = Vector3.new(s, s, s)
    local follow = state.hbMode == "follow"

    if follow then
        if next(hbOriginal) then restoreAllHitboxes() end
    else
        if next(hbProxies) then clearProxies() end
    end

    local touched = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local c = p.Character
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            local part = c and c:FindFirstChild(state.hbPart)
            local sameTeam = state.team and p.Team ~= nil and p.Team == LP.Team
            local valid = part and part:IsA("BasePart") and hum and hum.Health > 0 and not sameTeam

            if follow then
                if valid then
                    local o = hbProxies[p]
                    if not o or o.src ~= part or not o.proxy.Parent or o.proxy.Parent ~= c then
                        removeProxy(p)
                        local proxy = make("Part", {
                            Name = "NovaHitbox", Anchored = true, CanCollide = false,
                            CanTouch = false, CanQuery = true, CastShadow = false,
                            Material = Enum.Material.Neon, Color = ACCENT,
                            TopSurface = Enum.SurfaceType.Smooth,
                            BottomSurface = Enum.SurfaceType.Smooth,
                            Size = size, CFrame = part.CFrame,
                        }, c)
                        o = { proxy = proxy, src = part }
                        hbProxies[p] = o
                    end
                    o.proxy.Size = size
                    o.proxy.Transparency = state.hbTrans / 100
                    o.proxy.CFrame = part.CFrame
                else
                    removeProxy(p)
                end
            elseif valid then
                if not hbOriginal[part] then
                    hbOriginal[part] = {
                        Size = part.Size, Transparency = part.Transparency,
                        CanCollide = part.CanCollide, Material = part.Material,
                        Color = part.Color,
                    }
                end
                touched[part] = true
                part.Size = size
                part.Transparency = state.hbTrans / 100
                part.CanCollide = false
                part.Material = Enum.Material.Neon
                part.Color = ACCENT
            end
        end
    end

    if follow then
        local gone = {}
        for p in pairs(hbProxies) do
            if not p.Parent then table.insert(gone, p) end
        end
        for _, p in ipairs(gone) do removeProxy(p) end
    else
        local stale = {}
        for part in pairs(hbOriginal) do
            if not touched[part] then table.insert(stale, part) end
        end
        for _, part in ipairs(stale) do restorePart(part) end
    end
end

---------------------------------------------------------------------
-- Fly / Noclip / Jump
---------------------------------------------------------------------
local flyBV, flyBG

local function stopFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
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

---------------------------------------------------------------------
-- НЕВИДИМОСТЬ
-- «Призрак»: настоящее тело улетает высоко в небо и стоит там на
-- невидимой площадке — другие игроки тебя на карте не видят вообще.
-- Ты летаешь свободной камерой (WASD, Space / Ctrl, Shift, ПКМ — осмотр).
-- При выключении появляешься на земле там, где была камера.
-- «Сиденье»: старый способ (может не работать в части игр).
---------------------------------------------------------------------
local ghost = nil
local HIDE_HEIGHT = 20000
local GHOST_BIND = "NovaGhostCam"
local updateGhost

-- отключаем стандартное управление персонажем, пока работает призрак
local function setControls(enabled)
    pcall(function()
        local scripts = LP:FindFirstChild("PlayerScripts")
        local pm = scripts and scripts:FindFirstChild("PlayerModule")
        if not pm then return end
        local controls = require(pm):GetControls()
        if enabled then controls:Enable() else controls:Disable() end
    end)
end

local function unbindGhost()
    pcall(function() RS:UnbindFromRenderStep(GHOST_BIND) end)
end

local ghostHint = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -64),
    Size = UDim2.fromOffset(470, 34), BackgroundColor3 = PANEL,
    BorderSizePixel = 0, Visible = false,
}, gui)
corner(ghostHint, 17)
make("UIStroke", { Thickness = 1, Color = OFF }, ghostHint)
make("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = TEXT,
    Text = "Призрак:  WASD  •  Space / Ctrl  •  Shift — быстрее  •  ПКМ (держать) — осмотр",
}, ghostHint)

local function ghostOn()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (root and hum) then return false end

    local cam = workspace.CurrentCamera
    local look = cam.CFrame.LookVector
    local g = {
        savedCF = root.CFrame,
        ws = hum.WalkSpeed, ujp = hum.UseJumpPower, jp = hum.JumpPower, jh = hum.JumpHeight,
        pos = cam.CFrame.Position,
        yaw = math.atan2(-look.X, -look.Z),
        pitch = math.asin(math.clamp(look.Y, -1, 1)),
    }

    local hideCF = CFrame.new(root.Position + Vector3.new(0, HIDE_HEIGHT, 0))
    g.platform = make("Part", {
        Name = "NovaGhostPlatform", Anchored = true, CanCollide = true,
        Transparency = 1, Size = Vector3.new(60, 2, 60),
        Position = hideCF.Position - Vector3.new(0, 4, 0),
    }, workspace)

    root.CFrame = hideCF
    root.AssemblyLinearVelocity = Vector3.zero
    hum.WalkSpeed = 0
    hum.UseJumpPower = true
    hum.JumpPower = 0

    ghost = g

    -- камера сразу остаётся на прежнем месте, а не улетает за телом
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = CFrame.new(g.pos) * CFrame.fromOrientation(g.pitch, g.yaw, 0)
    setControls(false)
    ghostHint.Visible = true
    -- приоритет выше стандартной камеры Roblox, чтобы она не перебивала нашу
    RS:BindToRenderStep(GHOST_BIND, Enum.RenderPriority.Camera.Value + 1, function(dt)
        updateGhost(dt)
    end)
    return true
end

local function ghostOff()
    local g = ghost
    if not g then return end
    ghost = nil
    unbindGhost()
    setControls(true)
    ghostHint.Visible = false

    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    local target = g.savedCF
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = { g.platform }
    if char then table.insert(ignore, char) end
    params.FilterDescendantsInstances = ignore
    local hit = workspace:Raycast(g.pos, Vector3.new(0, -2000, 0), params)
    if hit then target = CFrame.new(hit.Position + Vector3.new(0, 4, 0)) end

    if root then
        root.CFrame = target
        root.AssemblyLinearVelocity = Vector3.zero
    end
    if hum then
        hum.WalkSpeed = g.ws
        hum.UseJumpPower = g.ujp
        hum.JumpPower = g.jp
        pcall(function() hum.JumpHeight = g.jh end)
    end
    pcall(function() g.platform:Destroy() end)

    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Custom
    if hum then cam.CameraSubject = hum end
    UIS.MouseBehavior = Enum.MouseBehavior.Default
end

function updateGhost(dt)
    local g = ghost
    if not g then return end
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable

    if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        local d = UIS:GetMouseDelta()
        g.yaw = g.yaw - d.X * 0.004
        g.pitch = math.clamp(g.pitch - d.Y * 0.004, -1.5, 1.5)
    elseif UIS.MouseBehavior == Enum.MouseBehavior.LockCurrentPosition then
        UIS.MouseBehavior = Enum.MouseBehavior.Default
    end

    local rot = CFrame.fromOrientation(g.pitch, g.yaw, 0)

    if not UIS:GetFocusedTextBox() then
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += rot.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= rot.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += rot.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= rot.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
        if dir.Magnitude > 0 then
            local speed = state.ghostSpeed * (UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1)
            g.pos += dir.Unit * speed * dt
        end
    end

    cam.CFrame = CFrame.new(g.pos) * rot
end

-- старый способ: сиденье
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

    if on then
        if state.invMode == "ghost" then
            local ok, res = pcall(ghostOn)
            if ok and res then
                notify("Ты исчез: летай камерой")
            else
                setters.inv(false, true)
                notify("Нет персонажа — подожди респавна")
            end
        else
            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
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
        end
    else
        pcall(ghostOff)
        cleanupInvis()
        notify("Ты снова виден")
    end
end

connect(LP.CharacterAdded, function()
    -- после респавна всё старое исчезло: просто сбрасываем состояние
    if state.inv then
        local g = ghost
        ghost = nil
        unbindGhost()
        setControls(true)
        ghostHint.Visible = false
        if g then pcall(function() g.platform:Destroy() end) end
        pcall(function()
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end)
        cleanupInvis()
        setters.inv(false, true)
    end
    flyBV, flyBG = nil, nil
end)

---------------------------------------------------------------------
-- АИМБОТ
-- • плавное наведение, не зависящее от FPS
-- • предсказание движения цели
-- • проверка стен (Wall Check)
-- • захват цели, пока держишь кнопку (Sticky)
-- • приоритет: ближе к курсору или ближе к тебе
---------------------------------------------------------------------
local fovCircle = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false,
}, gui)
corner(fovCircle, 999)
make("UIStroke", { Color = ACCENT2, Thickness = 1.5, Transparency = 0.35 }, fovCircle)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
pcall(function() rayParams.RespectCanCollide = true end)

local function isAimHeld()
    local k = state.aimKey
    if typeof(k) ~= "EnumItem" then return false end
    if k.EnumType == Enum.UserInputType then
        return UIS:IsMouseButtonPressed(k)
    end
    return UIS:IsKeyDown(k)
end

local function visibleFrom(origin, part)
    local ignore = {}
    if LP.Character then table.insert(ignore, LP.Character) end
    if part.Parent then table.insert(ignore, part.Parent) end
    rayParams.FilterDescendantsInstances = ignore
    return workspace:Raycast(origin, part.Position - origin, rayParams) == nil
end

-- возвращает часть тела цели и «очки» (меньше = лучше)
local function candidate(p, fovMul)
    if p == LP then return nil end
    local c = p.Character
    if not c then return nil end
    local hum = c:FindFirstChildOfClass("Humanoid")
    local part = c:FindFirstChild(state.aimPart) or c:FindFirstChild("Head")
    if not (hum and part and hum.Health > 0) then return nil end
    if state.team and p.Team ~= nil and p.Team == LP.Team then return nil end

    local pos, vis = Camera:WorldToViewportPoint(part.Position)
    if not vis then return nil end
    local cursorDist = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
    if cursorDist > state.fov * (fovMul or 1) then return nil end
    if state.wallCheck and not visibleFrom(Camera.CFrame.Position, part) then return nil end

    local score = cursorDist
    if state.aimMode == "distance" then
        score = (part.Position - Camera.CFrame.Position).Magnitude
    end
    return part, score
end

local aimLockPlayer = nil

local function getTarget()
    if state.sticky and aimLockPlayer and aimLockPlayer.Parent then
        local part = candidate(aimLockPlayer, 1.8)
        if part then return part end
    end
    aimLockPlayer = nil

    local best, bestScore, bestPlayer
    for _, p in ipairs(Players:GetPlayers()) do
        local part, score = candidate(p, 1)
        if part and (not bestScore or score < bestScore) then
            best, bestScore, bestPlayer = part, score, p
        end
    end
    aimLockPlayer = bestPlayer
    return best
end

---------------------------------------------------------------------
-- Главные циклы
---------------------------------------------------------------------
connect(RS.Heartbeat, function()
    pcall(updateHitboxes)
    syncProxies()
end)

connect(RS.RenderStepped, function(dt)
    Camera = workspace.CurrentCamera
    syncProxies()

    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    -- ESP: дистанция
    if state.esp and root and not ghost then
        for p, o in pairs(espObjs) do
            local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if r and o.lbl then
                o.lbl.Text = string.format("%s [%dm]", p.Name, (r.Position - root.Position).Magnitude)
            end
        end
    end

    -- Скорость / прыжок / FOV камеры
    if hum and not ghost then
        if state.speedOn then hum.WalkSpeed = state.walkSpeed end
        if state.jumpOn then
            hum.UseJumpPower = true
            hum.JumpPower = state.jumpPower
        end
    end
    if state.fovOn then Camera.FieldOfView = state.camFov end

    -- Аимбот
    local aiming = state.aim and not ghost
    fovCircle.Visible = aiming and state.showFov
    if aiming then
        local m = UIS:GetMouseLocation()
        fovCircle.Position = UDim2.fromOffset(m.X, m.Y)
        fovCircle.Size = UDim2.fromOffset(state.fov * 2, state.fov * 2)

        if isAimHeld() then
            local t = getTarget()
            if t then
                local vel = Vector3.zero
                local tr = t.Parent and t.Parent:FindFirstChild("HumanoidRootPart")
                if tr then vel = tr.AssemblyLinearVelocity end
                local aimPos = t.Position + vel * (state.predict / 1000)
                local goal = CFrame.lookAt(Camera.CFrame.Position, aimPos)
                local k = 2 + state.aimSpeed * 0.3
                local alpha = 1 - math.exp(-k * dt)
                Camera.CFrame = Camera.CFrame:Lerp(goal, math.clamp(alpha, 0, 1))
            end
        else
            aimLockPlayer = nil
        end
    end

    -- Полёт
    if state.fly and root and hum and not ghost then
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
hintLabels.footer = make("TextLabel", {
    Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12,
    TextColor3 = DIM, Text = "",
}, footer)

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
    apply(state[key], true)
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

local function cycle(page, name, desc, key, options, onChange)
    local row = rowBase(page, name, desc)
    local btn = sideButton(row, "?", 150)
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

local listening = nil
local function bind(page, name, desc, key, allowMouse)
    local row = rowBase(page, name, desc)
    local btn = sideButton(row, keyName(state[key]), 150)
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
cycle(tabCombat, "Приоритет цели", "Кого брать первым", "aimMode", {
    { "cursor", "Ближе к курсору" }, { "distance", "Ближе ко мне" },
})
toggle(tabCombat, "Wall Check", "Не целиться сквозь стены", "wallCheck")
toggle(tabCombat, "Захват цели", "Держится за цель, пока зажата кнопка", "sticky")
toggle(tabCombat, "Team Check", "Не целиться и не трогать свою команду", "team")
toggle(tabCombat, "Круг FOV", "Показывать круг области аима", "showFov")
slider(tabCombat, "Радиус FOV аима", "fov", 50, 500, "")
slider(tabCombat, "Скорость наведения", "aimSpeed", 5, 100, "%")
slider(tabCombat, "Предсказание", "predict", 0, 300, " мс")

section(tabCombat, "Хитбоксы")
toggle(tabCombat, "Hitbox", "Большая коробка вокруг игроков", "hitbox", function(on)
    if not on then clearHitboxes() end
end)
cycle(tabCombat, "Режим", "Как работает хитбокс", "hbMode", {
    { "follow", "Следует за игроком" }, { "real", "Реальная часть" },
}, function() clearHitboxes() end)
cycle(tabCombat, "Часть тела", "Вокруг чего коробка", "hbPart", {
    { "HumanoidRootPart", "Торс" }, { "Head", "Голова" },
}, function() clearHitboxes() end)
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
section(tabMisc, "Невидимость")
toggle(tabMisc, "Invisible", "Тело прячется, другие тебя не видят", "inv", setInvisible)
cycle(tabMisc, "Режим", "Призрак — камера, Сиденье — старый способ", "invMode", {
    { "ghost", "Призрак (камера)" }, { "seat", "Сиденье" },
}, function()
    if state.inv then setters.inv(false) end
end)
slider(tabMisc, "Скорость призрака", "ghostSpeed", 10, 300, "")

section(tabMisc, "Кнопки")
bind(tabMisc, "Кнопка меню", "Открыть / закрыть меню", "menuKey", false)

section(tabMisc, "Управление")
local help = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 120), BackgroundColor3 = ROW,
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
    Text = "  • Хитбоксы двигаются вместе с игроком\n  • Аим: плавность, предсказание, Wall Check, захват цели\n  • Невидимость: тело прячется, ты летаешь камерой\n  • Новый ключ и спокойное окно ввода ключа\n  • Круг FOV можно скрыть\n  • v4.1: камера призрака исправлена",
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
    pcall(clearHitboxes)
    pcall(ghostOff)
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
    backdrop(splash, false)

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
            { "Настройка невидимости...", 0.84 },
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
-- ОКНО ВВОДА КЛЮЧА (тусклое, без ярких цветов)
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
    -- приглушённая палитра
    local K_BG     = Color3.fromRGB(9, 9, 14)
    local K_CARD   = Color3.fromRGB(17, 17, 26)
    local K_LINE   = Color3.fromRGB(44, 44, 66)
    local K_FIELD  = Color3.fromRGB(24, 24, 36)
    local K_TEXT   = Color3.fromRGB(205, 205, 222)
    local K_DIM    = Color3.fromRGB(115, 115, 142)
    local K_ACCENT = Color3.fromRGB(88, 68, 160)
    local K_OK     = Color3.fromRGB(105, 175, 140)
    local K_BAD    = Color3.fromRGB(200, 100, 112)

    local scr = make("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = K_BG,
        BorderSizePixel = 0, ZIndex = 50,
    }, gui)
    backdrop(scr, true)

    local card = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(420, 370), BackgroundColor3 = K_CARD, BorderSizePixel = 0,
    }, scr)
    corner(card, 18)
    make("UIStroke", { Thickness = 1, Color = K_LINE }, card)
    local cardScale = make("UIScale", { Scale = 0.9 }, card)
    TS:Create(cardScale, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    local logo = make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 28),
        Size = UDim2.fromOffset(360, 42), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 32, TextColor3 = Color3.new(1, 1, 1),
        Text = "NOVA HUB",
    }, card)
    gradient(logo, 0, Color3.fromRGB(165, 150, 225), Color3.fromRGB(135, 175, 205))

    local badge = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 76),
        Size = UDim2.fromOffset(84, 22), BackgroundColor3 = Color3.fromRGB(34, 30, 58),
        BorderSizePixel = 0,
    }, card)
    corner(badge, 11)
    make("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Color3.fromRGB(160, 150, 205),
        Text = CONFIG.VERSION .. " UPDATE",
    }, badge)

    make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 122),
        Size = UDim2.fromOffset(340, 20), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = K_DIM,
        Text = "Введите ключ доступа",
    }, card)

    local box = make("TextBox", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 150),
        Size = UDim2.fromOffset(340, 46), BackgroundColor3 = K_FIELD, BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium, TextSize = 16, TextColor3 = K_TEXT,
        PlaceholderText = "NOVA-XXXX-XXXX", PlaceholderColor3 = Color3.fromRGB(85, 85, 110),
        Text = "", ClearTextOnFocus = false,
    }, card)
    corner(box, 12)
    local boxStroke = make("UIStroke", { Thickness = 1, Color = K_LINE }, box)

    local verify = make("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 212),
        Size = UDim2.fromOffset(340, 46), BackgroundColor3 = K_ACCENT, BorderSizePixel = 0,
        Font = Enum.Font.GothamSemibold, TextSize = 15, TextColor3 = Color3.fromRGB(235, 235, 245),
        Text = "Проверить ключ", AutoButtonColor = true,
    }, card)
    corner(verify, 12)

    local getKey = make("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 270),
        Size = UDim2.fromOffset(340, 40), BackgroundColor3 = Color3.fromRGB(26, 26, 38),
        BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 14,
        TextColor3 = Color3.fromRGB(165, 165, 190),
        Text = "Получить ключ (Discord)", AutoButtonColor = true,
    }, card)
    corner(getKey, 12)

    local status = make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 328),
        Size = UDim2.fromOffset(360, 22), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = K_DIM, Text = "",
    }, card)

    connect(box.Focused, function()
        TS:Create(boxStroke, TweenInfo.new(0.2), { Color = K_ACCENT }):Play()
    end)

    local function shake()
        local base = card.Position
        for _, dx in ipairs({ -10, 10, -6, 6, -3, 3, 0 }) do
            TS:Create(card, TweenInfo.new(0.04), { Position = base + UDim2.fromOffset(dx, 0) }):Play()
            task.wait(0.04)
        end
    end

    local busy = false
    local function submit()
        if busy then return end
        local k = box.Text
        busy = true
        if validKey(k) then
            status.TextColor3 = K_OK
            status.Text = "Ключ принят"
            TS:Create(boxStroke, TweenInfo.new(0.2), { Color = K_OK }):Play()
            saveKey(k)
            task.wait(0.7)
            fadeOut(scr, 0.5)
            task.wait(0.55)
            scr:Destroy()
            onSuccess()
        else
            status.TextColor3 = K_BAD
            status.Text = (tostring(k):match("^%s*$")) and "Введите ключ" or "Неверный ключ"
            TS:Create(boxStroke, TweenInfo.new(0.2), { Color = K_BAD }):Play()
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
        status.TextColor3 = K_DIM
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
