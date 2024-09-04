local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local TouchMenuBasicInfoDatum = require('TouchMenuBasicInfoDatum')
local TouchMenuCellSeMonsterDatum = require('TouchMenuCellSeMonsterDatum')
local TMCellSeMonsterDatum = require('TMCellSeMonsterDatum')
local TouchMenuCellRewardDatum = require('TouchMenuCellRewardDatum')
local TouchMenuButtonTipsData = require('TouchMenuButtonTipsData')
local TouchMenuMainBtnDatum = require('TouchMenuMainBtnDatum')
local MonsterBattleType = require('MonsterBattleType')
local SlgTouchMenuHelper = require('SlgTouchMenuHelper')
local KingdomMapUtils = require('KingdomMapUtils')
local NumberFormatter = require('NumberFormatter')
local UIMediatorNames = require('UIMediatorNames')
local MonsterClassType = require('MonsterClassType')
local SearchEntityType = require('SearchEntityType')
local UIHelper = require('UIHelper')
local SlgBattlePowerHelper = require("SlgBattlePowerHelper")
local DBEntityType = require('DBEntityType')
local TouchMenuBasicInfoDatumMarkProvider = require("TouchMenuBasicInfoDatumMarkProvider")

---@class SlgTouchMenuInfoProviderMonster:TouchMenuBasicInfoDatumMarkProvider
---@field new fun():SlgTouchMenuInfoProviderMonster
---@field super TouchMenuBasicInfoDatumMarkProvider
local SlgTouchMenuInfoProviderMonster = class('SlgTouchMenuInfoProviderMonster', TouchMenuBasicInfoDatumMarkProvider)

---@param mobData wds.MapMob
function SlgTouchMenuInfoProviderMonster:Setup(mobData)
    self.mobData = mobData
    self.mobConfig = ConfigRefer.KmonsterData:Find(mobData.MobInfo.MobID)
    local name,image,level,heroesIcons, halfPaint = SlgTouchMenuHelper.GetMobNameImageLevelHeadIcons(mobData)
    self.name = name
    self.image = image
    self.level = level
    self.heroicons = heroesIcons
    self.halfPaint = halfPaint
    self.creepBuff,self.creepBuffIcon,self.creepBuffValueStr = ModuleRefer.MapCreepModule:GetMonsterLinkTumorCreepBuffCount(mobData.ID)

    if UNITY_DEBUG or UNITY_EDITOR then
        self.name = self.name .. "(" .. mobData.ID .. ")"
    end
end
--- 主界面
---@return TouchMenuBasicInfoDatum
function SlgTouchMenuInfoProviderMonster:GetMainWindowDatum()
    local coord = KingdomMapUtils.CoordToXYString(
        math.floor(self.mobData.MapBasics.Position.X),
        math.floor(self.mobData.MapBasics.Position.Y)
    )
    local datum = TouchMenuBasicInfoDatum.new(self.name, self.image, coord, self.level):SetBack(false) 
    datum:SetTypeAndConfig(
        require("ChatShareUtils").TypeTrans(require("DBEntityType").MapMob),
        self.mobData.MobInfo.MobID
    )
    return datum
end

--- 怪物列表
---@return TouchMenuCellSeMonsterDatum
function SlgTouchMenuInfoProviderMonster:GetMonsterDatum()
    if #self.heroicons < 1 then return end
    local monsterDatum = TouchMenuCellSeMonsterDatum.new()
    monsterDatum:SetTitle(I18N.Get("setips_title_monster"))
    monsterDatum:SetCreepBufferCount(self.creepBuffIcon, self.creepBuff, function(clickTrans, datum)
        if datum.creepBuff then
            local content = I18N.GetWithParams("duzhu_qianghua", tostring(datum.creepBuff)) .. self.creepBuffValueStr
            ModuleRefer.ToastModule:SimpleShowTextToastTip(content, clickTrans)
        end
    end)
    for i = 1, #self.heroicons do
        if self.heroicons[i] then
            local monsterData = TMCellSeMonsterDatum.new()
            monsterData:SetIconId(self.heroicons[i].heroIcon)
            monsterDatum:AppendMonsterDatum(monsterData)
        end
    end
    return monsterDatum
end

-- 可能奖励列表
---@return TouchMenuCellRewardDatum
function SlgTouchMenuInfoProviderMonster:GetAdditionalRewardDatum()
    local dropId = self.mobConfig:DropShow()
    local rewardGroup = ConfigRefer.ItemGroup:Find(dropId)
    if (not rewardGroup) then
        return nil
    end

    local additionRewardLength = rewardGroup:AdditionRuleLength()
    if (additionRewardLength <= 0) then
        return nil
    end

    local count = 0
    local rewardDatum = TouchMenuCellRewardDatum.new()
    rewardDatum:SetTitle(I18N.Get("searchentity_info_possible_reward"))
    for k = 1, additionRewardLength do
        local additionReward = rewardGroup:AdditionRule(k)
        local additionRewardCfg = ConfigRefer.ItemGroupAdditionReward:Find(additionReward)
        --活动开始后可能获得的物品
        for i = 1, additionRewardCfg:RewardsLength() do
            local rewardInfo = additionRewardCfg:Rewards(i)
            local activityId = rewardInfo:RelatedActivity()
            for j = 1, rewardInfo:AdditionRewardLength() do
                local additionRewardId = rewardInfo:AdditionReward(j)
                local isOpen = ModuleRefer.ActivityCenterModule:IsActivityTemplateOpen(activityId)
                if isOpen then
                    local itemGroup = ConfigRefer.ItemGroup:Find(additionRewardId)
                    if itemGroup then
                        for m = 1, itemGroup:ItemGroupInfoListLength() do
                            local itemInfo = itemGroup:ItemGroupInfoList(m)
                            local itemCfg = ConfigRefer.Item:Find(itemInfo:Items())
                            if (itemCfg) then
                                local rewardData = {
                                    configCell = itemCfg,
                                    showTips = true,
                                    showCount = false,
                                    useNoneMask = false,
                                }
                                count = count + 1
                                rewardDatum:AppendItemIconData(rewardData)
                            end
                        end
                    end
                end
            end
        end
    end

    if count == 0 then
        return nil
    end
    return rewardDatum
end

-- 奖励列表
---@return TouchMenuCellRewardDatum
function SlgTouchMenuInfoProviderMonster:GetRewardDatum()
    local itemInfos = ModuleRefer.WorldSearchModule:GetMonsterDropItems(self.mobConfig)
    if itemInfos then
        local rewardDatum = TouchMenuCellRewardDatum.new()
        rewardDatum:SetTitle(I18N.Get("alliance_activity_pet_11"))


        local dropId = self.mobConfig:DropShow()
    local rewardGroup = ConfigRefer.ItemGroup:Find(dropId)
    if (not rewardGroup) then
        return nil
    end

    local additionRewardLength = rewardGroup:AdditionRuleLength()
    if (additionRewardLength <= 0) then
        return nil
    end

    for _, item in ipairs(itemInfos) do
            local itemConfig = ConfigRefer.Item:Find(item:Items())
            local rewardData = {
                configCell = itemConfig,
                showTips = true,
                showCount = false,
                useNoneMask = false,
            }
            rewardDatum:AppendItemIconData(rewardData)
        end
        return rewardDatum
    end
end

-- 奖励列表
---@param level number
---@return TouchMenuCellRewardDatum
function SlgTouchMenuInfoProviderMonster:GetFirstKillRewardDatum(level)
    local itemGroups = ModuleRefer.WorldSearchModule:GetMonsterFirstKillDropItems(level)
    if itemGroups then
        local rewardDatum = TouchMenuCellRewardDatum.new()
        rewardDatum:SetTitle(I18N.Get("searchentity_info_firstkill_reward"))
        for _, item in ipairs(itemGroups) do
            local itemConfig = ConfigRefer.Item:Find(item:Items())
            local rewardData = {
                configCell = itemConfig,
                showTips = true,
                showCount = false,
                useNoneMask = false,
            }
            rewardDatum:AppendItemIconData(rewardData)
        end
        return rewardDatum
    end
end

function SlgTouchMenuInfoProviderMonster:GetAttackableButtonTip()
    local _, needPower, recommendPower, _ = KingdomMapUtils.CalcRecommendPower(self.mobData)
    local buttonTip = nil
    if recommendPower > 0 then
        buttonTip = TouchMenuButtonTipsData.new()

        local showIcon = self.mobConfig:MonsterClass() == MonsterClassType.Normal
        if showIcon then
            local power = ModuleRefer.TroopModule:GetMaxTroopPower()
            local compareResult = SlgBattlePowerHelper.ComparePower(power, needPower, recommendPower)
            local icon = SlgBattlePowerHelper.GetPowerCompareIcon(compareResult)
            buttonTip:SetIcon(icon)
        end

        local str = I18N.GetWithParams("world_tjbl", NumberFormatter.Normal(recommendPower))
        buttonTip:SetContent(UIHelper.GetColoredText(str,'#000000'))
    end
    return buttonTip
end

---@return TouchMenuMainBtnDatum[]
function SlgTouchMenuInfoProviderMonster:GetAttackableButtonDatum()
    
    if KingdomMapUtils.IsNewbieState() then
        return {}
    end
    local battleType = require('SlgUtils').GetMonsterBattleType(self.mobData)
    if battleType == MonsterBattleType.Normal then

        local levelInfo = self.mobData.LevelEntityInfo
        local levelId = levelInfo ~= nil and levelInfo.LevelEntityId or 0 
        ---@type wds.Expedition
        local expEntity = (levelId ~= 0) and g_Game.DatabaseManager:GetEntity(levelId,DBEntityType.Expedition) or nil
        local expConfig = expEntity and ConfigRefer.WorldExpeditionTemplate:Find(expEntity.ExpeditionInfo.Tid) or nil
        if expConfig and expConfig:ProgressType() == require('ProgressType').Personal then
            return self:GetAutoFinishAttackableButtonDatum()
        else
            return self:GetNormalAttackableButtonDatum()
        end        
    else
        return self:GetAssambleAttackableButtonDatum()
    end
end



---private
---@return TouchMenuMainBtnDatum[]
function SlgTouchMenuInfoProviderMonster:GetNormalAttackableButtonDatum()   
    local onClick = function(mobData,trans)
        local __, needPower,recommendPower,costPPP = KingdomMapUtils.CalcRecommendPower(mobData)
        ---@type HUDSelectTroopListData
        local param = {}
        param.entity = mobData
        param.showBack = true
        param.isSE = false
        param.needPower=needPower
        param.recommendPower=recommendPower
        param.costPPP = costPPP
        require("HUDTroopUtils").StartMarch(param)
    end
    local btn = TouchMenuMainBtnDatum.new(I18N.Get("circlemenu_setoff"),onClick,self.mobData)    
    return {[1] = btn}
end

---private
---@return TouchMenuMainBtnDatum[]
function SlgTouchMenuInfoProviderMonster:GetAssambleAttackableButtonDatum()
    local btn = TouchMenuMainBtnDatum.new()
    local buttonEnable
    local itemId, itemCost, itemHas = ModuleRefer.SlgModule:GetSlgTeamTrusteeshipItemCostInfo(self.mobData.MobInfo.MobID)
    local costPPP, currPPP = ModuleRefer.SlgModule:GetSlgTeamTrusteeshipStaminaCostInfo(self.mobData.MobInfo.MobID)

    if itemId > 0 and itemCost > 0 then
        buttonEnable = ModuleRefer.AllianceModule:IsInAlliance() and itemHas >= itemCost
        local costItemCfg = ConfigRefer.Item:Find(itemId)
        btn.extraImage = costItemCfg and costItemCfg:Icon() or "sp_icon_item_rolin_lv2"
        btn.extraLabel = tostring(itemHas) .. '/' .. tostring(itemCost)
        btn.extraLabelColor = (itemHas >= itemCost) and CS.UnityEngine.Color.white or CS.UnityEngine.Color.red
    else
        buttonEnable = ModuleRefer.AllianceModule:IsInAlliance() and currPPP >= costPPP
        btn.extraImage = "sp_comp_icon_shape"
        btn.extraLabel = tostring(currPPP) .. '/' .. tostring(costPPP)
        btn.extraLabelColor = (currPPP >= costPPP) and CS.UnityEngine.Color.white or CS.UnityEngine.Color.red
    end

    --Assemble Button            
    btn.label = I18N.Get("alliance_team")
    btn.enable = buttonEnable
    
    local mobData = self.mobData
    local onClick = function()
        local __, needPower,recommendPower,costPPP = KingdomMapUtils.CalcRecommendPower(mobData)
        ---@type HUDSelectTroopListData
        local selectTroopData = {}
        selectTroopData.entity = mobData        
        selectTroopData.isSE = false
        selectTroopData.needPower = needPower
        selectTroopData.recommendPower = recommendPower
        selectTroopData.costPPP = costPPP
        selectTroopData.isAssemble = true
        selectTroopData.trusteeshipRule = ModuleRefer.SlgModule:GetTrusteeshipRule(self.mobData.MobInfo.MobID)
        require("HUDTroopUtils").StartMarch(selectTroopData)
    end
    btn.onClick = onClick
    btn.onClickDisable = function()
        if not ModuleRefer.AllianceModule:IsInAlliance() then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('alliance_team_toast02'))
            return
        end

        if itemId > 0 and itemCost > 0 then
            if itemHas < itemCost then
                local getmoreList = {}
                table.insert(getmoreList, {id = itemId, num = itemCost - itemHas})
                ModuleRefer.InventoryModule:OpenExchangePanel(getmoreList)
            end
        else
            if currPPP < costPPP  then
                local provider = require("EnergyGetMoreDataProvider").new()
                provider:SetItemList({ConfigRefer.ConstMain:AddenergyItemId()})
                g_Game.UIManager:Open(UIMediatorNames.UseResourceMediator, provider)
            end
        end
    end
    return {[1] = btn}
end



---private
---@return TouchMenuMainBtnDatum[]
function SlgTouchMenuInfoProviderMonster:GetAutoFinishAttackableButtonDatum()   
    local onNormalAttClick = function(mobData,trans)
        local __, needPower,recommendPower,costPPP = KingdomMapUtils.CalcRecommendPower(mobData)
        ---@type HUDSelectTroopListData
        local param = {}
        param.entity = mobData
        param.showBack = true
        param.isSE = false
        param.needPower=needPower
        param.recommendPower=recommendPower
        param.costPPP = costPPP
        require("HUDTroopUtils").StartMarch(param)
    end
    local normalAttBtn = TouchMenuMainBtnDatum.new(I18N.Get("circlemenu_setoff"),onNormalAttClick,self.mobData)    

    local onAutoFinishClick = function(mobData,trans)
        local __, needPower,recommendPower,costPPP = KingdomMapUtils.CalcRecommendPower(mobData)
        ---@type HUDSelectTroopListData
        local param = {}
        param.entity = mobData
        param.showBack = false
        param.showAutoFinish = true
        param.isSE = false
        param.needPower=needPower
        param.recommendPower=recommendPower
        param.costPPP = costPPP
        param.purpose = wrpc.MovePurpose.MovePurpose_AutoClearExpedition
        require("HUDTroopUtils").StartMarch(param)
    end
   
    local autoFinishBtn = TouchMenuMainBtnDatum.new(I18N.Get("circlemenu_autofinish"),onAutoFinishClick,self.mobData)    
        
    return {
        [1] = normalAttBtn,
        [2] = autoFinishBtn
    }
end

function SlgTouchMenuInfoProviderMonster:SetupSearch(attackLv)
    self.attackLv = attackLv
    self.monsterClass = self.mobConfig:MonsterClass()
    if self.monsterClass == MonsterClassType.Normal or
            self.monsterClass == MonsterClassType.Elite or
            self.monsterClass == MonsterClassType.TeamElite then    
        self.searchType = SearchEntityType.NormalMob
    end
end

function SlgTouchMenuInfoProviderMonster:GetSearchButtonTip()
    local buttonTip = TouchMenuButtonTipsData.new()   
    local str= ""
    if self.monsterClass == MonsterClassType.Normal or 
            self.monsterClass == MonsterClassType.Elite or
            self.monsterClass == MonsterClassType.TeamElite then
        str = I18N.GetWithParams("searchentity_toast_lowlv_1", self.attackLv)        
    end
    buttonTip:SetContent(str)
    return buttonTip
end

function SlgTouchMenuInfoProviderMonster:GetWorldEventMonsterButtonTip()
    local buttonTip = TouchMenuButtonTipsData.new()
    local str= I18N.Get("alliance_activity_pet_22")
    buttonTip:SetContent(str)
    return buttonTip
end

---@return TouchMenuMainBtnDatum[]
function SlgTouchMenuInfoProviderMonster:GetSearchButtonDatum()
    local btn = TouchMenuMainBtnDatum.new()
    btn.label = I18N.Get("searchentity_btn_search")
    local searchType = self.searchType
    local attackLv = self.attackLv
    local onClick = function()
        g_Game.UIManager:Open(UIMediatorNames.UIWorldSearchMediator, {selectType = searchType, searchLv = attackLv})
    end
    btn.onClick = onClick
    
    return {[1] = btn}
end

---@return TouchMenuMainBtnDatum[]
function SlgTouchMenuInfoProviderMonster:GetWorldEventCannotAttackButtonDatum()
    local btn = TouchMenuMainBtnDatum.new()
    btn.label = I18N.Get("alliance_team")
    btn:SetEnable(false)
    return {[1] = btn}
end
return SlgTouchMenuInfoProviderMonster
