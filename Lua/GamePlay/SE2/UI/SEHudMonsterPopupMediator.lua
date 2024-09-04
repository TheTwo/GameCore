local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require('Delegate')

---@class SEHudMonsterPopupMediator : BaseUIMediator
local SEHudMonsterPopupMediator = class('SEHudMonsterPopupMediator', BaseUIMediator)

function SEHudMonsterPopupMediator:ctor()
    self._dataList = {}
end

function SEHudMonsterPopupMediator:OnCreate(param)
    self:InitObjects()
end

function SEHudMonsterPopupMediator:OnShow(param)
    self:InitData(param)
    self:Refresh()
end

function SEHudMonsterPopupMediator:OnHide(param)

end

function SEHudMonsterPopupMediator:OnClose(data)

end

---@param self SEHudMonsterPopupMediator
function SEHudMonsterPopupMediator:InitObjects()
    self.btnBack = self:Button('p_btn_back', Delegate.GetOrCreate(self, self.OnBtnBackClicked))
    self.tableMonster = self:TableViewPro('p_table_monster')
    self.textTitle = self:Text('p_text_title', require("I18N").Temp().text_monster_info)
end

function SEHudMonsterPopupMediator:OnBtnBackClicked(args)
    self:CloseSelf()
end

---@param self SEHudMonsterPopupMediator
function SEHudMonsterPopupMediator:InitData(param)
    self._dataList = param.list
end

---@param self SEHudMonsterPopupMediator
function SEHudMonsterPopupMediator:Refresh()
    self:RefreshData()
    self:RefreshUI()
end

function SEHudMonsterPopupMediator:RefreshData()

end

function SEHudMonsterPopupMediator:RefreshUI()
    self.tableMonster:Clear()
    for _, data in pairs(self._dataList) do
        self.tableMonster:AppendData(data)
    end
    self.tableMonster:RefreshAllShownItem()
end


return SEHudMonsterPopupMediator
