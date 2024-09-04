local BaseUIComponent = require ('BaseUIComponent')

---@class ChatV2LoadingComp:BaseUIComponent
local ChatV2LoadingComp = class('ChatV2LoadingComp', BaseUIComponent)

function ChatV2LoadingComp:OnCreate()
    self._itemScript = self:BindComponent("", typeof(CS.SuperScrollView.LoopListViewItem2))
    self._icon_loading = self:GameObject("icon_loading")
    self._vx_trigger_loop2 = self:GameObject("vx_trigger_loop2")
end

---@param uimediator ChatV2UIMediator
function ChatV2LoadingComp:OnFeedData(uimediator)
    if uimediator:IsLoadingWaitRelease() or uimediator:IsLoaded() then
        self._icon_loading:SetActive(true)
        self._vx_trigger_loop2:SetActive(false)
        self._itemScript.CachedRectTransform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Vertical, 40)
    elseif uimediator:IsLoading() then
        self._icon_loading:SetActive(true)
        self._vx_trigger_loop2:SetActive(true)
        self._itemScript.CachedRectTransform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Vertical, 40)
    else
        self._icon_loading:SetActive(false)
        self._vx_trigger_loop2:SetActive(false)
        self._itemScript.CachedRectTransform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Vertical, 0)
    end
end

return ChatV2LoadingComp