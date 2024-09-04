---@class CircleMenuTextureNames
local CircleMenuButtonConfig = {}
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceUIConsts = require("ArtResourceUIConsts")

function CircleMenuButtonConfig.OnConfigLoaded()
    CircleMenuButtonConfig.ButtonIcons = {
        IconStrength = "sp_comp_icon_power",
        IconTime = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_common_icon_time_01),
        IconToggle = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_common_icon_toggle),
        IconCancel = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_icon_cancel),
        IconTick = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_icon_tick),
        IconStorage = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_icon_storage),
        IconInteriorEdit = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_interior_edit),
        IconInfo = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_common_icon_details),
        IconRotate = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_common_btn_set),
        ---Troop Circle Menu
        IconTroopCamp = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_troop_icon_a),
        IconTroopDialog = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_troop_icon_b),
        IconTroopBackArraw = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_troop_icon_c),
        IconTroopInfo = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_troop_icon_d),
        IconTroopAtt = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_troop_icon_attack),

        IconMark = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_mark),
        IconUnmark = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_comp_icon_unmark),
    }
    
    CircleMenuButtonConfig.ButtonBacks = {
        BackNegtive = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_btn_circle_negtive),
        BackMain = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_btn_circle_main),
        BackConfirm = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_btn_circle_confirm),
        BackGray = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_btn_circle_sec),
        ---Troop Circle Menu
        BackConfirm = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_btn_circle_confirm),
        BackMain  = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_btn_circle_main),
        BackNegtive = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_btn_circle_negtive),
        BackNormal = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_btn_circle_sec),
        BackSec = "sp_btn_circle_sec"
    }
    
end

return CircleMenuButtonConfig