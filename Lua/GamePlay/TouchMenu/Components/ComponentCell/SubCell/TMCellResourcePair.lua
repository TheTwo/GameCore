--- scene:scene_child_touch_menu_pair_resource

local UIHelper = require("UIHelper")

local BaseUIComponent = require("BaseUIComponent")

---@class TMCellResourcePair:BaseUIComponent
---@field new fun():TMCellResourcePair
---@field super BaseUIComponent
---@field FeedData fun(self:TMCellResourcePair, data:CommonPairsQuantityParameter[])
local TMCellResourcePair = class('TMCellResourcePair', BaseUIComponent)

function TMCellResourcePair:ctor()
    BaseUIComponent.ctor(self)
    ---@type TMCellResourcePairOne[]
    self._cells = {}
end

function TMCellResourcePair:OnCreate(param)
    self._p_group_item_01 = self:LuaBaseComponent("p_group_item_01")
    self._p_group_item_01:SetVisible(false)
end

---@param data CommonPairsQuantityParameter[]
function TMCellResourcePair:OnFeedData(data)
    local nowCount = #data
    local hasCount = #self._cells
    for i = hasCount, nowCount + 1, -1 do
        self._cells[i]:SetVisible(false)
    end
    for i = 1, nowCount do
        local cell = self:GetOrCreate(i)
        cell:FeedData(data[i])
    end
end

---@param index number
---@return TMCellResourcePairOne
function TMCellResourcePair:GetOrCreate(index)
    local ret = self._cells[index]
    if not ret then
        ret = UIHelper.DuplicateUIComponent(self._p_group_item_01, self._p_group_item_01.transform.parent)
        self._cells[index] = ret
    end
    ret:SetVisible(true)
    return ret
end

return TMCellResourcePair