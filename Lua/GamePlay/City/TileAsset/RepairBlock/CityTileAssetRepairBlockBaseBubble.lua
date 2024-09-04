local CityTileAssetGroupMemberBubble = require("CityTileAssetGroupMemberBubble")
---@class CityTileAssetRepairBlockBaseBubble:CityTileAssetGroupMemberBubble
---@field new fun():CityTileAssetRepairBlockBaseBubble
---@field parent CityTileAssetRepairBlockGroup
local CityTileAssetRepairBlockBaseBubble = class("CityTileAssetRepairBlockBaseBubble", CityTileAssetGroupMemberBubble)
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local Delegate = require("Delegate")
local Utils = require("Utils")
local Quaternion = CS.UnityEngine.Quaternion
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

---@param group CityTileAssetRepairBlockGroup
---@param repairBlock CityBuildingRepairBlock
function CityTileAssetRepairBlockBaseBubble:ctor(group, repairBlock)
    CityTileAssetGroupMemberBubble.ctor(self, group)
    self.repairBlock = repairBlock
    self:CollectRepairCost()
end

function CityTileAssetRepairBlockBaseBubble:CollectRepairCost()
    self.costItemId = {}
    local itemGroup = ConfigRefer.ItemGroup:Find(self.repairBlock.cfg:BaseRepairCost())
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        table.insert(self.costItemId, itemGroup:ItemGroupInfoList(i):Items())
    end
end

function CityTileAssetRepairBlockBaseBubble:GetCustomNameInGroup()
    return string.format("basebubble_%d", self.repairBlock.id)
end

function CityTileAssetRepairBlockBaseBubble:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    if not self:ShouldShow() then
        return string.Empty
    end

    return ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_bubble_need)
end

function CityTileAssetRepairBlockBaseBubble:ShouldShow()
    return self.repairBlock:IsValid() and not self.repairBlock:IsBaseRepaired()
end

function CityTileAssetRepairBlockBaseBubble:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then return end

    local tile = self.tileView.tile:GetCell()
    local x, y = tile.x + self.repairBlock.cfg:X(), tile.y + self.repairBlock.cfg:Y()
    local sizeX, sizeY = self.repairBlock.cfg:SizeX(), self.repairBlock.cfg:SizeY()
    local pos = self:GetCity():GetCenterWorldPositionFromCoord(x, y, sizeX, sizeY)
    go.transform:SetPositionAndRotation(pos, Quaternion.identity)

    self:OnBubbleLoaded(go)
end

function CityTileAssetRepairBlockBaseBubble:OnBubbleLoaded(go)
    local luaBehaviour = go:GetLuaBehaviour("City3DBubbleNeed")
    ---@type City3DBubbleNeed
    local bubble = luaBehaviour.Instance
    bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnRepairBaseClick), self.tileView.tile)
    self.bubble = bubble
    self:Refresh()
end

function CityTileAssetRepairBlockBaseBubble:Refresh()
    if not self.bubble then return end
    self.bubble:Reset():ShowDangerImg(self.repairBlock:IsPolluted())
    for i, v in ipairs(self.repairBlock:GetRepairBaseBubbleNeedData()) do
        self.bubble:AppendCustom(v.icon, v.text, v.showCheck)
    end
end

function CityTileAssetRepairBlockBaseBubble:OnAssetUnload()
    if self.bubble then
        self.bubble:ClearTrigger()
    end
    self.bubble = nil
end

---@param index number
---@param item City3DBubbleNeedItem
function CityTileAssetRepairBlockBaseBubble:OnRepairBaseClick(index, item)
    if self.repairBlock:IsPolluted() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("creep_clean_needed"))
        return
    end
    local city = self:GetCity()
    city:EnterRepairBlockBaseState(self.tileView.tile, self.repairBlock.cfg)
end

function CityTileAssetRepairBlockBaseBubble:OnTileViewInit()
    CityTileAssetGroupMemberBubble.OnTileViewInit(self)
    self:RegisterItemCountChangeListener()
    g_Game.EventManager:AddListener(EventConst.CITY_REPAIR_BLOCK_ENTER_STATE, Delegate.GetOrCreate(self, self.Hide))
    g_Game.EventManager:AddListener(EventConst.CITY_REPAIR_BLOCK_EXIT_STATE, Delegate.GetOrCreate(self, self.Show))
end

function CityTileAssetRepairBlockBaseBubble:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_REPAIR_BLOCK_ENTER_STATE, Delegate.GetOrCreate(self, self.Hide))
    g_Game.EventManager:RemoveListener(EventConst.CITY_REPAIR_BLOCK_EXIT_STATE, Delegate.GetOrCreate(self, self.Show))
    self:UnregisterItemCountChangeListener()
    CityTileAssetGroupMemberBubble.OnTileViewRelease(self)
end

function CityTileAssetRepairBlockBaseBubble:RegisterItemCountChangeListener()
    for _, itemId in ipairs(self.costItemId) do
        ModuleRefer.InventoryModule:AddCountChangeListener(itemId, Delegate.GetOrCreate(self, self.ForceRefresh))
    end
end

function CityTileAssetRepairBlockBaseBubble:UnregisterItemCountChangeListener()
    for _, itemId in ipairs(self.costItemId) do
        ModuleRefer.InventoryModule:RemoveCountChangeListener(itemId, Delegate.GetOrCreate(self, self.ForceRefresh))
    end
end

return CityTileAssetRepairBlockBaseBubble