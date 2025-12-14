--[[
    v-severe UI Library
    "The Best" - Secure, Optimized, Beautiful
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Types
type Theme = {
    Main: Color3,
    Secondary: Color3,
    Accent: Color3,
    Text: Color3,
    Outline: Color3
}

-- Library Object
local Library = {
    Connections = {},
    Flags = {},
    Theme = {
        Main = Color3.fromRGB(24, 24, 24),
        Secondary = Color3.fromRGB(32, 32, 32),
        Accent = Color3.fromRGB(0, 150, 255),
        Text = Color3.fromRGB(240, 240, 240),
        DarkText = Color3.fromRGB(150, 150, 150),
        Outline = Color3.fromRGB(50, 50, 50),
    } :: Theme,
    Font = "UI",
    Open = true,
}

-- Utility Functions
local Utility = {}

function Utility:Connect(signal: RBXScriptSignal, callback: (...any) -> ())
    local connection = signal:Connect(callback)
    table.insert(Library.Connections, connection)
    return connection
end

function Utility:Disconnect()
    for _, connection in ipairs(Library.Connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    Library.Connections = {}
end

function Utility:GetTextSize(text: string, size: number, font: Enum.Font?): Vector2
    -- Fallback/Simulation since Drawing doesn't have native GetTextBounds that accepts these exactly
    -- But since we are using Drawing library, we might need a specific handling.
    -- v-severe DrawingLib has GetTextBounds(font: string, size: number, text: string)
    if Drawing.GetTextBounds then
        return Drawing.GetTextBounds(Library.Font, size, text)
    else
        -- Fallback if not using v-severe environment or testing in Studio
        return TextService:GetTextSize(text, size, font or Enum.Font.SourceSans, Vector2.new(1000, 1000))
    end
end

function Utility:Lerp(a: number, b: number, t: number): number
    return a + (b - a) * t
end

function Utility:LerpColor(a: Color3, b: Color3, t: number): Color3
    return a:Lerp(b, t)
end

function Utility:ShiftColor(c: Color3, amount: number): Color3
    local h, s, v = c:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v + amount, 0, 1))
end

function Utility:IsMouseOver(pos: Vector2, size: Vector2): boolean
    local mPos = UserInputService:GetMouseLocation()
    return mPos.X >= pos.X and mPos.X <= pos.X + size.X
       and mPos.Y >= pos.Y and mPos.Y <= pos.Y + size.Y
end

-- Drawing Wrapper (Pooling & Management)
local DrawingLib = {}
local DrawCache = {}

function DrawingLib:Create(type: string, properties: table)
    local draw = Drawing.new(type)
    for k, v in pairs(properties) do
        draw[k] = v
    end
    table.insert(DrawCache, draw)
    return draw
end

function Library:Unload()
    Utility:Disconnect()
    for _, draw in ipairs(DrawCache) do
        draw:Remove()
    end
    DrawCache = {}
end

-- Input Handling
local Input = {
    Keys = {},
    Mouse = {
        Left = false,
        Right = false
    }
}

Utility:Connect(UserInputService.InputBegan, function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Input.Mouse.Left = true
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        Input.Mouse.Right = true
    elseif input.UserInputType == Enum.UserInputType.Keyboard then
        Input.Keys[input.KeyCode] = true
    end
end)

Utility:Connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Input.Mouse.Left = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        Input.Mouse.Right = false
    elseif input.UserInputType == Enum.UserInputType.Keyboard then
        Input.Keys[input.KeyCode] = nil
    end
end)

-- Main Window Class
local Window = {}
Window.__index = Window

function Library:CreateWindow(options: { Title: string, Size: Vector2? })
    local window = setmetatable({}, Window)
    
    window.Title = options.Title or "UI Library"
    window.Size = options.Size or Vector2.new(500, 350)
    window.Position = Vector2.new(100, 100)
    window.Tabs = {}
    window.ActiveTab = nil
    
    -- Visual Elements
    window.MainRect = DrawingLib:Create("Square", {
        Size = window.Size,
        Position = window.Position,
        Color = Library.Theme.Main,
        Filled = true,
        Thickness = 1,
        Visible = true,
        Rounding = 4 -- Using rounded corners if supported by Square/Quad
    })
    
    window.Border = DrawingLib:Create("Square", {
        Size = window.Size,
        Position = window.Position,
        Color = Library.Theme.Outline,
        Filled = false,
        Thickness = 2,
        Visible = true,
        Rounding = 4
    })
    
    window.TitleLabel = DrawingLib:Create("Text", {
        Text = window.Title,
        Position = window.Position + Vector2.new(10, 8),
        Size = 18,
        Color = Library.Theme.Text,
        Outline = true,
        OutlineColor = Color3.new(0,0,0),
        Visible = true,
        Font = 2 -- Standard font
    })

    -- Container for Tabs (Sidebar/Top)
    window.TabsContainer = DrawingLib:Create("Square", {
        Size = Vector2.new(window.Size.X - 20, 30),
        Position = window.Position + Vector2.new(10, 30),
        Color = Color3.new(0,0,0), -- Transparent filler
        Filled = false,
        Visible = false -- Logical container mainly
    })

    -- Dragging Logic
    local dragging = false
    local dragStart = Vector2.new()
    local startPos = Vector2.new()

    Utility:Connect(UserInputService.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if Utility:IsMouseOver(window.Position, Vector2.new(window.Size.X, 30)) then -- Drag via title bar
                dragging = true
                dragStart = UserInputService:GetMouseLocation()
                startPos = window.Position
            end
        end
    end)

    Utility:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    Utility:Connect(RunService.RenderStepped, function()
        if dragging then
            local delta = UserInputService:GetMouseLocation() - dragStart
            window.Position = startPos + delta
        end

        -- Update UI Positions
        window.MainRect.Position = window.Position
        window.Border.Position = window.Position
        window.TitleLabel.Position = window.Position + Vector2.new(10, 8)
        
        -- Update Layout of active elements
        window:UpdateLayout()
        
        -- Update Tabs
        local tabX = window.Position.X + 10
        for i, tab in ipairs(window.Tabs) do
            tab.Button.Position = Vector2.new(tabX, window.Position.Y + 35)
            tab.Label.Position = tab.Button.Position + Vector2.new(tab.Button.Size.X / 2, 6) -- Centered Text
            
            -- Simple hover effect
            if Utility:IsMouseOver(tab.Button.Position, tab.Button.Size) then
                tab.Button.Color = Utility:LerpColor(tab.Button.Color, Utility:ShiftColor(Library.Theme.Secondary, 0.1), 0.2)
            elseif window.ActiveTab == tab then
                 tab.Button.Color = Library.Theme.Accent -- Selected
            else
                 tab.Button.Color = Library.Theme.Secondary -- Default
            end
            
            tabX = tabX + tab.Button.Size.X + 5
        end
    end)

    return window
end

function Window:CreateTab(name: string)
    local tab = {
        Name = name,
        Elements = {},
        ParentWindow = self
    }
    
    local textSize = Utility:GetTextSize(name, 16, Enum.Font.SourceSans)
    local buttonSize = Vector2.new(textSize.X + 20, 25)
    
    tab.Button = DrawingLib:Create("Square", {
        Size = buttonSize,
        Position = Vector2.new(0,0), -- Updated in render loop
        Color = Library.Theme.Secondary,
        Filled = true,
        Rounding = 4,
        Visible = true
    })
    
    tab.Label = DrawingLib:Create("Text", {
        Text = name,
        Size = 16,
        Center = true,
        Color = Library.Theme.Text,
        Outline = true,
        Visible = true
    })
    
    -- Interaction
    Utility:Connect(UserInputService.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if Utility:IsMouseOver(tab.Button.Position, tab.Button.Size) then
                self.ActiveTab = tab
                -- Update visibility
                for _, t in ipairs(self.Tabs) do
                    local visible = (t == tab)
                    for _, elem in ipairs(t.Elements) do
                        if elem.SetVisible then elem:SetVisible(visible) end
                    end
                end
            end
        end
    end)
    
    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then self.ActiveTab = tab end
    
    return tab
end

-- Base Element Class Logic (Shared helpers)
local function CreateBaseElement(tab, sizeY)
    local elem = {
        Visible = (tab.ParentWindow.ActiveTab == tab),
        Position = Vector2.new(0,0), -- Calculated
        Size = Vector2.new(tab.ParentWindow.Size.X - 40, sizeY),
        ParentTab = tab
    }
    
    function elem:SetVisible(vis)
        elem.Visible = vis
        if elem.Visuals then
            for _, v in pairs(elem.Visuals) do
                if v.Visible ~= nil then v.Visible = vis end
            end
        end
    end
    
    table.insert(tab.Elements, elem)
    return elem
end

function Window:UpdateLayout()
    -- Recalculate positions for active tab elements
    if not self.ActiveTab then return end
    
    local currentY = self.Position.Y + 70 -- Header + Tabs offset
    local startX = self.Position.X + 20
    
    for _, elem in ipairs(self.ActiveTab.Elements) do
        elem.Position = Vector2.new(startX, currentY)
        if elem.Update then elem:Update() end
        currentY = currentY + elem.Size.Y + 5 -- Padding
    end
end

-- Button Component
function Window:CreateButton(tab, text, callback)
    local button = CreateBaseElement(tab, 30)
    button.Callback = callback or function() end
    
    button.Visuals = {
        Main = DrawingLib:Create("Square", {
            Filled = true,
            Color = Library.Theme.Secondary,
            Rounding = 4,
            Visible = button.Visible
        }),
        Label = DrawingLib:Create("Text", {
            Text = text,
            Size = 14,
            Center = true,
            Color = Library.Theme.Text,
            Outline = true,
            Visible = button.Visible
        })
    }
    
    function button:Update()
        self.Visuals.Main.Size = self.Size
        self.Visuals.Main.Position = self.Position
        self.Visuals.Label.Position = self.Position + Vector2.new(self.Size.X/2, 8)
        
        -- Animation/Interaction
        if self.Visible then
            if Utility:IsMouseOver(self.Position, self.Size) then
                self.Visuals.Main.Color = Utility:LerpColor(self.Visuals.Main.Color, Utility:ShiftColor(Library.Theme.Secondary, 0.1), 0.2)
                
                if Input.Mouse.Left then -- Click handling (rudimentary, ideally separate Click detection)
                     self.Visuals.Main.Color = Utility:ShiftColor(Library.Theme.Secondary, 0.2)
                end
            else
                self.Visuals.Main.Color = Library.Theme.Secondary
            end
        end
    end

    Utility:Connect(UserInputService.InputBegan, function(input)
       if input.UserInputType == Enum.UserInputType.MouseButton1 and button.Visible then
            if Utility:IsMouseOver(button.Position, button.Size) then
                pcall(button.Callback)
            end
       end
    end)
    
    return button
end

-- Toggle Component
function Window:CreateToggle(tab, text, default, callback)
    local toggle = CreateBaseElement(tab, 30)
    toggle.Value = default or false
    toggle.Callback = callback or function() end
    
    toggle.Visuals = {
        Container = DrawingLib:Create("Square", {
            Filled = true, -- Hitbox mostly
            Color = Color3.new(0,0,0),
            Transparency = 0, -- Check if Drawing supports Transparency/Opacity
            Visible = toggle.Visible
        }),
        Label = DrawingLib:Create("Text", {
            Text = text,
            Size = 14,
            Color = Library.Theme.Text,
            Outline = true,
            Visible = toggle.Visible
        }),
        Box = DrawingLib:Create("Square", {
            Filled = false,
            Thickness = 1,
            Color = Library.Theme.Outline,
            Rounding = 2,
            Visible = toggle.Visible
        }),
        Indicator = DrawingLib:Create("Square", {
            Filled = true,
            Color = Library.Theme.Accent,
            Rounding = 2,
            Visible = toggle.Visible
        })
    }
    
    function toggle:Update()
        -- Layout
        self.Visuals.Container.Size = self.Size
        self.Visuals.Container.Position = self.Position
        
        self.Visuals.Label.Position = self.Position + Vector2.new(0, 8)
        
        local boxSize = 16
        local boxPos = self.Position + Vector2.new(self.Size.X - boxSize, 7)
        self.Visuals.Box.Size = Vector2.new(boxSize, boxSize)
        self.Visuals.Box.Position = boxPos
        
        self.Visuals.Indicator.Size = Vector2.new(boxSize - 4, boxSize - 4)
        self.Visuals.Indicator.Position = boxPos + Vector2.new(2, 2)
        
        -- State Logic
        if self.Value then
            self.Visuals.Indicator.Filled = true
            -- self.Visuals.Indicator.Color = Library.Theme.Accent -- already set
        else
            self.Visuals.Indicator.Filled = false -- Hide it or transparent
             self.Visuals.Indicator.Color = Color3.new(0,0,0) -- Effectively hidden if black on black background or use Visible
        end
        self.Visuals.Indicator.Visible = self.Visible and self.Value -- Simple visibility toggle
        
        -- Hover
        if self.Visible and Utility:IsMouseOver(self.Position, self.Size) then
             self.Visuals.Label.Color = Library.Theme.Accent
        else
             self.Visuals.Label.Color = Library.Theme.Text
        end
    end
    
    Utility:Connect(UserInputService.InputBegan, function(input)
       if input.UserInputType == Enum.UserInputType.MouseButton1 and toggle.Visible then
            if Utility:IsMouseOver(toggle.Position, toggle.Size) then
                toggle.Value = not toggle.Value
                pcall(toggle.Callback, toggle.Value)
            end
       end
    end)
    
    return toggle
end

-- Slider Component
function Window:CreateSlider(tab, text, options, callback)
    local slider = CreateBaseElement(tab, 40)
    slider.Min = options.Min or 0
    slider.Max = options.Max or 100
    slider.Value = options.Default or slider.Min
    slider.Callback = callback or function() end
    
    slider.Visuals = {
        Label = DrawingLib:Create("Text", {
            Text = text,
            Size = 14,
            Color = Library.Theme.Text,
            Outline = true,
            Visible = slider.Visible
        }),
        ValueLabel = DrawingLib:Create("Text", {
            Text = tostring(slider.Value),
            Size = 14,
            Color = Library.Theme.Text,
            Outline = true,
            Visible = slider.Visible,
            Center = true -- We will center relative to right side roughly
        }),
        Bar = DrawingLib:Create("Square", {
            Filled = true,
            Color = Library.Theme.Secondary,
            Rounding = 4,
            Visible = slider.Visible
        }),
        Fill = DrawingLib:Create("Square", {
            Filled = true,
            Color = Library.Theme.Accent,
            Rounding = 4,
            Visible = slider.Visible
        })
    }
    
    local dragging = false
    
    function slider:UpdateValue(inputPos)
        local percent = math.clamp((inputPos.X - self.Visuals.Bar.Position.X) / self.Visuals.Bar.Size.X, 0, 1)
        local newValue = math.floor(self.Min + (self.Max - self.Min) * percent)
        self.Value = newValue
        self.Visuals.ValueLabel.Text = tostring(newValue)
        pcall(self.Callback, newValue)
    end
    
    function slider:Update()
        -- Layout
        self.Visuals.Label.Position = self.Position
        
        local barPos = self.Position + Vector2.new(0, 20)
        local barSize = Vector2.new(self.Size.X, 10)
        
        self.Visuals.Bar.Position = barPos
        self.Visuals.Bar.Size = barSize
        
        local fillPercent = (self.Value - self.Min) / (self.Max - self.Min)
        self.Visuals.Fill.Position = barPos
        self.Visuals.Fill.Size = Vector2.new(barSize.X * fillPercent, barSize.Y)
        
        self.Visuals.ValueLabel.Position = self.Position + Vector2.new(self.Size.X - 20, 0)
        
        -- Logic
        if dragging then
            slider:UpdateValue(UserInputService:GetMouseLocation())
        end
        
        -- Hover
        if self.Visible and Utility:IsMouseOver(self.Visuals.Bar.Position, self.Visuals.Bar.Size) then
             self.Visuals.Bar.Color = Utility:ShiftColor(Library.Theme.Secondary, 0.1)
        else
             self.Visuals.Bar.Color = Library.Theme.Secondary
        end
    end
    
    Utility:Connect(UserInputService.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and slider.Visible then
            if Utility:IsMouseOver(slider.Visuals.Bar.Position, slider.Visuals.Bar.Size) then
                dragging = true
                slider:UpdateValue(UserInputService:GetMouseLocation())
            end
        end
    end)
    
    Utility:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    return slider
end

-- Dropdown Component
function Window:CreateDropdown(tab, text, options, callback)
    local dropdown = CreateBaseElement(tab, 45) -- Helper height
    dropdown.Options = options or {}
    dropdown.Value = dropdown.Options[1] or ""
    dropdown.Callback = callback or function() end
    dropdown.Open = false
    
    dropdown.Visuals = {
        Label = DrawingLib:Create("Text", {
            Text = text,
            Size = 14,
            Color = Library.Theme.Text,
            Outline = true,
            Visible = dropdown.Visible
        }),
        Main = DrawingLib:Create("Square", {
            Filled = true,
            Color = Library.Theme.Secondary,
            Rounding = 4,
            Visible = dropdown.Visible
        }),
        SelectedText = DrawingLib:Create("Text", {
            Text = tostring(dropdown.Value),
            Size = 14,
            Color = Library.Theme.DarkText, -- Dimmer text for value
            Outline = true,
            Visible = dropdown.Visible,
            Center = true
        }),
        -- Arrow would go here
    }
    
    -- List container visuals (dynamic)
    dropdown.ListVisuals = {}
    
    function dropdown:Toggle()
        self.Open = not self.Open
        -- Create/Destroy list visuals
        for _, v in ipairs(self.ListVisuals) do v:Remove() end
        self.ListVisuals = {}
        
        if self.Open then
            local listY = self.Visuals.Main.Position.Y + self.Visuals.Main.Size.Y + 2
            for i, opt in ipairs(self.Options) do
                local bg = DrawingLib:Create("Square", {
                    Filled = true,
                    Color = Library.Theme.Main,
                    Size = Vector2.new(self.Visuals.Main.Size.X, 25),
                    Position = Vector2.new(self.Visuals.Main.Position.X, listY),
                    Visible = true,
                    ZIndex = 10 -- Higher than window
                })
                
                local txt = DrawingLib:Create("Text", {
                    Text = tostring(opt),
                    Size = 14,
                    Color = Library.Theme.Text,
                    Outline = true,
                    Center = true,
                    Position = bg.Position + Vector2.new(bg.Size.X/2, 5),
                    Visible = true,
                    ZIndex = 11
                })
                
                table.insert(self.ListVisuals, {Bg = bg, Text = txt, Value = opt})
                listY = listY + 26
            end
        end
    end
    
    function dropdown:Update()
        if self.Open and not self.Visible then self:Toggle() end -- Close if hidden
        
        self.Visuals.Label.Position = self.Position
        
        local mainPos = self.Position + Vector2.new(0, 20)
        local mainSize = Vector2.new(self.Size.X, 25)
        
        self.Visuals.Main.Position = mainPos
        self.Visuals.Main.Size = mainSize
        self.Visuals.SelectedText.Position = mainPos + Vector2.new(mainSize.X/2, 5)
        
        -- Update List interactions (Mouse click check for options)
        if self.Open then
             -- Simple interaction check in Update loop for hover effects
             for _, item in ipairs(self.ListVisuals) do
                 if Utility:IsMouseOver(item.Bg.Position, item.Bg.Size) then
                     item.Bg.Color = Library.Theme.Secondary
                 else
                     item.Bg.Color = Library.Theme.Main
                 end
             end
        end
    end
    
    Utility:Connect(UserInputService.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dropdown.Visible then
            if Utility:IsMouseOver(dropdown.Visuals.Main.Position, dropdown.Visuals.Main.Size) then
                dropdown:Toggle()
            elseif dropdown.Open then
                -- Check options
                local clickedOption = false
                for _, item in ipairs(dropdown.ListVisuals) do
                    if Utility:IsMouseOver(item.Bg.Position, item.Bg.Size) then
                        dropdown.Value = item.Value
                        dropdown.Visuals.SelectedText.Text = tostring(item.Value)
                        pcall(dropdown.Callback, item.Value)
                        clickedOption = true
                        break
                    end
                end
                
                if clickedOption or not Utility:IsMouseOver(dropdown.Visuals.Main.Position, dropdown.Visuals.Main.Size) then
                    dropdown:Toggle() -- Close
                end
            end
        end
    end)
    
    return dropdown
end

-- Keybind Component
function Window:CreateKeybind(tab, text, default, callback)
    local keybind = CreateBaseElement(tab, 30)
    keybind.Value = default or Enum.KeyCode.RightShift
    keybind.Callback = callback or function() end
    keybind.Binding = false
    
    keybind.Visuals = {
        Label = DrawingLib:Create("Text", {
            Text = text,
            Size = 14,
            Color = Library.Theme.Text,
            Outline = true,
            Visible = keybind.Visible
        }),
        Button = DrawingLib:Create("Square", {
            Filled = true,
            Color = Library.Theme.Secondary,
            Rounding = 4,
            Visible = keybind.Visible
        }),
        BindLabel = DrawingLib:Create("Text", {
            Text = keybind.Value.Name,
            Size = 13,
            Color = Library.Theme.Text,
            Outline = true,
            Center = true,
            Visible = keybind.Visible
        })
    }
    
    function keybind:Update()
        self.Visuals.Label.Position = self.Position + Vector2.new(0, 8)
        
        -- Right aligned button
        local btnSize = Vector2.new(80, 20)
        local btnPos = self.Position + Vector2.new(self.Size.X - btnSize.X, 5)
        
        self.Visuals.Button.Size = btnSize
        self.Visuals.Button.Position = btnPos
        self.Visuals.BindLabel.Position = btnPos + Vector2.new(btnSize.X/2, 3)
        
        if self.Binding then
            self.Visuals.BindLabel.Text = "..."
            self.Visuals.Button.Color = Library.Theme.Accent
        else
            self.Visuals.BindLabel.Text = self.Value.Name
            self.Visuals.Button.Color = Library.Theme.Secondary
        end
    end
    
    Utility:Connect(UserInputService.InputBegan, function(input)
        if keybind.Binding then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keybind.Value = input.KeyCode
                keybind.Binding = false
                pcall(keybind.Callback, keybind.Value)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                 -- Setup bindings for mouse if needed, but usually keyboard for "Keybind"
                 -- Adding simple cancel on click outside logic could be good
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 and keybind.Visible then
            if Utility:IsMouseOver(keybind.Visuals.Button.Position, keybind.Visuals.Button.Size) then
                keybind.Binding = true
            end
        end
        
        -- Trigger check
        if input.KeyCode == keybind.Value and not keybind.Binding then
             pcall(keybind.Callback)
        end
    end)
    
    return keybind
end

-- ColorPicker Component (Simplified RGB Sliders Popup)
function Window:CreateColorPicker(tab, text, default, callback)
    local colorpicker = CreateBaseElement(tab, 35)
    colorpicker.Value = default or Color3.new(1,1,1)
    colorpicker.Callback = callback or function() end
    colorpicker.Open = false
    
    colorpicker.Visuals = {
        Label = DrawingLib:Create("Text", {
            Text = text,
            Size = 14,
            Color = Library.Theme.Text,
            Outline = true,
            Visible = colorpicker.Visible
        }),
        Preview = DrawingLib:Create("Square", {
            Filled = true,
            Color = colorpicker.Value,
            Rounding = 4,
            Visible = colorpicker.Visible,
            Size = Vector2.new(30, 15) -- Fixed size preview
        })
    }
    
    colorpicker.Popup = {
        Main = DrawingLib:Create("Square", { Filled=true, Color=Library.Theme.Main, Visible=false, ZIndex=15 }),
        Border = DrawingLib:Create("Square", { Filled=false, Color=Library.Theme.Outline, Thickness=1, Visible=false, ZIndex=16 }),
        Sliders = {} -- R, G, B sliders
    }
    
    -- Helper to create popup slider
    local function CreatePopupSlider(idx, colorComp)
        local s = {
             Bar = DrawingLib:Create("Square", { Filled=true, Color=Color3.new(0.2,0.2,0.2), Visible=false, ZIndex=17 }),
             Fill = DrawingLib:Create("Square", { Filled=true, Color=colorComp, Visible=false, ZIndex=18 })
        }
        table.insert(colorpicker.Popup.Sliders, s)
        return s
    end
    CreatePopupSlider(1, Color3.new(1,0,0)) -- Red
    CreatePopupSlider(2, Color3.new(0,1,0)) -- Green
    CreatePopupSlider(3, Color3.new(0,0,1)) -- Blue
    
    function colorpicker:Update()
        self.Visuals.Label.Position = self.Position + Vector2.new(0,8)
        self.Visuals.Preview.Position = self.Position + Vector2.new(self.Size.X - 35, 8)
        self.Visuals.Preview.Color = self.Value
        
        if self.Open then
            local pPos = self.Visuals.Preview.Position + Vector2.new(0, 20)
            local pSize = Vector2.new(100, 70)
            
            self.Popup.Main.Position = pPos
            self.Popup.Main.Size = pSize
            self.Popup.Main.Visible = true
            
            self.Popup.Border.Position = pPos
            self.Popup.Border.Size = pSize
            self.Popup.Border.Visible = true
            
            -- Sliders
            local comps = {self.Value.R, self.Value.G, self.Value.B}
            for i, s in ipairs(self.Popup.Sliders) do
                local sY = pPos.Y + 10 + (i-1)*20
                local sPos = Vector2.new(pPos.X + 10, sY)
                local sSize = Vector2.new(80, 10)
                
                s.Bar.Visible = true
                s.Bar.Position = sPos
                s.Bar.Size = sSize
                
                s.Fill.Visible = true
                s.Fill.Position = sPos
                s.Fill.Size = Vector2.new(sSize.X * comps[i], sSize.Y)
            end
        else
            self.Popup.Main.Visible = false
            self.Popup.Border.Visible = false
            for _, s in ipairs(self.Popup.Sliders) do s.Bar.Visible = false; s.Fill.Visible = false end
        end
        
        -- Slider Logic (Dragging)
        if self.Open and Input.Mouse.Left then
            local mPos = UserInputService:GetMouseLocation()
             for i, s in ipairs(self.Popup.Sliders) do
                 if Utility:IsMouseOver(s.Bar.Position, s.Bar.Size) then
                     local pct = math.clamp((mPos.X - s.Bar.Position.X) / s.Bar.Size.X, 0, 1)
                     local r,g,b = self.Value.R, self.Value.G, self.Value.B
                     if i == 1 then r = pct elseif i == 2 then g = pct else b = pct end
                     self.Value = Color3.new(r,g,b)
                     self.Visuals.Preview.Color = self.Value
                     pcall(self.Callback, self.Value)
                 end
             end
        end
    end
    
    Utility:Connect(UserInputService.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and colorpicker.Visible then
            if Utility:IsMouseOver(colorpicker.Visuals.Preview.Position, colorpicker.Visuals.Preview.Size) then
                colorpicker.Open = not colorpicker.Open
            elseif colorpicker.Open and not Utility:IsMouseOver(colorpicker.Popup.Main.Position, colorpicker.Popup.Main.Size) then
                 colorpicker.Open = false
            end
        end
    end)
    
    return colorpicker
end

return Library
