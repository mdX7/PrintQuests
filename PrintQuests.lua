
local frame = CreateFrame("Frame")

frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("QUEST_REMOVED")
frame:RegisterEvent("CRITERIA_UPDATE")
frame:RegisterEvent("QUEST_LOG_UPDATE")

local unsurelyNamedTrackingQuests = {
    [83281] = "Weaver Weekly turnin???",
    [86931] = "Weaver Weekly turnin???",
    [84538] = "Weaver Accessory rank / Weaver weekly turnin?",
    [81562] = "Ringing Deeps Rare: Charmonger Rare killed?",
    [84044] = "Ringing Deeps Rare: Charmonger Rare killed?",
    [81511] = "Ringing Deeps Rare: Coalesced Monstrosity Rare killed?",
    [84045] = "Ringing Deeps Rare: Coalesced Monstrosity Rare killed?",
    [80415] = "War Supply Chest on Siren Isle/Azj'kahet looted?",
    [80416] = "War Supply Chest on Siren Isle/Azj'kahet looted?",
    [84873] = "Siren Isle Rare: Kill X Rares?",
    [85714] = "Siren Isle: Rune-Sealed Coffer solved (in Stormtide Dregs)?",
    [86171] = "Siren Isle: Rune-Sealed Coffer looted (in Stormtide Dregs)?",
    [85708] = "Siren Isle: Special Assignment: Storm's a Brewin unlocked?",
    [86486] = "Hungry, Hungry Snapdragon 2/X?",
}

local confidentlyNamedTrackingQuests = {
    [84801] = "Siren Isle Rare: Ghostmaker killed",
    [84792] = "Siren Isle Rare: Ikir the Flotsurge killed",
    [85403] = "Siren Isle Rare: Tempest Talon killed",
    [84798] = "Siren Isle Rare: Slaughtershell killed",
    [85405] = "Siren Isle Rare: Zek'hul the shipbreaker killed",
    [85404] = "Siren Isle Rare: Brinebough killed",
    [84805] = "Siren Isle Rare: Asbjorn the Bloodsoaked killed",
    [84794] = "Siren Isle Rare: Wreckwater killed",
    [85406] = "Siren Isle Rare: Ksvir the Forgotten killed",
    [85156] = "Angorla stay a while and listen",
    [85103] = "Apprentice Tanmar stay a while and listen",
    [85669] = "Siren Isle Excavation: Gravesludge killed in The Drain",
    [86732] = "Siren Isle Chest: Stone Carvers Scramseax looted",
    [84101] = "Brann reached Level 40",
    [84009] = "Alleria Stay a while and listen after The Fleet Arrives",
    [84345] = "Turalyon Stay a while and listen after Embassies and Envoys",
    [82461] = "Dagran Thaurissan II Stay a while and listen in The Archive",
    [84814] = "Dagran Thaurissan II Stay a while and listen in Vault of Memory",
    [85682] = "Magni Bronzebeard Stay a while and listen in front of The Archive",
    [82542] = "Rooktender Lufsela Stay a while and listen in front of Thrall, Shraubendre",
    [84813] = "Rooktender Lufsela Stay a while and listen in Dhar Oztan",
    [84539] = "Renown 22 Severed Threads",
    [84631] = "Awakening The Machine Wave 5 cleared",
    [84632] = "Awakening The Machine Wave 10 cleared",
    [84633] = "Awakening The Machine Wave 15 cleared",
    [84634] = "Awakening The Machine Wave 20 cleared",
    [83054] = "Mining: Slab of Slate 1/5 looted",
    [83053] = "Mining: Slab of Slate 2/5 looted",
    [83052] = "Mining: Slab of Slate 3/5 looted",
    [83051] = "Mining: Slab of Slate 4/5 looted",
    [83050] = "Mining: Slab of Slate 5/5 looted",
    [83049] = "Mining: Erosion-Polished Slate looted",
    [81881] = "Hallowfall Rare: Funglour killed",
    [84229] = "Faded Engineer Scriblings used",
    [81355] = "Convincingly Realistic Jumper Cables First Craft done",
}

local function PrintQuest(printType, questID)
    local questName = C_QuestLog.GetTitleForQuestID(questID)
    if questName then
        print("Quest ".. printType ..": |cFF00FF00" .. questName .. "|r (ID: " .. questID .. ")")
    elseif confidentlyNamedTrackingQuests[questID] then
        print("Quest ".. printType ..": |cFF00FF00TRACKING " .. confidentlyNamedTrackingQuests[questID] .. "|r (ID: " .. questID .. ")")
    elseif unsurelyNamedTrackingQuests[questID] then
        print("Quest ".. printType ..": |cFFFFFF00TRACKING " .. unsurelyNamedTrackingQuests[questID] .. "|r (ID: " .. questID .. ")")
    else
        print("Quest ".. printType .." |cFFFF0000(Tracking)|r: (ID: " .. questID .. ")")
    end
end

local completedQuests = {}
local questObjectives = {}

local function QueryCompletedQuests()
    local currentCompletedQuests = {}
    local completedQuestIDs = C_QuestLog.GetAllCompletedQuestIDs()
    if completedQuestIDs then
        for _, questID in ipairs(completedQuestIDs) do
            currentCompletedQuests[questID] = true
            if not completedQuests[questID] then
                PrintQuest("completed", questID)
            end
        end
    end

    for questID, _ in pairs(completedQuests) do
        if not currentCompletedQuests[questID] then
            PrintQuest("reverted", questID)
        end
    end
    completedQuests = currentCompletedQuests
end

local lastQueryTime = 0
local QUERY_THROTTLE_INTERVAL = 0.25 -- in seconds
local function ThrottledQueryCompletedQuests()
    local currentTime = GetTime()
    if currentTime - lastQueryTime > QUERY_THROTTLE_INTERVAL then
        QueryCompletedQuests()
        lastQueryTime = currentTime
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "CRITERIA_UPDATE" or event == "QUEST_LOG_UPDATE" then
        ThrottledQueryCompletedQuests()
    elseif event == "QUEST_ACCEPTED" then
        local questID = ...
        PrintQuest("accepted", questID)
        ThrottledQueryCompletedQuests()
    elseif event == "QUEST_TURNED_IN" then
        local questID = ...
        PrintQuest("turned in", questID)
        ThrottledQueryCompletedQuests()
    elseif event == "QUEST_REMOVED" then
        local questID = ...
        PrintQuest("removed", questID)
        ThrottledQueryCompletedQuests()
    end
end)
