---Scene Name : scene_city_toast_room
local BaseUIMediator = require ('BaseUIMediator')
local CityLegoI18N = require('CityLegoI18N')
local ConfigRefer = require('ConfigRefer')
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local ModuleRefer = require("ModuleRefer")
local TimerUtility = require("TimerUtility")
local Delegate = require("Delegate")

---@class CityLegoBuffToastUIMediator:BaseUIMediator
local CityLegoBuffToastUIMediator = class('CityLegoBuffToastUIMediator', BaseUIMediator)

function CityLegoBuffToastUIMediator:OnCreate()
    self.p_base_1 = self:GameObject("p_base_1")

    self._layout_name = self:GameObject("layout_name")
    self._p_text_name_old = self:Text("p_text_name_old")
    self._p_text_name_new = self:Text("p_text_name_new")

    self._p_group_buff = self:Transform("p_group_buff")
    self._p_text_furniture = self:Text("p_text_furniture", CityLegoI18N.UI_HintToastBuff)
    self._p_item_buff = self:LuaBaseComponent("p_item_buff")
    self._buff_pool = LuaReusedComponentPool.new(self._p_item_buff, self._p_group_buff)
end

---@param param CityLegoBuffToastUIParameter
function CityLegoBuffToastUIMediator:OnOpened(param)
    self.param = param

    self._p_text_name_old.text = param.oldName
    self._p_text_name_new.text = param.newName

    ---@type AttrGroupConfigCell
    local attrCfg
    if param.attrCfgId ~= nil then
        attrCfg = ConfigRefer.AttrGroup:Find(param.attrCfgId)
    end

    self._p_group_buff:SetVisible(attrCfg ~= nil)
    if attrCfg ~= nil then
        self._buff_pool:HideAll()
        local attrs = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(param.attrCfgId)
        for _, data in ipairs(attrs) do
            local item = self._buff_pool:GetItem()
            item:FeedData(data)
        end
    end

    self.timer = TimerUtility.DelayExecute(Delegate.GetOrCreate(self, self.CloseSelf), param.duration)
end

function CityLegoBuffToastUIMediator:OnClose(param)
    TimerUtility.StopAndRecycle(self.timer)
end

return CityLegoBuffToastUIMediator