local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require("UIMediatorNames")
local I18N = require('.I18N')
local MapAreaItem = class('MapAreaItem',BaseUIComponent)

function MapAreaItem:OnCreate(param)
    self.btnArea = self:Button('', Delegate.GetOrCreate(self, self.OnBtnAreaClicked))
    self.goImgSelect = self:GameObject('p_img_select')
    self.sliderProgressArea = self:Slider('p_progress_area')
end

function MapAreaItem:OnBtnAreaClicked(args)
    local city = ModuleRefer.CityModule.myCity
    local cellTile = city.gridView:GetCellTile(self.areaInfo.pos:X(), self.areaInfo.pos:Y())
    local param = cellTile:GetTouchInfoData()
    local cell = cellTile:GetCell()
    if cell == nil then
        return
    end
    if not cellTile:GetCity().zoneManager:IsZoneRecovered(cell.x, cell.y) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Temp().toast_need_unlock_fog)
        return
    end
    param.otherFunc = function()
        local worldPos = city:GetWorldPositionFromCoord(self.areaInfo.pos:X(), self.areaInfo.pos:Y())
        city.camera:LookAt(worldPos, 0.5)
        g_Game.UIManager:CloseByName("UICityMapMediator")
    end
    g_Game.UIManager:Open(UIMediatorNames.UICityAreaProgressMediator, param)
end

function MapAreaItem:OnFeedData(areaInfo)
    self.areaInfo = areaInfo
    self.btnArea.gameObject.transform.localPosition = CS.UnityEngine.Vector3(areaInfo.x, areaInfo.y, 0)
    local city = ModuleRefer.CityModule.myCity
    self.sliderProgressArea.value = city.zoneManager:GetRecoverProgressByElementDataId(areaInfo.id)
end

return MapAreaItem
