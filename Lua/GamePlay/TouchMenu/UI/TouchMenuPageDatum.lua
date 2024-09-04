---@class TouchMenuPageDatum
---@field new fun(basic, compsData, buttonGroupData, buttonTipsData, shareClick, toggleImage, powerData:TouchMenuPowerDatum):TouchMenuPageDatum
local TouchMenuPageDatum = class("TouchMenuPageDatum")
local TouchMenuCellDatumBase = require("TouchMenuCellDatumBase")

---@alias TouchMenuPowerDatum { powerText:string, powerIcon:string }

---@param basic TouchMenuBasicInfoDatum
---@param compsData TouchMenuCellDatumBase[]
---@param buttonGroupData TouchMenuMainBtnGroupData[]
---@param buttonTipsData TouchMenuButtonTipsData
---@param shareClick function
---@param toggleImage string
---@param pollutedData TouchMenuPollutedData
---@param powerData TouchMenuPowerDatum
function TouchMenuPageDatum:ctor(basic, compsData, buttonGroupData, buttonTipsData, shareClick, toggleImage, pollutedData, powerData)
    self.basic = basic
    self.compsData = compsData
    self.buttonGroupData = buttonGroupData
    self.buttonTipsData = buttonTipsData
    self.shareClick = shareClick
    self.toggleImage = toggleImage or "sp_common_icon_area"
    self.pollutedData = pollutedData
    self.powerData = powerData
end

---@param basic TouchMenuBasicInfoDatum
---@return TouchMenuPageDatum
function TouchMenuPageDatum:SetBasic(basic)
    self.basic = basic
    return self
end

---@param compsData TouchMenuCellDatumBase[]
---@return TouchMenuPageDatum
function TouchMenuPageDatum:SetTableCellData(compsData)
    self.compsData = compsData
    return self
end

---@param data TouchMenuCellDatumBase
---@return TouchMenuPageDatum
function TouchMenuPageDatum:AppendTableCellData(data, pos)
    if not data or not data:is(TouchMenuCellDatumBase) then
        return self
    end

    if not self.compsData then
        self.compsData = {}
    end
    if pos then
        table.insert(self.compsData, pos, data)
    else
        table.insert(self.compsData, data)
    end
    return self
end

---@param buttonGroupData TouchMenuMainBtnGroupData[]
---@return TouchMenuPageDatum
function TouchMenuPageDatum:SetButtonGroupData(buttonGroupData)
    self.buttonGroupData = buttonGroupData
    return self
end

---@param buttonGroupDatum TouchMenuMainBtnGroupData
---@return TouchMenuPageDatum
function TouchMenuPageDatum:AppendButtonGroupDatum(buttonGroupDatum, pos)
    if not buttonGroupDatum or GetClassName(buttonGroupDatum) ~= "TouchMenuMainBtnGroupData" then
        return self
    end

    if not self.buttonGroupData then
        self.buttonGroupData = {}
    end
    
    if pos then
        table.insert(self.buttonGroupData, pos, buttonGroupDatum)
    else
        table.insert(self.buttonGroupData, buttonGroupDatum)
    end
    return self
end

---@param shareClick function
---@return TouchMenuPageDatum
function TouchMenuPageDatum:SetShareClick(shareClick)
    self.shareClick = shareClick
    return self
end

---@param image string
---@return TouchMenuPageDatum
function TouchMenuPageDatum:SetToggleImage(image)
    self.toggleImage = image
    return self
end

---@param data TouchMenuPollutedData
---@return TouchMenuPageDatum
function TouchMenuPageDatum:SetPollutedData(data)
    self.pollutedData = data
    return self
end

---@return fun():TouchMenuMainBtnDatum
function TouchMenuPageDatum:Buttons()
    if self.buttonGroupData == nil then return nil end
    if #self.buttonGroupData == 0 then return nil end

    local groupIdx, buttonIdx = 1, 0
    local group = self.buttonGroupData[groupIdx]
    return function()
        buttonIdx = buttonIdx + 1
        while group ~= nil do
            if group.count < buttonIdx then
                groupIdx = groupIdx + 1
                buttonIdx = 1
                group = self.buttonGroupData[groupIdx]
            else
                return group.data[buttonIdx]
            end
        end
        return nil
    end
end

return TouchMenuPageDatum