local CityManagerBase = require("CityManagerBase")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local EventConst = require("EventConst")

---@class CityRandomVoice
---@field new fun():CityRandomVoice
local CityRandomVoice = class('CityRandomVoice', CityManagerBase)

function CityRandomVoice:ctor(city, ...)
    CityManagerBase.ctor(self, city, ...)
    ---@type CS.DragonReborn.SoundPlayingHandle
    self._currentHandle = nil
    self._nextPlayTime = nil
    ---@type string[]
    self._randomVoiceList = {}
    self._randomMin = nil
    self._randomMax = nil
    self._isPending = false
end

function CityRandomVoice:OnCityActive()
    self._randomMin = ConfigRefer.CityConfig:CityRandomVoiceIntervalRange(1)
    self._randomMax = ConfigRefer.CityConfig:CityRandomVoiceIntervalRange(2)
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    g_Game.EventManager:AddListener(EventConst.CITY_OPEN_HERO_MEDIATOR_PENDING_RANDOM_VOICE, Delegate.GetOrCreate(self, self.SetPending))
end

function CityRandomVoice:OnCityInactive()
    g_Game.EventManager:RemoveListener(EventConst.CITY_OPEN_HERO_MEDIATOR_PENDING_RANDOM_VOICE, Delegate.GetOrCreate(self, self.SetPending))
    if self._currentHandle then
        g_Game.SoundManager:Stop(self._currentHandle)
    end
    self._isPending = false
    self._currentHandle = nil
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

function CityRandomVoice:SetPending(isPending)
    if isPending == self._isPending then
        return
    end
    self._isPending = isPending
    if isPending then
        if self._currentHandle then
            g_Game.SoundManager:Stop(self._currentHandle)
        end
        self._currentHandle = nil
    end
end

function CityRandomVoice:RegeneratePlayList()
    table.clear(self._randomVoiceList)
    for _, v in ConfigRefer.CityRandomVoice:pairs() do
        if not v:Disabled() then
            local eventKey = ArtResourceUtils.GetAudio(v:Audio())
            if not string.IsNullOrEmpty(eventKey) then
                table.insert(self._randomVoiceList, eventKey)
            end
        end
    end
end

function CityRandomVoice:OnSecondTick(dt)
    if self._isPending then
        return
    end
    if not self._nextPlayTime then
        if not self._randomMin or not self._randomMax then
            return
        end
        self._nextPlayTime = math.random(self._randomMin, self._randomMax)
    end
    self._nextPlayTime = self._nextPlayTime - dt
    if self._nextPlayTime <= 0 then
        self._nextPlayTime = nil
        if self._currentHandle then
            g_Game.SoundManager:Stop(self._currentHandle)
        end
        self._currentHandle = nil
        if #self._randomVoiceList <= 0 then
            self:RegeneratePlayList()
        else
            local voiceEvent = table.remove(self._randomVoiceList)
            if not string.IsNullOrEmpty(voiceEvent) then
                self._currentHandle = g_Game.SoundManager:Play(voiceEvent)
            end
        end
    end
end

return CityRandomVoice