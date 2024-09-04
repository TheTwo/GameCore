local I18N = require("I18N")

---@class AllianceBehemothInfoComponentOperationProvider
---@field new fun():AllianceBehemothInfoComponentOperationProvider
local AllianceBehemothInfoComponentOperationProvider = class('AllianceBehemothInfoComponentOperationProvider')

function AllianceBehemothInfoComponentOperationProvider:ctor()
    ---@protected
    ---@type AllianceBehemoth
    self._currentBehemoth = nil
end

function AllianceBehemothInfoComponentOperationProvider:SetCurrentContext(currentBehemoth)
    self._currentBehemoth = currentBehemoth
end

---@param host AllianceBehemothInfoComponent
function AllianceBehemothInfoComponentOperationProvider:SetHost(host)
    self._host = host
end

function AllianceBehemothInfoComponentOperationProvider:ShowChallenge()
    return false
end

function AllianceBehemothInfoComponentOperationProvider:ChallengeText()
    return I18N.Get("alliance_behemoth_button_challenge")
end

function AllianceBehemothInfoComponentOperationProvider:OnClickChallenge()
    
end

function AllianceBehemothInfoComponentOperationProvider:ShowChallengeR5()
    return false
end

function AllianceBehemothInfoComponentOperationProvider:ChallengeTextR5()
    return I18N.Get("alliance_behemoth_button_challenge")
end

function AllianceBehemothInfoComponentOperationProvider:OnClickChallengeR5()
    
end

function AllianceBehemothInfoComponentOperationProvider:ShowCall()
    return false
end

function AllianceBehemothInfoComponentOperationProvider:CallText()
    return I18N.Get("alliance_behemoth_button_summon")
end

function AllianceBehemothInfoComponentOperationProvider:IsCallDisabled()
    return false
end

function AllianceBehemothInfoComponentOperationProvider:OnClickCall()
    
end

function AllianceBehemothInfoComponentOperationProvider:ShowChange()
    return false
end

function AllianceBehemothInfoComponentOperationProvider:ChangeText()
    return I18N.Get("alliance_behemoth_button_attend")
end

---@param clickRectTrans CS.UnityEngine.RectTransform
function AllianceBehemothInfoComponentOperationProvider:OnClickChange(clickRectTrans)
    
end

function AllianceBehemothInfoComponentOperationProvider:ShowReward()
    
end

---@param clickRectTrans CS.UnityEngine.RectTransform
function AllianceBehemothInfoComponentOperationProvider:OnClickReward(clickRectTrans)
    
end

function AllianceBehemothInfoComponentOperationProvider:ShowDetailTip()
    return false
end

---@param clickRectTrans CS.UnityEngine.RectTransform
function AllianceBehemothInfoComponentOperationProvider:OnClickDetailTip(clickRectTrans)
    
end

function AllianceBehemothInfoComponentOperationProvider:ShowNowControl()
    return false
end

function AllianceBehemothInfoComponentOperationProvider:ShowNotHave()
    return not self._currentBehemoth or self._currentBehemoth:IsFake()
end

function AllianceBehemothInfoComponentOperationProvider:ShowR5Text()
    return false
end

function AllianceBehemothInfoComponentOperationProvider:R5Text()
    return string.Empty
end

function AllianceBehemothInfoComponentOperationProvider:ShowCivilianText()
    return false
end

function AllianceBehemothInfoComponentOperationProvider:CivilianText()
    return string.Empty
end

function AllianceBehemothInfoComponentOperationProvider:NeedTickNowControl()
    return false
end

---@return boolean,string
function AllianceBehemothInfoComponentOperationProvider:TickNowControl(dt)
    return false,string.Empty
end

function AllianceBehemothInfoComponentOperationProvider:ShowInChallengeText()
    return false
end

---@return boolean,string
function AllianceBehemothInfoComponentOperationProvider:TickInChallengeText(dt)
    return false,string.Empty
end


function AllianceBehemothInfoComponentOperationProvider:OnShow()
    
end

function AllianceBehemothInfoComponentOperationProvider:OnHide()
    
end

return AllianceBehemothInfoComponentOperationProvider