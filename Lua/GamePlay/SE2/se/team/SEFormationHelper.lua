local ConfigRefer = require("ConfigRefer")
local SEFormationHelper = {}
local FORMATION_TYPE = {
    SINGLE = 1,
    DOUBLE_LEFT_RIGHT = 2,
    DOUBLE_FRONT_BACK = 3,
    TRIPLE_TRIANGLE = 4,
    TRIPLE_INVERSE_TRIANGLE = 5,

    NEW_DOUBLE = 6,
    NEW_TRIPLE = 7,
}
local FORMATION_IDX = {
    FIRST = 1,
    SECOND = 2,
    THIRD = 3,
}
local PET_OFFSET_BASE = {
    BL = {-0.707, -0.707},
    BR = {0.707, -0.707}
}
local FORMATION_HERO_OFFSET_BASE = {
    [FORMATION_TYPE.SINGLE] = {
        [FORMATION_IDX.FIRST] = {0, 0, PET_OFFSET_BASE.BR}
    },
    [FORMATION_TYPE.DOUBLE_LEFT_RIGHT] = {
        [FORMATION_IDX.FIRST] = {-1, 0, PET_OFFSET_BASE.BL},
        [FORMATION_IDX.SECOND] = {1, 0, PET_OFFSET_BASE.BR},
    },
    [FORMATION_TYPE.DOUBLE_FRONT_BACK] = {
        [FORMATION_IDX.FIRST] = {0, 1, PET_OFFSET_BASE.BR},
        [FORMATION_IDX.SECOND] = {0, -1, PET_OFFSET_BASE.BR},
    },
    [FORMATION_TYPE.TRIPLE_TRIANGLE] = {
        [FORMATION_IDX.FIRST] = {0, 1, PET_OFFSET_BASE.BR},
        [FORMATION_IDX.SECOND] = {-0.707, -0.707, PET_OFFSET_BASE.BL},
        [FORMATION_IDX.THIRD] = {0.707, -0.707, PET_OFFSET_BASE.BR},
    },
    [FORMATION_TYPE.TRIPLE_INVERSE_TRIANGLE] = {
        [FORMATION_IDX.FIRST] = {-0.707, 0.707, PET_OFFSET_BASE.BL},
        [FORMATION_IDX.SECOND] = {0.707, 0.707, PET_OFFSET_BASE.BR},
        [FORMATION_IDX.THIRD] = {0, -1, PET_OFFSET_BASE.BR},
    },
    [FORMATION_TYPE.NEW_DOUBLE] = {
        [FORMATION_IDX.FIRST] = {0, 0, PET_OFFSET_BASE.BR},
        [FORMATION_IDX.SECOND] = {0, -2, PET_OFFSET_BASE.BR},
    },
    [FORMATION_TYPE.NEW_TRIPLE] = {
        [FORMATION_IDX.FIRST] = {0, 0, PET_OFFSET_BASE.BR},
        [FORMATION_IDX.SECOND] = {-0.707, -1.707, PET_OFFSET_BASE.BL},
        [FORMATION_IDX.THIRD] = {0.707, -1.707, PET_OFFSET_BASE.BR},
    }
}
local PET_NON_MASTER_OFFSET_BASE = {
    [1] = {
        [FORMATION_IDX.FIRST] = {0, -2}
    },
    [2] = {
        [FORMATION_IDX.FIRST] = {-0.707, -2},
        [FORMATION_IDX.SECOND] = {0.707, -2},
    },
    [3] = {
        [FORMATION_IDX.FIRST] = {-0.707, -2},
        [FORMATION_IDX.SECOND] = {0, -2},
        [FORMATION_IDX.THIRD] = {0.707, -2},
    },
}

---@param heroCount number
---@param meleeHeroCount number
---@param orderHeroes SEHero[] @被排序过的英雄列表, 近战在前远程在后, 同类型按照Preset中所在数组位置排序
function SEFormationHelper.GetMatchFormationData(heroCount, meleeHeroCount, orderHeroes, useNewFormation)
    local formationOffsetBase = nil
    if heroCount == 1 then
        formationOffsetBase = FORMATION_HERO_OFFSET_BASE[FORMATION_TYPE.SINGLE]
    elseif heroCount == 2 then
        if useNewFormation then
            formationOffsetBase = FORMATION_HERO_OFFSET_BASE[FORMATION_TYPE.NEW_DOUBLE]
        else
            if meleeHeroCount == 1 then
                formationOffsetBase = FORMATION_HERO_OFFSET_BASE[FORMATION_TYPE.DOUBLE_FRONT_BACK]
            elseif meleeHeroCount == 0 or meleeHeroCount == 2 then
                formationOffsetBase = FORMATION_HERO_OFFSET_BASE[FORMATION_TYPE.DOUBLE_LEFT_RIGHT]
            end
        end
    elseif heroCount == 3 then
        if useNewFormation then
            formationOffsetBase = FORMATION_HERO_OFFSET_BASE[FORMATION_TYPE.NEW_TRIPLE]
        else
            if meleeHeroCount == 0 or meleeHeroCount == 1 then
                formationOffsetBase = FORMATION_HERO_OFFSET_BASE[FORMATION_TYPE.TRIPLE_TRIANGLE]
            elseif meleeHeroCount == 2 or meleeHeroCount == 3 then
                formationOffsetBase = FORMATION_HERO_OFFSET_BASE[FORMATION_TYPE.TRIPLE_INVERSE_TRIANGLE]
            end
        end
    end

    if formationOffsetBase == nil then
        g_Logger.WarnChannel("SEFormationHelper", "Invalid hero count %s or meleeHeroCount %s", heroCount, meleeHeroCount)
        return nil
    end

    return SEFormationHelper.PostFormationBase(formationOffsetBase, orderHeroes)
end

---@param orderHeroes SEHero[] @被排序过的英雄列表, 近战在前远程在后, 同类型按照Preset中所在数组位置排序
function SEFormationHelper.PostFormationBase(formationOffsetBase, orderHeroes)
    if #orderHeroes ~= #formationOffsetBase then
        g_Logger.WarnChannel("SEFormationHelper", "Invalid hero count %s", #orderHeroes)
        return nil
    end

    local radius = ConfigRefer.ConstSe:SEHeroFormationDis()
    local petRadius = ConfigRefer.ConstSe:SEPetFormationDis()
    local offsetMap = {}
    for i, seHero in ipairs(orderHeroes) do
        local base = formationOffsetBase[i]
        local heroXBase, heroYBase = base[1], base[2]
        local petBase = base[3]
        local petXBase, petYBase = petBase[1], petBase[2]
        offsetMap[seHero._id] = {x = heroXBase * radius, y = heroYBase * radius, petOffsetX = petXBase * petRadius, petOffsetY = petYBase * petRadius}
    end

    return offsetMap
end

---@param nonMasterOrderPets SEPet[] @被排序过的无主宠列表, 按照Preset中所在数组位置排序
function SEFormationHelper.GetNonMasterPetOffsets(nonMasterOrderPets)
    local formationOffsetBase = PET_NON_MASTER_OFFSET_BASE[#nonMasterOrderPets]
    if not formationOffsetBase then return nil end

    local radius = ConfigRefer.ConstSe:SEPetDeadMasterFormationDis()
    local offsetMap = {}
    for i, sePet in ipairs(nonMasterOrderPets) do
        local base = formationOffsetBase[i]
        local xbase, ybase = base[1], base[2]
        offsetMap[sePet._id] = {x = xbase * radius, y = ybase * radius}
    end
    return offsetMap
end

---@param p1 CS.UnityEngine.Vector2
---@param d1 CS.UnityEngine.Vector2
---@param p2 CS.UnityEngine.Vector2
---@param d2 CS.UnityEngine.Vector2
function SEFormationHelper.IsRaysIntersecting(p1, d1, p2, d2)
    local det = d1.x * d2.y - d1.y * d2.x
    if det == 0 then
        return false, nil
    end

    local t1 = (d2.y * (p2.x - p1.x) - d2.x * (p2.y - p1.y)) / det
    local t2 = (d1.y * (p2.x - p1.x) - d1.x * (p2.y - p1.y)) / det
    return t1 >= 0 and t2 >= 0, p1 + d1 * t1
end

return SEFormationHelper