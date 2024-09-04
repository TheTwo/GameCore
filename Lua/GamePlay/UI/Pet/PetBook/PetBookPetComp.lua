local BaseTableViewProCell = require("BaseTableViewProCell")
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local PetBookPetComp = class('PetBookPetComp', BaseTableViewProCell)
local ConfigRefer = require("ConfigRefer")
local UIHelper = require('UIHelper')
local HeroUIUtilities = require('HeroUIUtilities')
local PetCollectionEnum = require('PetCollectionEnum')
local NotificationType = require('NotificationType')

function PetBookPetComp:OnCreate()
    self.statusRecordParent = self:StatusRecordParent("")

    self.p_img_frame = self:Image('p_img_frame')
    self.p_text_pet_name = self:Text('p_text_pet_name')

    self.p_progress = self:Slider('p_progress')
    self.p_text_level = self:Text('p_text_level')

    self.p_img_pet = self:Image('p_img_pet')
    self.p_text_unknown = self:Text('p_text_unknown', '? ? ?')

    self.p_text_num = self:Text('p_text_num')
    self.p_img_select = self:GameObject('p_img_select')
    self.p_btn_pet = self:Button('p_btn_pet', Delegate.GetOrCreate(self, self.OnBtnClick))
    self.child_reddot_default = self:LuaObject("child_reddot_default")
end

function PetBookPetComp:OnShow()

end

function PetBookPetComp:OnHide()

end

function PetBookPetComp:OnFeedData(param)
    self.selected = param.selected
    self.param = param
    self.onClick = param.onClick
    self.p_text_num.text = ModuleRefer.PetCollectionModule:GetPetBookId(param:PetBookId())

    local petCfg = ConfigRefer.Pet:Find(param:SamplePetCfg())
    self.p_text_pet_name.text = I18N.Get(petCfg:Name())
    local icon = ConfigRefer.ArtResourceUI:Find(param:Icon()):Path()
    g_Game.SpriteManager:LoadSprite(icon, self.p_img_pet)
    local status = ModuleRefer.PetCollectionModule:GetPetStatus(param)
    self.status = status
    if status == PetCollectionEnum.PetStatus.Own then
        self.statusRecordParent:SetState(2)

        local quality = petCfg:Quality()
        local sprite = ModuleRefer.PetCollectionModule:GetFrameByQuality(quality)
        g_Game.SpriteManager:LoadSprite(sprite, self.p_img_frame)
        -- 宠物研究
        local level = 1
        local exp = 0
        local researchData = ModuleRefer.PetCollectionModule:GetResearchData(param:Id())
        if researchData then
            level = researchData.Level
            exp = researchData.Exp
        end
        local cfg = ModuleRefer.PetCollectionModule:GetResearchConfig(param:Id())
        local maxExp = ModuleRefer.PetCollectionModule:GetMaxExp(cfg, level)
        self.p_progress.value = exp / maxExp
        self.p_text_level.text = level

        self.p_img_pet.color = CS.UnityEngine.Color.white
        UIHelper.SetGray(self.p_img_pet.gameObject, false)
    elseif status == PetCollectionEnum.PetStatus.NotOwn then
        self.statusRecordParent:SetState(1)
        self.p_img_pet.color = CS.UnityEngine.Color.white
        UIHelper.SetGray(self.p_img_pet.gameObject, true)

    elseif status == PetCollectionEnum.PetStatus.Lock then
        self.statusRecordParent:SetState(0)
        self.p_img_pet.color = CS.UnityEngine.Color(0, 0, 0, 0.3)

    end

    self.p_img_select:SetVisible(self.selected)
    self:RefreshRedDot()
end

function PetBookPetComp:RefreshRedDot()
    local param = self.param
    if self.status == PetCollectionEnum.PetStatus.NotOwn then
        self.isNew = ModuleRefer.PetCollectionModule:GetRedDotStatus(param:Id())
    else
        self.isNew = false
    end
    if self.isNew then
        local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PetStory_New_" .. param:Id(), NotificationType.PET_STORY)
        ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(node, 1)
        ModuleRefer.NotificationModule:AttachToGameObject(node, self.child_reddot_default.go, self.child_reddot_default.redNew, self.child_reddot_default.redText)
    else
        local petStoryNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PetStory_" .. param:Id(), NotificationType.PET_STORY)
        ModuleRefer.NotificationModule:AttachToGameObject(petStoryNode, self.child_reddot_default.go, self.child_reddot_default.redTextGo, self.child_reddot_default.redText)
    end
end

function PetBookPetComp:OnBtnClick()
    if self.onClick then
        self.onClick(self.param)
        if self.isNew then
            self.isNew = false
            local node = ModuleRefer.NotificationModule:GetDynamicNode("PetStory_New_" .. self.param:Id(), NotificationType.PET_STORY)
            if node then
                ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(node, 0)
                ModuleRefer.NotificationModule:RemoveFromGameObject(self.child_reddot_default.go, false)
                ModuleRefer.PetCollectionModule:SetRedpoint({self.param:Id()})
            end
            -- self:RefreshRedDot()
        end
    end
end

function PetBookPetComp:Select()
    self.selected = true
    self.p_img_select:SetVisible(self.selected)
end

function PetBookPetComp:UnSelect()
    self.selected = false
    self.p_img_select:SetVisible(self.selected)
end

return PetBookPetComp
