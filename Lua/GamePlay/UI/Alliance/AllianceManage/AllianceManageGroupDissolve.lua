local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local BistateButton = require("BistateButton")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceManageGroupDissolve:BaseUIComponent
---@field new fun():AllianceManageGroupDissolve
---@field super BaseUIComponent
local AllianceManageGroupDissolve = class('AllianceManageGroupDissolve', BaseUIComponent)

function AllianceManageGroupDissolve:ctor()
    BaseUIComponent.ctor(self)
    self._checkStr = ""
    self._canDisband = false
    self._eventAdd = false
end

function AllianceManageGroupDissolve:OnCreate(param)
    self._p_text_content = self:Text("p_text_content", "alliance_retire_disband_details_title")
    ---@type BistateButton
    self._p_comp_btn_dissolve = self:LuaObject("p_comp_btn_dissolve")
    self._p_table_require = self:TableViewPro("p_table_require")
    self._p_text_influence = self:Text("p_text_influence", "alliance_retire_disband_effects_title")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickSeeDetailTip))
end

function AllianceManageGroupDissolve:OnShow(param)
    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    self:SetupEvents(true)
    self:RefreshUi()
end

function AllianceManageGroupDissolve:OnHide(param)
    self._allianceId = nil
    self:SetupEvents(false)
end

function AllianceManageGroupDissolve:OnClose(param)
    self:SetupEvents(false)
end

function AllianceManageGroupDissolve:SetupEvents(add)
    if not self._eventAdd and add then
        self._eventAdd = true
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    elseif self._eventAdd and not add then
        self._eventAdd = false
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    end
end

function AllianceManageGroupDissolve:OnClickBtnDissolve()
    local joinCd = ModuleRefer.AllianceModule:GetJoinAllianceCD()
    local joinCDStr = joinCd > 60 and ("%dm"):format(math.floor(joinCd // 60 + 0.5)) or ("%ds"):format(math.floor(joinCd + 0.5))
    ---@type CommonConfirmPopupMediatorParameter
    local param = {}
    param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    param.content = I18N.GetWithParams("alliance_retire_disband_makesure", joinCDStr)
    param.confirmLabel = I18N.Get("confirm")
    param.cancelLabel = I18N.Get("cancle")
    param.onConfirm = function()
        ModuleRefer.AllianceModule:DisbandAlliance()
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
end

function AllianceManageGroupDissolve:OnClickSeeDetailTip()
    ---@type TextToastMediatorParameter
    local parameter = {}
    parameter.clickTransform = self._p_btn_detail.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    parameter.content = I18N.Get("alliance_retire_disband_effects_desc1")
            .. '\n' .. I18N.Get("alliance_retire_disband_effects_desc2")
            .. '\n' .. I18N.Get("alliance_retire_disband_effects_desc3")
            .. '\n' .. I18N.Get("alliance_retire_disband_effects_desc4")
            .. '\n' .. I18N.Get("alliance_retire_disband_effects_desc5")
    ModuleRefer.ToastModule:ShowTextToast(parameter)
end

function AllianceManageGroupDissolve:RefreshUi()
    self._canDisband = true
    ---@type BistateButtonParameter
    local btnData = {}
    btnData.onClick = Delegate.GetOrCreate(self, self.OnClickBtnDissolve)
    btnData.disableClick = function() 
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_retire_disband_disable"))
    end
    btnData.buttonText = I18N.Get("alliance_retire_disband_btn")
    btnData.disableButtonText = I18N.Get("alliance_retire_disband_btn")
    btnData.buttonState = BistateButton.BUTTON_TYPE.RED
    self._p_comp_btn_dissolve:FeedData(btnData)
    self._p_table_require:Clear()

    if not self:AppendMemberCheck() then
        self._canDisband = false
    end
    if not self:AppendAllianceBuildingCheck() then
        self._canDisband = false
    end
    if not self:AppendAllianceVillageCheck() then
        self._canDisband = false
    end
    if not self:AppendAllianceNoVillageWarCheck() then
        self._canDisband = false
    end
    if not self:AppendAllianceNoGVECheck() then
        self._canDisband = false
    end
    self._p_comp_btn_dissolve:SetEnabled(self._canDisband)
end

function AllianceManageGroupDissolve:OnLeaveAlliance(allianceId)
    if self._allianceId and self._allianceId == allianceId then
        local mediator = self:GetParentBaseUIMediator()
        if mediator then
            mediator:CloseSelf()
        end
    end
end

function AllianceManageGroupDissolve:AppendMemberCheck()
    ---@type AllianceManageGroupDissolveCellData
    local cellData = {}
    cellData.content = I18N.Get("alliance_retire_disband_details_desc1")
    cellData.isSatisfied = ModuleRefer.AllianceModule:IsOnlyLeaderLeft()
    if not cellData.isSatisfied then
        cellData.gotoFunc = function()
            g_Game.UIManager:Open(UIMediatorNames.AllianceMemberMediator)
        end
    end
    self._p_table_require:AppendData(cellData)
    return cellData.isSatisfied
end

function AllianceManageGroupDissolve:AppendAllianceBuildingCheck()
    ---@type AllianceManageGroupDissolveCellData
    local cellData = {}
    cellData.content = I18N.Get("alliance_retire_disband_details_desc2")
    cellData.isSatisfied = ModuleRefer.AllianceModule:HasNoneAllianceBuilding()
    if not cellData.isSatisfied then
        cellData.gotoFunc = function()
            ---@type AllianceTerritoryMainMediatorParameter
            local param = {}
            param.entryTab = 3
            g_Game.UIManager:Open(UIMediatorNames.AllianceTerritoryMainMediator, param)
        end
    end
    self._p_table_require:AppendData(cellData)
    return cellData.isSatisfied
end

function AllianceManageGroupDissolve:AppendAllianceVillageCheck()
    ---@type AllianceManageGroupDissolveCellData
    local cellData = {}
    cellData.content = I18N.Get("alliance_retire_disband_details_desc3")
    local villages = ModuleRefer.VillageModule:GetAllVillageMapBuildingBrief()
    cellData.isSatisfied = table.isNilOrZeroNums(villages)
    if not cellData.isSatisfied then
        cellData.gotoFunc = function()
            ---@type AllianceTerritoryMainMediatorParameter
            local param = {}
            param.entryTab = 2
            g_Game.UIManager:Open(UIMediatorNames.AllianceTerritoryMainMediator, param)
        end
    end
    self._p_table_require:AppendData(cellData)
    return cellData.isSatisfied
end

function AllianceManageGroupDissolve:AppendAllianceNoVillageWarCheck()
    ---@type AllianceManageGroupDissolveCellData
    local cellData = {}
    cellData.content = I18N.Get("alliance_retire_disband_details_desc4")
    local villageWar = ModuleRefer.AllianceModule:GetMyAllianceVillageWars()
    cellData.isSatisfied = table.isNilOrZeroNums(villageWar)
    if not cellData.isSatisfied then
        cellData.gotoFunc = function()
            ---@type AllianceWarMediatorParameter
            local parameter = {}
            parameter.enterTabIndex = 2
            g_Game.UIManager:Open(UIMediatorNames.AllianceWarNewMediator, parameter)
        end
    end
    self._p_table_require:AppendData(cellData)
    return cellData.isSatisfied
end

function AllianceManageGroupDissolve:AppendAllianceNoGVECheck()
    ---@type AllianceManageGroupDissolveCellData
    local cellData = {}
    cellData.content = I18N.Get("alliance_retire_disband_details_desc5")
    local noWar,id = ModuleRefer.AllianceModule:HasNoneActivityBattle()
    cellData.isSatisfied = noWar
    if not cellData.isSatisfied then
        cellData.gotoFunc = function()
            g_Game.UIManager:Open(UIMediatorNames.AllianceBehemothListMediator)
        end
    end
    self._p_table_require:AppendData(cellData)
    return cellData.isSatisfied
end

return AllianceManageGroupDissolve