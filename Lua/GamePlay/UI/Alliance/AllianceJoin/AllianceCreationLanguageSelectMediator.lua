local BaseUIMediator = require("BaseUIMediator")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
---@class AllianceCreationLanguageSelectMediator:BaseUIMediator
local AllianceCreationLanguageSelectMediator = class("AllianceCreationLanguageSelectMediator", BaseUIMediator)

---@class AllianceCreationLanguageSelectMediatorParam
---@field selectedLangId number

function AllianceCreationLanguageSelectMediator:ctor()
end

function AllianceCreationLanguageSelectMediator:OnCreate()
    self.textTitle = self:Text("p_text_title", 'alliance_create_tips_language')
    self.tableLanguage = self:TableViewPro("p_table_language")
    ---@see CommonPopupBackLargeComponent
    self.luaBackGround = self:LuaObject("child_popup_base_l")
end

---@param param AllianceCreationLanguageSelectMediatorParam
function AllianceCreationLanguageSelectMediator:OnOpened(param)
    self.luaBackGround:FeedData({
        title = I18N.Get("alliance_create_title_language")
    })

    self.tableLanguage:Clear()
    ---@type AllianceCreationLanguageSelectCellParam
    local data = {}
    data.langId = 0
    data.selected = data.langId == param.selectedLangId
    self.tableLanguage:AppendData(data)
    for _, v in ConfigRefer.Language:ipairs() do
        ---@type AllianceCreationLanguageSelectCellParam
        local data = {}
        data.langId = v:Id()
        data.selected = data.langId == param.selectedLangId
        self.tableLanguage:AppendData(data)
    end
end

return AllianceCreationLanguageSelectMediator