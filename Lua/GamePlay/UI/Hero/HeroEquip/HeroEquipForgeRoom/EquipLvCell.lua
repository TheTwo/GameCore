local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local EventConst = require("EventConst")
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local EquipLvCell = class('EquipLvCell',BaseTableViewProCell)

function EquipLvCell:OnCreate(param)
    self.btnLv = self:Button('p_btn_lv', Delegate.GetOrCreate(self, self.OnBtnLvClicked))
    self.goStatusSelected = self:GameObject('p_status_selected')
    self.textLvSelected = self:Text('p_text_lv_selected')
    self.goStatusN = self:GameObject('p_status_n')
    self.textLvN = self:Text('p_text_lv_n')
    self.goStatusLock = self:GameObject('p_status_lock')
    self.textLvLock = self:Text('p_text_lv_lock')
end

function EquipLvCell:OnFeedData(buildId)
    self.buildId = buildId
    local buildCfg = ConfigRefer.HeroEquipBuild:Find(self.buildId)
    local systemEntry = buildCfg:SystemSwitch()
    self.isUnlock = true
    if systemEntry and systemEntry > 0 then
        self.isUnlock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(systemEntry)
    end
    self.goStatusSelected:SetActive(self.isUnlock)
    self.goStatusN:SetActive(self.isUnlock)
    self.goStatusLock:SetActive(not self.isUnlock)
    self.textLvSelected.text = I18N.Get("T" .. buildCfg:Level() .. "_Forg")
    self.textLvN.text = I18N.Get("T" .. buildCfg:Level() .. "_Forg")
    self.textLvLock.text = I18N.Get("T" .. buildCfg:Level() .. "_Forg")
end

function EquipLvCell:OnBtnLvClicked(args)
    if self.isUnlock then
        g_Game.EventManager:TriggerEvent(EventConst.HERO_SELECT_BUILD, self.buildId)
    else
        local buildCfg = ConfigRefer.HeroEquipBuild:Find(self.buildId)
        local systemEntry = buildCfg:SystemSwitch()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(ConfigRefer.SystemEntry:Find(systemEntry):LockedTips()))
    end
end

function EquipLvCell:Select()
   self.goStatusSelected:SetActive(true)
   self.goStatusN:SetActive(false)
end

function EquipLvCell:UnSelect()
    self.goStatusSelected:SetActive(false)
    self.goStatusN:SetActive(true)
end


return EquipLvCell
