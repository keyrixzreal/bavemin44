--!strict
--[[
    ═══════════════════════════════════════════════════════════════════
    FROSTED GLASS UI LIBRARY (Sonoma Edition - Fixed & Standalone)
    • FIX: AddDropdown polymorphic callback/default detection
    • FIX: AddSlider & AddToggle polymorphic argument handling
    • Clean library export (No demo, direct 'return Library')
    • %100 Opaque Orange Shield Cinematic Bypass Loader
    • Multi-Executor Protected Core (gethui, syn.protect_gui, CoreGui)
    ═══════════════════════════════════════════════════════════════════
]]

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- Tekrar çalıştırmada önceki pencereyi temizleme
if _G.FrostedGlassInstance then
    pcall(function()
        _G.FrostedGlassInstance:Destroy()
    end)
    _G.FrostedGlassInstance = nil
end

-- ====================================================================
-- 1. EXECUTOR GÜVENLİ GUI PARENT TESPİTİ
-- ====================================================================
local function GetSafeGuiContainer(): Instance
    local env = (getgenv and getgenv()) or _G
    
    if typeof(env.gethui) == "function" then
        return env.gethui()
    end
    
    if env.syn and typeof(env.syn.protect_gui) == "function" then
        local gui = Instance.new("ScreenGui")
        env.syn.protect_gui(gui)
        gui.Parent = game:GetService("CoreGui")
        return gui.Parent
    end
    
    local success, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if success and coreGui then
        local canWrite = pcall(function()
            local test = Instance.new("Folder", coreGui)
            test:Destroy()
        end)
        if canWrite then
            return coreGui
        end
    end
    
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ====================================================================
-- 2. DİZAYN SİSTEMİ & RENK PALETİ
-- ====================================================================
local Theme = {
    MainBg = Color3.fromRGB(16, 18, 24),          -- Derin, mat macOS arka planı
    SidebarBg = Color3.fromRGB(12, 14, 18),
    CardBg = Color3.fromRGB(24, 28, 38),
    CardHover = Color3.fromRGB(34, 40, 56),
    CardActive = Color3.fromRGB(0, 122, 255),
    
    Accent = Color3.fromRGB(0, 122, 255),          -- iOS Neon Mavi
    Orange = Color3.fromRGB(255, 149, 0),          -- Apple Turuncu (Bypass Kalkanı)
    Success = Color3.fromRGB(52, 199, 89),         -- Apple Zümrüt Yeşili
    Warning = Color3.fromRGB(255, 179, 64),        -- macOS Amber
    Danger = Color3.fromRGB(255, 69, 58),          -- macOS Kırmızı
    
    TextPrimary = Color3.fromRGB(250, 250, 255),
    TextSecondary = Color3.fromRGB(165, 170, 185),
    TextMuted = Color3.fromRGB(115, 120, 135),
    
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.88,
    
    FontRegular = Enum.Font.Gotham,
    FontMedium = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
}

local function Animate(instance: Instance, tweenInfo: TweenInfo, properties: {[string]: any}): Tween
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

local function ApplyGlassStroke(instance: Instance, transparency: number?): UIStroke
    local stroke = Instance.new("UIStroke")
    stroke.Name = "GlassStroke"
    stroke.Color = Theme.StrokeColor
    stroke.Transparency = transparency or Theme.StrokeTransparency
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = instance
    return stroke
end

-- ====================================================================
-- 3. WEB ASSET VE İKON ÖNBELLEKLEME
-- ====================================================================
local AssetCache = {
    Folder = "frosted_assets",
    FallbackMap = {
        home = "rbxassetid://10723407389",
        shield = "rbxassetid://10734950309",
        zap = "rbxassetid://10709778233",
        sliders = "rbxassetid://10734975692",
        settings = "rbxassetid://10734950020",
        user = "rbxassetid://10747373176",
        chevron = "rbxassetid://6031094364",
        lock = "rbxassetid://10723434711",
        check = "rbxassetid://10709790644",
        bell = "rbxassetid://10709775877",
        terminal = "rbxassetid://10734976822",
        eye = "rbxassetid://10723346959"
    }
}

function AssetCache:GetAsset(identifier: string): string
    if string.sub(identifier, 1, 13) == "rbxassetid://" then
        return identifier
    end

    local env = (getgenv and getgenv()) or _G
    local isExecutor = (typeof(env.writefile) == "function") 
        and (typeof(env.getcustomasset) == "function" or typeof(env.getsynasset) == "function")

    local isUrl = string.sub(identifier, 1, 7) == "http://" or string.sub(identifier, 1, 8) == "https://"
    
    if not isExecutor then
        return self.FallbackMap[string.lower(identifier)] or self.FallbackMap.shield
    end

    local getAssetFunc = env.getcustomasset or env.getsynasset
    local httpRequest = env.request or env.http_request or (env.syn and env.syn.request) or (http and http.request)

    if typeof(env.makefolder) == "function" and typeof(env.isfolder) == "function" then
        if not env.isfolder(self.Folder) then
            env.makefolder(self.Folder)
        end
    end

    local fileName = ""
    local targetUrl = ""

    if isUrl then
        fileName = self.Folder .. "/" .. string.gsub(identifier, "[^%w]", "_") .. ".png"
        targetUrl = identifier
    else
        local lowerName = string.lower(identifier)
        if self.FallbackMap[lowerName] then
            return self.FallbackMap[lowerName]
        end
        fileName = self.Folder .. "/" .. lowerName .. ".png"
        targetUrl = "https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/" .. lowerName .. ".png"
    end

    if typeof(env.isfile) == "function" and env.isfile(fileName) then
        return getAssetFunc(fileName)
    end

    local downloadSuccess = false
    local responseData = ""

    if httpRequest then
        local res = httpRequest({
            Url = targetUrl,
            Method = "GET"
        })
        if res and (res.StatusCode == 200 or res.Status == 200) and res.Body then
            responseData = res.Body
            downloadSuccess = true
        end
    elseif typeof(game.HttpGet) == "function" then
        local s, body = pcall(function()
            return game:HttpGet(targetUrl)
        end)
        if s and body and #body > 0 then
            responseData = body
            downloadSuccess = true
        end
    end

    if downloadSuccess and #responseData > 0 then
        pcall(function()
            env.writefile(fileName, responseData)
        end)
        return getAssetFunc(fileName)
    end

    return self.FallbackMap[string.lower(identifier)] or self.FallbackMap.shield
end

-- ====================================================================
-- 4. PENCERE SÜRÜKLEME (SMOOTH DRAGGING)
-- ====================================================================
local function MakeDraggable(dragHandle: GuiObject, targetFrame: GuiObject)
    local dragging = false
    local dragInput = nil
    local dragStart = Vector3.zero
    local startPos = targetFrame.Position

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Animate(targetFrame, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            })
        end
    end)
end

-- ====================================================================
-- 5. KÜTÜPHANE VE BİLDİRİM SİSTEMİ
-- ====================================================================
local Library = {}
Library.__index = Library

local ActiveGui: ScreenGui? = nil
local NotificationContainer: Frame? = nil

local function EnsureScreenGui(): ScreenGui
    if ActiveGui and ActiveGui.Parent then
        return ActiveGui
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "FrostedGlass_Production"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = GetSafeGuiContainer()

    _G.FrostedGlassInstance = gui

    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "NotificationStack"
    notifFrame.Size = UDim2.new(0, 320, 1, -40)
    notifFrame.Position = UDim2.new(1, -24, 1, -24)
    notifFrame.AnchorPoint = Vector2.new(1, 1)
    notifFrame.BackgroundTransparency = 1
    notifFrame.ZIndex = 2000
    notifFrame.Parent = gui

    local list = Instance.new("UIListLayout")
    list.VerticalAlignment = Enum.VerticalAlignment.Bottom
    list.HorizontalAlignment = Enum.HorizontalAlignment.Right
    list.Padding = UDim.new(0, 10)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = notifFrame

    ActiveGui = gui
    NotificationContainer = notifFrame
    return gui
end

function Library:Notify(title: string, text: string, duration: number?, icon: string?, customColor: Color3?)
    duration = duration or 3.5
    local accentColor = customColor or Theme.Accent
    EnsureScreenGui()

    local card = Instance.new("Frame")
    card.Name = "NotificationCard"
    card.Size = UDim2.fromOffset(310, 74)
    card.BackgroundColor3 = Theme.MainBg
    card.BackgroundTransparency = 0.04
    card.Position = UDim2.fromOffset(360, 0)
    card.ZIndex = 2001

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = card

    ApplyGlassStroke(card, 0.78)

    local pill = Instance.new("Frame")
    pill.Size = UDim2.fromOffset(4, 38)
    pill.Position = UDim2.fromOffset(10, 18)
    pill.BackgroundColor3 = accentColor
    pill.ZIndex = 2002
    pill.Parent = card

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(1, 0)
    pillCorner.Parent = pill

    local iconImg = Instance.new("ImageLabel")
    iconImg.Size = UDim2.fromOffset(22, 22)
    iconImg.Position = UDim2.fromOffset(24, 18)
    iconImg.BackgroundTransparency = 1
    iconImg.Image = AssetCache:GetAsset(icon or "shield")
    iconImg.ImageColor3 = accentColor
    iconImg.ZIndex = 2002
    iconImg.Parent = card

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 0, 18)
    titleLabel.Position = UDim2.fromOffset(54, 14)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Theme.FontBold
    titleLabel.Text = tostring(title or "")
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 2002
    titleLabel.Parent = card

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -60, 0, 24)
    descLabel.Position = UDim2.fromOffset(54, 34)
    descLabel.BackgroundTransparency = 1
    descLabel.Font = Theme.FontRegular
    descLabel.Text = tostring(text or "")
    descLabel.TextColor3 = Theme.TextSecondary
    descLabel.TextSize = 12
    descLabel.TextWrapped = true
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.ZIndex = 2002
    descLabel.Parent = card

    local progressTrack = Instance.new("Frame")
    progressTrack.Size = UDim2.new(1, -20, 0, 2)
    progressTrack.Position = UDim2.new(0, 10, 1, -5)
    progressTrack.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    progressTrack.BackgroundTransparency = 0.92
    progressTrack.Parent = card

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.fromScale(1, 1)
    progressBar.BackgroundColor3 = accentColor
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressTrack

    card.Parent = NotificationContainer

    Animate(card, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.fromOffset(0, 0)
    })

    Animate(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.fromScale(0, 1)
    })

    task.delay(duration, function()
        if not card.Parent then return end
        local out = Animate(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.fromOffset(360, 0),
            BackgroundTransparency = 1
        })
        Animate(titleLabel, TweenInfo.new(0.2), { TextTransparency = 1 })
        Animate(descLabel, TweenInfo.new(0.2), { TextTransparency = 1 })
        Animate(iconImg, TweenInfo.new(0.2), { ImageTransparency = 1 })
        Animate(pill, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
        out.Completed:Wait()
        card:Destroy()
    end)
end

-- ====================================================================
-- 6. PENCERE VE SEKME BİLEŞENLERİ (WINDOW & TABS)
-- ====================================================================
function Library:CreateWindow(config: { Title: string?, Bypass: boolean? })
    config = config or {}
    local Title = config.Title or "FROSTED // Sonoma Edition"
    local UseBypass = (config.Bypass ~= nil and config.Bypass) or false

    local screenGui = EnsureScreenGui()

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainWindow"
    mainFrame.Size = UDim2.fromOffset(680, 450)
    mainFrame.Position = UDim2.fromScale(0.5, 0.5)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Theme.MainBg
    mainFrame.BackgroundTransparency = 0
    mainFrame.ClipsDescendants = false
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = mainFrame

    ApplyGlassStroke(mainFrame, 0.82)

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 0.85
    uiScale.Parent = mainFrame

    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 48)
    topBar.BackgroundTransparency = 1
    topBar.Parent = mainFrame

    MakeDraggable(topBar, mainFrame)

    local dotsContainer = Instance.new("Frame")
    dotsContainer.Name = "WindowControls"
    dotsContainer.Size = UDim2.fromOffset(70, 48)
    dotsContainer.Position = UDim2.fromOffset(18, 0)
    dotsContainer.BackgroundTransparency = 1
    dotsContainer.Parent = topBar

    local dotList = Instance.new("UIListLayout")
    dotList.FillDirection = Enum.FillDirection.Horizontal
    dotList.VerticalAlignment = Enum.VerticalAlignment.Center
    dotList.Padding = UDim.new(0, 8)
    dotList.Parent = dotsContainer

    local isWindowVisible = true
    local isMinimized = false
    local bodyContainer: Frame

    local function ToggleVisibility(visible: boolean?)
        if visible ~= nil then
            isWindowVisible = visible
        else
            isWindowVisible = not isWindowVisible
        end

        if isWindowVisible then
            mainFrame.Visible = true
            Animate(uiScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
        else
            local shrink = Animate(uiScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0.75 })
            shrink.Completed:Wait()
            mainFrame.Visible = false
        end
    end

    local function CreateMacDot(color: Color3, callback: () -> ())
        local dot = Instance.new("TextButton")
        dot.Size = UDim2.fromOffset(12, 12)
        dot.BackgroundColor3 = color
        dot.Text = ""
        dot.AutoButtonColor = false
        dot.Parent = dotsContainer

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = dot

        dot.MouseEnter:Connect(function()
            Animate(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(14, 14) })
        end)
        dot.MouseLeave:Connect(function()
            Animate(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(12, 12) })
        end)
        dot.MouseButton1Click:Connect(function()
            Animate(dot, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(9, 9) })
            task.delay(0.1, function()
                Animate(dot, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(12, 12) })
            end)
            callback()
        end)
        return dot
    end

    CreateMacDot(Theme.Danger, function() ToggleVisibility(false) end)
    CreateMacDot(Theme.Warning, function()
        isMinimized = not isMinimized
        if isMinimized then
            Animate(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(680, 48) })
            bodyContainer.Visible = false
        else
            bodyContainer.Visible = true
            Animate(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(680, 450) })
        end
    end)
    CreateMacDot(Theme.Success, function()
        Library:Notify("Sistem Sağlıklı", "Bellek kancaları ve modüller aktif.", 2.5, "shield", Theme.Success)
    end)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -160, 1, 0)
    titleLabel.Position = UDim2.fromOffset(88, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Theme.FontBold
    titleLabel.Text = Title
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = topBar

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.fromOffset(0, 48)
    divider.BackgroundColor3 = Theme.StrokeColor
    divider.BackgroundTransparency = 0.92
    divider.BorderSizePixel = 0
    divider.Parent = topBar

    bodyContainer = Instance.new("Frame")
    bodyContainer.Name = "BodyContainer"
    bodyContainer.Size = UDim2.new(1, 0, 1, -49)
    bodyContainer.Position = UDim2.fromOffset(0, 49)
    bodyContainer.BackgroundTransparency = 1
    bodyContainer.Parent = mainFrame

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 180, 1, 0)
    sidebar.BackgroundColor3 = Theme.SidebarBg
    sidebar.BackgroundTransparency = 0.4
    sidebar.BorderSizePixel = 0
    sidebar.Parent = bodyContainer

    local sidebarCorner = Instance.new("UICorner")
    sidebarCorner.CornerRadius = UDim.new(0, 16)
    sidebarCorner.Parent = sidebar

    local tabButtonsList = Instance.new("ScrollingFrame")
    tabButtonsList.Name = "TabButtons"
    tabButtonsList.Size = UDim2.new(1, -16, 1, -20)
    tabButtonsList.Position = UDim2.fromOffset(8, 10)
    tabButtonsList.BackgroundTransparency = 1
    tabButtonsList.ScrollBarThickness = 0
    tabButtonsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabButtonsList.Parent = sidebar

    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.Padding = UDim.new(0, 6)
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Parent = tabButtonsList

    local pagesFolder = Instance.new("Frame")
    pagesFolder.Name = "Pages"
    pagesFolder.Size = UDim2.new(1, -200, 1, -20)
    pagesFolder.Position = UDim2.fromOffset(190, 10)
    pagesFolder.BackgroundTransparency = 1
    pagesFolder.ClipsDescendants = true
    pagesFolder.Parent = bodyContainer

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
            ToggleVisibility()
        end
    end)

    Animate(uiScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })

    -- %100 OPAK TURUNCU KALKAN BYPASS EKRANI
    if UseBypass then
        local bypassOverlay = Instance.new("Frame")
        bypassOverlay.Name = "CinematicBypass"
        bypassOverlay.Size = UDim2.fromScale(1, 1)
        bypassOverlay.BackgroundColor3 = Theme.MainBg
        bypassOverlay.BackgroundTransparency = 0
        bypassOverlay.ZIndex = 500
        bypassOverlay.Parent = mainFrame

        local bpCorner = Instance.new("UICorner")
        bpCorner.CornerRadius = UDim.new(0, 16)
        bpCorner.Parent = bypassOverlay

        local centerCard = Instance.new("Frame")
        centerCard.Size = UDim2.fromOffset(360, 220)
        centerCard.Position = UDim2.fromScale(0.5, 0.5)
        centerCard.AnchorPoint = Vector2.new(0.5, 0.5)
        centerCard.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
        centerCard.BackgroundTransparency = 0
        centerCard.ZIndex = 501
        centerCard.Parent = bypassOverlay

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 16)
        cardCorner.Parent = centerCard

        ApplyGlassStroke(centerCard, 0.8)

        local shieldIcon = Instance.new("ImageLabel")
        shieldIcon.Name = "BypassShield"
        shieldIcon.Size = UDim2.fromOffset(48, 48)
        shieldIcon.Position = UDim2.fromOffset(180, 48)
        shieldIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        shieldIcon.BackgroundTransparency = 1
        shieldIcon.Image = AssetCache:GetAsset("shield")
        shieldIcon.ImageColor3 = Theme.Orange
        shieldIcon.ZIndex = 502
        shieldIcon.Parent = centerCard

        task.spawn(function()
            while centerCard.Parent do
                Animate(shieldIcon, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Size = UDim2.fromOffset(54, 54) })
                task.wait(0.8)
                Animate(shieldIcon, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Size = UDim2.fromOffset(48, 48) })
                task.wait(0.8)
            end
        end)

        local statusText = Instance.new("TextLabel")
        statusText.Name = "Status"
        statusText.Size = UDim2.new(1, -40, 0, 24)
        statusText.Position = UDim2.fromOffset(20, 92)
        statusText.BackgroundTransparency = 1
        statusText.Font = Theme.FontBold
        statusText.Text = "Bypass Loading..."
        statusText.TextColor3 = Theme.TextPrimary
        statusText.TextSize = 15
        statusText.ZIndex = 502
        statusText.Parent = centerCard

        local barTrack = Instance.new("Frame")
        barTrack.Size = UDim2.new(1, -50, 0, 6)
        barTrack.Position = UDim2.fromOffset(25, 138)
        barTrack.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
        barTrack.ZIndex = 502
        barTrack.Parent = centerCard

        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(1, 0)
        barCorner.Parent = barTrack

        local barFill = Instance.new("Frame")
        barFill.Size = UDim2.fromScale(0.1, 1)
        barFill.BackgroundColor3 = Theme.Orange
        barFill.BorderSizePixel = 0
        barFill.ZIndex = 503
        barFill.Parent = barTrack

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = barFill

        local percentLabel = Instance.new("TextLabel")
        percentLabel.Size = UDim2.fromOffset(60, 20)
        percentLabel.Position = UDim2.fromOffset(180, 162)
        percentLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        percentLabel.BackgroundTransparency = 1
        percentLabel.Font = Theme.FontBold
        percentLabel.Text = "10%"
        percentLabel.TextColor3 = Theme.Orange
        percentLabel.TextSize = 12
        percentLabel.ZIndex = 502
        percentLabel.Parent = centerCard

        task.spawn(function()
            Animate(barFill, TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.fromScale(0.55, 1) })
            percentLabel.Text = "55%"
            task.wait(1.2)

            statusText.Text = "Menu Initializing..."
            Animate(barFill, TweenInfo.new(0.9, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.fromScale(1.0, 1),
                BackgroundColor3 = Theme.Success
            })
            Animate(shieldIcon, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                ImageColor3 = Theme.Success,
                Size = UDim2.fromOffset(56, 56)
            })
            percentLabel.Text = "100%"
            percentLabel.TextColor3 = Theme.Success
            statusText.TextColor3 = Theme.Success
            task.wait(0.8)

            local fade = Animate(bypassOverlay, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
            Animate(centerCard, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Position = UDim2.fromScale(0.5, 0.55),
                BackgroundTransparency = 1
            })
            Animate(statusText, TweenInfo.new(0.2), { TextTransparency = 1 })
            Animate(shieldIcon, TweenInfo.new(0.2), { ImageTransparency = 1 })
            Animate(barTrack, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
            Animate(barFill, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
            Animate(percentLabel, TweenInfo.new(0.2), { TextTransparency = 1 })

            fade.Completed:Wait()
            bypassOverlay:Destroy()

            Library:Notify("Bypass Loaded.", "Menu successfully initialized.", 3.5, "shield", Theme.Success)
        end)
    end

    local Window = {
        Tabs = {},
        CurrentTab = nil
    }

    function Window:CreateTab(name: string, iconIdentifier: string?)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab_" .. name
        tabBtn.Size = UDim2.new(1, 0, 0, 38)
        tabBtn.BackgroundColor3 = Theme.CardBg
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = tabButtonsList

        local tabBtnCorner = Instance.new("UICorner")
        tabBtnCorner.CornerRadius = UDim.new(0, 10)
        tabBtnCorner.Parent = tabBtn

        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.fromOffset(18, 18)
        icon.Position = UDim2.fromOffset(12, 10)
        icon.BackgroundTransparency = 1
        icon.Image = AssetCache:GetAsset(iconIdentifier or "home")
        icon.ImageColor3 = Theme.TextSecondary
        icon.Parent = tabBtn

        local tabLabel = Instance.new("TextLabel")
        tabLabel.Size = UDim2.new(1, -44, 1, 0)
        tabLabel.Position = UDim2.fromOffset(38, 0)
        tabLabel.BackgroundTransparency = 1
        tabLabel.Font = Theme.FontMedium
        tabLabel.Text = name
        tabLabel.TextColor3 = Theme.TextSecondary
        tabLabel.TextSize = 13
        tabLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabLabel.Parent = tabBtn

        local page = Instance.new("ScrollingFrame")
        page.Name = "Page_" .. name
        page.Size = UDim2.fromScale(1, 1)
        page.Position = UDim2.fromOffset(0, 0)
        page.BackgroundTransparency = 1
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Color3.fromRGB(80, 85, 105)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = pagesFolder

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Parent = page

        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingTop = UDim.new(0, 4)
        pagePadding.PaddingBottom = UDim.new(0, 10)
        pagePadding.PaddingLeft = UDim.new(0, 4)
        pagePadding.PaddingRight = UDim.new(0, 8)
        pagePadding.Parent = page

        local Tab = {
            Name = name,
            Page = page,
            Button = tabBtn,
            Label = tabLabel,
            Icon = icon
        }

        local function Select()
            for _, otherTab in ipairs(Window.Tabs) do
                if otherTab ~= Tab then
                    otherTab.Page.Visible = false
                    Animate(otherTab.Button, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
                    Animate(otherTab.Label, TweenInfo.new(0.25), { TextColor3 = Theme.TextSecondary })
                    Animate(otherTab.Icon, TweenInfo.new(0.25), { ImageColor3 = Theme.TextSecondary })
                end
            end

            Window.CurrentTab = Tab
            page.Position = UDim2.fromOffset(0, 12)
            page.Visible = true

            Animate(page, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0) })
            Animate(tabBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.22
            })
            Animate(tabLabel, TweenInfo.new(0.3), { TextColor3 = Theme.TextPrimary })
            Animate(icon, TweenInfo.new(0.3), { ImageColor3 = Theme.TextPrimary })
        end

        tabBtn.MouseButton1Click:Connect(Select)

        tabBtn.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                Animate(tabBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0.88, BackgroundColor3 = Theme.CardHover })
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                Animate(tabBtn, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
            end
        end)

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then
            Select()
        end

        -- ============================================================
        -- SEKME BİLEŞENLERİ (TÜMÜ POLİMORFİK VE HATAYA DAYANIKLI)
        -- ============================================================

        -- 1. AddSection
        function Tab:AddSection(title: any)
            local titleText = tostring(title or "")
            local sectionCard = Instance.new("Frame")
            sectionCard.Name = "Section_" .. titleText
            sectionCard.Size = UDim2.new(1, 0, 0, 30)
            sectionCard.BackgroundTransparency = 1
            sectionCard.Parent = page

            local sectionLabel = Instance.new("TextLabel")
            sectionLabel.Size = UDim2.new(1, -20, 1, 0)
            sectionLabel.Position = UDim2.fromOffset(6, 0)
            sectionLabel.BackgroundTransparency = 1
            sectionLabel.Font = Theme.FontBold
            sectionLabel.Text = string.upper(titleText)
            sectionLabel.TextColor3 = Theme.Accent
            sectionLabel.TextSize = 11
            sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
            sectionLabel.Parent = sectionCard

            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, -12, 0, 1)
            line.Position = UDim2.new(0, 6, 1, -2)
            line.BackgroundColor3 = Theme.StrokeColor
            line.BackgroundTransparency = 0.94
            line.BorderSizePixel = 0
            line.Parent = sectionCard

            return {
                Set = function(_, newTitle: any) sectionLabel.Text = string.upper(tostring(newTitle or "")) end
            }
        end

        -- 2. AddParagraph
        function Tab:AddParagraph(title: any, desc: any)
            local titleText = tostring(title or "")
            local descText = tostring(desc or "")

            local paraCard = Instance.new("Frame")
            paraCard.Name = "Paragraph_" .. titleText
            paraCard.Size = UDim2.new(1, 0, 0, 60)
            paraCard.BackgroundColor3 = Theme.CardBg
            paraCard.BackgroundTransparency = 0.45
            paraCard.Parent = page

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = paraCard
            ApplyGlassStroke(paraCard, 0.9)

            local pTitle = Instance.new("TextLabel")
            pTitle.Size = UDim2.new(1, -28, 0, 20)
            pTitle.Position = UDim2.fromOffset(14, 8)
            pTitle.BackgroundTransparency = 1
            pTitle.Font = Theme.FontBold
            pTitle.Text = titleText
            pTitle.TextColor3 = Theme.TextPrimary
            pTitle.TextSize = 13
            pTitle.TextXAlignment = Enum.TextXAlignment.Left
            pTitle.Parent = paraCard

            local pDesc = Instance.new("TextLabel")
            pDesc.Size = UDim2.new(1, -28, 0, 26)
            pDesc.Position = UDim2.fromOffset(14, 28)
            pDesc.BackgroundTransparency = 1
            pDesc.Font = Theme.FontRegular
            pDesc.Text = descText
            pDesc.TextColor3 = Theme.TextMuted
            pDesc.TextSize = 11
            pDesc.TextWrapped = true
            pDesc.TextXAlignment = Enum.TextXAlignment.Left
            pDesc.Parent = paraCard

            return {
                Set = function(_, newTitle: any, newDesc: any)
                    pTitle.Text = tostring(newTitle or "")
                    pDesc.Text = tostring(newDesc or "")
                end
            }
        end

        -- 3. AddLabel
        function Tab:AddLabel(text: any, iconIdent: string?)
            local labelText = tostring(text or "")
            local labelCard = Instance.new("Frame")
            labelCard.Size = UDim2.new(1, 0, 0, 38)
            labelCard.BackgroundColor3 = Theme.CardBg
            labelCard.BackgroundTransparency = 0.45
            labelCard.Parent = page

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = labelCard
            ApplyGlassStroke(labelCard, 0.9)

            local offsetLeft = 14
            if iconIdent then
                local iconImg = Instance.new("ImageLabel")
                iconImg.Size = UDim2.fromOffset(18, 18)
                iconImg.Position = UDim2.fromOffset(12, 10)
                iconImg.BackgroundTransparency = 1
                iconImg.Image = AssetCache:GetAsset(iconIdent)
                iconImg.ImageColor3 = Theme.Accent
                iconImg.Parent = labelCard
                offsetLeft = 38
            end

            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, -offsetLeft - 10, 1, 0)
            textLabel.Position = UDim2.fromOffset(offsetLeft, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Font = Theme.FontMedium
            textLabel.Text = labelText
            textLabel.TextColor3 = Theme.TextSecondary
            textLabel.TextSize = 13
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.Parent = labelCard

            return {
                Set = function(_, newText: any) textLabel.Text = tostring(newText or "") end
            }
        end

        -- 4. AddButton
        function Tab:AddButton(text: any, callback: any, iconIdent: string?)
            local btnText = tostring(text or "")
            local cb = (type(callback) == "function" and callback) or function() end

            local btnCard = Instance.new("TextButton")
            btnCard.Size = UDim2.new(1, 0, 0, 42)
            btnCard.BackgroundColor3 = Theme.CardBg
            btnCard.BackgroundTransparency = 0.45
            btnCard.Text = ""
            btnCard.AutoButtonColor = false
            btnCard.Parent = page

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = btnCard
            ApplyGlassStroke(btnCard, 0.88)

            local btnScale = Instance.new("UIScale")
            btnScale.Scale = 1
            btnScale.Parent = btnCard

            local offsetLeft = 14
            if iconIdent then
                local iconImg = Instance.new("ImageLabel")
                iconImg.Size = UDim2.fromOffset(18, 18)
                iconImg.Position = UDim2.fromOffset(12, 12)
                iconImg.BackgroundTransparency = 1
                iconImg.Image = AssetCache:GetAsset(iconIdent)
                iconImg.ImageColor3 = Theme.Accent
                iconImg.Parent = btnCard
                offsetLeft = 38
            end

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -offsetLeft - 36, 1, 0)
            label.Position = UDim2.fromOffset(offsetLeft, 0)
            label.BackgroundTransparency = 1
            label.Font = Theme.FontMedium
            label.Text = btnText
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = btnCard

            local glyph = Instance.new("TextLabel")
            glyph.Size = UDim2.fromOffset(20, 20)
            glyph.Position = UDim2.new(1, -28, 0.5, 0)
            glyph.AnchorPoint = Vector2.new(0, 0.5)
            glyph.BackgroundTransparency = 1
            glyph.Font = Theme.FontBold
            glyph.Text = "→"
            glyph.TextColor3 = Theme.TextMuted
            glyph.TextSize = 14
            glyph.Parent = btnCard

            btnCard.MouseEnter:Connect(function()
                Animate(btnCard, TweenInfo.new(0.2), { BackgroundColor3 = Theme.CardHover, BackgroundTransparency = 0.35 })
                Animate(glyph, TweenInfo.new(0.2), { Position = UDim2.new(1, -24, 0.5, 0), TextColor3 = Theme.TextPrimary })
            end)
            btnCard.MouseLeave:Connect(function()
                Animate(btnCard, TweenInfo.new(0.2), { BackgroundColor3 = Theme.CardBg, BackgroundTransparency = 0.45 })
                Animate(glyph, TweenInfo.new(0.2), { Position = UDim2.new(1, -28, 0.5, 0), TextColor3 = Theme.TextMuted })
            end)
            btnCard.MouseButton1Down:Connect(function()
                Animate(btnScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { Scale = 0.96 })
            end)
            btnCard.MouseButton1Up:Connect(function()
                Animate(btnScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
                task.spawn(function() pcall(cb) end)
            end)

            return btnCard
        end

        -- 5. AddToggle (Polimorfik Argüman Koruması)
        function Tab:AddToggle(title: any, arg2: any, arg3: any)
            local toggleTitle = tostring(title or "")
            local state = false
            local cb = function(_: boolean) end

            if type(arg2) == "function" then
                cb = arg2
                state = false
            elseif type(arg2) == "boolean" then
                state = arg2
                if type(arg3) == "function" then
                    cb = arg3
                end
            else
                if type(arg3) == "function" then
                    cb = arg3
                end
            end

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 44)
            card.BackgroundColor3 = Theme.CardBg
            card.BackgroundTransparency = 0.45
            card.Parent = page

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = card
            ApplyGlassStroke(card, 0.88)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -80, 1, 0)
            label.Position = UDim2.fromOffset(14, 0)
            label.BackgroundTransparency = 1
            label.Font = Theme.FontMedium
            label.Text = toggleTitle
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = card

            local switch = Instance.new("TextButton")
            switch.Size = UDim2.fromOffset(46, 26)
            switch.Position = UDim2.new(1, -58, 0.5, 0)
            switch.AnchorPoint = Vector2.new(0, 0.5)
            switch.BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(45, 50, 65)
            switch.Text = ""
            switch.AutoButtonColor = false
            switch.Parent = card

            local switchCorner = Instance.new("UICorner")
            switchCorner.CornerRadius = UDim.new(1, 0)
            switchCorner.Parent = switch

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(20, 20)
            knob.Position = state and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
            knob.AnchorPoint = Vector2.new(0, 0.5)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.Parent = switch

            local knobCorner = Instance.new("UICorner")
            knobCorner.CornerRadius = UDim.new(1, 0)
            knobCorner.Parent = knob

            local function UpdateToggle(newState: boolean)
                state = newState
                local targetPos = state and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                local targetColor = state and Theme.Accent or Color3.fromRGB(45, 50, 65)

                Animate(knob, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(24, 20) })
                task.delay(0.08, function()
                    Animate(knob, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Position = targetPos,
                        Size = UDim2.fromOffset(20, 20)
                    })
                end)
                Animate(switch, TweenInfo.new(0.3), { BackgroundColor3 = targetColor })
                task.spawn(function() pcall(cb, state) end)
            end

            switch.MouseButton1Click:Connect(function() UpdateToggle(not state) end)

            return {
                Set = function(_, val: boolean) UpdateToggle(val) end,
                Value = state
            }
        end

        -- 6. AddSlider (Polimorfik Argüman Koruması)
        function Tab:AddSlider(title: any, min: any, max: any, arg4: any, arg5: any, arg6: any)
            local sliderTitle = tostring(title or "")
            local minVal = tonumber(min) or 0
            local maxVal = tonumber(max) or 100
            local stepSize = 1
            local value = minVal
            local cb = function(_: number) end

            if type(arg4) == "function" then
                cb = arg4
                value = minVal
            elseif type(arg5) == "function" then
                cb = arg5
                value = tonumber(arg4) or minVal
            elseif type(arg6) == "function" then
                cb = arg6
                value = tonumber(arg4) or minVal
                stepSize = tonumber(arg5) or 1
            else
                if type(arg4) == "number" then value = arg4 end
                if type(arg5) == "number" then stepSize = arg5 end
            end

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 56)
            card.BackgroundColor3 = Theme.CardBg
            card.BackgroundTransparency = 0.45
            card.Parent = page

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = card
            ApplyGlassStroke(card, 0.88)

            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, -80, 0, 24)
            titleLabel.Position = UDim2.fromOffset(14, 8)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Font = Theme.FontMedium
            titleLabel.Text = sliderTitle
            titleLabel.TextColor3 = Theme.TextPrimary
            titleLabel.TextSize = 13
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.Parent = card

            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.fromOffset(60, 24)
            valueLabel.Position = UDim2.new(1, -74, 0, 8)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Font = Theme.FontBold
            valueLabel.Text = tostring(value)
            valueLabel.TextColor3 = Theme.Accent
            valueLabel.TextSize = 13
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Parent = card

            local track = Instance.new("TextButton")
            track.Size = UDim2.new(1, -28, 0, 6)
            track.Position = UDim2.fromOffset(14, 38)
            track.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
            track.Text = ""
            track.AutoButtonColor = false
            track.Parent = card

            local trackCorner = Instance.new("UICorner")
            trackCorner.CornerRadius = UDim.new(1, 0)
            trackCorner.Parent = track

            local initialPct = math.clamp((value - minVal) / (maxVal - minVal), 0, 1)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.fromScale(initialPct, 1)
            fill.BackgroundColor3 = Theme.Accent
            fill.BorderSizePixel = 0
            fill.Parent = track

            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(1, 0)
            fillCorner.Parent = fill

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(14, 14)
            knob.Position = UDim2.new(1, 0, 0.5, 0)
            knob.AnchorPoint = Vector2.new(0, 0.5)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.Parent = fill

            local knobCorner = Instance.new("UICorner")
            knobCorner.CornerRadius = UDim.new(1, 0)
            knobCorner.Parent = knob

            local dragging = false

            local function CalculateValue(inputX: number)
                local pct = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local rawVal = minVal + (maxVal - minVal) * pct
                value = math.floor((rawVal / stepSize) + 0.5) * stepSize
                value = math.clamp(value, minVal, maxVal)
                
                valueLabel.Text = tostring(value)
                local fillPct = (value - minVal) / (maxVal - minVal)
                Animate(fill, TweenInfo.new(0.05, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(fillPct, 1) })
                task.spawn(function() pcall(cb, value) end)
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    Animate(knob, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(18, 18) })
                    CalculateValue(input.Position.X)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if dragging then
                        dragging = false
                        Animate(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(14, 14) })
                    end
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    CalculateValue(input.Position.X)
                end
            end)

            return {
                Set = function(_, newVal: number)
                    value = math.clamp(newVal, minVal, maxVal)
                    valueLabel.Text = tostring(value)
                    local pct = (value - minVal) / (maxVal - minVal)
                    Animate(fill, TweenInfo.new(0.2), { Size = UDim2.fromScale(pct, 1) })
                    pcall(cb, value)
                end,
                Value = value
            }
        end

        -- 7. AddDropdown (HATANIN DÜZELTİLDİĞİ POLİMORFİK VE KESİN ÇÖZÜM!)
        function Tab:AddDropdown(title: any, options: any, defaultOrCallback: any, callbackOpt: any)
            local dropTitle = tostring(title or "")
            local optList = (type(options) == "table" and options) or {}
            local cb = function(_: string) end
            local selectedOption = ""

            -- Parametre Algılama: 3 parametreli mi yoksa 4 parametreli mi çağrıldı?
            if type(defaultOrCallback) == "function" then
                cb = defaultOrCallback
                selectedOption = tostring(optList[1] or "Seçiniz...")
            elseif type(defaultOrCallback) == "string" then
                selectedOption = defaultOrCallback
                if type(callbackOpt) == "function" then
                    cb = callbackOpt
                end
            else
                selectedOption = tostring(optList[1] or "Seçiniz...")
                if type(callbackOpt) == "function" then
                    cb = callbackOpt
                end
            end

            local isOpen = false

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 42)
            card.BackgroundColor3 = Theme.CardBg
            card.BackgroundTransparency = 0.45
            card.ClipsDescendants = true
            card.Parent = page

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = card
            ApplyGlassStroke(card, 0.88)

            local header = Instance.new("TextButton")
            header.Size = UDim2.new(1, 0, 0, 42)
            header.BackgroundTransparency = 1
            header.Text = ""
            header.AutoButtonColor = false
            header.Parent = card

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.5, 0, 1, 0)
            label.Position = UDim2.fromOffset(14, 0)
            label.BackgroundTransparency = 1
            label.Font = Theme.FontMedium
            label.Text = dropTitle
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = header

            local currentLabel = Instance.new("TextLabel")
            currentLabel.Size = UDim2.new(0.5, -46, 1, 0)
            currentLabel.Position = UDim2.new(0.5, 0, 0, 0)
            currentLabel.BackgroundTransparency = 1
            currentLabel.Font = Theme.FontMedium
            currentLabel.Text = tostring(selectedOption) -- Asla fonksiyona atanmaz, garantili string
            currentLabel.TextColor3 = Theme.Accent
            currentLabel.TextSize = 12
            currentLabel.TextXAlignment = Enum.TextXAlignment.Right
            currentLabel.Parent = header

            local chevron = Instance.new("ImageLabel")
            chevron.Size = UDim2.fromOffset(16, 16)
            chevron.Position = UDim2.new(1, -28, 0.5, 0)
            chevron.AnchorPoint = Vector2.new(0, 0.5)
            chevron.BackgroundTransparency = 1
            chevron.Image = AssetCache:GetAsset("chevron")
            chevron.ImageColor3 = Theme.TextSecondary
            chevron.Parent = header

            local optionsContainer = Instance.new("Frame")
            optionsContainer.Size = UDim2.new(1, -16, 0, 0)
            optionsContainer.Position = UDim2.fromOffset(8, 46)
            optionsContainer.BackgroundTransparency = 1
            optionsContainer.Parent = card

            local optLayout = Instance.new("UIListLayout")
            optLayout.Padding = UDim.new(0, 4)
            optLayout.SortOrder = Enum.SortOrder.LayoutOrder
            optLayout.Parent = optionsContainer

            local function UpdateDropdownVisuals()
                currentLabel.Text = tostring(selectedOption)
                for _, ch in ipairs(optionsContainer:GetChildren()) do
                    if ch:IsA("TextButton") then
                        local optLabel = ch:FindFirstChildOfClass("TextLabel")
                        local isSelected = (ch.Name == "Option_" .. selectedOption)
                        if optLabel then
                            Animate(optLabel, TweenInfo.new(0.2), {
                                TextColor3 = isSelected and Theme.Accent or Theme.TextSecondary
                            })
                            optLabel.Font = isSelected and Theme.FontBold or Theme.FontRegular
                        end
                        Animate(ch, TweenInfo.new(0.2), {
                            BackgroundColor3 = isSelected and Color3.fromRGB(0, 122, 255) or Color3.fromRGB(34, 40, 52),
                            BackgroundTransparency = isSelected and 0.25 or 0.55
                        })
                    end
                end
            end

            local function Populate()
                for _, ch in ipairs(optionsContainer:GetChildren()) do
                    if ch:IsA("TextButton") then ch:Destroy() end
                end

                for idx, optText in ipairs(optList) do
                    local optStr = tostring(optText)
                    local isSelected = (optStr == selectedOption)
                    local optBtn = Instance.new("TextButton")
                    optBtn.Name = "Option_" .. optStr
                    optBtn.Size = UDim2.new(1, 0, 0, 32)
                    optBtn.BackgroundColor3 = isSelected and Color3.fromRGB(0, 122, 255) or Color3.fromRGB(34, 40, 52)
                    optBtn.BackgroundTransparency = isSelected and 0.25 or 0.55
                    optBtn.Text = ""
                    optBtn.AutoButtonColor = false
                    optBtn.LayoutOrder = idx
                    optBtn.Parent = optionsContainer

                    local optCorner = Instance.new("UICorner")
                    optCorner.CornerRadius = UDim.new(0, 8)
                    optCorner.Parent = optBtn

                    local optLabel = Instance.new("TextLabel")
                    optLabel.Size = UDim2.new(1, -20, 1, 0)
                    optLabel.Position = UDim2.fromOffset(10, 0)
                    optLabel.BackgroundTransparency = 1
                    optLabel.Font = isSelected and Theme.FontBold or Theme.FontRegular
                    optLabel.Text = optStr
                    optLabel.TextColor3 = isSelected and Theme.Accent or Theme.TextSecondary
                    optLabel.TextSize = 12
                    optLabel.TextXAlignment = Enum.TextXAlignment.Left
                    optLabel.Parent = optBtn

                    optBtn.MouseButton1Click:Connect(function()
                        selectedOption = optStr
                        UpdateDropdownVisuals()
                        isOpen = false
                        Animate(chevron, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Rotation = 0 })
                        Animate(card, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 42) })
                        task.spawn(function() pcall(cb, selectedOption) end)
                    end)
                end
            end

            Populate()

            header.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                local targetHeight = isOpen and (48 + (#optList * 36) + 8) or 42
                Animate(chevron, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Rotation = isOpen and 180 or 0 })
                Animate(card, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, targetHeight) })
            end)

            return {
                Set = function(_, opt: any)
                    selectedOption = tostring(opt)
                    UpdateDropdownVisuals()
                    pcall(cb, selectedOption)
                end,
                Refresh = function(_, newOpts: any)
                    optList = (type(newOpts) == "table" and newOpts) or {}
                    Populate()
                end
            }
        end

        -- 8. AddTextInput
        function Tab:AddTextInput(title: any, placeholderOrCallback: any, callbackOpt: any)
            local inputTitle = tostring(title or "")
            local placeholderText = "Yazınız..."
            local cb = function(_: string) end

            if type(placeholderOrCallback) == "function" then
                cb = placeholderOrCallback
            elseif type(placeholderOrCallback) == "string" then
                placeholderText = placeholderOrCallback
                if type(callbackOpt) == "function" then
                    cb = callbackOpt
                end
            else
                if type(callbackOpt) == "function" then
                    cb = callbackOpt
                end
            end

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 44)
            card.BackgroundColor3 = Theme.CardBg
            card.BackgroundTransparency = 0.45
            card.Parent = page

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = card

            local stroke = ApplyGlassStroke(card, 0.88)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.45, 0, 1, 0)
            label.Position = UDim2.fromOffset(14, 0)
            label.BackgroundTransparency = 1
            label.Font = Theme.FontMedium
            label.Text = inputTitle
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = card

            local inputContainer = Instance.new("Frame")
            inputContainer.Size = UDim2.new(0.5, -14, 0, 28)
            inputContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
            inputContainer.AnchorPoint = Vector2.new(0, 0.5)
            inputContainer.BackgroundColor3 = Color3.fromRGB(36, 42, 56)
            inputContainer.Parent = card

            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, 6)
            inputCorner.Parent = inputContainer

            local textBox = Instance.new("TextBox")
            textBox.Size = UDim2.new(1, -16, 1, 0)
            textBox.Position = UDim2.fromOffset(8, 0)
            textBox.BackgroundTransparency = 1
            textBox.Font = Theme.FontRegular
            textBox.PlaceholderText = placeholderText
            textBox.PlaceholderColor3 = Theme.TextMuted
            textBox.Text = ""
            textBox.TextColor3 = Theme.TextPrimary
            textBox.TextSize = 12
            textBox.ClearTextOnFocus = false
            textBox.Parent = inputContainer

            textBox.Focused:Connect(function()
                Animate(inputContainer, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(45, 52, 70) })
                stroke.Color = Theme.Accent
                stroke.Transparency = 0.4
            end)

            textBox.FocusLost:Connect(function()
                Animate(inputContainer, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(36, 42, 56) })
                stroke.Color = Theme.StrokeColor
                stroke.Transparency = Theme.StrokeTransparency
                task.spawn(function() pcall(cb, textBox.Text) end)
            end)

            return {
                Set = function(_, newText: any)
                    textBox.Text = tostring(newText or "")
                    pcall(cb, textBox.Text)
                end,
                Get = function(_) return textBox.Text end
            }
        end

        -- 9. AddColorPicker
        function Tab:AddColorPicker(title: any, defaultColorOrCallback: any, callbackOpt: any)
            local cpTitle = tostring(title or "")
            local currentColor = Color3.fromRGB(0, 122, 255)
            local cb = function(_: Color3) end

            if type(defaultColorOrCallback) == "function" then
                cb = defaultColorOrCallback
            elseif typeof(defaultColorOrCallback) == "Color3" then
                currentColor = defaultColorOrCallback
                if type(callbackOpt) == "function" then
                    cb = callbackOpt
                end
            else
                if type(callbackOpt) == "function" then
                    cb = callbackOpt
                end
            end

            local isOpen = false

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 44)
            card.BackgroundColor3 = Theme.CardBg
            card.BackgroundTransparency = 0.45
            card.ClipsDescendants = true
            card.Parent = page

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = card
            ApplyGlassStroke(card, 0.88)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -70, 0, 44)
            label.Position = UDim2.fromOffset(14, 0)
            label.BackgroundTransparency = 1
            label.Font = Theme.FontMedium
            label.Text = cpTitle
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = card

            local previewBtn = Instance.new("TextButton")
            previewBtn.Size = UDim2.fromOffset(36, 22)
            previewBtn.Position = UDim2.new(1, -48, 0, 11)
            previewBtn.BackgroundColor3 = currentColor
            previewBtn.Text = ""
            previewBtn.AutoButtonColor = false
            previewBtn.Parent = card

            local prevCorner = Instance.new("UICorner")
            prevCorner.CornerRadius = UDim.new(0, 6)
            prevCorner.Parent = previewBtn

            local paletteFrame = Instance.new("Frame")
            paletteFrame.Size = UDim2.new(1, -28, 0, 40)
            paletteFrame.Position = UDim2.fromOffset(14, 48)
            paletteFrame.BackgroundTransparency = 1
            paletteFrame.Parent = card

            local presets = {
                Color3.fromRGB(255, 69, 58),
                Color3.fromRGB(255, 149, 0),
                Color3.fromRGB(255, 214, 10),
                Color3.fromRGB(52, 199, 89),
                Color3.fromRGB(0, 122, 255),
                Color3.fromRGB(175, 82, 222),
                Color3.fromRGB(255, 255, 255)
            }

            local pList = Instance.new("UIListLayout")
            pList.FillDirection = Enum.FillDirection.Horizontal
            pList.HorizontalAlignment = Enum.HorizontalAlignment.Center
            pList.Padding = UDim.new(0, 10)
            pList.Parent = paletteFrame

            for _, colorItem in ipairs(presets) do
                local pBtn = Instance.new("TextButton")
                pBtn.Size = UDim2.fromOffset(28, 28)
                pBtn.BackgroundColor3 = colorItem
                pBtn.Text = ""
                pBtn.AutoButtonColor = false
                pBtn.Parent = paletteFrame

                local pCorn = Instance.new("UICorner")
                pCorn.CornerRadius = UDim.new(1, 0)
                pCorn.Parent = pBtn

                pBtn.MouseButton1Click:Connect(function()
                    currentColor = colorItem
                    previewBtn.BackgroundColor3 = currentColor
                    isOpen = false
                    Animate(card, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 44) })
                    task.spawn(function() pcall(cb, currentColor) end)
                end)
            end

            previewBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                local targetH = isOpen and 96 or 44
                Animate(card, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, targetH) })
            end)

            return {
                Set = function(_, col: Color3)
                    currentColor = col
                    previewBtn.BackgroundColor3 = currentColor
                    pcall(cb, currentColor)
                end,
                Value = currentColor
            }
        end

        -- 10. AddKeybind
        function Tab:AddKeybind(title: any, arg2: any, arg3: any)
            local kbTitle = tostring(title or "")
            local boundKey = Enum.KeyCode.E
            local cb = function(_: Enum.KeyCode) end

            if type(arg2) == "function" then
                cb = arg2
            elseif typeof(arg2) == "EnumItem" then
                boundKey = arg2
                if type(arg3) == "function" then
                    cb = arg3
                end
            else
                if type(arg3) == "function" then
                    cb = arg3
                end
            end

            local isListening = false

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 44)
            card.BackgroundColor3 = Theme.CardBg
            card.BackgroundTransparency = 0.45
            card.Parent = page

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = card
            ApplyGlassStroke(card, 0.88)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -110, 1, 0)
            label.Position = UDim2.fromOffset(14, 0)
            label.BackgroundTransparency = 1
            label.Font = Theme.FontMedium
            label.Text = kbTitle
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = card

            local keyBtn = Instance.new("TextButton")
            keyBtn.Size = UDim2.fromOffset(80, 26)
            keyBtn.Position = UDim2.new(1, -94, 0.5, 0)
            keyBtn.AnchorPoint = Vector2.new(0, 0.5)
            keyBtn.BackgroundColor3 = Color3.fromRGB(38, 43, 56)
            keyBtn.Font = Theme.FontBold
            keyBtn.Text = boundKey.Name
            keyBtn.TextColor3 = Theme.Accent
            keyBtn.TextSize = 11
            keyBtn.AutoButtonColor = false
            keyBtn.Parent = card

            local keyCorner = Instance.new("UICorner")
            keyCorner.CornerRadius = UDim.new(0, 6)
            keyCorner.Parent = keyBtn

            local stroke = ApplyGlassStroke(keyBtn, 0.8)

            keyBtn.MouseButton1Click:Connect(function()
                if isListening then return end
                isListening = true
                keyBtn.Text = "..."
                stroke.Color = Theme.Accent

                local conn: RBXScriptConnection
                conn = UserInputService.InputBegan:Connect(function(input, gpe)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.Escape then
                            boundKey = input.KeyCode
                        end
                        keyBtn.Text = boundKey.Name
                        stroke.Color = Theme.StrokeColor
                        isListening = false
                        conn:Disconnect()
                    end
                end)
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if not gpe and not isListening and input.KeyCode == boundKey then
                    if UserInputService:GetFocusedTextBox() == nil then
                        task.spawn(function() pcall(cb, boundKey) end)
                    end
                end
            end)

            return {
                Set = function(_, newKey: Enum.KeyCode)
                    boundKey = newKey
                    keyBtn.Text = boundKey.Name
                end,
                Key = boundKey
            }
        end

        return Tab
    end

    return Window
end

-- ====================================================================
-- TEMİZ KÜTÜPHANE İHRACI (SAF KÜTÜPHANE)
-- ====================================================================
return Library
