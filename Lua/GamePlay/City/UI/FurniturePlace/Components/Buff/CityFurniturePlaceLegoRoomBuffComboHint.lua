local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local UIHelper = require("UIHelper")
local I18N = require("I18N")
local CityLegoBuffProvider_FurnitureCfg = require("CityLegoBuffProvider_FurnitureCfg")
local CityLegoBuffCalculatorTemp = require("CityLegoBuffCalculatorTemp")
local CityLegoBuffUnit = require("CityLegoBuffUnit")

---@class CityFurniturePlaceLegoRoomBuffComboHint:BaseUIComponent
local CityFurniturePlaceLegoRoomBuffComboHint = class('CityFurniturePlaceLegoRoomBuffComboHint', BaseUIComponent)

function CityFurniturePlaceLegoRoomBuffComboHint:OnCreate()

    --- 展示气泡的容器
    self._Contents = self:Transform("Contents")
    --- 预览Buff组成的名字
    self._p_text_name_room = self:Text("p_text_name_room")

    --- 模板隐藏根节点
    self._templates = self:Transform("templates")
    --- 节点模板
    ---@type CityFurniturePlaceLegoRoomBuffUINode
    self._p_item_furniture = self:LuaObject("p_item_furniture")
    --- 加号模板
    self._p_icon_add = self:GameObject("p_icon_add")

    self:InitPoolCache()
end

function CityFurniturePlaceLegoRoomBuffComboHint:InitPoolCache()
    self.nodePool = {self._p_item_furniture.CSComponent}
    self.plusPool = {self._p_icon_add}
    self.nodeIndex = 0
    self.plusIndex = 0
end

---@param legoBuilding CityLegoBuilding
---@param furLvCfg CityFurnitureLevelConfigCell
function CityFurniturePlaceLegoRoomBuffComboHint:TryShowAnyTips(legoBuilding, furLvCfg)
    local targetLvCfg, roomCfg = ModuleRefer.CityLegoBuffModule:GetLevelCfgByAddFurniture(legoBuilding, furLvCfg)

    local provider = CityLegoBuffProvider_FurnitureCfg.new(furLvCfg)
    local tempCalculator = CityLegoBuffCalculatorTemp.new()
    tempCalculator:AppendProvider(provider)

    local providers = legoBuilding.buffCalculator:GetAllPrividers()
    for _, v in pairs(providers) do
        tempCalculator:AppendProvider(v)
    end

    ---@type {buffCfg:RoomTagBuffConfigCell, level:number, id:number, isAuto:boolean, lackCount:number}[]
    local notActiveBuffUnit = {}
    for i = 1, targetLvCfg:RoomTagBuffsLength() do
        local buffCfgId = targetLvCfg:RoomTagBuffs(i)
        local buffCfg = ConfigRefer.RoomTagBuff:Find(buffCfgId)
        for j = 1, buffCfg:RoomTagListLength() do
            local tagId = buffCfg:RoomTagList(j)
            --- 先找到当前家具提供的tag会影响到的buff
            if provider:HasTag(tagId) then
                local buffUnit = CityLegoBuffUnit.new(buffCfg)
                --- 再判断这个buff是否还不能激活，只推荐还没激活的buff
                if not buffUnit:UpdateValidState(tempCalculator) then
                    table.insert(notActiveBuffUnit, {buffCfg = buffCfg, level = buffCfg:Level(), id = buffCfg:Id(), isAuto = buffCfg:AutoActive(), lackCount = buffUnit:GetLackTagCount()})
                    break
                end
            end
        end
    end

    if #notActiveBuffUnit == 0 then
        self:HideTips()
        return
    end

    table.sort(notActiveBuffUnit, function(a, b)
        if a.isAuto ~= b.isAuto then
            return a.isAuto
        end
        if a.lackCount ~= b.lackCount then
            return a.lackCount < b.lackCount
        end
        if a.level ~= b.level then
            return a.level > b.level
        end
        return a.id > b.id
    end)

    local recommendBuffCfg = notActiveBuffUnit[1].buffCfg
    local recommendBuffName = I18N.Get(recommendBuffCfg:BuffName())
    local nodeList = {}
    local providerMap = tempCalculator:GetTagProviderMap(recommendBuffCfg)

    for i = 1, recommendBuffCfg:RoomTagListLength() do
        local tagId = recommendBuffCfg:RoomTagList(i)
        local tagCfg = ConfigRefer.RoomTag:Find(tagId)
        local tagProvider = providerMap[i]
        local image = tagCfg:Icon()
        ---@type UIRoomBuffNode
        local node = {
            image = image,
            isPlaced = tagProvider ~= nil and tagProvider ~= provider,
            isPreview = tagProvider == provider
        }
        table.insert(nodeList, node)
    end
    self:ShowNodeTips(recommendBuffName, nodeList)
end

function CityFurniturePlaceLegoRoomBuffComboHint:ShowNodeTips(buffName, nodeList)
    self._p_text_name_room.text = buffName
    self:HideTips()
    for i = 1, #nodeList do
        local uiNode = self:AllocUiNode()
        uiNode:FeedData(nodeList[i])

        if i < #nodeList then
            self:AllocPlus()
        end
    end
end

function CityFurniturePlaceLegoRoomBuffComboHint:AllocUiNode()
    local nextIndex = self.nodeIndex + 1
    if self.nodePool[nextIndex] == nil then
        self.nodePool[nextIndex] = UIHelper.DuplicateUIComponent(self._p_item_furniture.CSComponent, self._Contents)
    end
    self.nodeIndex = nextIndex
    return self.nodePool[nextIndex]
end

function CityFurniturePlaceLegoRoomBuffComboHint:AllocPlus()
    local nextIndex = self.plusIndex + 1
    if self.plusPool[nextIndex] == nil then
        self.plusPool[nextIndex] = UIHelper.DuplicateUIGameObject(self._p_icon_add, self._Contents)
    end
    self.plusIndex = nextIndex
end

function CityFurniturePlaceLegoRoomBuffComboHint:HideTips()
    for i, v in ipairs(self.nodePool) do
        v.transform:SetParent(self._templates, false)
    end
    for i, v in ipairs(self.plusPool) do
        v.transform:SetParent(self._templates, false)
    end
    self.nodeIndex = 0
    self.plusIndex = 0
end

return CityFurniturePlaceLegoRoomBuffComboHint