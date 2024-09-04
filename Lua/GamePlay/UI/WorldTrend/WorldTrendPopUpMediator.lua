local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local UIMediatorNames = require("UIMediatorNames")
local PopUpWindomParameter = require('PopUpWindomParameter')
local EarthRevivalDefine = require('EarthRevivalDefine')

---@class WorldTrendPopUpMediator : BaseUIMediator
local WorldTrendPopUpMediator = class('WorldTrendPopUpMediator', BaseUIMediator)

function WorldTrendPopUpMediator:OnCreate()
    self.p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickGoTo))
    self.child_btn_close = self:Button("child_btn_close", Delegate.GetOrCreate(self, self.OnClickClose))

    self.p_text_title = self:Text('p_text_title')
    self.p_text_info = self:Text('p_text_info')
    self.p_text = self:Text('p_text')

    self.imgBackground = self:Image('p_img')
    self.textPeriod = self:Text('p_text_period')
    self.textPeriodNum = self:Text('p_text_period_number')

    self.tableviewproNewSystem = self:TableViewPro("p_table_systems")
    self.goSystems = self:GameObject("p_table_systems")
end

function WorldTrendPopUpMediator:OnOpened(Params)
    self.p_text.text = I18N.Get("goto")

    local worldStage = 1
    if Params and Params.popIds then
        local config = ConfigRefer.PopUpWindow:Find(Params.popIds[1])
        worldStage = config:RefWorldStage()
        self.popIds = Params.popIds
    end
    local configInfo = ConfigRefer.WorldStage:Find(worldStage)
    if not configInfo then
        return
    end
    if configInfo:StageBackgroundLength() > 0 then
        g_Game.SpriteManager:LoadSprite(configInfo:StageBackground(1), self.imgBackground)
    end
    self.textPeriod.text = I18N.Get(configInfo:Name())
    local stage = tonumber(configInfo:Stage())
    if stage < 10 then
        self.textPeriodNum.text = string.format("0%d", stage)
    else
        self.textPeriodNum.text = I18N.Get(configInfo:Stage())
    end
    if worldStage == 1 then
        self.p_text_title.text = I18N.Get("WorldStage_push_1")
        self.p_text_info.text = I18N.Get("WorldStage_push_2")
    else
        self.p_text_title.text = I18N.Get("WorldStage_push_3")
        self.p_text_info.text = I18N.Get("WorldStage_push_4")
    end
    self.tableviewproNewSystem:Clear()
    if configInfo:UnlockSystemsLength() > 0 then
        for i = 1, configInfo:UnlockSystemsLength() do
            self.tableviewproNewSystem:AppendData(configInfo:UnlockSystems(i))
        end
        self.goSystems:SetActive(true)
    else
        self.goSystems:SetActive(false)
    end
end

function WorldTrendPopUpMediator:OnClose()
    ModuleRefer.LoginPopupModule:OnPopupShown(self.popIds)
end

function WorldTrendPopUpMediator:OnClickGoTo()
    g_Game.UIManager:Open(UIMediatorNames.WorldTrendTimeLineMediator)
end

function WorldTrendPopUpMediator:OnClickClose()
    g_Game.UIManager:CloseByName(UIMediatorNames.WorldTrendPopUpMediator)
end

return WorldTrendPopUpMediator
