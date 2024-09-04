local BaseModule = require ('BaseModule')
local rapidJson = require("rapidjson")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require('ModuleRefer')
local SlgLocalConfig = require('SlgLocalConfig')
---@class SlgDataCacheModule:BaseModule
---@field soldierData table<number,SoldierCfgCache>
local SlgDataCacheModule = class('SlgDataCacheModule',BaseModule)

---@class SoldierClientCfgCache
---@field soldierCountCfg number[]
---@field battleModel_path string
---@field battleModel_scale number 
---@field soldierCountCfg_InCity number[]
---@field battleModelInCity_path string
---@field battleModelInCity_scale number 
---@field normalAtt number

---@class SoldierCfgCache
---@field speed number
---@field displayPower number
---@field clientCfgCache SoldierClientCfgCache


function SlgDataCacheModule:ctor()
    
end

function SlgDataCacheModule:OnRegister()    
    self._performanceLevel = (g_Game.PerformanceLevelManager:GetDeviceLevel() == CS.DragonReborn.Performance.DeviceLevel.High) and 0 or 1
    self:LoadSkillConfig()
    -- self:LoadSoldierConfig()
    self:LoadBackToCityConfig()
    local defaultSpeed = 240 --ConfigRefer.ConstMain:SlgEntityDefaultSpeed()
    self.defaultSpeed =  defaultSpeed / SlgLocalConfig.TroopUniScale
    self.deadSpeed = ConfigRefer.ConstMain:SlgTroopDeadSpeed() / SlgLocalConfig.TroopUniScale
end

function SlgDataCacheModule:OnRemove()
    self:ClearSkillConfig()
    -- self:ClearSoldierConfig()
    self:ClearBackToCityConfig()
end

---------------------------------------------------------------------------------------------------------------------------------------------
---Hero Skill Config Cache
---@class SkillConfig
function SlgDataCacheModule:LoadSkillConfig()    
    local jsonObj = g_Game.AssetManager:LoadTextToJsonObj('troop_skill')
    if not jsonObj then
        g_Logger.Error("skill_client.json parse error.")
        return
    end
    local skills = jsonObj["Skills"]
    local skillsMap = {}
    if skills then
        for i = 1, #skills do
            local skill = skills[i]
            local skillId = skill["Id"]
            skillsMap[skillId] = {}
            skillsMap[skillId].config = skill            

            if skill then
                local animName
                local animDuration
                local skillStage = skill.Stages.Default
                if skillStage and skillStage.Attacker then
                    for key, value in pairs(skillStage.Attacker) do
                        if value.AnimName then
                            animName = value.AnimName
                            animDuration = value.Time
                            break
                        end
                    end
                end           
                if animName and animDuration then
                    skillsMap[skillId].animName = animName
                    skillsMap[skillId].animDuration = animDuration
                end

                if skillStage and skillStage.Target then
                    local damageText
                    local camShake
                    for key, value in pairs(skillStage.Target) do
                        if value.TrackName == "Damage Text Track" then
                            damageText = value                           
                        end
                        if value.TrackName == "Slg Camera Shake Track" then
                            camShake = value
                        end
                        if damageText and camShake then
                            break
                        end
                    end
                    skillsMap[skillId].damageText = damageText
                    skillsMap[skillId].camShake = camShake
                end
            end
        end
    end
    self._skillsMap = skillsMap
    self._skillAssetIdMap = {}
    for key, value in ConfigRefer.KheroSkillLogical:ipairs() do
        local assetId = value:Asset()
        local cfgId = value:Id()
        if assetId and assetId > 0 and cfgId > 0 then
            self._skillAssetIdMap[cfgId] = assetId
        end
    end
end
function SlgDataCacheModule:ClearSkillConfig()
    self._skillsMap = nil
end
function SlgDataCacheModule:GetSkillAssetCache(assetId)
    if self._skillsMap then
        return self._skillsMap[assetId]
    end
end

function SlgDataCacheModule:GetSkillAssetId(configId)
    if self._skillAssetIdMap  then
        return self._skillAssetIdMap[configId]        
    end
end

---------------------------------------------------------------------------------------------------------------------------------------------
---Soldier Config Data Cache
-- local AttrTypeId_Speed_1 = 90040 --行军速度 近战
-- local AttrTypeId_Speed_2 = 90046 --行军速度 远程
-- local AttrTypeId_Speed_3 = 90049 --行军速度 工程
-- local ATTR_DISP_ID_POWER = 100 
-- function SlgDataCacheModule:LoadSoldierConfig()
--     self.soldierData = {}
--     local defaultSpeed = 240 --ConfigRefer.ConstMain:SlgEntityDefaultSpeed()
--     self.defaultSpeed =  defaultSpeed / SlgLocalConfig.TroopUniScale
--     self.deadSpeed = ConfigRefer.ConstMain:SlgTroopDeadSpeed() / SlgLocalConfig.TroopUniScale
--     local dispConfPower = ConfigRefer.AttrDisplay:Find(ATTR_DISP_ID_POWER)
--     for key, soldierCfg in ConfigRefer.Soldier:ipairs() do
--         ---@type SoldierCfgCache
--         local soldierCfgData = {}       
--         local id = soldierCfg:Id()
--         local attrGroupId = soldierCfg:SoldierAttr()
--         local attrGroupCfg = ConfigRefer.AttrGroup:Find(attrGroupId) 
--         if attrGroupCfg then
--             local attrCount = attrGroupCfg:AttrListLength()
--             if attrCount < 1 then
--                 goto LoadSoldierConfig_continue
--             end
--             for i = 1, attrCount do
--                 local attrItem = attrGroupCfg:AttrList(i)
--                 if attrItem:TypeId() == AttrTypeId_Speed_1 
--                     or attrItem:TypeId() == AttrTypeId_Speed_2 
--                     or attrItem:TypeId() == AttrTypeId_Speed_3 
--                 then
--                     soldierCfgData.speed = attrItem:Value()
--                     break
--                 end               
--             end

--             local attrList = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(attrGroupId)	   
--             soldierCfgData.displayPower = ModuleRefer.AttrModule:GetDisplayValueWithData(dispConfPower, attrList)
--             ::LoadSoldierConfig_continue::
--         end

--         local clientCfg = ConfigRefer.SoldierClient:Find(soldierCfg:SoldierClientCfg())
--         if clientCfg then
--             ---@type SoldierClientCfgCache
--             local cacheItem = {}

--             local soldierCountCfg = nil
--             local soldierCountCfg_InCity = nil
--             local countCfgLength = (self._performanceLevel > 0) and  SlgLocalConfig.MaxSoldierCount.low or SlgLocalConfig.MaxSoldierCount.heigh
--             --in world
--             local countLength = math.min( countCfgLength, clientCfg:SoldierCountLength())
--             if countLength > 0 then
--                 soldierCountCfg ={}
--                 for i = 1, countCfgLength do                    
--                     soldierCountCfg[i] = clientCfg:SoldierCount(i)                    
--                 end
--             end
--             cacheItem.soldierCountCfg = soldierCountCfg
--             --artres in world
--             local battleModelArt = ConfigRefer.ArtResource:Find(clientCfg:BattleModel())
--             cacheItem.battleModel_path = battleModelArt:Path()
--             cacheItem.battleModel_scale = battleModelArt:ModelScale()
                       
--             --in city
--             countLength = math.min( countCfgLength, clientCfg:SoldierCountInCityLength())
--             if countCfgLength > 0 then
--                 soldierCountCfg_InCity ={} -- CS.System.Array.CreateInstance(typeof(CS.System.Int32),countCfgLength)
--                 for i = 1, countCfgLength do                   
--                     soldierCountCfg_InCity[i] = clientCfg:SoldierCountInCity(i)                    
--                 end
--             end
--             --artres in city
--             local battleModelArt_InCity = ConfigRefer.ArtResource:Find(clientCfg:BattleModelInCity())
--             if battleModelArt_InCity then
--                 cacheItem.battleModelInCity_path = battleModelArt_InCity:Path()
--                 cacheItem.battleModelInCity_scale = battleModelArt_InCity:ModelScale()   
--             end         
--             cacheItem.soldierCountCfg_InCity = soldierCountCfg_InCity
            
--             ---normal attack skill Id
--             cacheItem.normalAtt = clientCfg:NormalAttAsset() or 0

--             soldierCfgData.clientCfgCache = cacheItem
--         end

--         self.soldierData[id] = soldierCfgData
--     end
-- end
-- function SlgDataCacheModule:ClearSoldierConfig()
--     self.soldierData = nil
-- end
-- function SlgDataCacheModule:GetSoldierSpeed(id)
--     local speed = nil
--     if self.soldierData[id] then
--         speed = self.soldierData[id].speed
--     end
--     return speed or self.defaultSpeed
-- end

-- function SlgDataCacheModule:GetSoldierPower(id)
--     local power = nil
--     if self.soldierData[id] then
--         power = self.soldierData[id].power
--     end
--     return power or 0
-- end

-- ---@return SoldierClientCfgCache
-- function SlgDataCacheModule:GetSoldierClientCfg(id)
--     if self.soldierData[id] then
--         return self.soldierData[id].clientCfgCache
--     end
-- end

---------------------------------------------------------------------------------------------------------------------------------------------
---Back to city ItemConfig
function SlgDataCacheModule:LoadBackToCityConfig()
    local itemGroupID = ConfigRefer.ConstMain:ImmediatelyBackToCityItemGroup()    
    if itemGroupID < 1 then
        return
    end
    local backCityItemGroup = ConfigRefer.ItemGroup:Find(itemGroupID)
    if not backCityItemGroup then
        return 
    end

    local itemListLength = backCityItemGroup:ItemGroupInfoListLength()
    if itemListLength < 1 then
        return
    end

    local itemInfo = backCityItemGroup:ItemGroupInfoList(1)
    if not itemInfo then
        return
    end
    self.BackCityItemID = itemInfo:Items()
    self.BackCityItemNumber = itemInfo:Nums()

    local itemCfg =  ConfigRefer.Item:Find(self.BackCityItemID)
    if not itemCfg then
        return
    end

    self.BackCityItemIcon = itemCfg:Icon()
    self.BackCityItemBackIcon = itemCfg:BackIcon()
    
end

function SlgDataCacheModule:ClearBackToCityConfig()
    self.BackCityItemIcon = nil
    self.BackCityItemBackIcon = nil
    self.BackCityItemID = nil
    self.BackCityItemNumber = nil
end

---@return string,string @ItemIcon name,ItemBack name
function SlgDataCacheModule:GetBackCityItemIcon()
    return self.BackCityItemIcon,self.BackCityItemBackIcon
end

---@return number,number @itemId,item count
function SlgDataCacheModule:GetBackCityItem()
    return self.BackCityItemID,self.BackCityItemNumber
end

return SlgDataCacheModule