local BaseTableViewProCell = require("BaseTableViewProCell")
local UIHelper = require("UIHelper")
local ColorConsts = require("ColorConsts")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
---@class UITroopPetSelectionCell : BaseTableViewProCell
local UITroopPetSelectionCell = class("UITroopPetSelectionCell", BaseTableViewProCell)

---@class UITroopPetSelectionCellData
---@field hp number
---@field maxHpAddPct number
---@field oriMaxHpAddPct number
---@field petId number
---@field selected boolean
---@field otherTeamIndex number
---@field hasSameType boolean
---@field onClick fun(data:UITroopPetSelectionCellData)

function UITroopPetSelectionCell:ctor()
    self.tick = false
    self.tickTimer = 0
    self.longPressTime = 0.7
    self.shortPressTime = 0.2

    self.pointerDown = false
end

function UITroopPetSelectionCell:OnCreate()
    self.goRoot = self:GameObject("")
    self.statusCtrler = self:StatusRecordParent("p_state_ctrl")
    ---@see CommonPetIcon
    self.luaPetIcon = self:LuaObject("child_card_pet_s")
    self.goCurrentTeam = self:GameObject("p_img_current_team")
    self.goHp = self:GameObject("p_hp")
    self.sliderHp = self:Slider("p_troop_hp")

    self.goOtherTeam = self:GameObject("p_base_other_team")
    self.textTeamIndex = self:Text("p_text_team_index")

    self.goInjured = self:GameObject("p_injuried")
    self.textInjured = self:Text('p_text_injuried','formation_injuring')

    self.luaReddot = self:LuaObject("child_reddot_default")

    self.goProgressCircle = self:GameObject("child_progress_circle")

    self.goHasSameType = self:GameObject("p_similar")
    self.goWorking = self:GameObject("p_work")
    self.textWork = self:Text("p_text_work")

    self.rectTransform = self:RectTransform("")

    self.goCircleTimer = self:GameObject("child_progress_circle")
	self.imgCircleProgress = self:Image("p_progress")
end

---@param data UITroopPetSelectionCellData
function UITroopPetSelectionCell:OnFeedData(data)
    if not data then return end
    self.data = data

    self.goProgressCircle:SetActive(false)
    self.goCurrentTeam:SetActive(data.selected)
    self.goOtherTeam:SetActive(not data.selected and data.otherTeamIndex > 0)
    self.textTeamIndex.text = data.otherTeamIndex
    UIHelper.SetGray(self.goRoot, self.goOtherTeam.activeSelf)

    self.goHp:SetActive(true)
    local hp = ModuleRefer.TroopModule:GetTroopPetHp(data.petId)
	local oriHpMax = ModuleRefer.TroopModule:GetTroopPetHpMax(data.petId, data.oriMaxHpAddPct or 0)
	local hpMax = ModuleRefer.TroopModule:GetTroopPetHpMax(data.petId, data.maxHpAddPct or 0)
	hp = math.floor((hp / oriHpMax) * hpMax)
	local battleMinHpPct = ConfigRefer.ConstMain:PresetBattleHeroHpPercentThreshold() / 100
	local isInjured = (hp <= math.floor(hpMax * battleMinHpPct))

    self.sliderHp.value = hp / hpMax
    self.goInjured:SetActive(isInjured)

    ---@type CommonPetIconBaseData
    local petIconData = {}
    petIconData.id = data.petId
    petIconData.onClick = Delegate.GetOrCreate(self, self.OnClick)
    petIconData.onPressDown = Delegate.GetOrCreate(self, self.OnPressDown)
    petIconData.onPressUp = Delegate.GetOrCreate(self, self.OnPressUp)
    petIconData.showJobIcon = true
    petIconData.showLevelPrefix = true
    self.luaPetIcon:FeedData(petIconData)

    self.goHasSameType:SetActive(data.hasSameType and not data.selected)

    local city = ModuleRefer.CityModule:GetMyCity()
    local isWorking = city.petManager:IsAssignedOnFurniture(data.petId)
    local workingStatusStr = I18N.Get("ui_ufo_working")
    self.goWorking:SetActive(isWorking and not data.hasSameType)
    self.textWork.text = workingStatusStr

    self.data.isWorking = isWorking
end

function UITroopPetSelectionCell:OnShow()
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function UITroopPetSelectionCell:OnHide()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function UITroopPetSelectionCell:OnRecycle()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function UITroopPetSelectionCell:OnTick(dt)
    if not self.tick then return end
    self.tickTimer = self.tickTimer + dt
    self.goCircleTimer:SetActive(self.tickTimer >= self.shortPressTime)
	local precent = self.tickTimer / self.longPressTime
	self.imgCircleProgress.fillAmount = precent
end

function UITroopPetSelectionCell:OnClick()
    if self.data and self.data.onClick then
        self.data.onClick(self.data)
    end
end

function UITroopPetSelectionCell:OnPressDown()
    self.tick = true
    self.tickTimer = 0
    if self.pointerDown then
        return
    end
    self.pointerDown = true
end

function UITroopPetSelectionCell:OnPressUp()
    if not self.pointerDown then
        return
    end
    self.pointerDown = false
    if self.tickTimer < self.longPressTime then
        -- self:OnClick()
    else
        ---@type UITroopPetCellDetailParam
        local data = {}
        data.petId = self.data.petId
        data.rectTransform = self.rectTransform
        g_Game.UIManager:Open(UIMediatorNames.UITroopPetCellDetailMediator, data)
    end

    self.tick = false
    self.tickTimer = 0
    self.goCircleTimer:SetActive(false)
end

return UITroopPetSelectionCell