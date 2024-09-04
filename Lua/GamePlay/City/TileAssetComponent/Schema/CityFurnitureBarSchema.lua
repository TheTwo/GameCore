local CityFurnitureBarSchema = {
    {"p_rotation", typeof(CS.U2DFacingCamera)},

    --- 升级
    {"p_progress_upgrade", typeof(CS.UnityEngine.GameObject)},
    {"p_text_upgrade_time", typeof(CS.U2DTextMesh)},
    {"p_bar_upgrade_n", typeof(CS.U2DSlider)},
    {"p_bar_upgrade_stop", typeof(CS.U2DSlider)},
    
    --- 血条
    {"p_progress", typeof(CS.UnityEngine.GameObject)},
    {"p_bar", typeof(CS.U2DSlider)},

    --- 选中信息
    {"p_info", typeof(CS.UnityEngine.GameObject)},
    {"p_text_lv", typeof(CS.U2DTextMesh)},
    {"p_text_name", typeof(CS.U2DTextMesh)},
}
return CityFurnitureBarSchema