local CityCitizenManageV3UIParameter = require("CityCitizenManageV3UIParameter")
local CityCitizenManageV3PageData = require("CityCitizenManageV3PageData")
local UIMediatorNames = require("UIMediatorNames")

local CityCitizenManageV3Helper = {}

---@param city City
function CityCitizenManageV3Helper.ShowUI_Homeless(city, onCitizenSelect)
    ---@param citizenData CityCitizenData
    local filterFunc = function(citizenData)
        return citizenData._houseId == 0
    end
    local param = CityCitizenManageV3UIParameter.new(city, filterFunc)
    param.onCitizenSelect = onCitizenSelect
    g_Game.UIManager:Open(UIMediatorNames.CityCitizenManageV3UIMediator, param)
end

return CityCitizenManageV3Helper