---@class MapPopupImageWithText
---@field behaviour CS.DragonReborn.LuaBehaviour
---@field template CS.UnityEngine.GameObject
---@field root CS.UnityEngine.Transform
---@field new fun():MapPopupImageWithText
---@field activeUnits {transform:CS.UnityEngine.Transform, distance:number, duration:number, startTime:number}[]
local MapPopupImageWithText = class("MapPopupImageWithText")
local Vector3 = CS.UnityEngine.Vector3
local Quaternion = CS.UnityEngine.Quaternion

function MapPopupImageWithText:Start()
    self.activeUnits = {}
end

function MapPopupImageWithText:PopupUnit(image, content, distance, duration)
    ---@type CS.UnityEngine.Transform
    local unit = CS.UnityEngine.GameObject.Instantiate(self.template, self.root).transform
    unit.localPosition = Vector3.zero
    unit.localRotation = Quaternion.identity
    unit.localScale = Vector3.one

    g_Game.SpriteManager:LoadSprite(image, unit:Find("p_sprite"):GetComponent(typeof(CS.U2DSpriteMesh)))
    unit:Find("p_sprite/p_text"):GetComponent(typeof(CS.U2DTextMesh)).text = content

    self:AppendPopupUnit(unit, distance or 1, duration or 1)
end

function MapPopupImageWithText:AppendPopupUnit(unit, distance, duration)
    if duration <= 0 then
        duration = 1
    end

    local save = {
        transform = unit,
        distance = distance,
        duration = duration,
        startTime = g_Game.RealTime.time
    }
    save.transform.gameObject:SetActive(true)
    table.insert(self.activeUnits, save)
end

function MapPopupImageWithText:Update()
    if not self.activeUnits then return end
    if #self.activeUnits == 0 then return end

    local cur = g_Game.RealTime.time
    for i = #self.activeUnits, 1, -1 do
        local v = self.activeUnits[i]
        local value = math.clamp01((cur - v.startTime) / v.duration)
        local distance = math.lerp(0, v.distance, value)
        v.transform.localPosition = Vector3(0, distance, 0)
        if value == 1 then
            local removed = table.remove(self.activeUnits, i)
            CS.UnityEngine.GameObject.Destroy(removed.transform.gameObject)
        end
    end
end

function MapPopupImageWithText:DeleteAll()
    if not self.activeUnits then return end
    if #self.activeUnits == 0 then return end

    for i, v in ipairs(self.activeUnits) do
        CS.UnityEngine.GameObject.Destroy(v.transform.gameObject)
    end
    table.clear(self.activeUnits)
end

return MapPopupImageWithText