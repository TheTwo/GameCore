local BaseGuideStep = require("BaseGuideStep")
---@class FocusTableViewProCellGuideStep : BaseGuideStep
local FocusTableViewProCellGuideStep = class("FocusTableViewProCellGuideStep", BaseGuideStep)

function FocusTableViewProCellGuideStep:ExecuteImpl()
    g_Logger.LogChannel('GuideModule','ExeGuideStep_FocusTableViewProCell: %d)', self.id)
    local zoneCfg = self.cfg:Zone()
    local winName = zoneCfg:UIName()
    local ctrlName = zoneCfg:CtrlName()
    local ctrlIndex = zoneCfg:CtrlIndex()
    local uiTrans = g_Game.UIManager:FindUICtrl(winName, ctrlName, ctrlIndex, g_Game.UIManager.UIMediatorType.Popup)
    if not uiTrans then
        g_Logger.LogChannel('GuideModule','查找TableViewPro控件失败: name:%s index:%d',ctrlName, ctrlIndex)
        self:Stop()
        return
    end
    local tableViewPro = uiTrans.transform:GetComponent(typeof(CS.TableViewPro))
    if tableViewPro then
        local paramLength = self.cfg:StringParamsLength()
        local strParam
        if paramLength > 0 then
            strParam = self.cfg:StringParams(1)
        end
        if strParam then
            local index = tableViewPro:GetIndexByCustomName(strParam)
            if index > -1 then
                tableViewPro:SetDataVisable(index, CS.TableViewPro.MoveSpeed.Fast)
            end
        end
    end
    self:End()
end

return FocusTableViewProCellGuideStep