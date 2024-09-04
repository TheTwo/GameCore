--- scene:scene_world_tips_fail

local Delegate = require("Delegate")
local EventConst = require("EventConst")

local BaseUIMediator = require("BaseUIMediator")

---@class WorldConquerFailTipMediatorParameter
---@field icon string
---@field mainContent string
---@field subContent string

---@class WorldConquerFailTipMediator:BaseUIMediator
---@field new fun():WorldConquerFailTipMediator
---@field super BaseUIMediator
local WorldConquerFailTipMediator = class('WorldConquerFailTipMediator', BaseUIMediator)

function WorldConquerFailTipMediator:ctor(param)
    BaseUIMediator.ctor(self)
    self.fadeDuration = 0.25
    self.existDuration = 2
    self.fadeInTime = self.fadeDuration
    self.fadeOutTime = self.existDuration - self.fadeDuration
    self.maxInQueue = 3
    
    ---@type WorldConquerFailTipMediatorParameter[]
    self._queue = {}
    ---@type WorldConquerFailTipMediatorParameter
    self._current = nil
    self._currentTime = 0
end

function WorldConquerFailTipMediator:OnCreate(param)
    self._p_content = self:BindComponent("p_content", typeof(CS.UnityEngine.CanvasGroup))
    self._p_img_building = self:Image("p_img_building")
    self._p_text_title = self:Text("p_text_title")
    self._p_text_info = self:Text("p_text_info")
end

---@param param WorldConquerFailTipMediatorParameter
function WorldConquerFailTipMediator:OnOpened(param)
    self:PushToQueue(param)
    self:Tick(0)
end

---@param param WorldConquerFailTipMediatorParameter
function WorldConquerFailTipMediator:SetUp(param)
    self._current = param
    self._currentTime = 0
    self._p_content.alpha = 0
    g_Game.SpriteManager:LoadSprite(param.icon, self._p_img_building)
    self._p_text_title.text = param.mainContent or string.Empty
    self._p_text_info.text = param.subContent or string.Empty
end

---@param param WorldConquerFailTipMediatorParameter
function WorldConquerFailTipMediator:PushToQueue(param)
    while #self._queue >= self.maxInQueue do
        table.remove(self._queue, 1)
    end
    table.insert(self._queue, param)
end

function WorldConquerFailTipMediator:OnShow(param)
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:AddListener(EventConst.UI_WORLD_CONQUER_FAIL_TIP_NEW, Delegate.GetOrCreate(self, self.PushToQueue))
end

function WorldConquerFailTipMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.UI_WORLD_CONQUER_FAIL_TIP_NEW, Delegate.GetOrCreate(self, self.PushToQueue))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function WorldConquerFailTipMediator:Tick(dt)
    if self._current then
        self._currentTime = self._currentTime + dt
        if self._currentTime > self.existDuration then
            self._current = nil
        else
            if self._currentTime <= self.fadeInTime then 
                self._p_content.alpha = math.inverseLerp(0, self.fadeInTime, self._currentTime)
            elseif self._currentTime >= self.fadeOutTime then
                self._p_content.alpha = math.inverseLerp(self.fadeOutTime, self.existDuration, self._currentTime)
            end
            return
        end
    end
    local next = table.remove(self._queue, 1)
    if not next then
        self:CloseSelf()
        return
    end
    self:SetUp(next)
end

return WorldConquerFailTipMediator