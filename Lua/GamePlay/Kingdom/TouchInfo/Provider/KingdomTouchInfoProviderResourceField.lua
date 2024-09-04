local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local Delegate = require("Delegate")
local KingdomTouchInfoProvider = require("KingdomTouchInfoProvider")
local KingdomTouchInfoCompHelper = require("KingdomTouchInfoCompHelper")
local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")
local KingdomTouchInfoOperation = require("KingdomTouchInfoOperation")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local TouchMenuHelper = require("TouchMenuHelper")
local DBEntityPath = require("DBEntityPath")
local ColorConsts = require("ColorConsts")
local UIHelper = require("UIHelper")
local UIMediatorNames = require("UIMediatorNames")

local TouchMenuCellPairDatum = require("TouchMenuCellPairDatum")
local TouchMenuCellLeagueDatum = require("TouchMenuCellLeagueDatum")
local TouchMenuCellProgressDatum = require("TouchMenuCellProgressDatum")
local TouchMenuButtonTipsData = require("TouchMenuButtonTipsData")
local TouchMenuCellRewardDatum = require("TouchMenuCellRewardDatum")
local TMCellRewardItemIconData = require("TMCellRewardItemIconData")
local TouchMenuCellPairTimeDatum = require("TouchMenuCellPairTimeDatum")


---@class KingdomTouchInfoProviderResourceField : KingdomTouchInfoProvider
local KingdomTouchInfoProviderResourceField = class("KingdomTouchInfoProviderResourceField", KingdomTouchInfoProvider)

function KingdomTouchInfoProviderResourceField:CreateBasicInfo(tile)
    local ret = KingdomTouchInfoCompHelper.GenerateBasicData(tile)
    ret:SetBack(ModuleRefer.PlayerModule:IsFriendly(tile.entity.Owner))
    return ret
end

function KingdomTouchInfoProviderResourceField:CreateDetailInfo(tile)
    ---@type wds.ResourceField
    local entity = tile.entity
    local resourceCfg = ConfigRefer.FixedMapBuilding:Find(entity.FieldInfo.ConfID)
    local outputItem = ConfigRefer.Item:Find(resourceCfg:OutputResourceItem())
    local ret = {}

    --联盟信息
    if entity.FieldInfo and entity.FieldInfo.AllianceId and entity.FieldInfo.AllianceId > 0 then
        local fieldInfo = entity.FieldInfo
        local myAllianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
        local allianceLabel = ModuleRefer.PlayerModule.FullName(fieldInfo.AllianceAbbr, fieldInfo.AllianceName)
        local allianceColor = myAllianceData and myAllianceData.ID == fieldInfo.AllianceID and ColorConsts.army_blue or ColorConsts.army_red
        allianceColor = UIHelper.TryParseHtmlString(allianceColor)
        local onClick = function()
            g_Game.UIManager:Open(UIMediatorNames.AllianceInfoPopupMediator, {allianceId = fieldInfo.AllianceId, tab = 1})
        end
        local allianceCellData = TouchMenuCellLeagueDatum.new(allianceLabel, allianceColor, fieldInfo.AllianceBadgeAppearance, fieldInfo.AllianceBadgePattern, onClick)
        table.insert(ret, allianceCellData)
    end

    --储量
    local ratioFunc = function()
        local remainResource = ModuleRefer.MapResourceFieldModule:GetRemainResourceAmount(entity)
        local totalResource = ModuleRefer.MapResourceFieldModule:GetTotalResourceAmount(entity)
        return remainResource / totalResource
    end
    local ratioTipFunc = function()
        local remainResource = ModuleRefer.MapResourceFieldModule:GetRemainResourceAmount(entity)
        local totalResource = ModuleRefer.MapResourceFieldModule:GetTotalResourceAmount(entity)
        return ("%s/%s"):format(remainResource, totalResource)
    end
    local icon = outputItem and outputItem:Icon() or string.Empty
    local title = I18N.Get("mining_info_reserves")
    local progressCollecting = TouchMenuCellProgressDatum.new(icon, title, ratioFunc,
nil, nil,true, ratioTipFunc
    )
    table.insert(ret, progressCollecting)

    --采集者相关信息
    if entity.Owner and entity.Owner.PlayerID > 0 then
        local owner = entity.Owner

        if ModuleRefer.PlayerModule:IsMine(owner) then
            local timerLabel = I18N.Get("mining_info_collection_time")
            local endTime = ModuleRefer.MapResourceFieldModule:GetCollectEndTime(entity)
            local timerData = TouchMenuHelper.GetSecondTickCommonTimerData(endTime)
            local remainTimePair = TouchMenuCellPairTimeDatum.new(timerLabel, timerData)
            table.insert(ret, remainTimePair)
        end

        local leftLabel = I18N.Get("mining_info_collection_collector")
        local rightLabel = ModuleRefer.PlayerModule.FullName(owner.AllianceAbbr.String, owner.PlayerName.String)
        local rightColor = ModuleRefer.MapHUDModule:GetColor(owner, true)
        local colorStr = CS.UnityEngine.ColorUtility.ToHtmlStringRGBA(rightColor)
        rightLabel = ("<color=#%s>%s</color>"):format(colorStr, rightLabel)
        local outputPair = TouchMenuCellPairDatum.new(leftLabel, rightLabel)
        table.insert(ret, outputPair)
    end

    --可能掉落奖励
    local petDropID = resourceCfg:OutputResourcePetDrop()
    local dropItemGroupInfos = ModuleRefer.InventoryModule:GetDropItems(petDropID)
    if dropItemGroupInfos then
        local weightSum = 0
        local itemCells = {}
        for _, itemGroupInfo in ipairs(dropItemGroupInfos) do
            weightSum = weightSum + itemGroupInfo:Weights()
        end
        for _, itemGroupInfo in ipairs(dropItemGroupInfos) do
            if itemGroupInfo:Nums() <= 0 then
                goto continue
            end
            local rateText = math.round(itemGroupInfo:Weights() / weightSum * 100) .. "%"
            ---@type ItemIconData
            local iconData = {}
            iconData.configCell = ConfigRefer.Item:Find(itemGroupInfo:Items())
            iconData.showCount = false
            iconData.showTextNum = true
            iconData.customTextNum = rateText
            local rewardCellData = TMCellRewardItemIconData.new(iconData)
            table.insert(itemCells, rewardCellData)
            ::continue::
        end
        local rewardData = TouchMenuCellRewardDatum.new(I18N.Get("searchentity_info_possible_reward"), itemCells)
        table.insert(ret, rewardData)
    end

    return ret
end

function KingdomTouchInfoProviderResourceField:CreateTipData(tile)
    ---@type wds.ResourceField
    local entity = tile.entity
    
    local tip = string.Empty
    if ModuleRefer.MapResourceFieldModule:IsLockedByVillage(entity) then
        tip = I18N.GetWithParams("mining_info_collection_after_occupying")
    end
    if ModuleRefer.MapResourceFieldModule:IsLockedByLandform(entity) then
        local landName = ModuleRefer.MapResourceFieldModule:GetUnlockLandformName(entity.FieldInfo.ConfID)
        tip = I18N.GetWithParams("mining_info_collection_after_stage", landName)
    end
    return TouchMenuButtonTipsData.new():SetContent(tip)
end

function KingdomTouchInfoProviderResourceField:CreateButtonInfo(tile)
    local buttons = {}
    
    local owner = tile.entity.Owner
    if ModuleRefer.PlayerModule:IsEmpty(owner) then
        local content = I18N.Get("mining_info_collection")
        local onClick = Delegate.GetOrCreate(ModuleRefer.MapResourceFieldModule, ModuleRefer.MapResourceFieldModule.RequestCollectResourceField)
        local isEnabled = not ModuleRefer.MapResourceFieldModule:IsLockedByLandform(tile.entity)
                    and not ModuleRefer.MapResourceFieldModule:IsLockedByVillage(tile.entity)
        local button = TouchMenuMainBtnDatum.new(content, onClick, tile.entity)
        button:SetEnable(isEnabled)
        table.insert(buttons, button)
    elseif ModuleRefer.PlayerModule:IsMine(owner) then
        local content = I18N.Get("mining_btn_recall")
        local onClick = Delegate.GetOrCreate(ModuleRefer.MapResourceFieldModule, ModuleRefer.MapResourceFieldModule.RequestRecallResourceField)
        local button = TouchMenuMainBtnDatum.new(content, onClick, tile.entity)
        table.insert(buttons, button)
    elseif ModuleRefer.PlayerModule:IsFriendly(owner) then
        local content = I18N.Get("troop_status_4")
        local button = TouchMenuMainBtnDatum.new(content):SetOnClickDisable(function()
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("mine_toast_being_collected"))
        end)
        button:SetEnable(false)
        table.insert(buttons, button)
    elseif ModuleRefer.PlayerModule:IsHostile(owner) then
        local content = I18N.Get("world_gongji")
        local onClick = KingdomTouchInfoOperation.SendTroopToMapBuilding
        local button = TouchMenuMainBtnDatum.new(content, onClick, tile.entity)
        table.insert(buttons, button)
    end
    return TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons)
end

return KingdomTouchInfoProviderResourceField