local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require("UIMediatorNames")
local CityCreepNodeCircleMenuHelper = require("CityCreepNodeCircleMenuHelper")
local MapPollutionItem = class('MapPollutionItem',BaseUIComponent)

function MapPollutionItem:OnCreate(param)
    self.btnArea = self:Button('', Delegate.GetOrCreate(self, self.OnBtnPollutionClicked))
    self.goGroupPollution = self:GameObject('p_group_pollution')
end

function MapPollutionItem:OnFeedData(pollutionInfo)
    self.pollutionInfo = pollutionInfo
    self.goGroupPollution.transform.localPosition = CS.UnityEngine.Vector3(pollutionInfo.x, pollutionInfo.y, 0)
end

function MapPollutionItem:OnBtnPollutionClicked()
    local city = ModuleRefer.CityModule.myCity
    local cellTile = city.gridView:GetCellTile(self.pollutionInfo.pos:X(), self.pollutionInfo.pos:Y())
    local cell = cellTile:GetCell()
    if cell == nil then
        return
    end
    local param = cellTile:GetTouchInfoData()
    param.otherFunc = function()
        local worldPos = city:GetWorldPositionFromCoord(self.pollutionInfo.pos:X(), self.pollutionInfo.pos:Y())
        city.camera:LookAt(worldPos, 0.5)
        g_Game.UIManager:CloseByName("UICityMapMediator")
    end
    g_Game.UIManager:Open(UIMediatorNames.UICityAreaProgressMediator, param)
end

return MapPollutionItem
