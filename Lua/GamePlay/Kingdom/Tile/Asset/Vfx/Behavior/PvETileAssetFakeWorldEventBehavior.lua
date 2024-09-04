local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local Utils = require("Utils")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local UIHelper = require('UIHelper')
local KingdomTouchInfoCompHelper = require('KingdomTouchInfoCompHelper')
local KingdomMapUtils = require("KingdomMapUtils")
local TouchMenuHelper = require('TouchMenuHelper')
local TouchMenuMainBtnDatum = require('TouchMenuMainBtnDatum')
local I18N = require('I18N')
local GotoUtils = require('GotoUtils')
local EventConst = require('EventConst')
local KingdomInteractionDefine = require("KingdomInteractionDefine")
local DBEntityType = require('DBEntityType')
local AddExpedition2RadarParameter = require("AddExpedition2RadarParameter")
local ProgressType = require('ProgressType')

---@class PvETileAssetFakeWorldEventBehavior
local PvETileAssetFakeWorldEventBehavior = class("PvETileAssetFakeWorldEventBehavior")

local QUALITY_COLOR = {
    "sp_world_base_1",
    "sp_world_base_2",
    "sp_world_base_3",
    "sp_world_base_4",
}

function PvETileAssetFakeWorldEventBehavior:Awake()
    self.lvText.text = 1
    self.progressImage.fillAmount = 1
    local quality = 0
    if quality and quality >= 0 then
        g_Game.SpriteManager:LoadSprite(QUALITY_COLOR[quality + 1], self.bgIcon)
    end
end

function PvETileAssetFakeWorldEventBehavior:OnEnable()
    if self.facingCamera then
        self.facingCamera.FacingCamera = KingdomMapUtils.GetBasicCamera().mainCamera
    end
    local kingdomInteraction = ModuleRefer.KingdomInteractionModule
    if kingdomInteraction then
        kingdomInteraction:AddOnClick(Delegate.GetOrCreate(self,self.DoOnClick), KingdomInteractionDefine.InteractionPriority.WorldEvent)
    end
end

function PvETileAssetFakeWorldEventBehavior:OnDisable()
    self.isSelected = false
    local kingdomInteraction = ModuleRefer.KingdomInteractionModule
    if kingdomInteraction then
        kingdomInteraction:RemoveOnClick(Delegate.GetOrCreate(self,self.DoOnClick))
    end
end

function PvETileAssetFakeWorldEventBehavior:DoOnClick(trans)
    if trans and #trans > 0 then
        for _, t in ipairs(trans) do
            if t == self.colliderTrans then

                self.isSelected = true
                self:OnSelected(self.isSelected)
                ---@type RadarObjectDetailParam                
                local param = {expeditionInfo = self.expeditionInfo}
            end
        end
    end
end

function PvETileAssetFakeWorldEventBehavior:InitEvent(expeditionInfo)
    local entity = g_Game.DatabaseManager:GetEntity(expeditionInfo.ID, DBEntityType.Expedition)
    if not entity then
        self:GetAsset().transform.gameObject:SetActive(false)
        return
    end
    self:InitEventByEntity(entity)
end

function PvETileAssetFakeWorldEventBehavior:InitEventByEntity(entity)
    self.expeditionInfo = entity.ExpeditionInfo
    self.progress = self.expeditionInfo.PersonalProgress[ModuleRefer.PlayerModule:GetPlayer().ID] or 0
    self.isSelected = false
    self:OnSelected(self.isSelected)
    self.goLv:SetActive(false)
    self:RefreshExpeditionInfo(entity.ID)
end

---@param expeditionInfo wrpc.RadarScanResultExpedition
function PvETileAssetFakeWorldEventBehavior:InitEventSkipEntity(expeditionInfo)
    self.expeditionInfo = expeditionInfo
    self.progress = self.expeditionInfo.PersonalProgress
    self.isSelected = false
    self:OnSelected(self.isSelected)
    self.goLv:SetActive(false)
    self:RefreshExpeditionInfo()
end

function PvETileAssetFakeWorldEventBehavior:OnSelected(isSelected)
    self.goSelected:SetActive(isSelected)
end

function PvETileAssetFakeWorldEventBehavior:OnRadarTaskClicked(entityID)
    if entityID ~= self.entityId then
         self.isSelected = false
         self:OnSelected(self.isSelected)
    end
 end

function PvETileAssetFakeWorldEventBehavior:RefreshExpeditionInfo(entityID)
    self.quality = self.expeditionInfo.Quality
    self.entityId = self.expeditionInfo.EntityID
    self.eventId = self.expeditionInfo.CfgId
    local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(self.eventId)
    if self.progress and self.progress > 0 then
        self.goLv:SetActive(true)
        self.level = eventCfg:Level()
        self.lvText.text = self.level        
        self.progressImage.fillAmount = math.clamp(self.progress / eventCfg:MaxProgress(), 0, 1)
        self.progressText.text = math.floor(self.progress / eventCfg:MaxProgress() ) * 100 .."%"
    end

    if  eventCfg:ProgressType() == ProgressType.Whole then
        self.groupIcon:SetActive(true)
    end

    if self.quality and self.quality >= 0 then
        g_Game.SpriteManager:LoadSprite(QUALITY_COLOR[self.quality + 1], self.bgIcon)
    else
        local parameter = AddExpedition2RadarParameter.new()
        parameter.args.ExpeditionInstanceId = self.eventId
        parameter.args.ExpeditionEntityId = self.entityId
        parameter:Send()
    end
end

function PvETileAssetFakeWorldEventBehavior:ChangeRangeQuality()
    local radarInfo = ModuleRefer.RadarModule:GetRadarInfo()
    self.quality = (radarInfo.ExpeditionQuality[self.entityId] or {}).QualityType or 0
    if self.quality and self.quality >= 0 then
        g_Game.SpriteManager:LoadSprite(QUALITY_COLOR[self.quality + 1], self.bgIcon)
    end
end

return PvETileAssetFakeWorldEventBehavior