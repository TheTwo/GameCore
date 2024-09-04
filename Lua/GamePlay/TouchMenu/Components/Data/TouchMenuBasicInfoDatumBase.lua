---@class TouchMenuBasicInfoDatumBase 抽象类，不要直接使用
---@field new fun():TouchMenuBasicInfoDatumBase
local TouchMenuBasicInfoDatumBase = class("TouchMenuBasicInfoDatumBase")

function TouchMenuBasicInfoDatumBase:GetCompName()
    return string.Empty
end

function TouchMenuBasicInfoDatumBase:ShowMarkBtn()
    return self.markProvider and self.markProvider:ShowMarkBtn() or false
end

---@return number
function TouchMenuBasicInfoDatumBase:GetMarkState()
    return self.markProvider and self.markProvider:GetMarkState() or 0
end

---@param btnTrans CS.UnityEngine.RectTransform
function TouchMenuBasicInfoDatumBase:OnClickBtnMark(btnTrans)
    if self.markProvider then
        return self.markProvider:OnClickBtnMark(btnTrans)
    end
    return false
end

---@param provider TouchMenuBasicInfoDatumMarkProvider
function TouchMenuBasicInfoDatumBase:SetMarkProvider(provider)
    self.markProvider = provider
    return self
end

function TouchMenuBasicInfoDatumBase:ShowReleaseBtn()
    return self.clickRelease ~= nil
end

---@param clickFunc fun(btnTrans:CS.UnityEngine.RectTransform):boolean
function TouchMenuBasicInfoDatumBase:SetClickBtnRelease(clickFunc)
    self.clickRelease = clickFunc
    return self
end

---@param btnTrans CS.UnityEngine.RectTransform
function TouchMenuBasicInfoDatumBase:OnClickReleaseBtn(btnTrans)
    if self.clickRelease then
        return self.clickRelease(btnTrans)
    end
    return false
end

function TouchMenuBasicInfoDatumBase:ShowDefuseBtn()
    return self.clickDefuse ~= nil
end

---@param clickFunc fun(btnTrans:CS.UnityEngine.RectTransform):boolean
function TouchMenuBasicInfoDatumBase:SetClickBtnDefuse(clickFunc)
    self.clickDefuse = clickFunc
    return self
end

---@param btnTrans CS.UnityEngine.RectTransform
function TouchMenuBasicInfoDatumBase:OnClickDefuseBtn(btnTrans)
    if self.clickDefuse then
        return self.clickDefuse(btnTrans)
    end
    return false
end

function TouchMenuBasicInfoDatumBase:ShowDeleteBtn()
    return self.clickDelete ~= nil
end

---@param clickDelete fun(btnTrans:CS.UnityEngine.RectTransform):boolean
function TouchMenuBasicInfoDatumBase:SetClickBtnDelete(clickDelete)
    self.clickDelete = clickDelete
    return self
end

---@param btnTrans CS.UnityEngine.RectTransform
function TouchMenuBasicInfoDatumBase:OnClickDeleteBtn(btnTrans)
    if self.clickDelete then
        return self.clickDelete(btnTrans)
    end
    return false
end

function TouchMenuBasicInfoDatumBase:ShowPlayerInfoBtn()
    return self.clickPlayerInfo ~= nil
end

---@param clickPlayerInfo fun(btnTrans:CS.UnityEngine.RectTransform):boolean
function TouchMenuBasicInfoDatumBase:SetClickBtnPlayerInfo(clickPlayerInfo)
    self.clickPlayerInfo = clickPlayerInfo
    return self
end

---@param btnTrans CS.UnityEngine.RectTransform
function TouchMenuBasicInfoDatumBase:OnClickPlayerInfoBtn(btnTrans)
    if self.clickPlayerInfo then
        return self.clickPlayerInfo(btnTrans)
    end
    return false
end

return TouchMenuBasicInfoDatumBase