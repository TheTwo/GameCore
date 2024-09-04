local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class GveTroopPrepareTableCell : BaseTableViewProCell
local GveTroopPrepareTableCell = class('GveTroopPrepareTableCell', BaseTableViewProCell)

function GveTroopPrepareTableCell:ctor()

end

function GveTroopPrepareTableCell:OnCreate()
    ---@type HeroInfoItemComponent
    self.compChildCardHeroS = self:LuaObject('child_card_hero_s')
    self.sliderTroopHp = self:Slider('p_troop_hp')
    self.btnSelect = self:Button('',Delegate.GetOrCreate(self,self.OnCellClick))
end


function GveTroopPrepareTableCell:OnShow(param)
end

function GveTroopPrepareTableCell:OnHide(param)
end

function GveTroopPrepareTableCell:OnOpened(param)
end

function GveTroopPrepareTableCell:OnClose(param)
end

function GveTroopPrepareTableCell:OnFeedData(param)
    self.onClick = param.onClick
    ---@type wds.TroopCandidate
    local data = param.troopData
    if not data then
        return
    end
    self.Index = param.index
    local heroId = nil
    if data.Heros and data.Heros[1] then
        heroId = data.Heros[1].ConfigId
    end
    ---@type HeroInfoData
    local heroInfo = {
        heroData = ModuleRefer.HeroModule:GetHeroByCfgId(heroId),
        hideJobIcon = false
    }
    self.compChildCardHeroS:FeedData(heroInfo)
    local heroIds = {}
    for key, value in pairs(data.Heros) do
        table.insert(heroIds,value.ConfigId)
    end
    -- local maxSoldier = ModuleRefer.TroopEditModule:CalcMaxSoldierCount(heroIds)
    -- if maxSoldier > 0 then
    --     self.sliderTroopHp.value = data.SoldierCount / maxSoldier
    -- else
    --     self.sliderTroopHp.value = 1
    -- end
    if data.Status == wds.TroopCandidateStatus.TroopCandidateDead then
        self.selectable = false
        self.compChildCardHeroS:SetGray(true)
    else
        self.selectable = true
        self.compChildCardHeroS:SetGray(false)
    end
end

function GveTroopPrepareTableCell:OnCellClick()
    if not self.selectable then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('alliance_battle_toast6'))
        return
    end
    if self.onClick then
        self.onClick(self.Index)
    end
end

function GveTroopPrepareTableCell:Select(param)
    --override
    if self.compChildCardHeroS then
        self.compChildCardHeroS:ChangeStateSelect(true)
    end
end
function GveTroopPrepareTableCell:UnSelect(param)
    --override
    if self.compChildCardHeroS then
        self.compChildCardHeroS:ChangeStateSelect(false)
    end
end


return GveTroopPrepareTableCell
