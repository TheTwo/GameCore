local BaseGuideStep = require("BaseGuideStep")
local GuideType = require("GuideType")
local QueuedTask = require("QueuedTask")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local KingdomMapUtils = require("KingdomMapUtils")
---@class OpenWindowGuideStep : BaseGuideStep
local OpenWindowGuideStep = class("OpenWindowGuideStep", BaseGuideStep)

function OpenWindowGuideStep:ExecuteImpl()
    g_Logger.LogChannel('GuideModule','ExeGuideStep_OpenWindow: %d)', self.id)
    self:OpenUIMediator(self.cfg:Type() == GuideType.OpenWindowAndWait)
end

function OpenWindowGuideStep:OpenUIMediator(wait)
    local uiName = self.cfg:StringParams(1)
    local uiParam
    if self.cfg:StringParamsLength() > 1 then
        uiParam = self.cfg:StringParams(2)
    end
    if string.IsNullOrEmpty(uiName) then
        return false
    end
    if not ModuleRefer.NewFunctionUnlockModule:CheckUIMediatorIsOpen(uiName) then
        return false
    end
    if wait then
        --当窗口关闭时，才继续执行下一步
        if not g_Game.UIManager:IsOpenedByName(uiName) then
            self:InternalOpenUIMediator(uiName, uiParam)
        end
        local queuedTask = QueuedTask.new()
        queuedTask:WaitEvent(EventConst.ON_UIMEDIATOR_CLOSEED, nil, function(param)
            return param == uiName
        end):DoAction(function()
                self:End()
            end
        ):Start()
    else
        --窗口成功打开后，就继续执行下一步
        if not g_Game.UIManager:IsOpenedByName(uiName) then
            self:InternalOpenUIMediator(uiName,uiParam,function()
                self:End()
            end)
        else
            self:End()
        end
    end
end
function OpenWindowGuideStep:InternalOpenUIMediator(uiName, uiParam, func)

    if uiName == UIMediatorNames.RadarMediator then
        local isInCity = g_Game.SceneManager.current:IsInCity()
        local basicCamera = KingdomMapUtils.GetBasicCamera()
        basicCamera.ignoreLimit = true
        ModuleRefer.RadarModule:SetRadarState(true)
        local param = {isInCity = isInCity, stack = basicCamera:RecordCurrentCameraStatus()}
        g_Game.UIManager:Open(UIMediatorNames.RadarMediator, param, func)
        return
    end

    if uiName == UIMediatorNames.AllianceWarMediator or
    uiName == UIMediatorNames.AllianceTechResearchMediator then
        local join = ModuleRefer.AllianceModule:IsInAlliance()
        if not join then
            g_Game.UIManager:Open(UIMediatorNames.AllianceInitialMediator, nil, func)
            return
        end
    end

    g_Game.UIManager:Open(uiName, uiParam, func)
end

return OpenWindowGuideStep