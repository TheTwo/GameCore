local BaseTableViewProCell = require("BaseTableViewProCell")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local AllianceModuleDefine = require("AllianceModuleDefine")
---@class AllianceCreationLanguageSelectCell:BaseTableViewProCell
local AllianceCreationLanguageSelectCell = class("AllianceCreationLanguageSelectCell", BaseTableViewProCell)

---@class AllianceCreationLanguageSelectCellParam
---@field langId number @Language CfgId or 0 for "All"
---@field selected boolean

function AllianceCreationLanguageSelectCell:ctor()
end

function AllianceCreationLanguageSelectCell:OnCreate()
    self.textLanguage = self:Text("p_text_language")
    self.statusCtrler = self:StatusRecordParent("child_toggle_dot")
    self.btnToggle = self:Button("child_toggle_dot", Delegate.GetOrCreate(self, self.OnBtnToggleClicked))
end

---@param param AllianceCreationLanguageSelectCellParam
function AllianceCreationLanguageSelectCell:OnFeedData(param)
    self.data = param
    self.textLanguage.text = AllianceModuleDefine.GetConfigLangaugeStr(param.langId)
    if param.selected then
        self:SelectSelf()
    end
end

function AllianceCreationLanguageSelectCell:Select()
    self.data.selected = true
    self.statusCtrler:ApplyStatusRecord(1)
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_CREATION_LANGUAGE_SELECT, self.data.langId)
end

function AllianceCreationLanguageSelectCell:UnSelect()
    self.data.selected = false
    self.statusCtrler:ApplyStatusRecord(0)
end

function AllianceCreationLanguageSelectCell:OnBtnToggleClicked()
    self:SelectSelf()
end

return AllianceCreationLanguageSelectCell