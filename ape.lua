-- Variables esenciales
local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage.Package.Events
local UserId = Player.UserId
local Lighting = game:GetService("Lighting")

-- Valores
local Datas = ReplicatedStorage.Datas
local currentQuest = Datas[UserId].Quest
local currentStats = Datas[UserId].Defense
local gohanStats = Datas[UserId].Strength
local currentRb = Datas[UserId].Rebirth
local invis_on = true -- Activar invisibilidad de forma predeterminada

_G.farm = true

_G.hasQuest = false

local npcs = {
    {"SSJG Kakata", 77500000},
    {"Broccoli", 35500000},
    {"SSJB Wukong", 8000000},
    {"Kai-fist Master", 17625000},
    {"SSJ2 Wukong", 15350000},
    {"Perfect Atom", 1575000},
    {"Chilly", 750000},
    {"Super Vegetable", 387500},
    {"Mapa", 90000},
    {"Radish", 75000},
    {"Klirin", 7000},
    {"X Fighter Trainer", 0}
}

local forms = {
    {"SSJ", 6000, 0},
}

local function getCurrentTime()
    return Lighting.ClockTime
end

local function selectQuest()
    local time = getCurrentTime()
    local selectedQuest = ""

    print("the time is -- ".. time .. " --")

    if (time >= 16 and time < 24 and gohanStats.Value > 30000) then
        selectedQuest = "Kid Nohag"
    else
        local bestNpc = nil
        local closestValue = math.huge

        for _, npc in pairs(npcs) do
            local npcName, npcMinStats = npc[1], npc[2]

            if currentStats.Value >= npcMinStats then
                local diff = currentStats.Value - npcMinStats
                if diff < closestValue then
                    closestValue = diff
                    bestNpc = npcName
                end
            end
        end

        selectedQuest = bestNpc or "No hay NPC disponible"
    end

    return selectedQuest
end

local function waitForCharacter()
    while not Player.Character do
        task.wait(0.1)
    end
    return Player.Character
end

local function makeInvisible()
    -- local character = Player.Character or Player.CharacterAdded:Wait()

    -- for _, part in ipairs(character:GetDescendants()) do
    --     if part:IsA("BasePart") then
    --         part.Transparency = 1
    --     end
    -- end

    -- local head = character:FindFirstChild("Head")
    -- if head then
    --     for _, child in ipairs(head:GetChildren()) do
    --         if child:IsA("BillboardGui") then
    --             child:Destroy()
    --         end
    --     end
    -- end
end

local function takeQuest(questName)
    local questGiver = workspace.Others.NPCs[questName]
    if questGiver and questGiver:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame = questGiver.HumanoidRootPart.CFrame
        task.wait(2)
        Events.Qaction:InvokeServer(questGiver)
        _G.hasQuest = true -- Marca que ahora hay una misión activa
    end
end

local function moveToNpc(npc)
    while _G.farm and _G.hasQuest and npc.Parent and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 do
        local character = waitForCharacter()

        if not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then
            task.wait(0.1) -- Espera si no existen las partes necesarias
            continue
        end

        local npcPosition = npc.HumanoidRootPart.Position
        local behindPosition = npcPosition - (npc.HumanoidRootPart.CFrame.LookVector * 2)

        character.HumanoidRootPart.CFrame = CFrame.new(behindPosition, npcPosition)

        task.wait(0.1)
    end
end

local function attack(npc)
    local character = waitForCharacter() -- Asegúrate de que el personaje esté disponible

    if not (npc and npc.Parent and npc:FindFirstChild("Humanoid") and character:FindFirstChild("Humanoid")) then
        return false
    end

    -- Verifica si hay una misión activa
    if not _G.hasQuest then
        return false -- Termina la función si no hay misión
    end

    while _G.farm and _G.hasQuest and npc.Parent and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 do
        if character.Humanoid.Health <= 0 then
            return false -- Si el personaje ha muerto, termina la función
        end

        for i = 1, 4 do
            Events.p:FireServer("Blacknwhite27", i)
            task.wait(0.1)

            if npc.Humanoid.Health <= 0 then
                return true
            end
        end
    end

    return false
end

makeInvisible()





Player.CharacterAdded:Connect(function()
    task.wait(1)
    makeInvisible()
    _G.hasQuest = false -- Restablece la variable al renacer

    -- Volver a tomar la misión después de renacer
    local questName = selectQuest()
    takeQuest(questName)
end)

while _G.farm do

    if invis_on and Player.Character then
        makeInvisible()
    end
    
    Events.reb:InvokeServer()
    -- Verifica si hay una misión activa
    if not _G.hasQuest then
        local questName = selectQuest()
        takeQuest(questName) -- Toma una nueva misión si no hay
        task.wait(1) -- Espera un segundo antes de volver a comprobar
        continue -- Salta al siguiente ciclo del bucle
    end

    local questName = selectQuest()
    local questData = ReplicatedStorage.Package.Quests[questName]

    if questData and currentQuest.Value == questName then
        local goal = questData.Goal.Value
        local npcToFarm = questData.Objective.Value
        local killedNpcs = 0

        for _, npc in pairs(workspace.Living:GetChildren()) do
            if npc.Name == npcToFarm and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                coroutine.wrap(moveToNpc)(npc)

                if attack(npc) then
                    killedNpcs += 1
                end

                if killedNpcs >= goal then
                    break
                end
            end
        end

        if killedNpcs >= goal then
            takeQuest(selectQuest())
        end
    else
        takeQuest(questName)
    end

    task.wait(1)
end
