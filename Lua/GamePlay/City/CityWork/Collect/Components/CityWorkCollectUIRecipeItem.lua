local BaseTableViewProCell = require ('BaseTableViewProCell')
local UIHelper = require('UIHelper')
local ConfigRefer = require('ConfigRefer')
local CityWorkI18N = require("CityWorkI18N")
local Delegate = require('Delegate')

---@class CityWorkCollectUIRecipeItem:BaseTableViewProCell
---@field uiMediator CityWorkCollectUIMediator
local CityWorkCollectUIRecipeItem = class('CityWorkCollectUIRecipeItem', BaseTableViewProCell)
local CityWorkFormula = require("CityWorkFormula")
local EventConst = require("EventConst")
local I18N = require("I18N")

---@class CityWorkCollectUIRecipeData
---@field recipe CityProcessConfigCell
---@field resType number
---@field count number
---@field subData CityWorkCollectUIRecipeSubData

function CityWorkCollectUIRecipeItem:OnCreate()
    self._p_icon_item = self:Image("p_icon_item")
    self._p_text_title = self:Text("p_text_title")
    self._p_text_num = self:Text("p_text_num")

    self._p_table_output = self:TableViewPro("p_table_output")
    self._icon_lock = self:GameObject("icon_lock")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickShowDetails))
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self._p_img_selected = self:GameObject("p_img_selected")

    self._p_click_btn = self:Button("p_click_btn", Delegate.GetOrCreate(self, self.OnClickSelectRecipe))

    self.gameObject = self.CSComponent.gameObject
end

---@param data CityWorkCollectUIRecipeData
function CityWorkCollectUIRecipeItem:OnFeedData(data)
    self.data = data
    self.recipe = data.recipe
    self.uiMediator = data.uiMediator
    self:Refresh()
    self:TryAddListener()
end

function CityWorkCollectUIRecipeItem:IsMainCell()
    return true
end

function CityWorkCollectUIRecipeItem:Refresh()
    g_Game.SpriteManager:LoadSprite(self.recipe:OutputIcon(), self._p_icon_item)
    self._p_text_title.text = I18N.Get(self.recipe:Name())
    self:UpdateCount()
    self:UpdateOutputTable()
    
    self._p_btn_detail.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, self.data.subData.expanded and 180 or 0)

    self._p_img_selected:SetActive(self.uiMediator._select == self.data)
    self._icon_lock:SetActive(self:IsRecipeEffective())
end

function CityWorkCollectUIRecipeItem:UpdateCount()
    self._p_text_num.text = I18N.GetWithParams(CityWorkI18N.UIHint_CityWorkCollect_ResCountRemain, self.data.count)
end

function CityWorkCollectUIRecipeItem:UpdateOutputTable()
    self._p_table_output:Clear()
    
    local outputList = self.uiMediator:GetOutputByResType(self.data.resType)
    for i, v in ipairs(outputList) do
        ---@type ItemIconData
        local itemData = {}
        itemData.configCell = v
        itemData.showCount = false
        itemData.showSelect = false
        self._p_table_output:AppendData(itemData)
    end
end

function CityWorkCollectUIRecipeItem:OnRecycle()
    self:TryRemoveListener()
end

function CityWorkCollectUIRecipeItem:OnClose()
    self:TryRemoveListener()
end

function CityWorkCollectUIRecipeItem:OnHide()
    self:TryRemoveListener()
end

function CityWorkCollectUIRecipeItem:TryAddListener()
    if not self.evtListener then
        g_Game.EventManager:AddListener(EventConst.UI_CITY_COLLECT_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnSelectRecipeEvt))
        self.evtListener = true
    end
end

function CityWorkCollectUIRecipeItem:TryRemoveListener()
    if self.evtListener then
        g_Game.EventManager:RemoveListener(EventConst.UI_CITY_COLLECT_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnSelectRecipeEvt))
        self.evtListener = nil
    end
end

function CityWorkCollectUIRecipeItem:OnClickSelectRecipe()
    if self.data.isEmpty then return end
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_COLLECT_SELECT_RECIPE, self.data)
end

function CityWorkCollectUIRecipeItem:OnSelectRecipeEvt(data)
    self._p_img_selected:SetActive(data == self.data)
end

function CityWorkCollectUIRecipeItem:IsRecipeEffective()
    return not self.uiMediator.city.cityWorkManager:IsProcessEffective(self.recipe)
end

function CityWorkCollectUIRecipeItem:OnClickShowDetails()
    if self.data.subData.expanded then
        self.uiMediator:RemoveSubData(self.data)
    else
        self.uiMediator:InsertSubDataForDetails(self.data)
    end
    self.data.subData.expanded = not self.data.subData.expanded
    self._p_btn_detail.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, self.data.subData.expanded and 90 or 0)
end

return CityWorkCollectUIRecipeItem