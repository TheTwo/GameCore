---scene: scene_league_popup_troop_defense

local Delegate = require("Delegate")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local BaseUIMediator = require("BaseUIMediator")

---@class DefenceMediator : BaseUIMediator
local DefenceMediator = class("DefenceMediator", BaseUIMediator)

function DefenceMediator:OnCreate()
    self.p_text_title = self:Text("p_text_title", "base_defence_title")
    self.p_text_status = self:Text("p_text_status")

    self.p_text_progress = self:Text("p_text_progress")
    self.p_progress_normal = self:Slider("p_progress_n")
    self.p_progress_damaged = self:Slider("p_progress_damaged")

    ---@type CS.UnityEngine.UI.Text[]
    self.tab_text_n =
    {
        [0] = self:Text("p_txt_left"),
        [1] = self:Text("p_txt_right"),
    }

    ---@type CS.UnityEngine.UI.Text[]
    self.tab_text_s =
    {
        [0] = self:Text("p_txt_left_select"),
        [1] = self:Text("p_txt_right_select"),
    }

    ---@type CS.UnityEngine.GameObject[]
    self.tab_selected =
    {
        [0] = self:GameObject("p_select_left"),
        [1] = self:GameObject("p_select_right"),
    }

    ---@type CS.UnityEngine.UI.Button[]
    self.tab_btns =
    {
        [0] = self:Button("p_btn_left", Delegate.GetOrCreate(self, self.OnLeftClick)),
        [1] = self:Button("p_btn_right", Delegate.GetOrCreate(self, self.OnRightClick)),
    }

    ---@type BaseUIComponent[]
    self.pages =
    {
        [0] = self:LuaObject("p_status_mine"), --WallDefencePage
        [1] = self:LuaObject("p_status_ally"), --WallReinforcePage
    }

    self.p_text_hint = self:Text("p_text_hint", "base_defence_tips")
end

function DefenceMediator:OnOpened(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Battle.MsgPath, Delegate.GetOrCreate(self, self.OnBattleChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.TroopPresets.DefendOrder.MsgPath, Delegate.GetOrCreate(self, self.OnDefendOrderChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Army.MsgPath, Delegate.GetOrCreate(self, self.OnArmyChanged))

    self.tabIndex = -1

    self:SetSelected(0)
    self:UpdateWallState()
    self:UpdateDefendOrder()
    self:UpdateArmy()
end

function DefenceMediator:OnClose()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Battle.MsgPath, Delegate.GetOrCreate(self, self.OnBattleChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.TroopPresets.DefendOrder.MsgPath, Delegate.GetOrCreate(self, self.OnDefendOrderChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Army.MsgPath, Delegate.GetOrCreate(self, self.OnArmyChanged))
end

function DefenceMediator:OnLeftClick()
    self:SetSelected(0)
end

function DefenceMediator:OnRightClick()
    self:SetSelected(1)
end

---@param index number
function DefenceMediator:SetSelected(index)
    if index == self.tabIndex then
        return
    end

    self.tabIndex = index

    self.tab_selected[index]:SetVisible(true)
    self.tab_selected[1 - index]:SetVisible(false)

    self.pages[index]:SetVisible(true)
    self.pages[1 - index]:SetVisible(false)
end

function DefenceMediator:UpdateWallState()
    local castle = ModuleRefer.PlayerModule:GetCastle()
    local hp = castle.Battle.Durability
    local maxHp = castle.Battle.MaxDurability
    local intact = hp >= maxHp

    if intact then
        self.p_text_status.text = I18N.Get("base_defence_wallstate") .. I18N.Get("base_defence_wallstate_intact")
    else
        self.p_text_status.text = I18N.Get("base_defence_wallstate") .. I18N.Get("base_defence_wallstate_worn")
    end

    self.p_progress_normal:SetVisible(intact)
    self.p_progress_damaged:SetVisible(not intact)

    self.p_progress_normal.value = 1
    self.p_progress_damaged.value = math.clamp01(hp / maxHp)

    self.p_text_progress.text = hp .. "/" .. maxHp
end

function DefenceMediator:UpdateDefendOrder()
    local castle = ModuleRefer.PlayerModule:GetCastle()
    local defendCount = castle.TroopPresets.DefendOrder:Count()
    local totalCount = castle.TroopPresets.Presets:Count()
    self.tab_text_n[0].text = I18N.GetWithParams("base_defence_mytroop", defendCount, totalCount)
    self.tab_text_s[0].text = I18N.GetWithParams("base_defence_mytroop", defendCount, totalCount)
end

function DefenceMediator:UpdateArmy()
    local castle = ModuleRefer.PlayerModule:GetCastle()
    local count = castle.Army.PlayerTroopIDs:Count()
    self.tab_text_n[1].text = I18N.GetWithParams("base_defence_allytroop", count)
    self.tab_text_s[1].text = I18N.GetWithParams("base_defence_allytroop", count)
end

---@param data wds.CastleBrief
function DefenceMediator:OnBattleChanged(data)
    if data.ID ~= ModuleRefer.PlayerModule:GetCastle().ID then
        return
    end

    self:UpdateWallState()
end

---@param data wds.CastleBrief
function DefenceMediator:OnDefendOrderChanged(data)
    if data.ID ~= ModuleRefer.PlayerModule:GetCastle().ID then
        return
    end

    self:UpdateDefendOrder()
end

---@param data wds.CastleBrief
function DefenceMediator:OnArmyChanged(data)
    if data.ID ~= ModuleRefer.PlayerModule:GetCastle().ID then
        return
    end

    self:UpdateArmy()
end

return DefenceMediator