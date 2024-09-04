local BaseTableViewProCell = require("BaseTableViewProCell")
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local DBEntityPath = require("DBEntityPath")
local TimeFormatter = require("TimeFormatter")
local GuideUtils = require("GuideUtils")
local LayoutRebuilder = CS.UnityEngine.UI.LayoutRebuilder
local UIMediatorNames = require("UIMediatorNames")
local PetCollectionEnum = require("PetCollectionEnum")
local NotificationType = require("NotificationType")
local PetCollectionPhoto = class('PetCollectionPhoto', BaseTableViewProCell)

function PetCollectionPhoto:OnCreate()
    self.p_base = self:Image('p_base')
    self.petIcon = self:Image('p_icon_pet')
    self.petOutline = self:Image('p_icon_pet_outline')
    self.openIcon = self:Image('p_icon_type')
    self.petIndex = self:Text('p_text_pet_num')
    self.petName = self:Text('p_text_pet_name')
    self.tagIcon = self:Image('p_tag_special')
    self.completeIcon = self:Image('p_complete')
    self.btn = self:Button('', Delegate.GetOrCreate(self, self.OnClick))
    self.child_reddot_default = self:GameObject("child_reddot_default")
end

function PetCollectionPhoto:OnShow()
    self:RegisterEvent()
end

function PetCollectionPhoto:OnHide()
    self:UnregisterEvent()
end

function PetCollectionPhoto:RegisterEvent()
    g_Game.EventManager:AddListener(EventConst.PET_COLLECTION_STORY_RED_POINT, Delegate.GetOrCreate(self, self.RefreshRedPoint))
end

function PetCollectionPhoto:UnregisterEvent()
    g_Game.EventManager:RemoveListener(EventConst.PET_COLLECTION_STORY_RED_POINT, Delegate.GetOrCreate(self, self.RefreshRedPoint))
end

function PetCollectionPhoto:OnFeedData(param)
    self._petIndex = param:Id()
    self.areaIndex = param.areaIndex
    self.pageIndex = param.pageIndex

    self.petIndex.text = param:Id()
    local icon = ConfigRefer.ArtResourceUI:Find(param:ShowPortrait()):Path()

    g_Game.SpriteManager:LoadSprite(icon, self.petIcon)
    g_Game.SpriteManager:LoadSprite(icon, self.petOutline)

    local status = ModuleRefer.PetCollectionModule:GetPetStatus(param)
    if status == PetCollectionEnum.PhotoStatusEnum.Own then
        self.petIcon:SetVisible(true)
        self.petOutline:SetVisible(false)
        self.petName.text = I18N.Get(ConfigRefer.Pet:Find(param:SamplePetCfg()):Name())
    elseif status == PetCollectionEnum.PhotoStatusEnum.Hide then
        self.petIcon:SetVisible(false)
        self.petOutline:SetVisible(true)
        self.petName.text = "?"

    elseif status == PetCollectionEnum.PhotoStatusEnum.CanBuy then
        self.petIcon:SetVisible(true)
        self.petOutline:SetVisible(true)
        self.petName.text = I18N.Get(ConfigRefer.Pet:Find(param:SamplePetCfg()):Name())

    end

    if param:IsVip() then
        g_Game.SpriteManager:LoadSprite("sp_pet_book_base_photo_gold", self.p_base)
    else
        g_Game.SpriteManager:LoadSprite("sp_pet_book_base_photo_white", self.p_base)
    end

    local isComplete = ModuleRefer.PetCollectionModule:IsPetCollectComplete(self._petIndex)
    self.tagIcon:SetVisible(false or param:IsVip())
    self.completeIcon:SetVisible(isComplete)

    self:IsNewPet()
    self:RefreshRedPoint()
end

function PetCollectionPhoto:OnClick()
    if (self.isNewPet) then
        self:IsNewPet()
        self:RefreshRedPoint()
        ModuleRefer.PetCollectionModule:SetRedpoint({self._petIndex})
    end

    g_Game.UIManager:Open(UIMediatorNames.PetCollectionPhotoDetailMediator, {pageIndex = self.pageIndex, petIndex = self._petIndex, areaIndex = self.areaIndex, detailTabIndex = 1})
end

function PetCollectionPhoto:RefreshRedPoint()

end

function PetCollectionPhoto:IsNewPet()
    self.isNewPet = ModuleRefer.PetCollectionModule:GetRedDotStatus(self._petIndex)
    self.child_reddot_default:SetVisible(self.isNewPet)
end

return PetCollectionPhoto
