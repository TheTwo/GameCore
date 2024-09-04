local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseUIComponent = require("BaseUIComponent")

---@class SEHudJoyStickBagComponentData
---@field seEnv SEEnvironment

---@class SEHudJoyStickBagComponent:BaseUIComponent
---@field new fun():SEHudJoyStickBagComponent
---@field super BaseUIComponent
local SEHudJoyStickBagComponent = class('SEHudJoyStickBagComponent', BaseUIComponent)

function SEHudJoyStickBagComponent:ctor()
    SEHudJoyStickBagComponent.super.ctor(self)
    ---@type SESceneBagManager
    self._seBagMgr = nil
    ---@type SEHudJoyStickBagItemCellData[]
    self._tableCellData = {}
end

function SEHudJoyStickBagComponent:OnCreate(param)
    self._p_btn_close_tips = self:Button("p_btn_close_tips", Delegate.GetOrCreate(self, self.OnClickClose))
    self._p_text_bag = self:Text("p_text_bag", "explore_des_bag")
    self._p_table_bag = self:TableViewPro("p_table_bag")
end

---@param param SEHudJoyStickBagComponentData
function SEHudJoyStickBagComponent:OnFeedData(param)
    self._seBagMgr = param.seEnv:GetSceneBagManager()
    self:RefreshTable()
end

function SEHudJoyStickBagComponent:RefreshTable()
    table.clear(self._tableCellData)
    self._p_table_bag:Clear()
    for itemId, count in self._seBagMgr:PairsOfCachedItems() do
        if count > 0 then
            ---@type SEHudJoyStickBagItemCellData
            local cellData = {}
            cellData.bagMgr = self._seBagMgr
            cellData.itemId = itemId
            table.insert(self._tableCellData, cellData)
            self._p_table_bag:AddData(cellData)
        end
    end
end

function SEHudJoyStickBagComponent:OnClickClose()
    self:SetVisible(false)
end

return SEHudJoyStickBagComponent