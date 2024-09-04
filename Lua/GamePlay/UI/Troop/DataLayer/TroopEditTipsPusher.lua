local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local TroopEditTips = require("TroopEditTips")
local Delegate = require("Delegate")
local UITroopHelper = require("UITroopHelper")
local TipsLevel = TroopEditTips.TipsLevel
---@class TroopEditTipsPusher
local TroopEditTipsPusher = class('TroopEditTipsPusher')

---@param manager TroopEditManager
function TroopEditTipsPusher:ctor(manager)
    self.manager = manager
end

function TroopEditTipsPusher:InitNodes()
    ---@type TroopEditTips 是否存在有动物而无英雄的排？
    local hasPetWithoutHeroNode = TroopEditTips.new(Delegate.GetOrCreate(self, self.HasPetWithoutHero), "{1}", nil, TipsLevel.Error)
    ---@type TroopEditTips 是否有可上阵的英雄？
    local hasAvaliableHeroNode = TroopEditTips.new(Delegate.GetOrCreate(self, self.HasAvaliableHero), "{1}", nil, TipsLevel.Error)
    ---@type TroopEditTips 前排英雄是否是Tank？
    local frontRowHeroIsTankNode = TroopEditTips.new(Delegate.GetOrCreate(self, self.FrontRowHeroIsTank), nil, nil, nil)
    ---@type TroopEditTips 中后排是否有Tank？
    local tankHeroInBackRowsNode = TroopEditTips.new(Delegate.GetOrCreate(self, self.TankHeroInBackRows), "team_tip_yellow_hero02", "team_tip_yellow_hero01", TipsLevel.Warning)
    ---@type TroopEditTips 已上阵英雄的同排是否有可上阵动物？
    local hasAvaliablePetNode = TroopEditTips.new(Delegate.GetOrCreate(self, self.HasAvaliablePet), "{1}", nil, TipsLevel.Error)
    ---@type TroopEditTips 前排动物是否是Tank？
    local frontRowPetIsTankNode = TroopEditTips.new(Delegate.GetOrCreate(self, self.FrontRowPetIsTank), nil, nil, nil)
    ---@type TroopEditTips 中后排动物是否有Tank？
    local tankPetInBackRowsNode = TroopEditTips.new(Delegate.GetOrCreate(self, self.TankPetInBackRows), "team_tip_yellow_animal02", "team_tip_yellow_animal01", TipsLevel.Warning)
    ---@type TroopEditTips 已解锁的英雄上阵位是否都已上满？
    local isSlotAllFilledNode = TroopEditTips.new(Delegate.GetOrCreate(self, self.IsSlotAllFilled), nil, nil, nil)
    ---@type TroopEditTips 是否已解锁狗窝？
    local isGachaUnlockNode = TroopEditTips.new(Delegate.GetOrCreate(self, self.IsGachaUnlock), "team_tip_red_hero09", nil, TipsLevel.Error)
    ---@type TroopEditTips 是否已解锁并未购买首充礼包？
    local isFirstRechargeAvailableNode = TroopEditTips.new(Delegate.GetOrCreate(self, self.IsFirstRechargeAvailable), "team_tip_red_hero08", "team_tip_red_hero07", TipsLevel.Error)
    ---@type TroopEditTips 是否有激活阵容效果？
    local isBuffActiveNode = TroopEditTips.new(Delegate.GetOrCreate(self, self.IsBuffActive), nil, "{1}", TipsLevel.Info)
    ---@type TroopEditTips 已激活阵容效果是否=5(max)？
    local isBuffMaxNode = TroopEditTips.new(Delegate.GetOrCreate(self, self.IsBuffMax), nil, "{1}", TipsLevel.Info)

    hasPetWithoutHeroNode:SetNTip(hasAvaliableHeroNode)
    hasAvaliableHeroNode:SetNTip(frontRowHeroIsTankNode)
    frontRowHeroIsTankNode:SetYTip(hasAvaliablePetNode)
    frontRowHeroIsTankNode:SetNTip(tankHeroInBackRowsNode)

    hasAvaliablePetNode:SetNTip(frontRowPetIsTankNode)
    frontRowPetIsTankNode:SetYTip(isSlotAllFilledNode)
    frontRowPetIsTankNode:SetNTip(tankPetInBackRowsNode)

    isSlotAllFilledNode:SetYTip(isBuffActiveNode)
    isSlotAllFilledNode:SetNTip(isGachaUnlockNode)
    isGachaUnlockNode:SetNTip(isFirstRechargeAvailableNode)

    isBuffActiveNode:SetYTip(isBuffMaxNode)

    self.firstNode = hasPetWithoutHeroNode
end

function TroopEditTipsPusher:GetTip()
    return self.firstNode:GetTip()
end

function TroopEditTipsPusher:HasPetWithoutHero()
    local i18NKeys = {
        "team_tip_red_hero10",
        "team_tip_red_hero11",
        "team_tip_red_hero12"
    }
    local errSlots = {}
    for i = 1, 3 do
        local heroSlot = self.manager.heroSlots[i]
        local petSlot = self.manager.petSlots[i]
        if heroSlot:IsEmpty() and not petSlot:IsEmpty() then
            table.insert(errSlots, petSlot:GetName())
        end
    end
    local errCount = #errSlots
    if errCount > 0 then
        local i18NKey = i18NKeys[errCount]
        return true, I18N.GetWithParamList(i18NKey, errSlots)
    end
    return false
end

function TroopEditTipsPusher:HasAvaliableHero()
    local i18NKeys = {
        "team_tip_red_hero01",
        "team_tip_red_hero02",
        "team_tip_red_hero03"
    }
    local errSlots = {}
    local hasAvaliableHero = false
    for _, heroData in ipairs(self.manager:GetHeroCellDatas(true)) do
        if not heroData.selected and heroData.otherTeamIndex == 0 then
            hasAvaliableHero = true
            break
        end
    end

    for i = 1, 3 do
        local heroSlot = self.manager.heroSlots[i]
        if heroSlot:IsEmpty() and hasAvaliableHero then
            table.insert(errSlots, heroSlot:GetName())
        end
    end
    local errCount = #errSlots
    if errCount > 0 then
        local i18NKey = i18NKeys[errCount]
        return true, I18N.GetWithParamList(i18NKey, errSlots)
    end
    return false
end

function TroopEditTipsPusher:FrontRowHeroIsTank()
    local heroSlot = self.manager.heroSlots[1]
    if heroSlot:IsEmpty() then
        return false
    end

    local heroUnit = heroSlot:GetUnit()
    local battleStyle = heroUnit:GetBattleStyleId()

    return battleStyle == require("BattleLabel").Tank
end

function TroopEditTipsPusher:TankHeroInBackRows()
    for i = 2, 3 do
        local heroSlot = self.manager.heroSlots[i]
        if heroSlot:IsEmpty() then
            return false
        end

        local heroUnit = heroSlot:GetUnit()
        local battleStyle = heroUnit:GetBattleStyleId()

        if battleStyle == require("BattleLabel").Tank then
            return true
        end
    end
    return false
end

function TroopEditTipsPusher:HasAvaliablePet()
    local i18NKeys = {
        "team_tip_red_animal01",
        "team_tip_red_animal02",
        "team_tip_red_animal03"
    }
    local errSlots = {}
    local hasAvaliablePet = false
    for _, petData in ipairs(self.manager:GetPetCellDatas(true)) do
        if not petData.selected and petData.otherTeamIndex == 0 and not petData.hasSameType and not petData.isWorking then
            hasAvaliablePet = true
            break
        end
    end

    for i = 1, 3 do
        local petSlot = self.manager.petSlots[i]
        local heroSlot = self.manager.heroSlots[i]
        if petSlot:IsEmpty() and not petSlot:IsLocked() and not heroSlot:IsEmpty() and hasAvaliablePet then
            table.insert(errSlots, petSlot:GetName())
        end
    end
    local errCount = #errSlots
    if errCount > 0 then
        local i18NKey = i18NKeys[errCount]
        return true, I18N.GetWithParamList(i18NKey, errSlots)
    end
    return false
end

function TroopEditTipsPusher:FrontRowPetIsTank()
    local petSlot = self.manager.petSlots[1]
    if petSlot:IsEmpty() then
        return false
    end

    local petUnit = petSlot:GetUnit()
    local battleStyle = petUnit:GetBattleStyleId()

    return battleStyle == require("BattleLabel").Tank
end

function TroopEditTipsPusher:TankPetInBackRows()
    for i = 2, 3 do
        local petSlot = self.manager.petSlots[i]
        if petSlot:IsEmpty() then
            return false
        end

        local petUnit = petSlot:GetUnit()
        local battleStyle = petUnit:GetBattleStyleId()

        if battleStyle == require("BattleLabel").Tank then
            return true
        end
    end
    return false
end

function TroopEditTipsPusher:IsSlotAllFilled()
    for i = 1, 3 do
        local heroSlot = self.manager.heroSlots[i]
        if (heroSlot:IsEmpty() and not heroSlot:IsLocked()) then
            return false
        end
    end
    return true
end

function TroopEditTipsPusher:IsGachaUnlock()
    local systemId = require("NewFunctionUnlockIdDefine").Global_gacha
    return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(systemId)
end

function TroopEditTipsPusher:IsFirstRechargeAvailable()
    local popId = ModuleRefer.ActivityShopModule:GetFirstRechargePopId()
    local groupId
    if popId > 0 then
        local pop = ConfigRefer.PopUpWindow:Find(popId)
        groupId = pop:PayGroup()
        local goodsId = ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(groupId)
        if goodsId and goodsId == 7 or goodsId == 8 then
            return true
        end
    end
    return false
end

function TroopEditTipsPusher:IsBuffActive()
    local buffId = self.manager:GetTroopBuffId()
    if buffId == 0 then
        return false, UITroopHelper.GetTiesStrByTiesId(1):gsub("%%", "%%%%")
    else
        return true
    end
end

function TroopEditTipsPusher:IsBuffMax()
    local buffId = self.manager:GetTroopBuffId()
    local buffCfg = ConfigRefer.TagTiesElement:Find(buffId)
    local cfg = ConfigRefer.TagTies:Find(buffCfg:Ties())
    if cfg:NextTagTies() > 0 then
        return false, UITroopHelper.GetTiesStrByTiesId(cfg:NextTagTies()):gsub("%%", "%%%%")
    else
        return true
    end
end


return TroopEditTipsPusher