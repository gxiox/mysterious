--// RELWX HUB + TD AUTO (Challenge / Event / Farm / Shop)  -- วางใน autoexec เพื่อให้รันต่อหลังวาป
--// ============================================================
--//  RELWX HUB  |  UI v7  (UI ONLY — ไม่มีฟังก์ชันเกม)
--//  - ปรับขนาดตามหน้าจออัตโนมัติ (+ ปรับเพิ่ม/ลดเองได้ในตั้งค่า)
--//  - ทุกอย่างผูกกับ Config และเซฟอัตโนมัติ
--//  - เพิ่มฟังก์ชันใหม่: ดูหัวข้อ "ADD YOUR FUNCTIONS"
--// ============================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")

-- ฟอนต์ UI  (เปลี่ยนได้: "Montserrat" | "BuilderSans" | "Gotham")
local UI_FONT = "Montserrat"
local function E(name)
    local ok, v = pcall(function()
        return Enum.Font[name]
    end)
    return ok and v or Enum.Font.Gotham
end
local FontFamilies = {
    Montserrat = { R = E("Montserrat"), M = E("MontserratMedium"), B = E("MontserratBold") },
    BuilderSans = { R = E("BuilderSans"), M = E("BuilderSansMedium"), B = E("BuilderSansBold") },
    Gotham = { R = Enum.Font.Gotham, M = Enum.Font.GothamMedium, B = Enum.Font.GothamBold },
}
local FNT = FontFamilies[UI_FONT] or FontFamilies.Gotham

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- เสียงตอนกดเปิด/ปิด (เปลี่ยน ID ได้ตามชอบ เช่น "rbxassetid://1234567")
local SOUND_ON = "rbxasset://sounds/switch.wav"
local SOUND_OFF = "rbxasset://sounds/button.wav"
local SOUND_FALLBACK = "rbxasset://sounds/electronicpingshort.wav" -- ใช้ถ้าเสียงข้างบนโหลดไม่ได้

--==================================================
-- CONFIG  (Auto Save / Auto Load)
--==================================================

local CONFIG_FILE = "RELWX_HUB_Config.json"

local Defaults = {
    -- สี
    UIAccentColor = "#C9CBD3",
    UIBackgroundColor = "#0A0A0C",
    UIButtonColor = "#232328",
    FloatingButtonColor = "#101012",
    FloatingBorderColor = "#E4E4EA",
    FloatingGlowColor = "#8E8E98",
    -- ฟังก์ชัน
    ExampleFunctionEnabled = false,
    ExampleFunction2Enabled = false,
    ExampleSlider = 50,
    -- ระบบ
    SoundEnabled = true,
    StatsVisible = true,
    UIScalePercent = 100,
    -- สถานะ UI
    LastTab = "Home",
    WindowVisible = true,
    Maximized = false,
    CollapsedSections = "",
    WindowX = 0.5,
    WindowY = 0.5,
    FloatX = 0.04,
    FloatY = 0.25,
    StatsX = 0.5,
    StatsY = 0.045,
    -- ===== TD AUTO =====
    AutoChallenge = true,
    AutoEvent = false,
    AutoFarm = false,
    AutoLeaveChallenge = true,
    MatchAuto = true,
    LeaveDelay = 3,
    PriorityOrder = "Challenge > Event > Farm",
    ChallengeTab = "All",
    FarmMode = "Story",
    FarmMap = "",
    FarmAct = 1,
    FarmDifficulty = "Normal",
    EventDifficulty = "Normal",
    AutoShop = true,
    ShopLeaveToBuy = true,
    -- ===== PARTY (Host / Guest) =====
    PartyEnabled = false, -- ปิด = เล่นคนเดียวตามปกติ
    PartyRole = "Host", -- Host | Guest
    PartyTarget = "", -- ชื่อ (username) ของเพื่อน
    PartyHostWait = 90, -- Host รอเพื่อนเข้าห้องสูงสุดกี่วิ
    AutoJoinJob = false,
    JobIdValue = "",
    -- state (ใช้ข้ามการวาป)
    StateActivity = "",
    StateChallengeNext = "{}",
    StateShopCycle = 0,
    StateShopMissing = false,
}
for _, id in ipairs({ "Fruit_1", "Fruit_2", "RareShard", "EpicShard", "LegendShard", "MythicShard", "MysteriousShard", "Trait", "StatRerollAll", "StatReroll", "MysteryCapsule" }) do
    Defaults["ShopC_" .. id] = (id == "Trait")
    Defaults["ShopG_" .. id] = false
end

local Config = {}
for k, v in pairs(Defaults) do
    Config[k] = v
end

local LoadedFromFile = false

local function LoadConfig()
    if not (isfile and readfile) then
        return
    end
    local ok, exists = pcall(isfile, CONFIG_FILE)
    if not (ok and exists) then
        return
    end
    pcall(function()
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        if type(data) == "table" then
            for k, v in pairs(Defaults) do
                if type(data[k]) == type(v) then
                    Config[k] = data[k]
                end
            end
            LoadedFromFile = true
        end
    end)
end

LoadConfig()
for _, k in ipairs({ "WindowX", "WindowY" }) do
    Config[k] = math.clamp(Config[k], 0.05, 0.95)
end
for _, k in ipairs({ "FloatX", "FloatY", "StatsX", "StatsY" }) do
    Config[k] = math.clamp(Config[k], 0.02, 0.98)
end
Config.UIScalePercent = math.clamp(Config.UIScalePercent, 60, 120)

local SaveHooks = {}
local SaveToken = 0

local function Fire(state)
    for _, h in ipairs(SaveHooks) do
        pcall(h, state)
    end
end

local function WriteNow()
    if not writefile then
        return "unsupported"
    end
    local ok = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
    end)
    return ok and "saved" or "failed"
end

local function SaveConfig(instant)
    SaveToken = SaveToken + 1
    local token = SaveToken
    Fire("saving")
    local function commit()
        if token ~= SaveToken then
            return
        end
        local result = WriteNow()
        Fire(result)
        if result == "saved" then
            task.delay(1.8, function()
                if token == SaveToken then
                    Fire("idle")
                end
            end)
        end
    end
    if instant then
        commit()
    else
        task.delay(0.3, commit)
    end
end

local function SetConfig(key, value)
    if Config[key] == value then
        return
    end
    Config[key] = value
    SaveConfig()
end

--==================================================
-- THEME  (ทุกสีใน UI คำนวณจาก Config และอัปเดตสดทันที)
--==================================================

local function RGB(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local function Lum(c)
    return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end

local function Hex(key, fallback)
    local ok, c = pcall(Color3.fromHex, Config[key])
    return ok and c or fallback
end

local Theme = {}

local function ComputeTheme()
    local bg = Hex("UIBackgroundColor", RGB(8, 8, 8))
    local dark = Lum(bg) < 0.5
    local to = dark and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
    Theme.Bg = bg
    Theme.Surface = bg:Lerp(to, 0.05)
    Theme.Surface2 = bg:Lerp(to, 0.095)
    Theme.Stroke = bg:Lerp(to, 0.17)
    Theme.Text = dark and RGB(244, 244, 244) or RGB(20, 20, 20)
    Theme.Sub = Theme.Text:Lerp(bg, 0.32)
    Theme.Muted = Theme.Text:Lerp(bg, 0.58)
    Theme.Accent = Hex("UIAccentColor", RGB(190, 190, 190))
    Theme.OnAccent = Lum(Theme.Accent) > 0.55 and RGB(15, 15, 15) or RGB(255, 255, 255)
    Theme.Button = Hex("UIButtonColor", RGB(36, 36, 36))
    local h, s, v = Theme.Accent:ToHSV()
    if s < 0.12 then
        Theme.Accent2 = Theme.Accent:Lerp(Color3.fromRGB(96, 104, 128), 0.6) -- เทา: ไล่เป็นเหล็กอมฟ้า
    else
        Theme.Accent2 = Color3.fromHSV((h + 0.12) % 1, s, math.max(v, 0.6))
    end
end

ComputeTheme()

local ThemeHooks = {}

local function OnTheme(fn)
    ThemeHooks[#ThemeHooks + 1] = fn
    pcall(fn)
end

local function Bind(obj, prop, key)
    OnTheme(function()
        obj[prop] = Theme[key]
    end)
end

local function ApplyTheme()
    ComputeTheme()
    for _, fn in ipairs(ThemeHooks) do
        pcall(fn)
    end
end

--==================================================
-- HELPERS
--==================================================

local Orders = setmetatable({}, { __mode = "k" })
local function Next(parent)
    Orders[parent] = (Orders[parent] or 0) + 1
    return Orders[parent]
end

local function New(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function Corner(parent, radius)
    return New("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function Stroke(parent, color, thickness, transparency)
    return New("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function Pad(parent, l, r, t, b)
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
    }, parent)
end

local function List(parent, padding)
    return New("UIListLayout", {
        Padding = UDim.new(0, padding or 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, parent)
end

local function Text(parent, text, size, font, color, align)
    local l = New("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = text or "",
        TextSize = size or 13,
        Font = font or FNT.R,
        TextXAlignment = align or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
    if type(color) == "string" then
        Bind(l, "TextColor3", color)
    elseif color then
        l.TextColor3 = color
    end
    return l
end

local function Tween(obj, t, props, style, dir)
    local tw = TweenService:Create(
        obj,
        TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function Apply(obj, animate, props)
    if animate then
        Tween(obj, 0.16, props)
    else
        for k, v in pairs(props) do
            obj[k] = v
        end
    end
end

local function Panel(parent, size, class)
    local f = New(class or "Frame", { BorderSizePixel = 0, LayoutOrder = Next(parent) }, parent)
    if class == "TextButton" then
        f.Text = ""
        f.AutoButtonColor = false
    end
    if size then
        f.Size = size
    end
    Bind(f, "BackgroundColor3", "Surface")
    Corner(f, 12)
    Bind(Stroke(f, Theme.Stroke, 1, 0.4), "Color", "Stroke")
    New("UIGradient", {
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.76, 0.76, 0.76)),
        Rotation = 90,
    }, f)
    local hi = New("Frame", {
        Size = UDim2.new(1, -28, 0, 1),
        Position = UDim2.fromOffset(14, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
    }, f)
    New("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, hi)
    return f
end

local function HoverRow(btn)
    local st = btn:FindFirstChildOfClass("UIStroke")
    btn.MouseEnter:Connect(function()
        Tween(btn, 0.12, { BackgroundColor3 = Theme.Surface2 })
        if st then
            Tween(st, 0.12, { Transparency = 0.05 })
        end
    end)
    local sc
    if btn:IsA("GuiButton") then
        sc = New("UIScale", { Scale = 1 }, btn)
        btn.MouseButton1Down:Connect(function()
            Tween(sc, 0.08, { Scale = 0.982 })
        end)
        btn.MouseButton1Up:Connect(function()
            Tween(sc, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
        end)
    end
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.12, { BackgroundColor3 = Theme.Surface })
        if st then
            Tween(st, 0.12, { Transparency = 0.4 })
        end
        if sc then
            Tween(sc, 0.12, { Scale = 1 })
        end
    end)
end

-- ชั้นสีไล่เฉดอ่อนๆ ของ accent ใช้ตกแต่งการ์ด
-- ไล่เฉด Accent -> Accent2 (วัตถุที่ใช้ต้องตั้ง BackgroundColor3 เป็นสีขาว)
local function AccentGrad(parent, rotation)
    local g = New("UIGradient", { Rotation = rotation or 0 }, parent)
    OnTheme(function()
        g.Color = ColorSequence.new(Theme.Accent, Theme.Accent2)
    end)
    return g
end

local function Tint(parent)
    local t = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1, 1, 1),
    }, parent)
    Corner(t, 12)
    local g = AccentGrad(t, 25)
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(1, 1),
    })
    return t
end

local function IsPointer(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

-- ไอคอนวาดด้วย Frame (ไม่พึ่งรูป/asset) คืนค่าฟังก์ชันเปลี่ยนสี
local function Icon(parent, kind, x, y)
    local box = New("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.fromOffset(x, y),
        BackgroundTransparency = 1,
    }, parent)
    local parts = {}
    local function rect(px, py, w, h, r, rot)
        local f = New("Frame", {
            Size = UDim2.fromOffset(w, h),
            Position = UDim2.fromOffset(px, py),
            BorderSizePixel = 0,
            Rotation = rot or 0,
        }, box)
        Corner(f, r or 1)
        parts[#parts + 1] = { f = f }
        return f
    end
    if kind == "grid" then
        rect(1, 1, 7, 7, 2)
        rect(10, 1, 7, 7, 2)
        rect(1, 10, 7, 7, 2)
        rect(10, 10, 7, 7, 2)
    elseif kind == "sliders" then
        rect(1, 2, 16, 2, 1)
        rect(1, 8, 11, 2, 1)
        rect(1, 14, 14, 2, 1)
    elseif kind == "close" then
        rect(1, 8, 16, 2, 1, 45)
        rect(1, 8, 16, 2, 1, -45)
    elseif kind == "max" then
        local r = New("Frame", {
            Size = UDim2.fromOffset(12, 12),
            Position = UDim2.fromOffset(3, 3),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, box)
        Corner(r, 3)
        parts[#parts + 1] = { stroke = Stroke(r, Color3.new(1, 1, 1), 2, 0) }
    else -- ring (settings)
        local r = New("Frame", {
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.fromOffset(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, box)
        Corner(r, 8)
        parts[#parts + 1] = { stroke = Stroke(r, Color3.new(1, 1, 1), 2, 0) }
        rect(7, 7, 4, 4, 2)
    end
    return function(c)
        for _, p in ipairs(parts) do
            if p.stroke then
                p.stroke.Color = c
            else
                p.f.BackgroundColor3 = c
            end
        end
    end
end

--==================================================
-- ROOT GUI
--==================================================

pcall(function()
    for _, v in ipairs(PlayerGui:GetChildren()) do
        if v.Name == "RELWX_UI" or v.Name == "RELWX_Floating" or v.Name == "RELWX_Stats"
            or v.Name == "TwoSki_RideAPet_Floating" then
            v:Destroy()
        end
    end
end)

local Screen = New("ScreenGui", {
    Name = "RELWX_UI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999998,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

-- เก็บ connection ทั้งหมดไว้ ตัดทิ้งตอน UI ถูกทำลาย (รันสคริปต์ซ้ำได้ไม่ค้าง)
local Conns = {}
local function Track(c)
    Conns[#Conns + 1] = c
    return c
end
Screen.Destroying:Connect(function()
    for _, c in ipairs(Conns) do
        pcall(function()
            c:Disconnect()
        end)
    end
end)

local BW, BH = 740, 580 -- ขนาดออกแบบ (ปรับตามจอผ่าน UIScale)
local SW = 172 -- ความกว้าง sidebar

local function ViewSize()
    local s = Screen.AbsoluteSize
    if s.X > 0 and s.Y > 0 then
        return s
    end
    return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
end

local function TargetScale()
    local v = ViewSize()
    local fit = math.min(v.X * 0.97 / BW, v.Y * 0.95 / BH)
    local base = math.min(fit * (Config.Maximized and 1 or 0.92), Config.Maximized and 1.4 or 1.1)
    local s = base * (Config.UIScalePercent / 100)
    return math.clamp(s, 0.3, math.max(0.3, fit))
end

local Main = New("CanvasGroup", {
    Name = "Main",
    Size = UDim2.fromOffset(BW, BH),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(Config.WindowX, Config.WindowY),
    BorderSizePixel = 0,
    BackgroundTransparency = 0.04,
    GroupTransparency = 1,
    Active = true,
    Visible = false,
}, Screen)
Bind(Main, "BackgroundColor3", "Bg")
Corner(Main, 18)

-- แสงพื้นหลัง (aurora) มุมซ้ายบน / ขวาล่าง
local function Aurora(key, rot)
    local f = New("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0 }, Main)
    Bind(f, "BackgroundColor3", key)
    Corner(f, 18)
    New("UIGradient", {
        Rotation = rot,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.82),
            NumberSequenceKeypoint.new(0.55, 1),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, f)
end
Aurora("Accent", 35)
Aurora("Accent2", 215)

-- ฝุ่นแสงลอยช้าๆ เป็นพื้นหลัง
local Dust = New("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, Main)
for i = 1, 16 do
    local sz = math.random(2, 4)
    local x = math.random()
    local p = New("Frame", {
        Size = UDim2.fromOffset(sz, sz),
        Position = UDim2.fromScale(x, 1.05),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.55 + math.random() * 0.3,
    }, Dust)
    Corner(p, 2)
    Bind(p, "BackgroundColor3", (i % 2 == 0) and "Accent" or "Accent2")
    local dur = 9 + math.random() * 9
    TweenService:Create(
        p,
        TweenInfo.new(dur, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, math.random() * 5),
        { Position = UDim2.fromScale(math.clamp(x + (math.random() - 0.5) * 0.15, 0, 1), -0.05) }
    ):Play()
end

local MainStroke = Stroke(Main, Color3.new(1, 1, 1), 1.5, 0)
local MainGrad = New("UIGradient", { Rotation = 0 }, MainStroke)
OnTheme(function()
    MainGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Stroke),
        ColorSequenceKeypoint.new(0.35, Theme.Accent),
        ColorSequenceKeypoint.new(0.65, Theme.Accent2),
        ColorSequenceKeypoint.new(1, Theme.Stroke),
    })
end)
TweenService:Create(
    MainGrad,
    TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    { Rotation = 360 }
):Play()
local MainScale = New("UIScale", { Scale = TargetScale() }, Main)

-- เงา + แสงเรืองใต้หน้าต่าง
local Shadow = New("Frame", {
    Size = UDim2.fromOffset(BW, BH),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    ZIndex = 0,
    Visible = false,
}, Screen)
local ShadowScale = New("UIScale", { Scale = 1 }, Shadow)
local ShadowLayers = {}
for i, g in ipairs({ 8, 20, 36, 56 }) do
    local l = New("Frame", {
        Size = UDim2.new(1, g * 2, 1, g * 2),
        Position = UDim2.fromOffset(-g, -g + 10),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(0, 0, 0),
    }, Shadow)
    Corner(l, 18 + g)
    ShadowLayers[i] = { f = l, base = 0.82 + i * 0.03 }
end
local ShadowGlow = New("Frame", {
    Size = UDim2.new(1, 40, 1, 40),
    Position = UDim2.fromOffset(-20, -20),
    BorderSizePixel = 0,
}, Shadow)
Corner(ShadowGlow, 38)
Bind(ShadowGlow, "BackgroundColor3", "Accent")
ShadowLayers[#ShadowLayers + 1] = { f = ShadowGlow, base = 0.95 }

Track(RunService.RenderStepped:Connect(function()
    local vis = Main.Visible
    Shadow.Visible = vis
    if not vis then
        return
    end
    Shadow.Position = Main.Position
    Shadow.Size = Main.Size
    ShadowScale.Scale = MainScale.Scale
    local a = Main.GroupTransparency
    for _, l in ipairs(ShadowLayers) do
        l.f.BackgroundTransparency = 1 - (1 - l.base) * (1 - a)
    end
end))

-- เส้นแสงด้านบนหน้าต่าง
local TopGlow = New("Frame", {
    Size = UDim2.new(0.8, 0, 0, 1),
    Position = UDim2.fromScale(0.1, 0),
    BorderSizePixel = 0,
}, Main)
Bind(TopGlow, "BackgroundColor3", "Accent")
New("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.15),
        NumberSequenceKeypoint.new(1, 1),
    }),
}, TopGlow)

local Opening = false

local function ApplyScale(animate)
    if Opening then
        return
    end
    if animate and Main.Visible then
        Tween(MainScale, 0.25, { Scale = TargetScale() }, Enum.EasingStyle.Quint)
    else
        MainScale.Scale = TargetScale()
    end
end

Track(Screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    ApplyScale(false)
end))

-- เปิด/ปิดหน้าต่างพร้อมเอฟเฟกต์ (ปิดแบบสโลว์: ค่อยๆ จางและหดลง)
-- เสียงเปิด/ปิด (ถ้าไฟล์เสียงโหลดไม่ขึ้น จะสลับไปใช้เสียงสำรองให้เอง)
local function PlayToggleSound(on, big)
    if not Config.SoundEnabled then
        return
    end
    pcall(function()
        local function play(id, vol, speed)
            local s = Instance.new("Sound")
            s.SoundId = id
            s.Volume = vol
            s.PlaybackSpeed = speed
            s.Parent = SoundService
            s:Play()
            Debris:AddItem(s, 2.5)
            return s
        end
        local speed = (on and 1.18 or 0.86) * (big and 0.85 or 1)
        local s = play(on and SOUND_ON or SOUND_OFF, big and 0.7 or 0.6, speed)
        task.delay(0.35, function()
            if s.Parent and s.TimeLength == 0 then
                play(SOUND_FALLBACK, 0.55, on and 1.35 or 0.85)
            end
        end)
    end)
end

-- ===== FX: วงคลื่น / ประกายไฟ / ลำแสง =====
local function FloatCenter()
    local s = Screen.AbsoluteSize
    return s.X * Config.FloatX, s.Y * Config.FloatY
end

local function FxRing(cx, cy, size, thick, dur, color)
    local r = New("Frame", {
        Size = UDim2.fromOffset(6, 6),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(cx, cy),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 60,
    }, Screen)
    Corner(r, 9999)
    local st = Stroke(r, color or Theme.Accent, thick, 0.05)
    Tween(r, dur, { Size = UDim2.fromOffset(size, size) }, Enum.EasingStyle.Quint)
    Tween(st, dur, { Transparency = 1, Thickness = 0.5 }, Enum.EasingStyle.Quad)
    Debris:AddItem(r, dur + 0.15)
end

local function FxSparks(cx, cy, spread, count, dist)
    for i = 1, count do
        local ang = math.random() * math.pi * 2
        local d = dist * (0.45 + math.random() * 0.8)
        local sz = math.random(3, 6)
        local px = cx + (math.random() - 0.5) * spread
        local col = (i % 3 == 0) and Color3.new(1, 1, 1) or ((i % 2 == 0) and Theme.Accent or Theme.Accent2)
        local p = New("Frame", {
            Size = UDim2.fromOffset(sz, sz),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(px, cy),
            BorderSizePixel = 0,
            BackgroundColor3 = col,
            ZIndex = 61,
        }, Screen)
        Corner(p, 3)
        local dur = 0.45 + math.random() * 0.45
        Tween(p, dur, {
            Position = UDim2.fromOffset(px + math.cos(ang) * d, cy + math.sin(ang) * d * 0.85),
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(1, 1),
        }, Enum.EasingStyle.Quint)
        Debris:AddItem(p, dur + 0.15)
    end
end

local function FxBeam(cx, cy, w)
    local b = New("Frame", {
        Size = UDim2.fromOffset(w, 4),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(cx, cy),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 62,
    }, Screen)
    New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, b)
    New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent2),
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Theme.Accent),
        }),
    }, b)
    Stroke(b, Theme.Accent, 5, 0.65)
    Debris:AddItem(b, 2)
    return b
end

local AnimToken = 0

-- เปิด: บินออกจากปุ่ม RX แล้วขยายเป็นหน้าต่าง + วงคลื่น
local function PlayOpen()
    AnimToken = AnimToken + 1
    local token = AnimToken
    Opening = true
    local t = TargetScale()
    local fx, fy = FloatCenter()

    MainStroke.Thickness = 1.5
    Main.Size = UDim2.fromOffset(BW, BH)
    Main.Position = UDim2.fromOffset(fx, fy)
    Main.GroupTransparency = 1
    MainScale.Scale = t * 0.12
    Main.Visible = true

    PlayToggleSound(true, true)
    FxRing(fx, fy, 120, 3, 0.55)
    FxSparks(fx, fy, 6, 12, 60)

    Tween(Main, 0.3, { GroupTransparency = 0 })
    Tween(Main, 0.6, { Position = UDim2.fromScale(Config.WindowX, Config.WindowY) }, Enum.EasingStyle.Quint)
    Tween(MainScale, 0.65, { Scale = t }, Enum.EasingStyle.Back)

    task.delay(0.5, function()
        if token ~= AnimToken then
            return
        end
        local ap, asz = Main.AbsolutePosition, Main.AbsoluteSize
        FxRing(ap.X + asz.X / 2, ap.Y + asz.Y / 2, math.max(asz.X, asz.Y) * 1.05, 2, 0.7, Theme.Accent2)
    end)
    task.delay(0.68, function()
        if token == AnimToken then
            Opening = false
        end
    end)
end

-- ปิด: ตัวหน้าต่างพองเล็กน้อย -> ยุบเป็นเส้นแสง -> หดเป็นจุด + ประกายไฟ -> บินเข้าปุ่ม RX แล้วปล่อยคลื่น
local function PlayClose()
    AnimToken = AnimToken + 1
    local token = AnimToken
    Opening = true
    PlayToggleSound(false, true)

    local s0 = MainScale.Scale
    local function alive()
        return token == AnimToken
    end

    -- 1) พองเล็กน้อย + ขอบสว่างวาบ
    Tween(MainScale, 0.14, { Scale = s0 * 1.03 }, Enum.EasingStyle.Sine)
    Tween(MainStroke, 0.3, { Thickness = 3.5 }, Enum.EasingStyle.Sine)

    -- 2) ยุบแนวตั้งเป็นเส้นบางๆ
    task.delay(0.14, function()
        if not alive() then
            return
        end
        Tween(Main, 0.36, { Size = UDim2.fromOffset(BW, 5) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tween(MainScale, 0.36, { Scale = s0 * 0.97 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    end)

    -- 3) เส้นแสงวาบ -> หดเป็นจุด + วงคลื่น + ประกายไฟ
    task.delay(0.5, function()
        if not alive() then
            return
        end
        local ap, asz = Main.AbsolutePosition, Main.AbsoluteSize
        local cx, cy = ap.X + asz.X / 2, ap.Y + asz.Y / 2
        local w = math.max(asz.X, 40)

        Main.Visible = false
        Main.Size = UDim2.fromOffset(BW, BH)
        Main.Position = UDim2.fromScale(Config.WindowX, Config.WindowY)
        MainScale.Scale = s0
        MainStroke.Thickness = 1.5

        local beam = FxBeam(cx, cy, w)
        FxRing(cx, cy, w * 0.75, 3, 0.6)
        FxRing(cx, cy, w * 0.45, 2, 0.5, Theme.Accent2)
        FxSparks(cx, cy, w, 28, 150 * math.max(s0, 0.6))
        Tween(beam, 0.26, { Size = UDim2.fromOffset(18, 18) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

        -- 4) จุดแสงบินเข้าปุ่ม RX
        task.delay(0.28, function()
            local fx, fy = FloatCenter()
            Tween(beam, 0.36, {
                Position = UDim2.fromOffset(fx, fy),
                Size = UDim2.fromOffset(8, 8),
            }, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)
            task.delay(0.36, function()
                beam:Destroy()
                FxRing(fx, fy, 100, 3, 0.55)
                FxSparks(fx, fy, 6, 12, 50)
                if alive() then
                    Opening = false
                end
            end)
        end)
    end)
end

local function SetWindow(visible)
    SetConfig("WindowVisible", visible)
    if visible then
        PlayOpen()
    else
        PlayClose()
    end
end

-- ลากหน้าต่าง/ปุ่ม/วิดเจ็ต แล้วเซฟตำแหน่งเป็นสัดส่วนหน้าจอ
local function SavePosition(target, kx, ky)
    local s = Screen.AbsoluteSize
    if s.X <= 0 or s.Y <= 0 then
        return
    end
    local c = target.AbsolutePosition + target.AbsoluteSize / 2
    local fx = math.clamp(c.X / s.X, 0.02, 0.98)
    local fy = math.clamp(c.Y / s.Y, 0.02, 0.98)
    target.Position = UDim2.fromScale(fx, fy)
    SetConfig(kx, math.floor(fx * 10000) / 10000)
    SetConfig(ky, math.floor(fy * 10000) / 10000)
end

local function MakeDraggable(handle, target, kx, ky, onClick)
    local dragging, dragInput, startPos, startCenter, moved = false, nil, nil, nil, false

    handle.InputBegan:Connect(function(input)
        if IsPointer(input) then
            dragging = true
            moved = false
            dragInput = input
            startPos = input.Position
            startCenter = target.AbsolutePosition + target.AbsoluteSize / 2
        end
    end)

    Track(UIS.InputChanged:Connect(function(input)
        if not dragging or not IsMove(input) then
            return
        end
        if input.UserInputType == Enum.UserInputType.Touch and input ~= dragInput then
            return
        end
        local d = input.Position - startPos
        if d.Magnitude > 8 then
            moved = true
        end
        if moved then
            local s = Screen.AbsoluteSize
            target.Position = UDim2.fromOffset(
                math.clamp(startCenter.X + d.X, 0, s.X),
                math.clamp(startCenter.Y + d.Y, 0, s.Y)
            )
        end
    end))

    Track(UIS.InputEnded:Connect(function(input)
        if dragging and IsPointer(input) then
            if input.UserInputType == Enum.UserInputType.Touch and input ~= dragInput then
                return
            end
            dragging = false
            if moved then
                SavePosition(target, kx, ky)
            elseif onClick then
                onClick()
            end
        end
    end))
end

-- แจ้งเตือนเล็กๆ ด้านล่างจอ (Toast)
local ActiveToast
local function Toast(text, on)
    if ActiveToast then
        ActiveToast:Destroy()
        ActiveToast = nil
    end
    local t = New("TextLabel", {
        Size = UDim2.fromOffset(0, 38),
        AutomaticSize = Enum.AutomaticSize.X,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 48),
        BorderSizePixel = 0,
        Text = text,
        TextSize = 12,
        Font = FNT.M,
        BackgroundColor3 = Theme.Surface2,
        TextColor3 = Theme.Text,
        ZIndex = 300,
    }, Screen)
    Corner(t, 19)
    Stroke(t, Theme.Accent, 1, 0.55)
    Pad(t, 38, 18, 0, 0)
    local dot = New("Frame", {
        Size = UDim2.fromOffset(8, 8),
        Position = UDim2.new(0, -24, 0.5, -4),
        BorderSizePixel = 0,
        BackgroundColor3 = (on == true) and RGB(70, 200, 120) or (on == false and Theme.Muted or Theme.Accent),
    }, t)
    Corner(dot, 4)
    ActiveToast = t
    Tween(t, 0.35, { Position = UDim2.new(0.5, 0, 1, -26) }, Enum.EasingStyle.Back)
    task.delay(1.7, function()
        if ActiveToast == t then
            Tween(t, 0.25, { Position = UDim2.new(0.5, 0, 1, 48) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.3, function()
                t:Destroy()
                if ActiveToast == t then
                    ActiveToast = nil
                end
            end)
        end
    end)
end

--==================================================
-- SAVE STATUS PILL
--==================================================

local SaveStates = {
    idle = { "Auto Save", nil },
    saving = { "กำลังบันทึก...", RGB(240, 190, 60) },
    saved = { "บันทึกแล้ว", RGB(70, 200, 120) },
    failed = { "บันทึกไม่ได้", RGB(235, 75, 90) },
    unsupported = { "ไม่รองรับไฟล์", RGB(235, 75, 90) },
}

local function StatusPill(parent, width)
    local pill = New("Frame", { Size = UDim2.fromOffset(width or 108, 26), BorderSizePixel = 0 }, parent)
    Bind(pill, "BackgroundColor3", "Surface2")
    Corner(pill, 13)
    Bind(Stroke(pill, Theme.Stroke, 1, 0.3), "Color", "Stroke")

    local dot = New("Frame", {
        Size = UDim2.fromOffset(8, 8),
        Position = UDim2.new(0, 11, 0.5, -4),
        BorderSizePixel = 0,
    }, pill)
    Corner(dot, 4)

    local label = Text(pill, "", 10, FNT.M, "Sub")
    label.Position = UDim2.fromOffset(26, 0)
    label.Size = UDim2.new(1, -30, 1, 0)

    local current = "idle"
    local function render()
        local s = SaveStates[current]
        label.Text = s[1]
        dot.BackgroundColor3 = s[2] or Theme.Accent
    end
    OnTheme(render)

    SaveHooks[#SaveHooks + 1] = function(state)
        current = state
        render()
    end
    return pill
end

--==================================================
-- FPS / MS WIDGET (เล็ก ลากได้ แยกจากหน้าต่างหลัก)
--==================================================

local StatsGui = New("ScreenGui", {
    Name = "RELWX_Stats",
    ResetOnSpawn = false,
    DisplayOrder = 999999,
    IgnoreGuiInset = true,
    Enabled = Config.StatsVisible,
}, PlayerGui)

local StatsBox = New("Frame", {
    Size = UDim2.fromOffset(152, 30),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(Config.StatsX, Config.StatsY),
    BorderSizePixel = 0,
    BackgroundTransparency = 0.1,
    Active = true,
}, StatsGui)
Bind(StatsBox, "BackgroundColor3", "Surface")
Corner(StatsBox, 15)
Bind(Stroke(StatsBox, Theme.Stroke, 1, 0.2), "Color", "Stroke")

local FpsLabel = Text(StatsBox, "", 11, FNT.M, "Sub", Enum.TextXAlignment.Center)
FpsLabel.RichText = true
FpsLabel.Size = UDim2.new(0.5, -1, 1, 0)

local MsLabel = Text(StatsBox, "", 11, FNT.M, "Sub", Enum.TextXAlignment.Center)
MsLabel.RichText = true
MsLabel.Position = UDim2.new(0.5, 1, 0, 0)
MsLabel.Size = UDim2.new(0.5, -1, 1, 0)

local StatsDivider = New("Frame", {
    Size = UDim2.fromOffset(1, 14),
    Position = UDim2.new(0.5, 0, 0.5, -7),
    BorderSizePixel = 0,
}, StatsBox)
Bind(StatsDivider, "BackgroundColor3", "Stroke")

MakeDraggable(StatsBox, StatsBox, "StatsX", "StatsY")

local Metrics = { fps = 60, ping = 0 }

do
    local frames, acc = 0, 0
    Track(RunService.RenderStepped:Connect(function(dt)
        frames = frames + 1
        acc = acc + dt
        if acc >= 0.5 then
            Metrics.fps = math.floor(frames / acc + 0.5)
            frames, acc = 0, 0
        end
    end))
end

local function GetPing()
    local ok, v = pcall(function()
        return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return (ok and type(v) == "number") and math.floor(v + 0.5) or 0
end

local function Level(value, good, mid, higherIsBetter)
    local g, m, b = RGB(70, 200, 120), RGB(240, 190, 60), RGB(235, 75, 90)
    if higherIsBetter then
        return value >= good and g or (value >= mid and m or b)
    end
    return value <= good and g or (value <= mid and m or b)
end

local function RefreshStats()
    Metrics.ping = GetPing()
    local fc = Level(Metrics.fps, 50, 30, true)
    local mc = Level(Metrics.ping, 80, 160, false)
    local muted = "#" .. Theme.Muted:ToHex()
    FpsLabel.Text = string.format(
        '<font color="#%s"><b>%d</b></font> <font color="%s">FPS</font>',
        fc:ToHex(), Metrics.fps, muted
    )
    MsLabel.Text = string.format(
        '<font color="#%s"><b>%d</b></font> <font color="%s">MS</font>',
        mc:ToHex(), Metrics.ping, muted
    )
end

--==================================================
-- TOP BAR
--==================================================

local Top = New("Frame", {
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, Main)

local TopLine = New("Frame", {
    Size = UDim2.new(1, -24, 0, 1),
    Position = UDim2.new(0, 12, 1, -1),
    BorderSizePixel = 0,
    BackgroundColor3 = Color3.new(1, 1, 1),
}, Top)
do
    local g = AccentGrad(TopLine, 0)
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.95),
        NumberSequenceKeypoint.new(0.5, 0.15),
        NumberSequenceKeypoint.new(1, 0.95),
    })
end

Top.ClipsDescendants = true
local Shine = New("Frame", {
    Size = UDim2.new(0, 120, 1, 0),
    Position = UDim2.new(-0.3, 0, 0, 0),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0,
}, Top)
New("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.93),
        NumberSequenceKeypoint.new(1, 1),
    }),
}, Shine)
TweenService:Create(
    Shine,
    TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 4),
    { Position = UDim2.new(1.1, 0, 0, 0) }
):Play()

local Badge = New("Frame", {
    Size = UDim2.fromOffset(34, 34),
    Position = UDim2.fromOffset(16, 13),
    BorderSizePixel = 0,
}, Top)
Badge.BackgroundColor3 = Color3.new(1, 1, 1)
AccentGrad(Badge, 45)
Corner(Badge, 10)
Bind(Stroke(Badge, Theme.Accent, 1.5, 0.65), "Color", "Accent")
local BadgeText = Text(Badge, "RX", 13, FNT.B, nil, Enum.TextXAlignment.Center)
BadgeText.Size = UDim2.fromScale(1, 1)
Bind(BadgeText, "TextColor3", "OnAccent")

local Brand = Text(Top, "", 15, FNT.B, "Text")
Brand.RichText = true
OnTheme(function()
    Brand.Text = 'RELWX <font color="#' .. Theme.Accent:ToHex() .. '">HUB</font>'
end)
Brand.Position = UDim2.fromOffset(60, 10)
Brand.Size = UDim2.new(1, -270, 0, 22)

local BrandSub = Text(Top, tostring(game.Name or ""), 10, FNT.R, "Muted")
BrandSub.Position = UDim2.fromOffset(60, 31)
BrandSub.Size = UDim2.new(1, -270, 0, 16)

local function WindowButton(kind, xOffset, danger)
    local b = New("TextButton", {
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(1, xOffset, 0.5, -16),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, Top)
    Corner(b, 10)
    Bind(b, "BackgroundColor3", "Surface2")
    local paint = Icon(b, kind, 7, 7)
    OnTheme(function()
        paint(Theme.Sub)
    end)
    b.MouseEnter:Connect(function()
        Tween(b, 0.12, { BackgroundColor3 = danger and RGB(200, 70, 80) or Theme.Button })
        paint(danger and RGB(255, 255, 255) or Theme.Text)
    end)
    b.MouseLeave:Connect(function()
        Tween(b, 0.12, { BackgroundColor3 = Theme.Surface2 })
        paint(Theme.Sub)
    end)
    return b
end

local MaxBtn = WindowButton("max", -86, false)
local CloseBtn = WindowButton("close", -48, true)
CloseBtn.MouseButton1Click:Connect(function()
    SetWindow(false)
end)

MakeDraggable(Top, Main, "WindowX", "WindowY")

MaxBtn.MouseButton1Click:Connect(function()
    SetConfig("Maximized", not Config.Maximized)
    SetConfig("WindowX", 0.5)
    SetConfig("WindowY", 0.5)
    Tween(Main, 0.3, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Quint)
    ApplyScale(true)
end)

--==================================================
-- SIDEBAR (หมวดหมู่)
--==================================================

local Rail = New("Frame", {
    Size = UDim2.new(0, SW, 1, -80),
    Position = UDim2.fromOffset(12, 68),
    BorderSizePixel = 0,
}, Main)
Bind(Rail, "BackgroundColor3", "Surface")
Corner(Rail, 14)
Bind(Stroke(Rail, Theme.Stroke, 1, 0.4), "Color", "Stroke")

local CatList = New("ScrollingFrame", {
    Size = UDim2.new(1, -16, 1, -80),
    Position = UDim2.fromOffset(8, 10),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 2,
    ScrollBarImageTransparency = 0.3,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ElasticBehavior = Enum.ElasticBehavior.Never,
}, Rail)
Bind(CatList, "ScrollBarImageColor3", "Accent")
List(CatList, 4)
Pad(CatList, 0, 4, 1, 1)

local UserBox = New("Frame", {
    Size = UDim2.new(1, -16, 0, 52),
    Position = UDim2.new(0, 8, 1, -60),
    BorderSizePixel = 0,
}, Rail)
Bind(UserBox, "BackgroundColor3", "Surface2")
Corner(UserBox, 12)

local Avatar = New("ImageLabel", {
    Size = UDim2.fromOffset(34, 34),
    Position = UDim2.new(0, 9, 0.5, -17),
    BorderSizePixel = 0,
    Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=60&h=60",
}, UserBox)
Corner(Avatar, 17)
Bind(Avatar, "BackgroundColor3", "Button")
Bind(Stroke(Avatar, Theme.Accent, 1.5, 0.2), "Color", "Accent")
Bind(Stroke(UserBox, Theme.Stroke, 1, 0.5), "Color", "Stroke")
local Online = New("Frame", {
    Size = UDim2.fromOffset(10, 10),
    Position = UDim2.new(0, 36, 0.5, 7),
    BorderSizePixel = 0,
    BackgroundColor3 = RGB(70, 200, 120),
    ZIndex = 3,
}, UserBox)
Corner(Online, 5)
Bind(Stroke(Online, Theme.Surface2, 2, 0), "Color", "Surface2")

local UName = Text(UserBox, LocalPlayer.DisplayName, 12, FNT.B, "Text")
UName.Position = UDim2.fromOffset(52, 9)
UName.Size = UDim2.new(1, -58, 0, 18)
local UTag = Text(UserBox, "@" .. LocalPlayer.Name, 10, FNT.R, "Muted")
UTag.Position = UDim2.fromOffset(52, 27)
UTag.Size = UDim2.new(1, -58, 0, 14)

local Pages = {}
local TabList = {}

local function CatGroup(name)
    local l = Text(CatList, name, 10, FNT.B, "Muted")
    l.Size = UDim2.new(1, 0, 0, 26)
    l.LayoutOrder = Next(CatList)
    Pad(l, 10, 0, 6, 0)
    return l
end

local CurrentTab = nil
local function SelectTab(id)
    if not Pages[id] then
        id = "Home"
    end
    SetConfig("LastTab", id)
    local changed = id ~= CurrentTab
    CurrentTab = id
    for pid, page in pairs(Pages) do
        page.Visible = (pid == id)
    end
    if changed then
        local p = Pages[id]
        p.Position = UDim2.fromOffset(0, 16)
        Tween(p, 0.32, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint)
    end
    for _, t in ipairs(TabList) do
        t.active = (t.id == id)
        t.paint()
    end
end

local function Category(name, id, iconKind)
    local b = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = Next(CatList),
    }, CatList)
    Corner(b, 11)
    local bst = Stroke(b, Theme.Accent, 1, 1)

    local ind = New("Frame", {
        Size = UDim2.fromOffset(3, 8),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 4, 0.5, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, b)
    Corner(ind, 2)

    local setIcon = Icon(b, iconKind, 16, 12)

    local lbl = Text(b, name, 13, FNT.M)
    lbl.Position = UDim2.fromOffset(44, 0)
    lbl.Size = UDim2.new(1, -48, 1, 0)
    lbl.TextColor3 = Theme.Sub

    local tab = { id = id, active = false, hover = false }
    function tab.paint()
        Tween(b, 0.15, {
            BackgroundColor3 = tab.active and Theme.Accent or Theme.Button,
            BackgroundTransparency = tab.active and 0.84 or (tab.hover and 0.5 or 1),
        })
        Tween(bst, 0.15, { Color = Theme.Accent, Transparency = tab.active and 0.55 or 1 })
        Tween(lbl, 0.15, { TextColor3 = tab.active and Theme.Text or Theme.Sub })
        Tween(ind, 0.15, {
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = tab.active and 0 or 1,
            Size = tab.active and UDim2.fromOffset(3, 22) or UDim2.fromOffset(3, 8),
        })
        setIcon(tab.active and Theme.Accent or Theme.Sub)
    end
    TabList[#TabList + 1] = tab
    OnTheme(tab.paint)

    b.MouseEnter:Connect(function()
        tab.hover = true
        tab.paint()
    end)
    b.MouseLeave:Connect(function()
        tab.hover = false
        tab.paint()
    end)
    b.MouseButton1Click:Connect(function()
        SelectTab(id)
    end)
    return b
end

--==================================================
-- PAGES
--==================================================

local Body = New("Frame", {
    Size = UDim2.new(1, -(SW + 36), 1, -80),
    Position = UDim2.fromOffset(SW + 24, 68),
    BackgroundTransparency = 1,
}, Main)

local function MakePage(id, title, subtitle)
    local page = New("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
    }, Body)
    Bind(page, "ScrollBarImageColor3", "Stroke")
    List(page, 8)
    Pad(page, 0, 8, 0, 14)

    local head = New("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        LayoutOrder = Next(page),
    }, page)
    local t = Text(head, title, 22, FNT.B, "Text")
    t.Size = UDim2.new(1, 0, 0, 28)
    local s = Text(head, subtitle or "", 11, FNT.R, "Muted")
    s.Position = UDim2.fromOffset(0, 29)
    s.Size = UDim2.new(1, 0, 0, 18)
    local hb = New("Frame", {
        Size = UDim2.fromOffset(36, 3),
        Position = UDim2.fromOffset(0, 53),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1, 1, 1),
    }, head)
    Corner(hb, 2)
    AccentGrad(hb, 0)

    Pages[id] = page
    return page
end

-- Section แบบพับ/ขยายได้ (จำสถานะไว้ใน Config)
local Collapsed = {}
for id in string.gmatch(Config.CollapsedSections, "[^|]+") do
    Collapsed[id] = true
end
local function SaveCollapsed()
    local t = {}
    for id, v in pairs(Collapsed) do
        if v then
            t[#t + 1] = id
        end
    end
    table.sort(t)
    SetConfig("CollapsedSections", table.concat(t, "|"))
end

local SectionsByPage = {}
local CurrentSection = nil

local function Section(page, title)
    local hdr = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = Next(page),
    }, page)

    local bar = New("Frame", {
        Size = UDim2.fromOffset(3, 14),
        Position = UDim2.new(0, 2, 0.5, -7),
        BorderSizePixel = 0,
    }, hdr)
    Corner(bar, 2)
    bar.BackgroundColor3 = Color3.new(1, 1, 1)
    AccentGrad(bar, 90)

    local hl = New("Frame", {
        Size = UDim2.new(1, -4, 0, 1),
        Position = UDim2.new(0, 2, 1, -1),
        BorderSizePixel = 0,
    }, hdr)
    Bind(hl, "BackgroundColor3", "Stroke")
    New("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, hl)

    local label = Text(hdr, title, 13, FNT.B, "Text")
    label.Position = UDim2.fromOffset(14, 0)
    label.Size = UDim2.new(1, -44, 1, 0)

    -- ลูกศร (วาดด้วยเส้น 2 เส้น)
    local chev = New("Frame", {
        Size = UDim2.fromOffset(14, 14),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -18, 0.5, 0),
        BackgroundTransparency = 1,
    }, hdr)
    local c1 = New("Frame", {
        Size = UDim2.fromOffset(8, 2), Position = UDim2.fromOffset(1, 6), Rotation = 45, BorderSizePixel = 0,
    }, chev)
    local c2 = New("Frame", {
        Size = UDim2.fromOffset(8, 2), Position = UDim2.fromOffset(6, 6), Rotation = -45, BorderSizePixel = 0,
    }, chev)
    Corner(c1, 1)
    Corner(c2, 1)
    OnTheme(function()
        c1.BackgroundColor3 = Theme.Muted
        c2.BackgroundColor3 = Theme.Muted
    end)

    local sec = { label = hdr, items = {}, collapsed = Collapsed[title] == true }
    function sec.refresh(animate)
        for _, it in ipairs(sec.items) do
            it.frame.Visible = it.matched and not sec.collapsed
        end
        local rot = sec.collapsed and -90 or 0
        if animate then
            Tween(chev, 0.18, { Rotation = rot })
        else
            chev.Rotation = rot
        end
    end
    sec.refresh(false)

    hdr.MouseButton1Click:Connect(function()
        sec.collapsed = not sec.collapsed
        Collapsed[title] = sec.collapsed
        SaveCollapsed()
        sec.refresh(true)
    end)

    CurrentSection = sec
    SectionsByPage[page] = SectionsByPage[page] or {}
    table.insert(SectionsByPage[page], sec)
    return sec
end

local function Register(row, search)
    local sec = CurrentSection
    if sec then
        table.insert(sec.items, { frame = row, search = string.lower(search or ""), matched = true })
        sec.refresh(false)
    end
end

local Refreshers = {}

--==================================================
-- COMPONENTS: Toggle / Slider / ColorRow
--==================================================

local FuncToggles = {}
local UpdateSummary = function() end

local function Toggle(page, opts)
    local row = Panel(page, UDim2.new(1, 0, 0, 64), "TextButton")
    HoverRow(row)
    Register(row, opts.title .. " " .. (opts.desc or ""))
    local rowStroke = row:FindFirstChildOfClass("UIStroke")

    local title = Text(row, opts.title, 13, FNT.M, "Text")
    title.Position = UDim2.fromOffset(18, 11)
    title.Size = UDim2.new(1, -96, 0, 20)

    local desc = Text(row, opts.desc or "", 11, FNT.R, "Muted")
    desc.Position = UDim2.fromOffset(18, 33)
    desc.Size = UDim2.new(1, -96, 0, 18)

    local strip = New("Frame", {
        Size = UDim2.fromOffset(3, 26),
        Position = UDim2.new(0, 4, 0.5, -13),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
    }, row)
    Corner(strip, 2)
    AccentGrad(strip, 90)

    local glow = New("Frame", {
        Size = UDim2.fromOffset(62, 40),
        Position = UDim2.new(1, -71, 0.5, -20),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
    }, row)
    Corner(glow, 20)
    AccentGrad(glow, 0)

    local track = New("Frame", {
        Size = UDim2.fromOffset(48, 26),
        Position = UDim2.new(1, -64, 0.5, -13),
        BorderSizePixel = 0,
    }, row)
    Corner(track, 13)
    local tStroke = Stroke(track, Theme.Stroke, 1, 0.2)
    Bind(tStroke, "Color", "Stroke")

    local fill = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
    }, track)
    Corner(fill, 13)
    AccentGrad(fill, 0)

    local knob = New("Frame", {
        Size = UDim2.fromOffset(20, 20),
        Position = UDim2.fromOffset(3, 3),
        BorderSizePixel = 0,
    }, track)
    Corner(knob, 10)

    local state = Config[opts.key] == true

    if page == Pages["Functions"] then
        FuncToggles[#FuncToggles + 1] = function()
            return state
        end
    end

    local function render(animate)
        Apply(track, animate, { BackgroundColor3 = Theme.Button })
        Apply(fill, animate, { BackgroundTransparency = state and 0 or 1 })
        Apply(glow, animate, { BackgroundTransparency = state and 0.82 or 1 })
        Apply(knob, animate, {
            Position = state and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = state and Theme.OnAccent or Theme.Sub,
        })
        Apply(strip, animate, { BackgroundTransparency = state and 0 or 1 })
        Apply(tStroke, animate, { Color = state and Theme.Accent or Theme.Stroke })
        if rowStroke then
            Apply(rowStroke, animate, {
                Color = state and Theme.Accent or Theme.Stroke,
                Transparency = state and 0.55 or 0.4,
            })
        end
        UpdateSummary()
    end
    OnTheme(function()
        render(false)
    end)

    local function set(v, fire)
        state = v
        SetConfig(opts.key, v)
        render(true)
        if fire then
            PlayToggleSound(v)
            if opts.callback then
                task.spawn(opts.callback, v)
            end
        end
    end

    row.MouseButton1Click:Connect(function()
        set(not state, true)
    end)

    Refreshers[#Refreshers + 1] = function()
        state = Config[opts.key] == true
        render(false)
        if opts.callback then
            task.spawn(opts.callback, state)
        end
    end

    if opts.callback then
        task.defer(opts.callback, state)
    end

    return {
        Get = function()
            return state
        end,
        Set = function(v)
            set(v, true)
        end,
    }
end

local function Slider(page, opts)
    local min, max, step = opts.min, opts.max, opts.step or 1
    local row = Panel(page, UDim2.new(1, 0, 0, 78))
    Register(row, opts.title .. " " .. (opts.desc or ""))

    local title = Text(row, opts.title, 13, FNT.M, "Text")
    title.Position = UDim2.fromOffset(16, 10)
    title.Size = UDim2.new(1, -110, 0, 20)

    local desc = Text(row, opts.desc or "", 11, FNT.R, "Muted")
    desc.Position = UDim2.fromOffset(16, 31)
    desc.Size = UDim2.new(1, -110, 0, 16)

    local pill = New("Frame", {
        Size = UDim2.fromOffset(82, 22),
        Position = UDim2.new(1, -98, 0, 9),
        BorderSizePixel = 0,
    }, row)
    Corner(pill, 11)
    Bind(pill, "BackgroundColor3", "Surface2")
    Bind(Stroke(pill, Theme.Accent, 1, 0.6), "Color", "Accent")
    local val = Text(row, "", 12, FNT.B, "Accent", Enum.TextXAlignment.Center)
    val.Position = UDim2.new(1, -98, 0, 9)
    val.Size = UDim2.fromOffset(82, 22)

    local bar = New("Frame", {
        Size = UDim2.new(1, -32, 0, 6),
        Position = UDim2.fromOffset(16, 60),
        BorderSizePixel = 0,
    }, row)
    Corner(bar, 3)
    Bind(bar, "BackgroundColor3", "Button")

    local fill = New("Frame", {
        Size = UDim2.fromScale(0, 1),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1, 1, 1),
    }, bar)
    Corner(fill, 3)
    AccentGrad(fill, 0)

    local knob = New("Frame", {
        Size = UDim2.fromOffset(16, 16),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        BorderSizePixel = 0,
    }, bar)
    Corner(knob, 8)
    Bind(knob, "BackgroundColor3", "Text")
    Bind(Stroke(knob, Theme.Accent, 3, 0), "Color", "Accent")

    local hit = New("TextButton", {
        Size = UDim2.new(1, -32, 0, 30),
        Position = UDim2.fromOffset(16, 48),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, row)

    local value = Config[opts.key]

    local function show()
        local a = (value - min) / (max - min)
        fill.Size = UDim2.fromScale(a, 1)
        knob.Position = UDim2.fromScale(a, 0.5)
        val.Text = string.format("%g", value) .. (opts.suffix or "")
    end

    local function setValue(v, fire)
        v = math.clamp(math.floor((v - min) / step + 0.5) * step + min, min, max)
        if v == value and fire then
            return
        end
        value = v
        show()
        if fire then
            SetConfig(opts.key, v)
            if opts.callback then
                task.spawn(opts.callback, v)
            end
        end
    end

    local dragging = false
    local function fromX(x)
        local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        setValue(min + (max - min) * a, true)
    end

    hit.InputBegan:Connect(function(input)
        if IsPointer(input) then
            dragging = true
            page.ScrollingEnabled = false
            Tween(knob, 0.12, { Size = UDim2.fromOffset(21, 21) })
            fromX(input.Position.X)
        end
    end)
    Track(UIS.InputChanged:Connect(function(input)
        if dragging and IsMove(input) then
            fromX(input.Position.X)
        end
    end))
    Track(UIS.InputEnded:Connect(function(input)
        if dragging and IsPointer(input) then
            dragging = false
            page.ScrollingEnabled = true
            Tween(knob, 0.12, { Size = UDim2.fromOffset(16, 16) })
        end
    end))

    value = math.clamp(value, min, max)
    show()

    Refreshers[#Refreshers + 1] = function()
        value = math.clamp(Config[opts.key], min, max)
        show()
        if opts.callback then
            task.spawn(opts.callback, value)
        end
    end

    if opts.callback then
        task.defer(opts.callback, value)
    end
end

-- ============================================================
--  COLOR PICKER v2  (สี่เหลี่ยมเฉด + แถบ Hue + HEX + พรีเซ็ต)
--  เปลี่ยนสีแล้วเซฟอัตโนมัติผ่าน SetConfig เหมือนเดิม
-- ============================================================
local PaletteColors = {
    "FFFFFF", "BEBEBE", "6B6B76", "2A2A33", "0E0E14", "000000", "8B5CF6", "6366F1",
    "3B82F6", "22D3EE", "10B981", "84CC16", "FACC15", "FB923C", "EF4444", "EC4899",
}

local ActiveOverlay, ActivePopup
local PaletteConns = {}

local function ClosePalette()
    for _, c in ipairs(PaletteConns) do
        pcall(function()
            c:Disconnect()
        end)
    end
    PaletteConns = {}
    if ActiveOverlay then
        ActiveOverlay:Destroy()
        ActiveOverlay = nil
    end
    if ActivePopup then
        ActivePopup:Destroy()
        ActivePopup = nil
    end
end

-- รวมการอัปเดตธีมให้เหลือครั้งเดียวต่อเฟรม (ลากสีแล้วไม่หน่วง)
local themePending = false
local function QueueTheme()
    if themePending then
        return
    end
    themePending = true
    task.defer(function()
        themePending = false
        ApplyTheme()
    end)
end

local function OpenPalette(title, key, onPick)
    ClosePalette()

    ActiveOverlay = New("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 150,
    }, Screen)
    Tween(ActiveOverlay, 0.2, { BackgroundTransparency = 0.45 })
    ActiveOverlay.MouseButton1Click:Connect(ClosePalette)

    local PW, PH = 240, 304
    local pop = New("CanvasGroup", {
        Size = UDim2.fromOffset(PW, PH),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ZIndex = 160,
        Active = true,
    }, Screen)
    Corner(pop, 16)
    Stroke(pop, Theme.Accent, 1.5, 0.35)
    local vs = ViewSize()
    New("UIScale", { Scale = math.clamp((vs.Y - 24) / PH, 0.5, 1) }, pop)
    ActivePopup = pop
    Tween(pop, 0.2, { GroupTransparency = 0 })

    -- สีเริ่มต้นจาก Config
    local okc, c0 = pcall(Color3.fromHex, Config[key])
    if not okc then
        c0 = Color3.new(1, 1, 1)
    end
    local H, S, V = c0:ToHSV()

    -- หัวข้อ + พรีวิว + ปุ่มปิด
    local ttl = Text(pop, title or "เลือกสี", 13, FNT.B, Theme.Text)
    ttl.Position = UDim2.fromOffset(14, 10)
    ttl.Size = UDim2.new(1, -130, 0, 20)

    local prev = New("Frame", {
        Size = UDim2.fromOffset(36, 18),
        Position = UDim2.fromOffset(PW - 82, 11),
        BorderSizePixel = 0,
    }, pop)
    Corner(prev, 6)
    Stroke(prev, Color3.new(1, 1, 1), 1, 0.75)

    local closeB = New("TextButton", {
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.fromOffset(PW - 38, 8),
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        Text = "×",
        TextSize = 18,
        Font = FNT.B,
        TextColor3 = Theme.Sub,
        AutoButtonColor = false,
    }, pop)
    Corner(closeB, 8)
    closeB.MouseButton1Click:Connect(ClosePalette)

    -- สี่เหลี่ยมเลือก Saturation / Value
    local sv = New("Frame", {
        Size = UDim2.fromOffset(PW - 28, 124),
        Position = UDim2.fromOffset(14, 40),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromHSV(H, 1, 1),
    }, pop)
    Corner(sv, 10)
    local wf = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1, 1, 1),
    }, sv)
    Corner(wf, 10)
    New("UIGradient", { Transparency = NumberSequence.new(0, 1) }, wf)
    local bf = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(0, 0, 0),
    }, sv)
    Corner(bf, 10)
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, bf)
    local svCur = New("Frame", {
        Size = UDim2.fromOffset(16, 16),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, sv)
    Corner(svCur, 8)
    Stroke(svCur, Color3.new(1, 1, 1), 2.5, 0)
    local svHit = New("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, sv)

    -- แถบ Hue
    local hue = New("Frame", {
        Size = UDim2.fromOffset(PW - 28, 14),
        Position = UDim2.fromOffset(14, 176),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1, 1, 1),
    }, pop)
    Corner(hue, 7)
    New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
    }, hue)
    local hueCur = New("Frame", {
        Size = UDim2.fromOffset(18, 18),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
    }, hue)
    Corner(hueCur, 9)
    Stroke(hueCur, Color3.new(1, 1, 1), 2.5, 0)
    local hueHit = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 12),
        Position = UDim2.fromOffset(0, -6),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, hue)

    -- ช่อง HEX
    local box = New("TextBox", {
        Size = UDim2.fromOffset(PW - 28, 30),
        Position = UDim2.fromOffset(14, 202),
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "#RRGGBB",
        ClearTextOnFocus = false,
        TextSize = 12,
        Font = FNT.M,
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.Muted,
    }, pop)
    Corner(box, 9)
    Stroke(box, Theme.Stroke, 1, 0.3)

    local function render(fromBox)
        local c = Color3.fromHSV(H, S, V)
        sv.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
        svCur.Position = UDim2.fromScale(S, 1 - V)
        hueCur.Position = UDim2.fromScale(H, 0.5)
        hueCur.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
        prev.BackgroundColor3 = c
        if not fromBox then
            box.Text = "#" .. string.upper(c:ToHex())
        end
        return c
    end
    local function commit(fromBox)
        onPick(render(fromBox))
    end
    render(false)

    -- ลาก (รองรับเมาส์/ทัช, ชดเชย GuiInset อัตโนมัติ)
    local function bindDrag(hit, onMove)
        local dragging, dInput = false, nil
        local off = Vector2.zero
        hit.InputBegan:Connect(function(input)
            if not IsPointer(input) then
                return
            end
            local p = Vector2.new(input.Position.X, input.Position.Y)
            local a, sz = hit.AbsolutePosition, hit.AbsoluteSize
            local inset = GuiService:GetGuiInset()
            local q = p + inset
            local inside = q.X >= a.X and q.X <= a.X + sz.X and q.Y >= a.Y and q.Y <= a.Y + sz.Y
            off = inside and inset or Vector2.zero
            dragging = true
            dInput = input
            onMove(p + off)
        end)
        PaletteConns[#PaletteConns + 1] = UIS.InputChanged:Connect(function(input)
            if dragging and IsMove(input) then
                if input.UserInputType == Enum.UserInputType.Touch and input ~= dInput then
                    return
                end
                onMove(Vector2.new(input.Position.X, input.Position.Y) + off)
            end
        end)
        PaletteConns[#PaletteConns + 1] = UIS.InputEnded:Connect(function(input)
            if dragging and IsPointer(input) then
                if input.UserInputType == Enum.UserInputType.Touch and input ~= dInput then
                    return
                end
                dragging = false
            end
        end)
    end

    bindDrag(svHit, function(pos)
        S = math.clamp((pos.X - sv.AbsolutePosition.X) / math.max(1, sv.AbsoluteSize.X), 0, 1)
        V = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / math.max(1, sv.AbsoluteSize.Y), 0, 1)
        commit(false)
    end)
    bindDrag(hueHit, function(pos)
        H = math.clamp((pos.X - hue.AbsolutePosition.X) / math.max(1, hue.AbsoluteSize.X), 0, 1)
        commit(false)
    end)

    box.FocusLost:Connect(function()
        local h = string.match(box.Text, "^%s*#?(%x%x%x%x%x%x)%s*$")
        if h then
            H, S, V = Color3.fromHex(h):ToHSV()
            commit(false)
        else
            box.TextColor3 = RGB(235, 75, 90)
            task.delay(0.8, function()
                if box.Parent then
                    box.TextColor3 = Theme.Text
                    render(false)
                end
            end)
        end
    end)

    -- สีสำเร็จรูป
    for i, hexv in ipairs(PaletteColors) do
        local c = Color3.fromHex(hexv)
        local sw = New("TextButton", {
            Size = UDim2.fromOffset(22, 22),
            Position = UDim2.fromOffset(14 + ((i - 1) % 8) * 27, 244 + math.floor((i - 1) / 8) * 28),
            BackgroundColor3 = c,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
        }, pop)
        Corner(sw, 11)
        Stroke(sw, Color3.new(1, 1, 1), 1, 0.8)
        sw.MouseButton1Click:Connect(function()
            H, S, V = c:ToHSV()
            commit(false)
        end)
    end
end

local ColorRefreshers = {}

local function ColorRow(page, title, key)
    local row = Panel(page, UDim2.new(1, 0, 0, 50), "TextButton")
    HoverRow(row)
    Register(row, title)

    local t = Text(row, title, 12, FNT.M, "Text")
    t.Position = UDim2.fromOffset(18, 0)
    t.Size = UDim2.new(1, -176, 1, 0)

    local hexLabel = Text(row, "", 10, FNT.M, "Muted", Enum.TextXAlignment.Right)
    hexLabel.Position = UDim2.new(1, -152, 0, 0)
    hexLabel.Size = UDim2.fromOffset(84, 50)

    local swatch = New("Frame", {
        Size = UDim2.fromOffset(44, 24),
        Position = UDim2.new(1, -60, 0.5, -12),
        BorderSizePixel = 0,
    }, row)
    Corner(swatch, 8)
    Stroke(swatch, Color3.new(1, 1, 1), 1, 0.7)

    local function refresh()
        swatch.BackgroundColor3 = Hex(key, RGB(100, 100, 100))
        hexLabel.Text = string.upper(tostring(Config[key]))
    end
    refresh()
    Refreshers[#Refreshers + 1] = refresh
    ColorRefreshers[#ColorRefreshers + 1] = refresh

    row.MouseButton1Click:Connect(function()
        OpenPalette(title, key, function(c)
            SetConfig(key, "#" .. string.upper(c:ToHex()))
            refresh()
            QueueTheme()
        end)
    end)
end

-- ธีมสำเร็จรูป: แตะครั้งเดียวเปลี่ยนทั้ง UI + ปุ่ม RX (เซฟอัตโนมัติ)
local ThemePresets = {
    { "Graphite", "#C9CBD3", "#0A0A0C", "#232328" },
    { "Violet", "#8B5CF6", "#09090D", "#1C1C26" },
    { "Crimson", "#F43F5E", "#0B0708", "#26151A" },
    { "Cyber", "#22D3EE", "#06090C", "#122029" },
    { "Toxic", "#4ADE80", "#060A07", "#13211A" },
    { "Sunset", "#FB923C", "#0C0805", "#271A10" },
}

local function ThemeGrid(page)
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = Next(page),
    }, page)
    New("UIGridLayout", {
        CellSize = UDim2.new(1 / 3, -7, 0, 56),
        CellPadding = UDim2.fromOffset(10, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, holder)
    Register(holder, "ธีม theme preset สำเร็จรูป")

    for _, p in ipairs(ThemePresets) do
        local card = Panel(holder, nil, "TextButton")
        HoverRow(card)

        local function dot(hex, x)
            local d = New("Frame", {
                Size = UDim2.fromOffset(22, 22),
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, x, 0.5, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromHex(hex),
            }, card)
            Corner(d, 11)
            Stroke(d, Color3.new(1, 1, 1), 1, 0.8)
        end
        dot(p[3], 12)
        dot(p[4], 24)
        dot(p[2], 36)

        local n = Text(card, p[1], 12, FNT.M, "Text")
        n.Position = UDim2.fromOffset(68, 0)
        n.Size = UDim2.new(1, -74, 1, 0)

        card.MouseButton1Click:Connect(function()
            SetConfig("UIAccentColor", p[2])
            SetConfig("UIBackgroundColor", p[3])
            SetConfig("UIButtonColor", p[4])
            SetConfig("FloatingButtonColor", p[3])
            SetConfig("FloatingBorderColor", p[2])
            SetConfig("FloatingGlowColor", p[2])
            for _, fn in ipairs(ColorRefreshers) do
                pcall(fn)
            end
            QueueTheme()
            Toast("ใช้ธีม " .. p[1])
        end)
    end
end

--==================================================
-- HOME
--==================================================

local Home = MakePage("Home", "หน้าหลัก", "ภาพรวมและข้อมูลเซิร์ฟเวอร์")

-- การ์ดต้อนรับ
local Hero = Panel(Home, UDim2.new(1, 0, 0, 84))
Tint(Hero)
local HeroSub = Text(Hero, "", 11, FNT.M, "Muted")
HeroSub.Position = UDim2.fromOffset(20, 14)
HeroSub.Size = UDim2.new(0.6, 0, 0, 16)
local HeroName = Text(Hero, LocalPlayer.DisplayName, 24, FNT.B, Color3.new(1, 1, 1))
HeroName.Position = UDim2.fromOffset(20, 32)
HeroName.Size = UDim2.new(0.6, 0, 0, 38)
AccentGrad(HeroName, 0)
local HeroClock = Text(Hero, "", 26, FNT.B, "Text", Enum.TextXAlignment.Right)
HeroClock.Position = UDim2.new(0.5, 0, 0, 16)
HeroClock.Size = UDim2.new(0.5, -20, 0, 34)
local HeroDate = Text(Hero, "", 10, FNT.M, "Muted", Enum.TextXAlignment.Right)
HeroDate.Position = UDim2.new(0.5, 0, 0, 52)
HeroDate.Size = UDim2.new(0.5, -20, 0, 16)

-- การ์ดแมพ (รูปไอคอนแมพจริงจาก Roblox)
local MapImage = "rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=150&h=150"

local MapCard = Panel(Home, UDim2.new(1, 0, 0, 116))
MapCard.ClipsDescendants = true

local MapBG = New("ImageLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Image = MapImage,
    ScaleType = Enum.ScaleType.Crop,
    ImageTransparency = 0.86,
}, MapCard)
Corner(MapBG, 12)

local MapFade = New("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0 }, MapCard)
Bind(MapFade, "BackgroundColor3", "Surface")
New("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 0.7),
    }),
}, MapFade)
Corner(MapFade, 12)
Tint(MapCard)

local MapIcon = New("ImageLabel", {
    Size = UDim2.fromOffset(84, 84),
    Position = UDim2.fromOffset(16, 16),
    BorderSizePixel = 0,
    Image = MapImage,
    ScaleType = Enum.ScaleType.Crop,
}, MapCard)
Corner(MapIcon, 16)
Bind(MapIcon, "BackgroundColor3", "Button")
Bind(Stroke(MapIcon, Theme.Stroke, 1.5, 0.1), "Color", "Stroke")

local MapName = Text(MapCard, tostring(game.Name or "Unknown"), 17, FNT.B, "Text")
MapName.Position = UDim2.fromOffset(112, 16)
MapName.Size = UDim2.new(1, -128, 0, 26)

local MapBy = Text(MapCard, "กำลังโหลดข้อมูลแมพ...", 11, FNT.R, "Muted")
MapBy.Position = UDim2.fromOffset(112, 43)
MapBy.Size = UDim2.new(1, -128, 0, 16)

local Chips = New("Frame", {
    Size = UDim2.new(1, -128, 0, 24),
    Position = UDim2.fromOffset(112, 72),
    BackgroundTransparency = 1,
}, MapCard)
New("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Chips)

local function Chip(text)
    local c = New("TextLabel", {
        Size = UDim2.fromOffset(0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        BorderSizePixel = 0,
        Text = text,
        TextSize = 10,
        Font = FNT.M,
        LayoutOrder = Next(Chips),
    }, Chips)
    Bind(c, "BackgroundColor3", "Surface2")
    Bind(c, "TextColor3", "Sub")
    Corner(c, 12)
    Pad(c, 10, 10, 0, 0)
    return c
end

local ChipPlace = Chip("ID " .. tostring(game.PlaceId))
local ChipPlayers = Chip("ผู้เล่น -/-")

task.spawn(function()
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        if info then
            if info.Name and info.Name ~= "" then
                MapName.Text = tostring(info.Name)
                BrandSub.Text = tostring(info.Name)
            end
            if info.Creator and info.Creator.Name then
                MapBy.Text = "โดย " .. tostring(info.Creator.Name)
            else
                MapBy.Text = ""
            end
        end
    end)
end)

local function Stat(parent, label, size)
    local c = Panel(parent, size)
    local bar = New("Frame", {
        Size = UDim2.fromOffset(3, 18),
        Position = UDim2.fromOffset(0, 12),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1, 1, 1),
    }, c)
    Corner(bar, 2)
    AccentGrad(bar, 90)
    local l = Text(c, label, 10, FNT.M, "Muted")
    l.Position = UDim2.fromOffset(16, 11)
    l.Size = UDim2.new(1, -30, 0, 14)
    local v = Text(c, "-", 14, FNT.B, "Text")
    v.Position = UDim2.fromOffset(16, 30)
    v.Size = UDim2.new(1, -30, 0, 22)
    return v
end

local Grid = New("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    LayoutOrder = Next(Home),
}, Home)
New("UIGridLayout", {
    CellSize = UDim2.new(0.5, -5, 0, 64),
    CellPadding = UDim2.fromOffset(10, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Grid)

local StatPlayer = Stat(Grid, "ผู้เล่น")
local StatTime = Stat(Grid, "เวลาในเซิร์ฟ")
local StatFps = Stat(Grid, "FPS")
local StatPing = Stat(Grid, "Ping")

-- กราฟ FPS ย้อนหลัง
local PerfCard = Panel(Home, UDim2.new(1, 0, 0, 120))
Tint(PerfCard)
local PerfTitle = Text(PerfCard, "ประสิทธิภาพ (FPS)", 12, FNT.B, "Text")
PerfTitle.Position = UDim2.fromOffset(18, 12)
PerfTitle.Size = UDim2.new(0.5, 0, 0, 18)
local PerfAvg = Text(PerfCard, "", 11, FNT.M, "Sub", Enum.TextXAlignment.Right)
PerfAvg.Position = UDim2.new(0.5, 0, 0, 12)
PerfAvg.Size = UDim2.new(0.5, -18, 0, 18)
local PerfBars = New("Frame", {
    Size = UDim2.new(1, -36, 0, 68),
    Position = UDim2.fromOffset(18, 40),
    BackgroundTransparency = 1,
}, PerfCard)

local PERF_N = 36
local PerfBar, PerfHist = {}, {}
for i = 1, PERF_N do
    local b = New("Frame", {
        Size = UDim2.new(1 / PERF_N, -2, 0, 2),
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new((i - 1) / PERF_N, 1, 1, 0),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
    }, PerfBars)
    Corner(b, 2)
    PerfBar[i] = b
    PerfHist[i] = 0
end

local function PerfUpdate()
    table.remove(PerfHist, 1)
    PerfHist[#PerfHist + 1] = Metrics.fps
    local peak, sum, cnt = 60, 0, 0
    for _, v in ipairs(PerfHist) do
        if v > peak then
            peak = v
        end
        if v > 0 then
            sum = sum + v
            cnt = cnt + 1
        end
    end
    for i, v in ipairs(PerfHist) do
        local b = PerfBar[i]
        b.Size = UDim2.new(1 / PERF_N, -2, math.clamp(v / peak, 0.04, 1), 0)
        b.BackgroundColor3 = Level(v, 50, 30, true)
        b.BackgroundTransparency = v == 0 and 1 or 0.08
    end
    PerfAvg.Text = "เฉลี่ย " .. tostring(cnt > 0 and math.floor(sum / cnt + 0.5) or 0) .. " FPS"
end

local sessionStart = os.time()

local function RefreshHome()
    local hr = tonumber(os.date("%H")) or 12
    HeroSub.Text = (hr >= 5 and hr < 12 and "อรุณสวัสดิ์")
        or (hr >= 12 and hr < 17 and "สวัสดีตอนบ่าย")
        or (hr >= 17 and hr < 21 and "สวัสดีตอนเย็น")
        or "ราตรีสวัสดิ์"
    HeroClock.Text = os.date("%H:%M")
    HeroDate.Text = os.date("%d / %m / %Y")
    local sec = math.max(0, os.time() - sessionStart)
    StatPlayer.Text = LocalPlayer.DisplayName
    StatTime.Text = string.format("%02d:%02d:%02d", math.floor(sec / 3600), math.floor((sec % 3600) / 60), sec % 60)
    StatFps.Text = tostring(Metrics.fps)
    StatFps.TextColor3 = Level(Metrics.fps, 50, 30, true)
    StatPing.Text = tostring(Metrics.ping) .. " ms"
    StatPing.TextColor3 = Level(Metrics.ping, 80, 160, false)
    ChipPlayers.Text = string.format("ผู้เล่น %d/%d", #Players:GetPlayers(), Players.MaxPlayers)
    PerfUpdate()
end

task.spawn(function()
    while Screen.Parent do
        RefreshStats()
        RefreshHome()
        task.wait(0.5)
    end
end)

--==================================================
-- FUNCTIONS
--==================================================

--==================================================
-- TD AUTO  (Challenge / Event / Farm / Shop)
-- ทั้งหมดอยู่ในฟังก์ชันเดียว เพื่อไม่ให้ชนลิมิต local ของ UI
--==================================================

;(function()
    local RS = game:GetService("ReplicatedStorage")
    local TeleportService = game:GetService("TeleportService")

    local LOBBY_PLACE_ID = 117949143041402
    local MATCH_TP_ID = 97246719761307 -- ค่าที่ client ของเกมส่งเข้า TeleportRequest
    local IN_LOBBY = (game.PlaceId == LOBBY_PLACE_ID)
    local Remotes = RS:WaitForChild("Remotes")
    local GameEvents = RS:WaitForChild("GameEvents")

    local MODE_KEYS = { Story = "Story", Mysterious = "Mysterios", Raid = "Raids" }
    local DIFFS = { "Normal", "Hard", "Nightmare" }
    local ORDERS = {
        "Challenge > Event > Farm",
        "Challenge > Farm > Event",
        "Event > Challenge > Farm",
        "Farm > Challenge > Event",
        "Event > Farm > Challenge",
        "Farm > Event > Challenge",
    }
    local SHOP_IDS = {
        "Fruit_1", "Fruit_2", "RareShard", "EpicShard", "LegendShard", "MythicShard",
        "MysteriousShard", "Trait", "StatRerollAll", "StatReroll", "MysteryCapsule",
    }

    local function alive()
        return Screen.Parent ~= nil
    end

    local function fmt(n)
        local s = tostring(math.floor(tonumber(n) or 0))
        while true do
            local r, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
            s = r
            if k == 0 then
                break
            end
        end
        return s
    end

    ------------------------------------------------------------------
    -- Shop config (ดึงจากเกม ถ้าไม่ได้ใช้ค่าสำรองจากดัมพ์)
    ------------------------------------------------------------------
    local ShopCfg
    do
        local ok, cfg = pcall(function()
            return require(RS.Modules.ShopModule.ShopConfig)
        end)
        if ok and type(cfg) == "table" and cfg.GoldShopItems and cfg.GemsShopItems then
            ShopCfg = cfg
        else
            ShopCfg = {
                RestockDuration = 3600,
                GoldShopItems = {
                    { ID = "Fruit_1", Price = 150, MaxStock = 10 },
                    { ID = "Fruit_2", Price = 350, MaxStock = 5 },
                    { ID = "RareShard", Price = 500, MaxStock = 10 },
                    { ID = "EpicShard", Price = 1000, MaxStock = 7 },
                    { ID = "LegendShard", Price = 2500, MaxStock = 5 },
                    { ID = "MythicShard", Price = 5000, MaxStock = 3 },
                    { ID = "MysteriousShard", Price = 65000, MaxStock = 1 },
                    { ID = "Trait", Price = 3000, MaxStock = 10 },
                    { ID = "StatRerollAll", Price = 500, MaxStock = 10 },
                    { ID = "StatReroll", Price = 1200, MaxStock = 10 },
                    { ID = "MysteryCapsule", Price = 3000, MaxStock = 50 },
                },
                GemsShopItems = {
                    { ID = "Fruit_1", Price = 10, MaxStock = 10 },
                    { ID = "Fruit_2", Price = 25, MaxStock = 5 },
                    { ID = "RareShard", Price = 35, MaxStock = 10 },
                    { ID = "EpicShard", Price = 75, MaxStock = 7 },
                    { ID = "LegendShard", Price = 180, MaxStock = 5 },
                    { ID = "MythicShard", Price = 350, MaxStock = 3 },
                    { ID = "MysteriousShard", Price = 10000, MaxStock = 1 },
                    { ID = "Trait", Price = 200, MaxStock = 10 },
                    { ID = "StatRerollAll", Price = 35, MaxStock = 10 },
                    { ID = "StatReroll", Price = 80, MaxStock = 10 },
                    { ID = "MysteryCapsule", Price = 750, MaxStock = 50 },
                },
            }
        end
    end

    local function shopItem(cur, id)
        local list = (cur == "Coins") and ShopCfg.GoldShopItems or ShopCfg.GemsShopItems
        for _, it in ipairs(list) do
            if it.ID == id then
                return it
            end
        end
        return nil
    end

    local function shopKey(cur, id)
        return (cur == "Coins" and "ShopC_" or "ShopG_") .. id
    end

    local function shopWanted()
        if not Config.AutoShop then
            return false
        end
        for _, id in ipairs(SHOP_IDS) do
            if Config[shopKey("Coins", id)] == true or Config[shopKey("Gems", id)] == true then
                return true
            end
        end
        return false
    end

    -- รอบรีสต็อกของร้าน = เวลาจริงตัดทุก xx:00 (เกมใช้ os.time() / 3600 เหมือนกัน)
    local function currentCycle()
        return math.floor(os.time() / ShopCfg.RestockDuration)
    end

    ------------------------------------------------------------------
    -- Maps / Act
    ------------------------------------------------------------------
    local FALLBACK_MAPS = {
        Story = {
            { key = "GreenForest", name = "Namek World", stages = 5, mode = "Story" },
            { key = "KirigakureVillage", name = "Kirigakure Village", stages = 5, mode = "Story" },
            { key = "CursedMall", name = "Cursed Mall", stages = 5, mode = "Story" },
            { key = "ValhallaArena", name = "Valhalla Arena", stages = 5, mode = "Story" },
            { key = "FateStory", name = "Fate Story", stages = 5, mode = "Story" },
        },
        Mysterious = {
            { key = "GreenForestMyterious", name = "Namek World", stages = 3, mode = "Mysterios" },
            { key = "KirigakureVillageMyterious", name = "Kirigakure Village", stages = 3, mode = "Mysterios" },
            { key = "CursedMallMyterious", name = "Cursed Mall", stages = 3, mode = "Mysterios" },
            { key = "ValhallaArenaMyterious", name = "Valhalla Arena", stages = 3, mode = "Mysterios" },
            { key = "FateStoryMysterious", name = "Fate Story Mysterious", stages = 3, mode = "Mysterios" },
        },
        Raid = {
            { key = "CursedAcademy", name = "Tokyo Jujutsu High", stages = 3, mode = "Raids" },
            { key = "AlabastaArc", name = "Alabasta Arc", stages = 3, mode = "Raids" },
            { key = "ScepterTower", name = "Scepter Tower", stages = 3, mode = "Raids" },
        },
    }

    local function getMapConfig()
        local ok, cfg = pcall(function()
            return require(RS.Modules.PlayingModule.MapConfig)
        end)
        if ok and type(cfg) == "table" then
            return cfg
        end
        return nil
    end

    local function mapList(modeName)
        local want = MODE_KEYS[modeName]
        local list = {}
        local cfg = getMapConfig()
        if cfg then
            for k, v in pairs(cfg) do
                if type(k) == "number" and k < 90 and type(v) == "table" and v.Mode == want and v.Locked ~= true then
                    table.insert(list, {
                        order = k,
                        key = v.MapToCreate,
                        name = v.Name,
                        stages = v.TotalStages or 1,
                        mode = v.Mode,
                    })
                end
            end
            table.sort(list, function(a, b)
                return a.order < b.order
            end)
        end
        if #list == 0 then
            for i, m in ipairs(FALLBACK_MAPS[modeName] or {}) do
                list[i] = m
            end
        end
        return list
    end

    local function findMap(modeName, key)
        for _, m in ipairs(mapList(modeName)) do
            if m.key == key then
                return m
            end
        end
        return nil
    end

    local function eventEntry()
        local cfg = getMapConfig()
        if cfg then
            for k, v in pairs(cfg) do
                if type(k) == "number" and k < 90 and type(v) == "table" and v.Mode == "Event" and v.Locked ~= true then
                    return { key = v.MapToCreate, name = v.Name, stages = v.TotalStages or 1, mode = v.Mode }
                end
            end
        end
        return { key = "FateEvent", name = "Fate (Event)", stages = 1, mode = "Event" }
    end

    local function stageRewards(mapKey, stage)
        local ok, r = pcall(function()
            local folder = RS.Modules.PlayingModule.MapConfig.MapStageReward
            local m = require(folder:FindFirstChild(mapKey))
            return m[stage] and m[stage].Rewards
        end)
        if ok and r then
            return r
        end
        return {}
    end

    local function normalizeFarm()
        local list = mapList(Config.FarmMode)
        if not list[1] then
            return
        end
        local found = findMap(Config.FarmMode, Config.FarmMap)
        if not found then
            found = list[1]
            SetConfig("FarmMap", found.key)
        end
        if Config.FarmAct < 1 or Config.FarmAct > found.stages then
            SetConfig("FarmAct", 1)
        end
    end

    ------------------------------------------------------------------
    -- Challenge state (เก็บเวลา "พร้อมอีกครั้ง" ของแต่ละแท็บลง Config)
    ------------------------------------------------------------------
    local function loadNext()
        local ok, t = pcall(function()
            return HttpService:JSONDecode(Config.StateChallengeNext)
        end)
        if ok and type(t) == "table" then
            return t
        end
        return {}
    end

    local function saveNext(t)
        SetConfig("StateChallengeNext", HttpService:JSONEncode(t))
    end

    local function challengeDue()
        local t = loadNext()
        local now = os.time()
        for tab, ts in pairs(t) do
            if (Config.ChallengeTab == "All" or Config.ChallengeTab == tab) and type(ts) == "number" and now >= ts then
                return true, tab
            end
        end
        return false
    end

    local function parseOrder()
        local r = {}
        for w in string.gmatch(Config.PriorityOrder, "%a+") do
            table.insert(r, w)
        end
        return r
    end

    local function prioIndex(name)
        for i, w in ipairs(parseOrder()) do
            if w == name then
                return i
            end
        end
        return 99
    end

    ------------------------------------------------------------------
    -- COMPONENTS: Choice / Action / Info  (สไตล์เดียวกับ Toggle / Slider)
    ------------------------------------------------------------------
    local function Choice(page, opts)
        local pillW = opts.pillWidth or 132
        local row = Panel(page, UDim2.new(1, 0, 0, 64), "TextButton")
        HoverRow(row)
        Register(row, opts.title .. " " .. (opts.desc or ""))

        local title = Text(row, opts.title, 13, FNT.M, "Text")
        title.Position = UDim2.fromOffset(18, 11)
        title.Size = UDim2.new(1, -(pillW + 40), 0, 20)

        local desc = Text(row, opts.desc or "", 11, FNT.R, "Muted")
        desc.Position = UDim2.fromOffset(18, 33)
        desc.Size = UDim2.new(1, -(pillW + 40), 0, 18)

        local pill = New("Frame", {
            Size = UDim2.fromOffset(pillW, 28),
            Position = UDim2.new(1, -(pillW + 16), 0.5, -14),
            BorderSizePixel = 0,
        }, row)
        Corner(pill, 14)
        Bind(pill, "BackgroundColor3", "Surface2")
        Bind(Stroke(pill, Theme.Accent, 1, 0.6), "Color", "Accent")

        local val = Text(row, "", 11, FNT.B, "Accent", Enum.TextXAlignment.Center)
        val.Position = UDim2.new(1, -(pillW + 16), 0.5, -14)
        val.Size = UDim2.fromOffset(pillW, 28)

        local function show()
            local v = Config[opts.key]
            val.Text = opts.label and opts.label(v) or tostring(v)
        end

        row.MouseButton1Click:Connect(function()
            local o = opts.options
            if type(o) == "function" then
                o = o()
            end
            if not o or #o == 0 then
                return
            end
            local idx = table.find(o, Config[opts.key]) or 0
            local v = o[(idx % #o) + 1]
            SetConfig(opts.key, v)
            show()
            PlayToggleSound(true)
            if opts.callback then
                task.spawn(opts.callback, v)
            end
        end)

        Refreshers[#Refreshers + 1] = show
        show()
        return { Refresh = show }
    end

    local function Action(page, opts)
        local row = Panel(page, UDim2.new(1, 0, 0, 56), "TextButton")
        HoverRow(row)
        Register(row, opts.title .. " " .. (opts.desc or ""))

        local title = Text(row, opts.title, 13, FNT.M, "Text")
        title.Position = UDim2.fromOffset(18, 9)
        title.Size = UDim2.new(1, -120, 0, 20)

        local desc = Text(row, opts.desc or "", 11, FNT.R, "Muted")
        desc.Position = UDim2.fromOffset(18, 30)
        desc.Size = UDim2.new(1, -120, 0, 16)

        local pill = New("Frame", {
            Size = UDim2.fromOffset(72, 28),
            Position = UDim2.new(1, -88, 0.5, -14),
            BorderSizePixel = 0,
        }, row)
        Corner(pill, 14)
        Bind(pill, "BackgroundColor3", "Accent")

        local lbl = Text(row, opts.button or "เริ่ม", 12, FNT.B, "OnAccent", Enum.TextXAlignment.Center)
        lbl.Position = UDim2.new(1, -88, 0.5, -14)
        lbl.Size = UDim2.fromOffset(72, 28)

        row.MouseButton1Click:Connect(function()
            PlayToggleSound(true)
            task.spawn(opts.callback)
        end)
    end

    local function TextInput(page, opts)
        local pillW = opts.pillWidth or 210
        local row = Panel(page, UDim2.new(1, 0, 0, 64))
        Register(row, opts.title .. " " .. (opts.desc or ""))

        local title = Text(row, opts.title, 13, FNT.M, "Text")
        title.Position = UDim2.fromOffset(18, 11)
        title.Size = UDim2.new(1, -(pillW + 40), 0, 20)

        local desc = Text(row, opts.desc or "", 11, FNT.R, "Muted")
        desc.Position = UDim2.fromOffset(18, 33)
        desc.Size = UDim2.new(1, -(pillW + 40), 0, 18)

        local pill = New("Frame", {
            Size = UDim2.fromOffset(pillW, 28),
            Position = UDim2.new(1, -(pillW + 16), 0.5, -14),
            BorderSizePixel = 0,
        }, row)
        Corner(pill, 14)
        Bind(pill, "BackgroundColor3", "Surface2")
        Bind(Stroke(pill, Theme.Accent, 1, 0.6), "Color", "Accent")

        local box = New("TextBox", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(pillW - 16, 28),
            Position = UDim2.new(1, -(pillW + 8), 0.5, -14),
            Text = tostring(Config[opts.key] or ""),
            PlaceholderText = opts.placeholder or "",
            ClearTextOnFocus = false,
            TextSize = 11,
            Font = FNT.B,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, row)
        Bind(box, "TextColor3", "Accent")
        Bind(box, "PlaceholderColor3", "Muted")

        box.FocusLost:Connect(function()
            local v = tostring(box.Text or ""):match("^%s*(.-)%s*$")
            box.Text = v
            SetConfig(opts.key, v)
            if opts.callback then
                task.spawn(opts.callback, v)
            end
        end)
        Refreshers[#Refreshers + 1] = function()
            box.Text = tostring(Config[opts.key] or "")
        end
    end

    -- รายชื่อผู้เล่นในเซิฟ (ชื่อที่เลือกไว้จะคงอยู่แม้อีกฝ่ายยังไม่อยู่ในเซิฟ)
    local function partyOptions()
        local o = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(o, p.Name)
            end
        end
        table.sort(o)
        local saved = Config.PartyTarget
        if saved ~= "" and not table.find(o, saved) then
            table.insert(o, 1, saved)
        end
        return o
    end

    local function Info(page, height)
        local row = Panel(page, UDim2.new(1, 0, 0, height or 110))
        Tint(row)
        local l1 = Text(row, "", 13, FNT.B, "Text")
        l1.Position = UDim2.fromOffset(18, 12)
        l1.Size = UDim2.new(1, -36, 0, 22)
        local l2 = Text(row, "", 11, FNT.M, "Accent")
        l2.Position = UDim2.fromOffset(18, 38)
        l2.Size = UDim2.new(1, -36, 0, 34)
        l2.TextWrapped = true
        l2.TextTruncate = Enum.TextTruncate.None
        l2.TextYAlignment = Enum.TextYAlignment.Top
        local l3 = Text(row, "", 11, FNT.R, "Muted")
        l3.Position = UDim2.fromOffset(18, 78)
        l3.Size = UDim2.new(1, -36, 0, 18)
        return {
            Set = function(a, b, c)
                l1.Text = a or ""
                l2.Text = b or ""
                l3.Text = c or ""
            end,
        }
    end

    ------------------------------------------------------------------
    -- PAGES
    ------------------------------------------------------------------
    local StatusBox, MapChoice, ActChoice, PartyChoice
    local doChallengeNow, doShopNow

    local function challengeTabs()
        local o = { "All" }
        local names = { "Daily", "Weekly" }
        if IN_LOBBY then
            pcall(function()
                local d = Remotes.GetChallengeData:InvokeServer()
                local n = {}
                for k, v in pairs(d) do
                    if type(v) == "table" and v.MapToCreate then
                        table.insert(n, k)
                    end
                end
                table.sort(n)
                if #n > 0 then
                    names = n
                end
            end)
        end
        for _, n in ipairs(names) do
            table.insert(o, n)
        end
        return o
    end

    local function onModeChanged()
        local list = mapList(Config.FarmMode)
        if list[1] then
            SetConfig("FarmMap", list[1].key)
        end
        SetConfig("FarmAct", 1)
        if MapChoice then
            MapChoice.Refresh()
        end
        if ActChoice then
            ActChoice.Refresh()
        end
    end

    local function onMapChanged()
        SetConfig("FarmAct", 1)
        if ActChoice then
            ActChoice.Refresh()
        end
    end

    local Functions = MakePage("Functions", "ฟังก์ชัน", "Challenge / ฟาร์ม / ซื้อของ  •  เซฟอัตโนมัติ")
    StatusBox = Info(Functions, 110)

    Section(Functions, "ระบบหลัก")
    Toggle(Functions, {
        key = "AutoChallenge",
        title = "Auto Challenge",
        desc = "ลง Daily / Weekly Challenge เมื่อพร้อม",
    })
    Choice(Functions, {
        key = "ChallengeTab",
        title = "Challenge ที่ลง",
        desc = "กดเพื่อสลับ",
        options = challengeTabs,
        label = function(v)
            return v == "All" and "ทั้งหมด" or tostring(v)
        end,
    })
    Choice(Functions, {
        key = "PriorityOrder",
        title = "ลำดับความสำคัญ",
        desc = "ซ้ายสุดทำก่อน (กดสลับ)",
        pillWidth = 190,
        options = ORDERS,
        label = function(v)
            local s = tostring(v)
            s = s:gsub("Challenge", "ชาเล้น")
            s = s:gsub("Event", "อีเวนต์")
            s = s:gsub("Farm", "ฟาร์ม")
            return s
        end,
    })
    Toggle(Functions, {
        key = "AutoLeaveChallenge",
        title = "กลับ Lobby หลังจบ Challenge",
        desc = "ฟาร์มด่านอื่นไม่ออกเองจนกว่า Challenge จะมา",
    })
    Toggle(Functions, {
        key = "MatchAuto",
        title = "เปิด Auto ในแมตช์",
        desc = "Vote Start / Autoplay / Skip Wave / Speed / Ultimate",
    })
    Slider(Functions, {
        key = "LeaveDelay",
        title = "หน่วงก่อนออกจากแมตช์",
        desc = "รอหลังจบ Challenge ก่อนกลับ Lobby",
        min = 0,
        max = 15,
        step = 1,
        suffix = " วิ",
    })

    Section(Functions, "ปาร์ตี้ Host / Guest (ปิด = เล่นคนเดียวตามปกติ)")
    Toggle(Functions, {
        key = "PartyEnabled",
        title = "ระบบ Host / Guest",
        desc = "เปิดเพื่อเล่นกับเพื่อน  •  ปิด = Auto ต่างๆ เล่นคนเดียว",
    })
    Choice(Functions, {
        key = "PartyRole",
        title = "บทบาทของเครื่องนี้",
        desc = "Host = สร้างห้อง+เชิญ  /  Guest = ตามเข้าห้อง Host",
        options = { "Host", "Guest" },
    })
    PartyChoice = Choice(Functions, {
        key = "PartyTarget",
        title = "เพื่อนในปาร์ตี้",
        desc = "กดสลับชื่อผู้เล่นในเซิฟ (จำชื่อที่เลือกไว้)",
        pillWidth = 190,
        options = partyOptions,
        label = function(v)
            return (v == nil or v == "") and "- กดเลือกชื่อ -" or tostring(v)
        end,
    })
    Action(Functions, {
        title = "รีเฟรชรายชื่อผู้เล่น",
        desc = "โหลดรายชื่อคนในเซิฟใหม่",
        button = "รีเฟรช",
        callback = function()
            PartyChoice.Refresh()
            Toast("ในเซิฟมีผู้เล่นอื่น " .. tostring(#partyOptions()) .. " คน")
        end,
    })
    Slider(Functions, {
        key = "PartyHostWait",
        title = "Host รอเพื่อนเข้าห้อง",
        desc = "ถ้าเพื่อนไม่เข้าภายในเวลานี้ จะออกจากห้องแล้วลองใหม่",
        min = 15,
        max = 180,
        step = 5,
        suffix = " วิ",
    })
    Toggle(Functions, {
        key = "AutoJoinJob",
        title = "Auto Join Job ID",
        desc = "วาปไปเซิฟ Lobby ตาม Job ID (ข้ามถ้าอยู่เซิฟเดียวกับเพื่อนแล้ว)",
    })
    TextInput(Functions, {
        key = "JobIdValue",
        title = "Job ID",
        desc = "วาง Job ID ของเซิฟ Lobby ที่จะเข้า",
        placeholder = "วาง Job ID ที่นี่",
        pillWidth = 230,
    })

    Section(Functions, "ทำทันที (ใน Lobby)")
    Action(Functions, {
        title = "ลง Challenge ตอนนี้",
        desc = "ข้ามเวลารอ แล้วลองลงทันที",
        button = "ลง",
        callback = function()
            doChallengeNow()
        end,
    })
    Action(Functions, {
        title = "ซื้อของร้านค้าตอนนี้",
        desc = "ซื้อตามรายการที่ติ๊กไว้",
        button = "ซื้อ",
        callback = function()
            doShopNow()
        end,
    })

    local Farm = MakePage("Farm", "ฟาร์ม", "เลือกด่านที่จะลง  •  Challenge มาก่อนตามลำดับที่ตั้ง")
    Section(Farm, "ฟาร์มด่าน")
    Toggle(Farm, {
        key = "AutoFarm",
        title = "Auto ฟาร์มด่าน",
        desc = "Story / Mysterious / Raid ตามที่เลือกด้านล่าง",
    })
    Choice(Farm, {
        key = "FarmMode",
        title = "โหมด",
        desc = "Story / Mysterious / Raid",
        options = { "Story", "Mysterious", "Raid" },
        callback = onModeChanged,
    })
    MapChoice = Choice(Farm, {
        key = "FarmMap",
        title = "แมพ",
        desc = "เลือกแมพของโหมดนี้",
        pillWidth = 160,
        options = function()
            local o = {}
            for _, m in ipairs(mapList(Config.FarmMode)) do
                table.insert(o, m.key)
            end
            return o
        end,
        label = function(v)
            local m = findMap(Config.FarmMode, v)
            return m and m.name or "-"
        end,
        callback = onMapChanged,
    })
    ActChoice = Choice(Farm, {
        key = "FarmAct",
        title = "Act (ด่านย่อย)",
        desc = "Stage ของแมพที่เลือก",
        options = function()
            local m = findMap(Config.FarmMode, Config.FarmMap)
            local o = {}
            for i = 1, (m and m.stages or 1) do
                table.insert(o, i)
            end
            return o
        end,
        label = function(v)
            return "Act " .. tostring(v)
        end,
    })
    Choice(Farm, {
        key = "FarmDifficulty",
        title = "ความยาก",
        desc = "Normal / Hard / Nightmare",
        options = DIFFS,
    })

    Section(Farm, "Event")
    Toggle(Farm, {
        key = "AutoEvent",
        title = "Auto ลง Event",
        desc = "ลงด่านอีเวนต์ปัจจุบัน (ต้องเลเวลถึงตามที่เกมกำหนด)",
    })
    Choice(Farm, {
        key = "EventDifficulty",
        title = "ความยาก Event",
        desc = "Normal / Hard / Nightmare",
        options = DIFFS,
    })

    local Shop = MakePage("Shop", "ร้านค้า", "ซื้อของอัตโนมัติ  •  ยืนใน Lobby จนซื้อหมดสต็อก")
    Section(Shop, "ตั้งค่า")
    Toggle(Shop, {
        key = "AutoShop",
        title = "Auto ซื้อของร้านค้า",
        desc = "ซื้อใหม่ทุกครั้งที่ร้านรีสต็อก (ทุก xx:00 เวลาจริง)",
    })
    Toggle(Shop, {
        key = "ShopLeaveToBuy",
        title = "ออกจากแมตช์ไปซื้อเมื่อรีสต็อก",
        desc = "ตอนฟาร์ม/Event อยู่ จะกลับ Lobby มาซื้อ แล้วกลับไปลงต่อ",
    })
    Section(Shop, "ร้าน Coins")
    for _, id in ipairs(SHOP_IDS) do
        local it = shopItem("Coins", id)
        Toggle(Shop, {
            key = shopKey("Coins", id),
            title = id,
            desc = it and ("ราคา " .. fmt(it.Price) .. " Coins  •  สต็อก " .. it.MaxStock) or "",
        })
    end
    Section(Shop, "ร้าน Gems")
    for _, id in ipairs(SHOP_IDS) do
        local it = shopItem("Gems", id)
        Toggle(Shop, {
            key = shopKey("Gems", id),
            title = id,
            desc = it and ("ราคา " .. fmt(it.Price) .. " Gems  •  สต็อก " .. it.MaxStock) or "",
        })
    end

    ------------------------------------------------------------------
    -- STATUS
    ------------------------------------------------------------------
    local statusText = "เริ่มทำงาน..."

    local function timersLine()
        local dur = ShopCfg.RestockDuration
        local left = dur - (os.time() % dur)
        local s = string.format("ร้านรีสต็อกใน %02d:%02d", math.floor(left / 60), left % 60)
        local t = loadNext()
        local now = os.time()
        local soon
        for _, ts in pairs(t) do
            if type(ts) == "number" and ts > now and (not soon or ts < soon) then
                soon = ts
            end
        end
        if soon then
            local d = soon - now
            s = s .. string.format("  |  Challenge รีเซ็ตใน %dh %02dm", math.floor(d / 3600), math.floor((d % 3600) / 60))
        end
        return s
    end

    local function refreshInfo()
        StatusBox.Set(
            string.format(
                "Trait  %s     Coins  %s     Gems  %s",
                fmt(LocalPlayer:GetAttribute("Trait")),
                fmt(LocalPlayer:GetAttribute("Coins")),
                fmt(LocalPlayer:GetAttribute("Gems"))
            ),
            "สถานะ: " .. statusText,
            timersLine()
        )
    end

    local function setStatus(t)
        statusText = t
        refreshInfo()
    end

    ------------------------------------------------------------------
    -- LOBBY: ซื้อของ + ลงด่าน
    ------------------------------------------------------------------
    local function balanceOf(cur)
        return tonumber(LocalPlayer:GetAttribute(cur)) or 0
    end

    -- ซื้อเต็ม MaxStock ในคำสั่งเดียว / เงินไม่พอซื้อเท่าที่ซื้อได้ / สต็อกเหลือน้อยลดจำนวนลงเอง
    -- return: ซื้อได้กี่ชิ้น, เงินไม่พอหรือเปล่า
    local function buyItemMax(it, cur)
        local target = it.MaxStock
        local afford = math.floor(balanceOf(cur) / it.Price)
        local poor = afford < target
        local want = math.min(target, afford)
        if want <= 0 then
            return 0, true
        end
        local got, tries = 0, 0
        while want >= 1 and tries < 12 and alive() do
            tries += 1
            local ok, res = pcall(function()
                return Remotes.BuyItem:InvokeServer(it.ID, want, cur)
            end)
            if ok and res then
                got += want
                want = math.min(target - got, math.floor(balanceOf(cur) / it.Price))
                if want >= 1 then
                    task.wait(0.15)
                end
            else
                if want == 1 then
                    break
                end
                want = math.floor(want / 2) -- เกินสต็อกที่เหลือ: ลองน้อยลง
                task.wait(0.15)
            end
        end
        return got, poor
    end

    local function canAffordAny()
        for _, cur in ipairs({ "Coins", "Gems" }) do
            local list = (cur == "Coins") and ShopCfg.GoldShopItems or ShopCfg.GemsShopItems
            for _, it in ipairs(list) do
                if Config[shopKey(cur, it.ID)] == true and balanceOf(cur) >= it.Price then
                    return true
                end
            end
        end
        return false
    end

    local function buyShop()
        local cycle = currentCycle()
        local bought, missing = 0, false
        setStatus("กำลังซื้อของร้านค้า...")
        for _, cur in ipairs({ "Coins", "Gems" }) do
            local list = (cur == "Coins") and ShopCfg.GoldShopItems or ShopCfg.GemsShopItems
            for _, it in ipairs(list) do
                if Config[shopKey(cur, it.ID)] == true then
                    if not alive() then
                        return bought
                    end
                    local got, poor = buyItemMax(it, cur)
                    bought += got
                    if poor then
                        missing = true -- เงินไม่พอ: ไม่รอ เล่นต่อ จะกลับมาซื้อเมื่อมีเงินพอ/รีสต็อก
                    end
                    if got > 0 then
                        setStatus(string.format("ซื้อ %s (%s) x%d  รวม %d ชิ้น", it.ID, cur, got, bought))
                    end
                end
            end
        end
        SetConfig("StateShopCycle", cycle)
        SetConfig("StateShopMissing", missing)
        setStatus(string.format("ซื้อของเสร็จ %d ชิ้น%s", bought, missing and " (เงินไม่พอบางรายการ เล่นต่อ)" or ""))
        return bought
    end

    ------------------------------------------------------------------
    -- PARTY (Host / Guest)
    ------------------------------------------------------------------
    local PartyList = {}
    local lastRoomJoin = 0

    local function nameMatches(p, name)
        if not p or not name or name == "" then
            return false
        end
        name = string.lower(name)
        local n = string.lower(tostring(p.Name or ""))
        local d = string.lower(tostring(p.DisplayName or ""))
        return n == name or d == name
    end

    local function isHostMode()
        return Config.PartyEnabled and Config.PartyRole == "Host"
    end

    local function isGuestMode()
        return Config.PartyEnabled and Config.PartyRole == "Guest"
    end

    local function targetPlayer()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and nameMatches(p, Config.PartyTarget) then
                return p
            end
        end
        return nil
    end

    local function partyHas(pred)
        for _, p in ipairs(PartyList) do
            if typeof(p) == "Instance" or type(p) == "table" then
                if pred(p) then
                    return true
                end
            end
        end
        return false
    end

    local function leaveLobbyRoom()
        pcall(function()
            Remotes.LeaveLobbyEvent:FireServer()
        end)
        PartyList = {}
    end

    local function guestJoin(roomId)
        local ok, res = pcall(function()
            return Remotes.RequestJoinLobby:InvokeServer("Join", roomId)
        end)
        lastRoomJoin = os.clock()
        return ok and res
    end

    if IN_LOBBY then
        pcall(function()
            Remotes.UpdatePartyEvent.OnClientEvent:Connect(function(list)
                if type(list) == "table" then
                    PartyList = list
                end
            end)
        end)
        -- Guest: ถูกเชิญจากเพื่อนที่เลือกไว้ = เข้าห้องอัตโนมัติ
        pcall(function()
            Remotes.LobbyInvite.OnClientEvent:Connect(function(inviter, roomId)
                if isGuestMode() and inviter and nameMatches(inviter, Config.PartyTarget) then
                    guestJoin(roomId)
                end
            end)
        end)
    end

    -- Auto Join Job ID: อยู่เซิฟที่ต้องการแล้ว / เพื่อนอยู่เซิฟเดียวกันแล้ว = ไม่ต้องวาป
    local function jobGuard()
        if not Config.AutoJoinJob then
            return true
        end
        local jid = tostring(Config.JobIdValue or ""):gsub("%s", "")
        if jid == "" or jid == game.JobId then
            return true
        end
        if Config.PartyEnabled and targetPlayer() then
            return true
        end
        setStatus("กำลังวาปไปเซิฟตาม Job ID...")
        pcall(function()
            TeleportService:TeleportToPlaceInstance(LOBBY_PLACE_ID, jid, LocalPlayer)
        end)
        for _ = 1, 15 do
            if not alive() then
                return false
            end
            task.wait(1)
        end
        return false
    end

    -- Host: เชิญเพื่อนซ้ำๆ จนเพื่อนเข้าห้อง
    local function hostWaitParty()
        local deadline = os.clock() + math.max(15, tonumber(Config.PartyHostWait) or 90)
        local lastInvite = -99
        while alive() and os.clock() < deadline do
            if partyHas(function(p)
                return nameMatches(p, Config.PartyTarget)
            end) then
                return true
            end
            if os.clock() - lastInvite >= 5 then
                lastInvite = os.clock()
                local tp = targetPlayer()
                if tp then
                    pcall(function()
                        Remotes.LobbyInvite:FireServer(tp)
                    end)
                end
            end
            local left = math.floor(deadline - os.clock())
            if targetPlayer() then
                setStatus(string.format("เชิญ %s แล้ว รอเข้าห้อง (%d วิ)", tostring(Config.PartyTarget), left))
            else
                setStatus(string.format("ไม่พบ %s ในเซิฟนี้ (%d วิ)", tostring(Config.PartyTarget), left))
            end
            task.wait(1)
        end
        return false
    end

    -- ยิงชุดคำสั่งเดียวกับที่ UI ของเกมใช้ตอนกด Play (ถ้าวาปสำเร็จ สคริปต์จะถูกตัดไปเอง)
    local function launch(activity, name, stage, rewards, difficulty, mapKey, mode)
        SetConfig("StateActivity", activity)
        SaveConfig(true)
        PartyList = {}
        pcall(function()
            Remotes.RequestJoinLobby:InvokeServer("Create")
        end)
        task.wait(0.8)

        local function sendSettings()
            Remotes.UpdateLobbySettings:FireServer(name, stage, rewards, difficulty, mapKey, mode)
        end
        sendSettings()
        task.wait(0.5)

        if isHostMode() then
            if Config.PartyTarget == "" then
                setStatus("เปิดระบบ Host แล้วแต่ยังไม่ได้เลือกชื่อเพื่อน")
                leaveLobbyRoom()
                SetConfig("StateActivity", "")
                task.wait(5)
                return false
            end
            if not hostWaitParty() then
                setStatus("เพื่อนไม่เข้าห้อง -> ออกจากห้องแล้วลองใหม่")
                leaveLobbyRoom()
                SetConfig("StateActivity", "")
                task.wait(3)
                return false
            end
            task.wait(1.5)
        end

        -- ส่งค่าแมพ/ด่านซ้ำก่อนเริ่ม กันเซิร์ฟเวอร์ยังไม่มีค่า (แก้แจ้งเตือน Please select a map and stage first)
        sendSettings()
        task.wait(0.8)
        Remotes.TeleportRequest:FireServer(MATCH_TP_ID, mode, mapKey, stage, difficulty)
        for _ = 1, 35 do
            if not alive() then
                return false
            end
            task.wait(1)
        end
        -- ยังอยู่ Lobby = ลงไม่ได้
        leaveLobbyRoom()
        SetConfig("StateActivity", "")
        return false
    end

    local function tryChallenge()
        local ok, data = pcall(function()
            return Remotes.GetChallengeData:InvokeServer()
        end)
        if not ok or type(data) ~= "table" then
            return false
        end
        local tabs = {}
        for name, v in pairs(data) do
            if type(v) == "table" and v.MapToCreate and (Config.ChallengeTab == "All" or Config.ChallengeTab == name) then
                table.insert(tabs, name)
            end
        end
        table.sort(tabs)

        for _, tab in ipairs(tabs) do
            local nextT = loadNext()
            if (nextT[tab] or 0) <= os.time() then
                local c = data[tab]
                local rewards = { Items = {} }
                for _, r in ipairs(c.Rewards or {}) do
                    if r.Id == "Coins" then
                        rewards.Coins = r.Amount
                    elseif r.Id == "Gems" then
                        rewards.Gems = r.Amount
                    else
                        table.insert(rewards.Items, { Id = r.Id, Count = r.Amount, Chance = 100 })
                    end
                end
                setStatus(string.format("ลง %s Challenge (%s stage %s)", tab, tostring(c.MapName), tostring(c.StageName)))
                launch("challenge", tab .. " Challenge", c.StageName, rewards, "Nightmare", c.MapToCreate, tab .. "Challenge")

                -- มาถึงตรงนี้ = ยังอยู่ Lobby (เคลียร์รอบนี้แล้ว/ลงไม่ได้) -> รอรอบรีเซ็ต
                nextT = loadNext()
                nextT[tab] = os.time() + math.max(60, tonumber(c.TimeLeft) or 3600) + 5
                saveNext(nextT)
            end
        end
        return false
    end

    local function launchEvent()
        local e = eventEntry()
        setStatus("ลง Event: " .. tostring(e.name))
        return launch("event", e.name, 1, stageRewards(e.key, 1), Config.EventDifficulty, e.key, e.mode)
    end

    local function launchFarm()
        normalizeFarm()
        local m = findMap(Config.FarmMode, Config.FarmMap)
        if not m then
            return false
        end
        local act = Config.FarmAct
        setStatus(string.format("ลง %s: %s Act %s (%s)", Config.FarmMode, m.name, tostring(act), Config.FarmDifficulty))
        return launch("farm", m.name, act, stageRewards(m.key, act), Config.FarmDifficulty, m.key, m.mode)
    end

    doChallengeNow = function()
        if not IN_LOBBY then
            Toast("ใช้ได้เฉพาะตอนอยู่ใน Lobby")
            return
        end
        saveNext({})
        tryChallenge()
    end

    doShopNow = function()
        if not IN_LOBBY then
            Toast("ใช้ได้เฉพาะตอนอยู่ใน Lobby")
            return
        end
        buyShop()
    end

    -- Guest 1 รอบ: ถ้ายังไม่อยู่ในห้อง ไปหาห้องของ Host แล้ว Join
    local roomSince = nil
    local function guestStep()
        if Config.PartyTarget == "" then
            setStatus("Guest: ยังไม่ได้เลือกชื่อ Host")
            return
        end
        local inRoom = partyHas(function(p)
            return p == LocalPlayer
        end)
        if inRoom then
            roomSince = roomSince or os.clock()
            setStatus("Guest: อยู่ในห้องแล้ว รอ " .. tostring(Config.PartyTarget) .. " เริ่มด่าน")
            if os.clock() - roomSince > 240 then
                leaveLobbyRoom() -- ค้างนานเกิน = รีเซ็ตแล้วหาห้องใหม่
                roomSince = nil
            end
            return
        end
        roomSince = nil
        if os.clock() - lastRoomJoin < 3 then
            return
        end
        local ok, rooms = pcall(function()
            return Remotes.GetLobbyList:InvokeServer()
        end)
        if ok and type(rooms) == "table" then
            for _, r in ipairs(rooms) do
                local host = string.lower(tostring(r.HostName or ""))
                local want = string.lower(Config.PartyTarget)
                local tp = targetPlayer()
                if host == want or (tp and host == string.lower(tp.DisplayName)) then
                    setStatus("Guest: เจอห้องของ " .. tostring(r.HostName) .. " กำลังเข้า...")
                    guestJoin(r.RoomId)
                    return
                end
            end
        end
        setStatus("Guest: รอ " .. tostring(Config.PartyTarget) .. " สร้างห้อง...")
    end

    local function lobbyMain()
        SetConfig("StateActivity", "")
        local t0 = os.clock()
        while LocalPlayer:GetAttribute("Coins") == nil and os.clock() - t0 < 25 do
            task.wait(0.5)
        end
        task.wait(2)

        while alive() do
            -- 0) Auto Join Job ID (ถ้าเปิด)
            if not jobGuard() then
                continue
            end

            -- 1) ร้านค้า: ซื้อใน Lobby ก่อน แล้วค่อยไปลงต่อ (เงินไม่พอ = ข้าม ไม่รอ)
            if
                shopWanted()
                and (currentCycle() ~= Config.StateShopCycle or (Config.StateShopMissing and canAffordAny()))
            then
                buyShop()
            end

            -- 1.5) Guest: ไม่สร้างห้องเอง คอยเข้าห้องของ Host
            if isGuestMode() then
                guestStep()
                task.wait(2)
                continue
            end

            -- 2) เลือกงานตามลำดับความสำคัญ
            for _, act in ipairs(parseOrder()) do
                if not alive() then
                    return
                end
                if act == "Challenge" and Config.AutoChallenge then
                    tryChallenge()
                elseif act == "Event" and Config.AutoEvent then
                    launchEvent()
                elseif act == "Farm" and Config.AutoFarm then
                    launchFarm()
                end
            end

            setStatus("ไม่มีงานให้ลงตอนนี้ (รอ 30 วิ แล้วเช็กใหม่)")
            for _ = 1, 30 do
                if not alive() then
                    return
                end
                task.wait(1)
            end
        end
    end

    ------------------------------------------------------------------
    -- MATCH: ตั้งค่า auto / ออกเมื่อจบ Challenge / ออกเมื่อ Challenge มา หรือร้านรีสต็อก
    ------------------------------------------------------------------
    local leaving = false

    local function leaveToLobby(why, teleportFirst)
        if leaving then
            return
        end
        leaving = true
        setStatus(why .. " -> กำลังกลับ Lobby")
        task.spawn(function()
            for i = 1, 20 do
                if not alive() then
                    return
                end
                local useTeleport = (i % 2 == 1) == (teleportFirst == true)
                pcall(function()
                    if useTeleport then
                        TeleportService:Teleport(LOBBY_PLACE_ID, LocalPlayer)
                    else
                        GameEvents.LeaveGameRequest:FireServer()
                    end
                end)
                task.wait(6)
            end
            leaving = false
        end)
    end

    local function shouldLeave(act)
        local myName = (act == "event") and "Event" or "Farm"
        if not isGuestMode() and Config.AutoChallenge and prioIndex("Challenge") < prioIndex(myName) then
            local due, tab = challengeDue()
            if due then
                return "Challenge (" .. tostring(tab) .. ") พร้อมแล้ว"
            end
        end
        if shopWanted() and Config.ShopLeaveToBuy and currentCycle() ~= Config.StateShopCycle and canAffordAny() then
            return "ร้านค้ารีสต็อกแล้ว"
        end
        return nil
    end

    local function matchMain()
        local act = Config.StateActivity
        local guestMode = isGuestMode()
        -- Guest ตาม Host: เล่น/Retry ต่อเนื่อง ไม่ออกเอง (ออกเมื่อ Host ออก)
        local farming = (act == "farm" or act == "event") or guestMode

        if guestMode then
            Players.PlayerRemoving:Connect(function(p)
                if nameMatches(p, Config.PartyTarget) then
                    task.delay(Config.LeaveDelay, function()
                        leaveToLobby("Host ออกจากแมตช์", false)
                    end)
                end
            end)
        end

        task.spawn(function()
            task.wait(6)
            if Config.MatchAuto then
                for _, k in ipairs({ "AutoVoteStart", "Autoplay", "AutoSkipWave", "AutoMaxGameSpeed", "AutoUltimate" }) do
                    pcall(function()
                        Remotes.UpdateSetting:FireServer(k, true)
                    end)
                end
                -- ฟาร์ม/Event = Retry เองต่อเนื่อง, Challenge = ไม่ retry เพื่อจะได้กลับ Lobby
                pcall(function()
                    Remotes.UpdateSetting:FireServer("AutoRetry", farming)
                end)
                pcall(function()
                    Remotes.UpdateSetting:FireServer("AutoNext", false)
                end)
            end
            setStatus("อยู่ในแมตช์: " .. (act ~= "" and act or "manual"))
        end)

        GameEvents.EndGameEvent.OnClientEvent:Connect(function()
            if farming then
                -- ไม่ออกเอง: ให้ AutoRetry ทำงาน ถ้าไม่ retry ภายใน 15 วิ ช่วยกด Retry
                task.delay(15, function()
                    if alive() and not leaving then
                        pcall(function()
                            GameEvents.RetryGameRequest:FireServer()
                        end)
                    end
                end)
            elseif Config.AutoLeaveChallenge then
                task.delay(Config.LeaveDelay, function()
                    leaveToLobby("จบแมตช์", false)
                end)
            end
        end)

        if farming then
            task.spawn(function()
                task.wait(10)
                while alive() do
                    if not leaving then
                        local why = shouldLeave(act)
                        if why then
                            leaveToLobby(why, true)
                        end
                    end
                    task.wait(5)
                end
            end)
        end
    end

    ------------------------------------------------------------------
    -- START
    ------------------------------------------------------------------
    task.defer(function()
        normalizeFarm()
        MapChoice.Refresh()
        ActChoice.Refresh()
        task.spawn(function()
            while alive() do
                refreshInfo()
                task.wait(1)
            end
        end)
        if IN_LOBBY then
            task.spawn(lobbyMain)
        else
            task.spawn(matchMain)
        end
    end)
end)()


--==================================================
-- SETTINGS
--==================================================

local Settings = MakePage("Settings", "ตั้งค่า", "ปรับแต่งหน้าตา RELWX  •  เปลี่ยนแล้วเซฟทันที")

Section(Settings, "ระบบ")

Toggle(Settings, {
    key = "SoundEnabled",
    title = "เสียงตอนเปิด/ปิดฟังก์ชัน",
    desc = "เล่นเสียงสั้นๆ เมื่อกดสวิตช์",
})

Toggle(Settings, {
    key = "StatsVisible",
    title = "แสดง FPS / MS",
    desc = "กล่องเล็กลากย้ายตำแหน่งได้",
    callback = function(v)
        StatsGui.Enabled = v
    end,
})

Slider(Settings, {
    key = "UIScalePercent",
    title = "ขนาดหน้าต่าง",
    desc = "ปรับเพิ่มจากขนาดอัตโนมัติตามหน้าจอ",
    min = 60,
    max = 120,
    step = 5,
    suffix = "%",
    callback = function()
        ApplyScale(true)
    end,
})

Section(Settings, "ธีมสำเร็จรูป")
ThemeGrid(Settings)

Section(Settings, "ธีม UI")
ColorRow(Settings, "สีหลัก UI", "UIAccentColor")
ColorRow(Settings, "สีพื้นหลัง UI", "UIBackgroundColor")
ColorRow(Settings, "สีปุ่ม UI", "UIButtonColor")

Section(Settings, "ปุ่มลอย RX")
ColorRow(Settings, "สีปุ่ม RX", "FloatingButtonColor")
ColorRow(Settings, "สีขอบ RX", "FloatingBorderColor")
ColorRow(Settings, "สี Glow RX", "FloatingGlowColor")

Section(Settings, "Config")

local CfgCard = Panel(Settings, UDim2.new(1, 0, 0, 64))
local CfgTitle = Text(CfgCard, "บันทึกอัตโนมัติ", 13, FNT.M, "Text")
CfgTitle.Position = UDim2.fromOffset(16, 11)
CfgTitle.Size = UDim2.new(1, -140, 0, 20)
local CfgDesc = Text(
    CfgCard,
    writefile and CONFIG_FILE or "executor นี้ไม่รองรับการเขียนไฟล์",
    10,
    FNT.R,
    "Muted"
)
CfgDesc.Position = UDim2.fromOffset(16, 33)
CfgDesc.Size = UDim2.new(1, -140, 0, 18)
local CfgPill = StatusPill(CfgCard, 108)
CfgPill.AnchorPoint = Vector2.new(1, 0.5)
CfgPill.Position = UDim2.new(1, -14, 0.5, 0)

local ResetRow = Panel(Settings, UDim2.new(1, 0, 0, 50), "TextButton")
HoverRow(ResetRow)
local ResetLabel = Text(ResetRow, "รีเซ็ตการตั้งค่าทั้งหมด", 12, FNT.M, RGB(235, 90, 100))
ResetLabel.Position = UDim2.fromOffset(16, 0)
ResetLabel.Size = UDim2.new(1, -32, 1, 0)

local FloatApplyPosition

local resetArmed = false
ResetRow.MouseButton1Click:Connect(function()
    if not resetArmed then
        resetArmed = true
        ResetLabel.Text = "กดอีกครั้งเพื่อยืนยันการรีเซ็ต"
        task.delay(3, function()
            resetArmed = false
            ResetLabel.Text = "รีเซ็ตการตั้งค่าทั้งหมด"
        end)
        return
    end
    resetArmed = false
    ResetLabel.Text = "รีเซ็ตการตั้งค่าทั้งหมด"

    for k, v in pairs(Defaults) do
        Config[k] = v
    end
    Collapsed = {}
    for _, secs in pairs(SectionsByPage) do
        for _, sec in ipairs(secs) do
            sec.collapsed = false
            sec.refresh(true)
        end
    end
    ApplyTheme()
    for _, fn in ipairs(Refreshers) do
        pcall(fn)
    end
    Tween(Main, 0.3, { Position = UDim2.fromScale(Config.WindowX, Config.WindowY) }, Enum.EasingStyle.Quint)
    ApplyScale(true)
    if FloatApplyPosition then
        FloatApplyPosition()
    end
    StatsBox.Position = UDim2.fromScale(Config.StatsX, Config.StatsY)
    StatsGui.Enabled = Config.StatsVisible
    SelectTab(Config.LastTab)
    SaveConfig(true)
    Toast("รีเซ็ตการตั้งค่าแล้ว")
end)

--==================================================
-- SIDEBAR CATEGORIES
--==================================================

CatGroup("เมนูหลัก")
Category("หน้าหลัก", "Home", "grid")
Category("ฟังก์ชัน", "Functions", "sliders")
Category("ฟาร์ม", "Farm", "grid")
Category("ร้านค้า", "Shop", "sliders")
CatGroup("ระบบ")
Category("ตั้งค่า", "Settings", "ring")

--==================================================
-- FLOATING RX BUTTON
--==================================================

local ToggleGui = New("ScreenGui", {
    Name = "RELWX_Floating",
    ResetOnSpawn = false,
    DisplayOrder = 999999,
    IgnoreGuiInset = true,
}, PlayerGui)

local Float = New("Frame", {
    Size = UDim2.fromOffset(48, 48),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(Config.FloatX, Config.FloatY),
    BackgroundTransparency = 1,
    Active = true,
}, ToggleGui)

local Glow = New("Frame", {
    Size = UDim2.new(1, 8, 1, 8),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
}, Float)
Corner(Glow, 15)
local GlowStroke = Stroke(Glow, RGB(145, 145, 145), 3, 0.2)

local RX = New("TextButton", {
    Size = UDim2.fromScale(1, 1),
    Text = "RX",
    TextSize = 15,
    Font = FNT.B,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Active = true,
}, Float)
Corner(RX, 13)
local RXStroke = Stroke(RX, RGB(255, 255, 255), 2, 0.05)
local RXGrad = New("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0.85),
        NumberSequenceKeypoint.new(1, 0),
    }),
}, RXStroke)
TweenService:Create(
    RXGrad,
    TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    { Rotation = 360 }
):Play()

OnTheme(function()
    local bg = Hex("FloatingButtonColor", RGB(18, 18, 18))
    RX.BackgroundColor3 = bg
    RX.TextColor3 = Lum(bg) > 0.55 and RGB(15, 15, 15) or RGB(255, 255, 255)
    RXStroke.Color = Hex("FloatingBorderColor", RGB(255, 255, 255))
    GlowStroke.Color = Hex("FloatingGlowColor", RGB(145, 145, 145))
end)

TweenService:Create(
    GlowStroke,
    TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { Transparency = 0.65 }
):Play()

FloatApplyPosition = function()
    Float.Position = UDim2.fromScale(Config.FloatX, Config.FloatY)
end

MakeDraggable(RX, Float, "FloatX", "FloatY", function()
    SetWindow(not Config.WindowVisible)
end)

--==================================================
-- START
--==================================================

SelectTab(Config.LastTab)
RefreshStats()
RefreshHome()

if Config.WindowVisible then
    PlayOpen()
end

if not LoadedFromFile then
    SaveConfig(true) -- สร้างไฟล์ Config ครั้งแรก
end

print("[RELWX] UI v7 Loaded" .. (LoadedFromFile and " (Config loaded)" or " (new Config)"))
