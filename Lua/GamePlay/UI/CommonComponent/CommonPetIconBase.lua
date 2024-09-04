local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIHelper = require('UIHelper')
local ConfigRefer = require("ConfigRefer")
local HeroUIUtilities = require('HeroUIUtilities')
local ArtResourceUtils = require('ArtResourceUtils')
local Utils = require("Utils")
local EventConst = require('EventConst')

---@class PetSkillLevelQuality
---@field level number
---@field quality number

---@class CommonPetIconBaseData
---@field id number @宠物ID
---@field cfgId number @宠物配置ID
---@field onClick fun(data: UIPetIconData)
---@field onPressDown fun(data: UIPetIconData)
---@field onPressUp fun(data: UIPetIconData)
---@field selected boolean
---@field level number
---@field rank number
---@field showMask boolean
---@field showDelete boolean
---@field showJobIcon boolean
---@field showLevelPrefix boolean
---@field onDeleteClick fun(data: UIPetIconData)
---@field disabled boolean
---@field onSelect fun(data: UIPetIconData)
---@field onUnselect fun(data: UIPetIconData)
---@field heroId number
---@field skillLevels PetSkillLevelQuality[]

---@class CommonPetIconBase : BaseUIComponent
local CommonPetIconBase = class('CommonPetIconBase', BaseUIComponent)

function CommonPetIconBase:ctor()
    self.isPressing = false
    self.pressingThreshold = 0.2
    self.pressTimer = 0
end

function CommonPetIconBase:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.PET_REFRESH_UNLOCK_STATE, Delegate.GetOrCreate(self, self.RefreshLock))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
end
function CommonPetIconBase:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.PET_REFRESH_UNLOCK_STATE, Delegate.GetOrCreate(self, self.RefreshLock))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function CommonPetIconBase:OnCreate(param)
    self:InitObjects()
end

function CommonPetIconBase:OnTick(dt)
    if not self.isPressing then
        self.pressTimer = 0
        return
    end
    self.pressTimer = self.pressTimer + dt
end

function CommonPetIconBase:InitObjects()
    self:PointerClick("", Delegate.GetOrCreate(self, self.OnClick))
    self:PointerDown("", Delegate.GetOrCreate(self, self.OnPressDown))
    self:PointerUp("", Delegate.GetOrCreate(self, self.OnPressUp))
    self._selected = self:GameObject("p_img_select")
    self._frame = self:Image("p_base_frame")
    self._icon = self:Image("p_img_pet")
    self._textLevel = self:Text("p_text_lv")
    self._mask = self:GameObject("p_img_none")
    self._buttonDelete = self:Button("p_btn_delete", Delegate.GetOrCreate(self, self.OnDeleteClick))
    self._heroNode = self:GameObject("p_hero")
    self._lock = self:GameObject("p_icon_lock")
    ---@type HeroInfoItemComponent
    self._heroComp = self:LuaObject("child_card_hero_s_ex")
    self._p_mask_frame = self:Image('p_mask_frame')
    ---@type UIHeroAssociateIconComponent
    self.compStyle = self:LuaObject('p_icon_style')
    --- @type PetStarLevelComponent
    self.p_star_layout = self:LuaObject('p_star_layout')

    self.p_icon_battle = self:GameObject('p_icon_battle')
    if self._textLevel then
        self._textLevelOutline = self._textLevel.gameObject:GetComponent(typeof(CS.UnityEngine.UI.Outline))
    end

    self.p_check = self:GameObject("p_check")
    self.p_unknown = self:GameObject('p_unknown')
    self.p_img_pet_1 = self:Image('p_img_pet_1')
    self.p_text_none = self:Text('p_text_none', "未拥有")

    self.p_icon_job = self:Image('p_icon_job')
end

---@param data CommonPetIconBaseData
function CommonPetIconBase:OnFeedData(data)
    if (data) then
        self.data = data
        self.id = data.id
        local petDataOrEmpty = (ModuleRefer.PetModule:GetPetByID(data.id) or {})
        self.cfgId = data.cfgId or petDataOrEmpty.ConfigId
        ---@type PetConfigCell
        self.cfg = self.cfgId and ModuleRefer.PetModule:GetPetCfg(self.cfgId) or nil
        self.petTypeCfg = data.petTypeCfg
        self.onClick = data.onClick
        self.selected = data.selected and data.selected or false
        self.level = data.level or petDataOrEmpty.Level
        self.rank = data.rank
        self.showMask = data.showMask
        self.showDelete = data.showDelete
        self.onDeleteClick = data.onDeleteClick
        self.disabled = data.disabled
        self.onSelect = data.onSelect
        self.needSelect = data.needSelect
        self.onUnselect = data.onUnselect
        self.heroId = data.heroId
        self.lockByTeam = data.lockByTeam
        self.manualLock = data.manualLock
        self.isLock = data.isLock
        self.isCheck = data.isCheck
        self.templateIds = data.templateIds or {}
        self.skillLevels = data.skillLevels
        self.multiSelectMode = data.multiSelectMode
        self.cell = data.cell
        self.isUnknown = data.isUnknown
        self.unOwn = data.unOwn
        if Utils.IsNotNull(self.p_icon_battle) then
            self.p_icon_battle:SetVisible(data.isBattle)
        end

        if self.cfg and self.compStyle then
            local tagId = self.cfg:AssociatedTagInfo()
            if tagId > 0 then
                self.compStyle:SetVisible(true)
                self.compStyle:FeedData({tagId = tagId})
            else
                self.compStyle:SetVisible(false)
            end
        end

        if data.id and (not self.heroId) then
            self.heroId = ModuleRefer.PetModule:GetPetLinkHero(data.id)
        end
    end
    self:RefreshUI()
end

function CommonPetIconBase:RefreshUI()
    if self._selected then
        self._selected:SetVisible(self.selected)
    end
    if (self.cfg) then
        local quality = self.cfg:Quality()
        local petIcon = UIHelper.GetFitPetHeadIcon(self._icon, self.cfg)
        g_Game.SpriteManager:LoadSprite(petIcon, self._icon)
        -- local rarityCfg = ConfigRefer.PetRarity:Find(quality)
        -- if (rarityCfg) then
            local frame = HeroUIUtilities.GetQualitySpriteID(quality)
            local frameMask = HeroUIUtilities.GetQualityFrontSpriteID(quality)

            if self._frame then
                g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(frame), self._frame)
            end
            if self._p_mask_frame then
                g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(frameMask), self._p_mask_frame)
            end
        -- end
    elseif self.petTypeCfg then
        g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(self.petTypeCfg:Icon()), self._icon)
    end

    if self._lock then
        if self.id and self.id > 0 then
            self._lock:SetVisible(ModuleRefer.PetModule:IsPetLocked(self.id))
        end
    end

    if self._textLevel then
        local prefix = ""
        if self.data.showLevelPrefix then
            prefix = "Lv."
        end
        if (self.level) then
            self._textLevel.text = prefix .. self.level
        else
            self._textLevel.text = nil
        end
    end

    if self._mask then
        self._mask:SetVisible(self.showMask == true)
    end
    if self._buttonDelete then
        self._buttonDelete.gameObject:SetVisible(self.showDelete == true)
    end

    if self._heroNode then
        if (self.heroId and self.heroId > 0) then
            self._heroNode:SetVisible(true)
            -- local heroData = ModuleRefer.HeroModule:GetHeroByCfgId(self.heroId)
            -- self._heroComp:FeedData({heroData = heroData, hideExtraInfo = true})
        else
            self._heroNode:SetVisible(false)
        end
    end

    if self.p_icon_job then
        if self.data.showJobIcon then   
            self.p_icon_job:SetVisible(true)
            local battleType = HeroUIUtilities.GetHeroBattleTypeTextureName(self.cfg:BattleType())
            if not string.IsNullOrEmpty(battleType) then
                g_Game.SpriteManager:LoadSprite(battleType, self.p_icon_job)
            end
        else
            self.p_icon_job:SetVisible(false)
        end
    end

    if (self.disabled or self.lockByTeam) then
        UIHelper.SetGray(self.CSComponent.gameObject, true)
    else
        UIHelper.SetGray(self.CSComponent.gameObject, false)
    end
    self:SetStars()
    self:RefreshManualLock()
    self:RefreshCheck()
    self:RefreshUnknown()
    self:RefreshUnOwn()
end

function CommonPetIconBase:RefreshCheck()
    if self.p_check then
        self.p_check:SetVisible(self.isCheck)
    end
end

function CommonPetIconBase:RefreshUnknown()
    if self.p_unknown then
        self.p_unknown:SetVisible(self.isUnknown)
        if self.isUnknown then
            local petIcon = UIHelper.GetFitPetHeadIcon(self.p_img_pet_1, self.cfg)
            g_Game.SpriteManager:LoadSprite(petIcon, self.p_img_pet_1)
        end
    end
end

function CommonPetIconBase:RefreshUnOwn()
    if self.p_text_none then
        self.p_text_none:SetVisible(self.unOwn)
    end
end

function CommonPetIconBase:SetCheck(check)
    self.isCheck = check
    self.showMask = check
    self.p_check:SetVisible(self.isCheck)
    self._mask:SetVisible(self.isCheck)
end

function CommonPetIconBase:RefreshLock(petId)
    if petId == self.id then
        self._lock:SetVisible(ModuleRefer.PetModule:IsPetLocked(self.id))
    end
end

function CommonPetIconBase:RefreshManualLock()
    if self.manualLock then
        self._lock:SetVisible(self.isLock)
    end
end

function CommonPetIconBase:OnClick(args)
    if self.pressTimer >= self.pressingThreshold then
        return
    end
    if (not self.disabled and self.onClick) then
        self.onClick(self.data)
    end
end

function CommonPetIconBase:OnPressDown(args)
    if (not self.disabled and self.data.onPressDown) then
        self.isPressing = true
        self.data.onPressDown(self.data)
    end
end

function CommonPetIconBase:OnPressUp(args)
    if (not self.disabled and self.data.onPressUp) then
        self.data.onPressUp(self.data)
        self.isPressing = false
    end
end

function CommonPetIconBase:OnDeleteClick(args)
    if (not self.disabled and self.onDeleteClick) then
        self.onDeleteClick(self.data, self._buttonDelete.transform)
    end
end

function CommonPetIconBase:SetStars()
    if self.p_star_layout then
        if self.id then
            local param = {petId = self.id}
            self.p_star_layout:FeedData(param)
            self.p_star_layout:SetVisible(true)
        elseif self.skillLevels then
            local param = {skillLevels = self.skillLevels}
            self.p_star_layout:FeedData(param)
            self.p_star_layout:SetVisible(true)
        else
            self.p_star_layout:SetVisible(false)
        end
    end
end

function CommonPetIconBase:OnSelect()
    self.selected = true
    self._selected:SetVisible(true)
    if self.onSelect then
        self.onSelect(self.data)
    end
end

function CommonPetIconBase:OnUnselect()
    self.selected = false
    self._selected:SetVisible(false)
    if self.onUnselect then
        self.onUnselect(self.data)
    end
end

function CommonPetIconBase:SetResonate()

end

return CommonPetIconBase

