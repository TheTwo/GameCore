local BaseTableViewProCell = require("BaseTableViewProCell")
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local DBEntityPath = require("DBEntityPath")
local TimeFormatter = require("TimeFormatter")
local GuideUtils = require("GuideUtils")
local LayoutRebuilder = CS.UnityEngine.UI.LayoutRebuilder
local StageDescType = require('StageDescType')
local ColorUtil = require('ColorUtil')
local ColorConsts = require('ColorConsts')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local Delegate = require('Delegate')

---@class WorldEventEventComponent : BaseTableViewProCell
local WorldEventEventComponent = class('WorldEventEventComponent', BaseTableViewProCell)
local vfxType = {NewStage = 1, Complete = 2}

function WorldEventEventComponent:OnCreate()
    self.p_text_world_events = self:Text('p_text_world_events')
    self.p_icon_finish = self:GameObject('p_icon_finish')
    self.p_icon_unfinished = self:GameObject('p_icon_unfinished')
    self.trigger_item = self:BindComponent("trigger_item", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
    self.p_item = self:Button('p_item', Delegate.GetOrCreate(self, self.OnBtnClick))
end

function WorldEventEventComponent:OnShow()
end

function WorldEventEventComponent:OnHide()
end

function WorldEventEventComponent:OnFeedData(param)
    self.spawnUnits = param.spawnUnits
    self.expeditionId = param.expeditionId

    local text
    local colorText

    if param.descType == StageDescType.TextOnly then
        text = I18N.Get(param.desc)
    else
        text = I18N.GetWithParams(param.desc, "<b>" .. param.curValue .. "</b>", "<b>" .. param.maxValue .. "</b>")
    end

    local isComplete = param.maxValue > 0 and param.curValue >= param.maxValue
    if isComplete then
        self.vfxType = vfxType.Complete
        colorText = ColorConsts.light_grey
        text = string.format("<color=%s>%s</color>/", colorText, text)
        self.p_icon_finish:SetVisible(true)
        self.p_icon_unfinished:SetVisible(false)
    else
        colorText = ColorConsts.white
        self.p_icon_finish:SetVisible(false)
        self.p_icon_unfinished:SetVisible(true)
    end

    self.p_text_world_events.text = text
    self:PlayVfx()
end

function WorldEventEventComponent:PlayVfx()
    if self.vfxType == vfxType.NewStage then
        self.trigger_item:PlayAll(FpAnimTriggerEvent.Custom1)

    elseif self.vfxType == vfxType.Complete then
        self.trigger_item:PlayAll(FpAnimTriggerEvent.Custom2)

    end
end

function WorldEventEventComponent:OnBtnClick()
    for k, v in pairs(self.spawnUnits) do
        local isFind = ModuleRefer.WorldEventModule:GotoSpawernUnit(v.spawnID, v.spawnType, self.expeditionId)
        if isFind then
            return
        end
    end
end

return WorldEventEventComponent
