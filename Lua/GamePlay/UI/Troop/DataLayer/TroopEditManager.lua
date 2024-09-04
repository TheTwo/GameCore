local TroopEditHeroSlot = require('TroopEditHeroSlot')
local TroopEditPetSlot = require('TroopEditPetSlot')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local EventConst = require('EventConst')
local UITroopConst = require('UITroopConst')
local HeroListSorters = require('HeroListSorters')
local PetListSorters = require('PetListSorters')
local UIMediatorNames = require('UIMediatorNames')
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local TroopEditTipsPusher = require('TroopEditTipsPusher')
local UITroopHelper = require('UITroopHelper')
local HUDTroopUtils = require('HUDTroopUtils')
local AudioConsts = require('AudioConsts')
---@class TroopEditManager
local TroopEditManager = class('TroopEditManager')

local MaxSlots = 3

function TroopEditManager:ctor()
    ---@type TroopEditHeroSlot[]
    self.heroSlots = {}
    ---@type TroopEditPetSlot[]
    self.petSlots = {}

    self.mapHeroId2SlotIndex = {}

    self.mapPetId2SlotIndex = {}

    self.onTroopEditChangeDelegates = {}

    self.curPresetIndex = 0

    self.dragStartIndex = -1
    self.dragEndIndex = -2

    self.dragStartType = -1
    self.dragEndType = -2

    self.hasChanged = false

    self.styleFilter = 0

    self.tipPusher = TroopEditTipsPusher.new(self)

    ---@type UITroopHeroSelectionCellData[]
    self.heroCellCache = {}
    ---@type UITroopPetSelectionCellData[]
    self.petCellCache = {}
end

function TroopEditManager:Init()
    g_Game.EventManager:AddListener(EventConst.ON_TROOP_MODEL_DRAG_START, Delegate.GetOrCreate(self, self.OnTroopModelDragStart))
    g_Game.EventManager:AddListener(EventConst.ON_TROOP_MODEL_DRAG_END, Delegate.GetOrCreate(self, self.OnTroopSlotDragEnd))
    g_Game.EventManager:AddListener(EventConst.ON_TROOP_MODEL_CLICK, Delegate.GetOrCreate(self, self.OnTroopModelClick))

    self.tipPusher:InitNodes()
end

function TroopEditManager:Release()
    for i = 1, MaxSlots do
        self.heroSlots[i]:Release()
        self.petSlots[i]:Release()
    end
    table.clear(self.heroSlots)
    table.clear(self.petSlots)
    table.clear(self.onTroopEditChangeDelegates)

    g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_MODEL_DRAG_START, Delegate.GetOrCreate(self, self.OnTroopModelDragStart))
    g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_MODEL_DRAG_END, Delegate.GetOrCreate(self, self.OnTroopSlotDragEnd))
    g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_MODEL_CLICK, Delegate.GetOrCreate(self, self.OnTroopModelClick))
end

function TroopEditManager:AddOnTroopEditChange(delegate)
    table.insert(self.onTroopEditChangeDelegates, delegate)
end

---@param view UI3DTroopModelView
function TroopEditManager:SetView(view)
    self.view = view
end

function TroopEditManager:RemoveOnTroopEditChange(delegate)
    for i = #self.onTroopEditChangeDelegates, 1, -1 do
        if self.onTroopEditChangeDelegates[i] == delegate then
            table.remove(self.onTroopEditChangeDelegates, i)
            break
        end
    end
end

function TroopEditManager:NotifyTroopEditChange(clearList)
    for _, delegate in ipairs(self.onTroopEditChangeDelegates) do
        if delegate then
            delegate(clearList)
        end
    end
end

function TroopEditManager:UpdateTroopFromPreset(presetIndex)
    self.curPresetIndex = presetIndex

    for i = 1, MaxSlots do
        if self.heroSlots[i] then
            self.heroSlots[i]:Release()
        end
        self.heroSlots[i] = TroopEditHeroSlot.new(i, self.curPresetIndex)

        if self.petSlots[i] then
            self.petSlots[i]:Release()
        end
        self.petSlots[i] = TroopEditPetSlot.new(i, self.curPresetIndex)
    end

    local buffValue = ModuleRefer.TroopModule:GetHerosRelationValueByIndex(presetIndex)
    buffValue = buffValue or 0

    for key, _ in pairs(self.mapHeroId2SlotIndex) do
        self.mapHeroId2SlotIndex[key] = nil
    end

    for key, _ in pairs(self.mapPetId2SlotIndex) do
        self.mapPetId2SlotIndex[key] = nil
    end

    local preset = ModuleRefer.TroopModule:GetPresetData(presetIndex)
    if preset then
        for i = 1, MaxSlots do
            local heroData = preset.Heroes[i]
            if not heroData then
                goto continue
            end
            local heroId = heroData.HeroCfgID
            if heroId > 0 then
                self.heroSlots[i]:AddUnit(heroId)
                self.heroSlots[i]:GetUnit():SetInitBuff(buffValue)
                self.mapHeroId2SlotIndex[heroId] = i
            end

            local petId = preset.Heroes[i].PetCompId
            if petId > 0 then
                self.petSlots[i]:AddUnit(petId)
                self.petSlots[i]:GetUnit():SetInitBuff(buffValue)
                self.mapPetId2SlotIndex[petId] = i
            end
            ::continue::
        end
    end

    self:UpdateHeroCellDatas()
    self:UpdatePetCellDatas()
    self:ApplyTroopBuff()
    self:NotifyTroopEditChange(true)

    self.view:ClearLockedSlotRing()
    for i = 1, MaxSlots do
        if self.heroSlots[i]:IsLocked() then
            self.view:LoadLockedSlotRing(i, UITroopConst.TroopSlotType.Hero)
        end

        if self.petSlots[i]:IsLocked() then
            self.view:LoadLockedSlotRing(i, UITroopConst.TroopSlotType.Pet)
        end
    end
end

function TroopEditManager:GetCurPresetIndex()
    return self.curPresetIndex
end

---@return boolean
function TroopEditManager:CanEdit()
    local preset = ModuleRefer.TroopModule:GetPresetData(self.curPresetIndex)
    return not preset or preset.Status == wds.TroopPresetStatus.TroopPresetIdle
end

function TroopEditManager:AddHero(heroId, slotIndex)
    if not self:CanEdit() then
        UITroopHelper.PopupTroopNotInHomeConfirm(self.curPresetIndex, I18N.Get("popup_recall_team_alert"))
        return
    end
    self.heroSlots[slotIndex]:AddUnit(heroId)
    self.mapHeroId2SlotIndex[heroId] = slotIndex
    for i, data in ipairs(self.heroCellCache) do
        if data.heroId == heroId then
            self.heroCellCache[i].selected = true
            break
        end
    end
    self:TroopEditChange()
    self.view:LoadDeployVfx(slotIndex, UITroopConst.TroopSlotType.Hero)
    self:PlayHeroDeploySound(slotIndex)
end

function TroopEditManager:RemoveHero(slotIndex)
    if not self:CanEdit() then
        UITroopHelper.PopupTroopNotInHomeConfirm(self.curPresetIndex, I18N.Get("popup_recall_team_alert"))
        return
    end
    if self.heroSlots[slotIndex]:IsEmpty() then return end
    local id = self.heroSlots[slotIndex]:GetUnit():GetId()
    self.mapHeroId2SlotIndex[id] = nil
    self.heroSlots[slotIndex]:RemoveUnit()
    for i, data in ipairs(self.heroCellCache) do
        if data.heroId == id then
            self.heroCellCache[i].selected = false
            break
        end
    end
    self:TroopEditChange()
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_click)
end

function TroopEditManager:RemoveHeroById(id)
    if not self:CanEdit() then
        UITroopHelper.PopupTroopNotInHomeConfirm(self.curPresetIndex, I18N.Get("popup_recall_team_alert"))
        return
    end
    local slotIndex = self.mapHeroId2SlotIndex[id]
    if slotIndex then
        self.heroSlots[slotIndex]:RemoveUnit()
        self.mapHeroId2SlotIndex[id] = nil
        for i, data in ipairs(self.heroCellCache) do
            if data.heroId == id then
                self.heroCellCache[i].selected = false
                break
            end
        end
        self:TroopEditChange()
    end
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_click)
end

function TroopEditManager:SwapHero(slotIndex1, slotIndex2)
    if not self:CanEdit() then
        UITroopHelper.PopupTroopNotInHomeConfirm(self.curPresetIndex, I18N.Get("popup_recall_team_alert"))
        return
    end
    local slot1 = self.heroSlots[slotIndex1]
    local slot2 = self.heroSlots[slotIndex2]
    self:InternalSwapUnit(slot1, slot2, self.mapHeroId2SlotIndex)
    self:TroopEditChange()
end

function TroopEditManager:AddPet(petId, slotIndex)
    if not self:CanEdit() then
        UITroopHelper.PopupTroopNotInHomeConfirm(self.curPresetIndex, I18N.Get("popup_recall_team_alert"))
        return
    end
    self.petSlots[slotIndex]:AddUnit(petId)
    self.mapPetId2SlotIndex[petId] = slotIndex
    local petType = ModuleRefer.PetModule:GetPetByID(petId).Type
    for i, data in ipairs(self.petCellCache) do
        local petData = ModuleRefer.PetModule:GetPetByID(data.petId)
        if data.petId == petId then
            self.petCellCache[i].selected = true
        end
        if petData.Type == petType then
            self.petCellCache[i].hasSameType = true
        end
    end
    self:TroopEditChange()
    self.view:LoadDeployVfx(slotIndex, UITroopConst.TroopSlotType.Pet)
    self:PlayPetDeploySound(slotIndex)
end

function TroopEditManager:RemovePet(slotIndex)
    if not self:CanEdit() then
        UITroopHelper.PopupTroopNotInHomeConfirm(self.curPresetIndex, I18N.Get("popup_recall_team_alert"))
        return
    end
    if self.petSlots[slotIndex]:IsEmpty() then return end
    local id = self.petSlots[slotIndex]:GetUnit():GetId()
    self.mapPetId2SlotIndex[id] = nil
    self.petSlots[slotIndex]:RemoveUnit()
    local petType = ModuleRefer.PetModule:GetPetByID(id).Type
    for i, data in ipairs(self.petCellCache) do
        local petData = ModuleRefer.PetModule:GetPetByID(data.petId)
        if data.petId == id then
            self.petCellCache[i].selected = false
        end
        if petData.Type == petType then
            self.petCellCache[i].hasSameType = false
        end
    end
    self:TroopEditChange()
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_click)
end

function TroopEditManager:RemovePetById(id)
    if not self:CanEdit() then
        UITroopHelper.PopupTroopNotInHomeConfirm(self.curPresetIndex, I18N.Get("popup_recall_team_alert"))
        return
    end
    local slotIndex = self.mapPetId2SlotIndex[id]
    if slotIndex then
        self.petSlots[slotIndex]:RemoveUnit()
        self.mapPetId2SlotIndex[id] = nil
        local petType = ModuleRefer.PetModule:GetPetByID(id).Type
        for i, data in ipairs(self.petCellCache) do
            local petData = ModuleRefer.PetModule:GetPetByID(data.petId)
            if data.petId == id then
                self.petCellCache[i].selected = false
            end
            if petData.Type == petType then
                self.petCellCache[i].hasSameType = false
            end
        end
        self:TroopEditChange()
    end
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_click)
end

function TroopEditManager:SwapPet(slotIndex1, slotIndex2)
    if not self:CanEdit() then
        UITroopHelper.PopupTroopNotInHomeConfirm(self.curPresetIndex, I18N.Get("popup_recall_team_alert"))
        return
    end
    local slot1 = self.petSlots[slotIndex1]
    local slot2 = self.petSlots[slotIndex2]
    self:InternalSwapUnit(slot1, slot2, self.mapPetId2SlotIndex)
    self:TroopEditChange()
end

---@param slotIndex number
---@return TroopEditHeroSlot
---@return TroopEditPetSlot
function TroopEditManager:GetSlot(slotIndex)
    return self.heroSlots[slotIndex], self.petSlots[slotIndex]
end

---@param slotIndex number
---@param slotType number
---@return TroopEditSlot
function TroopEditManager:GetSlotByType(slotIndex, slotType)
    if slotType == UITroopConst.TroopSlotType.Hero then
        return self.heroSlots[slotIndex]
    elseif slotType == UITroopConst.TroopSlotType.Pet then
        return self.petSlots[slotIndex]
    end
    return nil
end

function TroopEditManager:GetFirstEmptyHeroSlotIndex()
    for i, slot in ipairs(self.heroSlots) do
        if slot:IsEmpty() then
            return i
        end
    end
    return 0
end

function TroopEditManager:GetFirstEmptyPetSlotIndex()
    for i, slot in ipairs(self.petSlots) do
        if slot:IsEmpty() then
            return i
        end
    end
    return 0
end

function TroopEditManager:GetFirstAvaliableHeroSlotIndex()
    for i, slot in ipairs(self.heroSlots) do
        if not slot:IsLocked() and slot:IsEmpty() then
            return i
        end
    end
    return 0
end

function TroopEditManager:GetFirstAvaliablePetSlotIndex()
    for i, slot in ipairs(self.petSlots) do
        if not slot:IsLocked() and slot:IsEmpty() then
            return i
        end
    end
    return 0
end

---@return number
function TroopEditManager:GetTroopPower()
    local ret = 0
    for _, slot in ipairs(self.heroSlots) do
        if not slot:IsEmpty() and not slot:IsLocked() then
            ret = ret + slot:GetUnit():GetPower()
        end
    end

    for _, slot in ipairs(self.petSlots) do
        if not slot:IsEmpty() and not slot:IsLocked() then
            ret = ret + slot:GetUnit():GetPower()
        end
    end

    return ret
end

function TroopEditManager:GetTroopTip()
    return self.tipPusher:GetTip()
end

function TroopEditManager:SetStyleFilter(styleCfgId)
    self.styleFilter = styleCfgId
end

function TroopEditManager:GetStyleFilter()
    return self.styleFilter
end

---@param data UITroopHeroSelectionCellData
---@return boolean
function TroopEditManager:FilterHeroCellData(data)
    if self.styleFilter == 0 then
        return true
    end
    local heroData = ModuleRefer.HeroModule:GetHeroByCfgId(data.heroId)
    if not heroData or not heroData.configCell then
        return false
    end
    return heroData.configCell:AssociatedTagInfo() == self.styleFilter
end

---@param data UITroopPetSelectionCellData
---@return boolean
function TroopEditManager:FilterPetCellData(data)
    if self.styleFilter == 0 then
        return true
    end
    local petData = ModuleRefer.PetModule:GetPetByID(data.petId)
    local petCfg = ModuleRefer.PetModule:GetPetCfg(petData.ConfigId)
    if not petCfg then
        return false
    end
    return petCfg:AssociatedTagInfo() == self.styleFilter
end

function TroopEditManager:UpdateHeroCellDatas(withoutFilter, shouldSort)
    table.clear(self.heroCellCache)
    local ret = {}
    local inCurTeamHeroes = {}
    local inOtherTeamHeroes = {}
    local otherHeros = {}
    local player = ModuleRefer.PlayerModule:GetPlayer()
    for _, heroInfo in pairs(player.Hero.HeroInfos) do
        local teamIndex = ModuleRefer.TroopModule:GetHeroTeamIndex(heroInfo.CfgId) or 0
        ---@type UITroopHeroSelectionCellData
        local cellData = {}
        cellData.heroId = heroInfo.CfgId
        cellData.maxHpAddPct = 0
        cellData.oriMaxHpAddPct = 0
        cellData.hp = ModuleRefer.TroopModule:GetTroopHeroHp(heroInfo.CfgId)
        cellData.selected = self.mapHeroId2SlotIndex[heroInfo.CfgId] ~= nil
        cellData.otherTeamIndex = ((cellData.selected or teamIndex == self.curPresetIndex) and 0) or teamIndex
        cellData.onClick = Delegate.GetOrCreate(self, self.OnHeroCellClicked)

        if true then
            if cellData.otherTeamIndex > 0 then
                table.insert(inOtherTeamHeroes, cellData)
            elseif cellData.selected then
                table.insert(inCurTeamHeroes, cellData)
            else
                table.insert(otherHeros, cellData)
            end
        end
    end

    table.sort(inCurTeamHeroes, function(a, b)
        local dataA = ModuleRefer.HeroModule:GetHeroByCfgId(a.heroId)
        local dataB = ModuleRefer.HeroModule:GetHeroByCfgId(b.heroId)
        return HeroListSorters.HeroSortByPower(dataA, dataB)
    end)

    table.sort(inOtherTeamHeroes, function(a, b)
        local dataA = ModuleRefer.HeroModule:GetHeroByCfgId(a.heroId)
        local dataB = ModuleRefer.HeroModule:GetHeroByCfgId(b.heroId)
        return HeroListSorters.HeroSortByPower(dataA, dataB)
    end)

    table.sort(otherHeros, function(a, b)
        local dataA = ModuleRefer.HeroModule:GetHeroByCfgId(a.heroId)
        local dataB = ModuleRefer.HeroModule:GetHeroByCfgId(b.heroId)
        return HeroListSorters.HeroSortByPower(dataA, dataB)
    end)

    for _, data in ipairs(inCurTeamHeroes) do
        table.insert(ret, data)
    end

    for _, data in ipairs(otherHeros) do
        table.insert(ret, data)
    end

    for _, data in ipairs(inOtherTeamHeroes) do
        table.insert(ret, data)
    end

    self.heroCellCache = ret
end

function TroopEditManager:UpdatePetCellDatas(withoutFilter)
    table.clear(self.petCellCache)
    local ret = {}
    local inCurTeamPets = {}
    local inOtherTeamPets = {}
    local otherPets = {}

    local mapTroopPetType = {}
    for _, slot in ipairs(self.petSlots) do
        if not slot:IsEmpty() then
            local pet = slot:GetUnit()
            local petCfg = ModuleRefer.PetModule:GetPetCfg(pet:GetCfgId())
            if petCfg then
                mapTroopPetType[petCfg:Type()] = true
            end
        end
    end

    for _, petInfo in pairs(ModuleRefer.PetModule:GetPetList()) do
        local teamIndex = ModuleRefer.TroopModule:GetPetBelongedTroopIndex(petInfo.ID)
        local petType = ConfigRefer.Pet:Find(petInfo.ConfigId):Type()
        ---@type UITroopPetSelectionCellData
        local cellData = {}
        cellData.petId = petInfo.ID
        cellData.maxHpAddPct = 0
        cellData.oriMaxHpAddPct = 0
        cellData.hp = ModuleRefer.TroopModule:GetTroopPetHp(petInfo.ID)
        cellData.selected = self.mapPetId2SlotIndex[petInfo.ID] ~= nil
        cellData.otherTeamIndex = ((cellData.selected or teamIndex == self.curPresetIndex) and 0) or teamIndex
        cellData.hasSameType = mapTroopPetType[petType] and not cellData.selected
        cellData.onClick = Delegate.GetOrCreate(self, self.OnPetCellClicked)

        if true then
            if cellData.otherTeamIndex > 0 then
                table.insert(inOtherTeamPets, cellData)
            elseif cellData.selected then
                table.insert(inCurTeamPets, cellData)
            else
                table.insert(otherPets, cellData)
            end
        end
    end

    table.sort(inCurTeamPets, function(a, b)
        return PetListSorters.SortByPower(a.petId, b.petId)
    end)

    table.sort(inOtherTeamPets, function(a, b)
        return PetListSorters.SortByPower(a.petId, b.petId)
    end)

    table.sort(otherPets, function(a, b)
        return PetListSorters.SortByPower(a.petId, b.petId)
    end)

    for _, data in ipairs(inCurTeamPets) do
        table.insert(ret, data)
    end

    for _, data in ipairs(otherPets) do
        table.insert(ret, data)
    end

    for _, data in ipairs(inOtherTeamPets) do
        table.insert(ret, data)
    end

    self.petCellCache = ret
end

function TroopEditManager:GetHeroCellDatas(withoutFilter)
    if #self.heroCellCache == 0 then
        self:UpdateHeroCellDatas()
    end
    if not withoutFilter then
        local ret = {}
        for _, data in ipairs(self.heroCellCache) do
            if self:FilterHeroCellData(data) then
                table.insert(ret, data)
            end
        end
        return ret
    end
    return self.heroCellCache
end

function TroopEditManager:GetPetCellDatas(withoutFilter)
    if #self.petCellCache == 0 then
        self:UpdatePetCellDatas()
    end
    if not withoutFilter then
        local ret = {}
        for _, data in ipairs(self.petCellCache) do
            if self:FilterPetCellData(data) then
                table.insert(ret, data)
            end
        end
        return ret
    end
    return self.petCellCache
end

---@return table<number, number>
function TroopEditManager:GetTroopTagNums()
    local tags2Num = {}
    for id, _ in ConfigRefer.AssociatedTag:ipairs() do
        tags2Num[id] = 0
    end
    for _, slot in ipairs(self.heroSlots) do
        if not slot:IsEmpty() then
            local hero = slot:GetUnit()
            local tagId = hero:GetAssociatedTagId()
            if tagId > 0 then
                tags2Num[tagId] = tags2Num[tagId] + 1
            end
        end
    end

    for _, slot in ipairs(self.petSlots) do
        if not slot:IsEmpty() then
            local pet = slot:GetUnit()
            local tagId = pet:GetAssociatedTagId()
            if tagId > 0 then
                tags2Num[tagId] = tags2Num[tagId] + 1
            end
        end
    end
    return tags2Num
end

function TroopEditManager:GetTroopBuffId()
    local tags2Num = self:GetTroopTagNums()

    local maxMatchedNum = 0
    local maxBuffId = 0
    ---@type number, TagTiesElementConfigCell
    for _, cfg in ConfigRefer.TagTiesElement:ipairs() do
        local matchedNum = 0
        local active = true
        for i = 1, cfg:BattleStyleLength() do
            local tagId = cfg:BattleStyle(i)
            if tags2Num[tagId] < cfg:Num(i) then
                active = false
                matchedNum = 0
                break
            else
                matchedNum = matchedNum + cfg:Num(i)
            end
        end
        if active and matchedNum > maxMatchedNum then
            maxMatchedNum = matchedNum
            maxBuffId = cfg:Id()
        end
    end
    return maxBuffId
end

---@return table<number, number>
function TroopEditManager:GetTroopBuffValues()
    local ret = {}
    local buffId = self:GetTroopBuffId()
    local buffCfg = ConfigRefer.TagTiesElement:Find(buffId)
    if not buffCfg then
        return ret
    end
    local tiesCfg = ConfigRefer.TagTies:Find(buffCfg:Ties())
    local attrGroup = ConfigRefer.AttrGroup:Find(tiesCfg:TiesAddons(1))
    for i = 1, attrGroup:AttrListLength() do
        local attrId = attrGroup:AttrList(i):TypeId()
        local value = attrGroup:AttrList(i):Value() / 10000
        ret[attrId] = value
    end
    return ret
end

function TroopEditManager:GetTroopNeededHp()
    local ret = 0
    local eps = 1
    for _, slot in ipairs(self.heroSlots) do
        if not slot:IsEmpty() then
            local hero = slot:GetUnit()
            local need = hero:GetMaxHp() - hero:GetHp()
            if need > eps then
                ret = ret + need
            end
        end
    end

    for _, slot in ipairs(self.petSlots) do
        if not slot:IsEmpty() then
            local pet = slot:GetUnit()
            local need = pet:GetMaxHp() - pet:GetHp()
            if need > eps then
                ret = ret + need
            end
        end
    end

    return ret
end

---@return TroopEditUnit[]
function TroopEditManager:GetTroopNeedHpUnits()
    local ret = {}
    for _, slot in ipairs(self.heroSlots) do
        if not slot:IsEmpty() then
            local hero = slot:GetUnit()
            local needHp = hero:GetMaxHp() - hero:GetHp()
            if needHp > 0 then
                table.insert(ret, hero)
            end
        end
    end

    for _, slot in ipairs(self.petSlots) do
        if not slot:IsEmpty() then
            local pet = slot:GetUnit()
            local needHp = pet:GetMaxHp() - pet:GetHp()
            if needHp > 0 then
                table.insert(ret, pet)
            end
        end
    end

    return ret
end

---@return TroopEditUnit[]
function TroopEditManager:GetTroopCanHealUnits()
    local ret = {}
    local bagHp = ModuleRefer.TroopModule:GetTroopHpBagCurHp(self.curPresetIndex)
    if bagHp == 0 then
        local food = ModuleRefer.TroopModule:GetStockFoodCount()
        bagHp = food
    end
    for i = 1, MaxSlots do
        local heroSlot = self.heroSlots[i]
        if not heroSlot:IsEmpty() then
            local hero = heroSlot:GetUnit()
            local needHp = hero:GetMaxHp() - hero:GetHp()
            if bagHp > 0 and needHp > 0 then
                table.insert(ret, hero)
                bagHp = bagHp - needHp
            end
        end
        local petSlot = self.petSlots[i]
        if not petSlot:IsEmpty() then
            local pet = petSlot:GetUnit()
            local needHp = pet:GetMaxHp() - pet:GetHp()
            if bagHp > 0 and needHp > 0 then
                table.insert(ret, pet)
                bagHp = bagHp - needHp
            end
        end
    end
    return ret
end

---@return boolean
function TroopEditManager:IsTroopChanged()
    return self.hasChanged
end

function TroopEditManager:HasAvaliableHero()
    local heroes = self:GetHeroCellDatas(true)
    for _, hero in ipairs(heroes) do
        if not hero.selected and hero.otherTeamIndex == 0 then
            return true
        end
    end
    return false
end

function TroopEditManager:HasAvaliableHeroSlot()
    for _, slot in ipairs(self.heroSlots) do
        if slot:IsEmpty() then
            return true
        end
    end
    return false
end

function TroopEditManager:HasAvaliablePet()
    local pets = self:GetPetCellDatas(true)
    for _, pet in ipairs(pets) do
        if not pet.selected and pet.otherTeamIndex == 0 and not pet.hasSameType and not pet.isWorking then
            return true
        end
    end
    return false
end

function TroopEditManager:HasAvaliablePetSlot()
    for _, slot in ipairs(self.petSlots) do
        if slot:IsEmpty() and not slot:IsLocked() then
            return true
        end
    end
end

function TroopEditManager:HasHeroWithoutPet()
    for i = 1, MaxSlots do
        if self.petSlots[i]:IsEmpty() and not self.heroSlots[i]:IsEmpty() then
            return true
        end
    end
    return false
end

---@param callback fun(saveSucc:boolean, allowContinue:boolean)
function TroopEditManager:SaveTroop(callback)
    local canSave, errIndex = self:CheckCanSave()
    local errSlot = self.heroSlots[errIndex]
    if not canSave then
        ---@type CommonConfirmPopupMediatorParameter
        local confirmData = {}
        confirmData.content = I18N.GetWithParams("popup_save_changes", errSlot:GetName())
        confirmData.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
        confirmData.confirmLabel = I18N.Get("exit_discard_changes")
        confirmData.onConfirm = function ()
            callback(false, true)
            return true
        end
        confirmData.onCancel = function ()
            callback(false, false)
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmData)
        return
    end

    local msg = require("SaveTroopPresetParameter").new()
    msg.args.Slot = self.curPresetIndex - 1
    for i = 1, MaxSlots do
        local heroSlot = self.heroSlots[i]
        local petSlot = self.petSlots[i]
        msg.args.Preset.Heroes:Add({
            HeroCfgID = (heroSlot:IsEmpty() and 0) or heroSlot:GetUnit():GetId(),
            PetCompId = (petSlot:IsEmpty() and 0) or petSlot:GetUnit():GetId()
        })
    end
    msg:SendOnceCallback(nil, nil, nil, function (_, isSuccess, _)
        if isSuccess then
            self.hasChanged = false
            callback(true, true)
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("toast_save_succeed"))
        end
    end)
end

function TroopEditManager:CheckCanSave()
    local canSave = true
    local errIndex = 0
    for i = 1, MaxSlots do
        local heroSlot = self.heroSlots[i]
        local petSlot = self.petSlots[i]
        if heroSlot:IsEmpty() and not petSlot:IsEmpty() then
            canSave = false
            errIndex = i
            break
        end
    end
    return canSave, errIndex
end

---@private
function TroopEditManager:ApplyTroopBuff()
    local buffValues = self:GetTroopBuffValues()
    local _, bonusValue = next(buffValues)
    for _, slot in ipairs(self.heroSlots) do
        if not slot:IsEmpty() then
            slot:GetUnit():ApplyBuff(bonusValue or 0)
        end
    end
    for _, slot in ipairs(self.petSlots) do
        if not slot:IsEmpty() then
            slot:GetUnit():ApplyBuff(bonusValue or 0)
        end
    end
end

---@param slot1 TroopEditSlot
---@param slot2 TroopEditSlot
---@param map any
---@private
function TroopEditManager:InternalSwapUnit(slot1, slot2, map)
    if slot1:IsEmpty() and slot2:IsEmpty() then
        return
    end
    if slot1:IsLocked() or slot2:IsLocked() then
        if slot1:IsLocked() then
            ModuleRefer.ToastModule:AddSimpleToast(slot1:GetUnlockCondStr())
        else
            ModuleRefer.ToastModule:AddSimpleToast(slot2:GetUnlockCondStr())
        end
        return
    end
    if slot1:IsEmpty() then
        map[slot2:GetUnit():GetId()] = slot1:GetIndex()
        slot1:AddUnit(slot2:GetUnit():GetId())
        slot2:RemoveUnit()
        self.view:LoadDeployVfx(slot1:GetIndex(), slot1:GetType())
    elseif slot2:IsEmpty() then
        map[slot1:GetUnit():GetId()] = slot2:GetIndex()
        slot2:AddUnit(slot1:GetUnit():GetId())
        slot1:RemoveUnit()
        self.view:LoadDeployVfx(slot2:GetIndex(), slot2:GetType())
    else
        map[slot1:GetUnit():GetId()] = slot2:GetIndex()
        map[slot2:GetUnit():GetId()] = slot1:GetIndex()
        local temp = slot1:GetUnit():GetId()
        slot1:AddUnit(slot2:GetUnit():GetId())
        slot2:AddUnit(temp)
        self.view:LoadDeployVfx(slot1:GetIndex(), slot1:GetType())
        self.view:LoadDeployVfx(slot2:GetIndex(), slot2:GetType())
    end
end

---@private
function TroopEditManager:TroopEditChange(clearList)
    self.hasChanged = true
    self:ApplyTroopBuff()
    self:NotifyTroopEditChange(clearList)
end

---@private
function TroopEditManager:OnTroopModelDragStart(index, type)
    self.dragStartIndex = index
    self.dragStartType = type
end

---@private
function TroopEditManager:OnTroopSlotDragEnd(index, type)
    self.dragEndIndex = index
    self.dragEndType = type
    if not self:CanEdit() then
        UITroopHelper.PopupTroopNotInHomeConfirm(self.curPresetIndex, I18N.Get("popup_recall_team_alert"))
    elseif self.dragStartType == self.dragEndType and self.dragStartIndex ~= self.dragEndIndex then
        if self.dragEndType == UITroopConst.TroopSlotType.Hero then
            self:SwapHero(self.dragStartIndex, self.dragEndIndex)
        else
            self:SwapPet(self.dragStartIndex, self.dragEndIndex)
        end
    end
    self.dragStartIndex = -1
    self.dragEndIndex = -2
    self.dragStartType = -1
    self.dragEndType = -2

    self.view:UnloadSlotHoldingVfx()
end

function TroopEditManager:GetCurDraggingIndex()
    return self.dragStartIndex or 0
end

function TroopEditManager:GetCurDraggingType()
    return self.dragStartType or -1
end

---@private
function TroopEditManager:OnTroopModelClick(index, type)
    if type == UITroopConst.TroopSlotType.Hero then
        self:RemoveHero(index)
    else
        self:RemovePet(index)
    end
end

---@private
---@param data UITroopHeroSelectionCellData
function TroopEditManager:OnHeroCellClicked(data)
    if data.selected then
        self:RemoveHeroById(data.heroId)
    elseif data.otherTeamIndex > 0 then
        local heroCfg = ConfigRefer.Heroes:Find(data.heroId)
        local heroName = I18N.Get(heroCfg:Name())
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("team_hero_tip01", heroName))
    else
        local slotIndex = self:GetFirstAvaliableHeroSlotIndex()
        if slotIndex > 0 then
            self:AddHero(data.heroId, slotIndex)
        else
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("toast_team_hero_full"))
        end
    end
end

---@private
---@param data CommonPetIconBaseData
function TroopEditManager:OnPetCellClicked(data)
    local petName = ModuleRefer.PetModule:GetPetName(data.petId)
    if data.selected then
        self:RemovePetById(data.petId)
    elseif data.otherTeamIndex > 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("team_hero_tip01", petName))
    elseif data.hasSameType then
        ---@type CommonConfirmPopupMediatorParameter
        local confirmData = {}
        confirmData.content = I18N.GetWithParams("team_animal_tip02", petName)
        confirmData.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
        confirmData.confirmLabel = I18N.Get("btn_replace_confirm")

        confirmData.onConfirm = function ()
            for i, slot in ipairs(self.petSlots) do
                if not slot:IsEmpty() then
                    local pet = slot:GetUnit()
                    local petCfg = ModuleRefer.PetModule:GetPetCfg(pet:GetCfgId())
                    if petCfg:Type() == ModuleRefer.PetModule:GetPetCfgById(data.petId):Type() then
                        self:RemovePet(slot:GetIndex())
                        self:AddPet(data.petId, i)
                        break
                    end
                end
            end
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmData)
    elseif data.isWorking then
        local city = ModuleRefer.CityModule:GetMyCity()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("troop_pet_status", city.petManager:GetWorkPosition(data.petId)))
    else
        local slotIndex = self:GetFirstEmptyPetSlotIndex()
        if slotIndex > 0 then
            local slot = self.petSlots[slotIndex]
            if slot:IsLocked() then
                ModuleRefer.ToastModule:AddSimpleToast(slot:GetUnlockCondStr())
            else
                self:AddPet(data.petId, slotIndex)
            end
        else
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("toast_team_animal_full"))
        end
    end
end

function TroopEditManager:PlayHeroDeploySound(index)
    if self.voiceHandle and self.voiceHandle:IsValid() then
        g_Game.SoundManager:Stop(self.voiceHandle)
    end
    local slot = self.heroSlots[index]
    local heroId = slot:GetUnit():GetId()
    local heroCfg = ConfigRefer.Heroes:Find(heroId)
    local resCell = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
    self.voiceHandle = g_Game.SoundManager:PlayAudio(resCell:ShowVoiceRes())
end

function TroopEditManager:PlayPetDeploySound(index)
end

return TroopEditManager