local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')

---@class BagItemCell:BaseUIComponent
local BagItemCell = class('BagItemCell', BaseTableViewProCell)

function BagItemCell:ctor()

end

function BagItemCell:OnCreate()
    self.itemRoot = self:LuaBaseComponent("p_item_standard_s")
    ---@type BaseItemIcon
    self.itemLogic = self.itemRoot.Lua
end

function BagItemCell:Select()
    self.itemLogic:ChangeSelectStatus(true)
end

function BagItemCell:UnSelect()
    self.itemLogic:ChangeSelectStatus(false)
end

function BagItemCell:OnIconClick()
    local bagMediator = g_Game.UIManager:FindUIMediatorByName(require( 'UIMediatorNames').BagMediator)
    bagMediator.tableviewproTableList:SetToggleSelect(self.curUid)
    bagMediator:SelectItem(self.curUid)
end

function BagItemCell:OnFeedData(Uid)
    self.curUid = Uid
    self.itemLogic:ChangeSelectStatus(false)
    ---@type ItemIconData
    local baseItenData = {}
    baseItenData.showRecommend = false
    baseItenData.configCell = ModuleRefer.InventoryModule:GetConfigByUid(self.curUid)
    baseItenData.count = ModuleRefer.InventoryModule:GetAmountByUid(self.curUid)
    baseItenData.onClick = Delegate.GetOrCreate(self, self.OnIconClick)
    self.itemRoot:FeedData(baseItenData)
end

--function BagItemCell:OnRecycle()
--    self.itemRoot.Lua:ClearSprite()
--end

function BagItemCell:OnClose()
    self.itemLogic:ClearSprite()
end

return BagItemCell