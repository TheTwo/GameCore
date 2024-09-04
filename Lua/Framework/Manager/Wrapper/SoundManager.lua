---@type CS.DragonReborn.Sound.SoundManager
local CSSoundManager = CS.DragonReborn.Sound.SoundManager.Instance
local Delegate = require('Delegate')
--local SceneBgmUsage = require("SceneBgmUsage")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local EventConst = require("EventConst")
--local AudioConsts = require("AudioConsts")

---@class SoundManager
---@field new fun():SoundManager
local SoundManager = class('SoundManager', require("BaseManager"))

function SoundManager:ctor()
    self.manager = CSSoundManager;
    self.manager:OnGameInitialize(nil)
    g_Game:AddSystemTicker(Delegate.GetOrCreate(self,self.Tick))
    self._lastSceneBgmUsage = nil
    local dialogCode = CS.DragonReborn.UI.UIMediatorType.Dialog:GetHashCode()
    local popupCode = CS.DragonReborn.UI.UIMediatorType.Popup:GetHashCode()
    ---@type number
    self._uiSoundTypeMask = (dialogCode | popupCode)
    ---@type table<string, AudioUIConfigConfigCell>
    self._uiName2Sound = {}
    ---@type table<CS.DragonReborn.UI.UIMediatorType, AudioUIConfigConfigCell>
    self._defaultUiAudio = {}
    g_Game.EventManager:AddListener(EventConst.UI_BUTTON_CLICK_SOUND, Delegate.GetOrCreate(self, self.OnUIButtonClickSound))
    self._runtimeBankLruLimitKeep = 2
    self._runtimeBankLruLimit = 16
end

function SoundManager:Tick(delta)
    self.manager:Tick(delta)
end

---@return boolean
function SoundManager:IsReady()
    return CSSoundManager.IsReady
end

---@return number
function SoundManager:GetBgmVolume()
    return CSSoundManager.BgmVolume
end

---@param value number @0.0-100.0
function SoundManager:SetBgmVolume(value)
    CSSoundManager.BgmVolume = value
end

---@return number
function SoundManager:GetSfxVolume()
    return CSSoundManager.SfxVolume
end

---@param value number @0.0-100.0
function SoundManager:SetSfxVolume(value)
    CSSoundManager.SfxVolume = value
end

function SoundManager:GetCustomRTPCValue(name)
    return CSSoundManager:GetCustomRTPC(name)
end

function SoundManager:SetCustomRTPCValue(name, value)
    CSSoundManager:SetCustomRTPC(name, value)
end

function SoundManager:InitSoundManager()
    CSSoundManager:InitSoundManager()
    CSSoundManager:SetCustomRTPC("bigmap_position_rtpc_x", 0)
end

function SoundManager:OnDependenceReady()
    CSSoundManager:OnDependenceReady()
    if ConfigRefer.ConstMain.WwiseSoundBankLruLimit then
        local limit = math.max(self._runtimeBankLruLimitKeep, ConfigRefer.ConstMain:WwiseSoundBankLruLimit())
        self._runtimeBankLruLimit = limit
    end
    CSSoundManager:RuntimeModifyBankLruLimit(self._runtimeBankLruLimit)
    table.clear(self._uiName2Sound)
    table.clear(self._defaultUiAudio)
    local AudioUIConfig = ConfigRefer.AudioUIConfig
    for _, config in AudioUIConfig:ipairs() do
        local name = config:MediatorName()
        if not string.IsNullOrEmpty(name) then
            self._uiName2Sound[name] = config
        end
    end
    local ConstMain = ConfigRefer.ConstMain
    local enumType = CS.DragonReborn.UI.UIMediatorType
    self._defaultUiAudio[enumType.Dialog] = AudioUIConfig:Find(ConstMain:DefaultUIDialogAudio())
    self._defaultUiAudio[enumType.Popup] = AudioUIConfig:Find(ConstMain:DefaultUIPopupAudio())
    self._defaultUiAudio[enumType.Tip] = AudioUIConfig:Find(ConstMain:DefaultUITipAudio())
    self._defaultUiAudio[enumType.SceneUI] = AudioUIConfig:Find(ConstMain:DefaultUISceneUIAudio())
    self._defaultUiAudio[enumType.SystemMsg] = AudioUIConfig:Find(ConstMain:DefaultUISystemMsgAudio())
end

---@param listenerRoot  CS.UnityEngine.Transform
function SoundManager:SetSceneListener(listenerRoot)
    CSSoundManager:SetSceneListener(listenerRoot)
end

function SoundManager:SetResBaseAndAddPath()
    CSSoundManager:SetResBaseAndAddPath()
end

---@param eventName string
function SoundManager:PlayBgm(eventName)
    CSSoundManager:PlayBgm(eventName)
end

function SoundManager:StopBgm()
    CSSoundManager:StopBgm()
end

---@param eventName string
function SoundManager:PlayAmb(eventName)
    CSSoundManager:PlayAmb(eventName)
end

function SoundManager:StopAmb()
    CSSoundManager:StopAmb()
end

function SoundManager:SwitchAmb()
    CSSoundManager:SwitchAmb()
end

---@param eventName string
---@param go CS.UnityEngine.GameObject
---@param autoDestroyOnEnd boolean
---@return CS.DragonReborn.SoundPlayingHandle
function SoundManager:Play(eventName,go, autoDestroyOnEnd)
    if nil == autoDestroyOnEnd then
        autoDestroyOnEnd = false
    end
    return CSSoundManager:Play(eventName, go, autoDestroyOnEnd)
end

---@param id number @see AudioConsts
---@param go CS.UnityEngine.GameObject
---@param autoDestroyOnEnd boolean
---@return CS.DragonReborn.SoundPlayingHandle
function SoundManager:PlayAudio(id, go, autoDestroyOnEnd)
    local eventName = ArtResourceUtils.GetAudio(id)
    if string.IsNullOrEmpty(eventName) then
        return CS.DragonReborn.SoundPlayingHandle.INVALID
    end
    if nil == autoDestroyOnEnd then
        autoDestroyOnEnd = false
    end
    return CSSoundManager:Play(eventName, go, autoDestroyOnEnd)
end

---@param playingHandle CS.DragonReborn.SoundPlayingHandle
function SoundManager:Stop(playingHandle)
    CSSoundManager:Stop(playingHandle)
end

---@param eventName string
---@param playAfterCreate boolean @default:true
---@param parent CS.UnityEngine.Transform
---@param autoDestroyOnEnd boolean @default:true
---@return "CS.DragonReborn.ISoundEffect"
function SoundManager:Create(eventName, playAfterCreate,  parent, autoDestroyOnEnd)
    if nil == playAfterCreate then
        playAfterCreate = true
    end
    if nil == autoDestroyOnEnd then
        autoDestroyOnEnd = true
    end
    return CSSoundManager:Create(eventName, playAfterCreate, parent, autoDestroyOnEnd)
end

---@param soundEffect "CS.DragonReborn.ISoundEffect"
function SoundManager:DestroySoundEffect(soundEffect)
    CSSoundManager:DestroySoundEffect(soundEffect)
end

---@param resName string
function SoundManager:Load(resName)
    CSSoundManager:Load(resName)
end

---@param resName string
function SoundManager:UnLoad(resName)
    CSSoundManager:UnLoad(resName)
end

function SoundManager:Reset()
    g_Game.EventManager:RemoveListener(EventConst.UI_BUTTON_CLICK_SOUND, Delegate.GetOrCreate(self, self.OnUIButtonClickSound))
    g_Game:RemoveSystemTicker(Delegate.GetOrCreate(self,self.Tick))
    try_catch_traceback_with_vararg(self.manager.Reset, nil, self.manager)
end

function SoundManager:OnLowMemory()
    try_catch_traceback_with_vararg(self.manager.OnLowMemory, nil, self.manager)
end

function SoundManager:OnUIButtonClickSound(eventData)
    if not eventData or string.IsNullOrEmpty(eventData.eventData)  then
        return
    end
    self:Play(eventData.eventData)
end

---@param sceneBgmUsage "SceneBgmUsage"
---@param isEnter boolean
function SoundManager:OnSceneChange(sceneBgmUsage, isEnter)
    if isEnter then
        if self._lastSceneBgmUsage == sceneBgmUsage then
            return
        end
        if self._lastSceneBgmUsage then
            self:DoLeaveSceneBgmUsage()
        end
        self._lastSceneBgmUsage = sceneBgmUsage
        self:DoEnterSceneBgmUsage(sceneBgmUsage)
    elseif self._lastSceneBgmUsage == sceneBgmUsage then
        CSSoundManager:RuntimeModifyBankLruLimit(self._runtimeBankLruLimitKeep)
        CSSoundManager:RuntimeModifyBankLruLimit(self._runtimeBankLruLimit)
        self._lastSceneBgmUsage = nil
        self:DoLeaveSceneBgmUsage()
    else
        CSSoundManager:RuntimeModifyBankLruLimit(self._runtimeBankLruLimitKeep)
        CSSoundManager:RuntimeModifyBankLruLimit(self._runtimeBankLruLimit)
    end
end

---@param sceneBgmUsage "SceneBgmUsage"
function SoundManager:DoEnterSceneBgmUsage(sceneBgmUsage)
    ---@type SceneBgmConfigCell[]
    local list = {}
    local totalWeight = 0
    ---@type SceneBgmConfigCell
    local choose = nil
    for _, v in ConfigRefer.SceneBgm:ipairs() do
        if v:Usage() == sceneBgmUsage then
            if not choose then
                choose = v
            end
            if v:Weight() > 0 then
                totalWeight = totalWeight + v:Weight()
                table.insert(list, v)
            end
        end
    end
    if not choose then
        return
    end
    if #list > 1 then
        table.sort(list, function(a, b) 
            return a:Weight() < b:Weight()
        end)
        local w = math.random(0, totalWeight)
        local t = 0
        for i = #list, 1, -1 do
            local v = list[i]
            t = t + v:Weight()
            if t >= w then
                choose = v
                break
            end
        end
    end
    self:DoPlayBgmConfig(choose)
end

---@param config SceneBgmConfigCell
function SoundManager:DoPlayBgmConfig(config)
    local bgm = ArtResourceUtils.GetAudio(config:BGMRes())
    if not string.IsNullOrEmpty(bgm) then
        self:PlayBgm(bgm)
    end
    local amb = ArtResourceUtils.GetAudio(config:AmbRes())
    if not string.IsNullOrEmpty(amb) then
        self:PlayAmb(amb)
    end
end

function SoundManager:DoLeaveSceneBgmUsage()
    self:StopBgm()
    self:StopAmb()
    self:PlayAudio(AudioConsts.sfx_se_world_mapswitch)
end

---@param uiMediatorName string
---@param type CS.DragonReborn.UI.UIMediatorType
function SoundManager:OnUIMediatorPlayShowSound(uiMediatorName, type)
    local typeCode = type:GetHashCode()
    if (typeCode & self._uiSoundTypeMask) == 0 then
        return
    end
    local audio = self._uiName2Sound[uiMediatorName]
    if audio then
        self:PlayAudio(audio:OnShow())
    elseif self._defaultUiAudio[type] then
        self:PlayAudio(self._defaultUiAudio[type]:OnShow())
    end
end

---@param uiMediatorName string
---@param type CS.DragonReborn.UI.UIMediatorType
function SoundManager:OnUIMediatorPlayHideSound(uiMediatorName, type)
    local typeCode = type:GetHashCode()
    if (typeCode & self._uiSoundTypeMask) == 0 then
        return
    end
    local audio = self._uiName2Sound[uiMediatorName]
    if audio then
        self:PlayAudio(audio:OnHide())
    elseif self._defaultUiAudio[type] then
        self:PlayAudio(self._defaultUiAudio[type]:OnHide())
    end
end

return SoundManager