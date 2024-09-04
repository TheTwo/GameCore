---@diagnostic disable: assign-type-mismatch
local BaseUIComponent = require ('BaseUIComponent')
local UI3DModelInteractionManager = require('UI3DModelInteractionManager')
local EventConst = require('EventConst')
local Delegate = require('Delegate')

---@class UITroopHeroCardGroup : BaseUIComponent
local UITroopHeroCardGroup = class('UITroopHeroCardGroup', BaseUIComponent)

---@class UITroopHeroCardGroupData
---@field heroSlots TroopEditSlot[]
---@field petSlots TroopEditSlot[]

local MAX_HERO_COUNT = 3
function UITroopHeroCardGroup:ctor()
end

function UITroopHeroCardGroup:OnCreate()
    -- self:PointerClick('p_back_mask', Delegate.GetOrCreate(self, self.OnEmptyClick))
    self.luaTroopSlot1 = self:LuaObject('child_troop_position_1')
    self.luaTroopSlot2 = self:LuaObject('child_troop_position_2')
    self.luaTroopSlot3 = self:LuaObject('child_troop_position_3')

    self:Text('p_text_back','formation_back')
    self:Text('p_text_middle','formation_middle')
    self:Text('p_text_front','formation_front')

    self.statusCtrler = self:StatusRecordParent("")

    self.ui3dModelInteractMgr = UI3DModelInteractionManager.new(self, 'p_back_mask')

    self.troopSlots = {self.luaTroopSlot1, self.luaTroopSlot2, self.luaTroopSlot3}
end

function UITroopHeroCardGroup:OnShow(param)
    self.ui3dModelInteractMgr:Init()
    self.ui3dModelInteractMgr:SetOnClickEmpty(Delegate.GetOrCreate(self, self.OnEmptyClick))
end

function UITroopHeroCardGroup:OnHide(param)
    self.ui3dModelInteractMgr:Release()
end

function UITroopHeroCardGroup:OnOpened(param)
end

function UITroopHeroCardGroup:OnClose(param)
end

---@param data UITroopHeroCardGroupData
function UITroopHeroCardGroup:OnFeedData(data)
    for i = 1, MAX_HERO_COUNT do
        local slot = self.troopSlots[i]
        ---@type UITroopHeroCardData
        local slotData = {}
        slotData.heroUnit = data.heroSlots[i]:GetUnit()
        slotData.petUnit = data.petSlots[i]:GetUnit()
        slotData.index = i
        slot:FeedData(slotData)
    end
end

function UITroopHeroCardGroup:OnEmptyClick()
    g_Game.EventManager:TriggerEvent(EventConst.ON_TROOP_CLICK_EMPTY)
end

return UITroopHeroCardGroup
