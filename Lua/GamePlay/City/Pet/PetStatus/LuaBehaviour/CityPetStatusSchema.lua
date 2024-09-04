local CityPetStatusSchema = {
    {"p_rotation", typeof(CS.UnityEngine.Transform)},
    {"p_position", typeof(CS.UnityEngine.Transform)},

    {"p_emoji", typeof(CS.UnityEngine.Transform)},
    {"p_icon_emoji", typeof(CS.U2DSpriteMesh)},
    
    {"p_eating", typeof(CS.UnityEngine.Transform)},
    {"p_icon_food", typeof(CS.U2DSpriteMesh)},
    {"p_progress_eating", typeof(CS.U2DSpriteMesh)},
    
    {"p_progress", typeof(CS.UnityEngine.Transform)},
    {"p_progress_1", typeof(CS.U2DSpriteMesh)},
    
    {"p_popup_food", typeof(CS.UnityEngine.Transform)},
    {"p_icon_food_need", typeof(CS.U2DSpriteMesh)},

    {"p_text_name", typeof(CS.U2DTextMesh)},
}
return CityPetStatusSchema