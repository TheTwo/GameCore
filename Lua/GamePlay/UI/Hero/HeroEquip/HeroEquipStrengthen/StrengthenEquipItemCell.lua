local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local LockEquipParameter = require("LockEquipParameter")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local StrengthenEquipItemCell = class('StrengthenEquipItemCell',BaseTableViewProCell)

function StrengthenEquipItemCell:OnCreate(param)
    self.compChildItemStandardS = self:LuaBaseComponent('child_item_standard_s')
    self.compChildCardHeroS = self:LuaBaseComponent('child_card_hero_s')
    self.goItemMask = self:GameObject('p_item_mask')
    self.goItemNumSelected = self:GameObject('p_item_num_selected')
    self.textNumSelected = self:Text('p_text_num_selected')
    self.isSelect = false
    self.selectCount = 0
    self.parentMediator = self:GetParentBaseUIMediator()
    self.goItemMask:SetActive(false)
end

function StrengthenEquipItemCell:Select()
end

function StrengthenEquipItemCell:OnClose()
end

function StrengthenEquipItemCell:UnSelect()
end

function StrengthenEquipItemCell:OnEquipIconClick()
    if self.parentMediator.isAddMax then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("equip_strength_full_exp"))
        return
    end
    local selectfunc = function()
        if not self.isSelect then
            self.isSelect = true
            self:RefreshEquipState()
            g_Game.EventManager:TriggerEvent(EventConst.HERO_ONCLICK_STRENGTHEN, {uid = self.uid, isSelect = self.isSelect})
        end
    end

    local equip = ModuleRefer.InventoryModule:GetItemInfoByUid(self.uid)
    if equip.EquipInfo.IsLock then
        local dialogParam = {}
        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        dialogParam.title = I18N.Get("equip_warning")
        dialogParam.content = I18N.Get("hero_equip_lock_new")
        dialogParam.confirmLabel = I18N.Get("equip_warning_cancel")
        dialogParam.cancelLabel = I18N.Get("equip_warning_yes")
        dialogParam.onConfirm = function()
            return true
        end
        dialogParam.onCancel = function(context)
            local param = LockEquipParameter.new()
            param.args.EquipItemId = equip.ID
            param.args.IsLock = not equip.EquipInfo.IsLock
            param:SendWithFullScreenLockAndOnceCallback(nil, nil, function()
                self:RefreshLock()
            end)
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
        return
    end
    if equip.EquipInfo.StrengthenExp > 0 then
        local dialogParam = {}
        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        dialogParam.title = I18N.Get("equip_warning")
        dialogParam.content = I18N.GetWithParams("equip_warning_str_new", math.floor(ConfigRefer.ConstMain:EquipResolveReturnItemRate() * 100) .. "%%")
        dialogParam.confirmLabel = I18N.Get("equip_warning_cancel")
        dialogParam.cancelLabel = I18N.Get("equip_warning_yes")
        dialogParam.onConfirm = function()
            return true
        end
        dialogParam.onCancel = function(context)
            selectfunc()
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
    else
        selectfunc()
    end
end

function StrengthenEquipItemCell:OnEquipDelBtnClick()
    if self.isSelect then
        self.isSelect = false
        g_Game.EventManager:TriggerEvent(EventConst.HERO_ONCLICK_STRENGTHEN, {uid = self.uid, isSelect = self.isSelect})
        self:RefreshEquipState()
    end
end

function StrengthenEquipItemCell:RefreshEquipState()
    self.compChildItemStandardS.Lua:RefreshMaskState(self.isSelect)
    self.compChildItemStandardS.Lua:ChangeDelBtnState(self.isSelect)
    self.compChildItemStandardS.Lua:ChangeSelectStatus(self.isSelect)
end

function StrengthenEquipItemCell:OnItemIconClick()
    if self.parentMediator.isAddMax then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("equip_strength_full_exp"))
        return
    end
    self.selectCount = self.selectCount + 1
    self:RefreshItemState()
    g_Game.EventManager:TriggerEvent(EventConst.HERO_ONCLICK_STRENGTHEN, {itemId = self.itemId, count = self.selectCount})
end

function StrengthenEquipItemCell:OnDelBtnClick()
    self.selectCount = self.selectCount - 1
    self:RefreshItemState()
    g_Game.EventManager:TriggerEvent(EventConst.HERO_ONCLICK_STRENGTHEN, {itemId = self.itemId, count = self.selectCount})
end

function StrengthenEquipItemCell:RefreshItemState()
    local itemCount = ModuleRefer.InventoryModule:GetAmountByConfigId(self.itemId)
    if self.selectCount > itemCount then
        self.selectCount = itemCount
    end
    self.goItemNumSelected:SetActive(self.selectCount > 0)
    self.compChildItemStandardS.Lua:ChangeSelectStatus(self.selectCount > 0)
    self.compChildItemStandardS.Lua:ChangeDelBtnState(self.selectCount > 0)
    self.compChildItemStandardS.Lua:RefreshMaskState(self.selectCount > 0)
    self.textNumSelected.text = self.selectCount
end

function StrengthenEquipItemCell:RefreshLock()
    if not self.isItem then
        local item = ModuleRefer.InventoryModule:GetItemInfoByUid(self.uid)
        self.compChildItemStandardS.Lua:RefreshLockState(item.EquipInfo.IsLock)
    end
end

function StrengthenEquipItemCell:OnFeedData(data)
    self.isItem = data.isItem
    self.compChildItemStandardS.Lua:ChangeSelectStatus(false)
    if self.isItem then
        self.itemId = data.itemId
        self.compChildCardHeroS.gameObject:SetActive(false)
        self.itemCount = ModuleRefer.InventoryModule:GetAmountByConfigId(self.itemId)
        self.compChildItemStandardS.Lua:RefreshMaskState(self.itemCount <= 0)
        local itemData = {}
        itemData.configCell = ConfigRefer.Item:Find(self.itemId)
        itemData.showCount = self.itemCount > 0
        itemData.count = self.itemCount
        itemData.onClick = function()
            self:OnItemIconClick()
        end
        itemData.onDelBtnClick = function()
            self:OnDelBtnClick()
        end
        self.compChildItemStandardS:FeedData(itemData)
        self.goItemNumSelected:SetActive(false)
        self.selectCount = self.parentMediator.selectedItem[self.itemId] or 0
        self:RefreshItemState()
    else
        self.uid = data.uid
        self.compChildItemStandardS.Lua:RefreshMaskState(false)
        self.goItemNumSelected:SetActive(false)
        local item = ModuleRefer.InventoryModule:GetItemInfoByUid(self.uid)
        if item.EquipInfo.HeroConfigId and item.EquipInfo.HeroConfigId > 0 then
            self.compChildCardHeroS.gameObject:SetActive(true)
            self.compChildCardHeroS:FeedData(item.EquipInfo.HeroConfigId)
        else
            self.compChildCardHeroS.gameObject:SetActive(false)
        end
        local itemData = {}
        itemData.configCell = ConfigRefer.Item:Find(item.ConfigId)
        itemData.showCount = false
        itemData.showRightCount = item.EquipInfo.StrengthenLevel > 0
        itemData.count = item.EquipInfo.StrengthenLevel
        itemData.gearProtect = item.EquipInfo.IsLock
        itemData.onClick = function()
            self:OnEquipIconClick()
        end
        itemData.onDelBtnClick = function()
            self:OnEquipDelBtnClick()
        end
        self.compChildItemStandardS:FeedData(itemData)
        self.isSelect = self.parentMediator.selectedEquip[self.uid] or false
        self:RefreshEquipState()
    end
end

return StrengthenEquipItemCell
