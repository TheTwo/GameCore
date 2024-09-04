local I18N = require("I18N")
local KingdomMapUtils = require("KingdomMapUtils")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local Utils = require("Utils")
local TimeFormatter = require("TimeFormatter")
local ModuleRefer = require("ModuleRefer")

---@class KingdomDistrictNamesBehavior
---@field names CS.System.Collections.Generic.List(typeof(CS.UnityEngine.Component))
---@field openTimes CS.System.Collections.Generic.List(typeof(CS.UnityEngine.Component))
---@field remainTimes CS.System.Collections.Generic.List(typeof(CS.UnityEngine.Component))
local KingdomDistrictNamesBehavior = class("KingdomDistrictNamesBehavior")

function KingdomDistrictNamesBehavior:Awake()
    if not self.names then
        return
    end

    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local baseID = staticMapData:GetBaseId()
    
    local count = self.names.Count
    for i = 0, count - 1 do
        ---@type CS.UnityEngine.Component
        local component = self.names[i]
        if Utils.IsNotNull(component) then
            local id = i + 1
            local name = ModuleRefer.TerritoryModule:GetDistrictName(id)
            if not string.IsNullOrEmpty(name) then
                local textName = component:GetComponent(typeof(CS.U2DTextMesh))
                textName.text = name
                component:SetVisible(true)
            else
                component:SetVisible(false)
            end
        end
    end
end

function KingdomDistrictNamesBehavior:OnEnable()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecond))
    self:OnSecond()
end

function KingdomDistrictNamesBehavior:OnDisable()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecond))
end

function KingdomDistrictNamesBehavior:OnSecond()
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local baseID = staticMapData:GetBaseId()
    local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()-- - 60 * 86400

    local count = self.names.Count
    for i = 0, count - 1 do
        ---@type CS.U2DTextMesh
        local textOpenTime = self.openTimes[i]
        local textRemainTime = self.remainTimes[i]
        if Utils.IsNotNull(textOpenTime) and Utils.IsNotNull(textRemainTime) then
            local districtID = i + 1 + baseID
            local openTime = ModuleRefer.TerritoryModule:GetDistrictOpenTime(districtID)
            local remainTime = openTime - serverTime 
            if openTime > 0 and remainTime > 0 then
                textOpenTime:SetVisible(true)
                textRemainTime:SetVisible(true)
                textOpenTime.text = TimeFormatter.TimeToLocalTimeZoneDateTimeStringUseFormat(openTime, "yyyy/MM/dd HH:mm:ss")
                textRemainTime.text = TimeFormatter.SimpleFormatTimeWithDay(remainTime)
            else
                textOpenTime:SetVisible(false)
                textRemainTime:SetVisible(false)
            end
        end
        
    end
end

return KingdomDistrictNamesBehavior