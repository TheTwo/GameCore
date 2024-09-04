---Scene Name : scene_furniture_popup_repair
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local LuaReusedComponentPool = require("LuaReusedComponentPool")

---@class CityWorkFurnitureRepairUIMediator:BaseUIMediator
local CityWorkFurnitureRepairUIMediator = class('CityWorkFurnitureRepairUIMediator', BaseUIMediator)

function CityWorkFurnitureRepairUIMediator:OnCreate()
    self._btn_exit = self:Button("btn_exit", Delegate.GetOrCreate(self, self.OnClickExit))

    self._group_left = self:GameObject("group_left")
    ---@type CityFurnitureConstructionProcessCitizenBlock
    self._p_resident_root = self:LuaObject("p_resident_root")
    self._p_btn_efficiency = self:Button("p_btn_efficiency", Delegate.GetOrCreate(self, self.OnClickGear))
    self._p_text_efficiency = self:Text("p_text_efficiency")
    ---@type CityWorkUIBuffItem
    self._p_btn_buff_1 = self:LuaObject("p_btn_buff_1")
    ---@type CityWorkUIBuffItem
    self._p_btn_buff_2 = self:LuaObject("p_btn_buff_2")
    ---@type CityWorkUIBuffItem
    self._p_btn_buff_3 = self:LuaObject("p_btn_buff_3")

    self._content_right = self:GameObject("content_right")
    self._p_building_name = self:GameObject("p_building_name")
    self._p_text_building_name = self:Text("p_text_building_name")
    self._p_max = self:GameObject("p_max")
    self._p_text_max = self:Text("p_text_max")
    self._p_detail = self:GameObject("p_detail")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickBtnDetail))

    self._p_scroll_content = self:GameObject("p_scroll_content")
    self._p_durable = self:GameObject("p_durable")
    self._p_text_durable = self:Text("p_text_durable", "sys_city_17")
    self._p_text_durable_num = self:Text("p_text_durable_num") --- duration from
    self._p_text_durable_add = self:Text("p_text_durable_add") --- duration to
    self._p_text_durable_top = self:Text("p_text_durable_top") --- duration max
    self._p_progress_durable_preview = self:Slider("p_progress_durable_preview") --- 预览修理耐久进度
    self._p_progress_durable = self:Slider("p_progress_durable") --- 当前耐久进度

    self._p_title_need = self:GameObject("p_title_need")
    self._p_text_need = self:Text("p_text_need", "#材料消耗")
    self._p_resource_grid = self:GameObject("p_resource_grid")
    ---@type CityWorkUICostItem
    self._p_item = self:LuaBaseComponent("p_item")
    self._pool_cost = LuaReusedComponentPool.new(self._p_item, self._p_resource_grid)

    self._p_title_condition = self:Text("p_title_condition")
    self._p_text_condition = self:Text("p_text_condition", "ui_service_con")
    self._p_condition_vertical = self:Transform("p_condition_vertical")
    ---@type CityWorkUIConditionItem
    self._p_conditions = self:LuaBaseComponent("p_conditions")
    self._pool_condition = LuaReusedComponentPool.new(self._p_conditions, self._p_condition_vertical)

    self._p_text_hint_quantity = self:Text("p_text_hint_quantity", "#维修次数")

    self._p_text_time_b = self:Text("p_text_time_b", "#耗时")
    ---@type CommonTimer
    self._child_time_editor_cost = self:LuaBaseComponent("child_time_editor_cost")
    self._p_bottom_btn = self:GameObject("p_bottom_btn")
    ---@type BistateButton
    self._p_comp_btn_a_l_u2 = self:LuaObject("p_comp_btn_a_l_u2")

    self._p_progress = self:GameObject("p_progress")
    self._p_progress_n = self:Image("p_progress_n")
    self._p_progress_pause = self:Image("p_progress_pause")
    self._p_text_progress = self:Text("p_text_progress", "#维修中")
    ---@type CommonTimer
    self._child_time_progress = self:LuaObject("child_time_progress")
    self._p_btn_delect = self:Button("p_btn_delect", Delegate.GetOrCreate(self, self.OnClickCancel))
end

function CityWorkFurnitureRepairUIMediator:OnOpened(param)
    
end

function CityWorkFurnitureRepairUIMediator:OnClose(param)
    
end

function CityWorkFurnitureRepairUIMediator:OnClickExit()
    
end

function CityWorkFurnitureRepairUIMediator:OnClickGear()
    
end

function CityWorkFurnitureRepairUIMediator:OnClickBtnDetail()
    
end

function CityWorkFurnitureRepairUIMediator:OnClickCancel()
    
end

return CityWorkFurnitureRepairUIMediator