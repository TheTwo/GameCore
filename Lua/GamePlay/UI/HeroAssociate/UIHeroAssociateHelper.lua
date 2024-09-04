local ConfigRefer = require('ConfigRefer')
local TagType = require('TagType')
local TagEffectObject = require('TagEffectObject')
local ModuleRefer = require('ModuleRefer')

---@class HeroAssociateData_TagCfg
---@field name string
---@field icon number
---@field base number
---@field desc string
---@field restrain number[]
---@field counterRestrain number[]

---@class HeroAssociateData_RelationCfg
---@field key string
---@field tags number[]
---@field displayValue string @提升数值 I18N
---@field addHpPct number
---@field effectObjType number
---@field effectTags number[]

---@class HeroAssociateData
---@field tagCfg table<TagType,HeroAssociateData_TagCfg>
---@field relationCfg table<string,HeroAssociateData_RelationCfg>

---@class UIHeroAssociateHelper
local UIHeroAssociateHelper = class('UIHeroAssociateHelper')

---@private
---@param tags number[] @TagType
---@return string
function UIHeroAssociateHelper.CalcRelationKey(tags)
    if tags == nil or #tags == 0 then
        return 0
    end
    table.sort(tags)
    local key = 0
    for i = 1, #tags do
        key = key + tags[i] * 10 ^ (i - 1)
    end
    return tostring( math.floor(key))
end


---@public
---@return HeroAssociateData
function UIHeroAssociateHelper.GetHeroAssociateData(ignoreRelation)
    local tagCfg = ConfigRefer.AssociatedTag
    ---@type HeroAssociateData
    local data = {
        tagCfg = {},
        relationCfg = {},
    }
    for key, value in tagCfg:ipairs() do
        local tagType = value:TagInfo()
        if data.tagCfg[tagType] then
            g_Logger.ErrorChannel("UIHeroAssociateHelper","GetHeroAssociateData failed, tagType in [AssociatedTagConfig] is repeat:" .. key)
            return nil
        end
        if key ~= tagType then
            g_Logger.ErrorChannel("UIHeroAssociateHelper","GetHeroAssociateData failed, tagType in [AssociatedTagConfig] TagInfo is not equal to key!! ID:" .. key)
            return nil
        end
        data.tagCfg[tagType] = {
            name = value:Name(),
            icon = value:Icon(),
            base = value:Base(),
            desc = value:Des(),
            -- restrain = {},
            -- counterRestrain = {},
        }
        --此处暂时不需要关注这两个字段
        -- local restrainCount = value:RestrainTagInfoLength()
        -- for i = 1, restrainCount do
        --     data[tagType].restrain[i] = value:RestrainTagInfo(i)
        -- end
        -- local counterRestrainCount = value:CounterRestrainTagInfoLength()
        -- for i = 1, counterRestrainCount do
        --     data[tagType].counterRestrain[i] = value:CounterRestrainTagInfo(i)
        -- end

        if ignoreRelation then
            goto continue
        end

        local relationCount = value:TagTiesRelationshipsLength()
        for i = 1, relationCount do
            local relationship = value:TagTiesRelationships(i)
            local relationTagCount = relationship:TiesTagLength()
            ---@type number[]
            local relationTags = {}
            for j = 1, relationTagCount do
                table.insert(relationTags, relationship:TiesTag(j))
            end
            local relationKey = UIHeroAssociateHelper.CalcRelationKey(relationTags)
            if data.relationCfg[relationKey] then
                g_Logger.ErrorChannel("UIHeroAssociateHelper","GetHeroAssociateData failed, relationKey in [AssociatedTagConfig] is repeat:" .. key)
                return nil
            end
            local tiesId = relationship:Ties()
            local tiesCfg = ConfigRefer.TagTies:Find(tiesId)
            ---@type HeroAssociateData_RelationCfg
            local cfgData = {}
            cfgData.key = relationKey
            cfgData.tags = relationTags
            cfgData.displayValue = tiesCfg:Value()
            cfgData.effectObjType = relationship:EffectObject()
            cfgData.effectTags = {}
            for j = 1, relationship:EffectTagLength() do
                table.insert(cfgData.effectTags, relationship:EffectTag(j))
            end


            if tiesCfg:TiesAddonsLength() > 0 then
                for j = 1, tiesCfg:TiesAddonsLength() do
                    -- cfgData.addons[j] = tiesCfg:TiesAddons(j)
                    local addonId = tiesCfg:TiesAddons(j)
                    local addonCfg = ConfigRefer.AttrGroup:Find(addonId)
                    local attrLength = addonCfg:AttrListLength()
                    for k = 1, attrLength do
                        local addAttr = addonCfg:AttrList(k)
                        if addAttr:TypeId() == 18 then --血量_multi
                            cfgData.addHpPct = addAttr:Value()
                            break
                        end
                    end
                    if cfgData.addHpPct then
                        break
                    end
                end
            end

            data.relationCfg[relationKey] = cfgData
        end
        ::continue::
    end


    return data
end

---@public
---@param tags number[] @TagType
---@param data HeroAssociateData
---@return HeroAssociateData_RelationCfg
function UIHeroAssociateHelper.FindRelation(tags,data)
    if not data or not data.relationCfg then
        return nil
    end
    local relationKey = UIHeroAssociateHelper.CalcRelationKey(tags)
    local cfg = nil
    for key, value in pairs(data.relationCfg) do
        if key == relationKey then
            cfg = value
            break
        end
        if not cfg and string.find(relationKey,key,1,true) then
            cfg = value
        end
    end
    return cfg
end

---@param cfg HeroAssociateData_RelationCfg
---@param heroId number
---@return boolean
function UIHeroAssociateHelper.IsHeroEffect(cfg, heroId)
    if not cfg then
        return false
    end
    local heroTagId = ConfigRefer.Heroes:Find(heroId):AssociatedTagInfo()
    if cfg.effectObjType == TagEffectObject.TagEffectAll or cfg.effectObjType == TagEffectObject.TagEffectHero then
        for i = 1, #cfg.effectTags do
            if cfg.effectTags[i] == heroTagId then
                return true
            end
        end
    end
    return false
end

---@param cfg HeroAssociateData_RelationCfg
---@param petId number
---@return boolean
function UIHeroAssociateHelper.IsPetEffect(cfg, petId)
    if not cfg then
        return false
    end
    local pet = ModuleRefer.PetModule:GetPetByID(petId)
    local petCfg = ConfigRefer.Pet:Find(pet.ConfigId)
    local petTagId = petCfg:AssociatedTagInfo()
    if cfg.effectObjType == TagEffectObject.TagEffectAll or cfg.effectObjType == TagEffectObject.TagEffectPet then
        for i = 1, #cfg.effectTags do
            if cfg.effectTags[i] == petTagId then
                return true
            end
        end
    end
    return false
end

return UIHeroAssociateHelper