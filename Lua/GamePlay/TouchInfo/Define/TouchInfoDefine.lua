local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local TouchInfoDefine = {}

function TouchInfoDefine.OnConfigLoaded()
    TouchInfoDefine.ButtonIcons = {
        IconBuild = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_build),
        IconHome = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_common_icon_home),
        IconFurnitureFunction = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_process),
        IconIndoorEdit = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_interior_edit),
        IconStorage = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_troop_icon_storage),
        IconSESkillCard = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_skillcard),
        IconHeroEquip = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_equip),
        IconClearZone = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_clear),
        IconGetNewResident = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_new_resident),

        IconClearKernel = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_clear_02),
        IconResearch = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_science),
        IconScout = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_status_scout),
        IconUpgrade = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_upgrade),
        IconBuild2 = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_build_02),
        IconInvite = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_invite),
        IconGoto = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_goto),
        IconRebuild = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_rebuild),
        IconHelpBuild = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_help_build),
        IconGather = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_gather),
        IconMessageOfWar = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_message_war),
        IconDefense = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_defense),
        IconHelp = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_common_icon_help),
    }
    
    TouchInfoDefine.ButtonBacks = {
        BackNormal = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_btn_circle_main),
        BackWarn = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_btn_circle_negtive),
        BackGray = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_btn_circle_grey),
        BackRecommend = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_btn_circle_confirm),
    }
end

return TouchInfoDefine