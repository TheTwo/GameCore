--- scene:scene_league_tips_inform

local Delegate = require("Delegate")
local TimeFormatter = require("TimeFormatter")
local EventConst = require("EventConst")
local UIHelper = require("UIHelper")
local ModuleRefer = require("ModuleRefer")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceVillageWarInfoTipMediatorParameter
---@field content string
---@field contentStart string
---@field icon string
---@field endTime number|nil
---@field infoId number
---@field villageId number
---@field onclickGoTo fun(param:AllianceVillageWarInfoTipMediatorParameter)
---@field userdata any
---@field isUnderAttack boolean
---@field zeroTimeColor string|nil
---@field conutDown number|nil
---@field typeHash number
---@field delayStartTime number
---@field checkVillageNoInView boolean

---@class AllianceVillageWarInfoTipMediator:BaseUIMediator
---@field new fun():AllianceVillageWarInfoTipMediator
---@field super BaseUIMediator
local AllianceVillageWarInfoTipMediator = class('AllianceVillageWarInfoTipMediator', BaseUIMediator)

function AllianceVillageWarInfoTipMediator:ctor()
    BaseUIMediator.ctor(self)
    self._useTick = nil
    ---@type AllianceVillageWarInfoTipMediatorParameter
    self._parameter = nil
    self._isInShow = false
end

function AllianceVillageWarInfoTipMediator:OnCreate(param)
    self._p_content = self:Transform("p_content")
    ---@type CS.UnityEngine.RectTransform
    self._content_rect = self._p_content:GetChild(0):GetComponent(typeof(CS.UnityEngine.RectTransform))
    self._p_icon = self:Image("p_icon")
    self._p_text_content = self:Text("p_text_content")
    self._p_text_content_1 = self:Text("p_text_content_1")
    self._p_text_time = self:Text("p_text_time")
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickBtnGoto))
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))
    self._p_content:SetVisible(false)
    self._p_vx_inform_trigger = self:AnimTrigger("p_vx_inform_trigger")
end

function AllianceVillageWarInfoTipMediator:OnShow(param)
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_WAR_INFO_REMOVED, Delegate.GetOrCreate(self, self.OnWarInfoRemoved))
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LateTickViewInPos))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
end

---@param param AllianceVillageWarInfoTipMediatorParameter
function AllianceVillageWarInfoTipMediator:OnOpened(param)
    self:DoShow(param)
end

function AllianceVillageWarInfoTipMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_WAR_INFO_REMOVED, Delegate.GetOrCreate(self, self.OnWarInfoRemoved))
    self._useTick = nil
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateTickViewInPos))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
end

---@param param AllianceVillageWarInfoTipMediatorParameter
function AllianceVillageWarInfoTipMediator:DoShow(param)
    ---@type HUDQueryBtnViewPortResponse
    local responseTable = {}
    g_Game.EventManager:TriggerEvent(EventConst.HUD_QUERY_ALLIANCE_ENTRY_VIEWPORT, responseTable)
    if not responseTable.viewPortPos then
        self:CloseSelf()
        return
    end
    --local fadeOutTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() + 5
    local uiCamera = g_Game.UIManager:GetUICamera()
    local pos = uiCamera:ViewportToWorldPoint(responseTable.viewPortPos)
    self._p_content.anchoredPosition3D = self._p_content.parent:InverseTransformPoint(pos)
    self._parameter = param
    self._useTick = param.endTime
    self._p_text_content.text = param.content
    self._p_text_content_1.text = param.contentStart
    self._p_text_content:SetVisible(true)
    self._p_text_content_1:SetVisible(false)
    self._p_text_time:SetVisible(self._useTick)
    self._p_btn_goto:SetVisible(param.onclickGoTo ~= nil)
    g_Game.SpriteManager:LoadSprite(param.icon, self._p_icon)
    self._p_content:SetVisible(true)
    self._isInShow = true
    self._p_vx_inform_trigger:PlayAll(self._parameter.isUnderAttack and CS.FpAnimation.CommonTriggerType.Custom2 or CS.FpAnimation.CommonTriggerType.Custom1)
end

function AllianceVillageWarInfoTipMediator:OnClickBtnGoto()
    if self._parameter and self._parameter.onclickGoTo then
        self._parameter.onclickGoTo(self._parameter)
        self:CloseSelf()
    end
end

function AllianceVillageWarInfoTipMediator:Tick(dt)
    if not self._useTick then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    if self._useTick < nowTime then
        self._useTick = nil
        self:CloseSelf()
        return
    end
    if not self._parameter or not self._parameter.endTime then
        return
    end
    local leftTime = math.max(0, self._parameter.endTime - nowTime)
    if leftTime <= 6 and self._parameter.checkVillageNoInView then
        local inViewVillageId,typeHash = ModuleRefer.VillageModule:GetCurrentInViewVillage()
        if inViewVillageId
            and typeHash
            and inViewVillageId == self._parameter.villageId
            and typeHash == self._parameter.typeHash
        then
            self._useTick = nil
            self:CloseSelf()
            return
        end
    end
    local timeStr = TimeFormatter.SimpleFormatTimeWithDay(leftTime)
    if leftTime < 1 and not string.IsNullOrEmpty(self._parameter.contentStart) then
        self._p_text_content_1:SetVisible(true)
        self._p_text_content:SetVisible(false)
        self._p_text_time:SetVisible(false)
    end
    if self._parameter.conutDown and leftTime <= self._parameter.conutDown then
        timeStr = tostring(math.floor(leftTime + 0.5))
    end
    if leftTime < 1 and self._parameter.zeroTimeColor then
        timeStr = UIHelper.GetColoredText(timeStr, self._parameter.zeroTimeColor)
    end
    self._p_text_time.text = timeStr
end

function AllianceVillageWarInfoTipMediator:OnWarInfoRemoved(id)
    if not self._parameter or self._parameter.infoId ~= id then
        return
    end
    self:CloseSelf()
end

function AllianceVillageWarInfoTipMediator:LateTickViewInPos()
    if not self._isInShow then
        return
    end
    ---@type HUDQueryBtnViewPortResponse
    local responseTable = {}
    g_Game.EventManager:TriggerEvent(EventConst.HUD_QUERY_ALLIANCE_ENTRY_VIEWPORT, responseTable)
    if not responseTable.viewPortPos then
        self._p_content:SetVisible(false)
        return
    end
    local canShow = false
    if not responseTable.hide and not g_Game.UIManager:HasAnyDialogUIMediator() then
        canShow = true
    end
    self._p_content:SetVisible(canShow)
    
    local uiCamera = g_Game.UIManager:GetUICamera()
    local pos = uiCamera:ViewportToWorldPoint(responseTable.viewPortPos)
    self._p_content.anchoredPosition3D = self._p_content.parent:InverseTransformPoint(pos)
end

function AllianceVillageWarInfoTipMediator:OnLeaveAlliance(allianceId)
    self:CloseSelf()
end

return AllianceVillageWarInfoTipMediator