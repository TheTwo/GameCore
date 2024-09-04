local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local LandformTaskModule = require("LandformTaskModule")
local NotificationType = require("NotificationType")

---@class LandformSelectCellData
---@field landformConfigID number
---@field isLocked boolean
---@field clickCallback fun(number)

---@class LandformSelectCell : BaseTableViewProCell
---@field data LandformSelectCellData
local LandformSelectCell = class("LandformSelectCell", BaseTableViewProCell)

function LandformSelectCell:OnCreate(param)
    self.statusRecord = self:StatusRecordParent("")
    self.p_icon_landform = self:Image("p_icon_landform")
    self.p_img_select = self:GameObject("p_img_select")
    self.p_btn_landform = self:Button("p_btn_landform", Delegate.GetOrCreate(self, self.OnIconClicked))
    ---@type NotificationNode
    self.child_reddot_default = self:LuaObject("child_reddot_default")
end

---@param data LandformSelectCellData
function LandformSelectCell:OnFeedData(data)
    self.data = data
    local config = ConfigRefer.Land:Find(data.landformConfigID)
    g_Game.SpriteManager:LoadSpriteAsync(config:IconSpace(), self.p_icon_landform)
    self.statusRecord:SetState(data.isLocked and 1 or 0)

    local landformConfig = ConfigRefer.Land:Find(self.data.landformConfigID)
    local layer = landformConfig:LayerNum()
    local currentNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(LandformTaskModule.NotifyCellUniqueName .. layer, NotificationType.LANDFORM_TASK_MAIN)
    ModuleRefer.NotificationModule:AttachToGameObject(currentNode, self.child_reddot_default.go, self.child_reddot_default.redDot)
end

function LandformSelectCell:Select(param)
    self.p_img_select:SetVisible(true)
end

function LandformSelectCell:UnSelect(param)
    self.p_img_select:SetVisible(false)
end

function LandformSelectCell:OnIconClicked()
    if self.data.clickCallback then
        self.data.clickCallback(self.data.landformConfigID)
    end
    self:SelectSelf()
end

return LandformSelectCell