local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
local ProtocolId = require("ProtocolId")
local LoginAccountSetting = require("LoginAccountSetting")

---@class UISettingsMediator : BaseUIMediator
local UISettingsMediator = class('UISettingsMediator', BaseUIMediator)

function UISettingsMediator:ctor()
    self._allowViewEquip = 0
    self._drawCardBroadcast = 0
    self._musicVolume = 1
    self._soundVolume = 1
    self._languageCode = "zh"
end

function UISettingsMediator:OnCreate()
    self._langDataList = {}
    self._langSortList = {}
    self:InitObjects()
end

function UISettingsMediator:InitObjects()
    self.compTabCommon = self:LuaObject('p_tab_common')
    self.compTabLanguage = self:LuaObject('p_tab_language')
    self.tabCommon = self:GameObject('p_common')
    self.tabCommonTitleText = self:Text('p_text_title_basics', 'game_settings_general')
    self.tabCommonViewEquipText = self:Text('p_text_toggle_view', 'game_settings_show_equip')
    self.tabCommonViewEquipCtrl = self:BindComponent('p_common_view_equip_toggle', typeof(CS.StatusRecordParent))
    self.tabCommonViewEquipButton = self:Button('p_common_view_equip_toggle', Delegate.GetOrCreate(self, self.OnTabCommonViewEquipButtonClicked))
    self.tabCommonDrawCardText = self:Text('p_text_toggle_card', 'game_settings_show_drawcard')
    self.tabCommonDrawCardHintText = self:Text('p_text_hint_card', 'game_settings_drawcard_desc')
    self.tabCommonDrawCardCtrl = self:BindComponent('p_common_draw_card_toggle', typeof(CS.StatusRecordParent))
    self.tabCommonDrawCardButton = self:Button('p_common_draw_card_toggle', Delegate.GetOrCreate(self, self.OnTabCommonDrawCardButtonClicked))
    self.tabCommonAudioText = self:Text('p_text_title_sound', 'game_settings_sound_set')
    self.tabCommonMusicText = self:Text('p_progress_music', 'game_settings_music_volume')
    self.tabCommonMusicSlider = self:Slider('p_music_slider', Delegate.GetOrCreate(self, self.OnTabCommonMusicVolumeChanged))
    self.tabCommonSoundText = self:Text('p_progress_effect', 'game_settings_effect_volume')
    self.tabCommonSoundSlider = self:Slider('p_sound_slider', Delegate.GetOrCreate(self, self.OnTabCommonSoundVolumeChanged))
    self.tabCommonHelpButton = self:Button('p_btn_help', Delegate.GetOrCreate(self, self.OnTabCommonHelpButtonClicked))
    self.tabCommonHelpText = self:Text('p_text_help', I18N.Temp().text_service)
    self.tabCommonEulaButton = self:Button('p_btn_eula', Delegate.GetOrCreate(self, self.OnTabCommonEulaButtonClicked))
    self.tabCommonEulaText = self:Text('p_text_eula', I18N.Temp().text_agreement)
    self.tabCommonErrorButton = self:Button('p_btn_error', Delegate.GetOrCreate(self, self.OnTabCommonErrorButtonClicked))
    self.tabCommonErrorText = self:Text('p_text_error', I18N.Temp().text_bug_report)
    self.tabLanguage = self:GameObject('p_language')
    self.textLanguageTitle = self:Text('p_text_language', 'game_settings_language_set')
    self.tabLanguageList = self:TableViewPro('p_table_language')
    self.backButton = self:LuaBaseComponent('child_common_btn_back')

    self.btnNewGame = self:Button("p_btn_restart", Delegate.GetOrCreate(self, self.OnRestartNewGame))
    self.textNewGame = self:Text("p_text_restart", "start_new_game")
    self.btnNewGame:SetVisible(g_Game.ENABLE_START_NEW_GAME or false)

	-- TODO: 此版本隐藏, 以后看要不要加回来
	self.tabCommonHelpButton.gameObject:SetActive(false)
	self.tabCommonEulaButton.gameObject:SetActive(false)
	self.tabCommonErrorButton.gameObject:SetActive(false)
end


function UISettingsMediator:OnShow(param)
    self.backButton:FeedData({
        title = I18N.Get("game_settings"),
    })
    local tabData = {}
    tabData.index = 1
    tabData.onClick = Delegate.GetOrCreate(self, self.OnTabCommonButtonClicked)
    tabData.onClickLocked = nil
    tabData.btnName = I18N.Get("game_settings_general")
    tabData.isLocked = false
    self.compTabCommon:FeedData(tabData)
    local tabData2= {}
    tabData2.index = 2
    tabData2.onClick = Delegate.GetOrCreate(self, self.OnTabLanguageButtonClicked)
    tabData2.onClickLocked = nil
    tabData2.btnName = I18N.Get("game_settings_language")
    tabData2.isLocked = false
    self.compTabLanguage:FeedData(tabData2)
    self.compTabCommon:SetStatus(0)
    self.compTabLanguage:SetStatus(1)
    self:RefreshData()
    self:RefreshUI()
    self:OnTabCommonButtonClicked(1)
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.SetClientCustomData, Delegate.GetOrCreate(self, self.OnSetLanguage))
end

function UISettingsMediator:OnHide(param)
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.SetClientCustomData, Delegate.GetOrCreate(self, self.OnSetLanguage))
end

function UISettingsMediator:OnOpened(param)
end

function UISettingsMediator:OnClose(param)
end

function UISettingsMediator:RefreshData()
    -- 通用
    self._allowViewEquip = 0
    if (ModuleRefer.GameSettingModule:GetAllowViewEquip()) then
        self._allowViewEquip = 1
    end
    self._drawCardBroadcast = 0
    if (ModuleRefer.GameSettingModule:GetDrawCardBroadcast()) then
        self._drawCardBroadcast = 1
    end
    self._soundVolume = ModuleRefer.GameSettingModule:GetSoundVolume()
    self._musicVolume = ModuleRefer.GameSettingModule:GetMusicVolume()

    -- 语言
    self._languageCode = ModuleRefer.GameSettingModule:GetLanguageCode()
    self._langDataList = {}
    self._langSortList = {}
    for _, cell in ConfigRefer.Language:ipairs() do
        local data = {}
        data.id = cell:Id()
        data.onClick = Delegate.GetOrCreate(self, self.OnLanguageItemClicked)
        data.code = cell:StringId()
        data.text = I18N.Get(cell:LanguageKey())
        data.selected = data.code == self._languageCode
        self._langDataList[data.code] = data
        table.insert(self._langSortList, {
            text = data.text,
            code = data.code,
        })
    end
    table.sort(self._langSortList, function(a, b)
        return a.text < b.text
    end)
end

function UISettingsMediator:RefreshUI()
    -- 通用
    self.tabCommonViewEquipCtrl:SetState(self._allowViewEquip)
    self.tabCommonDrawCardCtrl:SetState(self._drawCardBroadcast)
    self.tabCommonMusicSlider.value = self._musicVolume
    self.tabCommonSoundSlider.value = self._soundVolume

    -- 语言
    self.tabLanguageList:Clear()
    for _, sortData in ipairs(self._langSortList) do
        self.tabLanguageList:AppendData(self._langDataList[sortData.code])
    end
    self.tabLanguageList:RefreshAllShownItem(false)
end

function UISettingsMediator:OnTabCommonButtonClicked(index)
    self.tabCommon:SetActive(true)
    self.tabLanguage:SetActive(false)
    self.compTabCommon:SetStatus(index == 0 and 1 or 0)
    self.compTabLanguage:SetStatus(index == 0 and 0 or 1)
end
function UISettingsMediator:OnTabLanguageButtonClicked(index)
    self.tabCommon:SetActive(false)
    self.tabLanguage:SetActive(true)
    self.compTabCommon:SetStatus(index == 1 and 0 or 1)
    self.compTabLanguage:SetStatus(index == 1 and 1 or 0)
    self.tabLanguageList:RefreshAllShownItem(false)
end
function UISettingsMediator:OnTabCommonViewEquipButtonClicked(args)
    if (self._allowViewEquip == 0) then
        self._allowViewEquip = 1
    else
        self._allowViewEquip = 0
    end
    ModuleRefer.GameSettingModule:SetAllowViewEquip(self._allowViewEquip == 1)
    self.tabCommonViewEquipCtrl:SetState(self._allowViewEquip)
end
function UISettingsMediator:OnTabCommonDrawCardButtonClicked(args)
    if (self._drawCardBroadcast == 0) then
        self._drawCardBroadcast = 1
    else
        self._drawCardBroadcast = 0
    end
    ModuleRefer.GameSettingModule:SetDrawCardBroadcast(self._drawCardBroadcast == 1)
    self.tabCommonDrawCardCtrl:SetState(self._drawCardBroadcast)
end

function UISettingsMediator:OnTabCommonMusicVolumeChanged(args)
    self._musicVolume = self.tabCommonMusicSlider.value
    ModuleRefer.GameSettingModule:SetMusicVolume(self._musicVolume)
end

function UISettingsMediator:OnTabCommonSoundVolumeChanged(args)
    self._soundVolume = self.tabCommonSoundSlider.value
    ModuleRefer.GameSettingModule:SetSoundVolume(self._soundVolume)
end

function UISettingsMediator:OnTabCommonHelpButtonClicked(args)
    -- body
end

function UISettingsMediator:OnTabCommonEulaButtonClicked(args)
    -- body
end

function UISettingsMediator:OnTabCommonErrorButtonClicked(args)
    -- body
end

---@param self UISettingsMediator
---@param code string
function UISettingsMediator:OnLanguageItemClicked(code)
    if (self._languageCode == code) then return end

    local langData = self._langDataList[code]

    ---@type CommonConfirmPopupMediatorParameter
    local dialogParam = {}
    dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    dialogParam.title = I18N.Get("se_quit_title")
    dialogParam.content = I18N.GetWithParams("change_language_set", langData.text)
    dialogParam.onConfirm = function(context)
        ModuleRefer.GameSettingModule:SetLanguageCode(code)
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
end

function UISettingsMediator:OnSetLanguage()
    g_Game:RestartGame()
end

function UISettingsMediator:OnRestartNewGame()
    LoginAccountSetting:ClearAccount()

    if USE_FPXSDK then
        -- 等SDK触发注销逻辑再重启
        ModuleRefer.FPXSDKModule:StartNewGame()
    else
        -- 立刻重启
        g_Game:RestartGame()
    end
end

return UISettingsMediator
