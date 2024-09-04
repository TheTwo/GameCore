local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")
---@class TouchMenuCellSeMonsterDatum:TouchMenuCellDatumBase
---@field new fun():TouchMenuCellSeMonsterDatum
local TouchMenuCellSeMonsterDatum = class("TouchMenuCellSeMonsterDatum", TouchMenuCellDatumBase)

---@param monstersData TMCellSeMonsterDatum[]
---@param infoClick fun()
function TouchMenuCellSeMonsterDatum:ctor(title, monstersData, infoClick)
	self.title = title
    self.monstersData = monstersData
    self.infoClick = infoClick
    self.creepBuffIcon = string.Empty
    self.creepBuff = nil
    ---@type fun(clickTrans:CS.UnityEngine.RectTransform, datum:TouchMenuCellSeMonsterDatum)
    self.onClickCreepBuffIcon = nil
end

function TouchMenuCellSeMonsterDatum:SetTitle(title)
	self.title = title
end

---@param monstersData TMCellSeMonsterDatum[]
---@return TouchMenuCellSeMonsterDatum
function TouchMenuCellSeMonsterDatum:SetMonsterData(monstersData)
    self.monstersData = monstersData
    return self
end

---@param monsterDatum TMCellSeMonsterDatum
---@return TouchMenuCellSeMonsterDatum
function TouchMenuCellSeMonsterDatum:AppendMonsterDatum(monsterDatum)
    self.monstersData = self.monstersData or {}
    table.insert(self.monstersData, monsterDatum)
    return self
end

---@param infoClick fun()
---@return TouchMenuCellSeMonsterDatum
function TouchMenuCellSeMonsterDatum:SetInfoClick(infoClick)
    self.infoClick = infoClick
    return self
end

function TouchMenuCellSeMonsterDatum:GetPrefabIndex()
    return 7
end

---@param onClick fun(clickTrans:CS.UnityEngine.RectTransform, datum:TouchMenuCellSeMonsterDatum)
function TouchMenuCellSeMonsterDatum:SetCreepBufferCount(icon, count, onClick)
    self.creepBuffIcon = icon
    self.creepBuff = count
    self.onClickCreepBuffIcon = onClick
    return self
end

return TouchMenuCellSeMonsterDatum
