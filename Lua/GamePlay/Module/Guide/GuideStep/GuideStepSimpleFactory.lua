local BaseGuideStep = require('BaseGuideStep')
local ConfigRefer = require('ConfigRefer')
local GuideType = require('GuideType')
local AutoClickGuideStep = require('AutoClickGuideStep')
local CloseAllWindowGuideStep = require('CloseAllWindowGuideStep')
local DialogGuideStep = require('DialogGuideStep')
local FocusSceneCameraAndFinGuideStep = require('FocusSceneCameraAndFinGuideStep')
local FocusSceneCameraAndOpenGuideStep = require('FocusSceneCameraAndOpenGuideStep')
local FocusTableViewProCellGuideStep = require('FocusTableViewProCellGuideStep')
local GotoCityGuideStep = require('GotoCityGuideStep')
local GotoWorldGuideStep = require('GotoWorldGuideStep')
local LvUpFurnitureGuideStep = require('LvUpFurnitureGuideStep')
local OpenWindowGuideStep = require('OpenWindowGuideStep')
local PauseCitizenGuideStep = require('PauseCitizenGuideStep')
local ResumeCitizenGuideStep = require('ResumeCitizenGuideStep')
local SendMsgGuideStep = require('SendMsgGuideStep')
local UIClickGuideStep = require('UIClickGuideStep')
local WaitGuideStep = require('WaitGuideStep')
---@class GuideStepSimpleFactory
local GuideStepSimpleFactory = class('GuideStepSimpleFactory')

---@param id number
---@return BaseGuideStep
function GuideStepSimpleFactory.CreateGuideStep(id)
    local type = ConfigRefer.Guide:Find(id):Type()
    if type == GuideType.Dialog then
        return DialogGuideStep.new(id)
    elseif type == GuideType.UIClick then
        return UIClickGuideStep.new(id)
    elseif type == GuideType.Wait then
        return WaitGuideStep.new(id)
    elseif type == GuideType.Drag then
        return FocusSceneCameraAndOpenGuideStep.new(id)
    elseif type == GuideType.Goto then
        return FocusSceneCameraAndOpenGuideStep.new(id)
    elseif type == GuideType.GroundClick then
        return FocusSceneCameraAndOpenGuideStep.new(id)
    elseif type == GuideType.CamFocus then
        return FocusSceneCameraAndFinGuideStep.new(id)
    elseif type == GuideType.OpenWindow then
        return OpenWindowGuideStep.new(id)
    elseif type == GuideType.OpenWindowAndWait then
        return OpenWindowGuideStep.new(id)
    elseif type == GuideType.AutoClick then
        return AutoClickGuideStep.new(id)
    elseif type == GuideType.SendMsg then
        return SendMsgGuideStep.new(id)
    elseif type == GuideType.CloseAllWindow then
        return CloseAllWindowGuideStep.new(id)
    elseif type == GuideType.GotoWorld then
        return GotoWorldGuideStep.new(id)
    elseif type == GuideType.GotoCity then
        return GotoCityGuideStep.new(id)
    elseif type == GuideType.FocusTableViewProCell then
        return FocusTableViewProCellGuideStep.new(id)
    elseif type == GuideType.PauseCitizen then
        return PauseCitizenGuideStep.new(id)
    elseif type == GuideType.ResumeCitizen then
        return ResumeCitizenGuideStep.new(id)
    elseif type == GuideType.LvUpFurniture then
        return LvUpFurnitureGuideStep.new(id)
    end
    return BaseGuideStep.new(id)
end

return GuideStepSimpleFactory