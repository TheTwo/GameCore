--- scene:scene_league_tips_gift

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIHelper = require("UIHelper")
local Utils = require("Utils")
local ConfigRefer = require("ConfigRefer")
local ItemGroupType = require("ItemGroupType")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceGiftTipsPopupMediatorParameter
---@field clickTrans CS.UnityEngine.RectTransform
---@field energyBoxConfig AllianceEnergyBoxConfigCell

---@class AllianceGiftTipsPopupMediator:BaseUIMediator
---@field new fun():AllianceGiftTipsPopupMediator
---@field super BaseUIMediator
local AllianceGiftTipsPopupMediator = class('AllianceGiftTipsPopupMediator', BaseUIMediator)

function AllianceGiftTipsPopupMediator:ctor()
    AllianceGiftTipsPopupMediator.super.ctor(self)
    ---@type CS.DragonReborn.UI.LuaBaseComponent[]
    self._cells = {}
end

function AllianceGiftTipsPopupMediator:OnCreate(param)
    self._p_content = self:RectTransform("p_content")
    self._p_scroll_gift = self:ScrollRect("p_scroll_gift")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_content = self:Text("p_text_content", "alliance_gift_chest_desc")
    self._p_text_reward = self:Text("p_text_reward")
    ---@see AllianceGiftTipsPopupCell
    self._p_item_sift = self:LuaBaseComponent("p_item_sift")
    self._p_item_sift:SetVisible(false)
end

---@param param AllianceGiftTipsPopupMediatorParameter
function AllianceGiftTipsPopupMediator:OnOpened(param)
    self._param = param
    local lvStr = tostring(param.energyBoxConfig:Level())
    self._p_text_name.text = I18N.GetWithParams("alliance_gift_chest_title", lvStr)
    self._p_text_reward.text = I18N.GetWithParams("alliance_gift_chest_listtitle", lvStr)
    local randomBox = ConfigRefer.RandomBox:Find(param.energyBoxConfig:Reward())
    ---@type AllianceGiftTipsPopupCellData[]
    local cellDataList = {}
    local totalWeight = 0
    local drawType = nil
    for i = 1, randomBox:GroupInfoLength() do
        local groupInfo = randomBox:GroupInfo(i)
        totalWeight = totalWeight + groupInfo:Weights()
        local groupItem = ConfigRefer.ItemGroup:Find(groupInfo:Groups())
        if drawType == nil then
            drawType = groupItem:Type()
        elseif drawType ~= groupItem:Type() then
            g_Logger.Error("无法同时展示随机和onebyone 抽取")
        end
    end
    for i = 1, randomBox:GroupInfoLength() do
        local groupInfo = randomBox:GroupInfo(i)
        local groupItem = ConfigRefer.ItemGroup:Find(groupInfo:Groups())
        if drawType == ItemGroupType.OneByOne then
            local drawCount = math.min(groupItem:ItemNum(), groupItem:ItemGroupInfoListLength())
            drawCount = math.min(drawCount, randomBox:MaxNum())
            drawCount = math.min(drawCount, randomBox:MinNum())
            for j = 1, drawCount do
                local itemInfo = groupItem:ItemGroupInfoList(j)
                ---@type AllianceGiftTipsPopupCellData
                local cellData = {}
                cellData.itemConfig = ConfigRefer.Item:Find(itemInfo:Items())
                cellData.count = itemInfo:Nums()
                cellData.weight = nil
                cellData.showAsFixed = true
                table.insert(cellDataList, cellData)
            end
        else
            local localWeight = 0
            for j = 1, groupItem:ItemGroupInfoListLength() do
                local itemInfo = groupItem:ItemGroupInfoList(j)
                localWeight = localWeight + itemInfo:Weights()
            end
            for j = 1, groupItem:ItemGroupInfoListLength() do
                local itemInfo = groupItem:ItemGroupInfoList(j)
                ---@type AllianceGiftTipsPopupCellData
                local cellData = {}
                cellData.itemConfig = ConfigRefer.Item:Find(itemInfo:Items())
                cellData.count = itemInfo:Nums()
                cellData.weight = (localWeight > 0 and (itemInfo:Weights() / localWeight) or 0) * (totalWeight > 0 and groupInfo:Weights() / totalWeight or 0)
                table.insert(cellDataList, cellData)
            end
        end
    end
    cellDataList[#cellDataList].isLast = true
    for i = #self._cells, #cellDataList + 1, -1  do
        local v = self._cells[i]
        self._cells[i] = nil
        UIHelper.DeleteUIGameObject(v.gameObject)
    end
    for i = 1, math.min(#cellDataList, #self._cells) do
        self._cells[i]:FeedData(cellDataList[i])
    end
    self._p_item_sift:SetVisible(true)
    for i = #self._cells + 1, #cellDataList do
        local cell = UIHelper.DuplicateUIComponent(self._p_item_sift, self._p_item_sift.transform.parent)
        self._cells[i] = cell
        cell:FeedData(cellDataList[i])
    end
    self._p_item_sift:SetVisible(false)
end

function AllianceGiftTipsPopupMediator:OnShow(param)
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.FocusOnRect))
end

function AllianceGiftTipsPopupMediator:OnHide(param)
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.FocusOnRect))
end

function AllianceGiftTipsPopupMediator:FocusOnRect()
    if not self._param then
        return
    end
    local trans = self._param.clickTrans
    if Utils.IsNull(trans) then
        return
    end
    local rect = trans.rect
    local rightCenter = CS.UnityEngine.Vector3(rect.xMax, rect.y + 0.5 * rect.yMax, 0)
    local worldPos = trans:TransformPoint(rightCenter)
    local contentLocalPos = self._p_content.parent:InverseTransformPoint(worldPos)
    self._p_content.anchoredPosition = CS.UnityEngine.Vector2(contentLocalPos.x, contentLocalPos.y)
end

return AllianceGiftTipsPopupMediator