local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local HeroConfigCache = require("HeroConfigCache")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceActivityWarTroopListPopupCell:BaseTableViewProCell
---@field new fun():AllianceActivityWarTroopListPopupCell
---@field super BaseTableViewProCell
local AllianceActivityWarTroopListPopupCell = class('AllianceActivityWarTroopListPopupCell', BaseTableViewProCell)

function AllianceActivityWarTroopListPopupCell:OnCreate(param)
    self._selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnClickSelf))
    ---@type PlayerInfoComponent
    self._child_ui_head_player = self:LuaObject("child_ui_head_player")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_power = self:Text("p_text_power")
    self._p_btn_delect = self:Button("p_btn_delect", Delegate.GetOrCreate(self, self.OnClickKick))
    self._p_content = self:StatusRecordParent("p_content")
    ---@type HeroInfoItemComponent[]
    self._heroHeads = {}
    for i = 1, 4 do
        self._heroHeads[i] = self:LuaObject(string.format("child_card_hero_s_%s", i))
    end
    ---@type CS.UnityEngine.GameObject[]
    self._head_empty = {}
    for i = 1, 4 do
        self._head_empty[i] = self:GameObject(string.format("p_empty_%s", i))
    end
end

---@param data AllianceActivityWarTroopListPopupCellData
function AllianceActivityWarTroopListPopupCell.GetTroopPower(data)
    local ret = 0
    ---@type wds.TroopCreateParam[][]
    local cells = data and data.__childCellsData
    if cells then
        for _, v in pairs(cells) do
            for _, heroTroop in pairs(v) do
                ret = ret + heroTroop.Power
            end
        end
    end
    return math.floor(ret + 0.5)
end

---@param data AllianceActivityWarTroopListPopupCellData
function AllianceActivityWarTroopListPopupCell:OnFeedData(data)
    self._cellData = data
    self._p_btn_delect:SetVisible(self._cellData._isSelf or self._cellData._adminMode)
    local troops = data._memberData.Troops or {}
    for i = 1, 4 do
        local troop = troops[i]
        if not troop then
            self._heroHeads[i]:SetVisible(false)
            self._head_empty[i]:SetVisible(true)
        else
            self._heroHeads[i]:SetVisible(true)
            self._head_empty[i]:SetVisible(false)
            local heroesConfigCell = ConfigRefer.Heroes:Find(troop.Heroes[0].ConfigId)
            ---@type HeroInfoData
            local heroData = {}
            heroData.heroData = HeroConfigCache.New(heroesConfigCell)
            self._heroHeads[i]:FeedData(heroData)
        end
    end
    local memberInfo = data._memberInfo
    if memberInfo then
        self._p_text_name.text = memberInfo.Name
        self._p_text_power.text = tostring(AllianceActivityWarTroopListPopupCell.GetTroopPower(data))
        self._child_ui_head_player:FeedData(memberInfo.PortraitInfo)
    else
        self._p_text_name.text = string.Empty
        self._p_text_power.text = string.Empty
    end
    self._p_content:SetState(data._isSelf and 1 or 0)
end

function AllianceActivityWarTroopListPopupCell:OnClickSelf()
    local tableView = self:GetTableViewPro()
    self._cellData:SetExpanded(not self._cellData:IsExpanded())
    tableView:UpdateData(self._cellData)
end

function AllianceActivityWarTroopListPopupCell:OnClickKick()
    if self._cellData._isSelf then
        ModuleRefer.AllianceModule:CancelSignUpAllianceActivityBattle(self._p_btn_delect.transform, self._cellData._battleId)
        return
    end
    if self._cellData._adminMode then
        ModuleRefer.AllianceModule:KickAllianceActivityBattleMember(self._p_btn_delect.transform, self._cellData._battleId, self._cellData._memberData.PlayerId)
        return
    end
end

return AllianceActivityWarTroopListPopupCell