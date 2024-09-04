local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require('UIMediatorNames')
local NoviceConst = require('NoviceConst')
---@class NoviceBaseDefenseMediator : BaseUIMediator
local NoviceBaseDefenseMediator = class('NoviceBaseDefenseMediator', BaseUIMediator)
---@sence scene_novice_task_main

function NoviceBaseDefenseMediator:OnCreate()
    ---@type NoviceBaseDefenseComponent[]
    self.baseDefComps = {
        self:LuaObject('p_day_1'),
        self:LuaObject('p_day_2'),
        self:LuaObject('p_day_3'),
        self:LuaObject('p_day_4'),
        self:LuaObject('p_day_5'),
    }

    for i, comp in ipairs(self.baseDefComps) do
        comp.compItemNeededQuantity = comp:LuaObject('child_common_quantity_' .. i)
        comp.textLock = comp:Text('p_text_lock_' .. i)
        comp.btnGoto = comp:Button('p_btn_goto_' .. i, Delegate.GetOrCreate(comp, comp.OnBtnGotoClicked))
        comp.imgIconFull = comp:Image('p_icon_full_' .. i)
    end

    self.textTitle = self:Text('p_text_title')
    self.textContent = self:Text('p_text_content')
    self.textProgress = self:Text('p_text_progress')

    self.btnBack = self:LuaObject('child_common_btn_back')
    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))

    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
    self.textGoto = self:Text('p_text_goto')

    self.compProgress = self:LuaObject('progress')
end

function NoviceBaseDefenseMediator:OnOpened(param)
    for i = 1, NoviceConst.MAX_DAY do
        self.baseDefComps[i]:FeedData({ day = i })
    end
    self.textTitle.text = I18N.Get('*基地防御')
    self.textContent.text = I18N.Get('*基地防御，但是字体小了两号')
    self.btnBack:FeedData({
        title = I18N.Get('*基地防御'),
        backBtnFunc = Delegate.GetOrCreate(self, self.OnBtnExitClicked)}
    )
    self.textGoto.text = I18N.Get('*升级任务')
    self.textProgress.text = '0%'
end

function NoviceBaseDefenseMediator:OnBtnBackClicked(args)
    self:CloseSelf()
end

function NoviceBaseDefenseMediator:OnBtnDetailClicked(args)
    local desc = I18N.Get('*基地防御，但是点了才会出现')
    ModuleRefer.ToastModule:ShowTextToast({clickTransform = self.btnDetail.transform, content = desc})
end

function NoviceBaseDefenseMediator:OnBtnGotoClicked(args)
    g_Game.UIManager:Open(UIMediatorNames.NoviceTaskMediator)
end

return NoviceBaseDefenseMediator