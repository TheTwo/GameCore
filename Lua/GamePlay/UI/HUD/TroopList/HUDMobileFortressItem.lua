---
local BaseTableViewProCell = require('BaseTableViewProCell')
local UIHelper = require('UIHelper')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local DBEntityPath = require('DBEntityPath')
local EventConst = require('EventConst')
local DBEntityType = require('DBEntityType')
local I18N = require('I18N')
local HeroUIUtilities = require('HeroUIUtilities')
local ConfigRefer = require('ConfigRefer')
local TimeFormatter = require('TimeFormatter')
local AllianceAuthorityItem = require('AllianceAuthorityItem')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
---@class HUDMobileFortressItem : BaseUIComponent
local HUDMobileFortressItem = class('HUDMobileFortressItem',BaseTableViewProCell)


function HUDMobileFortressItem:OnCreate(param)
    self:PointerClick('child_card_monster',Delegate.GetOrCreate(self,self.OnClickMobileFortress))

    self.imgStatus = self:Image('p_base_status')
    self.imgIconStatus = self:Image('p_icon_status')
    self.sliderTroopHp = self:Slider('p_troop_hp')
    self.imgHero = self:Image('p_img_hero')
    ---@type CommonTimer
	self.battleTimer = self:LuaObject("p_time")    

    self.vfxTrigger = self:AnimTrigger('vx_trigger')

    self.textLvl = self:Text('p_text_lv')

    self.kingdomInteraction = ModuleRefer.KingdomInteractionModule
    self.slgModule = ModuleRefer.SlgModule
end

---@param param HUDTroopListData
function HUDMobileFortressItem:OnFeedData(param)
    local fortressData = param.behemothInfo
    local configId = fortressData.configId
    self.vanishTime = fortressData.vanishTime
    if configId then        
        local heroConfig = nil
        local behemothTid = configId
        local monsterCfg = ConfigRefer.KmonsterData:Find(behemothTid)
        if monsterCfg and monsterCfg:HeroLength() > 0 then
            local mainInfo = monsterCfg:Hero(1)
            local heroNpcConfig = mainInfo and ConfigRefer.HeroNpc:Find(mainInfo:HeroConf()) or nil
            if heroNpcConfig then            
                heroConfig = ConfigRefer.Heroes:Find(heroNpcConfig:HeroConfigId())
            end
        end 

        if heroConfig then
            local heroIcon = ConfigRefer.HeroClientRes:Find(heroConfig:ClientResCfg()):HeadMini()
            self:LoadSprite(heroIcon, self.imgHero)
        end
    end

    self._entity = fortressData.entity
    if self._entity then
        local battleData = self._entity.Battle
        if battleData then
            self.sliderTroopHp.value = battleData.Hp / battleData.MaxHp
            local backName = nil
            local iconName = nil
            if self._entity.ID> 0 then
                ---@type wds.Troop
                iconName,backName = HeroUIUtilities.TroopStateIcon(self._entity)
            else
                iconName,backName = HeroUIUtilities.TroopStateIcon(nil)
            end

            UIHelper.LoadSprite(iconName,self.imgIconStatus)
            UIHelper.LoadSprite(backName,self.imgStatus)

            if self.kingdomInteraction then
                self:DragEvent('child_card_monster',
                        Delegate.GetOrCreate(self,self.OnTroopDragBegin) ,
                        Delegate.GetOrCreate(self,self.OnTroopDrag) ,
                        Delegate.GetOrCreate(self,self.OnEndTroopDrag),
                        true)
                self:DragCancelEvent('',Delegate.GetOrCreate(self,self.OnTroopDragCancel))
            end

        end
        self.textLvl.text = tostring( ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceLevel())
    end
    
    self.isWarning = false
    self:CheckAndShowVanishWarning()
    self.InitTimer = true
    self.battleTimer.CSComponent:SetVisible(true)
    self.battleTimer:RecycleTimer()         
    self.battleTimer:FeedData(                
    ---@type CommonTimerData    
    {
        infoString = I18N.Get('alliance_behemoth_summon_time'),
        endTime = self.vanishTime,
        needTimer = true,
        overrideTimeFormat = TimeFormatter.SimpleFormatTimeWithoutHour,
        intervalTime = 0.2,       
    })
    g_Game:AddSecondTicker( Delegate.GetOrCreate(self,self.CheckAndShowVanishWarning))    
end

function HUDMobileFortressItem:OnHide()
    if not self.InitTimer then
        return
    end
    self.InitTimer = false
    self.battleTimer:RecycleTimer()
    g_Game:RemoveSecondTicker( Delegate.GetOrCreate(self,self.CheckAndShowVanishWarning))
    self.vfxTrigger:FinishAll(FpAnimTriggerEvent.Custom2)
end

function HUDMobileFortressItem:CheckAndShowVanishWarning()
    if self.isWarning then
        return
    end
    if self.vanishTime - g_Game.ServerTime:GetServerTimestampInSeconds() < 60 then
        self.isWarning = true
        self.vfxTrigger:PlayAll(FpAnimTriggerEvent.Custom2)
    end
end

function HUDMobileFortressItem:OnClickMobileFortress()
    if not self._entity or self.isDragingTroop then
        return
    end
    
    local ctrl = self.slgModule:GetTroopCtrl(self._entity.ID)
    self.slgModule:SelectAndOpenTroopMenu(ctrl)
    self.slgModule:LookAtTroop(ctrl)
end

---@param go CS.UnityEngine.GameObject
---@param event CS.UnityEngine.EventSystems.PointerEventData
function HUDMobileFortressItem:OnTroopDragBegin(go,event)

    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.MoveMobileFortress) then
        return
    end
    if self._entity.BehemothTroopInfo and self._entity.BehemothTroopInfo.MonsterTid ~= 0 then
        if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.SummonBehemoth) then
            return
        end
    end

    if  not self.isDragingTroop then
        if self._entity and self._entity.ID > 0 then        
            local selectTroop = self.slgModule.troopManager:FindTroopCtrl(self._entity.ID)
            if selectTroop == nil or not selectTroop:CanSelect() then
                return
            end

            local seleCount = self.slgModule.selectManager:GetSelectCount()
            if seleCount > 1 and  not self.slgModule.selectManager:IsCtrlSelected(selectTroop) then
                return
            end

            self.isDragingTroop = true
            if seleCount < 2 then
                self.slgModule.selectManager:SetSelect(selectTroop)
            end
            self.kingdomInteraction:SetupDragTrans(selectTroop.troopView.trans)
            self.slgModule.touchManager:SetPressOnCtrl(selectTroop)
            self.kingdomInteraction:DoOnDragStart(event.position)
        end
    end
end

---@param go CS.UnityEngine.GameObject
---@param event CS.UnityEngine.EventSystems.PointerEventData
function HUDMobileFortressItem:OnTroopDrag(go,event)
    if not self.isDragingTroop then
        return
    end
    self.kingdomInteraction:DoOnDragUpdate(event.position)
end

---@param go CS.UnityEngine.GameObject
---@param event CS.UnityEngine.EventSystems.PointerEventData
function HUDMobileFortressItem:OnEndTroopDrag(go,event)
    if not self.isDragingTroop then
        return
    end
    self.isDragingTroop = false
    self.kingdomInteraction:DoOnDragStop(event.position)
    self.kingdomInteraction:SetupDragTrans(nil)
end

function HUDMobileFortressItem:OnTroopDragCancel(go)
    self.isDragingTroop = false
    self.kingdomInteraction:DoCancelDrag()
end

return HUDMobileFortressItem