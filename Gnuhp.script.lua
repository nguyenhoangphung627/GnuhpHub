-- GnuhpHub: Teleport (shop/NPC, teleport to ground) + ESP (Animals & DeadAnimals auto-scan)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- CONFIG
local UPDATE_INTERVAL = 0.12
local ESP_RANGE = 1200

-- cleanup old gui
if PlayerGui:FindFirstChild("GnuhpHub") then
    PlayerGui.GnuhpHub:Destroy()
end

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GnuhpHub"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local function makeFrame(parent, size, pos)
    local f = Instance.new("Frame", parent)
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = Color3.fromRGB(30,30,30)
    f.BorderSizePixel = 0
    f.AnchorPoint = Vector2.new(0,0)
    local c = Instance.new("UICorner", f)
    c.CornerRadius = UDim.new(0,8)
    local s = Instance.new("UIStroke", f)
    s.Transparency = 0.6
    s.Thickness = 1
    return f
end

local main = makeFrame(screenGui, UDim2.new(0, 300, 0, 120), UDim2.new(0.5, -150, 0.06, 0))
main.Active = true
main.Draggable = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, -40, 0, 30)
title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1
title.Text = "GnuhpHub"
title.TextColor3 = Color3.fromRGB(240,240,240)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

local collapse = Instance.new("TextButton", main)
collapse.Size = UDim2.new(0,26,0,26)
collapse.Position = UDim2.new(1, -36, 0, 6)
collapse.BackgroundTransparency = 1
collapse.Text = "□"
collapse.Font = Enum.Font.GothamBold
collapse.TextColor3 = Color3.fromRGB(240,240,240)

local labelRange = Instance.new("TextLabel", main)
labelRange.Size = UDim2.new(0, 160, 0, 20)
labelRange.Position = UDim2.new(0, 12, 0, 44)
labelRange.BackgroundTransparency = 1
labelRange.Text = "ESP Range: Not Active"
labelRange.TextColor3 = Color3.fromRGB(200,200,200)
labelRange.Font = Enum.Font.Gotham
labelRange.TextSize = 12
labelRange.TextXAlignment = Enum.TextXAlignment.Left

local tpBtn = Instance.new("TextButton", main)
tpBtn.Size = UDim2.new(0,130,0,36)
tpBtn.Position = UDim2.new(0,156,0,64)
tpBtn.Text = "TP to Shop"
tpBtn.Font = Enum.Font.GothamBold
tpBtn.TextSize = 14
tpBtn.BackgroundColor3 = Color3.fromRGB(40,120,220)
tpBtn.TextColor3 = Color3.fromRGB(240,240,240)
local tpCorner = Instance.new("UICorner", tpBtn); tpCorner.CornerRadius = UDim.new(0,6)

local espBtn = Instance.new("TextButton", main)
espBtn.Size = UDim2.new(0,130,0,36)
espBtn.Position = UDim2.new(0, 12, 0, 64)
espBtn.Text = "ESP: OFF"
espBtn.Font = Enum.Font.GothamBold
espBtn.TextSize = 14
espBtn.BackgroundColor3 = Color3.fromRGB(120,40,40)
espBtn.TextColor3 = Color3.fromRGB(240,240,240)
local espCorner = Instance.new("UICorner", espBtn); espCorner.CornerRadius = UDim.new(0,6)

local collapsed = false
collapse.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    if collapsed then
        TweenService:Create(main, TweenInfo.new(0.18), {Size = UDim2.new(0,300,0,34)}):Play()
        tpBtn.Visible = false
        labelRange.Visible = false
        espBtn.Visible = false
    else
        TweenService:Create(main, TweenInfo.new(0.18), {Size = UDim2.new(0,300,0,120)}):Play()
        tpBtn.Visible = true
        labelRange.Visible = true
        espBtn.Visible = true
    end
end)

-- UTIL: get model primary part
local function getModelPrimaryPart(m)
    if not m then return nil end
    if m.PrimaryPart and m.PrimaryPart:IsA("BasePart") then return m.PrimaryPart end
    local hrp = m:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then return hrp end
    for _,v in pairs(m:GetDescendants()) do
        if v:IsA("BasePart") then return v end
    end
    return nil
end

local shopKeywords = {"shop","store","vendor","seller","gunstore","gun","shopkeeper"}
local function modelNameHasShopKeyword(name)
    if not name then return false end
    local lower = string.lower(tostring(name))
    for _,kw in pairs(shopKeywords) do
        if string.find(lower, kw, 1, true) then
            return true
        end
    end
    return false
end

local function isShopModel(m)
    if not m then return false end
    if Players:GetPlayerFromCharacter(m) then return false end
    local ok, has = pcall(function() return CollectionService:HasTag(m, "Shop") end)
    if ok and has then
        return true
    end
    if modelNameHasShopKeyword(m.Name) then
        return true
    end
    return false
end

local function findNearestShopOrNPC()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position

    local bestShop, bestShopD = nil, math.huge
    local bestNPC, bestNPCD = nil, math.huge

    for _,inst in pairs(workspace:GetDescendants()) do
        if inst:IsA("Model") and inst ~= char then
            if Players:GetPlayerFromCharacter(inst) then
            else
                local prim = getModelPrimaryPart(inst)
                if prim and prim.Position then
                    local d = (prim.Position - myPos).Magnitude
                    if isShopModel(inst) then
                        if d < bestShopD then
                            bestShop = {model = inst, part = prim, dist = d}
                            bestShopD = d
                        end
                    else
                        if inst:FindFirstChildOfClass("Humanoid") then
                            local lname = string.lower(inst.Name)
                            if not (lname:find("spawn") or lname:find("lobby") or lname:find("wait") or lname:find("queue")) then
                                if d < bestNPCD then
                                    bestNPC = {model = inst, part = prim, dist = d}
                                    bestNPCD = d
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if bestShop then return bestShop end
    return bestNPC
end

local function findGroundBelow(position, ignoreList)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = ignoreList or {}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local from = position + Vector3.new(0, 80, 0)
    local dir = Vector3.new(0, -300, 0)
    local result = workspace:Raycast(from, dir, params)
    if result and result.Position then
        return result.Position, result
    end
    return nil, nil
end

tpBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local target = findNearestShopOrNPC()
    if not target then
        tpBtn.Text = "No Target"
        tpBtn.BackgroundColor3 = Color3.fromRGB(200,80,80)
        task.delay(1.2, function()
            tpBtn.Text = "TP to Shop"
            tpBtn.BackgroundColor3 = Color3.fromRGB(40,120,220)
        end)
        return
    end

    local ok, err = pcall(function()
        local ignore = {LocalPlayer.Character}
        if target.model and typeof(target.model) == "Instance" then
            table.insert(ignore, target.model)
        end

        local groundPos, hit = findGroundBelow(target.part.Position, ignore)
        if not groundPos then
            local offsets = {Vector3.new(0,0,0), Vector3.new(2,0,0), Vector3.new(-2,0,0), Vector3.new(0,0,2), Vector3.new(0,0,-2)}
            for _,off in pairs(offsets) do
                groundPos = findGroundBelow(target.part.Position + off, ignore)
                if groundPos then break end
            end
        end

        local finalCFrame
        if groundPos then
            local dir = hrp.Position - target.part.Position
            dir = Vector3.new(dir.X, 0, dir.Z)
            if dir.Magnitude < 0.1 then
                local lv = target.part.CFrame.LookVector
                dir = Vector3.new(lv.X, 0, lv.Z)
                if dir.Magnitude < 0.1 then dir = Vector3.new(1,0,0) end
            end
            dir = dir.Unit
            local targetPos = Vector3.new(groundPos.X, groundPos.Y, groundPos.Z) + dir * 3
            local yOffset = 3
            if hrp and hrp.Size and hrp.Size.Y then
                yOffset = hrp.Size.Y/2 + 0.1
            end
            finalCFrame = CFrame.new(targetPos.X, groundPos.Y + yOffset, targetPos.Z)
        else
            finalCFrame = target.part.CFrame + Vector3.new(0, 3, 0)
        end

        hrp.CFrame = finalCFrame
    end)

    if not ok then
        warn("Teleport error:", err)
        tpBtn.Text = "TP Err"
        task.delay(1.2, function()
            tpBtn.Text = "TP to Shop"
            tpBtn.BackgroundColor3 = Color3.fromRGB(40,120,220)
        end)
    else
        tpBtn.Text = "Teleported"
        tpBtn.BackgroundColor3 = Color3.fromRGB(40,160,40)
        task.delay(1.2, function()
            tpBtn.Text = "TP to Shop"
            tpBtn.BackgroundColor3 = Color3.fromRGB(40,120,220)
        end)
    end
end)

-- ESP code (auto-scan Animals & DeadAnimals; fallback to scanning workspace)
local espEnabled = false
local espMarkers = {} -- [model] = {billboard = Instance, highlight = Instance}
local animalFolders = {}

-- try to locate Animals / DeadAnimals folders
if workspace:FindFirstChild("Animals") then table.insert(animalFolders, workspace:FindFirstChild("Animals")) end
if workspace:FindFirstChild("DeadAnimals") then table.insert(animalFolders, workspace:FindFirstChild("DeadAnimals")) end

local function createESPForModel(model, dist)
    if espMarkers[model] then return end
    local primaryPart = getModelPrimaryPart(model)
    if not primaryPart then return end

    -- Highlight
    local ok, highlight = pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "Gnuhp_Highlight"
        h.FillColor = Color3.fromRGB(255, 60, 60)
        h.OutlineColor = Color3.fromRGB(255,255,255)
        h.FillTransparency = 0.6
        h.OutlineTransparency = 0
        h.Adornee = model
        h.Parent = model
        return h
    end)

    -- Billboard (parent to screenGui)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPMarker"
    billboard.Adornee = primaryPart
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 140, 0, 32)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.Parent = screenGui

    local label = Instance.new("TextLabel", billboard)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 200, 60)
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextScaled = false
    label.RichText = false
    label.Text = model.Name .. " - " .. math.floor(dist) .. "m"

    espMarkers[model] = {billboard = billboard, highlight = (ok and highlight) or nil}
end

local function removeESPForModel(model)
    local data = espMarkers[model]
    if not data then return end
    if data.billboard and data.billboard.Parent then data.billboard:Destroy() end
    if data.highlight and data.highlight.Parent then data.highlight:Destroy() end
    espMarkers[model] = nil
end

local function clearESP()
    for m,_ in pairs(espMarkers) do
        removeESPForModel(m)
    end
    espMarkers = {}
end

local function isAnimalModel_modelOnly(m)
    if not m or not m:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(m) then return false end
    if isShopModel(m) then return false end
    return true
end

local function scanAndCollectCandidates()
    local candidates = {}
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return candidates end
    local myPos = char.HumanoidRootPart.Position

    -- First prefer checking Animals/DeadAnimals folders if present
    if #animalFolders > 0 then
        for _,folder in ipairs(animalFolders) do
            if folder and folder:IsA("Folder") then
                for _,obj in ipairs(folder:GetDescendants()) do
                    if obj:IsA("Model") and isAnimalModel_modelOnly(obj) then
                        local prim = getModelPrimaryPart(obj)
                        if prim then
                            local dist = (prim.Position - myPos).Magnitude
                            if dist <= ESP_RANGE then
                                table.insert(candidates, {model = obj, dist = dist})
                            end
                        end
                    end
                end
            end
        end
        return candidates
    end

    -- Fallback: scan workspace for common mob indicators
    for _,inst in pairs(workspace:GetDescendants()) do
        if inst:IsA("Model") and inst ~= LocalPlayer.Character and isAnimalModel_modelOnly(inst) then
            local prim = getModelPrimaryPart(inst)
            if prim then
                local dist = (prim.Position - myPos).Magnitude
                if dist <= ESP_RANGE then
                    -- basic filters: prefer models that have Humanoid OR HumanoidRootPart OR AnimationController OR name hints
                    local okIndicator = false
                    if inst:FindFirstChildOfClass("Humanoid") then okIndicator = true end
                    if inst:FindFirstChild("HumanoidRootPart") and inst:FindFirstChildOfClass("AnimationController") then okIndicator = true end
                    local lname = inst.Name:lower()
                    if lname:find("deer") or lname:find("bear") or lname:find("animal") or lname:find("wolf") or lname:find("rabbit") then okIndicator = true end
                    if okIndicator then
                        table.insert(candidates, {model = inst, dist = dist})
                    end
                end
            end
        end
    end

    return candidates
end

local function updateESP()
    if not espEnabled then
        clearESP()
        return
    end

    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    local candidates = scanAndCollectCandidates()

    -- remove markers for models no longer candidates
    for model,_ in pairs(espMarkers) do
        local keep = false
        for _,c in ipairs(candidates) do
            if c.model == model then keep = true break end
        end
        if not keep then removeESPForModel(model) end
    end

    -- create or update markers
    for _,c in ipairs(candidates) do
        if not espMarkers[c.model] then
            pcall(function() createESPForModel(c.model, c.dist) end)
        else
            local marker = espMarkers[c.model]
            if marker and marker.billboard and marker.billboard:FindFirstChildOfClass("TextLabel") then
                marker.billboard:FindFirstChildOfClass("TextLabel").Text = c.model.Name .. " - " .. math.floor(c.dist) .. "m"
            end
        end
    end
end

espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    if espEnabled then
        espBtn.Text = "ESP: ON"
        espBtn.BackgroundColor3 = Color3.fromRGB(40,160,40)
        labelRange.Text = "ESP Range: Active ("..ESP_RANGE.."m)"
    else
        espBtn.Text = "ESP: OFF"
        espBtn.BackgroundColor3 = Color3.fromRGB(120,40,40)
        labelRange.Text = "ESP Range: Not Active"
        clearESP()
    end
end)

-- periodic update with throttle
local acc = 0
RunService.RenderStepped:Connect(function(dt)
    acc = acc + dt
    if acc >= UPDATE_INTERVAL then
        acc = 0
        if espEnabled then
            pcall(updateESP)
        end
    end
end)

-- cleanup on leave
Players.LocalPlayer.AncestryChanged:Connect(function()
    if not Players.LocalPlayer:IsDescendantOf(game) then
        if screenGui and screenGui.Parent then screenGui:Destroy() end
        clearESP()
    end
end)