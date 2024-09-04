local PvPTileAssetUnit = require("PvPTileAssetUnit")
local KingdomMapUtils = require("KingdomMapUtils")
local Utils = require("Utils")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ManualResourceConst = require("ManualResourceConst")
local KingdomConstant = require('KingdomConstant')
---@class CommonTileAssetSlgBubble : PvPTileAssetUnit
---@field behavior PvETileAsseRadarBubbleBehavior
local CommonTileAssetSlgBubble = class("CommonTileAssetSlgBubble", PvPTileAssetUnit)

function CommonTileAssetSlgBubble:GetLodPrefabName(lod)
    if self:CheckLod(lod) then
        return ManualResourceConst.ui3d_bubble_radar
    end
    return string.Empty
end

function CommonTileAssetSlgBubble:OnConstructionSetup()
    local data = self:GetData()
    if not data then
        self:Hide()
        return
    end
    
    local asset = self:GetAsset()
    self.behavior = asset:GetLuaBehaviour("PvETileAsseRadarBubbleBehavior").Instance
    if Utils.IsNull(self.behavior) then
        self:Hide()
        return
    end

    self.behavior:SetFrameActive(true)
    self.behavior:SetBubbleIcon(self:GetIcon())
    self.behavior:SetLodIcon(self:GetIcon())
    self.behavior:SetPetRewardActive(false)
    -- g_Logger.Log("Quality: " ..tostring(data))
    if self:GetQuality() >= 0 then
        self.behavior:SetQuality(self:GetQuality())
    else
        self.behavior:SetBubbleFrameCyst(self:GetCustomBubbleFrameCyst())
        self.behavior:SetBubbleBase(self:GetCustomBubbleBase())
        self.behavior:SetLodFrame(self:GetCustomLodFrame())
    end
    self.behavior:SetYOffset(self:GetYOffset())
    self.behavior:InitEvent(nil, self:GetCustomData())
    self:RefreshBubble()

    -- self.behavior:SetTrigger(Delegate.GetOrCreate(self, self.OnIconClick))
    self.behavior:RefreshAll()
end

function CommonTileAssetSlgBubble:OnConstructionShutdown()
    self.behavior = nil
end

function CommonTileAssetSlgBubble:OnLodChanged(oldLod, newLod)
    CommonTileAssetSlgBubble.super.OnLodChangedHighLod(self, oldLod, newLod)
    if Utils.IsNull(self.behavior) then
        return
    end

    self:RefreshBubble()
end

function CommonTileAssetSlgBubble:RefreshBubble()
    local showBubble = KingdomMapUtils.InMapNormalLod()
    self.behavior:ShowBubble(showBubble)
    self.behavior:ShowLodIcon(not showBubble)
    self:CustomBubbleLogic()
end

function CommonTileAssetSlgBubble:CheckLod(lod)
    --override this
    return lod < KingdomConstant.HighLod
end

function CommonTileAssetSlgBubble:GetIcon()
    --override this
end

function CommonTileAssetSlgBubble:GetQuality()
    --override this
    return 0
end

function CommonTileAssetSlgBubble:OnIconClick()
    --override this
end

function CommonTileAssetSlgBubble:GetCustomData()
    --override this
end

function CommonTileAssetSlgBubble:GetYOffset()
    --override this
    return 200
end

function CommonTileAssetSlgBubble:GetCustomBubbleBase()
    --override this
end

function CommonTileAssetSlgBubble:GetCustomBubbleFrameCyst()
    --override this
end

function CommonTileAssetSlgBubble:GetCustomLodFrame()
    --override this
end

function CommonTileAssetSlgBubble:CustomBubbleLogic()
    --override this
end

return CommonTileAssetSlgBubble