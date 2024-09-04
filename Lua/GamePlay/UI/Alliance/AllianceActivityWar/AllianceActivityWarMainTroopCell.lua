local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local HeroConfigCache = require("HeroConfigCache")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceActivityWarMainTroopCellData
---@field troopInfo wds.TroopCreateParam
---@field battleId number
---@field queueIndex number
---@field allowEdit boolean
---@field onClickAdd fun(trans:CS.UnityEngine.Transform)

---@class AllianceActivityWarMainTroopCell:BaseTableViewProCell
---@field new fun():AllianceActivityWarMainTroopCell
---@field super BaseTableViewProCell
local AllianceActivityWarMainTroopCell = class('AllianceActivityWarMainTroopCell', BaseTableViewProCell)

function AllianceActivityWarMainTroopCell:OnCreate(param)
    self._p_empty = self:Button("p_empty", Delegate.GetOrCreate(self, self.OnClickBtnEmpty))
    ---@type HeroInfoItemComponent
    self._child_card_hero_s_ex = self:LuaObject("child_card_hero_s_ex")
    self._p_btn_delect = self:Button("p_btn_delect", Delegate.GetOrCreate(self, self.OnClickBtnRemove))
end

---@param data AllianceActivityWarMainTroopCellData
function AllianceActivityWarMainTroopCell:OnFeedData(data)
    self._cellData = data
    if data.troopInfo then
        self._p_empty:SetVisible(false)
        self._child_card_hero_s_ex:SetVisible(true)
        local hero = data.troopInfo.Heroes[0]
        ---@type HeroInfoData
        local heroInfoData = {}
        heroInfoData.heroData = ModuleRefer.HeroModule:GetHeroByCfgId(hero.ConfigId)
        heroInfoData.hideJobIcon = true
        heroInfoData.hideStrongIcon = true
        heroInfoData.hideStrengthen = true
        heroInfoData.hideStyle = true
        self._child_card_hero_s_ex:FeedData(heroInfoData)
        self._p_btn_delect:SetVisible(data.allowEdit)
    else
        self._p_empty:SetVisible(true)
        self._child_card_hero_s_ex:SetVisible(false)
        self._p_btn_delect:SetVisible(false)
    end
end

function AllianceActivityWarMainTroopCell:OnClickBtnRemove()
    ModuleRefer.AllianceModule:ModifySignUpTroopPresetParameter(self._p_btn_delect.transform, self._cellData.battleId, self._cellData.troopInfo.PresetQueue,true)
end

function AllianceActivityWarMainTroopCell:OnClickBtnEmpty(trans)
    if self._cellData.troopInfo then
        return
    end
    if self._cellData.onClickAdd then
        self._cellData.onClickAdd(self._p_empty.transform)
    end
end

return AllianceActivityWarMainTroopCell