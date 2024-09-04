local EventConst = require('EventConst')
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local TimerUtility = require('TimerUtility')
local Utils = require('Utils')

---@field mainDog CS.UnityEngine.Animator
---@field otherDog1 CS.UnityEngine.Animator
---@field otherDog2 CS.UnityEngine.Animator
---@field otherDog3 CS.UnityEngine.Animator
---@field otherDog4 CS.UnityEngine.Animator
local HeroCardAnimControl = class('HeroCardAnimControl')

function HeroCardAnimControl:Awake()
    --g_Logger.Error('HeroCardAnimControl:Awake')

    self.otherDogs = {}
    table.insert(self.otherDogs, self.otherDog1)
    table.insert(self.otherDogs, self.otherDog2)
    table.insert(self.otherDogs, self.otherDog3)
    table.insert(self.otherDogs, self.otherDog4)
    --g_Logger.Error('otherDogs %s', #self.otherDogs)
end

function HeroCardAnimControl:Start()
    --g_Logger.Error('HeroCardAnimControl:Start')
end

function HeroCardAnimControl:OnEnable()
    --g_Logger.Error('HeroCardAnimControl:OnEnable')
    g_Game.EventManager:AddListener(EventConst.HERO_CARD_DOG_INIT, Delegate.GetOrCreate(self, self.InitIdle))
    g_Game.EventManager:AddListener(EventConst.HERO_CARD_FEED_DRAG_START, Delegate.GetOrCreate(self, self.OnDragStart))
    g_Game.EventManager:AddListener(EventConst.HERO_CARD_FEED_DRAG_END, Delegate.GetOrCreate(self, self.OnDragEnd))
end

function HeroCardAnimControl:OnDisable()
    --g_Logger.Error('HeroCardAnimControl:OnDisable')
    if self.tickTimer then
        TimerUtility.StopAndRecycle(self.tickTimer)
        self.tickTimer = nil
    end
    g_Game.EventManager:RemoveListener(EventConst.HERO_CARD_DOG_INIT, Delegate.GetOrCreate(self, self.InitIdle))
    g_Game.EventManager:RemoveListener(EventConst.HERO_CARD_FEED_DRAG_START, Delegate.GetOrCreate(self, self.OnDragStart))
    g_Game.EventManager:RemoveListener(EventConst.HERO_CARD_FEED_DRAG_END, Delegate.GetOrCreate(self, self.OnDragEnd))
end

function HeroCardAnimControl:InitIdle()
    self.mainDog:Play('sit_idle')
    for i = 1, #self.otherDogs do
        self.otherDogs[i]:Play('sit_idle')
    end
end

function HeroCardAnimControl:OnDestroy()
    --g_Logger.Error('HeroCardAnimControl:OnDestroy')
    if self.tickTimer then
        TimerUtility.StopAndRecycle(self.tickTimer)
        self.tickTimer = nil
    end
    self.mainDog = nil
end

function HeroCardAnimControl:OnDragStart(isOne)
    self.mainDog:Play('sit_to_wobble')
end

function HeroCardAnimControl:OnDragEnd(isOne)
    self.mainDog:Play('wobble_to_sniff')
    self.tickTimer = TimerUtility.DelayExecute(function() self:PlayOtherDogsRun(isOne) end, 1.1)
end

function HeroCardAnimControl:PlayOtherDogsRun(isOne)
    if not self.mainDog then
        return
    end
    if Utils.IsNullOrEmpty(self.mainDog) then
        return
    end
    if isOne then
        ModuleRefer.HeroCardModule:ChooseOtherDog()
        local randomDogAnim = self.otherDogs[ModuleRefer.HeroCardModule:GetOtherDogIndex()]
        randomDogAnim:Play('sit_to_run')
    else
        ModuleRefer.HeroCardModule:ChooseOtherDog()
        for i = 1, #self.otherDogs do
            self.otherDogs[i]:Play('sit_to_run')
        end
    end
    if self.tickTimer then
        TimerUtility.StopAndRecycle(self.tickTimer)
        self.tickTimer = nil
    end
end

return HeroCardAnimControl