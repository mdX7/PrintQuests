PrintQuests = {}
local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("QUEST_DATA_LOAD_RESULT")
frame:RegisterEvent("CRITERIA_UPDATE")
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("QUEST_REMOVED")
frame:RegisterEvent("QUEST_WATCH_UPDATE")
frame:RegisterEvent("QUEST_LOG_UPDATE")

local isReady = false

local function AddTrackingMessage(msg)
    if Grail and Grail.GDE then
        Grail:_AddTrackingMessage(msg)
    end
end

-- Queue: questID -> printType (only one printType per questID at a time)
local printQueue = {}

local function ActuallyPrintQuest(printType, questID)
    local questName = C_QuestLog.GetTitleForQuestID(questID)
    
    -- dont print quests which are spammed since 12.0.0
    if (questID == 94713 or 
        questID == 94714 or 
        questID == 94717 or 
        questID == 94718 or 
        questID == 94720 or 
        questID == 94721 or 
        questID == 95003 or 
        questID == 94763 or 
        questID == 94761 or 
        questID == 94758 or 
        questID == 94757 or 
        questID == 94753 or 
        questID == 94752 or 
        questID == 94751 or 
        questID == 94731 or 
        questID == 94725 or 
        questID == 94722 or 
        questID == 94719 or 
        questID == 94711 or 
        questID == 94708 or 
        questID == 94728 or 
        questID == 92857 or -- Ta'readon's Mount Voucher
        questID == 94759 or 
        questID == 94760 or 
        questID == 94762 or 
        questID == 95044) then
        return
    end
    
    if questName then
        print("(PQ) Quest ".. printType ..": |cFF00FF00" .. questName .. "|r (ID: " .. questID .. ")")
        AddTrackingMessage("(PQ) Quest ".. printType ..": |" .. questName .. "|r (ID: " .. questID .. ")")
    elseif Grail and Grail.GDE and Grail:QuestName(questID) then
        print("(PQ) Quest ".. printType ..": |cff91afGrail-TRACKING " .. Grail:QuestName(questID) .. "|r (ID: " .. questID .. ")")
        AddTrackingMessage("(PQ) Quest ".. printType ..": |Grail-TRACKING " .. Grail:QuestName(questID) .. "|r: (ID: " .. questID .. ")")
    elseif PrintQuests.ConfidentlyNamedTrackingQuests[questID] then
        print("(PQ) Quest ".. printType ..": |cFF00FF00TRACKING " .. PrintQuests.ConfidentlyNamedTrackingQuests[questID] .. "|r (ID: " .. questID .. ")")
        AddTrackingMessage("(PQ) Quest ".. printType ..": |TRACKING " .. PrintQuests.ConfidentlyNamedTrackingQuests[questID] .. "|r: (ID: " .. questID .. ")")
    elseif PrintQuests.UnsurelyNamedTrackingQuests[questID] then
        print("(PQ) Quest ".. printType ..": |cFFFFFF00TRACKING " .. PrintQuests.UnsurelyNamedTrackingQuests[questID] .. "|r (ID: " .. questID .. ")")
        AddTrackingMessage("(PQ) Quest ".. printType ..": TRACKING " .. PrintQuests.UnsurelyNamedTrackingQuests[questID] .. "|r: (ID: " .. questID .. ")")
    else
        print("(PQ) Quest ".. printType .." |cFFFF0000(Tracking)|r: (ID: " .. questID .. ")")
        AddTrackingMessage("(PQ) Quest ".. printType ..": |(Tracking)|r: (ID: " .. questID .. ")")
    end
end

local function FlushPrintQueue(questID)
    local printType = printQueue[questID]
    if not printType then return end
    printQueue[questID] = nil
    ActuallyPrintQuest(printType, questID)
end

local function PrintQuest(printType, questID)
    printQueue[questID] = printType
    C_QuestLog.RequestLoadQuestByID(questID)
    -- Timeout fallback after 20 seconds
    C_Timer.After(20, function()
        FlushPrintQueue(questID)
    end)
end

local completedQuests = {}

local function QueryCompletedQuests(suppressOutput)
    local currentCompletedQuests = {}
    local completedQuestIDs = C_QuestLog.GetAllCompletedQuestIDs()
    if completedQuestIDs then
        for _, questID in ipairs(completedQuestIDs) do
            currentCompletedQuests[questID] = true
            if not suppressOutput then
                if not completedQuests[questID] then
                    PrintQuest("rewarded", questID)
                end
            end
        end
    end
    if not suppressOutput then
        for questID, _ in pairs(completedQuests) do
            if not currentCompletedQuests[questID] then
                PrintQuest("reverted", questID)
            end
        end
    end
    completedQuests = currentCompletedQuests

    PrintQuestsSavedData = PrintQuestsSavedData or {}
    PrintQuestsSavedData.completedQuests = completedQuests
    PrintQuestsSavedData.initialized = true
end

local lastQueryTime = 0
local QUERY_THROTTLE_INTERVAL = 0.25
local function ThrottledQueryCompletedQuests()
    if not isReady then return end
    local currentTime = GetTime()
    if currentTime - lastQueryTime > QUERY_THROTTLE_INTERVAL then
        QueryCompletedQuests(false)
        lastQueryTime = currentTime
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "PrintQuests" then
            if PrintQuestsSavedData and PrintQuestsSavedData.completedQuests then
                completedQuests = PrintQuestsSavedData.completedQuests
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isFirstEverRun = not (PrintQuestsSavedData and PrintQuestsSavedData.initialized)
        QueryCompletedQuests(isFirstEverRun)
        isReady = true
    elseif event == "QUEST_DATA_LOAD_RESULT" then
        local questID, success = ...
        FlushPrintQueue(questID)
    elseif event == "CRITERIA_UPDATE" or event == "QUEST_LOG_UPDATE" then
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
    elseif event == "QUEST_WATCH_UPDATE" then
        local questID = ...
        C_Timer.After(0.1, function()
            if C_QuestLog.ReadyForTurnIn(questID) then
                PrintQuest("completed", questID)
                ThrottledQueryCompletedQuests()
            end
        end)
    end
end)
