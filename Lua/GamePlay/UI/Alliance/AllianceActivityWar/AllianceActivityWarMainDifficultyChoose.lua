local Delegate = require("Delegate")
local UIHelper = require("UIHelper")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceActivityWarMainDifficultyChooseData
---@field chooseList AllianceActivityWarMainDifficultyChooseCellData[]
---@field onChoose fun(index:number)
---@field index number

---@class AllianceActivityWarMainDifficultyChoose:BaseUIComponent
---@field new fun():AllianceActivityWarMainDifficultyChoose
---@field super BaseUIComponent
local AllianceActivityWarMainDifficultyChoose = class('AllianceActivityWarMainDifficultyChoose', BaseUIComponent)

function AllianceActivityWarMainDifficultyChoose:ctor()
    BaseUIComponent.ctor(self)
    ---@type CS.DragonReborn.UI.BaseComponent[]
    self._chooseItem = {}
    self._isInChoose = false
    self._selectedIndex = nil
    self._onChoose = nil
    ---@type AllianceActivityWarMainDifficultyChooseCellData[]
    self._chooseList = {}
    self._allowChange = false
end

function AllianceActivityWarMainDifficultyChoose:OnCreate(param)
    self._child_dropdown = self:Button("child_dropdown", Delegate.GetOrCreate(self, self.OnClickSelfBtn))
    self._p_arrow = self:RectTransform("p_arrow")
    self._p_list = self:Transform("p_list")
    self._p_item_template = self:BindComponent("p_item", typeof(CS.DragonReborn.UI.BaseComponent))
    self._p_text_lever = self:Text("p_text_lever")
    self._p_text_lever_detail = self:Text("p_text_lever_detail")
    self._p_item_template:SetVisible(false)
end

---@param data AllianceActivityWarMainDifficultyChooseData
function AllianceActivityWarMainDifficultyChoose:OnFeedData(data)
    self._selectedIndex = data.index
    self._onChoose = data.onChoose
    for _, v in ipairs(self._chooseItem) do
        UIHelper.DeleteUIComponent(v)
    end
    table.clear(self._chooseItem)
    table.clear(self._chooseList)
    for index = #data.chooseList, 1, -1 do
        local v = data.chooseList[index]
        self._chooseList[index] = v
        ---@type CS.DragonReborn.UI.BaseComponent
        local item = UIHelper.DuplicateUIComponent(self._p_item_template, self._p_list, v)
        item:SetVisible(true)
        self._chooseItem[index] = item
        ---@type AllianceActivityWarMainDifficultyChooseCell
        local cell = item.Lua
        cell:FeedData(v)
        cell.index = index
        cell.clickFunc = Delegate.GetOrCreate(self, self.OnClickCell)
    end
    local current = self._chooseList[data.index]
    self._p_text_lever.text = current.title
    self._p_text_lever_detail.text = current.content
    self:EndChoose()
end

function AllianceActivityWarMainDifficultyChoose:OnClickSelfBtn()
    if not self._allowChange then
        return
    end
    if self._isInChoose then
        self:EndChoose()
        return
    end
    self:BeginChoose()
end

function AllianceActivityWarMainDifficultyChoose:BeginChoose()
    local scale = self._p_arrow.localScale
    scale.x = 1
    self._p_arrow.localScale = scale
    self._p_list:SetVisible(true)
    self._isInChoose = true
end

function AllianceActivityWarMainDifficultyChoose:EndChoose()
    self._p_list:SetVisible(false)
    local scale = self._p_arrow.localScale
    scale.x = -1
    self._p_arrow.localScale = scale
    self._isInChoose = false
end

function AllianceActivityWarMainDifficultyChoose:OnClickCell(index)
    if not self._allowChange then
        return
    end
    if self._selectedIndex == index then
        self:EndChoose()
        return
    end
    local current = self._chooseList[index]
    if not current or current.isLocked then
        --self:EndChoose()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_battle_toast8"))
        return
    end
    self._selectedIndex = index
    self._p_text_lever.text = current.title
    self._p_text_lever_detail.text = current.content
    if self._onChoose then 
        self._onChoose(index)
    end
    self:EndChoose()
end

function AllianceActivityWarMainDifficultyChoose:SetAllowChange(allow)
    if not allow then
        self:EndChoose()
    end
    self._allowChange = allow
    self._p_arrow:SetVisible(allow)
end

return AllianceActivityWarMainDifficultyChoose