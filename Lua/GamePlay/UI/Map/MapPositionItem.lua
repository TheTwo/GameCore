local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local MapPositionItem = class('MapPositionItem',BaseUIComponent)
local Delegate = require('Delegate')

function MapPositionItem:OnCreate(param)
    self.btnPosition = self:Button('', Delegate.GetOrCreate(self, self.OnBtnPositionClicked))
end

function MapPositionItem:OnBtnPositionClicked(args)
    local city = ModuleRefer.CityModule.myCity
    local worldPos = city:GetWorldPositionFromCoord(self.positionInfo.x, self.positionInfo.y)
    city.camera:LookAt(worldPos, 0.5)
    g_Game.UIManager:CloseByName("UICityMapMediator")
end

function MapPositionItem:OnFeedData(positionInfo)
    self.positionInfo = positionInfo
end

return MapPositionItem
