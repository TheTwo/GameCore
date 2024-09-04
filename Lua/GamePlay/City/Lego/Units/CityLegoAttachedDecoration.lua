---@class CityLegoAttachedDecoration
---@field new fun():CityLegoAttachedDecoration
local CityLegoAttachedDecoration = sealedClass("CityLegoAttachedDecoration")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")

---@param legoBuilding CityLegoBuilding
---@param cfg AttachedDecoration
function CityLegoAttachedDecoration:ctor(legoBuilding, cfg, blockCfgId)
    self.payload = cfg
    self.pointName = cfg:AttachPoint()
    self.legoBuilding = legoBuilding
    
    self.isOutside = false
    local blockCfg = ConfigRefer.LegoBlock:Find(blockCfgId)
    for i = 1, blockCfg:AttachPointLength() do
        local attachPointCfgId = blockCfg:AttachPoint(i)
        local attachPointCfg = ConfigRefer.LegoBlockAttachPoint:Find(attachPointCfgId)
        if attachPointCfg:Name() == self.pointName then
            self.isOutside = attachPointCfg:Outside()
            break
        end
    end

    self.decorationCfg = ConfigRefer.LegoDecoration:Find(cfg:Decoration())
    self:InitPrefabName()
end

function CityLegoAttachedDecoration:InitPrefabName()
    local decoStyle = self.payload:Style()
    local decoArtMapCfg = ConfigRefer.LegoDecorationArtMap:Find(decoStyle)
    local modelCfgId = 0
    if decoArtMapCfg then
        if self.isOutside then
            modelCfgId = decoArtMapCfg:Model()
        else
            modelCfgId = decoArtMapCfg:ModelIndoor()
        end
    end
    
    self.decorationPrefabName, self.scale = ArtResourceUtils.GetItemAndScale(modelCfgId)
    if self.scale == 0 then
        self.scale = 1
    end
end

return CityLegoAttachedDecoration