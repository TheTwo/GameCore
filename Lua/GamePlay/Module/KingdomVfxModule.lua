local BaseModule = require('BaseModule')
local ManualResourceConst = require('ManualResourceConst')
local Delegate = require('Delegate')
local EventConst = require("EventConst")
local KingdomMapUtils = require('KingdomMapUtils')
local ModuleRefer = require('ModuleRefer')

local MapUtils = CS.Grid.MapUtils
local Vector3 = CS.UnityEngine.Vector3

---@class KingdomVfxModule
local KingdomVfxModule = class('KingdomVfxModule', BaseModule)

function KingdomVfxModule:ctor()

end

function KingdomVfxModule:ShutDown()
    self:OnRemove()
end
function KingdomVfxModule:Setup()
    self:OnRegister()
end
function KingdomVfxModule:OnRegister()
    g_Game.EventManager:AddListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnLodChanged))
    g_Game.EventManager:AddListener(EventConst.ENTER_COMMUNICATION_MODE, Delegate.GetOrCreate(self, self.DisplayLandFormVfx))
    self:RefreshMyCastleVfx()
end

function KingdomVfxModule:OnRemove()
    self:Clear()
    g_Game.EventManager:RemoveListener(EventConst.CAMERA_LOD_CHANGED, Delegate.GetOrCreate(self, self.OnLodChanged))
    g_Game.EventManager:RemoveListener(EventConst.ENTER_COMMUNICATION_MODE, Delegate.GetOrCreate(self, self.DisplayLandFormVfx))
end

function KingdomVfxModule:OnLodChanged(oldLod, newLod)
    self:RefreshMyCastleVfx()
end

function KingdomVfxModule:RefreshMyCastleVfx()
    local lod = KingdomMapUtils.GetLOD()
    if lod < 2 then
        if self.myCasleVfxHandle then
            self.myCasleVfxHandle:Delete()
            self.myCasleVfxHandle = nil
        end
        return
    else
        if not self.myCasleVfxHandle then
            self.myCasleVfxHandle = CS.DragonReborn.VisualEffect.VisualEffectHandle()
            local effectName = ManualResourceConst.vfx_bigmap_guangzhu_green_self
            self.myCasleVfxHandle:Create(effectName, effectName, nil, function(success, obj, handle)
                if success then
                    local go = handle.Effect.gameObject
                    local myCityCoord = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
                    local x = math.floor(myCityCoord.X)
                    local y = math.floor(myCityCoord.Y)
                    local pos = MapUtils.CalculateCoordToTerrainPosition(x, y, KingdomMapUtils.GetMapSystem())

                    go.transform.position = pos
                    go.transform.localScale = CS.UnityEngine.Vector3.one * 60
                end
            end)
        end
    end
end

function KingdomVfxModule:ShowCastleVfx(show)
    if self.myCasleVfxHandle then
        if show then
            self:RefreshMyCastleVfx()
        else
            self:Clear()
        end
    end
end

function KingdomVfxModule:RelocateCastle()
    self:Clear()
    self:RefreshMyCastleVfx()
end

function KingdomVfxModule:Clear()
    if self.myCasleVfxHandle then
        self.myCasleVfxHandle:Delete()
        self.myCasleVfxHandle = nil
    end
end

-- 世界事件大事件开启时，屏幕上飞粉色行军特效
-- function KingdomVfxModule:WorldEventPlayVfx()
--     local uiRootHud = CS.UnityEngine.GameObject.Find("RootHud")
--     self.worldEventVfx = CS.DragonReborn.VisualEffect.VisualEffectHandle()

--     self.worldEventVfx:Create("vfx_w_soldier_run_sm_pink", "vfx_w_soldier_run_sm_pink", uiRootHud.transform, function(success, obj, handle)
--         if success then
--             ---@type CS.UnityEngine.GameObject
--             local go = handle.Effect.gameObject
--             local startPos, endPos = self:GetRandomPosition()
--             go.transform.localPosition = v.Effect.gameObject
--             local step = 10
--             self.tickTimer = TimerUtility.IntervalRepeat(function()
--                 go.transform.localPosition = Vector3.MoveTowards(go.transform.localPosition, endPos, step * g_Game.Time.deltaTime)
--             end, 0.1, -1)
--         end
--     end, nil, 0, false, false)

-- end

-- -- 获得行军特效的起点终点
-- function KingdomVfxModule:GetRandomPosition()
--     local startPosX = math.random(0, 1920)
--     local startPosY = math.random(0, 1080)
--     local endPosX = math.random(0, 1920)
--     local endPosY = math.random(0, 1080)

--     return Vector3(startPosX, startPosY, 0), Vector3(endPosX, endPosY, 0)
-- end

return KingdomVfxModule
