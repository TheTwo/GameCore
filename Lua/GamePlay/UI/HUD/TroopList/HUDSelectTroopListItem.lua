local BaseTableViewProCell = require('BaseTableViewProCell')
local UIHelper = require('UIHelper')
local HeroUIUtilities = require('HeroUIUtilities')
local DBEntityPath = require('DBEntityPath')
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require('UIMediatorNames')
local I18N = require('I18N')
local Delegate = require('Delegate')
local SlgBattlePowerHelper = require('SlgBattlePowerHelper')
local Utils = require("Utils")
local CheckTroopTrusteeshipStateDefine = require("CheckTroopTrusteeshipStateDefine")
local SlgUtils = require("SlgUtils")
local HUDTroopUtils = require("HUDTroopUtils")

---@class HUDSelectTroopListItem : BaseTableViewProCell
local HUDSelectTroopListItem = class('HUDSelectTroopListItem',BaseTableViewProCell)

---@class HUDSelectTroopListItemData
---@field index number
---@field troopInfo TroopInfo
---@field data HUDSelectTroopListData
---@field troopList HUDSelectTroopList
---@field isAssemble boolean
---@field joinAssembleTeamId number|nil
---@field isEscrow boolean
---@field chooseEscrow boolean
---@field preFetchCache HUDSelectTroopAssembleTimePreFetch
---@field escrowType number|nil
---@field onSelectEscrowType fun(escrowType:number)
---@field onToggleChooseEscrow fun(isOn:boolean)
---@field noEscrowChoice table<wds.CreateAllianceAssembleType, boolean>|nil

function HUDSelectTroopListItem:OnCreate(param)
    self._selfCellRect = self:RectTransform("")
    self:PointerClick('',  Delegate.GetOrCreate(self, self.OnBtnClicked))

    --hero head icon componets
    self.compChildCardHeroS = self:LuaObject('child_card_hero_s')
    self.imgTroopStatus = self:Image('p_troop_status')
    self.imgIconStatus = self:Image('p_icon_status')
    self.sliderTroopHp = self:Slider('p_troop_hp')
    ---@type CS.StatusRecordParent
	self.mulitSelectToggle = self:BindComponent("child_toggle_set", typeof(CS.StatusRecordParent))
	self.mulitSelectButton = self:Button("child_toggle_set", Delegate.GetOrCreate(self, self.OnMulitSelectToggleClick))
    self.compareEmoji = self:Image("p_icon_compare_emoji")

    --battle tips components
    self.goItemTips = self:GameObject('p_item_tips')
    ---@type HUDSelectTroopBattleTipComponent
    self.compItemTip = self:LuaObject('p_item_tips')

    ---@type HUDSelectTroopBattleAssemblyTipComponent
    self.compAssembleTip = self:LuaObject('p_item_tips_league')
    self.lockGO = self:GameObject("p_lock")
    self.emptyGo = self:GameObject("p_status_empty")
    self.tipArrow = self:GameObject("p_arrow_1")

    --Set Init State
    self.compItemTip:SetVisible(false)
    self.goItemTips:SetActive(false)
    self.compAssembleTip:SetVisible(false)
    self.tipArrow:SetVisible(false)

    self.escrowFlag = self:GameObject("p_icon_escrow")

	self.backToggleValue = false
    self.escrowType = nil
    
    ---@type table<wds.CreateAllianceAssembleType, boolean>|nil
    self.noEscrowChoice = nil
    self.onSelectEscrowType = nil
    self.chooseEscrow = false
    self.chooseToggleEscrowChanged = nil
end

---@param data HUDSelectTroopListItemData
function HUDSelectTroopListItem:OnFeedData(data)
    if not data or not data.data then
        return
    end

    self.listItemData = data
    self.listData = data.data
    self.index = data.index
    self.troopInfo = data.troopInfo
    self.overrideClickGo = data.data.overrideItemClickGoFunc
    self.troopList = data.troopList
    self.allowEscrow = data.isEscrow
    self.chooseEscrow = data.chooseEscrow and data.isEscrow
    self.chooseToggleEscrowChanged = data.onToggleChooseEscrow
    self.escrowType = data.escrowType
    self.noEscrowChoice = data.noEscrowChoice
    self.onSelectEscrowType = data.onSelectEscrowType
    self.troopData = self.troopInfo.entityData

    local heroCfgID = ModuleRefer.TroopModule:GetPresetLeadHeroId(self.troopInfo.preset)

    self.hasComparePower = self.listData.needPower and self.listData.recommendPower and self.listData.needPower > 0 and self.listData.recommendPower > 0 and not self.listData.isCollectingRes
    self.locked = self.troopInfo.locked
    self.empty = not self.locked and heroCfgID <= 0
    self.showStatus = not self.locked and not self.empty
    self.showHero = not self.locked and not self.empty
    self.showEmoji = not self.locked and not self.empty and not self.listItemData.isAssemble and self.hasComparePower

    if heroCfgID > 0 then
        ---@type HeroInfoData
        local itemData =
        {
            heroData = ModuleRefer.HeroModule:GetHeroByCfgId(heroCfgID),
            hideExtraInfo = true,
            onClick = Delegate.GetOrCreate(self, self.OnBtnClicked),
        }
        self.compChildCardHeroS:FeedData(itemData)

        local troopPower = ModuleRefer.SlgModule:GetTroopPowerByPreset(self.troopInfo.preset)
        local param = self.listData
        local compareResult = HUDTroopUtils.ComparePower(troopPower, param.needPower, param.recommendPower, param.catchPet)
        g_Game.SpriteManager:LoadSprite(SlgBattlePowerHelper.GetPowerCompareIcon(compareResult), self.compareEmoji)    
    end

    self.lockGO:SetActive(self.locked)
    self.emptyGo:SetActive(self.empty)
    self.compChildCardHeroS:SetVisible(self.showHero)
    self.compareEmoji:SetVisible(self.showEmoji)
    self.imgTroopStatus:SetVisible(self.showStatus)
    self.sliderTroopHp:SetVisible(self.showStatus)

    self:OnTroopPresetChanged(nil,{[ self.index] = self.troopInfo.preset})
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.TroopPresets.Presets.MsgPath,Delegate.GetOrCreate(self,self.OnTroopPresetChanged))

    self.mulitSelectButton:SetVisible(false)
    self.mulitSelected = false

    if Utils.IsNotNull(self.escrowFlag) then
        self.escrowFlag:SetVisible(false)
    end
end

function HUDSelectTroopListItem:OnRecycle(param)
    self.compItemTip:SetVisible(false)
    self.compAssembleTip:SetVisible(false)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.TroopPresets.Presets.MsgPath,Delegate.GetOrCreate(self,self.OnTroopPresetChanged))
end

function HUDSelectTroopListItem:OnClose(param)
    self.compItemTip:SetVisible(false)
    self.compAssembleTip:SetVisible(false)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.TroopPresets.Presets.MsgPath,Delegate.GetOrCreate(self,self.OnTroopPresetChanged))
end

function HUDSelectTroopListItem:UpdateTroopStatus()
    local presetData = self.troopInfo.preset
    local troopData = self.troopInfo.entityData
    local iconName, backName, show = HeroUIUtilities.MyTroopStateIconByTroopAndPreset(troopData, presetData)
    UIHelper.LoadSprite(iconName, self.imgIconStatus)
    UIHelper.LoadSprite(backName, self.imgTroopStatus)

    self.imgIconStatus:SetVisible(show)
    self.imgTroopStatus:SetVisible(show)

    if presetData then
        local troopHp,troopMaxHp = ModuleRefer.SlgModule:GetTroopHpByPreset(presetData)
        if troopMaxHp < 1 then
            self.sliderTroopHp:SetVisible(false)
        else
            self.sliderTroopHp:SetVisible(true)
            self.sliderTroopHp.value = math.clamp01(troopHp / troopMaxHp)
        end
    else
        self.sliderTroopHp:SetVisible(true)
        self.sliderTroopHp.value = 1
    end

    local isInjured = false   
    if presetData then
        isInjured = SlgUtils.PresetAllHeroInjured(presetData,ModuleRefer.SlgModule.battleMinHpPct)
    end
    UIHelper.SetGray(self.compChildCardHeroS.CSComponent.gameObject,isInjured)

end

function HUDSelectTroopListItem:SetupTipInfo()
    if not self.troopInfo then
        self.compItemTip:SetVisible(false)
        self.goItemTips:SetActive(false)
        self.tipArrow:SetVisible(false)
        self.compAssembleTip:SetVisible(false)
    end
    if not self.listItemData.isAssemble then
        if (self.troopInfo) then           
            if (self.troopInfo.preset) then
                if self.listData.showAutoFinish then
                    self.backToggleValue = self.troopInfo.preset.AutoBackAfterClearExpedition       
                    if not self.backToggleValue then
                        ModuleRefer.SlgModule:SetTroopAutoFinishBattle(self.index, true)      
                        self.backToggleValue = true
                    end            
                else
                    self.backToggleValue = self.troopInfo.preset.Autoback
                end
            else
                self.backToggleValue = false
            end
        
        end
        local troopHp = ModuleRefer.SlgModule:GetTroopHpByPreset(self.troopInfo.preset)
        local troopPower = ModuleRefer.SlgModule:GetTroopPowerByPreset(self.troopInfo.preset)
        
        ---@type HUDSelectTroopBattleTipParam
        local tipCompData = {}
        tipCompData.listParam = self.listData
        
        if self.listData.showAutoFinish then
            tipCompData.showBack = false
            tipCompData.showAutoFinish = false
        elseif self.listData.isCollectingRes then
            tipCompData.showBack = true
        else
            tipCompData.showBack = self.listData.showBack or false
            tipCompData.showAutoFinish = false
        end
        tipCompData.onBackToggleClicked = Delegate.GetOrCreate(self,self.OnBackToggleClick)
        tipCompData.onGotoButtonClicked = Delegate.GetOrCreate(self,self.OnBtnGotoClicked)
        tipCompData.onDisableGotoButtonClicked = Delegate.GetOrCreate(self,self.OnBtnDisableGotoClicked)
                
        tipCompData.autoBack = self.backToggleValue

        tipCompData.preset = self.troopInfo.preset
        tipCompData.troopPower = troopPower
        tipCompData.troopHp = troopHp
        tipCompData.allowEscrow = self.allowEscrow
        tipCompData.chooseEscrow = self.chooseEscrow
        tipCompData.escrowType = self.escrowType
        tipCompData.onEscrowTypeChanged = Delegate.GetOrCreate(self, self.OnEscrowTypeChanged)
        tipCompData.onEscrowToggleChanged = Delegate.GetOrCreate(self, self.OnToggleChooseEscrowChanged)
        tipCompData.selectedCount = 1
        tipCompData.selectedTroopIdxSet = {}
        tipCompData.selectedTroopIdxSet[self.index] = true
        tipCompData.noEscrowChoice = self.noEscrowChoice

        if self.listData.showAutoFinish and self.backToggleValue then
            if self.troopInfo.entityData and self.troopInfo.entityData.MapStates.StateWrapper2.AutoBattle then
                tipCompData.disableGotoButton = true
            end
        end

        if SlgUtils.PresetAllHeroInjured(self.troopInfo.preset,ModuleRefer.SlgModule.battleMinHpPct) then
            tipCompData.disableGotoButton = true
        end

        if ModuleRefer.SlgModule:IsInMyCity() and self.troopInfo.preset.CopyTroopId > 0 and not self.listData.isSE  then
            tipCompData.disableGotoButton = true
        end

        if self.listData.isCollectingRes then
            local amount, time = ModuleRefer.MapResourceFieldModule:PrecalculateCollectInfo(self.troopInfo, self.troopInfo.preset, self.listData.entity)
            tipCompData.troopCollectAmount = amount
            tipCompData.troopCollectTime = time
            if amount <= 0 then
                tipCompData.disableGotoButton = true
            end
        end

        self.compItemTip:FeedData(tipCompData)
    end
end

function HUDSelectTroopListItem:SetupAssembleTipInfo()
    if not self.troopInfo then
        self.compItemTip:SetVisible(false)
        self.goItemTips:SetActive(false)
        self.tipArrow:SetVisible(false)
        self.compAssembleTip:SetVisible(false)
    end

    local troopPower = ModuleRefer.SlgModule:GetTroopPowerByPreset(self.troopInfo.preset)
    ---@type HUDAssembleTipComponentParam
    local tipCompData = {}
    tipCompData.listParam = self.listData
    tipCompData.listItem = self.listItemData
    tipCompData.troopPower = troopPower
    tipCompData.preset = self.troopInfo.preset
    tipCompData.arrowPosY = self._selfCellRect.localPosition.y
    tipCompData.onGotoButtonClicked = Delegate.GetOrCreate(self,self.OnAssembleStartButtonClick)
    self.compAssembleTip:FeedData(tipCompData)

end

---@param param CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function HUDSelectTroopListItem:OnBtnClicked(param, eventData)
    if self.locked then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('formation_locked'))
        return
    end

    if self.empty then
        ---@type UITroopMediatorParam
        local param = {}
        param.selectedTroopIndex = self.index
        g_Game.UIManager:Open(UIMediatorNames.UITroopMediator, param)
        return
    end

    g_Game.EventManager:TriggerEvent(EventConst.ON_SELECT_LEFT_TROOP, self.index)
end

function HUDSelectTroopListItem:Select()
    self.compareEmoji:SetVisible(false)

    if self.listItemData.isAssemble then
        self.compItemTip:SetVisible(false)
        self.goItemTips:SetActive(false)
        self.tipArrow:SetVisible(false)
        self.compAssembleTip:SetVisible(true)
        self.compChildCardHeroS:ChangeStateSelect(true)
        self:SetupAssembleTipInfo()
    else
        if not self.troopList or not self.troopList.selectAll then
            self.compItemTip:SetVisible(true)
            self.goItemTips:SetActive(true)
            self.tipArrow:SetVisible(true)
            self.compAssembleTip:SetVisible(false)
            self.compChildCardHeroS:ChangeStateSelect(true)
            self:SetupTipInfo()
        else
            self.compItemTip:SetVisible(false)
            self.goItemTips:SetActive(false)
            self.tipArrow:SetVisible(false)
            self.compAssembleTip:SetVisible(false)
            self.mulitSelectButton:SetVisible(true)
            self.mulitSelected = true
            self.mulitSelectToggle:Play(1)
            self.compChildCardHeroS:ChangeStateSelect(false)
        end
    end
end
function HUDSelectTroopListItem:UnSelect()
    self.compItemTip:SetVisible(false)
    self.goItemTips:SetActive(false)
    self.tipArrow:SetVisible(false)
    self.compAssembleTip:SetVisible(false)
    self.compChildCardHeroS:ChangeStateSelect(false)
    if not self.troopList or not self.troopList.selectAll then
        self.mulitSelectButton:SetVisible(false)
        self.compareEmoji:SetVisible(self.showEmoji)
    end
end

---@param args HUDSelectTroopListGoParameter|nil
function HUDSelectTroopListItem:OnBtnGotoClicked(args)
    local needCheckTrusteeship = true
    if self.listData and self.listData.isSE then
        needCheckTrusteeship = false
    end
    if not needCheckTrusteeship then
        HUDTroopUtils.StartSingleMarch(self.listData, self.index)
        g_Game.UIManager:CloseByName(UIMediatorNames.HUDSelectTroopList)
        return
    end
    local isTrusteeship = ModuleRefer.SlgModule.troopManager:CheckTroopTrusteeshipState(self.troopData,self.index)
    if isTrusteeship == CheckTroopTrusteeshipStateDefine.State.None then
        HUDTroopUtils.StartSingleMarch(self.listData, self.index)
    elseif isTrusteeship == CheckTroopTrusteeshipStateDefine.State.InEscrowPreparing then
        HUDTroopUtils.StartSingleMarch(self.listData, self.index)
    elseif CheckTroopTrusteeshipStateDefine.IsStateCanCancel(isTrusteeship) then
        ModuleRefer.SlgModule.troopManager:CancelTroopTrusteeshipAndGoOn(self.troopData,self.index,function(cancel)
            if cancel then
                ModuleRefer.SlgModule.selectManager:RefreshSelectedData()
                HUDTroopUtils.StartSingleMarch(self.listData, self.index)
            end
        end,isTrusteeship == CheckTroopTrusteeshipStateDefine.State.InAssemblePreparing)
    else
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_check_hosting_stop_title"))
    end
end

function HUDSelectTroopListItem:OnBtnDisableGotoClicked(args)
    if self.listData.showAutoFinish then   
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('autobattle_turnoff'))
    end

    if SlgUtils.PresetAllHeroInjured(self.troopInfo.preset,ModuleRefer.SlgModule.battleMinHpPct) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('toast_hp0_march_alert'))
    end

    if ModuleRefer.SlgModule:IsInMyCity() and self.troopInfo.preset.CopyTroopId > 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('battlewar_innerslg'))
    end

end

function HUDSelectTroopListItem:OnBackToggleClick()
    if self.listData.showAutoFinish then       
        ModuleRefer.SlgModule:SetTroopAutoFinishBattle(self.index, not self.backToggleValue)       
    else
        ModuleRefer.SlgModule:SetTroopAutoBack(self.index,not self.backToggleValue)
    end
end

function HUDSelectTroopListItem:OnEscrowTypeChanged(type)
    self.escrowType = type
    if self.onSelectEscrowType then
        self.onSelectEscrowType(type)
    end
end

function HUDSelectTroopListItem:OnToggleChooseEscrowChanged(isOn)
    self.chooseEscrow = isOn
    if self.chooseToggleEscrowChanged then
        self.chooseToggleEscrowChanged(isOn)
    end
end

function HUDSelectTroopListItem:OnMulitSelectToggleClick()
    self.mulitSelected = not self.mulitSelected
    self.mulitSelectToggle:Play( self.mulitSelected and 1 or 0)
    if self.troopList then
        self.troopList:OnItemMulitToggle(self.index,self.mulitSelected)
    end
end

---@param data wds.CastleBrief
---@param changed wds.TroopPreset[]
function HUDSelectTroopListItem:OnTroopPresetChanged(data,changed)
    if not self.troopInfo or not changed[self.index] then
        return
    end
    if self.listItemData.isAssemble then
    else
        local presetChanged = changed[self.index]
        if presetChanged.AutoBackAfterClearExpedition ~= nil 
            or presetChanged.Autoback ~= nil 
            or presetChanged.BasicInfo 
        then
            self:SetupTipInfo()
        end
    end
    self:UpdateTroopStatus()
end


function HUDSelectTroopListItem:OnAssembleStartButtonClick(selectTime)
    local function __OnBtnGotoClicked()
        if self.listItemData.isAssemble and self.listItemData.joinAssembleTeamId then
            ModuleRefer.SlgModule:JoinAllianceTeam(self.listItemData.joinAssembleTeamId, self.index)
            g_Game.UIManager:CloseByName(UIMediatorNames.HUDSelectTroopList)
            return
        end
        if not selectTime or selectTime < 1 then
            return
        end
        local targetEntity = nil
        if self.listData.entity then
            targetEntity = self.listData.entity
        elseif self.listData.tile then
            targetEntity = self.listData.tile.entity
        end

        local waitTime = selectTime
        local troopIndex = self.index - 1

        ModuleRefer.SlgModule:CreateAllianceTeam(targetEntity,troopIndex,waitTime)
        g_Game.UIManager:CloseByName(UIMediatorNames.HUDSelectTroopList)
    end

    local function CanStartMarch(onSucces)
        HUDTroopUtils.DoestTroopInjuredHeroMeetStartMarchConditions(self.index, function()
            HUDTroopUtils.DoestTroopStateMeetStartMarchConditions(self.index, onSucces)
        end)
    end
    
    local isTrusteeship = ModuleRefer.SlgModule.troopManager:CheckTroopTrusteeshipState(self.troopData,self.index)
    if isTrusteeship == CheckTroopTrusteeshipStateDefine.State.None then
        CanStartMarch(__OnBtnGotoClicked)
    elseif CheckTroopTrusteeshipStateDefine.IsStateCanCancel(isTrusteeship) then
        ModuleRefer.SlgModule.troopManager:CancelTroopTrusteeshipAndGoOn(self.troopData,self.index,function(cancel)
            if cancel then
                ModuleRefer.SlgModule.selectManager:RefreshSelectedData()
                CanStartMarch(__OnBtnGotoClicked)
            end
        end,isTrusteeship == CheckTroopTrusteeshipStateDefine.State.InAssemblePreparing)
    else
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_check_hosting_stop_title"))
    end
end

return HUDSelectTroopListItem;
