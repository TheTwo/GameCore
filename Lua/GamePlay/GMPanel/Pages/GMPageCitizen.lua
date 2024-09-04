local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local GUILayout = require("GUILayout")
local CitizenBTDefine = require("CitizenBTDefine")

local GMPage = require("GMPage")

---@class GMPageCitizen:GMPage
---@field new fun():GMPageCitizen
---@field super GMPage
local GMPageCitizen = class('GMPageCitizen', GMPage)

function GMPageCitizen:ctor()
    GMPageCitizen.super.ctor(self)
    self._viewPos = CS.UnityEngine.Vector2.zero
    self._citizenId = nil
    self._values = {}
    self._targetCitizenId = string.Empty
    self._actionGroupId = string.Empty
end

function GMPageCitizen:OnShow()
    self._citizenId = nil
    self._values = {}
end

function GMPageCitizen:OnGUI()
    local city = ModuleRefer.CityModule:GetMyCity()
    if not city then return end
    local citizenMgr = city.cityCitizenManager
    local envMgr = city.cityEnvironmentalIndicatorManager
    if not citizenMgr or not envMgr then return end
    if not citizenMgr._citizenUnit then return end

    if UNITY_EDITOR then
        local isDebugPoint = (g_Game.PlayerPrefsEx:GetInt("CityInteractPointManager_DEBUG", 0) > 0)
        local isDebugPoint2 = GUILayout.Toggle(isDebugPoint, "开启交互点debug(需要重启)")
        if isDebugPoint2 ~= isDebugPoint then
            g_Game.PlayerPrefsEx:SetInt("CityInteractPointManager_DEBUG", isDebugPoint2 and 1 or 0)
            g_Game.PlayerPrefsEx:Save()
        end
    end

    GUILayout.Label("全局指标")
    GUILayout.BeginHorizontal()
    for _, v in pairs(envMgr.Indicators) do
        GUILayout.Label(("指标:%s= %0.2f"):format(v.Id, v.Value))
    end
    GUILayout.EndHorizontal()
    GUILayout.Label("==============================================================")
    GUILayout.BeginHorizontal()
    GUILayout.Label("指定居民:", GUILayout.shrinkWidth)
    self._targetCitizenId = GUILayout.TextField(self._targetCitizenId)
    GUILayout.Label("ActionGroupId:", GUILayout.shrinkWidth)
    self._actionGroupId = GUILayout.TextField(self._actionGroupId)
    local citizenId = tonumber(self._targetCitizenId)
    local citizen = citizenMgr._citizenUnit[citizenId]
    local actionGroupId = tonumber(self._actionGroupId)
    if citizen then
        if GUILayout.Button("指定", GUILayout.shrinkWidth) then
            citizen._btContext:Write(CitizenBTDefine.ContextKey.ClearFlag, true)
            citizen._btContext:Write(CitizenBTDefine.ContextKey.ForcePerformanceActionGroupId, actionGroupId)
        end
    end
    GUILayout.EndHorizontal()
    GUILayout.Label("==============================================================")
    self._viewPos = GUILayout.BeginScrollView(self._viewPos)
    for id, v in pairs(citizenMgr._citizenUnit) do
        local indicators = v._data._envIndicators
        GUILayout.BeginHorizontal()
        GUILayout.Label(("居民:%s id:%s"):format(I18N.Get(v._data._config:Name()), id))
        GUILayout.FlexibleSpace()
        if self._citizenId ~= id then
            if GUILayout.Button("修改", GUILayout.shrinkWidth) then
                self._citizenId = id
                table.clear(self._values)
                for _, indicator in pairs(indicators) do
                    self._values[indicator.Id] = indicator.value
                end
            end
        else
            if GUILayout.Button("保存", GUILayout.shrinkWidth) then
                for indicatorId, value in pairs(self._values) do
                    indicators[indicatorId].value = value
                end
                table.clear(self._values)
                self._citizenId = 0
            end
        end
        GUILayout.EndHorizontal()
        if self._citizenId == id then
            for indicatorId, value in pairs(self._values) do
                GUILayout.BeginHorizontal()
                GUILayout.Label(("  指标:%s="):format(indicatorId))
                self._values[indicatorId] = tonumber(GUILayout.TextField(tostring(value))) or value
                GUILayout.EndHorizontal()
            end
        else
            for _, indicator in pairs(indicators) do
                GUILayout.Label(("  指标:%s= %0.2f"):format(indicator.Id, indicator.value))
            end
        end
        if self._citizenId ~= id then
            local context = v._btContext
            for key, value in pairs(context._container) do
                if type(value) ~= 'table' then
                    GUILayout.Label(("  黑板值:%s= %s"):format(key, value))
                elseif value and value.dumpStr then
                    GUILayout.Label(("  黑板值:%s= %s"):format(key, value:dumpStr()))
                end
            end
        end
    end
    GUILayout.EndScrollView()
end

return GMPageCitizen