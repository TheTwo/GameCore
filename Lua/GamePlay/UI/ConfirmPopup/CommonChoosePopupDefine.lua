---@class CommonChoosePopupDefine
local CommonChoosePopupDefine = {}
local UIHelper = require('UIHelper')

---@class CommonChoosePopupDefine.FilterEnum
CommonChoosePopupDefine.FilterEnum = {
    Common = 0,
    Personalise = 1,     --收藏界面    
}

---@class CommonChoosePopupDefine.ChooseType
CommonChoosePopupDefine.ChooseType = {
    Single = 1,     --单选
    Multiple = 2,   --多选
}

---@class CommonChoosePopupDefine.ChooseStyle
CommonChoosePopupDefine.ChooseStyle = {
    Dot = 1,        --点
    Tick = 2,       --√
}

CommonChoosePopupDefine.FilterTypeOffset = {
    Own = 0,
    Quality = 3,
    HeroBattleType = 7,
    HeroAssociatedTag = 10,
}

---@class CommonChoosePopupDefine.SubFilterLength
CommonChoosePopupDefine.SubFilterLength = {
    3,      --Own
    4,      --Quality
    3,      --HeroBattleType
    3,      --HeroAssociatedTag
}

---@class CommonChoosePopupDefine.FilterType
CommonChoosePopupDefine.FilterType = {
    Own = 1 << 0,        --是否拥有(3种)
    Quality = 1 << 3,    --品质(4种)
    HeroBattleType = 1 << CommonChoosePopupDefine.FilterTypeOffset.HeroBattleType,    --职业(3种)
    HeroAssociatedTag = 1 << CommonChoosePopupDefine.FilterTypeOffset.HeroAssociatedTag,    --羁绊标签(3种)
}

---@class CommonChoosePopupDefine.OwnSubFilterType
CommonChoosePopupDefine.OwnSubFilterType = {
    All = CommonChoosePopupDefine.FilterType.Own << 0,
    Owned = CommonChoosePopupDefine.FilterType.Own << 1,
    NotOwned = CommonChoosePopupDefine.FilterType.Own << 2,
}

---@class CommonChoosePopupDefine.OwnSubFilterTypeName
CommonChoosePopupDefine.OwnSubFilterTypeName = {
    "skincollection_ownstate_all",
    "skincollection_owned",
    "skincollection_notowned",
}

---@class CommonChoosePopupDefine.QualitySubFilterTypeName
CommonChoosePopupDefine.QualitySubFilterTypeName = {
    "skincollection_rarity4",
    "skincollection_rarity3",
    "skincollection_rarity2",
    "skincollection_rarity1",
}

---@class CommonChoosePopupDefine.QualitySubFilterTypeColor
CommonChoosePopupDefine.QualitySubFilterTypeColor = {
    "#f9751c",
    "#b259e6",
    "#4a8ddf",
    "#488a02",
}


CommonChoosePopupDefine.HeroBattleTypeSubFilterTypeName = {
    "hero_type_tank", --BattleLabel.Tank
    "hero_type_output", --BattleLabel.Damage
    "hero_type_gain", --BattleLabel.Support
}


CommonChoosePopupDefine.HeroBattleTypeSubFilterTypeIcon = {
    "sp_comp_icon_suit_05", --BattleLabel.Tank
    "sp_comp_icon_suit_04", --BattleLabel.Damage
    "sp_comp_icon_support", --BattleLabel.Support
}


CommonChoosePopupDefine.HeroBattleTypeSubFilterTypeColor = {
    "#f9751c",
    "#b259e6",
    "#4a8ddf",
}

CommonChoosePopupDefine.HeroAssociatedTagSubFilterTypeName = {
    "hero_type_strengh", --TagType.TagTypeStrength
    "hero_type_intelligent", --TagType.TagTypeIntelligence
    "hero_type_skill", --TagType.TagTypeSkill
}

CommonChoosePopupDefine.HeroAssociatedTagSubFilterTypeIcon = {
    "sp_comp_icon_strength", --TagType.TagTypeStrength
    "sp_comp_icon_intellect", --TagType.TagTypeIntelligence
    "sp_comp_icon_trick", --TagType.TagTypeSkill
}

CommonChoosePopupDefine.HeroAssociatedTagSubFilterTypeColor = {
    "#f9751c",
    "#b259e6",
    "#4a8ddf",
}

return CommonChoosePopupDefine