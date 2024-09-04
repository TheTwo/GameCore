local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local TimerUtility = require('TimerUtility')

---@class NewFunctionUnlockMediator : BaseUIMediator
local NewFunctionUnlockMediator = class('NewFunctionUnlockMediator', BaseUIMediator)

---@class NewFunctionUnlockParam
---@field FunctionId number

function NewFunctionUnlockMediator:OnCreate()
    self.imgFunction = self:Image('p_icon')
    self.txtFunctionName = self:Text('p_text_name')
    self.textUnlock = self:Text('p_text_unlock', I18N.Get("system_unlock_title"))
    self.textUnlockNew = self:Text('p_text_new', I18N.Get("system_unlock_new"))
end

---@param param NewFunctionUnlockParam
function NewFunctionUnlockMediator:OnOpened(param)
    if not param then
        return
    end

    self.param = param
    self:InitNewFunctionInfo(param)
end


function NewFunctionUnlockMediator:OnClose(param)
    if self.param and self.param.FunctionId then
        ModuleRefer.NewFunctionUnlockModule:ShowUnlockNewFunction(self.param.FunctionId)
    end
    self:StopTimer()
end

function NewFunctionUnlockMediator:StopTimer()
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function NewFunctionUnlockMediator:InitNewFunctionInfo(param)
    local cfg = ConfigRefer.SystemEntry:Find(param.FunctionId)
    if not cfg then
        return
    end

    g_Game.SpriteManager:LoadSprite(cfg:Icon(), self.imgFunction)
    self.txtFunctionName.text = I18N.Get(cfg:Name())

    -- self:StopTimer()
    if not self.timer then
        self.timer = TimerUtility.DelayExecute(function()
            ModuleRefer.NewFunctionUnlockModule:ShowUnlockNewFunction(param.FunctionId)
            self:CloseSelf()
        end, 4)
    end
end


return NewFunctionUnlockMediator