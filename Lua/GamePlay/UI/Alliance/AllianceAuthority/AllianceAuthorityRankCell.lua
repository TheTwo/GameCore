local I18N = require("I18N")
local AllianceModuleDefine = require("AllianceModuleDefine")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceAuthorityRankCellData
---@field authority AllianceAuthorityConfigCell
---@field rank number
---@field isLast boolean
---@field showRowBackground boolean

---@class AllianceAuthorityRankCell:BaseTableViewProCell
---@field new fun():AllianceAuthorityRankCell
---@field super BaseTableViewProCell
local AllianceAuthorityRankCell = class('AllianceAuthorityRankCell', BaseTableViewProCell)

function AllianceAuthorityRankCell:OnCreate(param)
    self._p_text_position = self:Text("p_text_position")
    ---@type CS.UnityEngine.UI.Image[]
    self._rightCells = {}
    ---@type CS.UnityEngine.GameObject[]
    self._rightSigns = {}
    ---@type CS.UnityEngine.GameObject[]
    self._p_line = {}
    for i = 1, 5 do
        self._rightCells[i] = self:Image(string.format("p_chick_%s", i))
        self._rightSigns[i] = self:GameObject(string.format("p_icon_tick_%s", i))
        self._p_line[i] = self:GameObject(string.format("p_line_%s", i))
    end
    self._p_base = self:GameObject("p_base")
end

---@param data AllianceAuthorityRankCellData
function AllianceAuthorityRankCell:OnFeedData(data)
    local r = data.rank
    for i = 1, #self._rightCells do
        self._rightCells[i].enabled = r == i
        self._p_line[i]:SetVisible(r == i)
    end
    self._p_base:SetVisible(data.showRowBackground)
    local cfg = data.authority
    for i = 1, #self._rightSigns do
        local key = string.format("R%s", i)
        local keyFunc =  cfg[key]
        self._rightSigns[i]:SetVisible(keyFunc and keyFunc(cfg) or false)
    end
    self._p_text_position.text = I18N.Get(AllianceModuleDefine.GetAuthorityName(cfg:KeyString()))
end

return AllianceAuthorityRankCell