-- scene:scene_construction_resident_feedback
local Delegate = require("Delegate")
local UIHelper = require("UIHelper")
local EventConst = require("EventConst")
---@type CS.UnityEngine.Vector3
local Vector3 = CS.UnityEngine.Vector3

local BaseUIMediator = require("BaseUIMediator")

---@class CityCitizenResidentFeedbackUIMediator:BaseUIMediator
---@field new fun():CityCitizenResidentFeedbackUIMediator
---@field super BaseUIMediator
local CityCitizenResidentFeedbackUIMediator = class('CityCitizenResidentFeedbackUIMediator', BaseUIMediator)

function CityCitizenResidentFeedbackUIMediator:ctor()
    BaseUIMediator.ctor(self)
    
    ---@type CityCitizenResidentFeedbackPaperCell
    self._showingPaper = nil
    ---@type CityCitizenResidentFeedbackPaperCell
    self._waitingPaper = nil
    
    self._isChangingNext = false
end

function CityCitizenResidentFeedbackUIMediator:OnCreate(param)
    self._p_btn_empty = self:Button("p_btn_empty", Delegate.GetOrCreate(self, self.OnClickEmpty))
    self._p_btn = self:Button("p_btn", Delegate.GetOrCreate(self, self.OnClickNext))
    ---@type CityCitizenResidentFeedbackLeftPortrait
    self._p_hero_pos = self:LuaObject("p_hero_pos")
    self._p_papercontainer = self:Transform("p_papercontainer")
    self._p_img_paperwork = self:LuaBaseComponent("p_img_paperwork")
    self._p_comp_btn_a_l_u2_editor = self:Button("p_comp_btn_a_l_u2", Delegate.GetOrCreate(self, self.OnClickEmpty))
    self._p_text = self:Text("p_text", "citizen_recieve_btn")
    
    
    self._p_img_paperwork:SetVisible(false)
end

---@param param CityCitizenResidentFeedbackUIDataProvider
function CityCitizenResidentFeedbackUIMediator:OnOpened(param)
    self._provider = param
    self._p_hero_pos:FeedData(param:CloneQueue())
    self:OnClickNext()
    self._provider:SetOnAddNew(Delegate.GetOrCreate(self, self.OnAddNew))
end

function CityCitizenResidentFeedbackUIMediator:OnClose(data)
    if self._provider then
        self._provider:Release()
        self._provider = nil
    end
end

function CityCitizenResidentFeedbackUIMediator:OnClickNext()
    if self._isChangingNext then
        return
    end
    local next = self._provider:Dequeue()
    if next then
        self:PlayNext(next)
    else
        self:OnClickEmpty()
    end
end

---@param next CityCitizenResidentFeedbackPaperCellParameter
function CityCitizenResidentFeedbackUIMediator:PrepareNext(next)
    if not next then
        return
    end
    local w = UIHelper.DuplicateUIComponent(self._p_img_paperwork, self._p_papercontainer)
    ---@type CS.DragonReborn.UI.LuaBaseComponent
    local luaBaseComponent = w:GetWithUniqueName("",typeof(CS.DragonReborn.UI.LuaBaseComponent))
    self._waitingPaper = luaBaseComponent.Lua
    self._waitingPaper:FeedData(next)
    local rt = self._waitingPaper:RectTransform()
    rt.localPosition = Vector3.zero
    rt:SetAsFirstSibling()
    self._waitingPaper:SetVisible(true)
end

---@param next CityCitizenResidentFeedbackPaperCellParameter
function CityCitizenResidentFeedbackUIMediator:PlayNext(next)
    self._isChangingNext = true
    self:PrepareNext(next)
    if self._p_hero_pos:IsPlaying() then
        self._p_hero_pos:ForwardEnd()
    end
    if self._showingPaper then
        self._p_hero_pos:PlayMoving()
        self._showingPaper:FastForwardCollectAni()
        self._showingPaper:PlayFlyawayThenDestroy(Delegate.GetOrCreate(self, self.OnNextShow))
        self._showingPaper = self._waitingPaper
        self._waitingPaper = nil
    else
        self._showingPaper = self._waitingPaper
        self._waitingPaper = nil
        self:OnNextShow()
    end
end

function CityCitizenResidentFeedbackUIMediator:OnNextShow()
    self._showingPaper:OnPlayCollectAni()
    self._isChangingNext = false
end

function CityCitizenResidentFeedbackUIMediator:OnClickEmpty()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_FEEDBACK_END_TRIGGER_HUD_EFFECT)
    self:CloseSelf()
end

function CityCitizenResidentFeedbackUIMediator:OnAddNew(citizenConfig)
    self._p_hero_pos:AppendData(citizenConfig)
end

return CityCitizenResidentFeedbackUIMediator

