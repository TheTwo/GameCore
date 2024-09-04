local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local HeroEquipForgeUIMediator = class('HeroEquipForgeUIMediator', BaseUIMediator)


function HeroEquipForgeUIMediator:ctor()

end

function HeroEquipForgeUIMediator:OnCreate()
    self.goTabTrainee = self:GameObject('tab_trainee')
    self.btnRoomTrainee = self:Button('p_btn_room_trainee', Delegate.GetOrCreate(self, self.OnBtnRoomTraineeClicked))
    self.imgIconTrainee = self:Image("p_icon_trainee")
    self.textNameTrainee = self:Text('p_text_name_trainee')
    self.textNameSTrainee = self:Text('p_text_name_s_trainee')
    self.goIconLockTrainee = self:GameObject('p_icon_lock_trainee')
    self.goTabJunior = self:GameObject('tab_junior')
    self.btnRoomJunior = self:Button('p_btn_room_junior', Delegate.GetOrCreate(self, self.OnBtnRoomJuniorClicked))
    self.imgIconJunior = self:Image("p_icon_junior")
    self.textNameJunior = self:Text('p_text_name_junior')
    self.textNameSJunior = self:Text('p_text_name_s_junior')
    self.goIconLockJunior = self:GameObject('p_icon_lock_junior')
    self.goTabSenior = self:GameObject('tab_senior')
    self.btnRoomSenior = self:Button('p_btn_room_senior', Delegate.GetOrCreate(self, self.OnBtnRoomSeniorClicked))
    self.imgIconSenior = self:Image("p_icon_senior")
    self.textNameSenior = self:Text('p_text_name_senior')
    self.textNameSSenior = self:Text('p_text_name_s_senior')
    self.goIconLockSenior = self:GameObject('p_icon_lock_senior')
    self.goTabMaster = self:GameObject('tab_master')
    self.btnRoomMaster = self:Button('p_btn_room_master', Delegate.GetOrCreate(self, self.OnBtnRoomMasterClicked))
    self.imgIconMaster = self:Image("p_icon_master")
    self.textNameMaster = self:Text('p_text_name_master')
    self.textNameSMaster = self:Text('p_text_name_s_master')
    self.goIconLockMaster = self:GameObject('p_icon_lock_master')
    self.compChildCommonBack = self:LuaBaseComponent('child_common_btn_back')

    self.btnLocks = {self.goIconLockTrainee, self.goIconLockJunior, self.goIconLockSenior, self.goIconLockMaster}
    self.forgeLevelNames = {self.textNameTrainee, self.textNameJunior, self.textNameSenior, self.textNameMaster}
    self.forgeLevelTitles = {self.textNameSTrainee, self.textNameSJunior, self.textNameSSenior, self.textNameSMaster}
    self.forgeLevelIcons = {self.imgIconTrainee, self.imgIconJunior, self.imgIconSenior, self.imgIconMaster}
end

function HeroEquipForgeUIMediator:OnHide()

end

function HeroEquipForgeUIMediator:OnShow()
    self.compChildCommonBack:FeedData({title = I18N.Get("equip_build")})
    self.forgeLevelList = {}
    local levels = ModuleRefer.HeroModule:GetEquipBuildLevels()
    for index = 1, #levels do
        local level = levels[index]
        local isUnlock = ModuleRefer.HeroModule:CheckHeroEquipForgeIsUnlock(level)
        self.forgeLevelList[#self.forgeLevelList + 1] = {isUnlock = isUnlock , level = level}
        self.btnLocks[index]:SetActive(not isUnlock)
        local levelCfg = ConfigRefer.EquipBuildUnlock:Find(level)
        self.forgeLevelNames[index].text = I18N.Get(levelCfg:Name())
        self.forgeLevelTitles[index].text = I18N.Get(levelCfg:Title())
        self:LoadSprite(levelCfg:Icon(), self.forgeLevelIcons[index])
    end
end

function HeroEquipForgeUIMediator:OnBtnRoomTraineeClicked()
    self:OpenForgeRootUI(1)
end
function HeroEquipForgeUIMediator:OnBtnRoomJuniorClicked()
    self:OpenForgeRootUI(2)
end
function HeroEquipForgeUIMediator:OnBtnRoomSeniorClicked()
    self:OpenForgeRootUI(3)
end
function HeroEquipForgeUIMediator:OnBtnRoomMasterClicked()
    self:OpenForgeRootUI(4)
end

function HeroEquipForgeUIMediator:OpenForgeRootUI(index)
    local forgeLevel = self.forgeLevelList[index]
    if forgeLevel.isUnlock then
        g_Game.UIManager:Open('HeroEquipForgeRoomUIMediator')
    else
        local forgeCfg = ConfigRefer.EquipBuildUnlock:Find(forgeLevel.level)
        local furnitureName = I18N.Get(ConfigRefer.CityFurnitureTypes:Find(forgeCfg:Furniture()):Name())
        local unlockLevel = ConfigRefer.CityFurnitureLevel:Find(forgeCfg:Level()):Level()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("equip_build_unlock", furnitureName, unlockLevel))
    end

end

return HeroEquipForgeUIMediator