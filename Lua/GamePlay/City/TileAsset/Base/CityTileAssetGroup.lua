local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetGroup:CityTileAsset
---@field members CityTileAssetGroupMember[]
---@field memberIdxMap table<string, CityTileAssetGroupMember>
---@field new fun():CityTileAssetGroup
local CityTileAssetGroup = class("CityTileAssetGroup", CityTileAsset)

---@interface ICityTileAssetGroupMember
---@field GetCustomNameInGroup fun():string @返回一个Group内的唯一名, 用于ForceRefresh时刷新判断是否是同一对象
---@field parent CityTileAssetGroup

function CityTileAssetGroup:ctor()
    CityTileAsset.ctor(self)
    self.members = nil
end

---@return CityTileAsset[]
function CityTileAssetGroup:GetCurrentMembers()
    ---override this
end

---@private
---@return CityTileAssetGroupMember[], table<string, CityTileAssetGroupMember>
function CityTileAssetGroup:GetCurrentMembersImp()
    local members = self:GetCurrentMembers()
    if not members then
        return nil, nil
    end
    local map = {}
    for i, v in ipairs(members) do
        local name = v:GetCustomNameInGroup()
        if map[name] then
            g_Logger.Error(("在同一个Group中存在重复name, 请检查%s实现"):format(GetClassName(self)))
        end
        map[name] = v
    end
    return members, map
end

function CityTileAssetGroup:Show()
    local members, countMap = self:GetCurrentMembersImp()
    if not members then return end

    self:ShowImp(members, countMap)
end

---@private
function CityTileAssetGroup:ShowImp(members, countMap)
    self.members = members
    self.memberIdxMap = countMap
    for i, asset in ipairs(self.members) do
        asset:SetView(self.tileView)
        asset:OnTileViewInit()
    end

    for i, asset in ipairs(self.members) do
        asset:Show()
    end
end

function CityTileAssetGroup:Hide()
    if not self.members then return end

    self:HideImp()
end

---@private
function CityTileAssetGroup:HideImp()
    for i, asset in ipairs(self.members) do
        asset:Hide()
    end

    for i, asset in ipairs(self.members) do
        asset:OnTileViewRelease()
        asset:SetView(nil)
    end

    self.members = nil
    self.memberIdxMap = nil
end

function CityTileAssetGroup:Refresh()
    if not self.members then return end

    for i, asset in ipairs(self.members) do
        asset:Refresh()
    end
end

function CityTileAssetGroup:ForceRefresh()
    if not self.members then return end

    local members, maps = self:GetCurrentMembersImp()
    ---@type CityTileAssetGroupMember[]
    local toShow, toHide = {}, {}
    for name, asset in pairs(maps) do
        if not self.memberIdxMap[name] then
            toShow[name] = asset
        end
    end

    for name, asset in pairs(self.memberIdxMap) do
        if not maps[name] then
            toHide[name] = asset
        end
    end

    for name, asset in pairs(toHide) do
        self.memberIdxMap[name] = nil
        table.removebyvalue(self.members, asset)
        asset:Hide()
        asset:OnTileViewRelease()
        asset:SetView(nil)
    end

    for _, v in ipairs(self.members) do
        v:ForceRefresh()
    end

    for name, asset in pairs(toShow) do
        self.memberIdxMap[name] = asset
        table.insert(self.members, asset)
        asset:SetView(self.tileView)
        asset:OnTileViewInit()
        asset:Show()
    end
end

function CityTileAssetGroup:IsLoadedOrEmpty()
    if not self.members then
        return true
    end
    if #self.members == 0 then
        return true
    end
    for i, asset in ipairs(self.members) do
        if not asset:IsLoadedOrEmpty() then
            return false
        end
    end
    return true
end

function CityTileAssetGroup:OnAssetLoadedProcess(go, userdata)
    g_Logger.Error("会调用进这里说明逻辑出问题了")
end

function CityTileAssetGroup:SetSelected(select)
    if not self.members then return end

    for i, asset in ipairs(self.members) do
        asset:SetSelected(select)
    end
end

return CityTileAssetGroup