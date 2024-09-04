local TouchMenuBasicInfoDatumBase = require("TouchMenuBasicInfoDatumBase")
---@class TouchMenuBasicInfoDatumSe:TouchMenuBasicInfoDatumBase
---@field new fun():TouchMenuBasicInfoDatumSe
local TouchMenuBasicInfoDatumSe = class("TouchMenuBasicInfoDatumSe", TouchMenuBasicInfoDatumBase)

---@param image string
---@param name string
---@param desc string
---@param coord {x:number, y:number}
---@param detailClick fun()
function TouchMenuBasicInfoDatumSe:ctor(image, name, desc, coord, detailClick)
    self.image = image
    self.name = name
    self.desc = desc
    self.coord = coord
    self.detailClick = detailClick
end

---@return TouchMenuBasicInfoDatumSe
function TouchMenuBasicInfoDatumSe:SetImage(image)
    self.image = image
    return self
end

---@return TouchMenuBasicInfoDatumSe
function TouchMenuBasicInfoDatumSe:SetName(name)
    self.name = name
    return self
end

---@return TouchMenuBasicInfoDatumSe
function TouchMenuBasicInfoDatumSe:SetDesc(desc)
    self.desc = desc
    return self
end

---@return TouchMenuBasicInfoDatumSe
function TouchMenuBasicInfoDatumSe:SetDetailClick(click)
    self.detailClick = click
    return self
end

function TouchMenuBasicInfoDatumSe:SetCoord(x, y)
    self.coord = { x = x, y = y }
    return self
end

function TouchMenuBasicInfoDatumSe:GetCompName()
    return "_child_touch_menu_se"
end

return TouchMenuBasicInfoDatumSe