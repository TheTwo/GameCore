local BaseUIComponent = require("BaseUIComponent")
---@class BaseTableViewProCell:BaseUIComponent
---@field new fun():BaseTableViewProCell
---@field CSComponent CS.TableViewProCell
---@field Select fun(self:BaseTableViewProCell,param:any)
---@field UnSelect fun(self:BaseTableViewProCell,param:any)
---@field OnRecycle fun(self:BaseTableViewProCell,param:any)
local BaseTableViewProCell = class("BaseTableViewProCell", BaseUIComponent)

---@return CS.TableViewPro
function BaseTableViewProCell:GetTableViewPro()
    return self.CSComponent.TableView;
end

function BaseTableViewProCell:GetCellData()
    return self.CSComponent:GetData();
end

function BaseTableViewProCell:SelectSelf()
    local table = self:GetTableViewPro()
    if table  then
        table:SetToggleSelect(self:GetCellData())
    end
end

---在实例化时调用一次
-- function BaseTableViewProCell:OnCreate(param)
--     --override
-- end

-- function BaseTableViewProCell:OnOpened(param)
--     --override
-- end

--OnShow
--|
--OnFeedData
--|
--OnRecycle
--|
--OnHide

---每次显示时调用，在OnFeedData之前
-- function BaseTableViewProCell:OnShow(data)
--     --override
-- end
---每次显示时调用，在OnShow之后
-- function BaseTableViewProCell:OnFeedData(data)
--     --override
-- end

---每次隐藏时调用，在OnHide之前
-- function BaseTableViewProCell:OnRecycle(param)
--     --override
-- end
---每次隐藏时调用，在OnRecycle之后
-- function BaseTableViewProCell:OnHide(param)
--     --override
-- end

---在窗口关闭时调用一次
-- function BaseTableViewProCell:OnClose(param)
--     --override
-- end

-- function BaseTableViewProCell:Select(param)
--     --override
-- end
-- function BaseTableViewProCell:UnSelect(param)
--     --override
-- end

---@param size CS.UnityEngine.Vector2
function BaseTableViewProCell:SetDynamicCellRectSize(size)
    --override
end

---如果name为空,使用AppendCellCustomName设置的名字,如果不为空,替换AppendCellCustomName设置的名字
---@param name string
function BaseTableViewProCell:RenameCell(name)   
    if self.CSComponent and self.CSComponent.TableView then
        self.CSComponent.TableView:SetupCellCustomName(self.CSComponent,name)   
    end
end

---@param tableView CS.TableViewPro
---@param cellName string
---@return number
function BaseTableViewProCell.GetIndexByName(tableView,cellName)
    if tableView and not string.IsNullOrEmpty(cellName) then                
        return tableView:GetIndexByCustomName(cellName)
    else
        return -1
    end
end


return BaseTableViewProCell