local GuideConst = require('GuideConst')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local UIMediatorNames = require('UIMediatorNames')
local CastleCreepSweepByItemParameter = require('CastleCreepSweepByItemParameter')
local CastleAddFurnitureParameter = require('CastleAddFurnitureParameter')
local CastleCreepSprayMedicineParameter = require('CastleCreepSprayMedicineParameter')
local CastleGetProcessOutputParameter = require('CastleGetProcessOutputParameter')
local DBEntityType = require('DBEntityType')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local ClientDataKeys = require('ClientDataKeys')
---@class GuideTriggerWatcher
local GuideTriggerWatcher = class('GuideTriggerWatcher')

function GuideTriggerWatcher:InitWatcher()
    g_Game.EventManager:AddListener(EventConst.ON_UIMEDIATOR_OPENED,Delegate.GetOrCreate(self,self.OnUIMediatorOpened))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_LEVEL_UP_FOR_GUIDE, Delegate.GetOrCreate(self, self.OnBuildingFinish))
    g_Game.EventManager:AddListener(EventConst.CITY_MAIN_BASE_FURNITURE_LEVEL_UP_FOR_GUIDE, Delegate.GetOrCreate(self, self.OnMainBaseFinish))
    g_Game.ServiceManager:AddResponseCallback(CastleAddFurnitureParameter.GetMsgId(),Delegate.GetOrCreate(self,self.OnFurnitureSetup))
    g_Game.EventManager:AddListener(EventConst.QUEST_CHAPTER_FINISH,Delegate.GetOrCreate(self,self.OnQuestChapterFinish))
    g_Game.ServiceManager:AddResponseCallback(CastleCreepSprayMedicineParameter.GetMsgId(),Delegate.GetOrCreate(self,self.OnCastleCreepSprayMedicine))
    g_Game.ServiceManager:AddResponseCallback(CastleCreepSweepByItemParameter.GetMsgId(),Delegate.GetOrCreate(self,self.OnCastleCreepSweep))
    g_Game.ServiceManager:AddResponseCallback(CastleGetProcessOutputParameter.GetMsgId(),Delegate.GetOrCreate(self,self.OnCollectExit))
    g_Game.EventManager:AddListener(EventConst.FACTION_OPENED,Delegate.GetOrCreate(self,self.OnFactionOpen))
    g_Game.EventManager:AddListener(EventConst.ON_UNLOCK_CITY_FOG,Delegate.GetOrCreate(self,self.OnUnlockCityFog))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_EXPLORER_RESPONSE_TO_NPC_CLICK,Delegate.GetOrCreate(self,self.OnNpcClick))
    g_Game.EventManager:AddListener(EventConst.ON_UNLOCK_WORLD_FOG,Delegate.GetOrCreate(self,self.OnUnlockWorldFog))
    g_Game.EventManager:AddListener(EventConst.ON_QUEST_FINISH,Delegate.GetOrCreate(self,self.OnQuestFinish))
    g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_STOP,Delegate.GetOrCreate(self,self.OnStoryTimelineStop))
    g_Game.EventManager:AddListener(EventConst.SE_EXIT,Delegate.GetOrCreate(self,self.OnSeExit))
    g_Game.EventManager:AddListener(EventConst.ON_SLG_MONSTER_DEAD,Delegate.GetOrCreate(self,self.OnSlgMonsterDead))
    g_Game.EventManager:AddListener(EventConst.RADAR_TASK_CLAIM_REWARD,Delegate.GetOrCreate(self,self.OnRadarReward))

    g_Game.EventManager:AddListener(EventConst.MAP_CLICK_ICON,Delegate.GetOrCreate(self,self.OnSelectIcon))
    g_Game.EventManager:AddListener(EventConst.MAP_CLICK_ICON_HIGH,Delegate.GetOrCreate(self,self.OnSelectIconHigh))

    g_Game.EventManager:AddListener(EventConst.MAP_CLICK_MONSTER,Delegate.GetOrCreate(self,self.OnSelectMonster))
    g_Game.EventManager:AddListener(EventConst.MAP_SELECT_BUILDING,Delegate.GetOrCreate(self,self.OnSelectBuilding))
    g_Game.EventManager:AddListener(EventConst.MAP_CLICK_PET,Delegate.GetOrCreate(self,self.OnSelectPet))
    g_Game.EventManager:AddListener(EventConst.MAP_CLICK_WORLD_EVENT,Delegate.GetOrCreate(self,self.OnSelectWorldEvent))
    g_Game.EventManager:AddListener(EventConst.MAP_CLICK_REWARD_INTERACTOR,Delegate.GetOrCreate(self,self.OnSelectRewardInteractor))
    g_Game.EventManager:AddListener(EventConst.ENTER_CITY_TRIGGER,Delegate.GetOrCreate(self,self.OnEnterCity))
    g_Game.EventManager:AddListener(EventConst.PET_LEVEL_UP,Delegate.GetOrCreate(self,self.OnPetLevelUp))

    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_UPGRADE_START, Delegate.GetOrCreate(self,self.OnFurnitureUpgradeStart))
    g_Game.EventManager:AddListener(EventConst.ON_UIMEDIATOR_CLOSEED, Delegate.GetOrCreate(self, self.OnUIMediatorClosed))

    g_Game.EventManager:AddListener(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, Delegate.GetOrCreate(self, self.OnAllianceJoinedWithDataReady))
end

function GuideTriggerWatcher:ReleaseWatcher()
    g_Game.EventManager:RemoveListener(EventConst.ON_UIMEDIATOR_OPENED,Delegate.GetOrCreate(self,self.OnUIMediatorOpened))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_LEVEL_UP_FOR_GUIDE, Delegate.GetOrCreate(self, self.OnBuildingFinish))
    g_Game.EventManager:RemoveListener(EventConst.CITY_MAIN_BASE_FURNITURE_LEVEL_UP_FOR_GUIDE, Delegate.GetOrCreate(self, self.OnMainBaseFinish))
    g_Game.ServiceManager:RemoveResponseCallback(CastleAddFurnitureParameter.GetMsgId(),Delegate.GetOrCreate(self,self.OnFurnitureSetup))

    g_Game.EventManager:RemoveListener(EventConst.QUEST_CHAPTER_FINISH,Delegate.GetOrCreate(self,self.OnQuestChapterFinish))
    g_Game.ServiceManager:RemoveResponseCallback(CastleCreepSprayMedicineParameter.GetMsgId(),Delegate.GetOrCreate(self,self.OnCastleCreepSprayMedicine))
    g_Game.ServiceManager:RemoveResponseCallback(CastleCreepSweepByItemParameter.GetMsgId(),Delegate.GetOrCreate(self,self.OnCastleCreepSweep))
    g_Game.ServiceManager:RemoveResponseCallback(CastleGetProcessOutputParameter.GetMsgId(),Delegate.GetOrCreate(self,self.OnCollectExit))
    g_Game.EventManager:RemoveListener(EventConst.FACTION_OPENED,Delegate.GetOrCreate(self,self.OnFactionOpen))
    g_Game.EventManager:RemoveListener(EventConst.ON_UNLOCK_CITY_FOG,Delegate.GetOrCreate(self,self.OnUnlockCityFog))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_EXPLORER_RESPONSE_TO_NPC_CLICK,Delegate.GetOrCreate(self,self.OnNpcClick))
    g_Game.EventManager:RemoveListener(EventConst.ON_UNLOCK_WORLD_FOG,Delegate.GetOrCreate(self,self.OnUnlockWorldFog))
    g_Game.EventManager:RemoveListener(EventConst.ON_QUEST_FINISH,Delegate.GetOrCreate(self,self.OnQuestFinish))
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_STOP,Delegate.GetOrCreate(self,self.OnStoryTimelineStop))
    g_Game.EventManager:RemoveListener(EventConst.SE_EXIT,Delegate.GetOrCreate(self,self.OnSeExit))
    g_Game.EventManager:RemoveListener(EventConst.ON_SLG_MONSTER_DEAD,Delegate.GetOrCreate(self,self.OnSlgMonsterDead))
    g_Game.EventManager:RemoveListener(EventConst.RADAR_TASK_CLAIM_REWARD,Delegate.GetOrCreate(self,self.OnRadarReward))

    g_Game.EventManager:RemoveListener(EventConst.MAP_CLICK_ICON,Delegate.GetOrCreate(self,self.OnSelectIcon))
    g_Game.EventManager:RemoveListener(EventConst.MAP_CLICK_ICON_HIGH,Delegate.GetOrCreate(self,self.OnSelectIconHigh))

    g_Game.EventManager:RemoveListener(EventConst.MAP_CLICK_MONSTER,Delegate.GetOrCreate(self,self.OnSelectMonster))
    g_Game.EventManager:RemoveListener(EventConst.MAP_SELECT_BUILDING,Delegate.GetOrCreate(self,self.OnSelectBuilding))
    g_Game.EventManager:RemoveListener(EventConst.MAP_CLICK_PET,Delegate.GetOrCreate(self,self.OnSelectPet))
    g_Game.EventManager:RemoveListener(EventConst.MAP_CLICK_WORLD_EVENT,Delegate.GetOrCreate(self,self.OnSelectWorldEvent))
    g_Game.EventManager:RemoveListener(EventConst.MAP_CLICK_REWARD_INTERACTOR,Delegate.GetOrCreate(self,self.OnSelectRewardInteractor))
    g_Game.EventManager:RemoveListener(EventConst.ENTER_CITY_TRIGGER,Delegate.GetOrCreate(self,self.OnEnterCity))
    g_Game.EventManager:RemoveListener(EventConst.PET_LEVEL_UP,Delegate.GetOrCreate(self,self.OnPetLevelUp))

    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_UPGRADE_START, Delegate.GetOrCreate(self,self.OnFurnitureUpgradeStart))
    g_Game.EventManager:RemoveListener(EventConst.ON_UIMEDIATOR_CLOSEED, Delegate.GetOrCreate(self, self.OnUIMediatorClosed))

    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, Delegate.GetOrCreate(self, self.OnAllianceJoinedWithDataReady))
end

function GuideTriggerWatcher:OnUIMediatorOpened(uiName)
    if uiName == UIMediatorNames.UIHeroMainUIMediator then   --打开英雄界面
        g_Logger.LogChannel('GuideModule', "UIHeroMainUIMediator TriggerGuide")
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.OpenUIHeroMainMediator)
    elseif uiName == UIMediatorNames.UIPetMediator then   --打开宠物界面
        g_Logger.LogChannel('GuideModule', "UIPetMediator TriggerGuide")

    elseif uiName == UIMediatorNames.RadarMediator then   --打开雷达界面
        local scene = g_Game.SceneManager.current
        if scene:IsInCity() then --城内开雷达
            g_Logger.LogChannel('GuideModule', "RadarMediator InCity TriggerGuide")
            ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.OpenRadar)
        else --城外开雷达
            g_Logger.LogChannel('GuideModule', "RadarMediator OutCity TriggerGuide")
            ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.OpenRadar)
        end
    elseif uiName == UIMediatorNames.StoryPopupTradeMediator then   --打开NPC服务界面
        g_Logger.LogChannel('GuideModule', "StoryPopupTradeMediator TriggerGuide")

    elseif uiName == UIMediatorNames.UIShopMeidator then   --打开商店界面
        g_Logger.LogChannel('GuideModule', "UIShopMeidator TriggerGuide")

    elseif uiName == UIMediatorNames.AllianceMainMediator then   --打开联盟界面
        g_Logger.LogChannel('GuideModule', "AllianceMainMediator TriggerGuide")

    elseif uiName == UIMediatorNames.UIScienceMediator then   --打开科研界面
        g_Logger.LogChannel('GuideModule', "UIScienceMediator TriggerGuide")

    elseif uiName == UIMediatorNames.CityConstructionModeUIMediator then   --打开建造界面
        g_Logger.LogChannel('GuideModule', "CityConstructionModeUIMediator TriggerGuide")

    elseif uiName == UIMediatorNames.QuestUIMediator then   --打开任务界面
        g_Logger.LogChannel('GuideModule', "QuestUIMediator TriggerGuide")

    elseif uiName == UIMediatorNames.UIChatMediator then   --打开聊天界面
        g_Logger.LogChannel('GuideModule', "UIChatMediator TriggerGuide")

    elseif uiName == UIMediatorNames.BagMediator then   --打开背包界面
        g_Logger.LogChannel('GuideModule', "BagMediator TriggerGuide")

    elseif uiName == UIMediatorNames.HeroCardMediator then   --打开抽卡界面
        g_Logger.LogChannel('GuideModule', "HeroCardMediator TriggerGuide")

    elseif uiName == UIMediatorNames.CityFurnitureConstructionProcessUIMediator then   --打开家具生产界面
        g_Logger.LogChannel('GuideModule', "CityFurnitureConstructionProcessUIMediator TriggerGuide")

    elseif uiName == UIMediatorNames.HeroEquipForgeRoomUIMediator then   --打开装备生产界面
        g_Logger.LogChannel('GuideModule', "HeroEquipForgeRoomUIMediator TriggerGuide")
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.OpenUIHeroEquipForgeRoomUIMediator)
    end
end

function GuideTriggerWatcher:OnUIMediatorClosed(uiName)
    if uiName == UIMediatorNames.SEExploreSettlementMediator then
        g_Logger.LogChannel('GuideModule', "OnCityExploreZoneRecoveryAnimEnd TriggerGuide")
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.OnCityExploreZoneRecoveryAnimEnd)
    end
end

function GuideTriggerWatcher:OnEnterCity()
    g_Logger.LogChannel('GuideModule', "OnEnterCity TriggerGuide")
    ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.EnterCity)
end

function GuideTriggerWatcher:OnBuildingFinish()
    g_Logger.LogChannel('GuideModule', "OnBuildingFinish TriggerGuide")
    ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.BuildingFinish)
end

function GuideTriggerWatcher:OnMainBaseFinish()
    g_Logger.LogChannel('GuideModule', "OnMainBaseFinish TriggerGuide")
    ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.MainbaseFinish)
end

function GuideTriggerWatcher:OnFurnitureSetup()
    g_Logger.LogChannel('GuideModule', "OnFurnitureSetup TriggerGuide")
    ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.SetupFurniture)
end

function GuideTriggerWatcher:OnQuestChapterFinish()
    g_Logger.LogChannel('GuideModule', "OnQuestChapterFinish TriggerGuide")
    ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.ChapterQuestFinish)
end

function GuideTriggerWatcher:OnQuestFinish()
    g_Logger.LogChannel('GuideModule', "OnQuestFinish TriggerGuide")

end

function GuideTriggerWatcher:OnCollectExit()
    g_Logger.LogChannel('GuideModule', "OnCollectExit TriggerGuide")
    ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.CollectExit)
end

function GuideTriggerWatcher:OnFactionOpen()
    g_Logger.LogChannel('GuideModule', "OnFactionOpen TriggerGuide")
    ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.FactionOpen)
end

function GuideTriggerWatcher:OnUnlockCityFog()
    g_Logger.LogChannel('GuideModule', "OnUnlockCityFog TriggerGuide")
    ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.UnlockFog)
end

function GuideTriggerWatcher:OnUnlockWorldFog()
    g_Logger.LogChannel('GuideModule', "OnUnlockWorldFog TriggerGuide")

end

function GuideTriggerWatcher:OnNpcClick()
    g_Logger.LogChannel('GuideModule', "OnNpcClick TriggerGuide")
    ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.NpcClick)
end

function GuideTriggerWatcher:OnCastleCreepSprayMedicine(isSuccess,data,respon)
    g_Logger.LogChannel('GuideModule', "OnCastleCreepSprayMedicine TriggerGuide")
    if isSuccess then
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.AfterCreepSprayMedicine)
    end
end

function GuideTriggerWatcher:OnCastleCreepSweep(isSuccess,data,respon)
    g_Logger.LogChannel('GuideModule', "OnCastleCreepSweep TriggerGuide")
    if isSuccess then
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.AfterCreepSweep)
    end
end

function GuideTriggerWatcher:OnStoryTimelineStop()
    g_Logger.LogChannel('GuideModule', "OnStoryTimelineStop TriggerGuide")

end

function GuideTriggerWatcher:OnSeExit()
    g_Logger.LogChannel('GuideModule', "OnSeExit TriggerGuide")

end

function GuideTriggerWatcher:OnSlgMonsterDead(mobId)
    g_Logger.LogChannel('GuideModule', "OnSlgMonsterDead TriggerGuide")
    if mobId == 334 then
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.SlgMonsterDead)
    end
end

function GuideTriggerWatcher:OnRadarReward()
    g_Logger.LogChannel('GuideModule', "OnRadarReward TriggerGuide")
    ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.RadarReward)
end

---@param ctrl TroopCtrl
function GuideTriggerWatcher:OnSelectMonster(ctrl)
    if ctrl and ctrl._data and ctrl._data.MobInfo and ctrl._data.MobInfo.BehemothCageId and ctrl._data.MobInfo.BehemothCageId ~= 0 then
        local cageEntity = g_Game.DatabaseManager:GetEntity(ctrl._data.MobInfo.BehemothCageId, DBEntityType.BehemothCage)
        if cageEntity then
            self:OnSelectBuilding(cageEntity)
            return
        end
    end
end

function GuideTriggerWatcher:OnSelectBuilding(entity)
    if not entity then
        return
    end
    if entity.TypeHash == DBEntityType.ResourceField then
        g_Logger.LogChannel('GuideModule', "ResourceField TriggerGuide")
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.SelectResource)
    elseif entity.TypeHash == DBEntityType.SeInteractor then
        g_Logger.LogChannel('GuideModule', "SeInteractor TriggerGuide")
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.SelectSE)
    elseif entity.TypeHash == DBEntityType.Village then
        g_Logger.LogChannel('GuideModule', "Village TriggerGuide")
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.SelectStronghold)
    elseif entity.TypeHash == DBEntityType.BehemothCage then
        g_Logger.LogChannel('GuideModule', "BehemothCage TriggerGuide")
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.SelectBehemothCage)
    end
end

function GuideTriggerWatcher:OnSelectPet()
    g_Logger.LogChannel('GuideModule', "OnSelectPet TriggerGuide")
    ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.SelectPet)
end

function GuideTriggerWatcher:OnSelectWorldEvent()
    g_Logger.LogChannel('GuideModule', "OnSelectWorldEvent TriggerGuide")
    ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.SelectEvent)
end

function GuideTriggerWatcher:OnSelectRewardInteractor()
    -- g_Logger.LogChannel('GuideModule', "OnSelectRewardInteractor TriggerGuide")
    -- ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.SelectRewardBox)
end

function GuideTriggerWatcher:OnPetLevelUp()
    g_Logger.LogChannel('GuideModule', "OnPetLevelUp TriggerGuide")
    ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.PetLevelUp)
end

function GuideTriggerWatcher:OnFurnitureUpgradeStart(city, v)
    ---@type CityFurniture
    local furniture = city.furnitureManager:GetFurnitureById(v.furnitureId)
    if furniture.furType == ConfigRefer.CityConfig:MainFurnitureType() then
        g_Logger.LogChannel('GuideModule', "OnFurnitureUpgradeStart TriggerGuide")
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.MainFurnitureUpgradeStart)
    elseif furniture.furType == ConfigRefer.CityConfig:CityWallFurnitureType() then
        g_Logger.LogChannel('GuideModule', "OnFurnitureUpgradeStart TriggerGuide")
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.CityWallUpgradeStart)
    elseif furniture.furType == ConfigRefer.CityConfig:TrainingDummyFurniture() then
        g_Logger.LogChannel('GuideModule', "OnFurnitureUpgradeStart TriggerGuide")
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.TurtleUpgradeStart)
    elseif furniture.furType == ConfigRefer.CityConfig:HotSpringFurniture() then
        g_Logger.LogChannel('GuideModule', "OnFurnitureUpgradeStart TriggerGuide")
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.HotSpringUpgradeStart)
    end
end

function GuideTriggerWatcher:OnAllianceJoinedWithDataReady()
    g_Logger.LogChannel('GuideModule', "OnAllianceJoinedWithDataReady TriggerGuide")
    if ModuleRefer.ClientDataModule:GetData(ClientDataKeys.GameData.JoinAllianceGuide) then
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.JoinAlliance)
    else
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.FirstTimeJoinAlliance)
        ModuleRefer.ClientDataModule:SetData(ClientDataKeys.GameData.JoinAllianceGuide, 1)
    end
end

return GuideTriggerWatcher