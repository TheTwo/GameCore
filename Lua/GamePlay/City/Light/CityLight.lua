---@type CS.UnityEngine.RenderSettings
local RenderSettings = CS.UnityEngine.RenderSettings

---@class CityLight
---@field behaviour CS.DragonReborn.LuaBehaviour
---@field IsDay boolean
---@field Light CS.UnityEngine.Light
---@field new fun():CityLight
local CityLight = sealedClass('CityLight')

function CityLight:Awake()
    ---@type CS.DragonReborn.City.CityLightGradientConfig
    self._colorConfig = self.behaviour.gameObject:GetComponent(typeof(CS.DragonReborn.City.CityLightGradientConfig))
    self._dayConfig = self._colorConfig.dayLight
    self._nightConfig =  self._colorConfig.nightLight
    self._runTimeIsDay = false
end

function CityLight:Update()
    if self.IsDay ~= self._runTimeIsDay then
        self._runTimeIsDay = self.IsDay
        self:DoEffect()
    end
end

function CityLight:OnEnable()
    self._backup = RenderSettings.ambientLight
    self._runTimeIsDay = self.IsDay
    self:DoEffect()
end

function CityLight:OnDisable()
    if self._backup then
        RenderSettings.ambientLight = self._backup
    end
    self._backup = nil
end

function CityLight:DoEffect()
    local config = self._runTimeIsDay and self._dayConfig or self._nightConfig
    RenderSettings.ambientLight = config.environmentColor
    self.Light.color = config.mainLightColor
    self.Light.intensity = config.mainLightIntensity
    self.Light.transform.rotation = config.mainLightRotate
    self.Light.shadowStrength = config.shadowStrength
end

return CityLight

