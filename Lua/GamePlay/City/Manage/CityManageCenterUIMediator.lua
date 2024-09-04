---Scene Name : scene_city_manage
local BaseUIMediator = require ('BaseUIMediator')
local CityManageCenterI18N = require("CityManageCenterI18N")
local ModuleRefer = require("ModuleRefer")

---@class CityManageCenterUIMediator:BaseUIMediator
local CityManageCenterUIMediator = class('CityManageCenterUIMediator', BaseUIMediator)
local I18N = require("I18N")

function CityManageCenterUIMediator:OnCreate()
    ---@see CityManageCenterTab 
    ---@左侧分页选择Tab
    self._p_table_tabs = self:TableViewPro("p_table_tabs")
    self._p_text_pet_count = self:Text("p_text_pet_count")

    ---@type CityManageCenterOverviewPage
    self._p_group_view = self:LuaObject("p_group_view")
    ---@type CityManageCenterDetailPage
    self._p_group_detail = self:LuaObject("p_group_detail")
end

---@param param CityManageCenterUIParameter
function CityManageCenterUIMediator:OnOpened(param)
    self.param = param
    self.param:OnMediatorOpened(self)
    local curJobPetCount, maxPetJobSlot = self.param:GetCurrentJobCount()
    local petCount = ModuleRefer.PetModule:GetPetCount()
    self._p_text_pet_count.text = I18N.GetWithParams(CityManageCenterI18N.UIHint_JobCounter, curJobPetCount, petCount)

    self._p_table_tabs:Clear()
    for i, v in ipairs(self.param:GetTabDataList()) do
        self._p_table_tabs:AppendData(v)
    end
end

function CityManageCenterUIMediator:OnClose()
    self.param:OnMediatorClosed(self)
end

return CityManageCenterUIMediator