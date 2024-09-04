local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")
local UIHelper = require("UIHelper")
local EventConst = require("EventConst")
---@class ActivityAllianceBossRegisterRewardPreviewBehemothCell : BaseTableViewProCell
local ActivityAllianceBossRegisterRewardPreviewBehemothCell = class("ActivityAllianceBossRegisterRewardPreviewBehemothCell", BaseTableViewProCell)

---@class ActivityAllianceBossRegisterRewardPreviewBehemothCellParam
---@field isSelect boolean
---@field kMonsterCfg KmonsterDataConfigCell
---@field isOwn boolean

function ActivityAllianceBossRegisterRewardPreviewBehemothCell:OnCreate()
    self.btnHeadIcon = self:Button("p_btn_pet", Delegate.GetOrCreate(self, self.OnBtnHeadIconClick))
    self.imgHeadIcon = self:Image("p_pet_head")
    self.goSelect = self:GameObject("p_base_select")
    self.goRoot = self:GameObject("")
end

---@param param ActivityAllianceBossRegisterRewardPreviewBehemothCellParam
function ActivityAllianceBossRegisterRewardPreviewBehemothCell:OnFeedData(param)
    self.isSelect = param.isSelect
    self.kMonsterCfg = param.kMonsterCfg
    self.isOwn = param.isOwn
    local _, icon = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(self.kMonsterCfg)
    g_Game.SpriteManager:LoadSprite(icon, self.imgHeadIcon)
    if self.isSelect then
        self:SelectSelf()
    end
    if not self.isOwn then
        UIHelper.SetGray(self.goRoot, true)
    end
end

function ActivityAllianceBossRegisterRewardPreviewBehemothCell:Select()
    self.isSelect = true
    self.goSelect:SetActive(true)
    g_Game.EventManager:TriggerEvent(EventConst.ON_ACTIVITY_ALLIANCE_BOSS_REGISTER_BEHEMOTH_CELL_SELECT, self.kMonsterCfg)
end

function ActivityAllianceBossRegisterRewardPreviewBehemothCell:UnSelect()
    self.isSelect = false
    self.goSelect:SetActive(false)
end

function ActivityAllianceBossRegisterRewardPreviewBehemothCell:OnBtnHeadIconClick()
    self:SelectSelf()
end

return ActivityAllianceBossRegisterRewardPreviewBehemothCell