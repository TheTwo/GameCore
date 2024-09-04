local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local QueuedTask = require('QueuedTask')
local Utils = require('Utils')
---@class GveTroopHint : BaseUIComponent
local GveTroopHint = class('GveTroopHint', BaseUIComponent)

function GveTroopHint:ctor()
    self.module = ModuleRefer.GveModule
    self.slgModule = ModuleRefer.SlgModule
    self.isVisible = true
end

function GveTroopHint:OnCreate()    
    self.goHint = self:GameObject('p_hint')
    self.rectHint = self:RectTransform('p_hint')
    self.goTroopHead = self:GameObject('p_troop_head')
    self.compTroopHead = self:LuaObject('p_troop_head')
    self.goArrow = self:GameObject('p_arrow')
    self.transArrow = self:Transform('p_arrow')
    self:SetUIVisible(false)
end


function GveTroopHint:OnShow(param)
    self:Init()
end

function GveTroopHint:Init()
    local troopData = self.module:GetSelectTroopData()
    if not troopData then
        self.troopId = nil
        self:SetUIVisible(false)
        return
    end
    self.troopId = troopData.ID
    local heroId = troopData.Battle.Group.Heros[0].HeroID
    ---@type HeroInfoData
    local heroInfoData = {
        heroData = ModuleRefer.HeroModule:GetHeroByCfgId(heroId),
        hideExtraInfo = true,
        onClick = Delegate.GetOrCreate(self,self.OnClickHead)
    }
    self.compTroopHead:FeedData(heroInfoData)
    self.troopCtrl = self.slgModule:GetTroopCtrl(self.troopId)
    if not self.troopCtrl then
        return
    end
    if self.troopCtrl:IsValid() and self.troopCtrl:GetCSView() then        
            self.anchorComp = UIHelper.SetWSTransAnchor(self.slgModule:GetCamera(),self.rectHint,self.troopCtrl:GetCSView().transform,true,Delegate.GetOrCreate(self,self.OnVisibleInScreen))        
            self.anchorComp:SetupAnchorSize(self.rectHint.rect)
            UIHelper.SetWSLookAtAnchor(self.slgModule:GetCamera(),self.transArrow,self.troopCtrl:GetCSView().transform,false)
    else
        local task = QueuedTask.new()
        task:WaitTrue(function()
            return self.troopCtrl:IsValid() and self.troopCtrl:GetCSView()
        end):DoAction(
            function()
                self.anchorComp = UIHelper.SetWSTransAnchor(self.slgModule:GetCamera(),self.rectHint,self.troopCtrl:GetCSView().transform,true,Delegate.GetOrCreate(self,self.OnVisibleInScreen))                        
                self.anchorComp:SetupAnchorSize(self.rectHint.rect)
                UIHelper.SetWSLookAtAnchor(self.slgModule:GetCamera(),self.transArrow,self.troopCtrl:GetCSView().transform,false)
            end
        ):Start()
    end    
    -- self:SetUIVisible(false)
end


function GveTroopHint:OnHide(param)
end

function GveTroopHint:OnOpened(param)
end

function GveTroopHint:OnClose(param)
    self.rectHint:SetVisible(false)
end

function GveTroopHint:OnFeedData(param)    

end

function GveTroopHint:OnClickHead()
    local ctrl = self.slgModule:GetTroopCtrl(self.troopId)
    self.slgModule:LookAtTroop(ctrl)
end

function GveTroopHint:OnVisibleInScreen(visible)
    if visible and self.isVisible then
        self:SetUIVisible(false)       
    elseif not visible and not self.isVisible then
        self:SetUIVisible(true)        
    end
end

function GveTroopHint:SetUIVisible(visible)
    self.isVisible = visible
    if Utils.IsNotNull(self.goTroopHead) then
        self.goTroopHead:SetVisible(visible)
        self.goArrow:SetVisible(visible)
    end
end

return GveTroopHint
