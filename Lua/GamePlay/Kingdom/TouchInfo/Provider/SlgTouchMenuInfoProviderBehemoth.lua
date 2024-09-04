local DBEntityType = require("DBEntityType")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local UIHelper = require('UIHelper')
local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")
local UIMediatorNames = require('UIMediatorNames')
local ColorConsts = require("ColorConsts")
local KingdomMapUtils = require('KingdomMapUtils')
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local KingdomTouchInfoOperation = require("KingdomTouchInfoOperation")

local TouchMenuButtonTipsData = require('TouchMenuButtonTipsData')
local TouchMenuMainBtnDatum = require('TouchMenuMainBtnDatum')
local TMCellRewardSpecialPairDatum = require('TMCellRewardSpecialPairDatum')
local TMCellRewardPetDatum = require('TMCellRewardPetDatum')
local TMCellRewardPairDatum = require('TMCellRewardPairDatum')
local TouchMenuCellSkillDatum = require('TouchMenuCellSkillDatum')
local TouchMenuCellRewardPairListDatum = require('TouchMenuCellRewardPairListDatum')
local KingdomTouchInfoProviderVillage = require('KingdomTouchInfoProviderVillage')

local SlgTouchMenuInfoProviderBehemoth = class('SlgTouchMenuInfoProviderBehemoth')

---@class SlgTouchMenuInfoProviderBehemoth_ActivityData
---@field id number
---@field startTime google.protobuf.Timestamp
---@field endTime google.protobuf.Timestamp

---@param mobData wds.MapMob
function SlgTouchMenuInfoProviderBehemoth:ctor(mobData)
    self.mobData = mobData
    self.cageId = mobData.MobInfo.BehemothCageId
    ---@type wds.BehemothCage
    local cageEntity = g_Game.DatabaseManager:GetEntity(self.cageId,DBEntityType.BehemothCage)
    if not cageEntity then
        return
    end
    self.cageEntity = cageEntity
    self.CageBuildingCfg = ConfigRefer.FixedMapBuilding:Find(cageEntity.BehemothCage.ConfigId)
    self.cageCfg = ConfigRefer.BehemothCage:Find(self.CageBuildingCfg:BehemothCageConfig())
    ---@type SlgTouchMenuInfoProviderBehemoth_ActivityData[]
    self.activities = {}
    local length = self.cageCfg:AttackActivityLength()

    for i = 1, length do
        local activityID = self.cageCfg:AttackActivity(i)
        local startTime, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(activityID)
        self.activities[i] = {
            id = activityID,
            startTime = startTime,
            endTime = endTime,
        }
    end
    self:SetupMenuState()
end

function SlgTouchMenuInfoProviderBehemoth:GetSkillDatum()
    if not self.mobData or not self.mobData.Battle then
        return nil
    end
    local mainHero = self.mobData.Battle.Group.Heros[0]
    local heroCfg = ConfigRefer.Heroes:Find(mainHero.HeroID)
    local skillIds = {}
    local skillLength = heroCfg:SlgSkillDisplayLength()
    for i = 1, skillLength do
        local skillId = heroCfg:SlgSkillDisplay(i)
        local skillInfoCfg = ConfigRefer.SlgSkillInfo:Find(skillId)        
        if skillInfoCfg then
            table.insert(skillIds, skillInfoCfg:SkillId())
        end
    end
    if skillLength < 1 then
        g_Logger.Error("SlgTouchMenuInfoProviderBehemoth:GetSkillDatum() 巨兽没有配置技能 巨兽KMonsterId:" .. self.mobData.MobInfo.MobID .." 英雄ID:" .. mainHero.HeroID)
    end
    local skillDatum = TouchMenuCellSkillDatum.new(
        I18N.Get("alliance_behemoth_skill_title"),UIHelper.TryParseHtmlString(ColorConsts.army_red)
        ,skillIds,function()
            ---@type UISkillDetailPopupParam
            local parameter = {}
            parameter.title = I18N.Get("alliance_behemoth_skill_title")
            parameter.skillTitle = I18N.Get("alliance_behemoth_title_tips_skill")
            parameter.skillIds = skillIds            
            g_Game.UIManager:Open(UIMediatorNames.UISkillDetailPopupMediator, parameter)
    end)
    return skillDatum
end


function SlgTouchMenuInfoProviderBehemoth:GetRewardDatum()
    local fixedMapBuildingConfig =  self.CageBuildingCfg --ConfigRefer.FixedMapBuilding:Find(self.cageEntity.MapBasics.ConfID)
    local pairBenefits = {}
    
    local allianceAttr = ConfigRefer.AttrGroup:Find(fixedMapBuildingConfig:AllianceAttrGroup())
    if allianceAttr then
        if allianceAttr and allianceAttr:AttrListLength() > 0 then
            ---@type {prefabIdx:number, cellData:{strLeft:string,strRight:string,icon:string}}[]
            local allianceGainAttr = {}
            for i = 1,  allianceAttr:AttrListLength() do
                local attrTypeAndValue = allianceAttr:AttrList(i)
                ModuleRefer.VillageModule.ParseAttrInfo(attrTypeAndValue, allianceGainAttr, true)
                local v= allianceGainAttr[1]
                allianceGainAttr[1] = nil
                table.insert(pairBenefits, TMCellRewardSpecialPairDatum.new(v.cellData.strLeft, v.cellData.strRight, v.cellData.icon))
            end
        end
    end
    
    if fixedMapBuildingConfig:VillageShowExtraPetItemLength() > 0 then
        local petConfigIds = {}
        ---@type TMCellRewardPetDatum
        local cellData = TMCellRewardPetDatum.new(I18N.Get("village_newpet_after_occupied"), petConfigIds)
        for i = 1, fixedMapBuildingConfig:VillageShowExtraPetItemLength() do
            table.insert(petConfigIds, fixedMapBuildingConfig:VillageShowExtraPetItem(i))
        end
        table.insert(pairBenefits, cellData)
    end
    
    local currencyConfig = ConfigRefer.AllianceCurrency:Find(fixedMapBuildingConfig:OccupyAllianceCurrencyType())
    if currencyConfig then
        local pairBenefitComp = TMCellRewardPairDatum.new(I18N.Get(currencyConfig:Name()), ("+%s"):format(fixedMapBuildingConfig:OccupyAllianceCurrencyNum()), currencyConfig:Icon())
        table.insert(pairBenefits, pairBenefitComp)
    end
    
    if fixedMapBuildingConfig:FactionValue() > 0 then
        table.insert(pairBenefits, TMCellRewardPairDatum.new(I18N.Get("village_info_Alliance_forces"), ("+%s"):format(fixedMapBuildingConfig:FactionValue()), "sp_comp_icon_achievement_1"))
    end
    
    local attr = self.cageEntity.BehemothCage.RandomAllianceAttrGroup
    ---@type {cellData:{strLeft:string,strRight:string,icon:string}}[]
    local addToTable = {}
    for _, v in ipairs(attr) do
        local attrGroup = ConfigRefer.AttrGroup:Find(v)
        if attrGroup then
            for i = 1,  attrGroup:AttrListLength() do
                ModuleRefer.VillageModule.ParseAttrInfo(attrGroup:AttrList(i), addToTable, true)
            end
        end
    end
    for _, v in ipairs(addToTable) do
        local pairBenefitComp = TMCellRewardPairDatum.new(v.cellData.strLeft, v.cellData.strRight, v.cellData.icon)
        table.insert(pairBenefits, pairBenefitComp)
    end

    local rewardPairListDatum = TouchMenuCellRewardPairListDatum.new(I18N.Get("village_info_Occupy_gains"), pairBenefits, function()        
        ---@type AllianceVillageOccupationGainMediatorParameter
        local parameter = {}
        parameter.village = self.cageEntity
        parameter.fixedMapCfgId = self.cageEntity.BehemothCage.ConfigId
        parameter.randomAllianceAttrGroup = self.cageEntity.BehemothCage.RandomAllianceAttrGroup
        g_Game.UIManager:Open(UIMediatorNames.AllianceBehemothCageRewardPopupMediator, parameter)
        
    end)

    return rewardPairListDatum
end

function SlgTouchMenuInfoProviderBehemoth:GetOccupiedDatum()
    return KingdomTouchInfoProviderVillage.GetOccupyInfoPart(self.cageEntity)    
end

---@class SlgTouchMenuInfoProviderBehemoth.ButtonFlags
SlgTouchMenuInfoProviderBehemoth.ButtonFlags = {
    none = 0,
    buttonDeclareWarDisabled = 1 << 1,
    buttonDeclareWarEnabled = 1 << 2,
    buttonCancelDeclare = 1 << 3,
    buttonAttack = 1 << 4,
    buttonManagedAttack = 1 << 5,
    buttonGotoList = 1 << 6,
    buttonScout = 1 << 7
}

---@param cage wds.BehemothCage
---@return SlgTouchMenuInfoProviderBehemoth.ButtonFlags number[FLAGS]
function SlgTouchMenuInfoProviderBehemoth.GetMenuStateFlags(cage)
    local btnFlags = SlgTouchMenuInfoProviderBehemoth.ButtonFlags
    ---@type SlgTouchMenuInfoProviderBehemoth.ButtonFlags
    local ret = SlgTouchMenuInfoProviderBehemoth.ButtonFlags.none

    local needScout = ModuleRefer.RadarModule:GetScout(cage)
    if needScout then
        ret = ret | btnFlags.buttonScout
        return ret
    end

    local can,_ =  ModuleRefer.VillageModule:GetCanSignAttackCageToast(cage)
    local sasDeclareWarOnCage, warInfo = ModuleRefer.VillageModule:HasDeclareWarOnCage(cage.ID)
    
    if ModuleRefer.PlayerModule:IsFriendly(cage.Owner) then
        -- ret = ret | btnFlags.buttonGotoList --0.9.0不能放置巨兽装置
    elseif sasDeclareWarOnCage then
        if warInfo.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
            ret = ret | btnFlags.buttonCancelDeclare
            -- ret = ret | btnFlags.buttonManagedAttack
        end
        if (cage.BehemothCage.Status & wds.BehemothCageStatusMask.BehemothCageStatusMaskInWaiting) ~= 0 then
            ret = ret | btnFlags.buttonAttack
        end
    else
        if (not can) then
            ret = ret | btnFlags.buttonDeclareWarDisabled
        else
            ret = ret | btnFlags.buttonDeclareWarEnabled
        end
    end
    return ret
end

function SlgTouchMenuInfoProviderBehemoth:SetupMenuState()
    self.buttonState = SlgTouchMenuInfoProviderBehemoth.GetMenuStateFlags(self.cageEntity)
end

---@return TouchMenuButtonTipsData
function SlgTouchMenuInfoProviderBehemoth.GetButtonTipByEntity(cage)
    local allianceID = ModuleRefer.AllianceModule:GetAllianceId()
    local _,oriTimestamp,_ = ModuleRefer.VillageModule:GetBehemothCountDown(cage, allianceID)
    if oriTimestamp and oriTimestamp > 0 then
        local tipFunc = function()
            ---@type wds.BehemothCage
            local cageEntity = cage
            local textKey,timestamp,tipColor = ModuleRefer.VillageModule:GetBehemothCountDown(cageEntity, allianceID)
            local tip = string.Empty
            local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
            local remainTime = timestamp - serverTime
            if remainTime >= 0 then
                local timeStr = TimeFormatter.SimpleFormatTimeWithDay(remainTime)
                tip = I18N.GetWithParams(textKey, timeStr)
                if not string.IsNullOrEmpty(tipColor) then
                    tip = UIHelper.GetColoredText(tip, tipColor)
                end
            end
            return tip
        end
        return TouchMenuButtonTipsData.new():SetContent(tipFunc)
    elseif not ModuleRefer.PlayerModule:IsFriendly(cage.Owner) then
        local can,tip = ModuleRefer.VillageModule:GetCanSignAttackCageToast(cage)
        if can then
            return nil
        end
        return TouchMenuButtonTipsData.new():SetContent(tip)
    end
    return nil
end

---@return TouchMenuButtonTipsData
function SlgTouchMenuInfoProviderBehemoth:GetButtonTip()
    return SlgTouchMenuInfoProviderBehemoth.GetButtonTipByEntity(self.cageEntity)
end

function SlgTouchMenuInfoProviderBehemoth.DeclareWar(cageEntity)
    ModuleRefer.VillageModule:StartSignAttackBehemothCage(cageEntity, true)
end

---@param cageEntity wds.BehemothCage
function SlgTouchMenuInfoProviderBehemoth.CancelDeclare(cageEntity)
    local villageName = ModuleRefer.MapBuildingTroopModule:GetBuildingName(cageEntity)
    local pos = cageEntity.MapBasics.BuildingPos
    local content = I18N.GetWithParams("alliance_behemoth_pop_CancelDeclare", villageName, KingdomMapUtils.CoordToXYString(pos.X, pos.Y))
    UIHelper.ShowConfirm(content, nil, function()
        if not ModuleRefer.VillageModule:CheckCanCancelDeclareOnBehemothCage(cageEntity, true) then
            return
        end
        ModuleRefer.VillageModule:DoCancelDeclareWarOnVillage(nil, cageEntity.ID)
        ModuleRefer.KingdomTouchInfoModule:Hide()
    end)
end

---@param mobData wds.MapMob
function SlgTouchMenuInfoProviderBehemoth.Attack(mobData)
    local __, needPower,recommendPower,costPPP = KingdomMapUtils.CalcRecommendPower(mobData)
    ---@type HUDSelectTroopListData
    local param = {}
    param.entity = mobData
    param.showBack = true
    param.isSE = false
    param.needPower=needPower
    param.recommendPower=recommendPower
    param.costPPP = costPPP
    param.purpose = wrpc.MovePurpose.MovePurpose_Move
    local x,y = math.floor(mobData.MapBasics.Position.X + 0.5),math.floor(mobData.MapBasics.Position.Y + 0.5)
    param.moveToPos = CS.DragonReborn.Vector2Short(x, y)
    require("HUDTroopUtils").StartMarch(param)
end

---@param entity table
function SlgTouchMenuInfoProviderBehemoth.ManagedAttack(entity)
    KingdomTouchInfoOperation.SendTroopToEntityQuickly(entity, true, true, nil, {[wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Durability]=true})
end

---@param cageEntity wds.BehemothCage
function SlgTouchMenuInfoProviderBehemoth.GotoList(cageEntity)
    ---@type AllianceBehemothListMediatorParameter
    local param = {}
    param.chooseEntityId = cageEntity.ID
    g_Game.UIManager:Open(UIMediatorNames.AllianceBehemothListMediator, param)
end

---@param cageEntity wds.BehemothCage
function SlgTouchMenuInfoProviderBehemoth.Scout(cageEntity)
    ModuleRefer.RadarModule:ScoutDialogue(cageEntity)
end

---@return TouchMenuMainBtnDatum[]
function SlgTouchMenuInfoProviderBehemoth:GetButtonDatum()

    local buttons = {}
    local btnFlags = SlgTouchMenuInfoProviderBehemoth.ButtonFlags
    local flags = self.buttonState
    
    if (flags & btnFlags.buttonCancelDeclare) ~= 0 then
        local buttonCancelDeclare = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Cancel_declara"), SlgTouchMenuInfoProviderBehemoth.CancelDeclare, self.cageEntity)
        table.insert(buttons, buttonCancelDeclare)
    end  
    if (flags & btnFlags.buttonAttack) ~= 0 then
        local buttonAttack = TouchMenuMainBtnDatum.new(I18N.Get("circlemenu_setoff"),SlgTouchMenuInfoProviderBehemoth.Attack,self.mobData)
        table.insert(buttons, buttonAttack)
    end
    if (flags & btnFlags.buttonManagedAttack) ~= 0 then
        local buttonManagedAttack = TouchMenuMainBtnDatum.new(I18N.Get("alliance_behemoth_button_AutomatGOTO"),SlgTouchMenuInfoProviderBehemoth.ManagedAttack,self.cageEntity)
        table.insert(buttons, buttonManagedAttack)
    end
    if (flags & btnFlags.buttonDeclareWarDisabled) ~= 0 then
        local buttonDeclareWarDisabled = TouchMenuMainBtnDatum.new(
            I18N.Get("village_btn_Declare_war"), 
            SlgTouchMenuInfoProviderBehemoth.DeclareWar, self.cageEntity
        ):SetEnable(false):SetOnClickDisable(function() 
            local _,tip = ModuleRefer.VillageModule:GetCanSignAttackCageToast(self.cageEntity)
            ModuleRefer.ToastModule:AddSimpleToast(tip)
        end)
        table.insert(buttons, buttonDeclareWarDisabled)
    end
    if (flags & btnFlags.buttonDeclareWarEnabled) ~= 0 then
        local buttonDeclareWarEnabled = TouchMenuMainBtnDatum.new(I18N.Get("village_btn_Declare_war"), SlgTouchMenuInfoProviderBehemoth.DeclareWar, self.cageEntity)
        table.insert(buttons, buttonDeclareWarEnabled)
    end
    if (flags & btnFlags.buttonGotoList) ~= 0 then
        local buttonGotoList = TouchMenuMainBtnDatum.new(I18N.Get("alliance_behemoth_button_look"), SlgTouchMenuInfoProviderBehemoth.GotoList, self.cageEntity)
        table.insert(buttons, buttonGotoList)
    end
    if (flags & btnFlags.buttonScout) ~= 0 then
        local btn = TouchMenuMainBtnDatum.new(I18N.Get("bw_radar_invest_btn"), SlgTouchMenuInfoProviderBehemoth.Scout, self.cageEntity)
        table.insert(buttons, btn)
    end
    return buttons
end

---@param mainWindowInfo TouchMenuBasicInfoDatum
function SlgTouchMenuInfoProviderBehemoth:AppendOperationOnBasicInfo(mainWindowInfo)
    local entityId = self.cageEntity.ID
    if ModuleRefer.AllianceModule:IsInAlliance() then
        if ModuleRefer.PlayerModule:IsFriendly(self.cageEntity.Owner) 
                and ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.BindBehemoth) 
                and ModuleRefer.AllianceModule.Behemoth:GetBehemothByBuildingEntityId(entityId)
        then
            mainWindowInfo:SetClickBtnRelease(function(btnTrans)
                local currentBehemoth =  ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth()
                if currentBehemoth and currentBehemoth:GetBuildingEntityId() == entityId then
                    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemoth_tips_Release"))
                    return false
                end
                ---@type CommonConfirmPopupMediatorParameter
                local confirmParameter = {}
                confirmParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
                confirmParameter.confirmLabel = I18N.Get("confirm")
                confirmParameter.cancelLabel = I18N.Get("cancle")
                confirmParameter.content = I18N.GetWithParams("alliance_behemoth_pop_Release", I18N.Get(self.CageBuildingCfg:Name()))
                confirmParameter.onConfirm = function() 
                    ModuleRefer.VillageModule:DoDropVillage(btnTrans, entityId, function(cmd, isSuccess, rsp) 
                        g_Game.UIManager:CloseAllByName(UIMediatorNames.TouchMenuUIMediator)
                    end)
                    return true
                end
                g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmParameter)
                return false
            end)
        end
    end
end

return SlgTouchMenuInfoProviderBehemoth