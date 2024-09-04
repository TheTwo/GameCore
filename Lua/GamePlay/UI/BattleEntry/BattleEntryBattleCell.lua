local BaseTableViewProCell = require("BaseTableViewProCell")
local I18N = require("I18N")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local GuideUtils = require("GuideUtils")
local BattleEntryType = require("BattleEntryType")
local FPXSDKBIDefine = require("FPXSDKBIDefine")
local ActivityAllianceBossRegisterStateHelper = require("ActivityAllianceBossRegisterStateHelper")
local ActivityAllianceBossConst = require("ActivityAllianceBossConst")
local ActivityBehemothConst = require("ActivityBehemothConst")
local UIHelper = require("UIHelper")
local ColorConsts = require("ColorConsts")
local TimeFormatter = require("TimeFormatter")
local UIMediatorNames = require("UIMediatorNames")
local SEHudTroopMediatorDefine = require("SEHudTroopMediatorDefine")
local KingdomMapUtils = require("KingdomMapUtils")

---@class BattleEntryBattleCell : BaseTableViewProCell
local BattleEntryBattleCell = class("BattleEntryBattleCell", BaseTableViewProCell)

function BattleEntryBattleCell:ctor()
end

function BattleEntryBattleCell:OnCreate()
    self.imgIconBattle = self:Image("p_icon_battle")
    self.textBattleName = self:Text("p_text_battle_name")
    self.goDesc = self:GameObject("p_desc")
    self.textDesc = self:Text("p_text_desc")
    self.textSubDesc = self:Text("p_text_desc_1")
    self.btn = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self.luaNotifyNode = self:LuaObject("child_reddot_default")
    self.goSubDescBase = self:GameObject("p_base")
end

---@param param BattleEntryConfigCell
function BattleEntryBattleCell:OnFeedData(param)
    self.cellData = param
    self:LoadSprite(self.cellData:Icon(), self.imgIconBattle)
    self.textBattleName.text = I18N.Get(self.cellData:Name())
    self:InitDisplayByType(self.cellData:Type())
end

function BattleEntryBattleCell:OnClick()
    local keyMap = FPXSDKBIDefine.ExtraKey.battle_entry_sub
    local extraData = {}
    extraData[keyMap.entry_id] = self.cellData:Id()
    extraData[keyMap.alliance_id] = (ModuleRefer.AllianceModule:GetMyAllianceData() or {}).ID or 0
    ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.battle_entry_sub, extraData)
    self:OnClickImpl(self.cellData:Type())
end

function BattleEntryBattleCell:OnClickImpl(type)
    if type == BattleEntryType.PvP then
        self:OnClickPvP()
    elseif type == BattleEntryType.BehemothBattle then
        self:OnClickBehemothBattle()
    --- Add new battle entry here
    else
        self:OnClickDefault()
    end
end

function BattleEntryBattleCell:InitDisplayByType(type)
    if type == BattleEntryType.PvP then
        self:InitPvPDisplay()
    elseif type == BattleEntryType.BehemothBattle then
        self:InitBehemothBattleDisplay()
    --- Add new battle entry here
    else
        self:InitDefaultDisplay()
    end
    local notifyNode = ModuleRefer.BattleEntryModule:GetNotifyNodeByType(type)
    if notifyNode then
        self.luaNotifyNode:SetVisible(false)
    else
        self.luaNotifyNode:SetVisible(false)
    end
end

function BattleEntryBattleCell:InitPvPDisplay()
    self.goDesc:SetActive(false)
    self.goSubDescBase:SetActive(false)
end

function BattleEntryBattleCell:InitBehemothBattleDisplay()
    self.goDesc:SetActive(true)
    self.goSubDescBase:SetActive(false)
    self.textDesc.text = I18N.Get("")
    self.textSubDesc.text = I18N.Get("")
    self.textDesc.color = UIHelper.TryParseHtmlString(ColorConsts.white_grey)
    self.textSubDesc.color = UIHelper.TryParseHtmlString(ColorConsts.white_grey)
    local battleCfgId = ActivityBehemothConst.BATTLE_CFG_ID
    local state = ActivityAllianceBossRegisterStateHelper.GetCurUIState(battleCfgId)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        self.textDesc.text = I18N.Get("alliance_behemoth_activity_tips3")
        self.textDesc.color = UIHelper.TryParseHtmlString(ColorConsts.white_grey)
    elseif not ModuleRefer.ActivityBehemothModule:IsDeviceBuilt() then
        self.textDesc.text = I18N.Get("alliance_behemoth_activity_tips4")
        self.textDesc.color = UIHelper.TryParseHtmlString(ColorConsts.white_grey)
    elseif state == ActivityAllianceBossConst.BATTLE_STATE.PREVIEW then
        local tmpId = ActivityAllianceBossRegisterStateHelper.GetPreviewTemplateId(battleCfgId)
        local _, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(tmpId)
        local year, month, day = TimeFormatter.TimeToDateTime(endTime.Seconds)
        self.textDesc.text = I18N.GetWithParams("alliance_behemoth_fighting12", string.format("UTC %d/%2d/%2d", year, month, day))
        self.textDesc.color = UIHelper.TryParseHtmlString(ColorConsts.white_grey)
    elseif state == ActivityAllianceBossConst.BATTLE_STATE.REGISTER then
        self.textDesc.text = I18N.Get("alliance_behemoth_challenge_state3")
        self.textDesc.color = UIHelper.TryParseHtmlString(ColorConsts.army_green)
        if ActivityAllianceBossRegisterStateHelper.IsRegisteredTroop(battleCfgId) then
            self.goSubDescBase:SetActive(true)
            self.textSubDesc.text = I18N.Get("alliance_behemoth_challenge_state13")
            self.textSubDesc.color = UIHelper.TryParseHtmlString(ColorConsts.white_grey)
        end
    elseif state == ActivityAllianceBossConst.BATTLE_STATE.WAITING then
        self.textDesc.text = I18N.Get("alliance_behemoth_challenge_state4")
        self.textDesc.color = UIHelper.TryParseHtmlString(ColorConsts.army_green)
        if ActivityAllianceBossRegisterStateHelper.IsRegisteredTroop(battleCfgId) then
            self.goSubDescBase:SetActive(true)
            self.textSubDesc.text = I18N.Get("alliance_behemoth_challenge_state13")
            self.textSubDesc.color = UIHelper.TryParseHtmlString(ColorConsts.white_grey)
        else
            self.goSubDescBase:SetActive(true)
            self.textSubDesc.text = I18N.Get("alliance_behemoth_challenge_state7")
            self.textSubDesc.color = UIHelper.TryParseHtmlString(ColorConsts.army_red)
        end
    elseif state == ActivityAllianceBossConst.BATTLE_STATE.BATTLE then
        self.textDesc.text = I18N.Get("alliance_behemoth_challenge_state5")
        self.textDesc.color = UIHelper.TryParseHtmlString(ColorConsts.army_green)
        if ActivityAllianceBossRegisterStateHelper.IsRegisteredTroop(battleCfgId) then
            self.goSubDescBase:SetActive(true)
            self.textSubDesc.text = I18N.Get("alliance_behemoth_challenge_state13")
            self.textSubDesc.color = UIHelper.TryParseHtmlString(ColorConsts.white_grey)
        else
            self.goSubDescBase:SetActive(true)
            self.textSubDesc.text = I18N.Get("alliance_behemoth_challenge_state7")
            self.textSubDesc.color = UIHelper.TryParseHtmlString(ColorConsts.white_grey)
        end
    else
        self.textDesc.text = I18N.Get("alliance_behemoth_challenge_state8")
        self.textDesc.color = UIHelper.TryParseHtmlString(ColorConsts.white_grey)
    end
end

function BattleEntryBattleCell:InitDefaultDisplay()
    self.goDesc:SetActive(false)
end

function BattleEntryBattleCell:OnClickPvP()
    if KingdomMapUtils.IsMapState() then
        g_Game.StateMachine:WriteBlackboard("SE_FROM_TYPE", SEHudTroopMediatorDefine.FromType.World, true)
        local myCityCoord = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
        local x = math.floor(myCityCoord.X)
        local y = math.floor(myCityCoord.Y)
        g_Game.StateMachine:WriteBlackboard("SE_FROM_X", x, true)
        g_Game.StateMachine:WriteBlackboard("SE_FROM_Y", y, true)
    else
        g_Game.StateMachine:WriteBlackboard("SE_FROM_TYPE", SEHudTroopMediatorDefine.FromType.City, true)
        g_Game.StateMachine:WriteBlackboard("SE_USE_DEFAULT_POS", true, true)
    end
    
    -- g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPMainMediator)
    self:OnClickDefault()
end

function BattleEntryBattleCell:OnClickBehemothBattle()
    ModuleRefer.ActivityBehemothModule:GotoBehemothActivity()
end

function BattleEntryBattleCell:OnClickDefault()
    local guideId = self.cellData:Goto()
    GuideUtils.GotoByGuide(guideId)
end

return BattleEntryBattleCell