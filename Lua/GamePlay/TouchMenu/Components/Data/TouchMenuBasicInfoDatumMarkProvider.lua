---@class TouchMenuBasicInfoDatumMarkProvider
---@field new fun():TouchMenuBasicInfoDatumMarkProvider
local TouchMenuBasicInfoDatumMarkProvider = class('TouchMenuBasicInfoDatumMarkProvider')

function TouchMenuBasicInfoDatumMarkProvider:ctor()
end

function TouchMenuBasicInfoDatumMarkProvider:ShowMarkBtn()
    return false
end

function TouchMenuBasicInfoDatumMarkProvider:GetMarkState()
    return 0
end

function TouchMenuBasicInfoDatumMarkProvider:OnClickBtnMark(btnTrans)
    g_Logger.Log("OnClickBtnMark")
end

return TouchMenuBasicInfoDatumMarkProvider