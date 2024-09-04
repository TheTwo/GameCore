--- scene:scene_league_popup_impeach_vote

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local UIHelper = require("UIHelper")
local DBEntityPath = require("DBEntityPath")
local TimeFormatter = require("TimeFormatter")
local ConfigRefer = require("ConfigRefer")
local ConfigTimeUtility = require("ConfigTimeUtility")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceImpeachmentVoteMediator:BaseUIMediator
---@field new fun():AllianceImpeachmentVoteMediator
---@field super BaseUIMediator
local AllianceImpeachmentVoteMediator = class('AllianceImpeachmentVoteMediator', BaseUIMediator)

function AllianceImpeachmentVoteMediator:ctor()
    AllianceImpeachmentVoteMediator.super.ctor(self)
    self._allianceId = 0
    self._selfPlayerFacebookId = 0
    self._votePerformed = false
    ---@type AllianceImpeachInfo
    self._impeachInfo = nil
end

function AllianceImpeachmentVoteMediator:OnCreate(param)
    ---@see CommonPopupBackComponent
    self._child_popup_base_l = self:LuaBaseComponent("child_popup_base_l")
    self._p_text_detail = self:Text("p_text_detail")
    self._p_text_time = self:Text("p_text_time")
    self._p_text_detail_hint = self:Text("p_text_detail_hint", "")
    self._p_text_list = self:Text("p_text_list", "alliance_retire_impeach_votelist")
    self._p_btn_list = self:Button("p_btn_list", Delegate.GetOrCreate(self, self.OnClickBtnDetailList))
    self._p_progress = self:Slider("p_progress")
    self._p_text_support = self:Text("p_text_support")
    self._p_text_oppose = self:Text("p_text_oppose")
    self._p_btn_support = self:Button("p_btn_support", Delegate.GetOrCreate(self, self.OnClickBtnNo))
    self._p_btn_oppose = self:Button("p_btn_oppose", Delegate.GetOrCreate(self, self.OnClickBtnYes))
    self._p_btn_text_support = self:Text("p_btn_text_support", "alliance_retire_impeach_againstbtn")
    self._p_btn_text_oppose = self:Text("p_btn_text_oppose", "alliance_retire_impeach_supportbtn")
end

function AllianceImpeachmentVoteMediator:OnOpened(param)
    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    self._selfPlayerFacebookId = ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID
    ---@type CommonBackButtonData
    local backBtnData = {}
    backBtnData.title = I18N.Get("alliance_retire_impeach_title")
    self._child_popup_base_l:FeedData(backBtnData)
    self:RefreshDetail()
end

function AllianceImpeachmentVoteMediator:RefreshDetail()
    ---@type AllianceImpeachInfo
    self._impeachInfo = ModuleRefer.AllianceModule:GetMyAllianceImpeachInfo()
    self._votePerformed = false
    if not self._impeachInfo.IsImpeach then
        self:CloseSelf()
        return
    end
    self._votePerformed = (self._impeachInfo.AgreeFbIds[self._selfPlayerFacebookId] ~= nil or self._impeachInfo.DisAgreeFbIds[self._selfPlayerFacebookId] ~= nil)
    UIHelper.SetGray(self._p_btn_support.gameObject, self._votePerformed)
    UIHelper.SetGray(self._p_btn_oppose.gameObject, self._votePerformed)
    local agreeCount = table.nums(self._impeachInfo.AgreeFbIds)
    local disagreeCount = table.nums(self._impeachInfo.DisAgreeFbIds)
    local p = math.inverseLerp(0, agreeCount + disagreeCount, disagreeCount)
    self._p_progress.value = p
    self._p_text_support.text = tostring(agreeCount)--I18N.GetWithParams("alliance_retire_impeach_support", tostring(agreeCount))
    self._p_text_oppose.text = tostring(disagreeCount)--I18N.GetWithParams("alliance_retire_impeach_against", tostring(disagreeCount))
    
    local impeachmentTime = ConfigTimeUtility.NsToSeconds(ConfigRefer.AllianceConsts:ImpeachWaitTime())
    local toHour = impeachmentTime / 60 // 60
    local needCount = ConfigRefer.AllianceConsts:ImpeachNeedMemberCount()
    self._p_text_detail.text = I18N.GetWithParams("alliance_retire_impeach_desc2", ("%d"):format(math.floor(toHour + 0.5)), needCount, self._impeachInfo.ImpeachNewLeaderName)
end

function AllianceImpeachmentVoteMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TickSec))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.AgreeFbIds.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.DisAgreeFbIds.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.IsImpeach.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.ImpeachEndTime.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.ImpeacherFacebookId.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.ImpeacherName.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.ImpeachNewLeaderFacebookId.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.ImpeachNewLeaderName.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
end

function AllianceImpeachmentVoteMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TickSec))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.AgreeFbIds.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.DisAgreeFbIds.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.IsImpeach.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.ImpeachEndTime.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.ImpeacherFacebookId.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.ImpeacherName.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.ImpeachNewLeaderFacebookId.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLeaderCtrl.ImpeachNewLeaderName.MsgPath, Delegate.GetOrCreate(self, self.OnImpeachInfoChanged))
end

function AllianceImpeachmentVoteMediator:OnClickBtnDetailList()
    g_Game.UIManager:Open(UIMediatorNames.AllianceImpeachmentVoteListMediator)
end

function AllianceImpeachmentVoteMediator:OnClickBtnYes()
    if self._votePerformed then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_retire_impeach_voteagain_toast"))
        return
    end
    ModuleRefer.AllianceModule:VoteForImpeachment(self._p_btn_oppose.transform, true, function(cmd, isSuccess, rsp) 
        self:RefreshDetail()
    end)
end

function AllianceImpeachmentVoteMediator:OnClickBtnNo()
    if self._votePerformed then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_retire_impeach_voteagain_toast"))
        return
    end
    ModuleRefer.AllianceModule:VoteForImpeachment(self._p_btn_oppose.transform, false, function(cmd, isSuccess, rsp)
        self:RefreshDetail()
    end)
end

function AllianceImpeachmentVoteMediator:OnLeaveAlliance()
    self:CloseSelf()
end

---@param entity wds.Alliance
function AllianceImpeachmentVoteMediator:OnImpeachInfoChanged(entity, _)
    if not entity or entity.ID ~= self._allianceId then
        return
    end
    self:RefreshDetail()
end

function AllianceImpeachmentVoteMediator:TickSec(dt)
    if not self._impeachInfo or not self._impeachInfo.IsImpeach then
        return
    end
    local leftTime = self._impeachInfo.ImpeachEndTime.ServerSecond - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    leftTime = math.max(0, leftTime)
    self._p_text_time.text = I18N.GetWithParams("alliance_retire_impeach_remainder", TimeFormatter.SimpleFormatTimeWithoutZero(leftTime))
end

return AllianceImpeachmentVoteMediator