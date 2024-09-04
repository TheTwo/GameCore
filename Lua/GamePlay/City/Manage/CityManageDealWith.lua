local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")
local CityManageCenterI18N = require("CityManageCenterI18N")
local LuaReusedComponentPool = require("LuaReusedComponentPool")

---@class CityManageDealWith:BaseUIComponent
local CityManageDealWith = class('CityManageDealWith', BaseUIComponent)

function CityManageDealWith:OnCreate()
    self._p_icon_processable = self:Image("p_icon_processable")
    self._p_text_processable = self:Text("p_text_processable")
    self._p_btn_goto_processable = self:Button("p_btn_goto_processable", Delegate.GetOrCreate(self, self.OnClickGoto))

    self._p_materials_processable = self:Transform("p_materials_processable")
    self._p_text_materials_processable = self:Text("p_text_materials_processable", CityManageCenterI18N.UIHint_Need)
    self._p_icon_materials_processable = self:Image("p_icon_materials_processable")
    self._pool_materials = LuaReusedComponentPool.new(self._p_icon_materials_processable, self._p_materials_processable)

    self._p_type_processable = self:Transform("p_type_processable")
    self._p_text_type_processable = self:Text("p_text_type_processable", CityManageCenterI18N.UIHint_Need)
    self._p_icon_type_processable = self:Image("p_icon_type_processable")
    self._pool_feature = LuaReusedComponentPool.new(self._p_icon_type_processable, self._p_type_processable)
end

function CityManageDealWith:OnFeedData(data)
    
end

function CityManageDealWith:OnClickGoto()
    
end

return CityManageDealWith