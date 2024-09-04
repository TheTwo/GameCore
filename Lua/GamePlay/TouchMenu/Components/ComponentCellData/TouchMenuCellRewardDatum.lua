local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")
---@class TouchMenuCellRewardDatum:TouchMenuCellDatumBase
---@field new fun(title, compsData, tips):TouchMenuCellRewardDatum
local TouchMenuCellRewardDatum = class("TouchMenuCellRewardDatum", TouchMenuCellDatumBase)
local TimerUtility = require("TimerUtility")
local Delegate = require("Delegate")
local TMCellRewardItemIconData = require("TMCellRewardItemIconData")
local TMCellRewardUIPetIconData = require("TMCellRewardUIPetIconData")
local TMCellRewardImage = require("TMCellRewardImage")

---@param compsData TMCellRewardBase[]
function TouchMenuCellRewardDatum:ctor(title, compsData, tips, extraTips)
    self.title = title
    self.compsData = compsData
    self.tips = tips
    self.extraTips = extraTips

    self.dynamicTips = self:IsDynamic(self.tips)
    self.dynamicExtraTips = self:IsDynamic(self.extraTips)
end

function TouchMenuCellRewardDatum:IsDynamic(element)
    return type(element) == "function"
end

---@param uiCell TouchMenuCellReward
function TouchMenuCellRewardDatum:BindUICell(uiCell)
    self.uiCell = uiCell
    uiCell:UpdateTitle(self.title)
    uiCell:UpdateTips(self:GetTips())
    uiCell:UpdateExtraTips(self:GetExtraTips())
    uiCell:UpdateTable(self.compsData)

    if self.dynamicTips then
        self.timer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.OnTick), 1, -1)
    end
end

function TouchMenuCellRewardDatum:UnbindUICell()
    self.uiCell = nil
    if self.dynamicTips then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function TouchMenuCellRewardDatum:OnTick()
    if self.uiCell ~= nil then
        self.uiCell:UpdateTips(self:GetTips())
        self.uiCell:UpdateExtraTips(self:GetExtraTips())
    end
end

function TouchMenuCellRewardDatum:GetTips()
    if self.dynamicTips then
        return self.tips()
    end
    return self.tips
end

function TouchMenuCellRewardDatum:GetExtraTips()
    if self.dynamicExtraTips then
        return self.extraTips()
    end
    return self.extraTips
end

function TouchMenuCellRewardDatum:GetPrefabIndex()
    return 6
end

---@param data ItemIconData
---@return TouchMenuCellRewardDatum
function TouchMenuCellRewardDatum:AppendItemIconData(data)
    if not data then return self end
    
    if not self.compsData then
        self.compsData = {}
    end
    table.insert(self.compsData, TMCellRewardItemIconData.new(data))
    return self
end

---@param data UIPetIconData
---@return TouchMenuCellRewardDatum
function TouchMenuCellRewardDatum:AppendUIPetIconData(data)
    if not data then return self end
    
    if not self.compsData then
        self.compsData = {}
    end
    table.insert(self.compsData, TMCellRewardUIPetIconData.new(data))
    return self
end

---@param image string
---@return TouchMenuCellRewardDatum
function TouchMenuCellRewardDatum:AppendImage(image)
    if string.IsNullOrEmpty(image) then return self end

    if not self.compsData then
        self.compsData = {}
    end
    table.insert(self.compsData, TMCellRewardImage.new(image))
    return self
end

---@return TouchMenuCellRewardDatum
function TouchMenuCellRewardDatum:SetTips(tips)
    self.tips = tips
    self.dynamicTips = self:IsDynamic(self.tips)
    return self
end

---@return TouchMenuCellRewardDatum
function TouchMenuCellRewardDatum:SetExtraTips(tips)
    self.extraTips = tips
    self.dynamicExtraTips = self:IsDynamic(self.extraTips)
	return self
end

---@return TouchMenuCellRewardDatum
function TouchMenuCellRewardDatum:SetCompsData(compsData)
    self.compsData = compsData
    return self
end

---@return TouchMenuCellRewardDatum
function TouchMenuCellRewardDatum:SetTitle(title)
	self.title = title
	return self
end

return TouchMenuCellRewardDatum
