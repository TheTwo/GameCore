local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local MapExploreItem = class('MapExploreItem',BaseUIComponent)

function MapExploreItem:OnCreate(param)
    self.goGroupExpore = self:GameObject('')
    self.goImgHero = self:GameObject('p_img_hero')
    self.goLine = self:GameObject("p_line")
end


function MapExploreItem:OnFeedData(exploreInfo)
   self.goGroupExpore.transform.localPosition = CS.UnityEngine.Vector3(exploreInfo.x, exploreInfo.y, 0)
   if exploreInfo.tx and exploreInfo.ty then
        local offsetX = exploreInfo.tx - exploreInfo.x
        local offsetY = exploreInfo.ty - exploreInfo.y
        self.goLine.transform.localPosition = CS.UnityEngine.Vector3(offsetX / 2, offsetY / 2, 0)
        self.goLine.transform.sizeDelta = CS.UnityEngine.Vector2(math.sqrt(offsetX * offsetX + offsetY * offsetY), 5)
        local xRad = CS.UnityEngine.Mathf.Atan2(offsetY, offsetX)
        local rotation = xRad / math.pi * 180
        self.goLine.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, rotation)
        self.goLine:SetActive(true)
   else
        self.goLine:SetActive(false)
   end
end

return MapExploreItem
