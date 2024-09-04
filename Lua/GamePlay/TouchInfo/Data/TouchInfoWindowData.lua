---@class TouchInfoWindowData
---@field new fun(style, ...:TouchInfoCompDatum):TouchInfoWindowData
local TouchInfoWindowData = sealedClass("TouchInfoWindowData")

---@vararg TouchInfoCompDatum
function TouchInfoWindowData:ctor(style, ...)
    self.windowStyle = style
    self.data = {...}
end

function TouchInfoWindowData:AppendComponent(comp)
    if comp then
        table.insert(self.data, comp)
    end
end

function TouchInfoWindowData:InsertComponent(comp, pos)
    if not comp then return end
    if type(pos) ~= "number" then pos = 1 end

    pos = math.clamp(pos, 1, #self.data + 1)
    table.insert(self.data, pos, comp)
end

return TouchInfoWindowData