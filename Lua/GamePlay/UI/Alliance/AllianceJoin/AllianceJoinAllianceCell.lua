local Delegate = require("Delegate")
local AllianceModuleDefine = require("AllianceModuleDefine")
local Utils = require("Utils")
local DBEntityPath = require("DBEntityPath")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceJoinAllianceCellData
---@field info wrpc.AllianceBriefInfo
---@field isApplied boolean

---@class AllianceJoinAllianceCell:BaseTableViewProCell
---@field new fun():AllianceJoinAllianceCell
---@field super BaseTableViewProCell
local AllianceJoinAllianceCell = class('AllianceJoinAllianceCell', BaseTableViewProCell)

function AllianceJoinAllianceCell:ctor()
    BaseTableViewProCell.ctor(self)
    self._eventsAdd = false
    self._allianceId = nil
end

function AllianceJoinAllianceCell:OnCreate(param)
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
    self._p_status = self:StatusRecordParent("")
    self._p_icon_active_level = self:Image("p_icon_active_level")
    self._p_btn_active_level = self:Button("p_btn_active_level",Delegate.GetOrCreate(self, self.OnClickAllianceActive))
end

---@param data AllianceJoinAllianceCellData
function AllianceJoinAllianceCell:OnFeedData(data)
    self._data = data
    self._allianceId = data.info.ID
    self._child_league_logo:FeedData(data.info.Flag)
    self._p_text_name.text = string.format('[%s]%s', data.info.Abbr, data.info.Name)
    self._p_text_need:SetVisible(data.info.JoinSetting == AllianceModuleDefine.JoinNeedApply and not data.isApplied)
    self._p_text_free:SetVisible(data.info.JoinSetting == AllianceModuleDefine.JoinWithoutApply and not data.isApplied)
    self._p_text_power.text = tostring(math.floor(data.info.Power + 0.5))
    self._p_text_quantity.text = string.format("%d/%d", data.info.MemberCount, data.info.MemberMax)
    local langId = data.info.Language
    self._p_text_language.text = AllianceModuleDefine.GetConfigLangaugeStr(langId)
    self._p_applied:SetVisible(data.isApplied)
    self:SetupEvents(true)

	
    local config = AllianceModuleDefine.GetAllianceActiveScoreLevelConfig(data.info.Active)
	if config then
		--self._p_text_active_level.text = I18N.Get(config:Name())
		--local success,color = CS.UnityEngine.ColorUtility.TryParseHtmlString(config:Color())
		--self._p_text_active_level.color = success and color or CS.UnityEngine.Color.white
		self._p_icon_active_level:SetVisible(true)
		g_Game.SpriteManager:LoadSprite(config:Icon(), self._p_icon_active_level)
	else
		self._p_icon_active_level:SetVisible(false)
	end
end

function AllianceJoinAllianceCell:OnRecycle(param)
    self:SetupEvents(false)
end

function AllianceJoinAllianceCell:OnClose(param)
    self:SetupEvents(false)
end

function AllianceJoinAllianceCell:OnClickSelf()
    self:SelectSelf()
end

function AllianceJoinAllianceCell:Select(param)
    self._p_img_select:SetVisible(true)
    if Utils.IsNotNull(self._p_status) then
        self._p_status:SetState(1)
    end
end

function AllianceJoinAllianceCell:UnSelect(param)
    self._p_img_select:SetVisible(false)
    if Utils.IsNotNull(self._p_status) then
        self._p_status:SetState(0)
    end
end

function AllianceJoinAllianceCell:SetupEvents(add)
    if add and not self._eventsAdd then
        self._eventsAdd = true
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerAlliance.AppliedAllianceIDs.MsgPath, Delegate.GetOrCreate(self, self.OnAppliedAllianceIDsChanged))
    elseif not add and self._eventsAdd then
        self._eventsAdd = false
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerAlliance.AppliedAllianceIDs.MsgPath, Delegate.GetOrCreate(self, self.OnAppliedAllianceIDsChanged))
    end
end

---@param entity wds.Player
---@param changeTable table
function AllianceJoinAllianceCell:OnAppliedAllianceIDsChanged(entity, changeTable)
    if entity.ID ~= ModuleRefer.PlayerModule:GetPlayer().ID then
        return
    end
    local needRefresh = false
    if not changeTable then
        return
    end
    if changeTable.Add then
        if changeTable.Add[self._allianceId] then
            needRefresh = 1
        end
    end
    if not needRefresh then
        return
    end
    self._data.isApplied = true
    self._p_applied:SetVisible(true)
    self._p_text_need:SetVisible(false)
    self._p_text_free:SetVisible(false)
end

function AllianceJoinAllianceCell:OnClickAllianceActive()
    local allianceData = self._data.info
    local score = allianceData.Active
    ---@type AllianceActiveTipMediatorParameter
    local param = {}
    param.activeValue = score
    param.clickTrans = self._p_btn_active_level.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    param.hideArrow = true
    g_Game.UIManager:Open(UIMediatorNames.AllianceActiveTipMediator, param)
end

return AllianceJoinAllianceCell
