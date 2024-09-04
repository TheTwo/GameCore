local SlgUtils = require('SlgUtils')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local DBEntityType = require('DBEntityType')
local ArtResourceUtils = require('ArtResourceUtils')
local ArtResourceUIConsts = require('ArtResourceUIConsts')
local HeroUIUtilities = require('HeroUIUtilities')
local ManualResourceConst = require('ManualResourceConst')
local KingdomConstant = require('KingdomConstant')
local PoolUsage = require("PoolUsage")
local Utils = require("Utils")
local MapEntityConstructingProgress = require("MapEntityConstructingProgress")
local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")
local PooledGameObjectHandle = CS.DragonReborn.AssetTool.PooledGameObjectHandle
local Vector3 = CS.UnityEngine.Vector3
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local MonsterClassType = require('MonsterClassType')
local TimerUtility = require("TimerUtility")
local MapHUDFadeDefine = require("MapHUDFadeDefine")
local ObjectType = require("ObjectType")
local AdornmentQuality = require("AdornmentQuality")
local I18N = require("I18N")
local MailUtils = require("MailUtils")

-- local EventConst = require('EventConst')
---@class TroopHUD
---@field facingCamera CS.U2DFacingCameraECS
---@field hudAnimTrigger CS.FpAnimation.FpAnimationCommonTrigger
---simple info
---@field simpleInfoRoot CS.UnityEngine.GameObject
---@field iconGo CS.UnityEngine.GameObject
---@field iconBaseImg CS.U2DSpriteMesh
---@field iconImg CS.U2DSpriteMesh
---@field monsterIconImg CS.U2DSpriteMesh
---@field nameTxt CS.U2DTextMesh
---@field hpGo CS.UnityEngine.GameObject
---@field hpValueRect CS.UnityEngine.RectTransform
---@field hpValueMiddleImg CS.U2DSpriteMesh
---@field hpValueImg CS.U2DSpriteMesh
---@field hpNormalColor CS.UnityEngine.Color
---@field hpDeadlyColor CS.UnityEngine.Color
---@field healAnimDelay CS.System.Single
---@field healAnimDuration CS.System.Single
---@field healAnimColor CS.UnityEngine.Color
---@field hurtAnimDelay CS.System.Single
---@field hurtAnimDuration CS.System.Single
---@field hurtAnimColor CS.UnityEngine.Color
---@field seriousAnimDelay CS.System.Single
---@field seriousAnimDuration CS.System.Single
---@field seriousAnimColor CS.UnityEngine.Color
---@field hpValueText CS.U2DTextMesh
-----@field mpGo CS.UnityEngine.GameObject
-----@field maxMpAmount CS.System.Single
-----@field minMpAmount CS.System.Single
-----@field mpValueImg CS.U2DSpriteMesh
---@field troopStateBack CS.U2DSpriteMesh
---@field troopStateImg CS.U2DSpriteMesh
---@field troopEscrowImg CS.U2DSpriteMesh
---@field troopKindBaseGo CS.UnityEngine.GameObject
---@field troopKindImg CS.U2DSpriteMesh
---@field ctrl TroopCtrl
---@field constructingHandle CS.DragonReborn.AssetTool.PooledGameObjectHandle
---@field constructing MapEntityConstructingProgress
---@field burstGo CS.UnityEngine.GameObject
---@field burstTimer CS.U2DSpriteMesh
---detail info
---@field detailInfoRoot CS.UnityEngine.GameObject
---bottom info
---@field facingCamera_bottom CS.U2DFacingCameraECS
---@field materialSetter CS.Lod.U2DWidgetMaterialSetter
---@field timer Timer
---@field lvGo_bottom   CS.UnityEngine.GameObject
---@field lvTxt_bottom  CS.U2DTextMesh
---@field lvBack_bottom CS.U2DSpriteMesh
---@field monsterIcon CS.U2DSpriteMesh
---@field monsterIconGo_bottom CS.UnityEngine.GameObject
---@field monsterIconSetter CS.Lod.U2DWidgetMaterialSetter
---@field lvIconSetter CS.Lod.U2DWidgetMaterialSetter
---@field iconTrigger MapUITrigger
---@field monsterTrigger MapUITrigger
---@field eventMark CS.UnityEngine.Transform
---@field titleGo CS.UnityEngine.GameObject
---@field textTitle CS.UU2DTextMesh
---@field imgTitle CS.U2DSpriteMesh
---@field eventIcon CS.U2DSpriteMesh
---@field provider TroopHUDAbstractProvider
---@field hammer CS.UnityEngine.GameObject

local TroopHUD = class('TroopHUD')

TroopHUD.State = {
    Hide = 0,
    Normal = 1,
    InBattle = 2,
    Select = 3,
    MulitSelect = 4,
    BigMap = 5,    
}

function TroopHUD:Awake()
    self.simpleInfoRoot:SetVisible(true)
    self.detailInfoRoot:SetVisible(false)
    self.iconGo:SetVisible(false)
    self.nameTxt:SetVisible(false)
    self.hpGo:SetVisible(false)
    -- self.mpGo:SetVisible(false)
    self.burstGo:SetActive(false)
    self.titleGo:SetVisible(false)
    self.module = ModuleRefer.SlgModule
    self.state = TroopHUD.State.Hide
    self.hpAnimType = 0
    self.isOverMax = false
    ---@type CS.UnityEngine.Transform
    self.trans = self.behaviour.transform
    self.heroHeight = 0
    self.iconTrigger = self.iconGo:GetLuaBehaviour("MapUITrigger").Instance
    self.monsterTrigger = self.monsterIconGo_bottom:GetLuaBehaviour("MapUITrigger").Instance
    self.eventMark = self.facingCamera_bottom.transform:Find("p_event_mark")
    self.provider = nil
end


function TroopHUD:OnEnable()
    local scene = require('KingdomMapUtils').GetKingdomScene()   
    self.lastStateIcon = nil
    self.lastEscrowIcon = false
    self.iconCache = {}
    self.isShowing = true
    self.isInGve = scene:GetName() == require('SlgScene').Name
    self:Hide()
    -- self.updater = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self,self.HUDUpdate),0.1,-1,false)
    -- g_Game:AddFrameTicker(Delegate.GetOrCreate(self,self.HUDUpdate))
    self.monsterIconSetter = self.monsterIconGo_bottom:GetComponent(typeof(CS.Lod.U2DWidgetMaterialSetter))
    self.lvIconSetter = self.lvGo_bottom:GetComponent(typeof(CS.Lod.U2DWidgetMaterialSetter))
    self.radarTaskIconSetter = self.radarTaskBase:GetComponent(typeof(CS.Lod.U2DWidgetMaterialSetter))
    self.iconTrigger:SetEnable(true)
    self.trigger.Instance:SetEnable(true)
    self.monsterTrigger:SetEnable(false)
    self.iconTrigger:SetTrigger(Delegate.GetOrCreate(self,self.OnIconClicked))
    self.monsterTrigger:SetTrigger(Delegate.GetOrCreate(self,self.OnIconClicked))
    self.eventMarkSetter = self.eventMark:GetComponent(typeof(CS.Lod.U2DWidgetMaterialSetter))
    self.trigger.Instance:SetTrigger(Delegate.GetOrCreate(self, self.OnClickRadarTaskBtn))
    self.radarTaskGo:SetVisible(false)
    self.troopEscrowImg:SetVisible(false)
    if not self.showEventMark then
        self.facingCamera_bottom.gameObject:SetVisible(false)
    end
    self.hpValueText.gameObject:SetActive(false)
    self.vaild = true   
    self.hpWidth = nil
end

function TroopHUD:OnIconClicked()
    if not self.ctrl then
        return
    end
    ModuleRefer.SlgModule:SelectAndOpenTroopMenu(self.ctrl)
end


function TroopHUD:OnDisable()
    self:Hide()
    self.lastStateIcon = nil
    self.isShowing = false
    self.hideAll = false        
    self.heroHeight = 0
    self.radarTaskGo:SetVisible(false)
    self.vaild = false
    self.showEventMark = false
    self.hpWidth = nil
    self.IsRadarTaskEntity = false
    self.isOverMax = false
end

function TroopHUD:Release()
    self:Hide()
    if self.radarBubbleCreateHandle then
        ModuleRefer.RadarModule:GetCreateHelper():Delete(self.radarBubbleCreateHandle)
        self.radarBubbleCreateHandle = nil
        self.bubblePosTrans = nil
    end
end

---@param ctrl TroopCtrl
function TroopHUD:FeedData(ctrl)
    if not ctrl then
        self:Hide()
        return
    end
    self.ctrl = ctrl
    self.iconImgSpLoaded = false
    
    local troopType = self.ctrl.troopType
    -- SlgUtils.TroopType = {
    --     Invalid = 0,
    --     MySelf = 1,
    --     Friend = 2,
    --     Other = 3,
    --     Monster = 4,
    --     Enemy = 5,
    --     Boss = 6,
    --     Behemoth = 7,
    -- }
    local typeHash = self.ctrl._data.TypeHash
    if typeHash == DBEntityType.MobileFortress then
        self.provider = require('TroopHUDProviderMobileFortress').new(self)
    elseif troopType == SlgUtils.TroopType.Monster or typeHash == DBEntityType.SlgPuppet then
        self.provider = require('TroopHUDProviderMonster').new(self)
    elseif troopType == SlgUtils.TroopType.MySelf then
        self.provider = require('TroopHUDProviderMySelf').new(self)
    elseif troopType == SlgUtils.TroopType.Friend then        
        self.provider = require('TroopHUDProviderFriend').new(self)                
    elseif troopType == SlgUtils.TroopType.Enemy then
        self.provider = require('TroopHUDProviderEnemy').new(self)
    elseif troopType == SlgUtils.TroopType.Boss then
        self.provider = require('TroopHUDProviderBoss').new(self)
    elseif troopType == SlgUtils.TroopType.Behemoth then
        self.provider = require('TroopHUDProviderBehemoth').new(self)
    end

    if self.provider then
        self.provider:Init()
    end    
    self:SetupWorldEventMark()
    self:SetDirty()    
end

function TroopHUD:GetHeroHeight()
    if not self.ctrl then 
        return
    end
    local ctrl = self.ctrl
    if ctrl._data and ctrl._data.Battle and ctrl._data.Battle.Group and ctrl._data.Battle.Group.Heros:Count() > 0 then
        local heroId = SlgUtils.GetTroopLeadHeroId(ctrl._data.Battle.Group.Heros)
        local heroCfg = (heroId and heroId > 0) and ConfigRefer.Heroes:Find(heroId) or nil
        local heroClientResCfg = heroCfg and ConfigRefer.HeroClientRes:Find( heroCfg:ClientResCfg()) or nil
        local artResCfg = heroClientResCfg and ConfigRefer.ArtResource:Find(heroClientResCfg:SlgModel()) or nil
        if artResCfg then
            self.heroHeight = artResCfg:CapsuleHeight() * artResCfg:ModelScale()
        end   
    end
end

function TroopHUD:SetupDeadWaring()
    if self.ctrl and self.ctrl.deadWaring and self.burstTimer then
        self.showingWarning = true
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self,self.TickBurstTimer))
    else
        self.showingWarning = false
    end
end

function TroopHUD:CheckState()
    if not self.provider or not self.ctrl then
        return TroopHUD.State.Hide
    end

    local troopData = self.ctrl._data
    if not self.ctrl:IsValid() or
        SlgUtils.IsTroopHideOnMap(troopData) or
        not SlgUtils.IsTroopSelectable(troopData) or
        self.ctrl:GetHP() < 1
    then
        return TroopHUD.State.Hide
    end

    local viewer = self.ctrl:GetTroopView()
    if not viewer then
        return TroopHUD.State.Hide
    end
    
    if self.isOverMax then
        if self.ctrl.troopType ~= SlgUtils.TroopType.MySelf or self.hideAll then
            return TroopHUD.State.Hide
        else
            return TroopHUD.State.BigMap
        end
    end

    return self.provider:CheckState()
end



function TroopHUD:SetFacingOffset(headOffset,bottomOffset)
    -- self.facingCamera.transform.localPosition = CS.UnityEngine.Vector3(0,height,0)
    self.facingCamera.facingOffset = headOffset
    self.facingCamera_bottom.facingOffset = bottomOffset
end

function TroopHUD:SetYOffset(headOffset,bottomOffset)
    self.facingCamera.yOffset = headOffset
    self.facingCamera_bottom.yOffset = bottomOffset
end

function TroopHUD:SetDirty(needShake)
    if self.isDirty then
        if needShake and not self.shakeOnLastUpdate then
            self.shakeOnLastUpdate = needShake
        end
        return
    end
    self.isDirty = true
    self.shakeOnLastUpdate = needShake
    self.module.troopManager:AddUpdateTroopHUD(self)
end



function TroopHUD:UpdateTroopInfo()

    self.state = self:CheckState()    
    if not self.provider then
        self:Hide()       
    elseif self.state == TroopHUD.State.Normal then
        self.provider:OnState_Normal()
        self:Show()
    elseif self.state == TroopHUD.State.InBattle then
        self.provider:OnState_Battle()
        self:Show()
    elseif self.state == TroopHUD.State.Select then
        self.provider:OnState_Selected()
        self:Show()
    elseif self.state == TroopHUD.State.MulitSelect then
        self.provider:OnState_MulitSelected()
        self:Show()
    elseif self.state == TroopHUD.State.BigMap then
        self.provider:OnState_BigMap()
        self:Show()
    else
        self:Hide()
    end
  
    if self.provider then
        self.provider:OnLODChanged(self.isOverMax, self.isOverMax)
    end   
end


function TroopHUD:Hide()
    if not self.isShowing then
        return
    end  
    
    self.isShowing = false
    if self.facingCamera then
        self.facingCamera.gameObject:SetVisible(false)
    end
    if self.facingCamera_bottom and not self.showEventMark then
        self.facingCamera_bottom.gameObject:SetVisible(false)
    end
    if self.showingWarning then
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self,self.TickBurstTimer))
        self.showingWarning = false
    end

    if self.bottomLaterActiver then
        self.bottomLaterActiver:Stop()
        self.bottomLaterActiver = nil
    end
    if self.eventMarkLaterActiver then
        self.eventMarkLaterActiver:Stop()
        self.eventMarkLaterActiver = nil
    end
    if self.iconTrigger then
        self.iconTrigger:SetTrigger(nil)
    end
    
    if self.monsterTrigger then
        self.monsterTrigger:SetTrigger(nil)
    end

    if Utils.IsNotNull(self.trigger) then
        self.trigger.Instance:SetTrigger(nil)
    end

    self:HideConstructing()
    self:StopHPAnim()
    self.hpGo:SetVisible(false)
    self.hpValueText:SetVisible(false)          
end

function TroopHUD:Show()
    if self.isShowing then
        return
    end
    local ctrl = self.ctrl
    if not ctrl then
        self:Hide()
        return
    end
    local viewer = ctrl:GetTroopView()
    if not viewer then
        self:Hide()
        return
    end

    if self.facingCamera then
        self.facingCamera.gameObject:SetVisible(true)
    end
    self.isShowing = true    
end

---@param battleRelation boolean
function TroopHUD:SetBattleRelationState(relation)
    if self.battleRelation ~= relation then
        self.battleRelation = relation
        self:SetDirty()
    end
end

function TroopHUD:StopHPAnim()
    if self.hpMidTweener and self.hpMidTweener:IsPlaying() then
        self.hpMidTweener:Kill(false)
    end
    if self.hpTweener and self.hpTweener:IsPlaying() then
        self.hpTweener:Kill(false)
    end
end

function TroopHUD:UpdateHPBar(needShake)
    local hpWidth = 0
    if not self.hpMaxWidth or not self.hpWidth then
        self.hpMaxWidth = self.hpValueRect.sizeDelta.x
    end

    local hp = self.ctrl:GetHP()
    local maxHp = self.ctrl:GetMaxHP()
    local hpPct = math.clamp01(hp / maxHp)
    hpWidth = self.hpMaxWidth * hpPct
    self.hpValueText.text = tostring(hp)

    if not self.hpWidth or math.abs(hpWidth - self.hpWidth) > 0.1 then
        local delta = 0
        if self.hpWidth then
            delta = (hpWidth - self.hpWidth) / self.hpMaxWidth
        end
        self.hpWidth = hpWidth

        if delta > 0.01 then
            self.hpValueMiddleImg.color = self.healAnimColor
            self.hpValueMiddleImg.width = hpWidth
            if self.hpAnimType ~= 1 then
                self:StopHPAnim()
            end
            self.hpAnimType = 1
            if self.hpValueImg then
                self.hpTweener = self.hpValueImg:DOWidth(hpWidth,self.healAnimDuration,self.healAnimDelay,CS.DG.Tweening.Ease.Linear,function()
                    if self then
                        self.hpAnimType = 0
                        if Utils.IsNotNull(self.hpValueImg) then
                            self.hpValueImg.width = self.hpWidth
                        end
                        if Utils.IsNotNull(self.hpValueMiddleImg) then
                            self.hpValueMiddleImg.width = self.hpWidth
                        end
                    end
                end)
            end
        elseif delta > -0.001 then
            self.hpValueMiddleImg.width = hpWidth
            self.hpValueImg.width = hpWidth
        elseif delta > -0.3 then
            self.hpValueImg.width = hpWidth
            self.hpValueMiddleImg.color = self.hurtAnimColor
            if self.hpAnimType >= 2 and self.hpMidTweener and self.hpMidTweener:IsPlaying() then
                self.hpMidTweener:ChangeEndValue(hpWidth)
            else
                self:StopHPAnim()
                self.hpAnimType = 2
                if self.hpValueMiddleImg then
                    self.hpMidTweener = self.hpValueMiddleImg:DOWidth(hpWidth,self.hurtAnimDuration,self.hurtAnimDelay,CS.DG.Tweening.Ease.Linear,function()
                        if self then
                            self.hpAnimType = 0
                            if Utils.IsNotNull(self.hpValueImg) then
                                self.hpValueImg.width = self.hpWidth
                            end
                            if Utils.IsNotNull(self.hpValueMiddleImg) then
                                self.hpValueMiddleImg.width = self.hpWidth
                            end
                        end
                    end)
                end
            end
        else
            self.hpValueImg.width = hpWidth
            self.hpValueMiddleImg.color = self.seriousAnimColor
            if needShake then
                self.hudAnimTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
            end
            if self.hpAnimType < 3 then
                self:StopHPAnim()
                self.hpAnimType = 3
                if self.hpValueMiddleImg then
                    self.hpMidTweener = self.hpValueMiddleImg:DOWidth(hpWidth,self.seriousAnimDuration,self.seriousAnimDelay,CS.DG.Tweening.Ease.InExpo,function()
                        if self then
                            self.hpAnimType = 0
                            if Utils.IsNotNull(self.hpValueImg) then
                                self.hpValueImg.width = self.hpWidth
                            end
                            if Utils.IsNotNull(self.hpValueMiddleImg) then
                                self.hpValueMiddleImg.width = self.hpWidth
                            end
                        end
                    end)
                end
            else
                self.hpMidTweener:ChangeEndValue(hpWidth)
            end
        end

        self.hpValueImg.color = (hpPct > 0.1) and self.hpNormalColor or self.hpDeadlyColor
    end

    -- if not self.mpWidth or math.abs(mpWidth - self.mpWidth) > 0.01 then
    --     self.mpWidth = mpWidth
    --     self.mpValueImg.fillAmount = mpWidth
    -- end
end

function TroopHUD:SyncHPBar()
    if not self.hpMaxWidth or not self.hpWidth then
        self.hpMaxWidth = self.hpValueRect.sizeDelta.x
    end

    local hp = self.ctrl:GetHP()
    local maxHp = self.ctrl:GetMaxHP()
    local hpPct = math.clamp01(hp / maxHp)
    local hpWidth = self.hpMaxWidth * hpPct
    self.hpValueMiddleImg.width = hpWidth
    self.hpValueImg.width = hpWidth
    self.hpWidth = hpWidth
    self.hpValueText.text = tostring(hp)
    self.hpValueImg.color = (hpPct > 0.1) and self.hpNormalColor or self.hpDeadlyColor
end

function TroopHUD:ShouldUpdateTroopStateIcon()
    return self.ctrl.troopType == SlgUtils.TroopType.MySelf
end

function TroopHUD:UpdateTroopStateIcon()
    if not self:ShouldUpdateTroopStateIcon() then
        return
    end

    local troop = self.ctrl:GetData()
    local troopStateIcon,troopStateBack = HeroUIUtilities.TroopStateIcon(troop)
    if self.lastStateIcon ~= troopStateIcon then
        self.lastStateIcon = troopStateIcon
        self.module:LoadTroopStateIconSprite(troopStateIcon,self.troopStateImg)
        self.module:LoadTroopStateIconSprite(troopStateBack,self.troopStateBack)
    end
    
    local ecsrowIcon = SlgUtils.GetEcsrowIcon(troop,nil)
    if ecsrowIcon ~= self.lastEscrowIcon then
        self.lastEscrowIcon = ecsrowIcon
        if string.IsNullOrEmpty(ecsrowIcon) then
            self.troopEscrowImg:SetVisible(false)
        else
            self.troopEscrowImg:SetVisible(true)
            g_Game.SpriteManager:LoadSpriteAsync(ecsrowIcon,self.troopEscrowImg)
        end
    end
end

function TroopHUD:UpdateHammerIcon()
    local troop = self.ctrl._data
    if troop and troop.MapStates.StateWrapper2.StrengthenRebuildOnMap then
        self.hammer:SetActive(true)
    else
        self.hammer:SetActive(false)
    end
end

function TroopHUD:HUDUpdate()
    if not self or not self.isDirty then return end
    self.isDirty = false
    if not self.vaild  or not self.ctrl then return end
    local needShake = self.shakeOnLastUpdate or false
    self.shakeOnLastUpdate = false
    self:UpdateTroopInfo()
    self:UpdateTroopStateIcon()
    self:UpdateHammerIcon()
    if self.provider then
        self.provider:OnUpdate()
    end
    if self.state == TroopHUD.State.InBattle then
        self:UpdateHPBar(needShake)
    elseif self.state == TroopHUD.State.Select then
        self:SyncHPBar()
    end
end

function TroopHUD:TickBurstTimer()
    if self.burstTimer and self.showingWarning and self.ctrl.lifeTime and self.ctrl.spawnTime then
        self.burstTimer.fillAmount =  math.max(0, (g_Game.Time.time - self.ctrl.spawnTime)/ self.ctrl.lifeTime )
    end
end

local one = Vector3.one
local up = Vector3.up

---@param data TroopHUD
---@param go CS.UnityEngine.GameObject
local function LoadCallback(go, data)
    if Utils.IsNotNull(go) then
        go.transform.localPosition = data.ctrl:GetPosition()
        data.constructing = MapEntityConstructingProgress.new()
        data.constructing:Setup(go)
        data.constructing:SetOffset(up * 150)
        data.constructing:SetScale(one)
        data:UpdateConstructing()
    end
end

function TroopHUD:ShowConstructing()
    if self.ctrl.TypeHash ~= DBEntityType.MobileFortress then
        return
    end

    if not self.constructingHandle then
        self.constructingHandle = PooledGameObjectHandle(PoolUsage.Troop)
    end
    self.constructingHandle:Create(ManualResourceConst.ui3d_bubble_progress, KingdomMapUtils.GetMapSystem().Parent, LoadCallback, self)

    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.UpdateConstructing))
end

function TroopHUD:SetWorldTaskBubbleState(visible)
    self.taskBubbleState = visible
end

function TroopHUD:TryShowRadarTaskBubble()
    if not KingdomMapUtils.InMapNormalLod(self.curLod) then
        return
    end
    if self.radarBubbleCreateHandle then
        -- ModuleRefer.RadarModule:GetCreateHelper():Delete(self.radarBubbleCreateHandle)
        -- self.radarBubbleCreateHandle = nil
        -- self.bubblePosTrans = nil
        return
    end
    if ModuleRefer.RadarModule:IsRadarTaskEntity(self.ctrl.ID) then
        self.IsRadarTaskEntity = true
        self:RefreshRadarTaskLodBase()
        self.radarBubbleCreateHandle = ModuleRefer.RadarModule:GetCreateHelper():Create(ManualResourceConst.ui3d_bubble_radar, self.facingCamera.transform.parent, function(bubbleGo)
                bubbleGo.transform.localPosition = CS.UnityEngine.Vector3.zero
                bubbleGo.transform.localScale = CS.UnityEngine.Vector3.one
                self.bubblePosTrans = bubbleGo.transform:Find("p_rotation/p_position")
                self.bubblePosTrans.localPosition = CS.UnityEngine.Vector3.up * (45 + self.heroHeight)
                ---@type PvETileAsseRadarBubbleBehavior
                local radarbubble = bubbleGo:GetLuaBehaviour("PvETileAsseRadarBubbleBehavior").Instance
                radarbubble:InitEvent(nil, {isRadarTaskBubble = true, type = ObjectType.SlgMob, ctrl = self.ctrl.ID, 
                X = self.ctrl._data.MapBasics.Position.X, Y = self.ctrl._data.MapBasics.Position.Y})
                radarbubble.facingCamera.yOffset = 100

                -- radarbubble:SetBubbleFrameCyst(ModuleRefer.RadarModule:GetRadarTaskFrameCyst(self.ctrl.ID))
                local radarTaskId = ModuleRefer.RadarModule:GetRadarTaskId(self.ctrl.ID)
                local configInfo = ConfigRefer.RadarTask:Find(radarTaskId)
                if configInfo then
                    if configInfo:IsSpecial() then
                        radarbubble:SetBubbleBase("sp_city_bubble_base_events")
                    else
                        radarbubble:SetBubbleBase(ModuleRefer.RadarModule:GetRadarTaskBase(self.ctrl.ID))
                    end
                    self.radarIcon = configInfo:RadarTaskIcon()
                    if self.radarIcon =="" then
                        local taskConfig = ConfigRefer.RadarTask:Find(radarTaskId)
                        local itemGroupConfig = ConfigRefer.ItemGroup:Find(taskConfig:QualityExtReward(4))
                        local itemGroup = itemGroupConfig:ItemGroupInfoList(1)
                        self.radarIcon = ConfigRefer.Item:Find(itemGroup:Items()):Icon()
                    end
                else
                    self.radarIcon = "sp_comp_icon_radar_monster"
                    radarbubble:SetBubbleBase(ModuleRefer.RadarModule:GetRadarTaskBase(self.ctrl.ID))
                end

                radarbubble:SetBubbleIcon(self.radarIcon)
                if not string.IsNullOrEmpty(configInfo:RadarTaskRewardIcon()) then
                    radarbubble:SetPetRewardActive(true)
                    radarbubble:SetPetRewardIcon(configInfo:RadarTaskRewardIcon())
                else
                    radarbubble:SetPetRewardActive(false)
                end
                if not string.IsNullOrEmpty(configInfo:RadarTaskCitizenIcon()) then
                    radarbubble:SetCitizenTaskActive(true)
                    radarbubble:SetCitizenTaskIcon(configInfo:RadarTaskCitizenIcon())
                else
                    radarbubble:SetCitizenTaskActive(false)
                end
                g_Game.SpriteManager:LoadSpriteAsync(self.radarIcon, self.radarTaskIcon)
                bubbleGo:SetActive(self.taskBubbleState ~= false)
            end)
    else
        self.IsRadarTaskEntity = false
    end
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.UpdateConstructing))
end

function TroopHUD:HideConstructing()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.UpdateConstructing))

    if self.constructing then
        self.constructing:ShutDown()
    end
    if self.constructingHandle then
        self.constructingHandle:Delete()
    end
end

function TroopHUD:UpdateConstructing()
    if self.constructing then
        if self.constructing:UpdateProgress(self.ctrl:GetData()) then
            self:HideConstructing()
        end
    end
end

function TroopHUD:OnLodChange(lod,overmax)
    if not self.ctrl then
        return
    end

    self.curLod = lod
    self.hideAll = KingdomMapUtils.InSymbolMapLod(lod)
    if self.provider then
        self.provider:OnLODChanged(self.isOverMax, self.isOverMax)
    end
    self.isOverMax = overmax
    self:SetDirty()
    self:OnLodChange_RadarTaskIcon(lod, overmax)
    self:OnLodChange_WorldEventIcon(lod)
end

function TroopHUD:DelayHideIcon()
    self.facingCamera_bottom.gameObject:SetVisible(false)
end

function TroopHUD:GetBehemothLodIcon(mobId)
    local kMonsterConfig = ConfigRefer.KmonsterData:Find(mobId)
    if not kMonsterConfig then return '' end
    local behemothDataCfg = ConfigRefer.BehemothData:Find(kMonsterConfig:BehemothInfo())
    if not behemothDataCfg then return '' end
    local allianceID = self.ctrl._data.Owner.AllianceID
    local playerID = self.ctrl._data.Owner.PlayerID

    local friendly = ModuleRefer.PlayerModule:IsFriendlyById(allianceID, playerID)
    local neutral = false
    if not friendly then
        neutral = ModuleRefer.PlayerModule:IsNeutral(allianceID)
    end
    local iconFaction
    if friendly then
        iconFaction = '3'
    elseif neutral then
        iconFaction = '4'
    else
        iconFaction = '2'
    end
    
    return behemothDataCfg:MapIcon() .. iconFaction
end

---@param mobEntity wds.MapMob
function TroopHUD:GetBehemothLodIcon2(mobEntity)
    local cageId = mobEntity.MobInfo.BehemothCageId
    ---@type wds.BehemothCage
    local cageEntity = g_Game.DatabaseManager:GetEntity(cageId, DBEntityType.BehemothCage)
    if cageEntity then
        local isCreepInfected = KingdomMapUtils.IsMapEntityCreepInfected(cageEntity)
        return ModuleRefer.VillageModule:GetVillageIcon(cageEntity.Owner.AllianceID, cageEntity.Owner.PlayerID, cageEntity.BehemothCage.ConfigId, false, isCreepInfected)
    end
    local kMonsterConfig = ConfigRefer.KmonsterData:Find(mobEntity.MobInfo.MobID)
    if not kMonsterConfig then return '' end
    local behemothDataCfg = ConfigRefer.BehemothData:Find(kMonsterConfig:BehemothInfo())
    if not behemothDataCfg then return '' end
    local allianceID = self.ctrl._data.Owner.AllianceID
    local playerID = self.ctrl._data.Owner.PlayerID

    local friendly = ModuleRefer.PlayerModule:IsFriendlyById(allianceID, playerID)
    local neutral = false
    if not friendly then
        neutral = ModuleRefer.PlayerModule:IsNeutral(allianceID)
    end
    local iconFaction
    if friendly then
        iconFaction = '3'
    elseif neutral then
        iconFaction = '4'
    else
        iconFaction = '2'
    end
    
    return behemothDataCfg:MapIcon() .. iconFaction
end

function TroopHUD:SetupBottomLevel()
    if not self.facingCamera_bottom then
        return
    end
    self.facingCamera_bottom.gameObject:SetVisible(false)    
    self:SetupMonsterBottomLevel()    
end

---@private
function TroopHUD:SetupMonsterBottomLevel()
    if not self.ctrl._data
        or not self.ctrl._data.MobInfo
        or (self.isInGve and self.ctrl.troopType == SlgUtils.TroopType.Boss)        
    then
        return
    end
    if not self.facingCamera_bottom.gameObject.activeSelf then
        self.lvGo_bottom:SetVisible(false)
    end

    -- local rootTrans = self.facingCamera_bottom.transform
    -- rootTrans.localPosition = Vector3(0,-rootTrans.parent.localPosition.y,0)
    self.facingCamera_bottom.screenOffsetDir = Vector3.down
    self.facingCamera_bottom.radius = self.ctrl:GetRadius() *0.5
    

    local mobConfig = ConfigRefer.KmonsterData:Find(self.ctrl._data.MobInfo.MobID)
    if not mobConfig then
        self.behaviour.gameObject:SetActive(false)
        return
    end

    local needShowLvl = SlgUtils.IsMobCanAttack(mobConfig) and self.ctrl.troopType ~= SlgUtils.TroopType.Behemoth

    local mobClass = mobConfig:MonsterClass()
    local lvBackImg, monsterIcon
    if mobClass == MonsterClassType.Boss then
        lvBackImg = needShowLvl and ArtResourceUtils.GetUIItem( ArtResourceUIConsts.sp_slg_base_lv_c)
        monsterIcon = ArtResourceUtils.GetUIItem( ArtResourceUIConsts.sp_icon_lod_monsters_02)
    elseif mobClass == MonsterClassType.Elite or mobClass == MonsterClassType.TeamElite then
        lvBackImg = needShowLvl and ArtResourceUtils.GetUIItem( ArtResourceUIConsts.sp_slg_base_lv_b)
        monsterIcon = ArtResourceUtils.GetUIItem( ArtResourceUIConsts.sp_icon_lod_monsters_01)
    elseif mobClass == MonsterClassType.Behemoth then
        monsterIcon = '' --self:GetBehemothLodIcon2(self.ctrl._data)
        lvBackImg = ''  
    else
        lvBackImg = needShowLvl and ArtResourceUtils.GetUIItem( ArtResourceUIConsts.sp_slg_base_lv_a)
        monsterIcon = ArtResourceUtils.GetUIItem( ArtResourceUIConsts.sp_icon_lod_monsters)
    end
    
    if needShowLvl then
        g_Game.SpriteManager:LoadSpriteAsync(lvBackImg, self.lvBack_bottom)
        self.lvTxt_bottom.text = tostring(self.ctrl._data.MobInfo.Level)
    end

    g_Game.SpriteManager:LoadSpriteAsync(monsterIcon, self.monsterIcon)
    self.monsterIconGo_bottom.transform.localPosition = CS.UnityEngine.Vector3(0, 20, 0)
    
    if self.bottomLaterActiver then
        self.bottomLaterActiver:Stop()
    end
    self.bottomLaterActiver = TimerUtility.DelayExecuteInFrame(function()
        --self.monsterIconGo_bottom:SetVisible(self.isOverMax)
        ModuleRefer.MapHUDModule:InitHUDFade(self.monsterIconSetter, self.isOverMax)
        if needShowLvl then
            ModuleRefer.MapHUDModule:InitHUDFade(self.lvIconSetter, true)
            self.lvGo_bottom:SetVisible(true)
        end
    end,3)
end

function TroopHUD:SetupAllianceBehemothBottomLevel()
    if not self.ctrl._data
        or not self.ctrl._data.BehemothTroopInfo        
    then
        return
    end
    if not self.facingCamera_bottom.gameObject.activeSelf then
        self.lvGo_bottom:SetVisible(false)
    end

    -- local rootTrans = self.facingCamera_bottom.transform
    -- rootTrans.localPosition = Vector3(0,-rootTrans.parent.localPosition.y,0)
    self.facingCamera_bottom.screenOffsetDir = Vector3.down
    self.facingCamera_bottom.radius = self.ctrl:GetRadius() *0.5
    local monsterIcon = self:GetBehemothLodIcon(self.ctrl._data.BehemothTroopInfo.MonsterTid)       
   
    if not string.IsNullOrEmpty(monsterIcon) then
        g_Game.SpriteManager:LoadSpriteAsync(monsterIcon, self.monsterIcon)
        self.monsterIconGo_bottom.transform.localPosition = CS.UnityEngine.Vector3(0, 80, 0)
    end
    if self.bottomLaterActiver then
        self.bottomLaterActiver:Stop()
    end
    self.bottomLaterActiver = TimerUtility.DelayExecuteInFrame(function()
        --self.monsterIconGo_bottom:SetVisible(self.isOverMax)
        ModuleRefer.MapHUDModule:InitHUDFade(self.monsterIconSetter, self.isOverMax)      
    end,3)
end

function TroopHUD:OnLODChanged_MobBottomLevel(oldOverMax, newOverMax)
    if not self.ctrl._data
        or not self.ctrl._data.MobInfo
        or (self.isInGve and self.ctrl.troopType == SlgUtils.TroopType.Boss)       
        or self.module:IsTroopInFog(self.ctrl)
    then
        self.facingCamera_bottom.gameObject:SetVisible(false)
        return
    end   

    -- if self.module:IsInCity() then
    local mobCfg =  ConfigRefer.KmonsterData:Find(self.ctrl._data.MobInfo.MobID)
    if not mobCfg then
        return
    end
    local needShowLvl = SlgUtils.IsMobCanAttack(mobCfg)  and self.ctrl.troopType ~= SlgUtils.TroopType.Behemoth
    if not needShowLvl and not newOverMax then
        self.facingCamera_bottom.gameObject:SetVisible(false)
        return
    end
    -- end

    self.facingCamera_bottom.gameObject:SetVisible(true)    
    if self.curLod < 1 then
        self.monsterIconGo_bottom:SetVisible(false)
        self.radarTaskGo:SetVisible(false)
    else
        if oldOverMax == newOverMax then
            if not oldOverMax then
                ModuleRefer.MapHUDModule:InitHUDFade(self.monsterIconSetter, false)
                ModuleRefer.MapHUDModule:InitHUDFade(self.lvIconSetter, true)
                if self.showEventMark then ModuleRefer.MapHUDModule:InitHUDFade(self.eventMarkSetter, true)end
                self.monsterTrigger:SetEnable(false)
            else
                if self.IsRadarTaskEntity then
                    self.monsterIconGo_bottom:SetVisible(false)
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.radarTaskIconSetter, MapHUDFadeDefine.Stay)
                else
                    self.monsterIconGo_bottom:SetVisible(true)
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.monsterIconSetter, MapHUDFadeDefine.Stay)
                end
                ModuleRefer.MapHUDModule:UpdateHUDFade(self.lvIconSetter, MapHUDFadeDefine.Stay)
                self.monsterTrigger:SetEnable(true)
            end
        else
            if newOverMax then
                if self.IsRadarTaskEntity then
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.radarTaskIconSetter, MapHUDFadeDefine.FadeIn)
                else
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.monsterIconSetter, MapHUDFadeDefine.FadeIn)
                end
                if self.showEventMark then 
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.eventMarkSetter, MapHUDFadeDefine.FadeOut) 
                end
                ModuleRefer.MapHUDModule:UpdateHUDFade(self.lvIconSetter, MapHUDFadeDefine.Stay)
            else
                if self.IsRadarTaskEntity then
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.radarTaskIconSetter, MapHUDFadeDefine.FadeOut)
                else
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.monsterIconSetter, MapHUDFadeDefine.FadeOut)
                end
                ModuleRefer.MapHUDModule:UpdateHUDFade(self.lvIconSetter, MapHUDFadeDefine.Stay)               
                if self.showEventMark then 
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.eventMarkSetter, MapHUDFadeDefine.FadeIn) 
                end
            end
            self.monsterTrigger:SetEnable( newOverMax and not self.IsRadarTaskEntity)
            -- self.trigger.Instance:SetEnable( newOverMax and self.IsRadarTaskEntity)
        end
    end
    self.lvGo_bottom:SetVisible(needShowLvl)
end

function TroopHUD:OnLODChanged_BehemothBottomLevel(oldOverMax, newOverMax)
    if not self.ctrl._data        
        or self.module:IsTroopInFog(self.ctrl)
    then
        self.facingCamera_bottom.gameObject:SetVisible(false)
        return
    end   

    self.facingCamera_bottom.gameObject:SetVisible(true)    
    if self.curLod < 1 then
        self.monsterIconGo_bottom:SetVisible(false)
        self.radarTaskGo:SetVisible(false)       
    else
        if oldOverMax == newOverMax then
            if not oldOverMax then
                ModuleRefer.MapHUDModule:InitHUDFade(self.monsterIconSetter, false)
                ModuleRefer.MapHUDModule:InitHUDFade(self.lvIconSetter, true)
                if self.showEventMark then ModuleRefer.MapHUDModule:InitHUDFade(self.eventMarkSetter, true)end
                self.monsterTrigger:SetEnable(false)
            else
                if self.IsRadarTaskEntity then
                    self.monsterIconGo_bottom:SetVisible(false)
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.radarTaskIconSetter, MapHUDFadeDefine.Stay)
                else
                    self.monsterIconGo_bottom:SetVisible(true)
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.monsterIconSetter, MapHUDFadeDefine.Stay)
                end
                ModuleRefer.MapHUDModule:UpdateHUDFade(self.lvIconSetter, MapHUDFadeDefine.Stay)
                self.monsterTrigger:SetEnable(true)
            end
        else
            if newOverMax then
                if self.IsRadarTaskEntity then
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.radarTaskIconSetter, MapHUDFadeDefine.FadeIn)
                else
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.monsterIconSetter, MapHUDFadeDefine.FadeIn)
                end
                if self.showEventMark then 
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.eventMarkSetter, MapHUDFadeDefine.FadeOut) 
                end
                ModuleRefer.MapHUDModule:UpdateHUDFade(self.lvIconSetter, MapHUDFadeDefine.Stay)
            else
                if self.IsRadarTaskEntity then
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.radarTaskIconSetter, MapHUDFadeDefine.FadeOut)
                else
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.monsterIconSetter, MapHUDFadeDefine.FadeOut)
                end
                ModuleRefer.MapHUDModule:UpdateHUDFade(self.lvIconSetter, MapHUDFadeDefine.Stay)               
                if self.showEventMark then 
                    ModuleRefer.MapHUDModule:UpdateHUDFade(self.eventMarkSetter, MapHUDFadeDefine.FadeIn) 
                end
            end
            self.monsterTrigger:SetEnable( newOverMax and not self.IsRadarTaskEntity)
            -- self.trigger.Instance:SetEnable( newOverMax and self.IsRadarTaskEntity)
        end
    end
    self.lvGo_bottom:SetVisible(false)
end

function TroopHUD:SetupWorldEventMark()    
    self.eventMark:SetVisible(false)
    self.showEventMark = false

    if self.ctrl._data.LevelEntityInfo 
        and self.ctrl._data.LevelEntityInfo.LevelEntityId > 0 
        and (self.ctrl._data.Owner.ExclusivePlayerId == 0 or self.ctrl._data.Owner.ExclusivePlayerId == self.module:MySelf().ID)
    then
        if ModuleRefer.WorldEventModule:IsWorldEventActive(self.ctrl._data.LevelEntityInfo.LevelEntityId) then
            local entity = g_Game.DatabaseManager:GetEntity(self.ctrl._data.LevelEntityInfo.LevelEntityId, DBEntityType.Expedition)
            self:SetWorldEventIcon(entity)
        end
    end
end

function TroopHUD:UpdateWorldEventMark()    
    if not self.showEventMark then
        return 
    end
    if self.ctrl:IsSelected() or self.ctrl:IsFocus() then        
        self.eventMark.localPosition = CS.UnityEngine.Vector3.up * 290    
    elseif self.eventMark and self.state == TroopHUD.State.InBattle then        
        self.eventMark.localPosition = CS.UnityEngine.Vector3.up * 290        
    else
        self.eventMark.localPosition = CS.UnityEngine.Vector3.up * (120 + self.heroHeight)
   end
end

function TroopHUD:UpdateTitle()
    if not self.ctrl or not self.ctrl._data.OwnerExt then
        self.titleGo:SetActive(false)
        return
    end

    local titleID = self.ctrl._data.OwnerExt.Title
    local configInfo = ConfigRefer.Adornment:Find(titleID)
    if configInfo and configInfo:Quality() == AdornmentQuality.Golden then
        self.titleGo:SetActive(true)
        self.textTitle.text = I18N.Get(configInfo:Name())
        local titleConfig = ConfigRefer.AdornmentTitle:Find(tonumber(configInfo:Icon()))
        if titleConfig then
            g_Game.SpriteManager:LoadSpriteAsync(titleConfig:TitleIcon(), self.imgIcon)
            g_Game.SpriteManager:LoadSpriteAsync(titleConfig:TitleBaseL(), self.imgTitle_l)
            g_Game.SpriteManager:LoadSpriteAsync(titleConfig:TitleBase(), self.imgTitle)
            g_Game.SpriteManager:LoadSpriteAsync(titleConfig:TitleBaseR(), self.imgTitle_r)
        end
    else
        self.titleGo:SetActive(false)
    end
end

function TroopHUD:SetHeroIconImgVisible(show,troopType)
    self.iconGo:SetVisible(show)
    self.troopStateBack:SetVisible(show and self:ShouldUpdateTroopStateIcon())
    self.troopKindBaseGo:SetVisible(show)
    if show and not self.iconImgSpLoaded then
        self.iconImgSpLoaded = true
        ---@type wds.Troop | wds.MapMob
        local troop = SlgUtils.GetCaptainTroop(self.ctrl._data)
        if troop.TypeHash == DBEntityType.MobileFortress then
            local behemothTid = troop.BehemothTroopInfo.MonsterTid
            local _, icon, _ = MailUtils.GetMonsterNameIconLevel(behemothTid)
            g_Game.SpriteManager:LoadSpriteAsync(icon, self.monsterIconImg)
            self.iconImg:SetVisible(false)
            self.troopKindBaseGo:SetVisible(false)
        else
            if troopType == SlgUtils.TroopType.Monster then
                self.monsterIconImg:SetVisible(true)
                self.iconImg:SetVisible(false)

                if troop.Battle.Group.Heros and troop.Battle.Group.Heros[0] then
                    local mainHero = troop.Battle.Group.Heros[0]
                    local heroIcon = MailUtils.GetHeroHeadMiniById(mainHero.HeroID)
                    g_Game.SpriteManager:LoadSpriteAsync(heroIcon, self.monsterIconImg)
                end
            else
                self.monsterIconImg:SetVisible(false)
                self.iconImg:SetVisible(true)

                local mainHeroId = SlgUtils.GetTroopLeadHeroId(troop.Battle.Group.Heros)
                local heroIcon = MailUtils.GetHeroHeadMiniById(mainHeroId)
                g_Game.SpriteManager:LoadSpriteAsync(heroIcon, self.iconImg)
            end
            
            g_Game.SpriteManager:LoadSpriteAsync(
                ArtResourceUtils.GetUIItem(HeroUIUtilities.GetTroopTypeTextureId(troop.Battle.Group.Heros))
                ,self.troopKindImg)
        end

        if troopType == SlgUtils.TroopType.MySelf then
            g_Game.SpriteManager:LoadSpriteAsync(ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_troop_frame_a),self.iconBaseImg)
        elseif troopType == SlgUtils.TroopType.Friend then
            g_Game.SpriteManager:LoadSpriteAsync(ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_troop_frame_b),self.iconBaseImg)
        else
            g_Game.SpriteManager:LoadSpriteAsync(ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_troop_frame_c),self.iconBaseImg)
        end
    end
end

function TroopHUD:SetTroopNameTxtVisible(show,troopType)
    if show then
        local troop = SlgUtils.GetCaptainTroop(self.ctrl._data)
        self.nameTxt.text = ModuleRefer.PlayerModule.FullNameOwner(troop.Owner)
        self.nameTxt.color = SlgUtils.GetEntityColor(troopType)
        self.nameTxt:SetVisible(true)
    else
        self.nameTxt:SetVisible(false)
    end
end

function TroopHUD:SetBehemothNameTxtVisible(show,troopType)
    if show and self.ctrl._data and self.ctrl._data.BehemothTroopInfo then
        local troopData = self.ctrl._data
        local behemothCfg = ConfigRefer.KmonsterData:Find(troopData.BehemothTroopInfo.MonsterTid)
        local allianceName = troopData.Owner.AllianceAbbr.String
        self.nameTxt.text = string.format("[%s]%s", allianceName, I18N.Get(behemothCfg:Name()))
        self.nameTxt.color = SlgUtils.GetEntityColor(troopType)
        self.nameTxt:SetVisible(true)
    else
        self.nameTxt:SetVisible(false)
    end
end

function TroopHUD:UpateRadarBubble()
    if not self.bubblePosTrans then
        return
    end
   if self.ctrl:IsSelected() or self.ctrl:IsFocus() then
        self.bubblePosTrans.localPosition = CS.UnityEngine.Vector3.up * (240 + self.heroHeight)
    elseif self.battleRelation and self.state == TroopHUD.State.InBattle then
        self.bubblePosTrans.localPosition = CS.UnityEngine.Vector3.up * (240 + self.heroHeight)
    else
        self.bubblePosTrans.localPosition = CS.UnityEngine.Vector3.up * (45 + self.heroHeight)
   end
end

function TroopHUD:OnClickRadarTaskBtn()
    self.ctrl._module:SelectAndOpenTroopMenu(self.ctrl)
end

function TroopHUD:SetupRadarBubble()
    if not self.ctrl then
        return
    end
    if ModuleRefer.RadarModule:IsRadarTaskEntity(self.ctrl.ID) then
        self.IsRadarTaskEntity = true
        if KingdomMapUtils.InMapLowLod(self.curLod) then
            self:RefreshRadarTaskLodBase()
            self.radarTaskGo:SetVisible(true)
            ModuleRefer.MapHUDModule:UpdateHUDFade(self.radarTaskIconSetter, MapHUDFadeDefine.FadeIn)
        end
    else
        self.IsRadarTaskEntity = false
    end
end

function TroopHUD:OnLodChange_RadarTaskIcon(lod, isOverMax)
    if KingdomMapUtils.InMapLowLod(lod) and self.IsRadarTaskEntity then
        if self.radarBubbleCreateHandle then
            ModuleRefer.RadarModule:GetCreateHelper():Delete(self.radarBubbleCreateHandle)
            self.radarBubbleCreateHandle = nil
            self.bubblePosTrans = nil
        end
        self:RefreshRadarTaskLodBase()
        self.radarTaskGo:SetVisible(true)
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.radarTaskIconSetter, MapHUDFadeDefine.FadeIn)
    else
        if lod < KingdomConstant.HighLod and self.IsRadarTaskEntity then
            if lod <= KingdomConstant.LowLod then
                self.radarTaskGo:SetVisible(false)
            else
                self:RefreshRadarTaskLodBase()
                self.radarTaskGo:SetVisible(true)
                ModuleRefer.MapHUDModule:UpdateHUDFade(self.radarTaskIconSetter, MapHUDFadeDefine.FadeIn)
            end
        else
            self.radarTaskGo:SetVisible(false)
            ModuleRefer.MapHUDModule:UpdateHUDFade(self.radarTaskIconSetter, MapHUDFadeDefine.FadeOut)
        end
    end
    self.trigger.Instance:SetTrigger(Delegate.GetOrCreate(self, self.OnClickRadarTaskBtn))
end

function TroopHUD:RefreshRadarTaskLodBase()
    if Utils.IsNotNull(self.radarTaskBase) then
        local radarTaskId = ModuleRefer.RadarModule:GetRadarTaskId(self.ctrl.ID)
        local configInfo = ConfigRefer.RadarTask:Find(radarTaskId)
        local baseName
        if configInfo:IsSpecial() then
            self.radarIcon = configInfo:RadarTaskIcon()
            baseName = "sp_city_bubble_base_events"
        else
            self.radarIcon = "sp_comp_icon_radar_monster"
            baseName = ModuleRefer.RadarModule:GetRadarTaskLodBase(self.ctrl.ID)
        end
        if not string.IsNullOrEmpty(baseName) then
            if self.radarIcon =="" then
                local taskConfig = ConfigRefer.RadarTask:Find(radarTaskId)
                local itemGroupConfig = ConfigRefer.ItemGroup:Find(taskConfig:QualityExtReward(4))
                local itemGroup = itemGroupConfig:ItemGroupInfoList(1)
                self.radarIcon = ConfigRefer.Item:Find(itemGroup:Items()):Icon()
            end
            g_Game.SpriteManager:LoadSpriteAsync(baseName, self.radarTaskBase)
            g_Game.SpriteManager:LoadSpriteAsync(self.radarIcon, self.radarTaskIcon)
        end
    end
end

function TroopHUD:OnLodChange_WorldEventIcon(lod)
    if lod == 1 and self.showEventMark then
        self.eventIcon:SetVisible(true)
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.eventMarkSetter, MapHUDFadeDefine.FadeIn)
    else
        self.eventIcon:SetVisible(false)
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.eventMarkSetter, MapHUDFadeDefine.FadeOut)
    end
end

--世界事件交互物
function TroopHUD:InteractorSetup()
    self.eventIcon:SetVisible(true)
    self.facingCamera_bottom.gameObject:SetVisible(true)
    self.facingCamera.gameObject:SetVisible(false)
    self.lvGo_bottom:SetVisible(false)
    self.monsterIcon.gameObject:SetVisible(false)
    self.radarTaskGo:SetVisible(false)
end

function TroopHUD:SetWorldEventIcon(entity)
    self.showEventMark = true
    local icon
    local isMine, isMulti, isAlliance, isBigEvent = ModuleRefer.WorldEventModule:CheckEventType(entity)
    if isMine or isMulti then
            icon = "sp_icon_lod_event"
     elseif isAlliance then
        if isBigEvent then
            icon = "sp_icon_lod_event_league"
        else
            icon = "sp_icon_lod_event_multi"
        end
    end
    g_Game.SpriteManager:LoadSpriteAsync(icon, self.eventIcon)
    if self.eventMarkLaterActiver then
        self.eventMarkLaterActiver:Stop()
    end
    self.eventMark.localPosition = CS.UnityEngine.Vector3.up * (150 + self.heroHeight)
    self.eventMarkLaterActiver = TimerUtility.DelayExecuteInFrame( function()
        self.eventMark:SetVisible(true)
        ModuleRefer.MapHUDModule:InitHUDFade(self.eventMarkSetter, not self.isOverMax)
    end,3)        
end
return TroopHUD