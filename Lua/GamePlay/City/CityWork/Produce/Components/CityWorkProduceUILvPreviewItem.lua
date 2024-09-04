local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local ItemGroupHelper = require("ItemGroupHelper")

---@class CityWorkProduceUILvPreviewItem:BaseTableViewProCell
local CityWorkProduceUILvPreviewItem = class('CityWorkProduceUILvPreviewItem', BaseTableViewProCell)

function CityWorkProduceUILvPreviewItem:OnCreate()
    self._p_base_current = self:GameObject("p_base_current")
    self._p_text_level = self:Text("p_text_level")
    self._p_group_item = self:GameObject("p_group_item")
    ---@type StarItemIcon
    self._child_item_star_s = self:LuaObject("child_item_star_s")

    self._img_01 = self:GameObject("img_01")
    self._img_02 = self:GameObject("img_02")

    self._p_group_outcome = self:Transform("p_group_outcome")
    ---@type BaseItemIcon
    self._child_item_standard_s = self:LuaBaseComponent("child_item_standard_s")
    self._output_pool = LuaReusedComponentPool.new(self._child_item_standard_s, self._p_group_outcome)
end

---@param data CityWorkProduceUILvPreviewItemData
function CityWorkProduceUILvPreviewItem:OnFeedData(data)
    self.data = data
    self._p_text_level.text = data.label

    self._img_01:SetActive(self.data.isCurrent)
    self._img_02:SetActive(self.data.isCurrent)
    
    local eleResCfg = ConfigRefer.CityElementResource:Find(data.processCfg:GenerateResType())
    if eleResCfg == nil then
        self._child_item_star_s:SetVisible(false)
        self._p_group_outcome:SetVisible(false)
        return
    end

    self._child_item_star_s:SetVisible(true)

    ---@type StarItemIconData
    self._recipeData = self._recipeData or {}
    self._recipeData.starCount = eleResCfg:Star()
    self._recipeData.itemIconData = self._recipeData.itemIconData or {}
    self._recipeData.itemIconData.customImage = eleResCfg:Icon()
    self._recipeData.itemIconData.customQuality = eleResCfg:Quality()
    self._recipeData.itemIconData.showCount = false
    self._recipeData.itemIconData.showTips = false
    self._child_item_star_s:FeedData(self._recipeData)

    local output = ConfigRefer.ItemGroup:Find(eleResCfg:Reward())
    if output == nil then
        self._p_group_outcome:SetVisible(false)
        return
    end

    self._p_group_outcome:SetVisible(true)
    self._output_pool:HideAll()
    
    ---@type ItemIconData[]
    self._outputData = self._outputData or {}
    local list, map = ItemGroupHelper.GetPossibleOutput(output)
    for i = 1, math.min(3, #list) do
        local info = list[i]
        local itemCfg = ConfigRefer.Item:Find(info.id)
        self._outputData[i] = self._outputData[i] or {}
        self._outputData[i].configCell = itemCfg
        self._outputData[i].showTips = true
        self._outputData[i].showCount = false
        local item = self._output_pool:GetItem()
        item:FeedData(self._outputData[i])
    end
end

return CityWorkProduceUILvPreviewItem