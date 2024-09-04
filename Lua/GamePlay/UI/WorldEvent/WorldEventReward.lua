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

---@class WorldEventReward : BaseTableViewProCell
local WorldEventReward = class('WorldEventReward', BaseTableViewProCell)

function WorldEventReward:OnCreate()
    self.transform = self:RectTransform('')
    -- self.p_img_claim = self:GameObject('p_img_claim')
    -- self.p_icon_reward_n = self:GameObject('p_icon_reward_n')
    -- self.p_icon_reward_open = self:GameObject('p_icon_reward_open')
    self.vfx_particle_common = self:GameObject('vfx_particle_common')
end

function WorldEventReward:OnShow()
    g_Game.EventManager:AddListener(EventConst.WORLD_EVENT_PROGRESS_DOT, Delegate.GetOrCreate(self, self.PlayVfx))
end

function WorldEventReward:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.WORLD_EVENT_PROGRESS_DOT, Delegate.GetOrCreate(self, self.PlayVfx))
end

function WorldEventReward:OnFeedData(param)
    self.progress = param.progress
    self.num = param.num
    self.readyToPlayVfx = self.progress < self.num
    self.transform.localPosition = CS.UnityEngine.Vector3(param.pos.x - self.transform.rect.width / 2, self.transform.localPosition.y, self.transform.localPosition.z)
    self.vfx_particle_common:SetVisible(false)
end

-- 每个点只在刚好达成的时候
function WorldEventReward:PlayVfx(progress)
    if self.readyToPlayVfx and progress >= self.num then
        self.readyToPlayVfx = false
        self.vfx_particle_common:SetVisible(true)
        g_Game.EventManager:RemoveListener(EventConst.WORLD_EVENT_PROGRESS_DOT, Delegate.GetOrCreate(self, self.PlayVfx))
    end
end

return WorldEventReward
