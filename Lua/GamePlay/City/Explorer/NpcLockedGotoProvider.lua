local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local NpcServiceObjectType = require("NpcServiceObjectType")

local CommonNpcServiceGotoProvider = require("CommonNpcServiceGotoProvider")

---@class NpcLockedGotoProvider:CommonNpcServiceGotoProvider
---@field new fun(elementId:number):NpcLockedGotoProvider
---@field super CommonNpcServiceGotoProvider
local NpcLockedGotoProvider = class('NpcLockedGotoProvider', CommonNpcServiceGotoProvider)

---@param elementId number
function NpcLockedGotoProvider:ctor(elementId)
    self._elementId = elementId
    self._npcConfig = ConfigRefer.CityElementNpc:Find(ConfigRefer.CityElementData:Find(elementId):ElementId())
    CommonNpcServiceGotoProvider.ctor(self, NpcServiceObjectType.CityElement, elementId)
end

function NpcLockedGotoProvider:GetTitle()
    return I18N.Get(self._npcConfig:Name())
end

function NpcLockedGotoProvider:GetHintText()
    return I18N.Get("tips_precondition_npc")
end

return NpcLockedGotoProvider