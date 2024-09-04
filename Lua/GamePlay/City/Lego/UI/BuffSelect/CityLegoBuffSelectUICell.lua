local BaseTableViewProCell = require ('BaseTableViewProCell')
local LuaReusedComponentPool = require('LuaReusedComponentPool')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local CityLegoBuffDifferData = require("CityLegoBuffDifferData")

---@class CityLegoBuffSelectUICell:BaseTableViewProCell
local CityLegoBuffSelectUICell = class('CityLegoBuffSelectUICell', BaseTableViewProCell)

function CityLegoBuffSelectUICell:OnCreate()
    self:Button("child_toggle_dot", Delegate.GetOrCreate(self, self.OnClick))
    self._child_toggle_dot = self:StatusRecordParent("child_toggle_dot")
    self._p_text_status = self:Text("p_text_status")

    self._p_group_buff = self:Transform("p_group_buff")
    self._p_item_buff = self:LuaBaseComponent("p_item_buff")
    self._buff_pool = LuaReusedComponentPool.new(self._p_item_buff, self._p_group_buff)

    self._trigger = self:AnimTrigger("trigger")
end

---@param data {cfg:RoomTagBuffConfigCell, isSelected:boolean}
function CityLegoBuffSelectUICell:OnFeedData(data)
    self.data = data

    self._child_toggle_dot:ApplyStatusRecord(data.isSelected and 1 or 0)
    self._p_text_status.text = I18N.Get(data.cfg:BuffName())
    
    self._buff_pool:HideAll()
    
    local propertyList = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(data.cfg:GolbalAttr())
    ---@type CityLegoBuffDifferData[]
    local dataList = {}
    if propertyList then
        for i, v in ipairs(propertyList) do
            local data = CityLegoBuffDifferData.new(v.type, v.originValue)
            table.insert(dataList, data)
        end
    end
    
    for i = 1, data.cfg:BattleAttrGroupsLength() do
        local battleGroup = data.cfg:BattleAttrGroups(i)
        local battleValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(battleGroup:Attr())
        if battleValues then
            for _, v in ipairs(battleValues) do
                if battleGroup:TextLength() == 0 then
                    local data = CityLegoBuffDifferData.new(v.type, v.originValue)
                    table.insert(dataList, data)
                else
                    for j = 1, battleGroup:TextLength() do
                        local prefix = battleGroup:Text(j)
                        local data = CityLegoBuffDifferData.new(v.type, v.originValue, nil, prefix)
                        table.insert(dataList, data)
                    end
                end
            end
        end
    end

    for i, v in ipairs(dataList) do
        local item = self._buff_pool:GetItem()
        item:FeedData(v)
    end
end

function CityLegoBuffSelectUICell:OnClick()
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_LEGO_BUFF_SELECT_CELL, self.data.cfg)
end

function CityLegoBuffSelectUICell:TryPlayLightVX()
    if not self.data or not self.data.isSelected then return false end

    self._trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    local length = self._trigger:GetTriggerTypeAnimLength(CS.FpAnimation.CommonTriggerType.Custom1)
    return true, length
end

return CityLegoBuffSelectUICell