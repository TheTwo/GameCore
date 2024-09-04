--- scene:scene_league_initial

local EventConst = require("EventConst")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local UIHelper = require("UIHelper")
local ModuleRefer = require("ModuleRefer")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceInitialMediator:BaseUIMediator
---@field new fun():AllianceInitialMediator
---@field super BaseUIMediator
local AllianceInitialMediator = class('AllianceInitialMediator', BaseUIMediator)

function AllianceInitialMediator:OnCreate(param)
    self._p_title = self:Text("p_title", "league_recruit")
    self._p_comp_btn_create = self:Button("p_comp_btn_create", Delegate.GetOrCreate(self, self.OnClickCreateAlliance))
    self._p_text_create = self:Text("p_text_create", "create_league")
    self._p_comp_btn_join = self:Button("p_comp_btn_join", Delegate.GetOrCreate(self, self.OnClickJoinAlliance))
    self._p_text_join = self:Text("p_text_join", "join_league")
    self._p_btn_back = self:Button("p_btn_back", Delegate.GetOrCreate(self, self.CloseSelf))
    
    self._p_text_1 = self:Text("p_text_1", "recruit_title_1")
    self._p_text_2 = self:Text("p_text_2", "recruit_content_1")
    self._p_text_3 = self:Text("p_text_3", "recruit_title_2")
    self._p_text_4 = self:Text("p_text_4", "recruit_content_2")
    self._p_text_5 = self:Text("p_text_5", "recruit_title_3")
    self._p_text_6 = self:Text("p_text_6", "recruit_content_3")
    self._p_text_award = self:Text("p_text_award")

    self.p_hint_invitation = self:GameObject('p_hint_invitation')
    self.p_text_hint_invitation = self:Text("p_text_hint_invitation")
    self.p_hint_invitation:SetVisible(false)
end

function AllianceInitialMediator.BuildInTextImagePart(itemId, count, fontSize)
    local icon = ConfigRefer.Item:Find(itemId)
    return ("<quad name=%s size=%d width=1 /> %d"):format(UIHelper.IconOrMissing(icon and icon:Icon()), fontSize, count)
end

function AllianceInitialMediator:OnShow(param)
    local config = ConfigRefer.ItemGroup:Find(ConfigRefer.AllianceConsts:AllianceRewardOnJoinFirst())
    local rewardPart = ''
    local fontSize = self._p_text_award.fontSize
    if config:ItemGroupInfoListLength() > 0 then
        local item = config:ItemGroupInfoList(1)
        rewardPart = AllianceInitialMediator.BuildInTextImagePart(item:Items(), item:Nums(), fontSize)
    end
    for i = 2, config:ItemGroupInfoListLength() do
        local item = config:ItemGroupInfoList(i)
        rewardPart = rewardPart .. ", " .. AllianceInitialMediator.BuildInTextImagePart(item:Items(), item:Nums(), fontSize)
    end
    self._p_text_award.text = I18N.GetWithParams("alliance_shoucijiaru", rewardPart)
    self:AddEvents()

    local alliances = ModuleRefer.AllianceModule:GetRecuirtAllianceInfo()
    local count = #alliances
    self.p_text_hint_invitation.text = I18N.GetWithParams("#你有{1}条联盟邀请",count)
    self.p_hint_invitation:SetVisible(count>0)
end

function AllianceInitialMediator:OnHide(param)
    self:RemoveEvents()
end

function AllianceInitialMediator:OnClickCreateAlliance()
    g_Game.UIManager:Open(UIMediatorNames.AllianceCreationMediator)
    self:CloseSelf()
end

function AllianceInitialMediator:OnClickJoinAlliance()
    g_Game.UIManager:Open(UIMediatorNames.AllianceJoinMediator)
    self:CloseSelf()
end

function AllianceInitialMediator:AddEvents()
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_JOINED, Delegate.GetOrCreate(self, self.OnJoinedAlliance))
end

function AllianceInitialMediator:RemoveEvents()
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_JOINED, Delegate.GetOrCreate(self, self.OnJoinedAlliance))
end

function AllianceInitialMediator:OnJoinedAlliance()
    self:CloseSelf()
end

return AllianceInitialMediator