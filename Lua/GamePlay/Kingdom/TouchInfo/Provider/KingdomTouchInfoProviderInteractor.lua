local KingdomTouchInfoProvider = require("KingdomTouchInfoProvider")
local KingdomTouchInfoCompHelper = require("KingdomTouchInfoCompHelper")
local TouchMenuHelper = require("TouchMenuHelper")
local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")
local TouchMenuBasicInfoDatumSe = require("TouchMenuBasicInfoDatumSe")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local DBEntityType = require("DBEntityType")
local KingdomTouchInfoOperation = require("KingdomTouchInfoOperation")
local TouchMenuCellRewardDatum = require("TouchMenuCellRewardDatum")
local TouchMenuCellPairDatum = require("TouchMenuCellPairDatum")
local TouchMenuButtonTipsData = require("TouchMenuButtonTipsData")

---@class KingdomTouchInfoProviderInteractor : KingdomTouchInfoProvider
local KingdomTouchInfoProviderInteractor = class("KingdomTouchInfoProviderInteractor", KingdomTouchInfoProvider)

function KingdomTouchInfoProviderInteractor:CreateBasicInfo(tile)
    local slgInteractor = tile.entity
    local config = ConfigRefer.Mine:Find(slgInteractor.Interactor.ConfigID)
    return TouchMenuBasicInfoDatumSe.new(config:ShowIcon(), I18N.Get(config:ShowName()), I18N.Get(config:ShowDesc()))
end

function KingdomTouchInfoProviderInteractor:CreateDetailInfo(tile)
    ---@type wds.SlgInteractor
    local slgInteractor = tile.entity
    local config = ConfigRefer.Mine:Find(slgInteractor.Interactor.ConfigID)
    local ret = {}

    if ModuleRefer.RadarModule:IsMultiInteractor(config) then
        local remainTimes = ModuleRefer.RadarModule:GetInteractorRemainTimes(slgInteractor)
        local pairRemainTimes = TouchMenuCellPairDatum.new()
        pairRemainTimes:SetLeftLabel(I18N.Get("alliance_activity_big22"))
        pairRemainTimes:SetRightLabel(tostring(remainTimes))
        table.insert(ret, pairRemainTimes)
    end
    
    local itemGroupLength = config:AddItemIdsLength()
    local rewardDatum = TouchMenuCellRewardDatum.new()
    if itemGroupLength > 0 then
        rewardDatum:SetTitle(I18N.Get("searchentity_info_possible_reward"))
        for i = 1, itemGroupLength do
            local itemGroupID = config:AddItemIds(i)
            local itemGroupConfig = ConfigRefer.ItemGroup:Find(itemGroupID)
            local itemLength = itemGroupConfig:ItemGroupInfoListLength()
            for j = 1, itemLength do
                local itemConfig = itemGroupConfig:ItemGroupInfoList(j)
                ---@type ItemIconData
                local rewardData = {
                    configCell = ConfigRefer.Item:Find(itemConfig:Items()),
                    showTips = true,
                    showCount = true,
                    count = itemConfig:Nums(),
                    useNoneMask = false,
                }
                rewardDatum:AppendItemIconData(rewardData)
            end
           
        end
        table.insert(ret, rewardDatum)
    end
    return ret
end

function KingdomTouchInfoProviderInteractor:CreateTipData(tile)
    ---@type wds.SlgInteractor
    local slgInteractor = tile.entity
    local config = ConfigRefer.Mine:Find(slgInteractor.Interactor.ConfigID)

    if ModuleRefer.RadarModule:IsMultiInteractor(config) then
        local content
        if ModuleRefer.RadarModule:CanInteract(slgInteractor) then
            content = I18N.Get("alliance_activity_big27")
        else
            local limitTimes = config:PlayerInteractLimit()
            content = I18N.GetWithParams("alliance_activity_big25", limitTimes)
        end
        return TouchMenuButtonTipsData.new():SetContent(content)
    end
end

function KingdomTouchInfoProviderInteractor:CreateButtonInfo(tile)
    local slgInteractor = tile.entity
    local config = ConfigRefer.Mine:Find(slgInteractor.Interactor.ConfigID)
    
    local buttons = {}
    local btnStr = I18N.Get("slg_caiji")
    if not string.IsNullOrEmpty(config:ButtonText()) then
        btnStr = I18N.Get(config:ButtonText())
    end
    local buttonCollect = TouchMenuMainBtnDatum.new(btnStr, KingdomTouchInfoProviderInteractor.Collect, tile)
    local canInteract = ModuleRefer.RadarModule:CanInteract(slgInteractor)
    buttonCollect:SetEnable(canInteract)
    table.insert(buttons, buttonCollect)

    if tile.entity.LevelEntityInfo and tile.entity.LevelEntityInfo.LevelEntityId > 0 and config:CanCollect() then
        --添加自动完成按钮
        local levelId = tile.entity.LevelEntityInfo.LevelEntityId
        local expEntity = (levelId ~= 0) and g_Game.DatabaseManager:GetEntity(levelId, DBEntityType.Expedition) or nil
        local expConfig = expEntity and ConfigRefer.WorldExpeditionTemplate:Find(expEntity.ExpeditionInfo.Tid) or nil
        if expConfig and expConfig:ProgressType() == require('ProgressType').Personal then
            local autoFinishBtn = TouchMenuMainBtnDatum.new(
                    I18N.Get("circlemenu_autofinish"),
                    KingdomTouchInfoOperation.SendTroopToWorldEventAndAutoFinish,
                    tile.entity)
            table.insert(buttons,autoFinishBtn)
        end
    end

    return TouchMenuHelper.GetRecommendButtonGroupDataArray(buttons)
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProviderInteractor.Collect(tile)
    KingdomTouchInfoOperation.SendTroopToEntityQuickly(tile.entity)
end

return KingdomTouchInfoProviderInteractor