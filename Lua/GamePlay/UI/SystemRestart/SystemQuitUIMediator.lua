---Scene Name : scene_common_popup_quit
local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require("Delegate")
local I18N_TEMP = require("I18N_TEMP")

---@class SystemQuitUIMediator : BaseUIMediator
local SystemQuitUIMediator = class('SystemQuitUIMediator', BaseUIMediator)

function SystemQuitUIMediator:OnCreate()
    self._p_text_confirm_detail = self:Text("p_text_confirm_detail", I18N_TEMP.hint_not_support_device)
    self._p_btn_confirm_b = self:Button("p_btn_confirm_b", Delegate.GetOrCreate(self, self.OnQuit))
    self._p_btn_confirm_b_lb = self:Text("p_btn_confirm_b_lb", I18N_TEMP.hint_close_game)
end

function SystemQuitUIMediator:OnOpened(param)

end

function SystemQuitUIMediator:OnClose()

end

function SystemQuitUIMediator:OnQuit()
    g_Game:QuitGame()
end

return SystemQuitUIMediator