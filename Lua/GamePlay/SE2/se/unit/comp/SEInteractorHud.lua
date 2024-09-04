local Delegate = require("Delegate")
local TimeFormatter = require("TimeFormatter")

---@class SEInteractorHud
---@field behaviour CS.DragonReborn.LuaBehaviour
---@field FacingCamera CS.U2DFacingCamera
---@field ProgressGo CS.UnityEngine.GameObject
---@field Icon CS.U2DSpriteMesh
---@field ProgressBar CS.U2DSpriteMesh
---@field TimeText CS.U2DTextMesh
---@field CityTrigger CS.DragonReborn.LuaBehaviour
---@field BtnGo CS.UnityEngine.GameObject
---@field IconBtn CS.U2DSpriteMesh
local SEInteractorHud = class('SEInteractorHud')

function SEInteractorHud:ctor()
    self._onClickFunc = nil
    self._tickTimeDuration = nil
    self._tickTimeLeft = nil
end

function SEInteractorHud:Awake()
    ---@type CityTrigger
    self._cityTrigger = self.CityTrigger.Instance
    self._cityTrigger:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickTrigger), nil, true, false)
end

function SEInteractorHud:SetupFacingCamera(camera, extraScale)
    self.FacingCamera.FacingCamera = camera
    self.FacingCamera.OrthographicScaleExtraScale = extraScale
end

function SEInteractorHud:SetIcon(icon)
    g_Game.SpriteManager:LoadSprite(icon, self.Icon)
    g_Game.SpriteManager:LoadSprite(icon, self.IconBtn)
end

function SEInteractorHud:SetTickTime(startTime, endTime, showText)
    self._tickTimeDuration = endTime - startTime
    self._tickTimeLeft = self._tickTimeDuration
    self.BtnGo:SetVisible(false)
    self.ProgressBar:SetVisible(true)
    self.TimeText:SetVisible(showText)
end

function SEInteractorHud:ClearTick()
    self._tickProgressStartTime = nil
    self._tickProgressEndTime = nil
    self.ProgressBar:SetVisible(false)
    self.TimeText:SetVisible(false)
end

---@param value fun():boolean
function SEInteractorHud:SetOnClick(value)
    self._onClickFunc = value
end

function SEInteractorHud:Reset()
    self.FacingCamera.OrthographicScaleExtraScale = 1
    self.FacingCamera.transform.localScale = CS.UnityEngine.Vector3.one
    self.ProgressBar.fillAmount = 0
    self.ProgressBar:SetVisible(false)
    self.TimeText:SetVisible(false)
    self.BtnGo:SetVisible(false)
    self.ProgressGo:SetVisible(false)
    self._onClickFunc = nil
    g_Game.SpriteManager:SetNullSprite(self.Icon)
    g_Game.SpriteManager:SetNullSprite(self.IconBtn)
end

function SEInteractorHud:OnClickTrigger()
    if self._onClickFunc then
        return self._onClickFunc()
    end
    return false
end

function SEInteractorHud:Tick(dt, nowTime)
    if not self._tickTimeLeft or not self._tickTimeDuration then return end
    local leftTime = self._tickTimeLeft - dt
    if leftTime < 0 then
        self._tickTimeLeft = nil
        self._tickTimeDuration = nil
        self.TimeText:SetVisible(false)
        return false
    end
    self._tickTimeLeft = leftTime
    local progress = math.inverseLerp(self._tickTimeDuration, 0, leftTime)
    self.ProgressBar.fillAmount = progress
    self.TimeText.text = TimeFormatter.SimpleFormatTime(math.max(0, leftTime))
    return true
end

function SEInteractorHud:SetVisible(visible, btnMode)
    self.behaviour:SetVisible(visible)
    self.BtnGo:SetVisible(btnMode)
    self.ProgressGo:SetVisible(not btnMode)
end

return SEInteractorHud