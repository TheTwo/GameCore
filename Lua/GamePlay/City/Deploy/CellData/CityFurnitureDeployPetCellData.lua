local CityFurnitureDeployCellData = require("CityFurnitureDeployCellData")
---@class CityFurnitureDeployPetCellData:CityFurnitureDeployCellData
---@field new fun():CityFurnitureDeployPetCellData
local CityFurnitureDeployPetCellData = class("CityFurnitureDeployPetCellData", CityFurnitureDeployCellData)

function CityFurnitureDeployPetCellData:GetPrefabIndex()
    return 0
end

---@return number @0未解锁 1未驻派 2已驻派
function CityFurnitureDeployPetCellData:GetStatus()
    ---override this
    return 0
end

---@return boolean
function CityFurnitureDeployPetCellData:IsShowLockCondition()
    ---override this
    return false
end

---@return string
function CityFurnitureDeployPetCellData:GetLockConditionStr()
    ---override this
    return nil
end

---@return boolean
function CityFurnitureDeployPetCellData:IsShowLockTime()
    ---override this
    return false
end

---@return string
function CityFurnitureDeployPetCellData:GetLockTimeStr()
    ---override this
    return nil
end

---@return boolean
function CityFurnitureDeployPetCellData:IsShowNonDeployTime()
    ---override this
    return false
end

---@return string
function CityFurnitureDeployPetCellData:GetNonDeployTimeStr()
    ---override this
    return nil
end

---@return string
function CityFurnitureDeployPetCellData:GetPetName()
    ---override this
    return nil
end

---@return string
function CityFurnitureDeployPetCellData:GetDeployTimeStr()
    ---override this
    return nil
end

---@return CommonPetIconBaseData
function CityFurnitureDeployPetCellData:GetPetData()
    ---override this
    return nil
end

---@param cell CityFurnitureDeployUIPetCell
function CityFurnitureDeployPetCellData:OnClick(cell)
    ---override this
end

---@param cell CityFurnitureDeployUIPetCell
function CityFurnitureDeployPetCellData:OnClickDelete(cell)
    ---override this
end

function CityFurnitureDeployPetCellData:ShowDeleteButton()
    ---override this
    return false
end

function CityFurnitureDeployPetCellData:IsLandNotFit()
    return false
end

function CityFurnitureDeployPetCellData:IsShowShare()
    return false
end

return CityFurnitureDeployPetCellData