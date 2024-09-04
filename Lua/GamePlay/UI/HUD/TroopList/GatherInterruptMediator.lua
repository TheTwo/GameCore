---scene:scene_popup_collect_interrupt

local Delegate = require("Delegate")
local TimeFormatter = require("TimeFormatter")
local I18N = require("I18N")
local BaseUIMediator = require("BaseUIMediator")

---@class GatherInterruptMediator : BaseUIMediator
local GatherInterruptMediator = class("GatherInterruptMediator", BaseUIMediator)

---@class GatherInterruptData
---@field preset wds.TroopPreset
---@field onLeave func

function GatherInterruptMediator:OnCreate()
    self.p_title = self:Text("p_title", "bestrongwarning_title")
    self.p_text_1 = self:Text("p_text_1", "popup_team_collect_desc01")
    self.p_text_2 = self:Text("p_text_2")
    self.p_table_icon = self:TableViewPro("p_table_icon")
    self.p_comp_btn_leave = self:Button("p_comp_btn_leave", Delegate.GetOrCreate(self, self.OnLeave))
    self.p_text = self:Text("p_text", "btn_animalcave_leave")

    ---@type BistateButton
    self.p_comp_btn_collect = self:LuaObject("p_comp_btn_collect")
end

---@param param GatherInterruptData
function GatherInterruptMediator:OnOpened(param)
    self.param = param

    ---@type BistateButtonParameter
    local btnData = {}
    btnData.onClick = Delegate.GetOrCreate(self, self.OnContinue)
    btnData.buttonText = I18N.Get("btn_animalcave_continue")
    self.p_comp_btn_collect:FeedData(btnData)

    self:RefreshUI()
end

function GatherInterruptMediator:OnShow(param)
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.Tick))
end

function GatherInterruptMediator:OnHide(param)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.Tick))
end

function GatherInterruptMediator:RefreshUI()
    self:UpdateItems()
    self:UpdateTime()
end

function GatherInterruptMediator:Tick()
    self:UpdateTime()
end

function GatherInterruptMediator:UpdateItems()
    self.p_table_icon:Clear()

    local basicInfo = self.param.preset.BasicInfo
    for id, count in pairs(basicInfo.GatherItems) do
        ---@type GatherInterruptItemCellData
        local data = {}
        data.id = id
        data.count = count
        self.p_table_icon:AppendData(data)
    end
end

function GatherInterruptMediator:UpdateTime()
    local basicInfo = self.param.preset.BasicInfo
    local duration = (basicInfo.GatherEndTime - g_Game.ServerTime:GetServerTimestampInMilliseconds()) / 1000
    duration = math.max(duration, 0)
    self.p_text_2.text = I18N.GetWithParams("popup_team_collect_desc02", TimeFormatter.SimpleFormatTime(duration))
end

function GatherInterruptMediator:OnLeave()
    if self.param.onLeave then
        self.param.onLeave()
    end
    self:CloseSelf()
end

function GatherInterruptMediator:OnContinue()
    self:CloseSelf()
end

return GatherInterruptMediator