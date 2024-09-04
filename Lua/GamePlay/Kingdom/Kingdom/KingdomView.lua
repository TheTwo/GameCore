local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local TimerUtility = require("TimerUtility")
local EventConst = require("EventConst")

local MapHUDManager = CS.Kingdom.MapHUDManager


---@class KingdomView
---@field surfaces table<KingdomSurface>
---@field hudManager CS.Kingdom.MapHUDManager
local KingdomView = class("KingdomView")

function KingdomView:ctor()
    self.surfaces = {}
    self.hudManager = MapHUDManager()
end

---@param mapSystem CS.Grid.MapSystem
function KingdomView:Initialize(mapSystem)
    table.insert(self.surfaces, require("KingdomSurfaceLandmark").new())
    table.insert(self.surfaces, require("KingdomSurfaceCastle").new())
    table.insert(self.surfaces, require("KingdomSurfaceSelfAllianceCastle").new())
    table.insert(self.surfaces, require("KingdomSurfaceSelfAllianceCenter").new())
    table.insert(self.surfaces, require("KingdomSurfaceEntityAttachment").new())
    table.insert(self.surfaces, require("KingdomSurfaceOcean").new())
    --table.insert(self.surfaces, require("KingdomSurfaceLandform").new())
    table.insert(self.surfaces, require("KingdomSurfaceHighland").new())
    table.insert(self.surfaces, require("KingdomSurfaceDistrictNames").new())
    table.insert(self.surfaces, require("KingdomSurfaceBasemap").new())

    self.hudManager:Initialize(Delegate.GetOrCreate(self, self.IconClickCallback))

    ---@param surface KingdomSurface
    for _, surface in ipairs(self.surfaces) do
        surface:Initialize(mapSystem, self.hudManager)
    end
    
    ModuleRefer.KingdomInteractionModule:AddOnClick(Delegate.GetOrCreate(self, self.OnClick))

    g_Game.EventManager:AddListener(EventConst.ENTER_KINGDOM_MAP_START, Delegate.GetOrCreate(self, self.OnEnterMap))
    g_Game.EventManager:AddListener(EventConst.LEAVE_KINGDOM_MAP_START, Delegate.GetOrCreate(self, self.OnLeaveMap))
    g_Game.EventManager:AddListener(EventConst.CAMERA_SIZE_CHANGED, Delegate.GetOrCreate(self, self.OnSizeChanged))

end

function KingdomView:Release()
    ModuleRefer.KingdomInteractionModule:RemoveOnClick(Delegate.GetOrCreate(self, self.OnClick))

    g_Game.EventManager:RemoveListener(EventConst.ENTER_KINGDOM_MAP_START, Delegate.GetOrCreate(self, self.OnEnterMap))
    g_Game.EventManager:RemoveListener(EventConst.LEAVE_KINGDOM_MAP_START, Delegate.GetOrCreate(self, self.OnLeaveMap))
    g_Game.EventManager:RemoveListener(EventConst.CAMERA_SIZE_CHANGED, Delegate.GetOrCreate(self, self.OnSizeChanged))

    self:LeaveHighLod(true)

    ---@param surface KingdomSurface
    for _, surface in ipairs(self.surfaces) do
        surface:Dispose()
    end

    self.hudManager:Dispose()
end

function KingdomView:ClearUnits()
    ---@param surface KingdomSurface
    for _, surface in ipairs(self.surfaces) do
        surface:ClearUnits()
    end
end

function KingdomView:Tick()
    if not KingdomMapUtils.IsMapState() then
        return
    end

    self.hudManager:Tick()
end

function KingdomView:OnEnterMap()
    ---@param surface KingdomSurface
    for _, surface in ipairs(self.surfaces) do
        surface:OnEnterMap()
    end
end

function KingdomView:OnLeaveMap()
    ---@param surface KingdomSurface
    for _, surface in ipairs(self.surfaces) do
        surface:OnLeaveMap()
    end
end

function KingdomView:OnLodChanged(oldLod, newLod)
    for _, surface in ipairs(self.surfaces) do
        surface:OnLodChanged(oldLod, newLod)
    end
    
    local oldHigh = KingdomMapUtils.InMapKingdomLod(oldLod)
    local newHigh = KingdomMapUtils.InMapKingdomLod(newLod)
    if not oldHigh and not newHigh then
        return
    end

    if not oldHigh and newHigh then
        self:EnterHighLod()
    elseif oldHigh and not newHigh then
        self:LeaveHighLod(false)
    end
end

function KingdomView:OnSizeChanged(oldSize, newSize)
    ---@param surface KingdomSurface
    for _, surface in ipairs(self.surfaces) do
        surface:OnSizeChanged(oldSize, newSize)
    end
end

 
function KingdomView:EnterHighLod()
    ---@param surface KingdomSurface
    for _, surface in ipairs(self.surfaces) do
        surface:OnEnterHighLod()
    end
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.Tick), 0)
end

function KingdomView:LeaveHighLod()
    self.hudManager:Clear()

    ---@param surface KingdomSurface
    for _, surface in ipairs(self.surfaces) do
        surface:OnLeaveHighLod()
    end
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.Tick), 0)
end

function KingdomView:OnClick(trans, position)
    self.hudManager:SetClickPosition(position)
end

function KingdomView:IconClickCallback(id)
    ---@param surface KingdomSurface
    for _, surface in ipairs(self.surfaces) do
        if surface:OnIconClick(id) then
            return
        end
    end
end

return KingdomView