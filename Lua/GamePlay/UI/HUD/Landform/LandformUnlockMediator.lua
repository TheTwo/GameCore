local I18N = require('I18N')
local BaseUIMediator = require("BaseUIMediator")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")

---@class LandformUnlockMediatorParameter
---@field landCfgId number @LandConfigCell Id

---@class LandformUnlockMediator:BaseUIMediator
---@field new fun():LandformUnlockMediator
---@field super BaseUIMediator
local LandformUnlockMediator = class('LandformUnlockMediator', BaseUIMediator)

local CLOSE_DELAY = 3

---@param param LandformUnlockMediatorParameter
function LandformUnlockMediator:OnCreate(param)
    self.landCfgid = param.landCfgId

    self.imgLandform = self:Image('p_img_landform')
    self.txtUnlock = self:Text('p_text_unlock', 'bw_newcircle_info_1')
    self.txtName = self:Text('p_text_landform')
    self.txtUnlockLandformDesc = self:Text('p_text_hint')
    self.txtUnlockPet = self:Text('p_text_pet', 'bw_newcircle_info_3')
    self.txtUnlockMonster = self:Text('p_text_monster', 'pet_group_fire_name')
    self.txtUnlockRes = self:Text('p_text_res', 'searchentity_btn_resourcefield_egg')

    self.tablePet = self:TableViewPro('p_table_pet')
    self.tableMonster = self:TableViewPro('p_table_monster')
    self.tableRes = self:TableViewPro('p_table_boss')

    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnCloseClick))
    self.txtContinue = self:Text('p_text_continue', 'bw_tips_newcircle_2')
end

function LandformUnlockMediator:OnShow(param)
    self:RefreshUI()

    self.canClose = false
    self.timeLeft = CLOSE_DELAY
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
end

function LandformUnlockMediator:OnHide(param)
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
end

---@param delta number @秒
function LandformUnlockMediator:OnFrameTick(delta)
    self.timeLeft = self.timeLeft - delta
    if self.timeLeft > 0 then
        self.canClose = false
        self.txtContinue.text = I18N.GetWithParams('bw_tips_newcircle_1', math.ceil(self.timeLeft))
    else
        self.canClose = true
        self.txtContinue.text = I18N.Get('bw_tips_newcircle_2')
    end
end

function LandformUnlockMediator:RefreshUI()
    local landCfgCell = ConfigRefer.Land:Find(self.landCfgid)
    g_Game.SpriteManager:LoadSprite(landCfgCell:Icon(), self.imgLandform)
    self.txtName.text = I18N.Get(landCfgCell:Name())
    self.txtUnlockLandformDesc.text = I18N.Get(landCfgCell:Disc())

    self.tablePet:Clear()
    local petCount = landCfgCell:UnlockPetLength()
    local petVillageCount = landCfgCell:UnlockPetVillageLength()
    for i = 1, petVillageCount do
        local unlockPet = landCfgCell:UnlockPetVillage(i)
        ---@type LandformImageCellData
        local petCellData = {}
        petCellData.iconId, petCellData.qualityIcon = ModuleRefer.LandformModule:GetMiniIconFromPetCfgId(unlockPet)
        petCellData.nameKey = ModuleRefer.LandformModule:GetNameFromPetCfgId(unlockPet)
        petCellData.descKey = ModuleRefer.LandformModule:GetDescFromPetCfgId(unlockPet)
        petCellData.isVillagePet = true
        self.tablePet:AppendData(petCellData)
    end
    for i = 1, petCount do
        local unlockPet = landCfgCell:UnlockPet(i)
        ---@type LandformImageCellData
        local petCellData = {}
        petCellData.iconId, petCellData.qualityIcon = ModuleRefer.LandformModule:GetMiniIconFromPetCfgId(unlockPet)
        petCellData.nameKey = ModuleRefer.LandformModule:GetNameFromPetCfgId(unlockPet)
        petCellData.descKey = ModuleRefer.LandformModule:GetDescFromPetCfgId(unlockPet)
        petCellData.isPetItem = true
        petCellData.petItemID = ModuleRefer.LandformModule:GetItemIDFromPetCfgId(unlockPet)
        self.tablePet:AppendData(petCellData)
    end

    self.tableMonster:Clear()
    local monsterCount = landCfgCell:UnlockEliteMobLength()
    for i = 1, monsterCount do
        local unlockMonster = landCfgCell:UnlockEliteMob(i)
        ---@type LandformImageCellData
        local monsterCellData = {}
        monsterCellData.iconId, monsterCellData.qualityIcon = ModuleRefer.LandformModule:GetMiniIconFromKmonsterDataCfgId(unlockMonster)
        monsterCellData.nameKey = ModuleRefer.LandformModule:GetNameFromKmonsterDataCfgId(unlockMonster)
        monsterCellData.descKey = ModuleRefer.LandformModule:GetDescFromKmonsterDataCfgId(unlockMonster)
        monsterCellData.isMonster = true
        monsterCellData.itemGroupId = ModuleRefer.LandformModule:GetRewardsFromKmonsterDataCfgId(unlockMonster)
        self.tableMonster:AppendData(monsterCellData)
    end

    local resCount = landCfgCell:UnlockResourceFieldLength()
    self.tableRes:Clear()
    for i = 1, resCount do
        local unlockResourceField = landCfgCell:UnlockResourceField(i)
        ---@type LandformImageCellData
        local resCellData = {}
        resCellData.iconId, resCellData.qualityIcon = ModuleRefer.LandformModule:GetMiniIconFromResourceFieldCfgId(unlockResourceField)
        resCellData.nameKey = ModuleRefer.LandformModule:GetNameFromResourceFieldCfgId(unlockResourceField)
        resCellData.descKey = ModuleRefer.LandformModule:GetDescFromResourceFieldCfgId(unlockResourceField)
        --bossCellData.isMonster = false  
        --bossCellData.itemGroupId = ModuleRefer.LandformModule:GetRewardsFromResourceFieldCfgId(unlockBoss)
        self.tableRes:AppendData(resCellData)
    end
end

function LandformUnlockMediator:OnCloseClick()
    if self.canClose then
        self:CloseSelf()
    end
end

return LandformUnlockMediator