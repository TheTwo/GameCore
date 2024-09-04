local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

---@class AllianceWarTabBattle
---@field new fun(host:AllianceWarMediator, nodeName:string):AllianceWarTabBattle
local AllianceWarTabBattle = class('AllianceWarTabBattle')

---@param host AllianceWarMediator
function AllianceWarTabBattle:ctor(host, nodeName)
    self._host = host
    self._p_root = host:GameObject(nodeName)
    self._p_table = host:TableViewPro("p_table_war")
end

function AllianceWarTabBattle:OnEnter()
    self._p_root:SetVisible(true)
    self._p_table:Clear()
    self._host:SetTabHasData(false)
end

function AllianceWarTabBattle:OnExit()
    self._p_table:Clear()
    self._p_root:SetVisible(false)
end

return AllianceWarTabBattle