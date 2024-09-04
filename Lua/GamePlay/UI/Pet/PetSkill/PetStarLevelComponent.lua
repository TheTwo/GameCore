local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')

---@class PetStarLevelComponent : BaseTableViewProCell
---@field data HeroConfigCache
local PetStarLevelComponent = class('PetStarLevelComponent', BaseTableViewProCell)

function PetStarLevelComponent:ctor()

end

function PetStarLevelComponent:OnCreate()
    ---@type PetSkillStarGroup
    self.child_pet_star_l_1 = self:LuaObject('child_pet_star_l_1')

    ---@type PetSkillStarGroup
    -- UE名字不统一
    if self.child_pet_star_l_1 == nil then
        self.child_pet_star_l_1 = self:LuaObject('p_pet_star_1')
        self.child_pet_star_l_2 = self:LuaObject('p_pet_star_2')
        self.child_pet_star_l_3 = self:LuaObject('p_pet_star_3')
        self.child_pet_star_l_4 = self:LuaObject('p_pet_star_4')
        self.child_pet_star_l_5 = self:LuaObject('p_pet_star_5')
        self.child_pet_star_l_6 = self:LuaObject('p_pet_star_6')
    else
        self.child_pet_star_l_1 = self:LuaObject('child_pet_star_l_1')
        self.child_pet_star_l_2 = self:LuaObject('child_pet_star_l_2')
        self.child_pet_star_l_3 = self:LuaObject('child_pet_star_l_3')
        self.child_pet_star_l_4 = self:LuaObject('child_pet_star_l_4')
        self.child_pet_star_l_5 = self:LuaObject('child_pet_star_l_5')
        self.child_pet_star_l_6 = self:LuaObject('child_pet_star_l_6')
    end

    ---@type PetSkillStarGroup[]
    self.stars = {self.child_pet_star_l_1, self.child_pet_star_l_2, self.child_pet_star_l_3, self.child_pet_star_l_4, self.child_pet_star_l_5, self.child_pet_star_l_6}
end

---@class PetStarLevelComponentParam
---@field petId number|nil
---@field skillLevels {level:number, quality:number}[]|nil
---@field playNextStarVfx boolean
---@field showAsGetPet boolean
---@field simpleInit {bigStarCount:number, smallStarInfo:{level:number, quality:number, forceLoad:boolean}[]}

---@param param PetStarLevelComponentParam
function PetStarLevelComponent:OnFeedData(param)
    if param.petId then
        local starLevel, skillLevels = ModuleRefer.PetModule:GetSkillLevelQuality(param.petId)
        self:SetupStarBySkillLevels(skillLevels)
    elseif param.skillLevels then
        self:SetupStarBySkillLevels(param.skillLevels)
    elseif param.simpleInit then
        self:SetupStarBySimpleInit(param.simpleInit)
    end
end

function PetStarLevelComponent:SetupStarBySkillLevels(skillLevels)
    local unlockStar = 0
    -- 每个技能解锁两个星星槽位
    for k, v in pairs(skillLevels) do
        unlockStar = unlockStar + 2
    end

    for i = 1, 6 do
        ---@type PetSkillStarGroupParam
        local data = {start = (i - 1) * 5 + 1, skillLevels = skillLevels}
        self.stars[i]:FeedData(data)

        if i <= unlockStar then
            self.stars[i]:SetLock(false)
        else
            self.stars[i]:SetLock(true)
        end
    end
end

---@param simpleInit {bigStarCount:number, smallStarInfo:{level:number, quality:number, forceLoad:boolean}[]}
function PetStarLevelComponent:SetupStarBySimpleInit(simpleInit)
    local maxCount = math.min(simpleInit.bigStarCount, #self.stars)
    for i = 1, 6 do
        self.stars[i]:SetVisible(maxCount >= i)
        if maxCount >= i then
            ---@type PetSkillStarGroupParam
            local data = simpleInit.smallStarInfo[i]
            if data then
                self.stars[i]:FeedData(data)
                self.stars[i]:SetLock(false)
            else
                self.stars[i]:FeedData({level = 0, forceLoad = true})
                self.stars[i]:SetLock(true)
            end
        end
    end
end

return PetStarLevelComponent
