local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')

---@class ModelViewData
---@field heroPathList string[]
---@field heroScaleList number[]
---@field heroCircleTypeList number[]
---@field heroJobTypeList number[]
---@field heroHPs number[]@hp / maxHp
---@field petPathList string[]
---@field petScaleList number[]
---@field petCircleTypeList number[]
---@field petHPs number[]@hp / maxHp

---@class ModelSetupData
---@field isHero boolean
---@field pathes string[]
---@field scale number[]
---@field ringTypes number[]
---@field jobTypes number[]
---@field anims string[]

---@class UI3DTroopModelViewHelper
local UI3DTroopModelViewHelper = class("UI3DTroopModelViewHelper")

local MAX_HERO_COUNT = 3
UI3DTroopModelViewHelper.ViewType ={
    Hero = 1,
    Pet = 2,
}
---@param troopPreset wds.TroopPreset
---@return ModelViewData
function UI3DTroopModelViewHelper.CreateTroopViewDataViaTroopData(troopPreset)
    if not troopPreset then return nil,nil end

    local heroIds = {}
    local petIds = {}
    for i = 1, #troopPreset.Heroes do
        heroIds[i] = troopPreset.Heroes[i].HeroCfgID
        local linkedPetId = ModuleRefer.HeroModule:GetHeroLinkPet( heroIds[i])
        local petInfo = ModuleRefer.PetModule:GetPetInfo(linkedPetId)
        petIds[i] = petInfo and petInfo.ConfigID or 0
    end

    return UI3DTroopModelViewHelper.CreateTroopViewData(heroIds,petIds)
end

---@param heroCfgIds int[] @Ids of HeroesConfigCell
---@param petCgfIds int[] @Ids of PetConfigCell
---@param heroHPs boolean[] @is Combatable
---@param petHPs boolean[] @is Combatable
---@return ModelViewData
function UI3DTroopModelViewHelper.CreateTroopViewData(heroCfgIds,petCgfIds,heroHPs,petHPs)
    if not heroCfgIds then return nil,nil end

    ---@type string[]
    local heroPathes = {}
    ---@type number[]
    local heroScalees = {}
    ---@type number[]
    local heroCircleTypes = {}
    ---@type number[]
    local heroJobTypes = {}
    ---@type string[]
    local petPathes = {}
    ---@type number[]
    local petScales = {}
    ---@type number[]
    local petCircleTypes = {}

    for i = 1, MAX_HERO_COUNT do
        local heroCfgId = heroCfgIds[i]
        ---@type HeroesConfigCell
        local heroConfig = heroCfgId and ConfigRefer.Heroes:Find(heroCfgIds[i]) or nil
        local heroModel = nil
        local heroScale = 1
        local heroType = -1
        local heroJob = -1
        if heroConfig then
            ---@type SeNpcConfigCell
            local heroSeConfig = ConfigRefer.SeNpc:Find(heroConfig:SeNpcCfgId())
            ---@type ArtResourceConfigCell
            local heroArtRes = nil

            if heroSeConfig then
                heroArtRes = ConfigRefer.ArtResource:Find(heroSeConfig:Model())
            end
            if heroArtRes then
                heroModel = heroArtRes:Path()
                heroScale = heroArtRes:ModelScale()
            end
            heroType = heroConfig:Quality() + 1
            heroJob = heroConfig:BattleType()

        end
        heroPathes[i] = heroModel
        heroScalees[i] = heroScale
        heroCircleTypes[i] = heroType
        heroJobTypes[i] = heroJob
    end

    for i = 1, MAX_HERO_COUNT do
        local petCfgId = petCgfIds[i]
        ---@type PetConfigCell
        local petConfig = petCfgId and ConfigRefer.Pet:Find(petCgfIds[i]) or nil
        local petModel = nil
        local petScale = 1
        if petConfig then
            ---@type SeNpcConfigCell
            local petSeConfig = ConfigRefer.SeNpc:Find(petConfig:SeNpcId())
            ---@type ArtResourceConfigCell
            local petArtRes = nil

            if petSeConfig then
                petArtRes = ConfigRefer.ArtResource:Find(petSeConfig:Model())
            end
            if petArtRes then
                petModel = petArtRes:Path()
                petScale = petArtRes:ModelScale()
            end
        end
        petPathes[i] = petModel
        petScales[i] = petScale
        petCircleTypes[i] = petConfig and (petConfig:Quality() + 1) or 0
    end
    ---@type ModelViewData
    local ret =  {}
    ret.heroPathList = heroPathes
    ret.heroScaleList = heroScalees
    ret.heroCircleTypeList = heroCircleTypes
    ret.heroJobTypeList = heroJobTypes
    ret.petPathList = petPathes
    ret.petScaleList = petScales
    ret.petCircleTypeList = petCircleTypes
    ret.heroHPs = heroHPs
    ret.petHPs = petHPs
    return ret
end



---@param data ModelViewData
---@param type number @UI3DTroopModelViewHelper.ViewType
---@return ModelSetupData
function UI3DTroopModelViewHelper.GenModelData(data, type)
    ---@type ModelSetupData
    local retData = {}
    if type == UI3DTroopModelViewHelper.ViewType.Hero then
        retData.isHero = true
        if data then
            retData.pathes = data.heroPathList or {}
            retData.scale = data.heroScaleList or {}
            retData.ringTypes = data.heroCircleTypeList or {}
            retData.jobTypes = data.heroJobTypeList or {}
            if data.heroHPs then
                retData.anims = {}
                for i = 1, #data.heroHPs do
                    if data.heroHPs[i] then
                        retData.anims[i] = 'idle'
                    else
                        retData.anims[i] = 'death_loop'
                    end
                end
            end
        else
            retData.pathes = {}
            retData.scale = {}
            retData.ringTypes = {}
            retData.jobTypes = {}
        end


    elseif type == UI3DTroopModelViewHelper.ViewType.Pet then
        retData.isHero = false
        if data then
            retData.pathes = data.petPathList or {}
            retData.scale = data.petScaleList or {}
            retData.ringTypes = data.petCircleTypeList or {}
            if data.petHPs then
                retData.anims = {}
                for i = 1, #data.petHPs do
                    if data.petHPs[i] then
                        retData.anims[i] = 'idle'
                    else
                        retData.anims[i] = 'stun'
                    end
                end
            end
        else
            retData.pathes = {}
            retData.scale = {}
            retData.ringTypes = {}
        end
    end

    return retData
end

return UI3DTroopModelViewHelper