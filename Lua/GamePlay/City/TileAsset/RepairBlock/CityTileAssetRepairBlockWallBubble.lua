local CityTileAssetGroupMemberBubble = require("CityTileAssetGroupMemberBubble")
---@class CityTileAssetRepairBlockWallBubble:CityTileAssetGroupMemberBubble
---@field new fun():CityTileAssetRepairBlockWallBubble
---@field parent CityTileAssetRepairBlockGroup
local CityTileAssetRepairBlockWallBubble = class("CityTileAssetRepairBlockWallBubble", CityTileAssetGroupMemberBubble)
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local Delegate = require("Delegate")
local Utils = require("Utils")
local Quaternion = CS.UnityEngine.Quaternion
local EventConst = require("EventConst")
local UIMediatorNames = require("UIMediatorNames")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

---@param group CityTileAssetRepairBlockGroup
---@param repairBlock CityBuildingRepairBlock
---@param wallIdx number
function CityTileAssetRepairBlockWallBubble:ctor(group, repairBlock, wallIdx)
    CityTileAssetGroupMemberBubble.ctor(self, group)
    self.repairBlock = repairBlock
    self.wallIdx = wallIdx
    self:CollectRepairCost()
end

function CityTileAssetRepairBlockWallBubble:CollectRepairCost()
    self.costItemId = {}
    local itemGroup = ConfigRefer.ItemGroup:Find(self.repairBlock.cfg:RepairWalls(self.wallIdx):Cost())
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        table.insert(self.costItemId, itemGroup:ItemGroupInfoList(i):Items())
    end
end

function CityTileAssetRepairBlockWallBubble:GetCustomNameInGroup()
    return string.format("wallbubble%d_of_%d", self.wallIdx, self.repairBlock.id)
end

function CityTileAssetRepairBlockWallBubble:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    if not self:ShouldShow() then
        return string.Empty
    end

    return ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_bubble_need)
end

function CityTileAssetRepairBlockWallBubble:ShouldShow()
    return self.repairBlock:IsValid() and self.repairBlock:IsBaseRepaired() and not self.repairBlock:IsWallRepaired(self.wallIdx) and not g_Game.UIManager:IsOpenedByName(UIMediatorNames.CityBuildingRepairBlockBaseUIMediator)
end

function CityTileAssetRepairBlockWallBubble:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then return end

    local tile = self.tileView.tile:GetCell()
    local wallCfg = self.repairBlock.cfg:RepairWalls(self.wallIdx)
    local x, y = tile.x + self.repairBlock.cfg:X() + wallCfg:OffsetX(), tile.y + self.repairBlock.cfg:Y() + wallCfg:OffsetY()
    local pos = self:GetCity():GetWorldPositionFromCoord(x, y)
    go.transform:SetPositionAndRotation(pos, Quaternion.identity)

    self:OnBubbleLoaded(go)
end

function CityTileAssetRepairBlockWallBubble:OnBubbleLoaded(go)
    local luaBehaviour = go:GetLuaBehaviour("City3DBubbleNeed")
    ---@type City3DBubbleNeed
    local bubble = luaBehaviour.Instance
    bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnRepairWallClick), self.tileView.tile)
    self.bubble = bubble
    self:Refresh()
end

function CityTileAssetRepairBlockWallBubble:Refresh()
    if not self.bubble then return end
    self.bubble:Reset():ShowDangerImg(self.repairBlock:IsPolluted())
    for i, v in ipairs(self.repairBlock:GetRepairWallBubbleNeedData(self.wallIdx)) do
        self.bubble:AppendCustom(v.icon, v.text, v.showCheck)
    end
end

function CityTileAssetRepairBlockWallBubble:OnAssetUnload()
    if self.bubble then
        self.bubble:ClearTrigger()
    end
    self.bubble = nil
end

---@param index number
---@param item City3DBubbleNeedItem
function CityTileAssetRepairBlockWallBubble:OnRepairWallClick(index, item)
    if self.repairBlock:IsPolluted() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("creep_clean_needed"))
        return
    end
    local city = self:GetCity()
    city:EnterRepairBlockWallState(self.tileView.tile, self.repairBlock.cfg, self.wallIdx)
end

function CityTileAssetRepairBlockWallBubble:OnTileViewInit()
    CityTileAssetGroupMemberBubble.OnTileViewInit(self)
    self:RegisterItemCountChangeListener()
    g_Game.EventManager:AddListener(EventConst.CITY_REPAIR_BLOCK_ENTER_STATE, Delegate.GetOrCreate(self, self.Hide))
    g_Game.EventManager:AddListener(EventConst.CITY_REPAIR_BLOCK_EXIT_STATE, Delegate.GetOrCreate(self, self.Show))
end

function CityTileAssetRepairBlockWallBubble:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_REPAIR_BLOCK_ENTER_STATE, Delegate.GetOrCreate(self, self.Hide))
    g_Game.EventManager:RemoveListener(EventConst.CITY_REPAIR_BLOCK_EXIT_STATE, Delegate.GetOrCreate(self, self.Show))
    self:UnregisterItemCountChangeListener()
    CityTileAssetGroupMemberBubble.OnTileViewRelease(self)
end

function CityTileAssetRepairBlockWallBubble:RegisterItemCountChangeListener()
    for _, itemId in ipairs(self.costItemId) do
        ModuleRefer.InventoryModule:AddCountChangeListener(itemId, Delegate.GetOrCreate(self, self.ForceRefresh))
    end
end

function CityTileAssetRepairBlockWallBubble:UnregisterItemCountChangeListener()
    for _, itemId in ipairs(self.costItemId) do
        ModuleRefer.InventoryModule:RemoveCountChangeListener(itemId, Delegate.GetOrCreate(self, self.ForceRefresh))
    end
end

return CityTileAssetRepairBlockWallBubble