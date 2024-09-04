local Delegate = require("Delegate")
local DBEntityPath = require("DBEntityPath")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local GuideUtils = require("GuideUtils")
local FPXSDKBIDefine = require("FPXSDKBIDefine")
local DoNotShowAgainHelper = require("DoNotShowAgainHelper")
local UITroopHelper = require("UITroopHelper")
local HUDTroopUtils = require("HUDTroopUtils")
---@class HUDTroopBubbleHolder
local HUDTroopBubbleHolder = class("HUDTroopBubbleHolder")

---@param cell BaseTableViewProCell
---@param presetIndex number
function HUDTroopBubbleHolder:ctor(cell, presetIndex, empty, lock)
    self.cell = cell
    self.empty = empty
    self.lock = lock
    self.index = presetIndex
    self.btnAddHp = self.cell:Button('p_btn_blood_add', Delegate.GetOrCreate(self, self.OnBtnAddHpClick))
    self.btnCreateHp = self.cell:Button('p_btn_blood_create', Delegate.GetOrCreate(self, self.OnBtnCreateHpClick))
end

function HUDTroopBubbleHolder:Setup()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.TroopPresets.MsgPath, Delegate.GetOrCreate(self, self.OnTroopPresetsChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnCastleFurnitureChanged))
    g_Game.ServiceManager:AddResponseCallback(require("HomeSeTroopRecoverHpParameter").GetMsgId(), Delegate.GetOrCreate(self, self.OnHomeSeRecover))
    g_Game.ServiceManager:AddResponseCallback(require("RecoverPresetHpParameter").GetMsgId(), Delegate.GetOrCreate(self, self.UpdateUI))
    self:UpdateUI()
end

function HUDTroopBubbleHolder:Release()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.TroopPresets.MsgPath, Delegate.GetOrCreate(self, self.OnTroopPresetsChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnCastleFurnitureChanged))
    g_Game.ServiceManager:RemoveResponseCallback(require("HomeSeTroopRecoverHpParameter").GetMsgId(), Delegate.GetOrCreate(self, self.OnHomeSeRecover))
    g_Game.ServiceManager:RemoveResponseCallback(require("RecoverPresetHpParameter").GetMsgId(), Delegate.GetOrCreate(self, self.UpdateUI))
    self.btnAddHp.onClick:RemoveAllListeners()
    self.btnCreateHp.onClick:RemoveAllListeners()
    self.cell = nil
    self.btnAddHp = nil
    self.btnCreateHp = nil
end

function HUDTroopBubbleHolder:OnTroopPresetsChanged(entity)
    if not entity or entity.ID ~= ModuleRefer.PlayerModule:GetCastle().ID then return end
    self:UpdateUI()
end

function HUDTroopBubbleHolder:OnCastleFurnitureChanged(entity)
    if not entity or entity.ID ~= ModuleRefer.PlayerModule:GetCastle().ID then return end
    self:UpdateUI()
end

function HUDTroopBubbleHolder:OnHomeSeRecover(response)
    self:UpdateUI()
end

function HUDTroopBubbleHolder:UpdateUI()
    local isMultiSelecting = ModuleRefer.SlgModule.selectManager:GetSelectCount() > 1
    if not self.index or isMultiSelecting then
        self.btnAddHp.gameObject:SetActive(false)
        self.btnCreateHp.gameObject:SetActive(false)
        return
    end
    local preset = ModuleRefer.PlayerModule:GetCastle().TroopPresets.Presets[self.index]
    if not preset then return end
    if self.empty or self.lock then
        self.btnAddHp.gameObject:SetActive(false)
        self.btnCreateHp.gameObject:SetActive(false)
        return
    end
    if HUDTroopUtils.IsPresetInHomeSe(self.index) then
        self:UpdateUIBySe()
    else
        self:UpdateUIBySlg()
    end
end

function HUDTroopBubbleHolder:UpdateUIBySlg()
    local troopInfo = HUDTroopUtils.GetTroopInfo(self.index)
    if troopInfo and HUDTroopUtils.GetTroopStates(troopInfo).Attacking then
        self.btnAddHp.gameObject:SetActive(false)
        self.btnCreateHp.gameObject:SetActive(false)
        return
    end
    local bagHp = ModuleRefer.TroopModule:GetTroopHpBagCurHp(self.index)
    local neededHp = self:GetTroopNeededHp(self.index)
    self.btnAddHp.gameObject:SetActive(neededHp > 1 and bagHp > 0)
    self.btnCreateHp.gameObject:SetActive(neededHp > 1 and bagHp <= 0)
end

function HUDTroopBubbleHolder:UpdateUIBySe()
    local teamData = HUDTroopUtils.GetExplorerTeamData(self.index)
    if teamData and teamData:Battling() then
        self.btnAddHp.gameObject:SetActive(false)
        self.btnCreateHp.gameObject:SetActive(false)
        return
    end
    local bagHp = ModuleRefer.TroopModule:GetTroopHpBagCurHp(self.index)
    local neededHp = self:GetTroopNeededHp(self.index)
    self.btnAddHp.gameObject:SetActive(neededHp > 1 and bagHp > 0)
    self.btnCreateHp.gameObject:SetActive(neededHp > 1 and bagHp <= 0)
end

---@param index number
function HUDTroopBubbleHolder:GetTroopNeededHp(index)
    return ModuleRefer.TroopModule:GetTroopNeededHp(index)
end

function HUDTroopBubbleHolder:OnBtnAddHpClick()
    local troopInfo = HUDTroopUtils.GetTroopInfo(self.index)
    if troopInfo and HUDTroopUtils.IsTroopRetreating(troopInfo) then
        UITroopHelper.PopupTroopInRetreatAndRecoveryFailedConfirm()
        return
    end

    local bagHp = ModuleRefer.TroopModule:GetTroopHpBagCurHp(self.index)
    local neededHp = self:GetTroopNeededHp(self.index)
    local canHealHp = ModuleRefer.TroopModule:GetTroopCanHealHp(self.index)
    local withBag = bagHp < neededHp
    local taskId = ConfigRefer.ConstMain:TeamAlert()
    ---@type TaskItemDataProvider
    local task = require("TaskItemDataProvider").new(taskId)
    if DoNotShowAgainHelper.CanShowAgain("RecoverTroopPresetHp", DoNotShowAgainHelper.Cycle.Daily) and not task:IsTaskFinished() then
        UITroopHelper.PopupRecoveryHpConfirm(self.index, canHealHp, withBag)
    else
        ModuleRefer.TroopModule:RecoverTroopPresetHp(self.index - 1, withBag)
        canHealHp = ("%d"):format(math.floor(canHealHp))
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("toast_foodtohp_01", canHealHp))
    end
end

function HUDTroopBubbleHolder:OnBtnCreateHpClick()
    local foodCount = ModuleRefer.TroopModule:GetStockFoodCount()
    if foodCount <= 0 then
        UITroopHelper.PopupFoodNotEnoughConfirm(0)
    else
        UITroopHelper.PopupBagNotEnoughConfirm(self.index, self.btnCreateHp.transform)
    end
end

return HUDTroopBubbleHolder