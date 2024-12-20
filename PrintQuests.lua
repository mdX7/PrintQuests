
local frame = CreateFrame("Frame")

frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("QUEST_REMOVED")
frame:RegisterEvent("CRITERIA_UPDATE")
frame:RegisterEvent("QUEST_LOG_UPDATE")

local function PrintQuest(printType, questID)
    local questName = C_QuestLog.GetTitleForQuestID(questID)
    if questName then
        print("Quest ".. printType ..": " .. questName .. " (ID: " .. questID .. ")")
    else
        print("Quest ".. printType .." (Tracking): (ID: " .. questID .. ")")
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

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "CRITERIA_UPDATE" or event == "QUEST_LOG_UPDATE" then
        QueryCompletedQuests()
    elseif event == "QUEST_ACCEPTED" then
        local questID = ...
        PrintQuest("accepted", questID)
        QueryCompletedQuests()
    elseif event == "QUEST_TURNED_IN" then
        local questID = ...
        PrintQuest("turned in", questID)
        QueryCompletedQuests()
    elseif event == "QUEST_REMOVED" then
        local questID = ...
        PrintQuest("removed", questID)
        QueryCompletedQuests()
    end
end)
