local KingdomMapUtils = require('KingdomMapUtils')

---@class WaitUnitOperation
---@field patience number
---@field waitTileX number
---@field waitTileZ number
---@field waitTileLod number
---@field process fun(tile:MapRetrieveResult)
local WaitUnitOperation = class("WaitUnitOperation")

local MaxPatience = 3

function WaitUnitOperation:SetData(x, z, lod, process)
    self.waitTileX = x
    self.waitTileZ = z
    self.waitTileLod = lod
    self.patience = MaxPatience
    self.process = process
end

function WaitUnitOperation:Reset()
    self.waitTileX = nil
    self.waitTileZ = nil
    self.waitTileLod = nil
    self.patience = 0
    self.process = nil
end

function WaitUnitOperation:IsValid()
    return self.waitTileLod and self.patience > 0
end

function WaitUnitOperation:Tick(dt)
    self.patience = self.patience - dt
    
    local tile = KingdomMapUtils.RetrieveMap(self.waitTileX, self.waitTileZ)
    if tile and tile.entity and self.process and KingdomMapUtils.GetLOD() == self.waitTileLod then
        self.process(tile)
        self:Reset()
    end
end

return WaitUnitOperation