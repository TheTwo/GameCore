local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local KingdomMapUtils = require('KingdomMapUtils')
local EventConst = require('EventConst')
local ArtResourceUtils = require('ArtResourceUtils')
local KingdomInteractionDefine = require("KingdomInteractionDefine")
---@class PvETileAssetRadarTaskBubbleBehavior
local PvETileAssetRadarTaskBubbleBehavior = class("PvETileAssetRadarTaskBubbleBehavior")

local QUALITY_COLOR = {
   "sp_radar_img_light_01",
   "sp_radar_img_light_02",
   "sp_radar_img_light_03",
   "sp_radar_img_light_04",
}

function PvETileAssetRadarTaskBubbleBehavior:Awake()

end

function PvETileAssetRadarTaskBubbleBehavior:OnEnable()
    if self.facingCamera then
        self.facingCamera.FacingCamera = KingdomMapUtils.GetBasicCamera().mainCamera
    end
    local kingdomInteraction = ModuleRefer.KingdomInteractionModule
    if kingdomInteraction then
        kingdomInteraction:AddOnClick(Delegate.GetOrCreate(self,self.DoOnClick), KingdomInteractionDefine.InteractionPriority.RadarBubble)
    end
end

function PvETileAssetRadarTaskBubbleBehavior:OnDisable()
    local kingdomInteraction = ModuleRefer.KingdomInteractionModule
    if kingdomInteraction then
        kingdomInteraction:RemoveOnClick(Delegate.GetOrCreate(self,self.DoOnClick))
    end
    self.isSelected = false
end

function PvETileAssetRadarTaskBubbleBehavior:InitEvent(bubbleType, customData, iconName)
    self.bubbleType = bubbleType
    self.customData = customData
    self.iconName = iconName
    self.entityID = customData.EntityId
    self.isSelected = false
    self:InitRadarTaskBubble(self.customData)
end

function PvETileAssetRadarTaskBubbleBehavior:InitRadarTaskBubble(customData)
    self.quality = customData.Quality
    -- self.bgIcon.color = QUALITY_COLOR[self.quality + 1]
    g_Game.SpriteManager:LoadSprite(QUALITY_COLOR[self.quality + 1], self.bgIcon)
    self.remainTime = customData.VanishTime.timeSeconds
    if self.customData.State == wds.RadarTaskState.RadarTaskState_CanReceiveReward then
        self.goRedDot:SetActive(true)
    end
    if self:CheckIsMovingToRadarTask() then
        self:GoingToRadarTaskTarget()
    end
end

function PvETileAssetRadarTaskBubbleBehavior:OnSelected(isSelected)
    self.goFrameNormal:SetActive(not isSelected)
    self.goFrameSelect:SetActive(isSelected)
end

function PvETileAssetRadarTaskBubbleBehavior:OnClaimReward()    
    self.goRedDot:SetActive(false)
end

function PvETileAssetRadarTaskBubbleBehavior:OnRadarTaskStateChanged(isGoing)
   if isGoing then
        self:GoingToRadarTaskTarget()
   else
        self:NoneRadarTaskTarget()
   end
end

function PvETileAssetRadarTaskBubbleBehavior:OnRadarTaskClicked(entityID)
   if entityID ~= self.entityID then
        self.isSelected = false
        self:OnSelected(self.isSelected)
   end
end

function PvETileAssetRadarTaskBubbleBehavior:GoingToRadarTaskTarget()
    self.bgIcon.color.a = 0.3
    self.iconStatus.color.a = 0.3
end

function PvETileAssetRadarTaskBubbleBehavior:NoneRadarTaskTarget()
    self.bgIcon.color.a = 1
    self.iconStatus.color.a = 1
end

function PvETileAssetRadarTaskBubbleBehavior:CheckIsMovingToRadarTask()
    local troops = ModuleRefer.SlgModule:GetMyTroops() or {}
    for i, troop in ipairs(troops) do
        if troop.entityData and troop.entityData.MovePathInfo then
            local entityID = troop.entityData.MovePathInfo.TargetUID
            if self.customData and entityID == self.customData.EntityId then
                 return true
            end
        end
    end
    return false
end

function PvETileAssetRadarTaskBubbleBehavior:DoOnClick(trans)
    if trans and #trans > 0 then
        for _, t in ipairs(trans) do
            if t == self.colliderTrans then
                if self.bubbleType == wrpc.RadarEntityType.RadarEntityType_RadarTask then

                    self.isSelected = true
                    self:OnSelected(self.isSelected)

                    ---@type RadarObjectDetailParam                
                    local param = {ID = self.customData.ID, eneityId = self.customData.EntityId, radarTaskID = self.customData.RadarTaskId, taskState = self.customData.State, quality = self.customData.Quality,
                     vanishTime = self.customData.VanishTime, worldPos = self.customData.Pos}
                end
            end
        end
    end
end



return PvETileAssetRadarTaskBubbleBehavior