---@class PvPTileAssetHUDConstructionSchema
---@field new fun():PvPTileAssetHUDConstructionSchema
local PvPTileAssetHUDConstructionSchema = {
    {"facingCamera", typeof(CS.U2DFacingCamera)},

    {"goDurability", typeof(CS.UnityEngine.GameObject)},
    {"sliderProgressNormal", typeof(CS.U2DSlider)},
    {"textProgress", typeof(CS.U2DTextMesh)},
    
    {"goTroopQuantity", typeof(CS.UnityEngine.GameObject)},
    {"textTroopQuantity", typeof(CS.U2DTextMesh)},
    
    {"goStateTime", typeof(CS.UnityEngine.GameObject)},
    {"textStateTime", typeof(CS.U2DTextMesh)},
    {"imgStateIcon",typeof(CS.U2DSpriteMesh)},

    {"allianceLogo", typeof(CS.DragonReborn.LuaBehaviour)},
    {"verticalLayoutGroup", typeof(CS.UnityEngine.UI.VerticalLayoutGroup)},

    {"goTitle", typeof(CS.UnityEngine.GameObject)},
    {"textTitle", typeof(CS.U2DTextMesh)},
    {"imgIcon",typeof(CS.U2DSpriteMesh)},
    {"imgTitle_l",typeof(CS.U2DSpriteMesh)},
    {"imgTitle",typeof(CS.U2DSpriteMesh)},
    {"imgTitle_r",typeof(CS.U2DSpriteMesh)},
}

return PvPTileAssetHUDConstructionSchema
