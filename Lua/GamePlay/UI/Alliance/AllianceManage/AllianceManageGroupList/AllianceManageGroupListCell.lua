local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local AllianceModuleDefine = require("AllianceModuleDefine")
local DBEntityType = require('DBEntityType')
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceManageGroupListCell:BaseTableViewProCell
---@field new fun():AllianceManageGroupListCell
---@field super BaseTableViewProCell
local AllianceManageGroupListCell = class('AllianceManageGroupListCell', BaseTableViewProCell)

function AllianceManageGroupListCell:OnCreate(param)
    self._selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnClickSelf))
    self._p_img_select = self:GameObject("p_img_select")
    ---@type CommonAllianceLogoComponent
    self._child_league_logo = self:LuaObject("child_league_logo")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_need = self:Text("p_text_need", "request_need")
    self._p_text_free = self:Text("p_text_free", "request_unneeded")
    self._p_text_power = self:Text("p_text_power")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_text_language = self:Text("p_text_language")
    self._p_applied = self:GameObject("p_applied")
    self._p_text_applied = self:Text("p_text_applied", "applied")
    self._icon_area = self:Image('icon_area')
    self._p_text_area = self:Text('p_text_area')
end

---@param data AllianceJoinAllianceCellData
function AllianceManageGroupListCell:OnFeedData(data)
    self._child_league_logo:FeedData(data.info.Flag)
    self._p_text_name.text = string.format('[%s]%s', data.info.Abbr, data.info.Name)
    self._p_text_need:SetVisible(data.info.JoinSetting == AllianceModuleDefine.JoinNeedApply)
    self._p_text_free:SetVisible(data.info.JoinSetting == AllianceModuleDefine.JoinWithoutApply)
    self._p_text_power.text = tostring(math.floor(data.info.Power + 0.5))
    self._p_text_quantity.text = string.format("%d/%d", data.info.MemberCount, data.info.MemberMax)
    self._p_applied:SetVisible(data.isApplied)
    local langId = data.info.Language
    self._p_text_language.text = AllianceModuleDefine.GetConfigLangaugeStr(langId)
    self:UpdateAllianceActive(data.info.Active)
end

function AllianceManageGroupListCell:UpdateAllianceActive(activeValue)
    if activeValue == nil then
        activeValue = 0
    end
    self._icon_area:SetVisible(true)
    self._p_text_area:SetVisible(true)

    local config = AllianceModuleDefine.GetAllianceActiveScoreLevelConfig(activeValue)
    self._p_text_area.text = I18N.Get(config:Name())
    local success,color = CS.UnityEngine.ColorUtility.TryParseHtmlString(config:Color())
    self._p_text_area.color = success and color or CS.UnityEngine.Color.white
    g_Game.SpriteManager:LoadSprite(config:Icon(), self._icon_area)
end

function AllianceManageGroupListCell:OnClickSelf()
    self:SelectSelf()
end

function AllianceManageGroupListCell:Select(param)
    self._p_img_select:SetVisible(true)
end

function AllianceManageGroupListCell:UnSelect(param)
    self._p_img_select:SetVisible(false)
end

return AllianceManageGroupListCell