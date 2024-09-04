local Delegate = require("Delegate")
local DBEntityPath = require("DBEntityPath")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local GuideUtils = require("GuideUtils")
local FPXSDKBIDefine = require("FPXSDKBIDefine")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
local NumberFormatter = require("NumberFormatter")
local DoNotShowAgainHelper = require("DoNotShowAgainHelper")
local UITroopHelper = require("UITroopHelper")
local EventConst = require("EventConst")
local HUDTroopUtils = require("HUDTroopUtils")
---@class TroopEditTroopBubbleHolder
local TroopEditTroopBubbleHolder = class("TroopEditTroopBubbleHolder")

---@param cell BaseTableViewProCell
---@param presetIndex number
---@param empty boolean
---@param lock boolean
---@param manager TroopEditManager
function TroopEditTroopBubbleHolder:ctor(cell, presetIndex, empty, lock, manager)
    self.cell = cell
    self.empty = empty
    self.lock = lock
    self.index = presetIndex
    self.manager = manager

    self.btnAddHp = self.cell:Button('p_btn_recover', Delegate.GetOrCreate(self, self.OnBtnAddHpClick))
    self.btnCreateHp = self.cell:Button('p_btn_recover_red', Delegate.GetOrCreate(self, self.OnBtnCreateHpClick))

    self.goRoot = self.cell:GameObject('p_group_recover')

    self.textHp = self.cell:Text('p_text_hp')
end

function TroopEditTroopBubbleHolder:Setup()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.TroopPresets.MsgPath, Delegate.GetOrCreate(self, self.OnTroopPresetsChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnCastleFurnitureChanged))
    self.manager:AddOnTroopEditChange(Delegate.GetOrCreate(self, self.UpdateUI))
    self:UpdateUI()
end

function TroopEditTroopBubbleHolder:Release()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.TroopPresets.MsgPath, Delegate.GetOrCreate(self, self.OnTroopPresetsChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnCastleFurnitureChanged))
    self.manager:RemoveOnTroopEditChange(Delegate.GetOrCreate(self, self.UpdateUI))
    self.btnAddHp.onClick:RemoveAllListeners()
    self.btnCreateHp.onClick:RemoveAllListeners()
end

function TroopEditTroopBubbleHolder:OnTroopPresetsChanged(entity)
    if not entity or entity.ID ~= ModuleRefer.PlayerModule:GetCastle().ID then return end
    self:UpdateUI()
end

function TroopEditTroopBubbleHolder:OnCastleFurnitureChanged(entity)
    if not entity or entity.ID ~= ModuleRefer.PlayerModule:GetCastle().ID then return end
    self:UpdateUI()
end

function TroopEditTroopBubbleHolder:UpdateUI()
    if HUDTroopUtils.IsPresetInHomeSe(self.index) then
        self:UpdateUIBySe()
    else
        self:UpdateUIBySlg()
    end
end

function TroopEditTroopBubbleHolder:UpdateUIBySlg()
    local troopInfo = HUDTroopUtils.GetTroopInfo(self.index)
    if troopInfo and (HUDTroopUtils.GetTroopStates(troopInfo) or {}).Attacking then
        self.btnAddHp.gameObject:SetActive(false)
        self.btnCreateHp.gameObject:SetActive(false)
        self.textHp.gameObject:SetActive(false)
        return
    end
    self.textHp.gameObject:SetActive(true)
    local bagHp = math.floor(ModuleRefer.TroopModule:GetTroopHpBagCurHp(self.index))
    self.btnAddHp.gameObject:SetActive(bagHp > 0)
    self.btnCreateHp.gameObject:SetActive(bagHp <= 0)
    local capacity = ModuleRefer.TroopModule:GetTroopHpBagCapacity(self.index)
    self.textHp.text = ("%s/%s"):format(NumberFormatter.NumberAbbr(bagHp, true), NumberFormatter.NumberAbbr(capacity, true))
end

function TroopEditTroopBubbleHolder:UpdateUIBySe()
    local teamData = HUDTroopUtils.GetExplorerTeamData(self.index)
    if teamData and teamData:Battling() then
        self.btnAddHp.gameObject:SetActive(false)
        self.btnCreateHp.gameObject:SetActive(false)
        self.textHp.gameObject:SetActive(false)
        return
    end
    self.textHp.gameObject:SetActive(true)
    local bagHp = ModuleRefer.TroopModule:GetTroopHpBagCurHp(self.index)
    self.btnAddHp.gameObject:SetActive(bagHp > 0)
    self.btnCreateHp.gameObject:SetActive(bagHp <= 0)
    local capacity = ModuleRefer.TroopModule:GetTroopHpBagCapacity(self.index)
    self.textHp.text = ("%s/%s"):format(NumberFormatter.NumberAbbr(bagHp, true), NumberFormatter.NumberAbbr(capacity, true))
end

function TroopEditTroopBubbleHolder:OnBtnAddHpClick()
    if not self.manager:CheckCanSave() then
        ---@type CommonConfirmPopupMediatorParameter
        local confirmData = {}
        confirmData.content = I18N.Get("popup_heal_condition")
        confirmData.styleBitMask = CommonConfirmPopupMediatorDefine.Style.Confirm

        confirmData.onConfirm = function()
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmData)
        return
    end
    if self.manager:IsTroopChanged() then
        self.manager:SaveTroop(function(success, _)
            if success then
                self:AddHp()
            end
        end)
    else
        self:AddHp()
    end
end

function TroopEditTroopBubbleHolder:AddHp()
    local neededHp = ModuleRefer.TroopModule:GetTroopNeededHp(self.index)
    if neededHp <= 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("toast_foodtohp_02"))
        return
    end

    local troopInfo = HUDTroopUtils.GetTroopInfo(self.index)
    if troopInfo and HUDTroopUtils.IsTroopRetreating(troopInfo) then
        UITroopHelper.PopupTroopInRetreatAndRecoveryFailedConfirm()
        return
    end

    local canHealHp = ModuleRefer.TroopModule:GetTroopCanHealHp(self.index)
    local bagHp = ModuleRefer.TroopModule:GetTroopHpBagCurHp(self.index)
    local withBag = bagHp < neededHp
    local taskId = ConfigRefer.ConstMain:TeamAlert()
    ---@type TaskItemDataProvider
    local task = require("TaskItemDataProvider").new(taskId)
    if DoNotShowAgainHelper.CanShowAgain("RecoverTroopPresetHp", DoNotShowAgainHelper.Cycle.Daily) and not task:IsTaskFinished() then
        UITroopHelper.PopupRecoveryHpConfirm(self.index, canHealHp, withBag, self.btnAddHp.transform)
    else
        ModuleRefer.TroopModule:RecoverTroopPresetHp(self.index - 1, withBag, self.btnAddHp.transform)
        neededHp = ("%d"):format(math.floor(neededHp))
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("toast_foodtohp_01", neededHp))
    end
end

function TroopEditTroopBubbleHolder:OnBtnCreateHpClick()
    if not self.manager:CheckCanSave() then
        ---@type CommonConfirmPopupMediatorParameter
        local confirmData = {}
        confirmData.content = I18N.Get("popup_heal_condition")
        confirmData.styleBitMask = CommonConfirmPopupMediatorDefine.Style.Confirm

        confirmData.onConfirm = function()
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmData)
        return
    end
    if self.manager:IsTroopChanged() then
        self.manager:SaveTroop(function(success, _)
            if success then
                self:CreateHp()
            end
        end)
    else
        self:CreateHp()
    end
end

function TroopEditTroopBubbleHolder:CreateHp()
    local foodCount = ModuleRefer.TroopModule:GetStockFoodCount()
    if foodCount <= 0 then
        UITroopHelper.PopupFoodNotEnoughConfirm(0, self.manager)
    else
        UITroopHelper.PopupBagNotEnoughConfirm(self.index, self.btnCreateHp.transform)
    end
end

function TroopEditTroopBubbleHolder:Show()
    self.goRoot:SetActive(true)
end

function TroopEditTroopBubbleHolder:Hide()
    self.goRoot:SetActive(false)
end

return TroopEditTroopBubbleHolder