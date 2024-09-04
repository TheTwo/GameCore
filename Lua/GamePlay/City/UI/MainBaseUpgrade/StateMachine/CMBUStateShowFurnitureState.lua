local CMBUState = require("CMBUState")
---@class CMBUStateShowFurnitureState:CMBUState
---@field new fun():CMBUStateShowFurnitureState
local CMBUStateShowFurnitureState = class("CMBUStateShowFurnitureState", CMBUState)
local I18N = require("I18N")

function CMBUStateShowFurnitureState:Enter()
    self:AppendTableCell()
end

function CMBUStateShowFurnitureState:AppendTableCell()
    if self.uiMediator.lvCfg:FurnitureLevelMapLength() == 0 then
        return
    end

    local data = {content = I18N.Get("city_main_bui_upgrade_effect_2")}
    self.uiMediator._p_table_content:AppendData(data, 0)
    local data = {lvCfg = self.uiMediator.lvCfg}
    self.uiMediator._p_table_content:AppendData(data, 2)
    self.uiMediator._p_table_content:SetDataVisable(data, CS.TableViewPro.MoveSpeed.Normal)
end

function CMBUStateShowFurnitureState:OnContinueClick()
    self.uiMediator:BackToPrevious()
end

return CMBUStateShowFurnitureState