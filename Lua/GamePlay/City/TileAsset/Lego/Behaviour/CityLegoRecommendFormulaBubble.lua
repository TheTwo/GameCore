---@class CityLegoRecommendFormulaBubble
---@field new fun():CityLegoRecommendFormulaBubble
---@field p_rotation CS.UnityEngine.Transform
---@field p_position CS.UnityEngine.Transform
---@field p_grid CS.U2DHorizontalLayoutGroup
---@field icon_room CS.U2DSpriteMesh
---@field p_templates CS.UnityEngine.Transform
---@field p_tmplate_furniture CS.UnityEngine.GameObject
---@field p_templates_add CS.UnityEngine.Transform
---@field p_icon_add CS.UnityEngine.GameObject
local CityLegoRecommendFormulaBubble = class("CityLegoRecommendFormulaBubble")
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local ConfigRefer = require("ConfigRefer")

function CityLegoRecommendFormulaBubble:Awake()
    self.pool_units = LuaReusedComponentPool.new(self.p_tmplate_furniture, self.p_templates)
    self.pool_adds = LuaReusedComponentPool.new(self.p_icon_add, self.p_templates_add)
end

function CityLegoRecommendFormulaBubble:Reset()
    self.pool_units:HideAll()
    self.pool_adds:HideAll()
end

---@param legoBuilding CityLegoBuilding
---@param buffCfg RoomTagBuffConfigCell
---@param lvCfg CityFurnitureLevelConfigCell
function CityLegoRecommendFormulaBubble:UpdatePreview(legoBuilding, buffCfg, lvCfg, complete)
    -- local previewTagProvide = {}
    -- for i = 1, lvCfg:RoomTagsLength() do
    --     local tagCfgId = lvCfg:RoomTags(i)
    --     previewTagProvide[tagCfgId] = (previewTagProvide[tagCfgId] or 0) + 1
    -- end

    local providerMap = legoBuilding.buffCalculator:GetTagProviderMap(buffCfg)
    for i = 1, buffCfg:RoomTagListLength() do
        local tagCfgId = buffCfg:RoomTagList(i)
        local tagCfg = ConfigRefer.RoomTag:Find(tagCfgId)
        local provider = providerMap[i]
        local icon = tagCfg:Icon()
        -- if provider then
        --     icon = provider:GetImage()
        -- elseif previewTagProvide[tagCfgId] > 0 then
            icon = tagCfg:IconInRouteMap()
            -- previewTagProvide[tagCfgId] = previewTagProvide[tagCfgId] - 1
        -- end
        
        local unitGo = self.pool_units:GetItem()
        unitGo.transform:SetParent(self.p_grid.transform)
        ---@type FormulaItem
        local unit = unitGo:GetLuaBehaviour("FormulaItem").Instance
        unit:UpdateUI(icon, provider ~= nil)

        if i < buffCfg:RoomTagListLength() then
            local addGo = self.pool_adds:GetItem()
            addGo.transform:SetParent(self.p_grid.transform)
        end
    end
end

---@param legoBuilding CityLegoBuilding
---@param buffCfg RoomTagBuffConfigCell
function CityLegoRecommendFormulaBubble:UpdateExpire(legoBuilding, buffCfg)
    local providerMap = legoBuilding.buffCalculator:GetTagProviderMap(buffCfg)
    for i = 1, buffCfg:RoomTagListLength() do
        local tagCfgId = buffCfg:RoomTagList(i)
        local tagCfg = ConfigRefer.RoomTag:Find(tagCfgId)
        local provider = providerMap[i]
        local icon = tagCfg:IconInRouteMap()

        local unitGo = self.pool_units:GetItem()
        unitGo.transform:SetParent(self.p_grid.transform)
        ---@type FormulaItem
        local unit = unitGo:GetLuaBehaviour("FormulaItem").Instance
        unit:UpdateUI(icon, provider ~= nil)

        if i < buffCfg:RoomTagListLength() then
            local addGo = self.pool_adds:GetItem()
            addGo.transform:SetParent(self.p_grid.transform)
        end
    end
end

return CityLegoRecommendFormulaBubble