local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')

---@class UITroopHeroCardGroupPvpTempData
---@field editable boolean
---@field limitEdit boolean
---@field simpleMode boolean
---@field isPvP boolean
---@field onEmptyButtonClick fun(data:UITroopHeroCardData):void
---@field onHeroDeleteClick fun(data:UITroopHeroCardData):void
---@field onHeroCardClick fun(data:UITroopHeroCardData):void
---@field onPetBindChanged fun(data:table<number,number>):void @heroId,petId
---@field onHeroCardDataChanged fun(data:UITroopHeroCardData[],changed:UITroopHeroCard):void
---@field heroCardData UITroopHeroCardData[]
---@field getOtherPetLinkInfo fun():table<number,number>
---@field onSpaceClick fun():void

---@class UITroopHeroCardGroupPvpTemp : BaseUIComponent
---@field heroCards UITroopHeroCard[]
---@field _heroCardData UITroopHeroCardData[]
---@field editable boolean
---@field simpleMode boolean
---@field onEmptyButtonClick fun(data:UITroopHeroCardData):void
---@field onHeroCardDataChanged fun(data:UITroopHeroCardData[],changed:UITroopHeroCard):void
---@field getOtherPetLinkInfo fun():table<number,number>

---@class UITroopHeroCardGroupPvpTemp : BaseUIComponent
local UITroopHeroCardGroupPvpTemp = class('UITroopHeroCardGroupPvpTemp', BaseUIComponent)

local MAX_HERO_COUNT = 3
function UITroopHeroCardGroupPvpTemp:ctor()

end

function UITroopHeroCardGroupPvpTemp:OnCreate()
    self:PointerClick('p_back_mask', Delegate.GetOrCreate(self, self.OnEmptyClick))
    self:AddHeroCard(self:LuaObject('child_troop_position_1'))
    self:AddHeroCard(self:LuaObject('child_troop_position_2'))
    self:AddHeroCard(self:LuaObject('child_troop_position_3'))

    self:Text('p_text_back','formation_back')
    self:Text('p_text_middle','formation_middle')
    self:Text('p_text_front','formation_front')

    self.statusCtrler = self:StatusRecordParent("")
end


function UITroopHeroCardGroupPvpTemp:OnShow(param)
end

function UITroopHeroCardGroupPvpTemp:OnHide(param)
end

function UITroopHeroCardGroupPvpTemp:OnOpened(param)
end

function UITroopHeroCardGroupPvpTemp:OnClose(param)
end

---@param param UITroopHeroCardGroupPvpTempData
function UITroopHeroCardGroupPvpTemp:OnFeedData(param)
    self._heroCardData = param.heroCardData
    self.editable = param.editable
    self.simpleMode = param.simpleMode
    self.onEmptyButtonClick = param.onEmptyButtonClick
    self.onHeroCardDataChanged = param.onHeroCardDataChanged
    self.getOtherPetLinkInfo = param.getOtherPetLinkInfo
    self.onSpaceClick = param.onSpaceClick
    self.onHeroCardClick = param.onHeroCardClick
    self.isPvP = param.isPvP
    ---old

    for i = 1, MAX_HERO_COUNT do
        local heroCardData = self._heroCardData and self._heroCardData[i]
        if heroCardData == nil then
            heroCardData = {}
        end
        heroCardData.slotIndex = i
        heroCardData.editable = param.editable
        heroCardData.limitEdit = param.limitEdit
        heroCardData.simpleMode = param.simpleMode
        heroCardData.onEmptyButtonClick = Delegate.GetOrCreate(self, self.OnEmtpyButtonClick)
		heroCardData.onHeroDeleteClick = Delegate.GetOrCreate(self, self.OnHeroCardDeleteClick)
        self.heroCards[i]:FeedData(heroCardData)

        -- self.heroCardList[i]:FeedData(data)
		-- if (healedHeroList and healedHeroList[heroId]) then
		-- 	self.heroCardList[i]:PlayHealingEffect()
		-- else
		-- 	self.heroCardList[i]:StopHealingEffect()
		-- end
    end
end

function UITroopHeroCardGroupPvpTemp:RefreshHeroData()
    for i = 1, MAX_HERO_COUNT do
        local heroCardData = self._heroCardData and self._heroCardData[i]
        if heroCardData ~= nil then
            self.heroCards[i]:RefreshUI()
        end
    end
end


function UITroopHeroCardGroupPvpTemp:OnEmtpyButtonClick(data)
    if self.onEmptyButtonClick then
        self.onEmptyButtonClick(data)
    end
end

---@param data UITroopHeroCardData
function UITroopHeroCardGroupPvpTemp:OnHeroCardDeleteClick(data)

    local cardData = self._heroCardData[data.slotIndex]
    if cardData == nil or cardData.heroCfgId ~= data.heroCfgId then
        return
    end
    cardData.heroCfgId = 0
    cardData.petCompId = 0
    if self.onHeroCardDataChanged then
        self.onHeroCardDataChanged(self._heroCardData,cardData)
    end

end

---@param heroCard UITroopHeroCard
function UITroopHeroCardGroupPvpTemp:AddHeroCard(heroCard)
    if (heroCard == nil) then
        return
    end
    if (self.heroCards == nil) then
        self.heroCards = {}
    end
    table.insert(self.heroCards, heroCard)
    heroCard:AddClickListener(
        Delegate.GetOrCreate(self,self.OnHeroCardClick),
        Delegate.GetOrCreate(self,self.OnHeroInfoClick),
        Delegate.GetOrCreate(self,self.OnPetClick)
    )
end

---@param data UITroopHeroCardData
function UITroopHeroCardGroupPvpTemp:OnHeroCardClick(data)
    local id = data.heroCfgId
    for key, value in pairs(self.heroCards) do
        if value:GetHeroConfigId() == id then
            if value.showCircleButtons then
                value:CloseCircleMenu()
            else
                value:OpenCircleMenu()
            end
        else
            value:CloseCircleMenu()
        end
    end
    if self.onHeroCardClick then
        self.onHeroCardClick(data)
    end
end

---@param data UITroopHeroCardData
function UITroopHeroCardGroupPvpTemp:OnHeroInfoClick(data)
    self:ShowHerosDetailInCurTroop(data)
end

---@private
---@param data UITroopHeroCardData
function UITroopHeroCardGroupPvpTemp:ShowHerosDetailInCurTroop(data)
	if (not data) then return end
	if (data.heroCfgId and data.heroCfgId > 0) then
        local outList = {}
        for _, value in pairs(self._heroCardData) do
            if value and value.heroCfgId and value.heroCfgId > 0 then
                table.insert(outList, value.heroCfgId)
            end
        end

		g_Game.UIManager:Open(UIMediatorNames.UIHeroMainUIMediator, {
			id = data.heroCfgId,
			outList = outList,
            isPvP = self.isPvP,
            onPetModified = Delegate.GetOrCreate(self, self.OnPetSelected),
		})
	end
end

---@param data UITroopHeroCardData
function UITroopHeroCardGroupPvpTemp:OnPetClick(data)
	local typeList = ModuleRefer.PetModule:GetTypeList()
	local hasPet = false
	if typeList then
		for _, typeId in ipairs(typeList) do
			local count = ModuleRefer.PetModule:GetPetCountByType(typeId)
			if count and count > 0 then
                hasPet = true
            end
        end
    end
    if not hasPet then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("hero_pet_nopet"))
        return
    end

	-- ModuleRefer.TroopModule:ForceHideRedDotPet()
	-- local petId = ModuleRefer.HeroModule:GetHeroLinkPet(data.heroCfgId, self.isPvP)
	-- self._petChangeEffectData = {
	-- 	heroId = data.heroId,
	-- 	petId = petId,
	-- 	troopIndex = self._selectedTroopIndex,
	-- 	slotIndex = data.slotIndex,
	-- }
    local petId = 0
    local heroIdList = {}
    local petLinkInfo = {}
    local petCompIds = {}
    for i = 1, MAX_HERO_COUNT do
        local heroCardData = self._heroCardData[i]
        if heroCardData and heroCardData.heroCfgId and heroCardData.heroCfgId > 0 then
            table.insert(heroIdList,heroCardData.heroCfgId)
            if heroCardData.heroCfgId == data.heroCfgId then
                petId = heroCardData.petCompId
            end
            petLinkInfo[heroCardData.heroCfgId] = heroCardData.petCompId
            if heroCardData.petCompId and heroCardData.petCompId > 0 then
                petCompIds[heroCardData.petCompId] = true
            end
        end
    end

    if self.getOtherPetLinkInfo then
        local otherLinkInfo = self.getOtherPetLinkInfo()
        if otherLinkInfo then
            for petCompId, heroCfgId in pairs(otherLinkInfo) do
                if not petCompIds[petCompId] then
                    if heroCfgId > 0 and not petLinkInfo[heroCfgId] then
                        petLinkInfo[heroCfgId] = petCompId
                    end
                end
            end
        end
    end



	g_Game.UIManager:Open(UIMediatorNames.UIPetCarryMediator, {
		heroId = data.heroCfgId,
		petId = petId,
        heroList = heroIdList,
        petLinkInfo = petLinkInfo,
        isPvP = self.isPvP,
        onPetModified = Delegate.GetOrCreate(self, self.OnPetSelected),
		troopIndex = self._selectedTroopIndex,
        slotIndex = data.slotIndex
	})

    g_Game.EventManager:TriggerEvent(EventConst.TROOP_PET_CLICK, data.heroCfgId)
end

function UITroopHeroCardGroupPvpTemp:OnPetSelected(heroId,petId)
    local hasChangeIndex = nil

    for i = 1, MAX_HERO_COUNT do
        if self._heroCardData[i] and self._heroCardData[i].heroCfgId == heroId then
            self._heroCardData[i].petCompId = petId
            self.heroCards[i]:RefreshUI()
            hasChangeIndex = i
            break
        end
    end

    if hasChangeIndex and self.onHeroCardDataChanged then
        self.onHeroCardDataChanged(self._heroCardData,self._heroCardData[hasChangeIndex])
    end
end

function UITroopHeroCardGroupPvpTemp:RefreshUI()
    for i = 1, MAX_HERO_COUNT do
        self.heroCards[i]:RefreshUI()
    end
end

---@param heroPos CS.UnityEngine.Vector3[]
---@param petPos CS.UnityEngine.Vector3[]
function UITroopHeroCardGroupPvpTemp:SetupHeroAndPetPos(camera,heroPos, petPos)
    for i = 1, MAX_HERO_COUNT do
        if heroPos[i] and petPos[i] then
            self.heroCards[i]:SetFollowWSPosition(camera,heroPos[i], petPos[i])
        end
    end
end

function UITroopHeroCardGroupPvpTemp:OnEmptyClick()
    if self.onSpaceClick then
        self.onSpaceClick()
    end
    for key, value in pairs(self.heroCards) do
        value:CloseCircleMenu()
    end
end

function UITroopHeroCardGroupPvpTemp:OnHeroSelectPanelShowHide(show)
    if show then
        -- self.statusCtrler:ApplyStatusRecord(1)
    else
        -- self.statusCtrler:ApplyStatusRecord(0)
    end
end

return UITroopHeroCardGroupPvpTemp
