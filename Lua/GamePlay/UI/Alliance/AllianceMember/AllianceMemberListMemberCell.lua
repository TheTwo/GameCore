local Delegate = require("Delegate")
local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local ConfigRefer = require("ConfigRefer")
local ConfigTimeUtility = require("ConfigTimeUtility")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceMemberListMemberCell:BaseTableViewProCell
---@field new fun():AllianceMemberListMemberCell
---@field super BaseTableViewProCell
local AllianceMemberListMemberCell = class('AllianceMemberListMemberCell', BaseTableViewProCell)

function AllianceMemberListMemberCell:ctor()
    AllianceMemberListMemberCell.super.ctor(self)
    self._x = nil
    self._y = nil
    self._eventAdd = false
    self._tickShowSwitch = false
    self._roundSwitchTextTime = nil
    self._roundSwitchTime = 3
end

function AllianceMemberListMemberCell:OnCreate(param)
    self._p_frame_head = self:Image("p_frame_head")
    self._p_icon_head = self:Image("p_icon_head")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_state = self:Text("p_text_state")
    self._p_text_power = self:Text("p_text_power")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_text_quantity:SetVisible(false)
    self._p_text_position = self:Text("p_text_position")
    self._p_btn_click_pos = self:Button("p_btn_click_pos", Delegate.GetOrCreate(self, self.OnClickCoord))
    
    ---@type PlayerInfoComponent
    self._child_ui_head_player = self:LuaObject("child_ui_head_player")
    self._child_ui_head_player:SetClickHeadCallback(Delegate.GetOrCreate(self, self.OnClickPlayerHead))
    
    self._p_change = self:GameObject("p_change")
    self._p_progress = self:Slider("p_progress")
    self._p_text_change = self:Text("p_text_change")
    self._p_btn_cancel = self:Button("p_btn_cancel", Delegate.GetOrCreate(self, self.OnClickBtnCancelSwitchLeader))
    self._p_click_rect = self:Button("p_click_rect", Delegate.GetOrCreate(self, self.OnClickPlayerHead))
end

---@param data wds.AllianceMember
function AllianceMemberListMemberCell:OnFeedData(data)
    self._x = data.BigWorldPosition.X
    self._y = data.BigWorldPosition.Y
    self._playerData = data
    self._playerId = data.PlayerID
    self._p_text_name.text = data.Name
    self._p_text_state.text = TimeFormatter.AlliancePlayerLastOnlineTime(data)
    self._p_text_power.text = tostring(math.floor(data.Power + 0.5))
    --self._p_text_quantity.text = tostring(math.floor(data.KillPoint + 0.5))
    self._p_text_position.text = string.format("%d,%d", math.floor(data.BigWorldPosition.X + 0.5), math.floor(data.BigWorldPosition.Y + 0.5))
    if self._playerId == ModuleRefer.PlayerModule.playerId then
        self._child_ui_head_player:FeedData(ModuleRefer.PlayerModule:GetPlayer().Basics.PortraitInfo)
    else
        self._child_ui_head_player:FeedData(self._playerData.PortraitInfo)
    end
    self._tickShowSwitch = ModuleRefer.AllianceModule:IsAllianceMemberSwitchLeaderTarget(data)
    self._p_change:SetVisible(self._tickShowSwitch)
    self._p_btn_cancel:SetVisible(ModuleRefer.AllianceModule:IsAllianceLeader())
    self._roundSwitchTextTime = 3
    self._p_text_change.text = I18N.Get("alliance_retire_transleader_willing")
    self:SetupTick(true)
    self:TickSec(0)
end

function AllianceMemberListMemberCell:OnRecycle()
    self:SetupTick(false)
end

function AllianceMemberListMemberCell:OnShow(param)
    self:SetupTick(true)
end

function AllianceMemberListMemberCell:OnHide(param)
    self:SetupTick(false)
end

function AllianceMemberListMemberCell:OnClose(param)
    self:SetupTick(false)
end

function AllianceMemberListMemberCell:OnClickPlayerHead()
    -- ---@type AlliancePlayerPopupMediatorData
    -- local param = {}
    -- param.playerData = self._playerData
    -- param.allowAllianceOperation = true
    -- g_Game.UIManager:Open(UIMediatorNames.AlliancePlayerPopupMediator, param)
    local isManager = ModuleRefer.AllianceModule:IsAllianceR4Above()
    ModuleRefer.PlayerModule:ShowPlayerInfoPanel(self._playerData.PlayerID, self._p_text_name,isManager)
end

function AllianceMemberListMemberCell:OnClickCoord()
    if not self._x or not self._y then
        return
    end
    AllianceWarTabHelper.GoToCoord(self._x, self._y)
    self:GetParentBaseUIMediator():CloseSelf()
end

function AllianceMemberListMemberCell:SetupTick(add)
    if not self._eventAdd and add then
        self._eventAdd = true
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TickSec))
    elseif self._eventAdd and not add then
        self._eventAdd = false
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TickSec))
    end
end

function AllianceMemberListMemberCell:TickSec(dt)
    if not self._tickShowSwitch then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local endTime = ModuleRefer.AllianceModule:GetSwitchLeaderEndTime()
    local leftTime = endTime - nowTime
    if leftTime <= 0 then
        self._p_change:SetVisible(false)
        self._tickShowSwitch = false
        self._roundSwitchTextTime = nil
        return
    end
    local totalTime = ConfigTimeUtility.NsToSeconds(ConfigRefer.AllianceConsts:SwitchLeaderWaitTime())
    if totalTime <= 0 then
        self._p_change:SetVisible(false)
        self._tickShowSwitch = false
        self._roundSwitchTextTime = nil
        return
    end
    if self._roundSwitchTextTime then
        if self._roundSwitchTextTime > 0 then
            self._roundSwitchTextTime = self._roundSwitchTextTime - dt
            if self._roundSwitchTextTime <= 0 then
                self._roundSwitchTextTime = -1 * self._roundSwitchTime
            end
        else
            self._roundSwitchTextTime = self._roundSwitchTextTime + dt
            if self._roundSwitchTextTime >= 0 then
                self._roundSwitchTextTime = self._roundSwitchTime
                self._p_text_change.text = I18N.Get("alliance_retire_transleader_willing")
            end
        end
        if self._roundSwitchTextTime < 0 then
            self._p_text_change.text = TimeFormatter.SimpleFormatTimeWithoutZero(leftTime)
        end
    else
        self._p_text_change.text = string.Empty
    end
    local progress = math.clamp01(1 - (leftTime / totalTime))
    self._p_progress.value = progress
end

function AllianceMemberListMemberCell:OnClickBtnCancelSwitchLeader()
    if not ModuleRefer.AllianceModule:IsAllianceLeader() then
        return
    end
    ---@type CommonConfirmPopupMediatorParameter
    local confirmParameter = {}
    confirmParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    confirmParameter.content = I18N.Get("alliance_retire_transleader_cancel")
    confirmParameter.confirmLabel = I18N.Get("confirm")
    confirmParameter.cancelLabel = I18N.Get("cancle")
    confirmParameter.onConfirm = function()
        ModuleRefer.AllianceModule:CancelSwitchLeader(self._p_btn_cancel.transform)
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmParameter)
end

return AllianceMemberListMemberCell