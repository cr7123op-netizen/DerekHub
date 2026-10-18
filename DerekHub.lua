--[[ Derek Hub v5.1 — Stealth Edition | Author: ALPHA ]]
task.wait(3) -- تأخير عشان نتجنب فحص التحميل

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local RS         = game:GetService("ReplicatedStorage")
local UIS        = game:GetService("UserInputService")
local Tween      = game:GetService("TweenService")
local VU         = game:GetService("VirtualUser")
local LP         = Players.LocalPlayer

-- حماية من التحميل المزدوج بدون getgenv
if _G.__DerekHubStealth then return end
_G.__DerekHubStealth = true

local C = {
    AutoSteal=false, SafeMode=true, AntiCatch=false, AntiRagdoll=false,
    GodMode=false, ESP=false, MaxDist=10, MinDelay=0.8, MaxDelay=1.5
}

-- دالة بحث آمنة عن Remotes (بدون GetDescendants الثقيل)
local function findRemote(kws)
    local list = RS:GetChildren()
    for _,v in ipairs(list) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local n = string.lower(v.Name)
            for _,k in ipairs(kws) do
                if n:find(k) then return v end
            end
        end
    end
    return nil
end
local StealRemote  = findRemote({"steal","grab","takeegg","pickup"})
local ReportRemote = findRemote({"report","catch","caught","tackle","trip","kick","ban"})

local function getChar()
    local c = LP.Character
    return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

local function getEggs()
    local t = {}
    for _,o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("Model") or o:IsA("Part") then
            local n = string.lower(o.Name)
            if n:find("egg") and not n:find("plot") and not n:find("spawn") then
                local p = o:FindFirstChildWhichIsA("ProximityPrompt", true)
                if p then table.insert(t, {model=o, prompt=p}) end
            end
        end
    end
    return t
end

local function stealEgg(e)
    if not e or not e.model.Parent then return end
    local _,hum,hrp = getChar()
    if not hum or not hrp or hum.Health <= 0 then return end
    local pos = (e.model:IsA("Model") and e.model:GetPivot().Position) or e.model.Position
    if (pos - hrp.Position).Magnitude > C.MaxDist then return end
    if e.prompt then pcall(function() fireproximityprompt(e.prompt) end) return end
    if StealRemote then pcall(function() StealRemote:FireServer(e.model) end) end
end

local stealing = false
local function autoSteal()
    if stealing then return end; stealing = true
    task.spawn(function()
        while C.AutoSteal do
            local _,hum,hrp = getChar()
            if hum and hrp and hum.Health > 0 then
                local best,bestD = nil, math.huge
                for _,e in ipairs(getEggs()) do
                    local pos = (e.model:IsA("Model") and e.model:GetPivot().Position) or e.model.Position
                    local d = (pos - hrp.Position).Magnitude
                    if d < bestD and d <= C.MaxDist then best, bestD = e, d end
                end
                if best then
                    stealEgg(best)
                    task.wait(math.random()*(C.MaxDelay-C.MinDelay)+C.MinDelay)
                else task.wait(0.5) end
            else task.wait(0.5) end
        end
        stealing = false
    end)
end

-- حماية (بدون getrawmetatable إذا مو موجود)
local function antiCatch()
    if not (getrawmetatable and setreadonly and newcclosure) then return end
    local mt = getrawmetatable(game)
    if mt and mt.__namecall then
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            if self == ReportRemote then return nil end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end
end

local function antiRagdoll()
    task.spawn(function()
        while C.AntiRagdoll do
            local _,hum,hrp = getChar()
            if hum then
                if hum:GetState() == Enum.HumanoidStateType.Physics then
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                end
                if hrp then
                    local r = hrp:FindFirstChild("Ragdoll")
                    if r then pcall(function() r:Destroy() end) end
                end
            end
            task.wait(0.1)
        end
    end)
end

local function godMode()
    task.spawn(function()
        while C.GodMode do
            local _,hum = getChar()
            if hum then hum.Health = hum.MaxHealth end
            task.wait(0.25)
        end
    end)
end

local espObjs = {}
local function updateESP()
    if not C.ESP then
        for _,b in pairs(espObjs) do b:Destroy() end
        espObjs = {}
        return
    end
    for _,d in ipairs(getEggs()) do
        local egg = d.model
        if not espObjs[egg] then
            local b = Instance.new("BoxHandleAdornment")
            b.Adornee = egg; b.AlwaysOnTop = true; b.ZIndex = 5
            b.Size = egg:IsA("Model") and egg:GetExtentsSize() or egg.Size
            b.Color3 = Color3.fromRGB(255,30,30); b.Transparency = 0.5
            b.Parent = egg; espObjs[egg] = b
        end
    end
    for e,b in pairs(espObjs) do if not e.Parent then b:Destroy(); espObjs[e]=nil end end
end
RunService.RenderStepped:Connect(updateESP)

LP.Idled:Connect(function() pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end) end)

-- ============ الواجهة (مخفية في gethui) ============
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local clr = {
    bg=Color3.fromRGB(15,10,12), panel=Color3.fromRGB(25,15,18),
    accent=Color3.fromRGB(220,30,40), accent2=Color3.fromRGB(255,60,70),
    text=Color3.fromRGB(245,235,235), knobOff=Color3.fromRGB(60,45,50),
}

-- استخدام gethui إذا متوفر (أكثر أماناً من PlayerGui)
local uiParent = (gethui and gethui()) or LP:WaitForChild("PlayerGui")

local gui = mk("ScreenGui", {Name="DerekHubUI", ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, uiParent)

local iconBtn = mk("TextButton", {
    Name="DerekIcon", Size=UDim2.fromOffset(64,64),
    Position=UDim2.new(0,20,0.5,-32), BackgroundColor3=clr.accent,
    BorderSizePixel=0, AutoButtonColor=false, Text="D",
    Font=Enum.Font.GothamBlack, TextSize=30,
    TextColor3=Color3.new(1,1,1), ZIndex=100,
}, gui)
mk("UICorner",{CornerRadius=UDim.new(1,0)}, iconBtn)
local iconStroke = mk("UIStroke",{Color=clr.accent2, Thickness=2.5, Transparency=0.2}, iconBtn)

local panel = mk("Frame", {
    Name="Panel", Size=UDim2.fromOffset(340,480),
    Position=UDim2.new(0.5,-170,0.5,-240), BackgroundColor3=clr.bg,
    BorderSizePixel=0, Visible=false, ZIndex=90,
}, gui)
mk("UICorner",{CornerRadius=UDim.new(0,14)}, panel)
mk("UIStroke",{Color=clr.accent, Thickness=1.5, Transparency=0.3}, panel)

local titleBar = mk("Frame",{Size=UDim2.new(1,0,0,48), BackgroundColor3=clr.panel, BorderSizePixel=0}, panel)
mk("UICorner",{CornerRadius=UDim.new(0,14)}, titleBar)
mk("Frame",{Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,1,-14), BackgroundColor3=clr.panel, BorderSizePixel=0}, titleBar)

local closeBtn = mk("TextButton", {
    Size=UDim2.fromOffset(32,32), Position=UDim2.new(1,-42,0.5,-16),
    BackgroundColor3=clr.accent, Text="✕", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=16, BorderSizePixel=0, AutoButtonColor=false,
}, titleBar)
mk("UICorner",{CornerRadius=UDim.new(0,8)}, closeBtn)

local content = mk("ScrollingFrame", {
    Size=UDim2.new(1,-20,1,-158), Position=UDim2.new(0,10,0,106),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3,
    CanvasSize=UDim2.new(0,0,0,0), ScrollBarImageColor3=clr.accent,
}, panel)
mk("UIListLayout",{Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder}, content)

local function addToggle(text, default, callback)
    local row = mk("Frame",{Size=UDim2.new(1,-10,0,44), BackgroundColor3=clr.panel, BorderSizePixel=0}, content)
    mk("UICorner",{CornerRadius=UDim.new(0,10)}, row)
    mk("TextLabel",{Size=UDim2.new(1,-80,1,0), Position=UDim2.new(0,14,0,0), BackgroundTransparency=1, Font=Enum.Font.GothamMedium, TextSize=14, TextColor3=clr.text, Text=text, TextXAlignment=Enum.TextXAlignment.Left}, row)
    local sw = mk("Frame",{Size=UDim2.fromOffset(48,26), Position=UDim2.new(1,-60,0.5,-13), BackgroundColor3=default and clr.accent or clr.knobOff, BorderSizePixel=0}, row)
    mk("UICorner",{CornerRadius=UDim.new(1,0)}, sw)
    local knob = mk("Frame",{Size=UDim2.fromOffset(20,20), Position=UDim2.new(0, default and 25 or 3,0.5,-10), BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0}, sw)
    mk("UICorner",{CornerRadius=UDim.new(1,0)}, knob)
    local state = default
    local btn = mk("TextButton",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text=""}, row)
    btn.MouseButton1Click:Connect(function()
        state = not state
        Tween:Create(sw, TweenInfo.new(0.18), {BackgroundColor3 = state and clr.accent or clr.knobOff}):Play()
        Tween:Create(knob, TweenInfo.new(0.18), {Position = UDim2.new(0, state and 25 or 3,0.5,-10)}):Play()
        if callback then pcall(callback, state) end
    end)
end

addToggle("Auto Steal", false, function(v) C.AutoSteal=v; if v then autoSteal() end end)
addToggle("Anti Catch", false, function(v) C.AntiCatch=v; if v then antiCatch() end end)
addToggle("Anti Ragdoll", false, function(v) C.AntiRagdoll=v; if v then antiRagdoll() end end)
addToggle("God Mode", false, function(v) C.GodMode=v; if v then godMode() end end)
addToggle("ESP Eggs", false, function(v) C.ESP=v end)

local isOpen = false
local function openPanel()
    if isOpen then return end
    isOpen = true; panel.Visible = true
    Tween:Create(panel, TweenInfo.new(0.2), {Size=UDim2.fromOffset(340,480)}):Play()
end
local function closePanel()
    if not isOpen then return end
    isOpen = false
    Tween:Create(panel, TweenInfo.new(0.2), {Size=UDim2.fromOffset(340,0)}):Play()
    task.delay(0.22, function() if not isOpen then panel.Visible = false end end)
end
iconBtn.MouseButton1Click:Connect(function() if isOpen then closePanel() else openPanel() end end)
closeBtn.MouseButton1Click:Connect(closePanel)
