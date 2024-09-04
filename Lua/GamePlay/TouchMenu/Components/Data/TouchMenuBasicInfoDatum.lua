local TouchMenuBasicInfoDatumBase = require("TouchMenuBasicInfoDatumBase")
---@class TouchMenuBasicInfoDatum:TouchMenuBasicInfoDatumBase
---@field new fun(name, image, coord, level, tipsOnClick):TouchMenuBasicInfoDatum
local TouchMenuBasicInfoDatum = class("TouchMenuBasicInfoDatum", TouchMenuBasicInfoDatumBase)

---@param owner wds.Owner|wds.AllianceMember
function TouchMenuBasicInfoDatum:ctor(name, image, coord, level, tipsOnClick, owner, background)
    self.name = name
    self.image = image
    self.coord = coord
    self.level = level
    self.tipsOnClick = tipsOnClick
    self.detailClick = nil
    ---@type TouchMenuBasicInfoDatumMarkProvider
    self.markProvider = nil
    self:SetOwner(owner)
    self:SetBack(background)
end

function TouchMenuBasicInfoDatum:ShowLevel()
    return type(self.level) == "number"
end

function TouchMenuBasicInfoDatum:GetLevelText()
    return ("Lv.%d"):format(self.level)
end

function TouchMenuBasicInfoDatum:ShowCoord()
    return not string.IsNullOrEmpty(self.coord)
end

function TouchMenuBasicInfoDatum:GetCoordText()
    return self.coord
end

function TouchMenuBasicInfoDatum:ShowImage()
    return not string.IsNullOrEmpty(self.image)
end

function TouchMenuBasicInfoDatum:ShowTipsButton()
    return type(self.tipsOnClick) == "function"
end

function TouchMenuBasicInfoDatum:ShowHeadPlayer()
    return self.owner ~= nil
end

function TouchMenuBasicInfoDatum:ShowBackground()
    return not string.IsNullOrEmpty(self.background)
end

---@return TouchMenuBasicInfoDatum
function TouchMenuBasicInfoDatum:SetImage(image)
    self.image = image
    return self
end

---@return TouchMenuBasicInfoDatum
function TouchMenuBasicInfoDatum:SetCoord(coord)
    self.coord = coord
    return self
end

---@return TouchMenuBasicInfoDatum
function TouchMenuBasicInfoDatum:SetLevel(level)
    self.level = level
    return self
end

---@return TouchMenuBasicInfoDatum
function TouchMenuBasicInfoDatum:SetTipsOnClick(tipsOnClick)
    self.tipsOnClick = tipsOnClick
    return self
end

---@return TouchMenuBasicInfoDatum
function TouchMenuBasicInfoDatum:SetTypeAndConfig(dbType, configID)
    self.dbType = dbType
    self.configID = configID
    return self
end

---@param owner wds.Owner|wds.AllianceMember
---@return TouchMenuBasicInfoDatum
function TouchMenuBasicInfoDatum:SetOwner(owner)
    if owner then
        self.owner = owner
        self.image = nil
    end
    return self
end

---@param background boolean|string
---@return TouchMenuBasicInfoDatum
function TouchMenuBasicInfoDatum:SetBack(background)
    if background == nil then return self end
    if type(background) == "boolean" then
        self.background = background and "sp_menu_bg_self" or "sp_menu_bg_enemy"
    elseif type(background) == "string" then
        self.background = background
    end
    return self
end

function TouchMenuBasicInfoDatum:GetCompName()
    return "_child_touch_menu_name"
end

return TouchMenuBasicInfoDatum