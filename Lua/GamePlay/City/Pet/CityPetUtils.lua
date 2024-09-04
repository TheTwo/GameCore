local PetWorkType = require("PetWorkType")
local I18N = require("I18N")
local PetQuality = require("PetQuality")
local CityPetUtils = {}

function CityPetUtils.GetFeatureIcon(feature)
    if feature == PetWorkType.Handwork then
        return "sp_common_icon_make"
    elseif feature == PetWorkType.Woodcutting then
        return "sp_common_icon_wood"
    elseif feature == PetWorkType.Mining then
        return "sp_common_icon_stone"
    elseif feature == PetWorkType.Collect then
        return "sp_common_icon_collect"
    elseif feature == PetWorkType.Fire then
        return "sp_common_icon_fire"
    elseif feature == PetWorkType.Watering then
        return "sp_common_icon_water"
    elseif feature == PetWorkType.AnimalHusbandry then
        return "sp_common_icon_livestock"
    end
    return string.Empty
end

function CityPetUtils.GetFeatureName(feature)
    return I18N.Get("animal_work_type_0"..feature)
end

---@param quality number
function CityPetUtils.GetQualityName(quality)
    if quality == PetQuality.LV1 then
        return I18N.Get("equip_quality2_colorless")
    elseif quality == PetQuality.LV2 then
        return I18N.Get("equip_quality3_colorless")
    elseif quality == PetQuality.LV3 then
        return I18N.Get("equip_quality4_colorless")
    elseif quality == PetQuality.LV4 then
        return I18N.Get("equip_quality5_colorless")
    end
    return string.Empty
end

return CityPetUtils