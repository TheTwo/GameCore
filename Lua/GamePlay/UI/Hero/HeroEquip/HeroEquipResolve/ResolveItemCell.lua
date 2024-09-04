local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local ResolveItemCell = class('ResolveItemCell',BaseTableViewProCell)

function ResolveItemCell:OnCreate(param)
    self.compChildItemStandardS = self:LuaBaseComponent('child_item_standard_s')
    self.btnDelete = self:Button('p_btn_delete', Delegate.GetOrCreate(self, self.OnBtnDeleteClicked))
    self.goLock = self:GameObject("p_icon_equip_lock")
    self.goBaseItem = self:GameObject("p_item_base_01")
end

function ResolveItemCell:OnBtnDeleteClicked()
    local equipResolveUIMediator = g_Game.UIManager:FindUIMediatorByName(require('UIMediatorNames').HeroEquipResolveUIMediator)
    equipResolveUIMediator:RemoveSelectItem(self.data.ID)
end

function ResolveItemCell:OnIconClick()
    local equipResolveUIMediator = g_Game.UIManager:FindUIMediatorByName(require('UIMediatorNames').HeroEquipResolveUIMediator)
    equipResolveUIMediator:ShowItemDetails(self.data)
    if self.data.EquipInfo.IsLock then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("equipp_break_locked"))
        return
    end
    equipResolveUIMediator:AddSelectItem(self.data)
end

function ResolveItemCell:OnFeedData(itemUid)
    if itemUid == -1 then
        self.compChildItemStandardS.gameObject:SetActive(false)
        self.btnDelete.gameObject:SetActive(false)
        self.goLock:SetActive(false)
        self.goBaseItem:SetActive(true)
        return
    end
    self.compChildItemStandardS.gameObject:SetActive(true)
    self.goBaseItem:SetActive(false)
    self.data = ModuleRefer.InventoryModule:GetItemInfoByUid(itemUid)
    local itemData = {}
    itemData.configCell = ConfigRefer.Item:Find(self.data.ConfigId)
    itemData.showCount = false
    itemData.showRightCount = self.data.EquipInfo.StrengthenLevel > 0
    itemData.count = self.data.EquipInfo.StrengthenLevel
    itemData.onClick = function()
        self:OnIconClick()
    end
    self.compChildItemStandardS:FeedData(itemData)
    local equipResolveUIMediator = g_Game.UIManager:FindUIMediatorByName(require('UIMediatorNames').HeroEquipResolveUIMediator)
    self.btnDelete.gameObject:SetActive(equipResolveUIMediator:CheckIsSelected(itemUid))
    self.goLock:SetActive(self.data.EquipInfo.IsLock)
end

return ResolveItemCell
