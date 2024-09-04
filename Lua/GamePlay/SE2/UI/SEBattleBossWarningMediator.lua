local BaseUIMediator = require ('BaseUIMediator')

---@class SEBattleBossWarningMediator : BaseUIMediator
local SEBattleBossWarningMediator = class('SEBattleBossWarningMediator', BaseUIMediator)

function SEBattleBossWarningMediator:ctor()

end

function SEBattleBossWarningMediator:OnCreate()
    self.textWarning = self:Text('p_text_warning', 'se_warning_boss')
end


function SEBattleBossWarningMediator:OnShow(param)
end

function SEBattleBossWarningMediator:OnHide(param)
end

function SEBattleBossWarningMediator:OnOpened(param)
end

function SEBattleBossWarningMediator:OnClose(param)
end

return SEBattleBossWarningMediator;
