local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local MapBuildingItem = class('MapBuildingItem',BaseUIComponent)

function MapBuildingItem:OnCreate(param)
    self.goGroupBuildling = self:GameObject('')
    self.btnTipsBuilding = self:Button('p_btn_tips_building', Delegate.GetOrCreate(self, self.OnBtnTipsBuildingClicked))
    self.imgIconBuildling = self:Image('p_icon_buildling')
end

function MapBuildingItem:OnBtnTipsBuildingClicked(args)

end

function MapBuildingItem:OnFeedData(buildingInfo)
    self.goGroupBuildling.transform.localPosition = CS.UnityEngine.Vector3(buildingInfo.x, buildingInfo.y, 0)
    g_Game.SpriteManager:LoadSprite(buildingInfo.cell:Image(), self.imgIconBuildling)
end

return MapBuildingItem
