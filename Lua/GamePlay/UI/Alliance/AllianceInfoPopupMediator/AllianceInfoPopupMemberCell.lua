local Delegate = require("Delegate")
local TimeFormatter = require("TimeFormatter")
local ModuleRefer = require("ModuleRefer")
local BaseTableViewProCell = require("BaseTableViewProCell")
local UIMediatorNames = require("UIMediatorNames")

---@class AllianceInfoPopupMemberCell:BaseTableViewProCell
---@field new fun():AllianceInfoPopupMemberCell
---@field super BaseTableViewProCell
local AllianceInfoPopupMemberCell = class('AllianceInfoPopupMemberCell', BaseTableViewProCell)

function AllianceInfoPopupMemberCell:OnCreate(param)
    self._p_frame_head = self:Image("p_frame_head")
    self._p_icon_head = self:Image("p_icon_head")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_power = self:Text("p_text_power")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_text_quantity:SetVisible(false)
    ---@type PlayerInfoComponent
    self._child_ui_head_player = self:LuaObject("child_ui_head_player")
    self._child_ui_head_player:SetClickHeadCallback(Delegate.GetOrCreate(self, self.OnClickPlayerHead))
end

---@param data wds.AllianceMember
function AllianceInfoPopupMemberCell:OnFeedData(data)
    self._playerData = data
    self._playerId = data.PlayerID
    self._p_text_name.text = data.Name
    self._p_text_power.text = tostring(math.floor(data.Power + 0.5))
    self._p_text_quantity.text = tostring(math.floor(data.KillPoint + 0.5))
    self._child_ui_head_player:FeedData(data)
end

function AllianceInfoPopupMemberCell:OnClickPlayerHead()
    -- ---@type AlliancePlayerPopupMediatorData
    -- local param = {}
    -- param.playerData = self._playerData
    -- param.allowAllianceOperation = false
    -- g_Game.UIManager:Open(UIMediatorNames.AlliancePlayerPopupMediator, param)
    ModuleRefer.PlayerModule:ShowPlayerInfoPanel(self._playerData.PlayerID, self._p_text_name)
end

return AllianceInfoPopupMemberCell