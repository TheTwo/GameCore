---Scene Name : scene_toast_jump
local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require('Delegate')
local EventConst = require("EventConst")
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local UIHelper = require("UIHelper")

---@class JumpToastMediator:BaseUIMediator
---@field activeItems {go:CS.UnityEngine.GameObject, canvasGroup:CS.UnityEngine.CanvasGroup, posY:number, killTime:number}[]
---@field waitKillItmes {go:CS.UnityEngine.GameObject, canvasGroup:CS.UnityEngine.CanvasGroup, posY:number, killTime:number}[]
local JumpToastMediator = class('JumpToastMediator', BaseUIMediator)

---@class JumpToastParameter
---@field content string
---@field imageId number | string
---@field color string

function JumpToastMediator:OnCreate()
    self.templateGo = self:GameObject("p_content")
    self.originPos = self.templateGo.transform.anchoredPosition
    self.offsetY = 50
    self.moveDuration = 0.1
    self.fadeDuration = 0.25
    self.existDuration = 2
    self.maxCount = 3
end

---@param param JumpToastParameter
function JumpToastMediator:OnOpened(param)
    self:InitComponentPool()
    self:UpdateCloseTime()
    if not string.IsNullOrEmpty(param.content) then
        self:AddToastInstance(param.content, param.imageId, param.color)
    end
    g_Game.EventManager:AddListener(EventConst.UI_EVENT_JUMP_TOAST_NEW, Delegate.GetOrCreate(self, self.OnNewToast))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
end

function JumpToastMediator:OnClose(param)
    self:ReleaseComponentPool()
    self:StopAllItemsDOTween()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
    g_Game.EventManager:RemoveListener(EventConst.UI_EVENT_JUMP_TOAST_NEW, Delegate.GetOrCreate(self, self.OnNewToast))
end

function JumpToastMediator:InitComponentPool()
    self.pool = LuaReusedComponentPool.new(self.templateGo, self.CSComponent.transform)
    self.activeCount = 0
    self.activeItems = {}
    self.waitKillItmes = {}
end

function JumpToastMediator:ReleaseComponentPool()
    self.pool:Release()
    self.pool = nil
end

function JumpToastMediator:StopAllItemsDOTween()
    for i, v in ipairs(self.activeItems) do
        v.go.transform:DOKill(false)
        v.canvasGroup:DOKill(false)
    end
    for i, v in ipairs(self.waitKillItmes) do
        v.go.transform:DOKill(false)
        v.canvasGroup:DOKill(false)
    end
    self.activeItems = nil
    self.waitKillItmes = nil
    self.activeCount = 0
end

function JumpToastMediator:OnNewToast(content, imageId, color)
    if not string.IsNullOrEmpty(content) then
        self:AddToastInstance(content, imageId, color)
    end
end

function JumpToastMediator:OnTick(delta)
    if g_Game.Time.time > self.closeTime then
        self:CloseSelf()
    end
end

function JumpToastMediator:OnFrameTick()
    local now = g_Game.RealTime.time
    while #self.activeItems > 0 and self.activeItems[#self.activeItems].killTime <= now do
        local tokill = table.remove(self.activeItems)
        self.activeCount = self.activeCount - 1
        tokill.posY = tokill.posY + (self.offsetY / 2)
        tokill.go.transform:DOKill(true)
        tokill.go.transform:DOAnchorPosY(tokill.posY, self.moveDuration, false)
        tokill.canvasGroup:DOKill(true)
        tokill.canvasGroup:DOFade(0, self.fadeDuration)
        tokill.killTime = now + math.max(self.fadeDuration, self.moveDuration)
        table.insert(self.waitKillItmes, tokill)
    end

    while #self.waitKillItmes > 0 and self.waitKillItmes[1].killTime <= now do
        local tokill = table.remove(self.waitKillItmes, 1)
        if self.pool then
            self.pool:Recycle(tokill.go)
        end
    end
end

function JumpToastMediator:AddToastInstance(content, imageId, color)
    self:RecycleItem(self.maxCount)
    self:MoveUpActiveItems()

    ---@type CS.UnityEngine.GameObject
    local item = self.pool:GetItem()
    local textComp = item.transform:Find("p_text_toast"):GetComponent(typeof(CS.UnityEngine.UI.Text))
    textComp.text = content
    if color then
        textComp.color = UIHelper.TryParseHtmlString(color)
    end
    local imageComp = item.transform:Find("p_text_toast/p_icon"):GetComponent(typeof(CS.UnityEngine.UI.Image))
    if type(imageId) == "string" then
        imageComp.gameObject:SetActive(true)
        UIHelper.LoadSprite(imageId, imageComp)
    elseif imageId and imageId > 0 then
        local image = ArtResourceUtils.GetUIItem(imageId)
        if not string.IsNullOrEmpty(image) then
            imageComp.gameObject:SetActive(true)
            g_Game.SpriteManager:LoadSprite(image, imageComp)
        else
            imageComp.gameObject:SetActive(false)
        end
    else
        imageComp.gameObject:SetActive(false)
    end

    self.activeCount = self.activeCount + 1
    item.transform.anchoredPosition = CS.UnityEngine.Vector2(self.originPos.x, self.originPos.y - self.offsetY)
    item.transform:DOAnchorPosY(self.originPos.y, self.moveDuration, false)
    ---@type CS.UnityEngine.CanvasGroup
    local canvasGroup = item:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    canvasGroup:DOKill(true)
    canvasGroup.alpha = 0
    canvasGroup:DOFade(1, self.fadeDuration)
    local datum = {go = item, canvasGroup = canvasGroup, posY = self.originPos.y, killTime = g_Game.RealTime.time + self.existDuration}
    table.insert(self.activeItems, 1, datum)
    self:UpdateCloseTime()
    ---@type CS.FpAnimation.FpAnimationCommonTrigger
    local trigger = item.gameObject:GetComponentInChildren(typeof(CS.FpAnimation.FpAnimationCommonTrigger), true)
    if Utils.IsNotNull(trigger) then
        trigger:ResetAll(CS.FpAnimation.CommonTriggerType.OnEnable)
        trigger:PlayAll(CS.FpAnimation.CommonTriggerType.OnEnable)
    end
end

function JumpToastMediator:UpdateCloseTime()
    self.closeTime = g_Game.Time.time + self.moveDuration + self.existDuration + 0.5
end

function JumpToastMediator:RecycleItem(maxCount)
    if self.activeCount < maxCount then return end

    self.activeCount = self.activeCount - 1
    local item = table.remove(self.activeItems)
    item.go.transform:DOKill(true)
    item.posY = item.posY + self.offsetY
    item.go.transform:DOAnchorPosY(item.posY, self.moveDuration, false)
    item.canvasGroup:DOFade(0, self.fadeDuration)
    item.killTime = g_Game.RealTime.time + math.max(self.moveDuration, self.fadeDuration)

    table.insert(self.waitKillItmes, item)
end

function JumpToastMediator:MoveUpActiveItems()
    for i, item in ipairs(self.activeItems) do
        item.go.transform:DOKill(true)
        item.posY = item.posY + self.offsetY
        item.go.transform:DOAnchorPosY(item.posY, self.moveDuration, false)
    end
end

return JumpToastMediator