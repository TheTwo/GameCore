local BaseUIComponent = require('BaseUIComponent')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local UIHelper = require('UIHelper')
local ColorConsts = require('ColorConsts')
local UIMediatorNames = require('UIMediatorNames')

---@class LandformInfoPanelParameter
---@field landCfgId number @LandConfigCell Id

---@class LandformInfoPanel : BaseUIComponent
---@field super BaseUIComponent
local LandformInfoPanel = class("LandformInfoPanel", BaseUIComponent)

function LandformInfoPanel:OnCreate(param)
    --self.goOpen = self:GameObject('p_group_open')
    --self.imgLandform = self:Image('p_img_landform')
    --self.txtLandformName = self:Text('p_text_landform')
    --self.txtLandformStatus = self:Text('p_text_status')

    self.txtLandformDesc = self:Text('p_text_desc')
    
    self.goGroupPet = self:GameObject('p_group_pet')
    self.txtPet = self:Text('p_text_pet', 'searchentity_btn_pet')
    self.tablePet = self:TableViewPro('p_table_pet')

    self.goGroupMonster = self:GameObject('p_group_monster')
    self.txtMonster = self:Text('p_text_monster', 'pet_group_fire_name')
    self.txtMonsterQualityPre = self:Text('p_text_monster_level', 'bw_info_moblevelrange')
    self.txtMonsterQuality = self:Text('p_text_monster_level_num')
    --self.tableMonster = self:TableViewPro('p_table_monster')

    self.goGroupRes = self:GameObject('p_group_egg')
    self.txtRes = self:Text('p_text_egg', 'searchentity_btn_resourcefield_egg')
    self.txtResQualityPre = self:Text('p_text_egg_level', 'bw_info_moblevelrange')
    self.txtResQuality = self:Text('p_text_egg_level_num')
    --self.tableRes = self:TableViewPro('p_table_res')

end

function LandformInfoPanel:OnShow(param)
end

function LandformInfoPanel:OnHide(param)
end

function LandformInfoPanel:FeedData(data)
    self.data = data

    self:RefreshUI()
end

function LandformInfoPanel:RefreshUI()
    local landCfgCell = ConfigRefer.Land:Find(self.data.landCfgId)
    if not landCfgCell then
        return
    end

    --g_Game.SpriteManager:LoadSprite(landCfgCell:Iconbg(), self.imgLandform)
    --self.txtLandformName.text = I18N.Get(landCfgCell:Name())

    --local isPlayerUnlock = ModuleRefer.LandformModule:IsPlayerUnlock(landCfgCell:Id())
    --if not isPlayerUnlock then
    --    self.txtLandformStatus.text = I18N.Get('bw_info_circle_unlock')
    --    self.txtLandformStatus.color = UIHelper.TryParseHtmlString(ColorConsts.quality_white)
    --else
    --    self.txtLandformStatus.text = I18N.Get('bw_info_unlock_newcircle')
    --    self.txtLandformStatus.color = UIHelper.TryParseHtmlString(ColorConsts.army_green)
    --end

    self.txtLandformDesc.text = I18N.Get(landCfgCell:Disc())

    local petCount = landCfgCell:UnlockPetLength()
    local petVilliageCount = landCfgCell:UnlockPetVillageLength()
    local petTotalCount = petCount + petVilliageCount
    self.goGroupPet:SetVisible(petTotalCount > 0)
    if petTotalCount > 0 then
        self.tablePet:Clear()
        for i = 1, petVilliageCount do
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
    end

    local eliteMonsterCount = landCfgCell:UnlockEliteMobLength()
    self.goGroupMonster:SetVisible(eliteMonsterCount > 0)
    if eliteMonsterCount > 0 then
        self.txtMonsterQuality.text = I18N.Get(landCfgCell:DiscEliteMonster())
        --self.tableMonster:Clear()
        --for i = 1, eliteMonsterCount do
        --    local unlockMonster = landCfgCell:UnlockEliteMob(i)
        --    ---@type LandformImageCellData
        --    local monsterCellData = {}
        --    monsterCellData.iconId, monsterCellData.qualityIcon = ModuleRefer.LandformModule:GetMiniIconFromKmonsterDataCfgId(unlockMonster)
        --    monsterCellData.nameKey = ModuleRefer.LandformModule:GetNameFromKmonsterDataCfgId(unlockMonster)
        --    monsterCellData.descKey = ModuleRefer.LandformModule:GetDescFromKmonsterDataCfgId(unlockMonster)
        --    monsterCellData.isMonster = true
        --    monsterCellData.itemGroupId = ModuleRefer.LandformModule:GetRewardsFromKmonsterDataCfgId(unlockMonster)
        --    self.tableMonster:AppendData(monsterCellData)
        --end
    end

    local resCount = landCfgCell:UnlockResourceFieldLength()
    self.goGroupRes:SetVisible(resCount > 0)
    if resCount > 0 then
        self.txtResQuality.text = I18N.Get(landCfgCell:DiscResourceField())
        --self.tableRes:Clear()
        --for i = 1, resCount do
        --    local unlockResourceField = landCfgCell:UnlockResourceField(i)
        --    ---@type LandformImageCellData
        --    local resCellData = {}
        --    resCellData.iconId, resCellData.qualityIcon = ModuleRefer.LandformModule:GetMiniIconFromResourceFieldCfgId(unlockResourceField)
        --    resCellData.nameKey = ModuleRefer.LandformModule:GetNameFromResourceFieldCfgId(unlockResourceField)
        --    resCellData.descKey = ModuleRefer.LandformModule:GetDescFromResourceFieldCfgId(unlockResourceField)
        --    --bossCellData.isMonster = false  
        --    --bossCellData.itemGroupId = ModuleRefer.LandformModule:GetRewardsFromResourceFieldCfgId(unlockBoss)
        --    self.tableRes:AppendData(resCellData)
        --end
    end
end

---点击打开概率分布说明
function LandformInfoPanel:OnPetDetailClick()
    ---@type LandformPetProbabilityMediatorParameter
    local param = {}
    param.landCfgId = self.data.landCfgId
    g_Game.UIManager:Open(UIMediatorNames.LandformPetProbabilityMediator, param)
end

return LandformInfoPanel