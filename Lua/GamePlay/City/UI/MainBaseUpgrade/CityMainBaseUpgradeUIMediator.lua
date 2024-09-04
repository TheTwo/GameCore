---Scene Name : scene_build_popup_upgrade_successful
local BaseUIMediator = require ('BaseUIMediator')
local StateMachine = require('StateMachine')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class CityMainBaseUpgradeUIMediator:BaseUIMediator
local CityMainBaseUpgradeUIMediator = class('CityMainBaseUpgradeUIMediator', BaseUIMediator)
local CityMainBaseUpgradeI18N = require("CityMainBaseUpgradeI18N")

function CityMainBaseUpgradeUIMediator:OnCreate()
    self._status_open = self:GameObject("status_open")
    self._p_text_title_open = self:Text("p_text_title_open", CityMainBaseUpgradeI18N.TITLE)
    self._p_text_lv = self:Text("p_text_lv", CityMainBaseUpgradeI18N.UI_HINTLEVEL)
    self._p_text_lv_open = self:Text("p_text_lv_open")

    self._p_text_content_1 = self:Text("p_text_content_1", CityMainBaseUpgradeI18N.EFFECT_1)
    
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnContinueClick))
    self._p_text_continue = self:Text("p_text_continue", CityMainBaseUpgradeI18N.UIHINT_TAP_TO_CONDINUE)

    ---@see CityMainBaseUpgradeNewFurCell
    ---@see CityMainBaseUpgradePropertyCell
    ---@see CityMainBaseUpgradeUILvCell
    self._p_table_content = self:TableViewPro("p_table_content")

    self._trigger = self:AnimTrigger("trigger")
end

---@param furniture CityFurniture
function CityMainBaseUpgradeUIMediator:OnOpened(furniture)
    self.furniture = furniture
    self._p_text_lv_open.text = ("%02d"):format(furniture.level)
    
    ---@type NewBaseUpgradeUIDataConfigCell
    self.lvCfg = nil
    for _, cfg in ConfigRefer.NewBaseUpgradeUIData:ipairs() do
        if cfg:Level() == furniture.level then
            self.lvCfg = cfg
            break
        end
    end

    self.stateMachine = StateMachine.new()
    self.stateMachine:AddState("ShowProperty", require("CMBUStateShowPropertyState").new(self))
    self.stateMachine:AddState("ShowLv", require("CMBUStateShowLvState").new(self))
    self.stateMachine:AddState("ShowFurniture", require("CMBUStateShowFurnitureState").new(self))
    self._p_table_content:Clear()

    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnFrameTicker))
    self._trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, Delegate.GetOrCreate(self, self.OnAnimFinished))

    g_Game.SoundManager:Play("sfx_ui_finish_town_levelup")
end

function CityMainBaseUpgradeUIMediator:OnClose()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnFrameTicker))
end

function CityMainBaseUpgradeUIMediator:OnContinueClick()
    if self.stateMachine.currentState then
        self.stateMachine.currentState:OnContinueClick()
    end
end

function CityMainBaseUpgradeUIMediator:OnAnimFinished()
    self.stateMachine:ChangeState("ShowProperty")
end

function CityMainBaseUpgradeUIMediator:OnFrameTicker(delta)
    self.stateMachine:Tick(delta)
end

function CityMainBaseUpgradeUIMediator:ShowTapToContinue()
    self._p_btn_close:SetVisible(true)
    self._p_text_continue:SetVisible(true)
end

return CityMainBaseUpgradeUIMediator