
local BaseUIComponent = require("BaseUIComponent")

--    1
-- 4     8
--    2
---@class AllianceTechResearchLinkerNodeParameter
---@field cellPosIdx number
---@field linkFlag number
---@field unlockFlag number

---@class AllianceTechResearchLinkerNode:BaseUIComponent
---@field new fun():AllianceTechResearchLinkerNode
---@field super BaseUIComponent
local AllianceTechResearchLinkerNode = class('AllianceTechResearchLinkerNode', BaseUIComponent)

function AllianceTechResearchLinkerNode:OnCreate(param)
    ---@type CS.UnityEngine.GameObject[]
    self._linkMap = {}
    self._linkMap[1] = self:GameObject("p_line_t")
    self._linkMap[2] = self:GameObject("p_line_b")
    self._linkMap[4] = self:GameObject("p_line_l")
    self._linkMap[8] = self:GameObject("p_line_r")
    ---@type CS.UnityEngine.GameObject[]
    self._unlockMap = {}
    self._unlockMap[1] = self:GameObject("p_line_t_unlock")
    self._unlockMap[2] = self:GameObject("p_line_b_unlock")
    self._unlockMap[4] = self:GameObject("p_line_l_unlock")
    self._unlockMap[8] = self:GameObject("p_line_r_unlock")
    ---@type CS.UnityEngine.GameObject[]
    self._lockedMap = {}
    self._lockedMap[1] = self:GameObject("p_line_t_lock")
    self._lockedMap[2] = self:GameObject("p_line_b_lock")
    self._lockedMap[4] = self:GameObject("p_line_l_lock")
    self._lockedMap[8] = self:GameObject("p_line_r_lock")
    self._p_icon_nail = self:GameObject("p_icon_nail")
    self._p_icon_nail_lock = self:GameObject("p_icon_nail_lock")
    self._p_icon_nail_unlock = self:GameObject("p_icon_nail_unlock")
    self._p_line_c = self:GameObject("p_line_c")
    self._p_line_c_lock = self:GameObject("p_line_c_lock")
    self._p_line_c_unlock = self:GameObject("p_line_c_unlock")
end

---@param data AllianceTechResearchLinkerNodeParameter
function AllianceTechResearchLinkerNode:OnFeedData(data)
    local linkFlag = data.linkFlag or 0
    local unlockFlag = data.unlockFlag or 0
    for i, v in pairs(self._linkMap) do
        local isLinked = (i & linkFlag) ~= 0
        v:SetVisible(isLinked)
        if isLinked then
            local isUnlocked = (i & unlockFlag) ~= 0
            self._unlockMap[i]:SetVisible(isUnlocked)
            self._lockedMap[i]:SetVisible(not isUnlocked)
        end
    end
    local showNail = (linkFlag == 7) or (linkFlag == 11) or (linkFlag == 13) or (linkFlag == 14) or (linkFlag == 15)
    self._p_icon_nail:SetVisible(showNail)
    if showNail then
        local unlockNail = unlockFlag ~= 0
        self._p_icon_nail_lock:SetVisible(not unlockNail)
        self._p_icon_nail_unlock:SetVisible(unlockNail)
    end
    self._p_line_c:SetVisible(linkFlag ~= 0)
    self._p_line_c_lock:SetVisible(unlockFlag == 0)
    self._p_line_c_unlock:SetVisible(unlockFlag ~= 0)
end

return AllianceTechResearchLinkerNode