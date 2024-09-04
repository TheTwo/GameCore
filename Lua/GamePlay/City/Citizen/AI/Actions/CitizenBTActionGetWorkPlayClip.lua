local ModuleRefer = require("ModuleRefer")
local CitizenBTDefine = require("CitizenBTDefine")
local CityCitizenDefine = require("CityCitizenDefine")
local CityWorkTargetType = require("CityWorkTargetType")
local ConfigRefer = require("ConfigRefer")
local AudioConsts = require("AudioConsts")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionGetWorkPlayClip:CitizenBTActionNode
---@field new fun():CitizenBTActionGetWorkPlayClip
---@field super CitizenBTActionNode
local CitizenBTActionGetWorkPlayClip = class('CitizenBTActionGetWorkPlayClip', CitizenBTActionNode)

function CitizenBTActionGetWorkPlayClip:Run(context, gContext)
    local workTargetInfo = context:Read(CitizenBTDefine.ContextKey.WorkTargetInfo)
    if not workTargetInfo then
        return false
    end
    local city = context:GetCity()
    ---@type CitizenBTActionPlayClipContextParam
    local playClipParam = {}
    playClipParam.clipName = self:GetInteractAniClip(city, workTargetInfo)
    playClipParam.soundId = self:GetInteractSound(workTargetInfo)
    playClipParam.leftTime = nil
    playClipParam.dumpStr = CitizenBTDefine.DumpWorkInfo
    context:Write(CitizenBTDefine.ContextKey.PlayClipInfo, playClipParam)
    return CitizenBTActionGetWorkPlayClip.super.Run(self, context, gContext)
end

---@param city MyCity
---@param workTargetInfo CityCitizenTargetInfo
function CitizenBTActionGetWorkPlayClip:GetInteractAniClip(city, workTargetInfo)
    local targetId = workTargetInfo.id
    local targetType = workTargetInfo.type
    if targetType == CityWorkTargetType.Building then
        local cell = city.grid:FindMainCellWithTileId(targetId)
        if cell then
            local c = ConfigRefer.BuildingLevel:Find(cell:ConfigId())
            if c then
                local clip = c:ConstructAction()
                if not string.IsNullOrEmpty(clip) then
                    return clip
                end
            end
        end
        return CityCitizenDefine.AniClip.Building
    end
    if targetType == CityWorkTargetType.Resource then
        ---@type CityElementResource
        local c = city.elementManager:GetElementById(targetId)
        if c then
            local res = c.resourceConfigCell
            if res and not string.IsNullOrEmpty(res:CollectAction()) then
                return res:CollectAction()
            end
        end
        return CityCitizenDefine.AniClip.Logging
    end
    if targetType == CityWorkTargetType.Furniture then
        local cell = city.furnitureManager:GetFurnitureById(targetId)
        if cell then
            local c = ConfigRefer.CityFurnitureLevel:Find(cell:ConfigId())
            if c and not string.IsNullOrEmpty(c:Action()) then
                return c:Action()
            end
        end
    end
    return CityCitizenDefine.AniClip.Crafting
end

---@param workTargetInfo CityCitizenTargetInfo
function CitizenBTActionGetWorkPlayClip:GetInteractSound(workTargetInfo)
    local targetId = workTargetInfo.id
    local targetType= workTargetInfo.type
    if not targetId or not targetType or targetType ~= CityWorkTargetType.Resource then
        return
    end
    local eleConfig = ConfigRefer.CityElementData:Find(targetId)
    if not eleConfig then
        return
    end
    local resConfig = ConfigRefer.CityElementResource:Find(eleConfig:ElementId())
    if not resConfig then
        return
    end
    local itemGroupCfg = ConfigRefer.ItemGroup:Find(resConfig:Reward())
    if not itemGroupCfg then
        return
    end
    local InventoryModule = ModuleRefer.InventoryModule
    for i = 1, itemGroupCfg:ItemGroupInfoListLength() do
        local item = itemGroupCfg:ItemGroupInfoList(i)
        local itemId = item:Items()
        local resType = InventoryModule:GetResTypeByItemId(itemId)
        if resType then
            if resType == 1 then
                return AudioConsts.sfx_ui_logging
            elseif resType ==2 then
                return AudioConsts.sfx_ui_quarrying
            end
        end
    end
end

return CitizenBTActionGetWorkPlayClip