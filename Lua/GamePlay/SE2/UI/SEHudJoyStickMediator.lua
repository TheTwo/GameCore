--- scene:scene_hud_explore_joystick
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local SEJoystickDefine = require("SEJoystickDefine")
local ConfigRefer = require("ConfigRefer")

local BaseUIMediator = require("BaseUIMediator")

---@class SEHudJoyStickMediatorParameter
---@field seEnv SEEnvironment
---@field throwBallTimeLimit number

---@class SEHudJoyStickMediator:BaseUIMediator
---@field new fun():SEHudJoyStickMediator
---@field super BaseUIMediator
local SEHudJoyStickMediator = class('SEHudJoyStickMediator', BaseUIMediator) 

function SEHudJoyStickMediator:ctor()
    SEHudJoyStickMediator.super.ctor(self)
    self._currentSelectBallId = nil
    self._currentSelectBallItem = nil
    ---@type table<number, fun()>
    self._listenToItemChangedRemoveHandler = {}
    self._anyAWDSKeyDown = false
    ---@type SEEnvironment
    self._seEnv = nil
    self._throwBallTimeLimit = nil
    self._throwBallPressEndTime = 0
    self._timelinePlaying = false
    self._hasThrowBallItem = false
    self._throwBallUnlocked = true
    self._exploreBagUnlocked = true
    self._seTeamInBattle = false
end

function SEHudJoyStickMediator:OnCreate()
    self._p_joystick_move = self:Joystick("p_joystick_move", Delegate.GetOrCreate(self, self.OnMovePointerDown), Delegate.GetOrCreate(self, self.OnMovePointerUp), Delegate.GetOrCreate(self, self.OnMoveValueChanged), Delegate.GetOrCreate(self, self.OnMovePointerCancel))
    self._p_joystick_ball = self:Joystick("p_joystick_ball", Delegate.GetOrCreate(self, self.OnBallPointerDown), Delegate.GetOrCreate(self, self.OnBallPointerUp), Delegate.GetOrCreate(self, self.OnBallValueChanged), Delegate.GetOrCreate(self, self.OnBallPointerCancel))
    self._p_img_normal = self:GameObject("p_img_normal")
    self._p_img_time_left = self:Image("p_img_time_left")
    self._p_img_mask = self:GameObject("p_img_mask")
    self._p_item = self:Image("p_item")
    self._p_text_cancel = self:Text("p_text_cancel", "cancle")
    self._p_cancle_area = self:RectTransform("p_cancle_area")
    self._p_btn_ball = self:Button("p_btn_ball", Delegate.GetOrCreate(self, self.OnClickSelectBall))
    self._p_icon = self:Image("p_icon")
    self._p_text_quantity = self:Text("p_text_quantity")
    ---@type SEHudJoyStickSelectBallTip
    self._p_tips_ball = self:LuaObject("p_tips_ball")
    self._p_btn_bag = self:Button("p_btn_bag", Delegate.GetOrCreate(self, self.OnClickBg))
    ---@type SEHudJoyStickBagComponent
    self._p_tips_bag = self:LuaObject("p_tips_bag")

    self._p_tips_ball:SetVisible(false)
    self._p_img_normal:SetVisible(true)
    self._p_img_time_left:SetVisible(false)
    self._p_img_mask:SetVisible(false)
    self._p_tips_bag:SetVisible(false)
    self._p_cancle_area:SetVisible(false)
end

---@param param SEHudJoyStickMediatorParameter
function SEHudJoyStickMediator:OnOpened(param)
    self._seEnv = param.seEnv
    self._throwBallTimeLimit = param.throwBallTimeLimit
    self:AutoSelectOneBall()
    for _, removeHandler in pairs(self._listenToItemChangedRemoveHandler) do
        removeHandler()
    end
    table.clear(self._listenToItemChangedRemoveHandler)
    local bagMgr = self._seEnv:GetSceneBagManager()
    local callChangeFunc = Delegate.GetOrCreate(self, self.OnBallItemChanges)
    for _, value in ConfigRefer.PetPocketBall:inverse_ipairs() do
        local itemId = value:LinkItem()
         self._listenToItemChangedRemoveHandler[itemId] = bagMgr:AddCountChangeListener(itemId, function()
            callChangeFunc(itemId)
        end)
    end
    self:OnSystemEntryChanged()
    --self:RefreshStickBallVisible()
    --self:RefreshBagBtnVisible()
end

function SEHudJoyStickMediator:OnClose()
    g_Game.EventManager:TriggerEvent(EventConst.SE_JOYSTICK_VALUE_CLEAR, SEJoystickDefine.JoystickType.Move, SEJoystickDefine.JoystickType.Ball)
end

function SEHudJoyStickMediator:OnShow(param)
    if self._seEnv then
        for _, removeHandler in pairs(self._listenToItemChangedRemoveHandler) do
            removeHandler()
        end
        table.clear(self._listenToItemChangedRemoveHandler)
        local bagMgr = self._seEnv:GetSceneBagManager()
        local callChangeFunc = Delegate.GetOrCreate(self, self.OnBallItemChanges)
        for _, value in ConfigRefer.PetPocketBall:inverse_ipairs() do
            local itemId = value:LinkItem()
             self._listenToItemChangedRemoveHandler[itemId] = bagMgr:AddCountChangeListener(itemId, function()
                callChangeFunc(itemId)
            end)
        end
    end
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.IgnoreInvervalTick))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_HIDE_CITY_BUBBLE_REFRESH, Delegate.GetOrCreate(self, self.OnStoryHideCityBubbleRefresh))
    self._timelinePlaying = false
    if ModuleRefer.StoryModule:IsStoryTimelineOrDialogPlaying() then
        self:OnStoryHideCityBubbleRefresh(true)
    end
    g_Game.EventManager:AddListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self, self.OnSystemEntryChanged))
    self:OnSystemEntryChanged()
end

function SEHudJoyStickMediator:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self, self.OnSystemEntryChanged))
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_HIDE_CITY_BUBBLE_REFRESH, Delegate.GetOrCreate(self, self.OnStoryHideCityBubbleRefresh))
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.IgnoreInvervalTick))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    for _, removeHandler in pairs(self._listenToItemChangedRemoveHandler) do
        removeHandler()
    end
    table.clear(self._listenToItemChangedRemoveHandler)
end

function SEHudJoyStickMediator:RefreshStickBallVisible()
    self._p_joystick_ball:SetVisible(not self._timelinePlaying and self._hasThrowBallItem and self._throwBallUnlocked and not self._seTeamInBattle)
end

function SEHudJoyStickMediator:RefreshBagBtnVisible()
    local visible = not self._timelinePlaying and self._exploreBagUnlocked and not self._seTeamInBattle
    self._p_btn_bag:SetVisible(visible)
    if not visible then
        self._p_tips_bag:SetVisible(false)
    end
end

function SEHudJoyStickMediator:OnStoryHideCityBubbleRefresh(nowPlaying)
    self._timelinePlaying = nowPlaying
    self._p_joystick_move:SetVisible(not nowPlaying)
    self:RefreshStickBallVisible()
    self:RefreshBagBtnVisible()
end

function SEHudJoyStickMediator:OnMovePointerDown()
    g_Game.EventManager:TriggerEvent(EventConst.SE_JOYSTICK_POINTER_DOWN, SEJoystickDefine.JoystickType.Move)
end

function SEHudJoyStickMediator:OnMovePointerUp()
    g_Game.EventManager:TriggerEvent(EventConst.SE_JOYSTICK_POINTER_UP, SEJoystickDefine.JoystickType.Move)
end

function SEHudJoyStickMediator:OnMovePointerCancel()
    g_Game.EventManager:TriggerEvent(EventConst.SE_JOYSTICK_POINTER_CANCEL, SEJoystickDefine.JoystickType.Move)
end

---@param dir CS.UnityEngine.Vector2
function SEHudJoyStickMediator:OnMoveValueChanged(dir)
    g_Game.EventManager:TriggerEvent(EventConst.SE_JOYSTICK_VALUE_CHANGED, SEJoystickDefine.JoystickType.Move, dir)
end

function SEHudJoyStickMediator:OnBallPointerDown()
    g_Game.EventManager:TriggerEvent(EventConst.SE_JOYSTICK_POINTER_DOWN, SEJoystickDefine.JoystickType.Ball)
    self._p_cancle_area:SetVisible(true)
    if self._throwBallTimeLimit and self._throwBallTimeLimit > 0 then
        self._p_img_time_left:SetVisible(true)
        self._p_img_time_left.fillAmount = 1
        self._throwBallPressEndTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() + self._throwBallTimeLimit
    else
        self._p_img_time_left:SetVisible(false)
    end
end

---@param screenPos CS.UnityEngine.Vector2
function SEHudJoyStickMediator:OnBallPointerUp(screenPos)
    if CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(self._p_cancle_area, screenPos, g_Game.UIManager:GetUICamera()) then
        g_Game.EventManager:TriggerEvent(EventConst.SE_JOYSTICK_POINTER_CANCEL, SEJoystickDefine.JoystickType.Ball)
        g_Logger.Log("OnBallPointerUp 摇杆已取消")
    else
        g_Game.EventManager:TriggerEvent(EventConst.SE_JOYSTICK_POINTER_UP, SEJoystickDefine.JoystickType.Ball)
    end
    self._p_cancle_area:SetVisible(false)
    self._p_img_mask:SetVisible(false)
    self._p_img_normal:SetVisible(true)
    self._p_img_time_left:SetVisible(false)
    self._throwBallPressEndTime = nil
end

---@param lastScreenPos CS.UnityEngine.Vector2
function SEHudJoyStickMediator:OnBallPointerCancel(lastScreenPos)
    g_Game.EventManager:TriggerEvent(EventConst.SE_JOYSTICK_POINTER_CANCEL, SEJoystickDefine.JoystickType.Ball)
    self._p_cancle_area:SetVisible(false)
    self._p_img_mask:SetVisible(false)
    self._p_img_normal:SetVisible(true)
    self._p_img_time_left:SetVisible(false)
    self._throwBallPressEndTime = nil
    g_Logger.Log("OnBallPointerCancel 摇杆已取消")
end

---@param dir CS.UnityEngine.Vector2
function SEHudJoyStickMediator:OnBallValueChanged(dir)
    local pointerPos = self._p_joystick_ball.LastPointerPosition
    local inCancelRange = CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(self._p_cancle_area, CS.UnityEngine.Vector2(pointerPos.x, pointerPos.y), g_Game.UIManager:GetUICamera())
    self._p_img_mask:SetVisible(inCancelRange)
    self._p_img_normal:SetVisible(not inCancelRange)
    g_Game.EventManager:TriggerEvent(EventConst.SE_JOYSTICK_VALUE_CHANGED, SEJoystickDefine.JoystickType.Ball, dir, inCancelRange)
end

function SEHudJoyStickMediator:OnClickSelectBall()
    self._p_tips_ball:SetVisible(true)
    ---@type SEHudJoyStickSelectBallTipParameter
    local tipData = {}
    tipData.currentPocketBallId = self._currentSelectBallId
    tipData.onSelect = Delegate.GetOrCreate(self, self.OnSelectedBallChanged)
    tipData.seEnv = self._seEnv
    self._p_tips_ball:FeedData(tipData)
end

function SEHudJoyStickMediator:OnSelectedBallChanged(pocketBallId)
    if not pocketBallId then
        self._currentSelectBallId = nil
        self._currentSelectBallItem = nil
        self._p_btn_ball:SetVisible(false)
        self._p_item:SetVisible(false)
        self._hasThrowBallItem = false
        ModuleRefer.SEJoystickControlModule:SetCurrentSelectedBallItemId(nil)
        self:RefreshStickBallVisible()
        return false
    end
    local ballConfig = ConfigRefer.PetPocketBall:Find(pocketBallId)
    local itemId = ballConfig:LinkItem()
    self._hasThrowBallItem = true
    self:RefreshStickBallVisible()
    self._p_btn_ball:SetVisible(true)
    self._p_item:SetVisible(true)
    self._currentSelectBallId = pocketBallId
    self._currentSelectBallItem = itemId
    local count = self._seEnv:GetSceneBagManager():GetAmountByConfigId(itemId)
    self._p_text_quantity.text = string.format("x%d", count)
    local itemConfig = ConfigRefer.Item:Find(itemId)
    g_Game.SpriteManager:LoadSprite(itemConfig:Icon(), self._p_icon)
    g_Game.SpriteManager:LoadSprite(itemConfig:Icon(), self._p_item)
    ModuleRefer.SEJoystickControlModule:SetCurrentSelectedBallItemId(pocketBallId)
    return true
end

function SEHudJoyStickMediator:AutoSelectOneBall()
    self._currentSelectBallId = nil
    self._currentSelectBallItem = nil
    local bagMgr = self._seEnv:GetSceneBagManager()
    for _, value in ConfigRefer.PetPocketBall:inverse_ipairs() do
        local itemId = value:LinkItem()
        local count = bagMgr:GetAmountByConfigId(itemId)
        if count > 0 then
            self._currentSelectBallId = value:Id()
            self._currentSelectBallItem = itemId
            break
        end
    end
    self:OnSelectedBallChanged(self._currentSelectBallId)
end

function SEHudJoyStickMediator:OnBallItemChanges(itemId)
    if not self._currentSelectBallItem then
        self:AutoSelectOneBall()
    elseif itemId == self._currentSelectBallItem then
        local bagMgr = self._seEnv:GetSceneBagManager()
        local count = bagMgr:GetAmountByConfigId(itemId)
        if count <= 0 then
            self:AutoSelectOneBall()
        else
            self._p_text_quantity.text = string.format("x%d", count)
        end
    end
end

function SEHudJoyStickMediator:Tick(dt)
    local inBattle = self._seTeamInBattle
    self._seTeamInBattle = false
    local teamMgr = self._seEnv:GetTeamManager()
    local team = teamMgr:GetOperatingTeam()
    local unitMgr = self._seEnv:GetUnitManager()
    if team then
        local playerId = ModuleRefer.PlayerModule:GetPlayerId()
        local presetIndex = team._presetIdx
        local heroList = unitMgr:GetHeroList()
        for _, hero in pairs(heroList) do
            local entity = hero:GetEntity()
            if entity.Owner.PlayerID == playerId and entity.BasicInfo.PresetIndex == presetIndex then
                if entity.MapStates.StateWrapper.Battle then
                    self._seTeamInBattle = true
                    break
                end
            end
        end
    end
    if inBattle == self._seTeamInBattle then
        return
    end
    self:RefreshBagBtnVisible()
    self:RefreshStickBallVisible()
end

function SEHudJoyStickMediator:IgnoreInvervalTick()
    if self._throwBallPressEndTime then
        local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        local leftTime = self._throwBallPressEndTime - nowTime
        if leftTime <= 0 then
            self._throwBallPressEndTime = nil
            self._p_joystick_ball.enabled = false
            self._p_joystick_ball.enabled = true
        else
            local rate = math.inverseLerp(0, self._throwBallTimeLimit, leftTime)
            self._p_img_time_left.fillAmount = rate
        end
    end
    if not UNITY_EDITOR and not UNITY_STANDALONE_OSX and not UNITY_STANDALONE_WIN then
        return
    end
    local input = CS.UnityEngine.Input
    local inputA = input.GetKey(CS.UnityEngine.KeyCode.A)
    local inputW = input.GetKey(CS.UnityEngine.KeyCode.W)
    local inputD = input.GetKey(CS.UnityEngine.KeyCode.D)
    local inputS = input.GetKey(CS.UnityEngine.KeyCode.S)
    local anyPressDown = inputA or inputW or inputD or inputS
    if self._anyAWDSKeyDown ~= anyPressDown then
        self._anyAWDSKeyDown = anyPressDown
        if anyPressDown then
            self:OnMovePointerDown()
        else
            self:OnMovePointerUp()
        end
    elseif self._anyAWDSKeyDown then
        local xValue = 0
        local yValue = 0
        if inputA then
            xValue = xValue - 1
        end
        if inputD then
            xValue = xValue + 1
        end
        if inputW then
            yValue = yValue + 1
        end
        if inputS then
            yValue = yValue - 1
        end 
        self:OnMoveValueChanged(CS.UnityEngine.Vector2(xValue, yValue).normalized)
    end
end

function SEHudJoyStickMediator:OnClickBg()
    self._p_tips_bag:SetVisible(true)
    ---@type SEHudJoyStickBagComponentData
    local param = {}
    param.seEnv = self._seEnv
    self._p_tips_bag:FeedData(param)
end

function SEHudJoyStickMediator:OnSystemEntryChanged()
    local unlockThrowBallLock = ConfigRefer.ConstSe:SEJoyStickThrowBallLock()
    local unlocked = true
    if unlockThrowBallLock ~= 0 then
        unlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(unlockThrowBallLock)
    end
    if self._throwBallUnlocked ~= unlocked then
        self._throwBallUnlocked = unlocked
        self:RefreshStickBallVisible()
    end
    unlocked = true
    local unlockExploreBagLock = ConfigRefer.ConstSe:SEExploreBagLock()
    if unlockExploreBagLock ~= 0 then
        unlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(unlockExploreBagLock)
    end
    if self._exploreBagUnlocked ~= unlocked then
        self._exploreBagUnlocked = unlocked
        self:RefreshBagBtnVisible()
    end
end

function SEHudJoyStickMediator:OnSeTeamBattleStatusChanged()
    
end

return SEHudJoyStickMediator
