local Utils = require("Utils")
local KingdomMapUtils = require("KingdomMapUtils")

---@class AllianceWarBuildingCellData
---@field new fun(id:number,type:number):AllianceWarBuildingCellData
local AllianceWarBuildingCellData = class('AllianceWarBuildingCellData')

function AllianceWarBuildingCellData:ctor(id, type)
    self._id = id
    self._type = type
end

---@return number
function AllianceWarBuildingCellData:GetId()
    return self._id
end

---@return number
function AllianceWarBuildingCellData:GetType()
    return self._type
end

---@return {allianceId:number, abbr:string, name:string}|nil
function AllianceWarBuildingCellData:GetSourceInfo()
    return nil
end

---@return number|nil
function AllianceWarBuildingCellData:GetDistance()
    return nil
end

---@return boolean
function AllianceWarBuildingCellData:UseTick()
    return false
end

---@return boolean
function AllianceWarBuildingCellData:IsAttack()
    return true
end

---@return nil|number, number
function AllianceWarBuildingCellData:GetPos()
    return nil
end

---@return string
function AllianceWarBuildingCellData:GetTargetName()
    return string.Empty
end

---@return string
function AllianceWarBuildingCellData:GetTargetIcon()
    return string.Empty
end

---@return nil|number
function AllianceWarBuildingCellData:GetLv()
    return nil
end

---@return string
function AllianceWarBuildingCellData:GetStatusName(nowTime)
    return string.Empty
end

---@return number
function AllianceWarBuildingCellData:GetEndTime()
    return 2147483647
end

---@return string
function AllianceWarBuildingCellData:GetProgressValueSting(nowTime)
    return string.Empty
end

---@return number
function AllianceWarBuildingCellData:GetProgress(nowTime)
    return 0
end

---@return boolean
function AllianceWarBuildingCellData:ShowJoin()
    return false
end

---@return boolean
function AllianceWarBuildingCellData:ShowQuit()
    return false
end

function AllianceWarBuildingCellData:OnClickQuit()
    
end

function AllianceWarBuildingCellData:OnClickJoin()
    
end

function AllianceWarBuildingCellData:OnClickEscrowTip()
    
end

function AllianceWarBuildingCellData:UpdateData(payload, isUnderAttack)
    
end

---@return boolean
function AllianceWarBuildingCellData:NeedEscrowInfoUpdated()
    return false
end

function AllianceWarBuildingCellData:EscrowInfoUpdated()
    
end

---@param root CS.UnityEngine.GameObject
---@param title CS.UnityEngine.UI.Text
---@param icon1 CS.UnityEngine.UI.Image
---@param value1 CS.UnityEngine.UI.Text
---@param icon2 CS.UnityEngine.UI.Image
---@param value2 CS.UnityEngine.UI.Text
function AllianceWarBuildingCellData:SetUpExtraInfo(root, title, icon1, value1, icon2, value2)
    if Utils.IsNotNull(root) then
        root:SetVisible(false)
    end
end

---@param root CS.UnityEngine.GameObject
---@param icon CS.UnityEngine.UI.Image
---@param text CS.UnityEngine.UI.Text
---@param btn CS.UnityEngine.UI.Button
function AllianceWarBuildingCellData:SetUpEscrowPart(root, icon, text, btn)
    if Utils.IsNotNull(root) then
        root:SetVisible(false)
    end
end

function AllianceWarBuildingCellData:IsTargetBehemothCage()
    return false
end

return AllianceWarBuildingCellData