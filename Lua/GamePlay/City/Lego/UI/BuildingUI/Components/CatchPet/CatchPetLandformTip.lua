local I18N = require('I18N')
local BaseUIMediator = require("BaseUIMediator")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require('KingdomMapUtils')
local EventConst = require('EventConst')
local TimerUtility = require('TimerUtility')

---@class CatchPetLandformTipParameter
---@field landCfgId number @LandConfigCell Id
---@field needGoto boolean @是否需要跳转到地形

---@class CatchPetLandformTip:BaseUIMediator
---@field new fun():CatchPetLandformTip
---@field super BaseUIMediator
local CatchPetLandformTip = class('CatchPetLandformTip', BaseUIMediator)

---@param param CatchPetLandformTipParameter
function CatchPetLandformTip:OnCreate(param)
    self.landCfgId = param.landCfgId
    self.needGoto = param.needGoto or false
    self.hideAll = param.hideAll or false

    self.imgBanner = self:Image('p_banner_landform')
    self.txtTitle = self:Text('p_text_title')
    self.txtDesc = self:Text('p_text_desc')
    self.txtPetSubtitle = self:Text('p_text_subtitle', 'pet_drone_available_pets_name')
    self.tablePet = self:TableViewPro('p_table_pet')
    self.btnPetProbability = self:Button('p_btn_info', Delegate.GetOrCreate(self, self.OnPetProbabilityClick))
    self.petObj = self:GameObject('pet')
    self.p_btn = self:GameObject('p_btn')
    self.p_btn_goto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnClickGoto))
    self.p_text_goto = self:Text('p_text_goto', 'bw_btn_goto_landmod')
end

function CatchPetLandformTip:OnShow(param)
    self.content = param.content
    self.title = param.title
    self:RefreshUI()
    if self.needGoto then
        self.petObj:SetVisible(false)
        self.p_btn:SetVisible(true)
    elseif self.hideAll then
        self.petObj:SetVisible(false)
        self.p_btn:SetVisible(false)
    else
        self.petObj:SetVisible(true)
        self.p_btn:SetVisible(false)
    end
end

function CatchPetLandformTip:OnHide(param)

end

function CatchPetLandformTip:RefreshUI()
    local landCfgCell = ConfigRefer.Land:Find(self.landCfgId)

    g_Game.SpriteManager:LoadSprite(landCfgCell:Iconbg(), self.imgBanner)
    self.txtTitle.text = self.title ~= nil and self.title or I18N.Get(landCfgCell:Name())
    self.txtDesc.text = self.content ~= nil and self.content or I18N.Get(landCfgCell:Disc())

    --宠物图鉴复用时，不用往下走了
    if self.hideAll or self.needGoto then
        return
    end

    self.tablePet:Clear()
    local petCount = landCfgCell:UnlockPetLength()
    local petVillageCount = landCfgCell:UnlockPetVillageLength()
    for i = 1, petVillageCount do
        local unlockPet = landCfgCell:UnlockPetVillage(i)
        ---@type LandformImageCellData
        local petCellData = {}
        petCellData.iconId = ModuleRefer.LandformModule:GetMiniIconFromPetCfgId(unlockPet)
        petCellData.nameKey = ModuleRefer.LandformModule:GetNameFromPetCfgId(unlockPet)
        petCellData.descKey = ModuleRefer.LandformModule:GetDescFromPetCfgId(unlockPet)
        petCellData.isVillagePet = true
        self.tablePet:AppendData(petCellData)
    end
    for i = 1, petCount do
        local unlockPet = landCfgCell:UnlockPet(i)
        ---@type LandformImageCellData
        local petCellData = {}
        petCellData.iconId = ModuleRefer.LandformModule:GetMiniIconFromPetCfgId(unlockPet)
        petCellData.nameKey = ModuleRefer.LandformModule:GetNameFromPetCfgId(unlockPet)
        petCellData.descKey = ModuleRefer.LandformModule:GetDescFromPetCfgId(unlockPet)
        self.tablePet:AppendData(petCellData)
    end
end

function CatchPetLandformTip:OnPetProbabilityClick()
    ---@type LandformPetProbabilityMediatorParameter
    local param = {}
    param.landCfgId = self.landCfgId
    g_Game.UIManager:Open(UIMediatorNames.LandformPetProbabilityMediator, param)
end

function CatchPetLandformTip:OnClickGoto()
    --local scene = g_Game.SceneManager.current
    --local duration = 2
    --
    --g_Game.UIManager:CloseByName(UIMediatorNames.PetCollectionPhotoDetailMediator)
    --g_Game.UIManager:CloseByName(UIMediatorNames.PetCollectionPhotoMediator)
    --g_Game.UIManager:CloseByName(UIMediatorNames.UIPetMediator)
    --g_Game.UIManager:CloseByName(UIMediatorNames.CatchPetLandformTip)
    --g_Game.UIManager:CloseByName(UIMediatorNames.RadarMediator)
    --
    --if scene:IsInCity() then
    --    local callback = function()
    --        KingdomMapUtils.GetBasicCamera():ForceGiveUpTween()
    --        KingdomMapUtils.GetBasicCamera():ZoomToMaxSize(duration)
    --        TimerUtility.DelayExecute(function()
    --            g_Game.EventManager:TriggerEvent(EventConst.OPEN_LANDFORM_VIEW)
    --            g_Game.EventManager:TriggerEvent(EventConst.ON_LANDFORM_SELECT, self.landCfgId)
    --        end, duration)
    --    end
    --    scene:LeaveCity(callback)
    --else
    --    KingdomMapUtils.GetBasicCamera():ForceGiveUpTween()
    --    KingdomMapUtils.GetBasicCamera():ZoomToMaxSize(duration)
    --    TimerUtility.DelayExecute(function()
    --        g_Game.EventManager:TriggerEvent(EventConst.OPEN_LANDFORM_VIEW)
    --        g_Game.EventManager:TriggerEvent(EventConst.ON_LANDFORM_SELECT, self.landCfgId)
    --    end, duration)
    --end
    
    self:CloseSelf()
    g_Game.UIManager:Open(UIMediatorNames.LandformIntroUIMediator)
end

return CatchPetLandformTip
