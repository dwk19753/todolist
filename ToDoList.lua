-- =========================
-- Defaults
-- =========================

local DEFAULTS = {
    daily = {
        { text = "Do World Quests", completed = false },
        { text = "Run a Mythic+", completed = false },
    },
    weekly = {
        { text = "Raid Vault", completed = false },
        { text = "Weekly Dungeon Quest", completed = false },
    },
    lastDailyReset = 0,
    lastWeeklyReset = 0,
}

-- =========================
-- Utility Functions
-- =========================

local function CopyDefaults(src, dest)
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = dest[k] or {}
            CopyDefaults(v, dest[k])
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
end

local function GetStartOfDay(timestamp)
    local t = date("*t", timestamp)
    t.hour = 0
    t.min = 0
    t.sec = 0
    return time(t)
end

local function GetStartOfWeek(timestamp)
    local t = date("*t", timestamp)
    local day = t.wday -- 1=Sunday, 2=Monday, 3=Tuesday
    local diff = (day - 3) % 7 -- Tuesday reset
    t.day = t.day - diff
    t.hour = 0
    t.min = 0
    t.sec = 0
    return time(t)
end

local function ResetIfNeeded()
    local now = GetServerTime()

    -- Daily
    local todayStart = GetStartOfDay(now)
    if todayStart > TodoListDB.lastDailyReset then
        for _, task in ipairs(TodoListDB.daily) do
            task.completed = false
        end
        TodoListDB.lastDailyReset = todayStart
    end

    -- Weekly
    local weekStart = GetStartOfWeek(now)
    if weekStart > TodoListDB.lastWeeklyReset then
        for _, task in ipairs(TodoListDB.weekly) do
            task.completed = false
        end
        TodoListDB.lastWeeklyReset = weekStart
    end
end

-- =========================
-- UI
-- =========================

local frame = CreateFrame("Frame", "TodoListFrame", UIParent, "BasicFrameTemplateWithInset")




frame:SetSize(300, 400)
frame:SetPoint("CENTER")

-- Make resizable
frame:SetResizable(true)
frame:SetClampedToScreen(true)

-- Resize handle
local resizeButton = CreateFrame("Button", nil, frame)
resizeButton:SetPoint("BOTTOMRIGHT")
resizeButton:SetSize(16, 16)

resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

resizeButton:SetScript("OnMouseDown", function()
    frame:StartSizing("BOTTOMRIGHT")
end)

resizeButton:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing()

    if TodoListDB then
        TodoListDB.width = frame:GetWidth()
        TodoListDB.height = frame:GetHeight()
    end
end)



frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
frame.title:SetText("Todo List")

local function CreateSectionTitle(parent, text, yOffset)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 15, yOffset)
    title:SetText(text)
    return title
end

local function CreateCheckbox(parent, taskTable, taskIndex, taskType, yOffset)
    local task = taskTable[taskIndex]

    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", 20, yOffset)
    checkbox:SetChecked(task.completed)

    checkbox.text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkbox.text:SetText(task.text)

    checkbox:SetScript("OnClick", function(self)
        task.completed = self:GetChecked()
    end)

    table.insert(frame.contentElements, checkbox)

    -- Delete button
    local deleteBtn = CreateFrame("Button", nil, parent, "UIPanelCloseButton")
    deleteBtn:SetSize(20, 20)
    deleteBtn:SetPoint("LEFT", checkbox.text, "RIGHT", 5, 0)

    deleteBtn:SetScript("OnClick", function()
        table.remove(taskTable, taskIndex)
        BuildUI()
    end)

    table.insert(frame.contentElements, deleteBtn)
end


local function ClearContent()
    if frame.contentElements then
        for _, element in ipairs(frame.contentElements) do
            element:Hide()
            element:SetParent(nil)
        end
    end
    frame.contentElements = {}
end


function BuildUI()
    ClearContent()

    local y = -40

    -- Daily Section
    local dailyTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dailyTitle:SetPoint("TOPLEFT", 15, y)
    dailyTitle:SetText("Daily")
    table.insert(frame.contentElements, dailyTitle)

    y = y - 30

    for i = 1, #TodoListDB.daily do
        CreateCheckbox(frame, TodoListDB.daily, i, "daily", y)
        y = y - 25
    end

    -- Add Daily Button
    local addDailyBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    addDailyBtn:SetSize(100, 22)
    addDailyBtn:SetPoint("TOPLEFT", 20, y)
    addDailyBtn:SetText("+ Add Daily")

    addDailyBtn:SetScript("OnClick", function()
        StaticPopup_Show("TODO_ADD_DAILY")
    end)

    table.insert(frame.contentElements, addDailyBtn)

    y = y - 40

    -- Weekly Section
    local weeklyTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    weeklyTitle:SetPoint("TOPLEFT", 15, y)
    weeklyTitle:SetText("Weekly")
    table.insert(frame.contentElements, weeklyTitle)

    y = y - 30

    for i = 1, #TodoListDB.weekly do
        CreateCheckbox(frame, TodoListDB.weekly, i, "weekly", y)
        y = y - 25
    end

    -- Add Weekly Button
    local addWeeklyBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    addWeeklyBtn:SetSize(100, 22)
    addWeeklyBtn:SetPoint("TOPLEFT", 20, y)
    addWeeklyBtn:SetText("+ Add Weekly")

    addWeeklyBtn:SetScript("OnClick", function()
        StaticPopup_Show("TODO_ADD_WEEKLY")
    end)

    table.insert(frame.contentElements, addWeeklyBtn)
end


-- =========================
-- Initialization
-- =========================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function()
    if not TodoListDB then
        TodoListDB = {}
    end

    CopyDefaults(DEFAULTS, TodoListDB)
    ResetIfNeeded()
    BuildUI()
end)

-- =========================
-- Popup Dialogs
-- =========================

StaticPopupDialogs["TODO_ADD_DAILY"] = {
    text = "Enter Daily Task",
    button1 = "Add",
    button2 = "Cancel",
    hasEditBox = true,
    maxLetters = 100,
    OnAccept = function(popup)
        local editBox = popup.editBox or _G[popup:GetName() .. "EditBox"]
        local text = editBox and editBox:GetText()

        if text and text ~= "" then
            table.insert(TodoListDB.daily, {
                text = text,
                completed = false
            })
            BuildUI()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["TODO_ADD_WEEKLY"] = {
    text = "Enter Weekly Task",
    button1 = "Add",
    button2 = "Cancel",
    hasEditBox = true,
    maxLetters = 100,
    OnAccept = function(popup)
        local editBox = popup.editBox or _G[popup:GetName() .. "EditBox"]
        local text = editBox and editBox:GetText()

        if text and text ~= "" then
            table.insert(TodoListDB.weekly, {
                text = text,
                completed = false
            })
            BuildUI()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}


-- =========================
-- Slash Command
-- =========================

SLASH_TODOLIST1 = "/todo"

SlashCmdList["TODOLIST"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
