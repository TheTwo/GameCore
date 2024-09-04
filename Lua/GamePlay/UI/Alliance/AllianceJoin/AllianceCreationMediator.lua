--- scene:scene_league_create

local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local InputFieldWithCheckStatus = require("InputFieldWithCheckStatus")
local ConfigRefer = require("ConfigRefer")
local AllianceModule = require("AllianceModule")
local UIMediatorNames = require("UIMediatorNames")
local AllianceModuleDefine = require("AllianceModuleDefine")
local I18N = require("I18N")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local FPXSDKBIDefine = require("FPXSDKBIDefine")
local UIHelper = require("UIHelper")
local TimeFormatter = require("TimeFormatter")
local city = require('ModuleRefer').CityModule.myCity
local BaseUIMediator = require("BaseUIMediator")

---@class AllianceCreationMediator:BaseUIMediator
---@field new fun():AllianceCreationMediator
---@field super BaseUIMediator
local AllianceCreationMediator = class('AllianceCreationMediator', BaseUIMediator)

function AllianceCreationMediator:ctor()
    BaseUIMediator.ctor(self)
    self._allowCreate = true
    ---@type AllianceModuleCreateAllianceParameter
    self._createAllianceParameter = {
        name = '',
        abbr = '',
        notice = '',
        flag = wds.AllianceFlag.New(1, 1, 1),
        lang = 0,
        joinSetting = AllianceModuleDefine.JoinWithoutApply
    }

    ---@type number[]
    self._badgeAppearanceIds = {}
    ---@type number[]
    self._badgePatternIds = {}
    ---@type number[]
    self._territoryColorIds = {}
end

function AllianceCreationMediator:OnCreate(param)
    ---@type CommonBackButtonComponent
    self._child_common_btn_back = self:LuaObject("child_common_btn_back")
    ---@type CommonResourceBtn
    self._child_btn_capsule = self:LuaObject("child_btn_capsule")

    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickGoToJoin))
    self._p_text_go_join = self:Text("p_text_go_join", "join_league")

    self._p_img_area = self:Image("p_img_area")
    ---@type CommonAllianceLogoComponent
    self._child_league_logo = self:LuaObject("child_league_logo")

    self._p_status_basic = self:Transform("p_status_basic")

    self._p_text_abbr = self:Text("p_text_abbr", "league_abbr")
    self._p_input_abbr = InputFieldWithCheckStatus.new(self, "p_input_abbr", self:GetAbbrPlaceHolder())
    self._p_input_abbr:SetStatusTrans("p_status_a_abbr", "p_status_b_abbr", "p_status_c_abbr")
    self._p_btn_detail_abbr = self:Button("p_btn_detail_abbr", Delegate.GetOrCreate(self, self.OnClickCheckDetailAbbr))
    self._p_text_abbr_num = self:Text("p_text_count")

    self._p_text_name = self:Text("p_text_name", "league_name")
    self._p_input_name = InputFieldWithCheckStatus.new(self, "p_input_name", self:GetNamePlaceHolder())
    self._p_input_name:SetStatusTrans("p_status_a_name", "p_status_b_name", "p_status_c_name")
    self._p_btn_detail_name = self:Button("p_btn_detail_name", Delegate.GetOrCreate(self, self.OnClickCheckDetailName))
    self._p_text_name_num = self:Text("p_text_count_1")

    self._p_text_declaim = self:Text("p_text_declaim", "league_declaim")
    self._p_input_declaim = InputFieldWithCheckStatus.new(self, "p_input_declaim", self:GetNoticePlaceHolder())
    self._p_input_declaim:SetStatusTrans("p_status_a", "p_status_b", "p_status_c")
    self._p_input_declaim:SetAllowEmpty(true)
    self._p_btn_detail_declaim = self:Button("p_btn_detail_declaim", Delegate.GetOrCreate(self, self.OnClickCheckDetailDeclaim))
    self._p_text_declaim_num = self:Text("p_text_count_2")

    self._p_text_requirement = self:Text("p_text_requirement", "league_requirement")
    self._p_text_hint = self:Text("p_text_hint", "request_need")
    self._child_toggle = self:Toggle("child_toggle", Delegate.GetOrCreate(self, self.OnToggleChanged))

    self._p_comp_btn_disign = self:Button("p_comp_btn_disign", Delegate.GetOrCreate(self, self.OnClickDesignBtn))
    self._p_text_design_btn = self:Text("p_text_design_btn", "league_design")

    ---@type CommonResourceRequirementComponent
    self._p_resources = self:LuaObject("p_resources")
    ---@type BistateButton
    self._child_comp_btn_b = self:LuaObject("child_comp_btn_b")

    ---@type AllianceCreationSetupFlagAndColorComponent
    self._p_status_logo = self:LuaObject("p_status_logo")

    self._p_title_language = self:Text("p_title_language", "alliance_recruit_Shout_chat_title2")
    self._p_text_language = self:Text("p_text_language")
    self._p_text = self:Text("p_text", "alliance_create_language_change")
    self._child_comp_btn_a_m_u2 = self:Button("child_comp_btn_a_m_u2", Delegate.GetOrCreate(self, self.OnClickSelectLanguage))

    self._p_btn_random = self:Button("p_btn_random", Delegate.GetOrCreate(self, self.OnClickRandom))
end

function AllianceCreationMediator:OnShow(param)
    self:FeedSubPart()
    self:FeedCreateButton()
    self:AddEvents()
end

function AllianceCreationMediator:OnHide(param)
    self:RemoveEvents()
end

function AllianceCreationMediator:OnClose(data)
    self._p_input_abbr:Release()
    self._p_input_name:Release()
    self._p_input_declaim:Release()
    self.super.OnClose(self, data)
end

function AllianceCreationMediator:AddEvents()
    self._p_input_abbr:SetCheckFunction(ModuleRefer.AllianceModule.CheckAllianceAbbr)
    self._p_input_abbr:SetCustomOnEndCheck(Delegate.GetOrCreate(self, self.OnAbbrCustomCheckEnd))
    self._p_input_name:SetCheckFunction(ModuleRefer.AllianceModule.CheckAllianceName)
    self._p_input_name:SetCustomOnEndCheck(Delegate.GetOrCreate(self, self.OnNameCustomCheckEnd))
    self._p_input_declaim:SetCheckFunction(ModuleRefer.AllianceModule.CheckAllianceNotice)
    self._p_input_declaim:SetCustomOnEndCheck(Delegate.GetOrCreate(self, self.OnDeclaimCustomCheckEnd))

    -- self._p_input_declaim:TransToStatus(InputFieldWithCheckStatus.Status.Pass)

    self._p_input_abbr:AddEvents()
    self._p_input_name:AddEvents()
    self._p_input_declaim:AddEvents()
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, Delegate.GetOrCreate(self, self.OnJoinAlliance))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_CREATION_LANGUAGE_SELECT, Delegate.GetOrCreate(self, self.OnLanguageSelect))
end

function AllianceCreationMediator:RemoveEvents()
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_JOINED_WITH_DATA_READY, Delegate.GetOrCreate(self, self.OnJoinAlliance))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_CREATION_LANGUAGE_SELECT, Delegate.GetOrCreate(self, self.OnLanguageSelect))
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    self._p_input_declaim:RemoveEvents()
    self._p_input_name:RemoveEvents()
    self._p_input_abbr:RemoveEvents()

    self._p_input_declaim:SetCheckFunction(nil)
    self._p_input_declaim:SetCustomOnEndCheck(nil)
    self._p_input_name:SetCheckFunction(nil)
    self._p_input_name:SetCustomOnEndCheck(nil)
    self._p_input_abbr:SetCheckFunction(nil)
    self._p_input_abbr:SetCustomOnEndCheck(nil)
end

function AllianceCreationMediator:FeedSubPart()
    ---@type CommonBackButtonData
    local btnData = {
        title = I18N.Get("create_league")
    }
    self._child_common_btn_back:FeedData(btnData)

    local furnitureId = ConfigRefer.AllianceConsts:AllianceCreateCostRelateFurniture()
    local furniture = city.furnitureManager:GetFurnitureByTypeCfgId(furnitureId)
    local level = 1
    if furniture == nil then
        ModuleRefer.ToastModule:AddSimpleToast("AllianceConsts:AllianceCreateCostRelateFurniture : "..furnitureId)
        g_Logger.Error("尚未拥有家具 AllianceConsts:AllianceCreateCostRelateFurniture : " ..furnitureId)
    else
        level = furniture.level
    end

    local length = ConfigRefer.AllianceConsts:AllianceCreateCostsToFurnitureLevelLength()
    local index = level <= length and level or length
    local itemGroup = ConfigRefer.AllianceConsts:AllianceCreateCostsToFurnitureLevel(index)

    local requireItemId,requireCount = ModuleRefer.AllianceModule.GetAllianceCostItemAndNum(itemGroup)
    local item = requireItemId and ConfigRefer.Item:Find(requireItemId)

    ---@type CommonResourceBtnData
    local iconData = {
        iconName = item and item:Icon() or string.Empty,
        content = requireItemId and tostring(ModuleRefer.InventoryModule:GetAmountByConfigId(requireItemId)) or string.Empty,
        isShowPlus = false,
    }
    self._child_btn_capsule:FeedData(iconData)

    self._child_league_logo:FeedData(self._createAllianceParameter.flag)

    self._child_toggle.isOn = self._createAllianceParameter.joinSetting == AllianceModuleDefine.JoinNeedApply

    ---@type CommonResourceRequirementComponentParameter
    local resourceRequireParameter = {
        iconComponent = "p_icon",
        numberComponent = "p_text_quantity",
        requireId = requireItemId,
        requireValue = requireCount,
        normalColor = CS.UnityEngine.Color(241.0/255, 230.0/255, 224.0/255, 1.0),
        notEnoughColor = CS.UnityEngine.Color.red,
        requireType = 2
    }
    self._p_resources:FeedData(resourceRequireParameter)
    self:UpdateLanguageText()

    for _, v in ConfigRefer.AllianceBadgeAppearance:ipairs() do
        table.insert(self._badgeAppearanceIds, v:Id())
    end
    for _, v in ConfigRefer.AllianceBadgePattern:ipairs() do
        table.insert(self._badgePatternIds, v:Id())
    end
    for _, v in ConfigRefer.AllianceTerritoryColor:ipairs() do
        table.insert(self._territoryColorIds, v:Id())
    end
    self:OnClickRandom() -- 2024/01/04 联盟初始化选择头像的时候，默认进行一个随机
end

function AllianceCreationMediator:FeedCreateButton()
    ---@type BistateButtonParameter
    local parameter = {
        onClick = Delegate.GetOrCreate(self, self.OnClickCreateBtn),
        disableClick = Delegate.GetOrCreate(self, self.OnDisableClick),
        buttonText = "confirm",

    }
    self._child_comp_btn_b:FeedData(parameter)
end

function AllianceCreationMediator:Tick(_)
    local allowCreate = false
    repeat
        if self._p_input_abbr:GetStatus() ~= InputFieldWithCheckStatus.Status.Pass then
            break
        end
        if self._p_input_name:GetStatus() ~= InputFieldWithCheckStatus.Status.Pass then
            break
        end
        local _, content = self._p_input_declaim:GetInputContent()
        if (self._p_input_declaim:GetStatus() ~= InputFieldWithCheckStatus.Status.Pass)
        and not (content):IsNullOrEmpty()
        then
            break
        end
        if not self._p_resources:GetIsEnough() then
            break
        end
        if ModuleRefer.AllianceModule:IsAllianceCreationInCD() then
            break
        end
        allowCreate = true
    until true
    if self._allowCreate ~= allowCreate then
        self._allowCreate = allowCreate
        self._child_comp_btn_b:SetEnabled(self._allowCreate)
    end
    AllianceCreationMediator.UpdateInputLengthInspector(self._p_input_abbr._input.text, ConfigRefer.AllianceConsts:AllianceAbbrLenMax(), self._p_text_abbr_num)
    AllianceCreationMediator.UpdateInputLengthInspector(self._p_input_name._input.text, ConfigRefer.AllianceConsts:AllianceNameLenMax(), self._p_text_name_num)
    AllianceCreationMediator.UpdateInputLengthInspector(self._p_input_declaim._input.text, ConfigRefer.AllianceConsts:AllianceNoticeLenMax(), self._p_text_declaim_num)
end

function AllianceCreationMediator.UpdateInputLengthInspector(text, maxLength, targetLabel)
    local length = text and utf8.len(text) or 0
    targetLabel.text = ("(%d/%d)"):format(length, maxLength)
end

function AllianceCreationMediator:OnToggleChanged(isOn)
    self._createAllianceParameter.joinSetting = (isOn and AllianceModuleDefine.JoinNeedApply) or AllianceModuleDefine.JoinWithoutApply
end

function AllianceCreationMediator:OnClickGoToJoin()
    self:CloseSelf(nil, true)
    g_Game.UIManager:Open(UIMediatorNames.AllianceJoinMediator)
end

function AllianceCreationMediator:OnClickDesignBtn()
    self._p_status_basic:SetVisible(false)
    self._p_status_logo:SetVisible(true)
    ---@type AllianceCreationSetupFlagAndColorComponentParameter
    local parameter = {
        flag = self._child_league_logo,
        areaImage = self._p_img_area,
        originData = self._createAllianceParameter.flag,
        onConfirm = function(newValue)
            AllianceModule.CopyFlagSetting(newValue, self._createAllianceParameter.flag)
            self._p_status_logo:SetVisible(false)
            self._p_status_basic:SetVisible(true)
        end,
        onCancel = function()
            self._p_status_logo:SetVisible(false)
            self._p_status_basic:SetVisible(true)
        end
    }
    self._p_status_logo:FeedData(parameter)
end

function AllianceCreationMediator:OnClickCreateBtn()
    if not self._allowCreate then
        return
    end
    local nameStatus,name = self._p_input_name:GetInputContent()
    if nameStatus ~= InputFieldWithCheckStatus.Status.Pass then
        return
    end
    local abbrStatus,abbr = self._p_input_abbr:GetInputContent()
    if abbrStatus ~= InputFieldWithCheckStatus.Status.Pass then
        return
    end
    local noticeStatus,notice = self._p_input_declaim:GetInputContent()
    if noticeStatus ~= InputFieldWithCheckStatus.Status.Pass
            and noticeStatus ~= InputFieldWithCheckStatus.Status.Init  then
        return
    end
    if string.IsNullOrEmpty(notice) then
        notice = self:GetNoticePlaceHolder()
    end
    ---@type CommonConfirmPopupMediatorParameter
    local popupData = {}
    popupData.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel

    local furnitureId = ConfigRefer.AllianceConsts:AllianceCreateCostRelateFurniture()
    local furniture = city.furnitureManager:GetFurnitureByTypeCfgId(furnitureId)
    local level = 1
    if furniture == nil then
        g_Logger.Error("尚未拥有家具 AllianceConsts:AllianceCreateCostRelateFurniture : " ..furnitureId)
    else
        level = furniture.level
    end
    local length = ConfigRefer.AllianceConsts:AllianceCreateCostsToFurnitureLevelLength()
    local index = level <= length and level or length
    local itemGroup = ConfigRefer.AllianceConsts:AllianceCreateCostsToFurnitureLevel(index)

    local _,costItemCount = ModuleRefer.AllianceModule.GetAllianceCostItemAndNum(itemGroup)

    popupData.content = I18N.GetWithParams("creation_confirm", tostring(costItemCount))
    popupData.confirmLabel = I18N.Get("confirm")
    popupData.cancelLabel = I18N.Get("cancle")
    popupData.onConfirm = function(_)
        self._createAllianceParameter.name = name
        self._createAllianceParameter.abbr = abbr
        self._createAllianceParameter.notice = notice
        ModuleRefer.AllianceModule:SendCreateAlliance(self._createAllianceParameter, function(cmd, isSuccess, rsp)
            if isSuccess then
                local keyMap = FPXSDKBIDefine.ExtraKey.alliance_creat
                local extraMap = {}
                extraMap[keyMap.alliance_name] = name
                extraMap[keyMap.alliance_icon] = self._createAllianceParameter.flag.BadgeAppearance
                extraMap[keyMap.alliance_label] = abbr
                ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.alliance_creat, extraMap)
            end
        end)
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, popupData)
end

function AllianceCreationMediator:OnDisableClick()
    if ModuleRefer.AllianceModule:IsAllianceCreationInCD() then
        local cdTime = ModuleRefer.AllianceModule:GetNextAllianceCreationTime() - g_Game.ServerTime:GetServerTimestampInSeconds()
        local hour = math.floor(cdTime / 3600)
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("alliance_create_cd", hour))
    end
    self._p_resources:ShowLakeJump()
end

function AllianceCreationMediator:OnJoinAlliance()
    self:CloseSelf(nil, true)
    ---@type AllianceMainMediatorParameter
    local openParameter = {
        showJoinAni = true
    }
    g_Game.UIManager:Open(UIMediatorNames.AllianceMainMediator, openParameter)
end

---@param langId number
function AllianceCreationMediator:OnLanguageSelect(langId)
    self._createAllianceParameter.lang = langId
    self:UpdateLanguageText()
end

function AllianceCreationMediator:UpdateLanguageText()
    self._p_text_language.text = AllianceModuleDefine.GetConfigLangaugeStr(self._createAllianceParameter.lang)
end

function AllianceCreationMediator:OnClickSelectLanguage()
    g_Game.UIManager:Open(UIMediatorNames.AllianceCreationLanguageSelectMediator, {
        selectedLangId = self._createAllianceParameter.lang
    })
end

function AllianceCreationMediator:OnClickRandom()
    local randomAppearanceId = self._badgeAppearanceIds[math.random(1, #self._badgeAppearanceIds)]
    local randomPatternId = self._badgePatternIds[math.random(1, #self._badgePatternIds)]
    local randomColorId = self._territoryColorIds[math.random(1, #self._territoryColorIds)]
    self._createAllianceParameter.flag.BadgeAppearance = randomAppearanceId
    self._createAllianceParameter.flag.BadgePattern = randomPatternId
    self._createAllianceParameter.flag.TerritoryColor = randomColorId
    self._child_league_logo:FeedData(self._createAllianceParameter.flag)
    self._p_img_area.color = UIHelper.TryParseHtmlString(ConfigRefer.AllianceTerritoryColor:Find(randomColorId):Color())
end

function AllianceCreationMediator:OnClickCheckDetailAbbr()
    self:CheckAndShowErrorTip(self._p_input_abbr, self._p_btn_detail_abbr)
end

function AllianceCreationMediator:OnClickCheckDetailName()
    self:CheckAndShowErrorTip(self._p_input_name, self._p_btn_detail_name)
end

function AllianceCreationMediator:OnClickCheckDetailDeclaim()
    self:CheckAndShowErrorTip(self._p_input_declaim, self._p_btn_detail_declaim)
end

---@param input InputFieldWithCheckStatus
---@param target CS.UnityEngine.UI.Button
function AllianceCreationMediator:CheckAndShowErrorTip(input, target)
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

function AllianceCreationMediator:OnAbbrCustomCheckEnd(pass)
    if not pass then
        self:OnClickCheckDetailAbbr()
    end
end

function AllianceCreationMediator:OnNameCustomCheckEnd(pass)
    if not pass then
        self:OnClickCheckDetailName()
    end
end

function AllianceCreationMediator:OnDeclaimCustomCheckEnd(pass)
    if not pass then
        self:OnClickCheckDetailDeclaim()
    end
end

function AllianceCreationMediator:GetAbbrPlaceHolder()
    local minCharactor = ConfigRefer.AllianceConsts:AllianceAbbrLenMin()
    local maxCharactor = ConfigRefer.AllianceConsts:AllianceAbbrLenMax()
    return I18N.GetWithParams("alliance_create_sign_num", minCharactor, maxCharactor)
end

function AllianceCreationMediator:GetNamePlaceHolder()
    local minCharactor = ConfigRefer.AllianceConsts:AllianceNameLenMin()
    local maxCharactor = ConfigRefer.AllianceConsts:AllianceNameLenMax()
    return I18N.GetWithParams("alliance_create_name_num", minCharactor, maxCharactor)
end

function AllianceCreationMediator:GetNoticePlaceHolder()
    -- local minCharactor = ConfigRefer.AllianceConsts:AllianceNoticeLenMin()
    -- local maxCharactor = ConfigRefer.AllianceConsts:AllianceNoticeLenMax()
    -- return I18N.GetWithParams("alliance_create_declaration_num", minCharactor, maxCharactor)
    return I18N.Get("alliance_declaration_tips10")
end

return AllianceCreationMediator