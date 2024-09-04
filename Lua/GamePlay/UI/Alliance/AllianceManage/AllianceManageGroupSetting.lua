local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local AllianceModuleDefine = require("AllianceModuleDefine")
local UIMediatorNames = require("UIMediatorNames")
local InputFieldWithCheckStatus = require("InputFieldWithCheckStatus")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local DBEntityPath = require("DBEntityPath")
local Utils = require("Utils")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceManageGroupSetting:BaseUIComponent
---@field new fun():AllianceManageGroupSetting
---@field super BaseUIComponent
local AllianceManageGroupSetting = class('AllianceManageGroupSetting', BaseUIComponent)

function AllianceManageGroupSetting:ctor()
    BaseUIComponent.ctor(self)
    self._allowClickSave = false
    self._isAllianceLeader = false
    ---@type AllianceModuleCreateAllianceParameter
    self._createAllianceParameter = {
        name = '',
        abbr = '',
        notice = '',
        flag = wds.AllianceFlag.New(1, 1, 1),
        lang = 0,
        joinSetting = AllianceModuleDefine.JoinWithoutApply
    }
    self._allianceId = nil
    self._inEditFlag = false
end

function AllianceManageGroupSetting:OnCreate(param)
    self._p_img_area = self:Image("p_img_area")
    ---@type CommonAllianceLogoComponent
    self._child_league_logo = self:LuaObject("child_league_logo")
    self._p_status_basic = self:GameObject("p_status_basic")
    self._p_text_abbr = self:Text("p_text_abbr", "league_abbr")
    self._p_text_name = self:Text("p_text_name", "league_name")
    self._p_text_declaim = self:Text("p_text_declaim", "league_declaim")
    self._p_text_requirement = self:Text("p_text_requirement", "league_requirement")
    self._p_text_hint = self:Text("p_text_hint", "request_need")

    self._p_text_abbr_nomal = self:Text("p_text_abbr_nomal")
    self._p_text_name_normal = self:Text("p_text_name_normal")
    self._p_text_declaim_normal = self:Text("p_text_declaim_normal")
    self._child_toggle = self:Toggle("child_toggle", Delegate.GetOrCreate(self, self.OnJoinToggleChanged))
    self._p_icon_hint_base = self:Image("p_icon_hint_base")

    self._p_status_btns = self:GameObject("p_status_btns")

    self._p_text_abbr = self:Text("p_text_abbr", "league_abbr")
    self._p_input_abbr = self:Button("p_input_abbr", Delegate.GetOrCreate(self, self.OnClickInputAbbr))

    self._p_text_name = self:Text("p_text_name", "league_name")
    self._p_input_name = self:Button("p_input_name", Delegate.GetOrCreate(self, self.OnClickInputName))

    self._p_text_declaim = self:Text("p_text_declaim", "league_declaim")
    ---@type InputFieldWithCheckStatus
    self._p_input_declaim = InputFieldWithCheckStatus.new(self, "p_input_declaim")
    self._p_input_declaim:SetStatusTrans("p_status_a", "p_status_b", "p_status_c")
    self._p_input_declaim:SetAllowEmpty(true)
    self._p_btn_detail_declaim = self:Button("p_btn_detail_declaim", Delegate.GetOrCreate(self, self.OnClickCheckDetailDeclaim))

    self._p_comp_btn_design = self:Button("p_comp_btn_design", Delegate.GetOrCreate(self, self.OnClickBtnDesign))
    self._p_design_text = self:Text("p_design_text", "league_design")
    ---@type BistateButton
    self._child_comp_btn_b = self:LuaObject("child_comp_btn_b")

    ---@type AllianceCreationSetupFlagAndColorComponent
    self._p_status_logo = self:LuaObject("p_status_logo")
    ---@type CommonResourceRequirementComponent
    self._p_resources = self:LuaObject("p_resources")

    self._p_status_basic_trigger = self:AnimTrigger("p_status_basic")
    self._p_status_logo_trigger = self:AnimTrigger("p_status_logo")

    ---@type CommonResourceBtn
    self._child_btn_capsule = self:LuaObject("child_btn_capsule")

    self._p_text_language = self:Text("p_text_language", 'alliance_recruit_Shout_chat_title2')
    self._p_text_language_hint = self:Text("p_text_language_hint")
    self._p_group_hint_language = self:GameObject("p_group_hint_language")
    self._p_text = self:Text("p_text", "alliance_create_language_change")
    self._child_comp_btn_a_m_u2 = self:Button("child_comp_btn_a_m_u2", Delegate.GetOrCreate(self, self.OnClickBtnLanguage))

    self._p_btn_recruit = self:Button("p_btn_recruit", Delegate.GetOrCreate(self, self.OnClickBtnRecruit))
    self._p_text_recruit = self:Text("p_text_recruit", "alliance_recruit_button_set")
end

function AllianceManageGroupSetting:OnShow(param)
    self:FeedSubPart()
    if self._isAllianceLeader then
        self:FeedSaveButton()
    end

    self._p_input_declaim:SetCheckFunction(ModuleRefer.AllianceModule.CheckAllianceNotice)
    self._p_input_declaim:AddEvents()
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceBasicInfo.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceBriefInfoChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_CREATION_LANGUAGE_SELECT, Delegate.GetOrCreate(self, self.OnLanguageSelect))
end

function AllianceManageGroupSetting:OnHide(param)
    self._allianceId = nil
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_CREATION_LANGUAGE_SELECT, Delegate.GetOrCreate(self, self.OnLanguageSelect))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceBasicInfo.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceBriefInfoChanged))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    self._p_input_declaim:RemoveEvents()
    self._p_input_declaim:SetCheckFunction(nil)
end

function AllianceManageGroupSetting:OnClose(param)
    self._p_input_declaim:Release()
end

function AllianceManageGroupSetting:FeedSubPart()
    self._delayTickHideNode = nil
    self._delayTickHide = nil
    self._p_status_logo:SetVisible(false)
    self._p_status_basic:SetVisible(true)
    --self._p_resources:SetVisible(false)

    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    local allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceData()
    local allianceBasicInfo = allianceInfo.AllianceBasicInfo
    self._createAllianceParameter.flag = allianceBasicInfo.Flag
    self._createAllianceParameter.joinSetting = allianceBasicInfo.JoinSetting
    self._createAllianceParameter.lang = allianceBasicInfo.Language
    self._createAllianceParameter.abbr = allianceBasicInfo.Abbr
    self._createAllianceParameter.name = allianceBasicInfo.Name
    self._createAllianceParameter.notice = allianceBasicInfo.Notice

    self._child_league_logo:FeedData(self._createAllianceParameter.flag)
    local cfg = ConfigRefer.AllianceTerritoryColor:Find(self._createAllianceParameter.flag.TerritoryColor)
    if cfg then
        local success,color = CS.UnityEngine.ColorUtility.TryParseHtmlString(cfg:Color())
        self._p_img_area.color = success and color or CS.UnityEngine.Color.white
    else
        self._p_img_area.color = CS.UnityEngine.Color.white
    end
    self._child_toggle.transition = CS.UnityEngine.UI.Selectable.Transition.None
    self._child_toggle.isOn = self._createAllianceParameter.joinSetting == AllianceModuleDefine.JoinNeedApply
    self._p_text_abbr_nomal.text = self._createAllianceParameter.abbr or ''
    self._p_text_name_normal.text = self._createAllianceParameter.name
    local requireItemId,_ = ModuleRefer.AllianceModule.GetAllianceCostItemAndNum(ConfigRefer.AllianceConsts:AllianceModifyFlagCost())

    self._p_text_language_hint.text = AllianceModuleDefine.GetConfigLangaugeStr(self._createAllianceParameter.lang)

    local isAllianceLeader = ModuleRefer.AllianceModule:IsAllianceLeader()
    if isAllianceLeader then
        self._isAllianceLeader = true
        local item = requireItemId and ConfigRefer.Item:Find(requireItemId)
        ---@type CommonResourceBtnData
        local iconData = {
            iconName = item and item:Icon() or string.Empty,
            content = requireItemId and tostring(ModuleRefer.InventoryModule:GetAmountByConfigId(requireItemId)) or string.Empty,
            isShowPlus = false,
        }
        self._p_status_btns:SetVisible(true)
        self._child_btn_capsule:FeedData(iconData)
        self._child_btn_capsule:SetVisible(false) -- 2023.12 交互稿修改，不再显示资源栏
        self._child_toggle.interactable = true
        self._p_input_declaim._input.gameObject:SetVisible(true)
        self._p_text_declaim_normal:SetVisible(false)
        self._p_input_declaim:InitContent(self._createAllianceParameter.notice)
        self._p_icon_hint_base.enabled = true
        self._child_comp_btn_a_m_u2.gameObject:SetActive(true)
        self._p_btn_recruit.gameObject:SetActive(true)
    else
        self._isAllianceLeader = false
        self._p_status_btns:SetVisible(false)
        self._p_input_declaim._input.gameObject:SetVisible(false)
        self._child_btn_capsule:SetVisible(false)
        self._child_toggle.interactable = false
        self._p_text_declaim_normal:SetVisible(true)
        self._p_text_declaim_normal.text = self._createAllianceParameter.notice
        self._p_icon_hint_base.enabled = false
        self._child_comp_btn_a_m_u2.gameObject:SetActive(false)
        self._p_btn_recruit.gameObject:SetActive(false)
    end
end

function AllianceManageGroupSetting:FeedSaveButton()
    ---@type BistateButtonParameter
    local parameter = {
        onClick = Delegate.GetOrCreate(self, self.OnClickBtnSaveAllianceInfo),
        buttonText = I18N.Get("alliance_setting_change"),

    }
    self._child_comp_btn_b:FeedData(parameter)
end

function AllianceManageGroupSetting:OnClickInputAbbr()
    local requireItemId,need = ModuleRefer.AllianceModule.GetAllianceCostItemAndNum(ConfigRefer.AllianceConsts:AllianceModifyAbbrCost())
    ---@type CommonConfirmPopupMediatorParameter
    local parameter = {}
    parameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.WithInputCheck | CommonConfirmPopupMediatorDefine.Style.WithResource
    parameter.title = I18N.Get("league_abbr")
    parameter.content = ''
    parameter.confirmLabel = I18N.Get("alliance_setting_change")
    parameter.cancelLabel = I18N.Get("cancle")
    parameter.inputParameter = {initText = self._createAllianceParameter.abbr, checkFunc = ModuleRefer.AllianceModule.CheckAllianceAbbr, contentType = CS.UnityEngine.UI.InputField.ContentType.Alphanumeric}
    ---@type CommonResourceRequirementComponentParameter
    local requireParameter = {}
    parameter.resourceParameter = requireParameter
    requireParameter.requireId = requireItemId
    requireParameter.requireType = 2
    requireParameter.requireValue = need
    parameter.onConfirm = function(context,inputStatus,inputValue)
        if inputStatus ~= InputFieldWithCheckStatus.Status.Pass then
            return false
        end
        local count = requireItemId and ModuleRefer.InventoryModule:GetAmountByConfigId(requireItemId)
        if count and need > count then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_setting_nomoney"))
            return false
        else
            local lastPopId = context
            ---@type CommonConfirmPopupMediatorParameter
            local doubleConfirmParameter = {}
            doubleConfirmParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
            doubleConfirmParameter.content = I18N.GetWithParams("alliance_setting_change_abbr", tostring(need))
            doubleConfirmParameter.confirmLabel = I18N.Get("confirm")
            doubleConfirmParameter.cancelLabel = I18N.Get("cancle")
            doubleConfirmParameter.onConfirm = function(_)
                ModuleRefer.AllianceModule:SetAllianceAbbrParameter(inputValue, function(_, isSuccess, _)
                    if isSuccess then
                        g_Game.UIManager:Close(lastPopId)
                    end
                end)
                return true
            end
            g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, doubleConfirmParameter, nil, true)
            return false
        end
    end
    parameter.context = g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, parameter)
end

function AllianceManageGroupSetting:OnClickInputName()
    local needItemId,need = ModuleRefer.AllianceModule.GetAllianceCostItemAndNum(ConfigRefer.AllianceConsts:AllianceModifyNameCost())
    ---@type CommonConfirmPopupMediatorParameter
    local parameter = {}
    parameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.WithInputCheck | CommonConfirmPopupMediatorDefine.Style.WithResource
    parameter.title = I18N.Get("league_name")
    parameter.confirmLabel = I18N.Get("alliance_setting_change")
    parameter.cancelLabel = I18N.Get("cancle")
    parameter.inputParameter = {initText = self._createAllianceParameter.name, checkFunc = ModuleRefer.AllianceModule.CheckAllianceName}
    ---@type CommonResourceRequirementComponentParameter
    local requireParameter = {}
    parameter.resourceParameter = requireParameter
    requireParameter.requireId = needItemId
    requireParameter.requireType = 2
    requireParameter.requireValue = need
    parameter.onConfirm = function(context,inputStatus,inputValue)
        if inputStatus ~= InputFieldWithCheckStatus.Status.Pass then
            return false
        end
        local count = needItemId and ModuleRefer.InventoryModule:GetAmountByConfigId(needItemId)
        if count and need > count then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_setting_nomoney"))
            return false
        else
            local lastPopId = context
            ---@type CommonConfirmPopupMediatorParameter
            local doubleConfirmParameter = {}
            doubleConfirmParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
            doubleConfirmParameter.content = I18N.GetWithParams("alliance_setting_change_name", tostring(need))
            doubleConfirmParameter.confirmLabel = I18N.Get("confirm")
            doubleConfirmParameter.cancelLabel = I18N.Get("cancle")
            doubleConfirmParameter.onConfirm = function(_)
                ModuleRefer.AllianceModule:SetAllianceNameParameter(inputValue, function(_, isSuccess, _)
                    if isSuccess then
                        g_Game.UIManager:Close(lastPopId)
                    end
                end)
                return true
            end
            g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, doubleConfirmParameter, nil, true)
            return false
        end
    end
    parameter.context = g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, parameter)
end

function AllianceManageGroupSetting:OnClickCheckDetailDeclaim()
    self:CheckAndShowErrorTip(self._p_input_declaim, self._p_btn_detail_declaim)
end

---@param input InputFieldWithCheckStatus
---@param target CS.UnityEngine.UI.Button
function AllianceManageGroupSetting:CheckAndShowErrorTip(input, target)
    local lastErrorCode,lastError = input:GetLastError()
    if not lastErrorCode or lastErrorCode == 0 then
        return
    end
    ---@type CommonTipPopupMediatorParameter
    local tipParameter = {}
    tipParameter.targetTrans = target:GetComponent(typeof(CS.UnityEngine.RectTransform))
    tipParameter.text = I18N.Get(lastError)
    g_Game.UIManager:Open(UIMediatorNames.CommonTipPopupMediator, tipParameter)
end

function AllianceManageGroupSetting:OnClickBtnDesign()
    self._delayTickHide = nil
    self._delayTickHideNode = nil
    if Utils.IsNotNull(self._p_status_basic_trigger) then
        self._p_status_basic:SetVisible(true)
        self._p_status_basic_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
        self._delayTickHide = self._p_status_basic_trigger:GetTriggerTypeAnimLength(CS.FpAnimation.CommonTriggerType.Custom2)
        self._delayTickHideNode = self._p_status_basic
    else
        self._p_status_basic:SetVisible(false)
    end
    self._p_resources:SetVisible(true)
    self._p_status_logo:SetVisible(true)
    if Utils.IsNotNull(self._p_status_logo_trigger) then
        self._p_status_logo_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
    local requireItemId,requireCount = ModuleRefer.AllianceModule.GetAllianceCostItemAndNum(ConfigRefer.AllianceConsts:AllianceModifyFlagCost())

    --self._p_resources:SetVisible(true)
    ---@type CommonResourceRequirementComponentParameter
    local resourceRequireParameter = {
        iconComponent = "p_icon",
        numberComponent = "p_text_quantity",
        requireId = requireItemId,
        requireValue = requireCount,
        normalColor = CS.UnityEngine.Color(36.0/255, 38.0/255, 48.0/255, 1.0),
        notEnoughColor = CS.UnityEngine.Color.red,
        requireType = 2
    }
    self._p_resources:FeedData(resourceRequireParameter)
    ---@type AllianceCreationSetupFlagAndColorComponentParameter
    local parameter = {
        flag = self._child_league_logo,
        areaImage = self._p_img_area,
        originData = self._createAllianceParameter.flag,
        onConfirm = Delegate.GetOrCreate(self, self.OnClickBtnSaveFlag),
        onCancel = Delegate.GetOrCreate(self, self.OnClickBtnCancelFlagEdit),
        disableConfirmWhenNoChange = true
    }
    self._p_status_logo:FeedData(parameter)
    self._inEditFlag = true
end

---@param newValue wds.AllianceFlag
function AllianceManageGroupSetting:OnClickBtnSaveFlag(newValue, btnTrans)
    if self._p_resources:GetIsEnough() then
        self._createAllianceParameter.flag = newValue
        self._child_league_logo:FeedData(self._createAllianceParameter.flag)
        self._delayTickHide = nil
        self._delayTickHideNode = nil
        if Utils.IsNotNull(self._p_status_logo_trigger) then
            self._p_status_logo:SetVisible(true)
            self._p_status_logo_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
            self._delayTickHide = self._p_status_logo_trigger:GetTriggerTypeAnimLength(CS.FpAnimation.CommonTriggerType.Custom2)
            self._delayTickHideNode = self._p_status_logo
        else
            self._p_status_logo:SetVisible(false)
        end
        self._p_status_basic:SetVisible(true)
        if Utils.IsNotNull(self._p_status_basic_trigger) then
            self._p_status_basic_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        end

        --self._p_resources:SetVisible(false)
        ModuleRefer.AllianceModule:SetAllianceFlagParameter(newValue, btnTrans, function(cmd, isSuccess, rsp)
            if isSuccess then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_setting_finish_edit"))
            else
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_setting_unmodified"))
            end
        end)
        self._inEditFlag = false
        self._p_resources:SetVisible(false)
    else
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_setting_nomoney"))
    end
end

function AllianceManageGroupSetting:OnClickBtnRecruit()
    g_Game.UIManager:Open(UIMediatorNames.AllianceRecruitSettingMediator, {showSend = false})
end

function AllianceManageGroupSetting:TickFadeChangeTab(dt)
    if not self._delayTickHide then
        return
    end
    self._delayTickHide = self._delayTickHide - dt
    if self._delayTickHide <= 0 then
        self._delayTickHide = nil
        if self._delayTickHideNode then
            self._delayTickHideNode:SetVisible(false)
        end
        self._delayTickHideNode = nil
    end
end

function AllianceManageGroupSetting:OnClickBtnLanguage()
    ---@type AllianceCreationLanguageSelectMediatorParam
    local data = {}
    data.selectedLangId = self._createAllianceParameter.lang
    g_Game.UIManager:Open(UIMediatorNames.AllianceCreationLanguageSelectMediator, data)
end

function AllianceManageGroupSetting:OnClickBtnCancelFlagEdit()
    self._child_league_logo:FeedData(self._createAllianceParameter.flag)
    self._delayTickHide = nil
    self._delayTickHideNode = nil
    if Utils.IsNotNull(self._p_status_logo_trigger) then
        self._p_status_logo:SetVisible(true)
        self._p_status_logo_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
        self._delayTickHide = self._p_status_logo_trigger:GetTriggerTypeAnimLength(CS.FpAnimation.CommonTriggerType.Custom2)
        self._delayTickHideNode = self._p_status_logo
    else
        self._p_status_logo:SetVisible(false)
    end
    self._p_status_basic:SetVisible(true)
    if Utils.IsNotNull(self._p_status_basic_trigger) then
        self._p_status_basic_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
    self._p_resources:SetVisible(false)
    self._inEditFlag = false
end

function AllianceManageGroupSetting:OnClickBtnSaveAllianceInfo()
    local noticeStatus,notice = self._p_input_declaim:GetInputContent()
    if noticeStatus ~= InputFieldWithCheckStatus.Status.Pass
            and noticeStatus ~= InputFieldWithCheckStatus.Status.Init then
        return
    end
    self._createAllianceParameter.notice = notice
    local allianceBasicInfo = ModuleRefer.AllianceModule:GetMyAllianceBasicInfo()
    if UNITY_DEBUG then
        assert(allianceBasicInfo, "allianceBasicInfo is nil")
    elseif not allianceBasicInfo then
        g_Logger.Error("allianceBasicInfo is nil")
        return
    end
    if allianceBasicInfo.Notice == self._createAllianceParameter.notice and allianceBasicInfo.Language == self._createAllianceParameter.lang and allianceBasicInfo.JoinSetting == self._createAllianceParameter.joinSetting then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_setting_unmodified"))
        return
    end
    ModuleRefer.AllianceModule:SetAllianceBasicInfo(self._createAllianceParameter.notice, self._createAllianceParameter.lang, self._createAllianceParameter.joinSetting, function(cmd, isSuccess, rsp)
        if isSuccess then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_setting_finish_edit"))
        else
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_setting_unmodified"))
        end
    end)
end

---@param isOn boolean
function AllianceManageGroupSetting:OnJoinToggleChanged(isOn)
    local choose = isOn and AllianceModuleDefine.JoinNeedApply or AllianceModuleDefine.JoinWithoutApply
    if choose ~= self._createAllianceParameter.joinSetting then
        self._createAllianceParameter.joinSetting = choose
        self._allianceInfoDirty = true
    end
end

---@param entity wds.Alliance
function AllianceManageGroupSetting:OnAllianceBriefInfoChanged(entity, changedData)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    self:FeedSubPart()
end

---@param langId number
function AllianceManageGroupSetting:OnLanguageSelect(langId)
    self._createAllianceParameter.lang = langId
    self._p_text_language_hint.text = AllianceModuleDefine.GetConfigLangaugeStr(langId)
end

function AllianceManageGroupSetting:Tick(dt)
    if not self._isAllianceLeader then
        return
    end
    local allowCreate = false
    repeat
        if self._p_input_declaim:GetStatus() ~= InputFieldWithCheckStatus.Status.Pass then
            break
        end
        allowCreate = true
    until true
    if self._allowClickSave ~= allowCreate then
        self._allowClickSave = allowCreate
        self._child_comp_btn_b:SetEnabled(self._allowClickSave)
    end
    self:TickFadeChangeTab(dt)
end

function AllianceManageGroupSetting:CheckBeforeExit(continue)
    if not ModuleRefer.AllianceModule:IsAllianceLeader() then
        return true
    end
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    local basicData = allianceData.AllianceBasicInfo
    local s,n = self._p_input_declaim:GetInputContent()
    if self._inEditFlag
            or basicData.JoinSetting ~= self._createAllianceParameter.joinSetting
            or s == InputFieldWithCheckStatus.Status.Checking
            or n ~= basicData.Notice
    then
        ---@type CommonConfirmPopupMediatorParameter
        local confirmPop = {}
        confirmPop.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
        confirmPop.confirmLabel = I18N.Get("confirm")
        confirmPop.cancelLabel = I18N.Get("cancle")
        confirmPop.content = I18N.Get("alliance_setting_chang_cancel")
        confirmPop.onConfirm = function()
            if self._inEditFlag then
                self:OnClickBtnCancelFlagEdit()
            end
            if continue then
                continue()
            end
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmPop)
        return false
    end
    return true
end

return AllianceManageGroupSetting