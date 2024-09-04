local Utils = require("Utils")

local GMPage = require("GMPage")
---@class GMPageItem:GMPage
---@field new fun():GMPageItem
local GMPageItem = class("GMPageItem", GMPage)
local GUILayout = require("GUILayout")
local EmptyName = "找不到此物品"

function GMPageItem:ctor()
    self._itemId = ""
    self._itemCount = "99"
    self._searchResult = {}
    self._searchHash = {}
    self._debugSupport = nil
end

function GMPageItem:OnShow()
    if self.panel._serverCmdProvider then
        if self.panel._serverCmdProvider:NeedRefresh() then
            self.panel._serverCmdProvider:RefreshCmdList()
        end
    end
    self._debugSupport = g_Game.debugSupport
end

function GMPageItem:OnGUI()
    GUILayout.BeginHorizontal(GUILayout.Height(48))
    local spName = self:GetItemSpriteName()
    local sprite
    if not string.IsNullOrEmpty(spName) then
        sprite = self._debugSupport.GetCachedSpriteForGmGui(spName)
    end
    if Utils.IsNotNull(sprite) then
        local rect = GUILayout.GetRect(48, 48, GUILayout.shrinkWidth)
        self._debugSupport.DrawSpriteOnGui(sprite, rect)
    end
    GUILayout.BeginVertical()
    GUILayout.BeginHorizontal()
    GUILayout.Label("物品ID:", GUILayout.Width(80))
    self._itemId = GUILayout.TextField(self._itemId, GUILayout.ExpandWidth(true))
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    GUILayout.Label("物品名:", GUILayout.Width(80))
    GUILayout.Label(self:GetItemName(), GUILayout.ExpandWidth(true))
    if self.panel._serverCmdProvider then
        if self.panel._serverCmdProvider:IsReady() then
            if GUILayout.Button("添加", GUILayout.Width(50)) then
                self:RequestAddItem(checknumber(self._itemId), checknumber(self._itemCount))
            end
        end
    end
    GUILayout.EndHorizontal()
    GUILayout.EndVertical()
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    GUILayout.Label("数量:", GUILayout.Width(80))
    self._itemCount = GUILayout.TextField(self._itemCount, GUILayout.ExpandWidth(true))
    if GUILayout.Button("+", GUILayout.Width(30)) then
        self._itemCount = tostring(checknumber(self._itemCount) + 1)
    end
    if GUILayout.Button("-", GUILayout.Width(30)) then
        self._itemCount = tostring(math.max(1, checknumber(self._itemCount) - 1))
    end
    GUILayout.EndHorizontal()

    GUILayout.BeginHorizontal()
    GUILayout.Label("模糊搜索:", GUILayout.Width(80))
    local keyWord = GUILayout.TextField(self._keyword, GUILayout.ExpandWidth(true))
    if keyWord ~= self._keyword then
        self._keyword = keyWord
        self:SearchByKeyword()
    end
    GUILayout.EndHorizontal()

    if #self._searchResult > 0 then
        GUILayout.Space(5)
        for i = 1, math.min(#self._searchResult, 8) do
            if GUILayout.Button(("%d : %s"):format(self._searchResult[i].Id, self._searchResult[i].Name)) then
                self._itemId = self._searchResult[i].IdStr
                table.clear(self._searchResult)
                break
            end
        end
    end
end

function GMPageItem:OnHide()
    
end

function GMPageItem:Release()
    self._searchResult = nil
    self._searchHash = nil
    self._itemMap = nil
end

---@return table<string, {Id:number, Name:string, IdStr:string, Icon:string}>
function GMPageItem:GetItemMap()
    if not self._itemMap then
        self._itemMap = self:GetItemMapImp()
    end
    return self._itemMap
end

function GMPageItem:GetItemMapImp()
    local ConfigRefer = require("ConfigRefer")
    local I18N = require("I18N")
    local ItemConfig = ConfigRefer.Item
    local map = {}
    for _, cell in ItemConfig:ipairs() do
        local id = cell:Id()
        local idStr = tostring(id)
        map[idStr] = {Id = id, Name = I18N.Get(cell:NameKey()), IdStr = idStr, Icon = cell:Icon()}
    end
    table.sort(map, function(l, r) return l.Id < r.Id end)
    return map
end

function GMPageItem:GetItemName()
    if string.IsNullOrEmpty(self._itemId) then
        return EmptyName
    end
    local itemMap = self:GetItemMap()
    local item = itemMap[self._itemId]
    if not item then
        return EmptyName
    end
    return item.Name
end

function GMPageItem:GetItemSpriteName()
    if string.IsNullOrEmpty(self._itemId) then
        return string.Empty
    end
    local itemMap = self:GetItemMap()
    local item = itemMap[self._itemId]
    if not item then
        return string.Empty
    end
    return item.Icon
end

function GMPageItem:SearchByKeyword()
    table.clear(self._searchResult)
    table.clear(self._searchHash)
    if string.IsNullOrEmpty(self._keyword) then
        return
    end

    local number = checknumber(self._keyword)
    if number > 0 then
        self:SearchById(tostring(number))
    end
    self:SearchByName(self._keyword)
    table.sort(self._searchResult, function(l, r) return l.Id < r.Id end)
end

function GMPageItem:SearchById(idStr)
    local itemMap = self:GetItemMap()
    for _, value in pairs(itemMap) do
        if value.IdStr:match(idStr) and not self._searchHash[value.Id] then
            table.insert(self._searchResult, value)
            self._searchHash[value.Id] = value
        end
    end
end

function GMPageItem:SearchByName(name)
    local itemMap = self:GetItemMap()
    for _, value in pairs(itemMap) do
        if value.Name:match(name) and not self._searchHash[value.Id] then
            table.insert(self._searchResult, value)
            self._searchHash[value.Id] = value
        end
    end
end

function GMPageItem:RequestAddItem(id, count)
    local itemMap = self:GetItemMap()
    if itemMap[tostring(id)] == nil then
        return
    end
    if self.panel._serverCmdProvider and self.panel._serverCmdProvider:IsReady() then
        self.panel._serverCmdProvider:SendAddItem(id, count)
    end
end

return GMPageItem