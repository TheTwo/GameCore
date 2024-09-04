local KingdomMapUtils = require('KingdomMapUtils')
local TouchInfoHelper = require("TouchInfoHelper")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local EventConst = require('EventConst')
local KingdomTouchInfoContext = require("KingdomTouchInfoContext")
local ArtResourceUtils = require("ArtResourceUtils")
local TimeFormatter = require("TimeFormatter")
local TouchMenuBasicInfoDatum = require("TouchMenuBasicInfoDatum")
local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")
local TouchMenuCellPairDatum = require("TouchMenuCellPairDatum")
local TouchMenuCellTextDatum = require("TouchMenuCellTextDatum")
local TouchMenuCellRewardDatum = require("TouchMenuCellRewardDatum")
local TouchMenuCellProgressDatum = require("TouchMenuCellProgressDatum")
local TouchMenuCellPairTimeDatum = require("TouchMenuCellPairTimeDatum")
local TouchMenuCellTaskDatum = require("TouchMenuCellTaskDatum")
local TouchMenuHelper = require("TouchMenuHelper")
local NumberFormatter = require("NumberFormatter")
local TouchMenuBasicInfoDatumSe = require('TouchMenuBasicInfoDatumSe')
local TMCellRewardItemIconData = require("TMCellRewardItemIconData")
local TouchMenuCellSeMonsterDatum = require("TouchMenuCellSeMonsterDatum")
local TMCellSeMonsterDatum = require("TMCellSeMonsterDatum")
local ProgressType = require("ProgressType")
local UIMediatorNames = require("UIMediatorNames")
local ChatShareUtils = require("ChatShareUtils")
local KingdomTouchInfoMarkProvider = require("KingdomTouchInfoMarkProvider")

---@class KingdomTouchInfoCompHelper:TouchInfoHelper
local KingdomTouchInfoCompHelper = setmetatable({}, {__index = TouchInfoHelper})

---@param tile MapRetrieveResult
---@return TouchMenuBasicInfoDatum 环形菜单顶部基本信息
function KingdomTouchInfoCompHelper.GenerateBasicData(tile)
    local name = nil
    local level = nil
    local coord = nil
    local image = nil
    local dbType = nil
    local configID = nil
    if tile.entity then
        name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(tile.entity)
        if UNITY_DEBUG or UNITY_EDITOR then
            name = name .. "(" .. tostring(tile.entity.ID) .. ")"
        end
        level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(tile.entity)
        image = ModuleRefer.MapBuildingTroopModule:GetBuildingImage(tile.entity)
        dbType = ChatShareUtils.TypeTrans(tile.entity.TypeHash)
        configID = tile.entity.MapBasics.ConfID
    else
        if ModuleRefer.MapCreepModule:CreepExistsAt(tile.X, tile.Z) then
            --todo slgCreep -> SlgCreepCenter
            local _, creepConfig = ModuleRefer.MapCreepModule:GetCreepDataAt(tile.X, tile.Z)
            name = I18N.Get(creepConfig:OuterName())
            level = creepConfig:Level()
        else
            name, image = KingdomTouchInfoCompHelper.GetEmptyTileNameAndImage(tile.X, tile.Z)
            level = nil
            dbType = -1
        end
    end
	coord = KingdomMapUtils.CoordToXYString(tile.X, tile.Z)
    local markProvider = KingdomTouchInfoMarkProvider.new(tile, false)
    return TouchMenuBasicInfoDatum.new(name, image, coord, level):SetTypeAndConfig(dbType, configID):SetMarkProvider(markProvider)
end

---@param data wds.MapEntityBrief | wds.AllianceMember
function KingdomTouchInfoCompHelper.GenerateBasicDataHighLod(tileX, tileZ, name, level)
    if not name then
        name = KingdomTouchInfoCompHelper.GetEmptyTileNameAndImage(tileX, tileZ)
        level = 0
    end
    local tile = KingdomMapUtils.RetrieveMap(tileX, tileZ)
    --local markProvider = KingdomTouchInfoMarkProvider.new(tile, true)
    return TouchMenuBasicInfoDatum.new(name, nil, KingdomMapUtils.CoordToXYString(tileX, tileZ), level)--:SetMarkProvider(markProvider)
end

function KingdomTouchInfoCompHelper.GetEmptyTileNameAndImage(tileX, tileZ)
    local landCfgId = ModuleRefer.TerritoryModule:GetLandCfgIdAt(tileX, tileZ)
    local landCfgCell = ConfigRefer.Land:Find(landCfgId)
    if landCfgCell then
        return I18N.Get(landCfgCell:Name()), landCfgCell:IconSpace()
    end

    return I18N.Get("world_kongdi"), nil
end

---@param callback fun(onClickDatum:table, trans:CS.UnityEngine.Transform)
function KingdomTouchInfoCompHelper.GenerateButtonCompData(callback, object, icon, label, backIcon)
    return TouchMenuMainBtnDatum.new(label, callback, object)
end

---@param tile MapRetrieveResult
---@return TouchMenuCellDatumBase[] 环形菜单主Window
function KingdomTouchInfoCompHelper.GenerateBuildingDetailWindow(tile)
    ---@type wds.EnergyTower|wds.TransferTower|wds.DefenceTower
    local entity = tile.entity
    -- local buildingConfig = ModuleRefer.MapBuildingTroopModule:GetBuildingConfig(entity.MapBasics.ConfID)

    -- local troopCount = tostring(ModuleRefer.MapBuildingTroopModule:GetTotalTroopCount(entity.Army, entity.MapBasics, nil))
    local durability = string.format("%d/%d", entity.Battle.Durability, entity.Battle.MaxDurability)

    -- local pairTroopComp = TouchMenuCellPairDatum.new(I18N.Get("xiangzhen_shoujun"), tostring(troopCount))
    -- pairTroopComp:SetBlackSprite("sp_hud_icon_friends")
    -- pairTroopComp:SetHintCallback(function()
    --     ModuleRefer.MapBuildingTroopModule:ShowTroopInfo(tile)
    -- end)
    
    local pairDurabilityComp = TouchMenuCellPairDatum.new(I18N.Get("xiangzhen_naijiu"), tostring(durability))
    pairDurabilityComp:SetBlackSprite("sp_comp_icon_durability")
    
    -- return {pairTroopComp, pairDurabilityComp}
    return {pairDurabilityComp}
end

---@param tile MapRetrieveResult
function KingdomTouchInfoCompHelper.GenerateResourceField_TableCellData(tile)
    ---@type wds.ResourceField
    local entity = tile.entity
    local resourceCfg = ConfigRefer.FixedMapBuilding:Find(entity.FieldInfo.ConfID)
    local outputItem = ConfigRefer.Item:Find(resourceCfg:OutputResourceItem())
    local ret = {}
    
    local leftLabel = I18N.Get("mining_info_reserves")
    local rightLabel = tostring(resourceCfg:OutputResourceMax())
    local outputPair = TouchMenuCellPairDatum.new(leftLabel, rightLabel, outputItem:Icon())
    table.insert(ret, outputPair)
    
    return ret
end

function KingdomTouchInfoCompHelper.GenerateMistMainWindow(cellId, tileX, tileZ)
    local cellAttrConfig = ModuleRefer.MapFogModule:GetMistAttrConfig(cellId)
    local name = I18N.Get(cellAttrConfig:Name())
    local level = cellAttrConfig:Level()
    return TouchMenuBasicInfoDatum.new(name, nil, KingdomMapUtils.CoordToXYString(tileX, tileZ), level)

end

function KingdomTouchInfoCompHelper.GenerateMistDetailWindow(cellId)
    local cellAttrConfig = ModuleRefer.MapFogModule:GetMistAttrConfig(cellId)
    local result = {}
    for i = 1, cellAttrConfig:ExploreCondLength() do
        local taskId = cellAttrConfig:ExploreCond(i)
        local taskDatum = TouchMenuCellTaskDatum.new(taskId)
        table.insert(result, taskDatum)
    end
    return result
end

---@param slgInteractor wds.SlgInteractor
function KingdomTouchInfoCompHelper.GenerateSlgInteractorDetailWindow(slgInteractor)
    local conf = ConfigRefer.Mine:Find(slgInteractor.Interactor.ConfigID)
    return TouchMenuBasicInfoDatumSe.new(conf:ShowIcon(), I18N.Get(conf:ShowName()), I18N.Get(conf:ShowDesc()))
end

function KingdomTouchInfoCompHelper.GenerateExpeditionBasicWindow(eventId)
    local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(eventId)
    return TouchMenuBasicInfoDatum.new(I18N.Get(eventCfg:Name())):SetLevel(eventCfg:Level())
end

function KingdomTouchInfoCompHelper.GenerateExpeditionDetailWindow(eventId, progress, quality)
    local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(eventId)
    local rewards = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(eventCfg:FullProgressReward()) or {}
    if quality and quality >= 0 then
        local itemGroupId = eventCfg:QualityExtReward(quality + 1)
        local expends = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(itemGroupId) or {}
        local ids = {}
        for _, reward in ipairs(rewards) do
            local id = reward.configCell:Id()
            if ids[id] then
                ids[id] = ids[id] + reward.count
            else
                ids[id] = reward.count
            end
        end
        for _, single in ipairs(expends) do
            local id  = single.configCell:Id()
            if ids[id] then
                ids[id] = ids[id] + single.count
            else
                ids[id] = single.count
            end
        end
        for i = 1, eventCfg:PartProgressRewardLength() do
            local progressReward = eventCfg:PartProgressReward(i)
            local progressRewardItems = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(progressReward:Reward()) or {}
            for _, reward in ipairs(progressRewardItems) do
                local id = reward.configCell:Id()
                if ids[id] then
                    ids[id] = ids[id] + reward.count
                else
                    ids[id] = reward.count
                end
            end
        end
        local itemArrays = {}
        for id, count in pairs(ids) do
            local itemConfig = ConfigRefer.Item:Find(id)
            itemArrays[#itemArrays + 1] = {configCell = itemConfig, count = count, showTips = true}
        end
        rewards = itemArrays
    end
    local compsData = {}
    local pairComp = nil
    local rewardComp
    if progress then
        local percent =  math.clamp(progress / eventCfg:MaxProgress(), 0, 1)
        pairComp = TouchMenuCellPairDatum.new(I18N.Get("world_sj_wcd"), percent * 100 .. "%")
        rewardComp = TouchMenuHelper.GetCellRewardDatum(rewards, percent >= 1 and I18N.Get("world_sj_hd") or I18N.Get("world_sj_knhd"))
    else
        rewardComp = TouchMenuHelper.GetCellRewardDatum(rewards, I18N.Get("world_sj_knhd"))
    end

    local descComp = TouchMenuCellTextDatum.new(I18N.Get(eventCfg:Des()), true)
    table.insert(compsData, pairComp)
    table.insert(compsData, descComp)
    table.insert(compsData, rewardComp)
    return compsData
end

return KingdomTouchInfoCompHelper