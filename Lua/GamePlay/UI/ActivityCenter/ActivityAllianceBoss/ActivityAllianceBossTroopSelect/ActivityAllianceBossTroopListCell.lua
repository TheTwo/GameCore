local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local HeroConfigCache = require("HeroConfigCache")
local ModuleRefer = require("ModuleRefer")
local ColorConsts = require("ColorConsts")
local UIHelper = require("UIHelper")
local ActivityAllianceBossConst = require("ActivityAllianceBossConst")
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
---@class ActivityAllianceBossTroopListCell : BaseTableViewProCell
local ActivityAllianceBossTroopListCell = class("ActivityAllianceBossTroopListCell", BaseTableViewProCell)

---@class ActivityAllianceBossTroopListCellParam
---@field memberInfo wds.AllianceBattleMemberInfo
---@field memberPlayerInfo wds.AllianceMember
---@field battleId number
---@field uiState number

function ActivityAllianceBossTroopListCell:ctor()
    ---@type boolean
    self.isMyTroop = nil
    ---@type CS.DragonReborn.UI.BaseComponent[]
    self.heroSlots = nil
end

function ActivityAllianceBossTroopListCell:OnCreate()
    self.luaPlayerHead = self:LuaObject('child_ui_head_player')
    self.textPlayerName = self:Text('p_text_name')
    self.textPower = self:Text('p_text_power')
    self.luaHeroHead = self:LuaObject('child_card_hero_s_1')
    self.btnDelete = self:Button('p_btn_delect', Delegate.GetOrCreate(self, self.OnBtnDeleteClick))
    ---@see ActivityAllianceBossRegisterTroopHeroSlot
    self.luaHeroSlotsTemplate = self:LuaBaseComponent('p_slot')
end

---@param param ActivityAllianceBossTroopListCellParam
function ActivityAllianceBossTroopListCell:OnFeedData(param)
    self.troop = param.memberInfo.Troops[1]
    self.memberInfo = param.memberInfo
    self.battleId = param.battleId
    local troop = self.troop
    local heroesConfigCell = ConfigRefer.Heroes:Find(troop.Heroes[0].ConfigId)
    ---@type HeroInfoData
    local heroData = {}
    heroData.heroData = HeroConfigCache.New(heroesConfigCell)
    self.luaHeroHead:FeedData(heroData)
    local heroPower = 0
    for _, v in pairs(troop.Heroes) do
        heroPower = heroPower + v.Power
    end
    self.textPower.text = troop.Power + heroPower
    self.isMyTroop = ModuleRefer.PlayerModule.playerId == param.memberInfo.PlayerId
    if self.isMyTroop then
        self.textPlayerName.color = UIHelper.TryParseHtmlString(ColorConsts.quality_green)
    end
    self.textPlayerName.text = param.memberPlayerInfo.Name
    self.luaPlayerHead:FeedData(param.memberPlayerInfo.PortraitInfo)
    local canEdit = param.uiState == ActivityAllianceBossConst.BATTLE_STATE.REGISTER
    self.btnDelete.gameObject:SetActive(self.isMyTroop and canEdit)

    self:InitHeroSlots()
end

function ActivityAllianceBossTroopListCell:OnRecycle()
    self:RecycleHeroSlots()
end

function ActivityAllianceBossTroopListCell:InitHeroSlots()
    self.heroSlots = {}
    self.luaHeroSlotsTemplate:SetVisible(true)
    for _, v in pairs(self.troop.Heroes) do
        local slot = UIHelper.DuplicateUIComponent(self.luaHeroSlotsTemplate)
        slot:FeedData(v)
        table.insert(self.heroSlots, slot)
    end
    self.luaHeroSlotsTemplate:SetVisible(false)
end

function ActivityAllianceBossTroopListCell:RecycleHeroSlots()
    for _, v in pairs(self.heroSlots) do
        UIHelper.DeleteUIComponent(v)
    end
    self.heroSlots = {}
end

function ActivityAllianceBossTroopListCell:OnBtnDeleteClick()
    if self.isMyTroop then
        ModuleRefer.AllianceModule:ModifySignUpTroopPresetParameter(self.btnDelete.transform,
        self.battleId, self.troop.PresetQueue, true)
    else
        ---@type CommonConfirmPopupMediatorParameter
        local data = {}
        data.title = I18N.Get("*踢出玩家")
        data.content = I18N.Get("alliance_challengeactivity_pop_kick")
        data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
        data.onConfirm = function (context)
            ModuleRefer.AllianceModule:KickAllianceActivityBattleMember(self.btnDelete.transform,
            self.battleId, self.memberInfo.PlayerId)
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, data)
    end
end

return ActivityAllianceBossTroopListCell