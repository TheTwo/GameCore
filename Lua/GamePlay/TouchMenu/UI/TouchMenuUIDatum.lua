---@class TouchMenuUIDatum
---@field new fun(...):TouchMenuUIDatum
local TouchMenuUIDatum = class("TouchMenuUIDatum")

function TouchMenuUIDatum.Empty()
    return TouchMenuUIDatum.new()
end

---@vararg TouchMenuPageDatum
function TouchMenuUIDatum:ctor(...)
    self.pages = {...}
    self.pageCount = #self.pages
    self.startPage = 1
    self.worldPos = nil
    ---@type CS.UnityEngine.Transform
    self.followTrans = nil
    self.marginX = nil
    self.marginZ = nil
    self.emptyClose = false
    ---@type fun()
    self.onHideCallBack = nil
    self.closeOnTime = nil
end

---@return TouchMenuUIDatum
function TouchMenuUIDatum:SetStartPage(startPage)
    self.startPage = math.clamp(startPage, math.min(self.pageCount, 1), math.max(self.pageCount, 1))
    return self
end

---@param page TouchMenuPageDatum
---@return TouchMenuUIDatum
function TouchMenuUIDatum:AddPage(page, pos)
    if not page or GetClassName(page) ~= "TouchMenuPageDatum" then
        return self
    end

    if pos then
        table.insert(self.pages, pos, page)
        if pos <= self.startPage then
            self.startPage = self.startPage + 1
        end
    else
        table.insert(self.pages, page)
    end
    self.pageCount = self.pageCount + 1
    return self
end

---@param worldPos CS.UnityEngine.Vector3
---@param marginX number
---@param marginZ number
---@return TouchMenuUIDatum
function TouchMenuUIDatum:SetPos(worldPos, marginX, marginZ)
    self.worldPos = worldPos
    self.marginX = marginX or 0
    self.marginZ = marginZ or 0
    return self
end

function TouchMenuUIDatum:SetFollowTransform(transform,offset, marginX, marginZ)
    self.followTrans = transform
    self.followOffset = offset or 0
    self.marginX = marginX or 0
    self.marginZ = marginZ or 0
    return self
end

---@param emptyClose boolean
---@return TouchMenuUIDatum
function TouchMenuUIDatum:SetClickEmptyClose(emptyClose)
    self.emptyClose = emptyClose
    return self
end

---@param onHideCallback fun()
---@return TouchMenuUIDatum
function TouchMenuUIDatum:SetOnHideCallback(onHideCallback)
    self.onHideCallBack = onHideCallback
    return self
end

return TouchMenuUIDatum