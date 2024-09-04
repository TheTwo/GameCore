---Scene Name : scene_city_room_popup_formula_buff
local BaseUIMediator = require ('BaseUIMediator')
local CityLegoI18N = require('CityLegoI18N')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local I18N = require("I18N")

---@class CityLegoBuffSelectUIMediator:BaseUIMediator
local CityLegoBuffSelectUIMediator = class('CityLegoBuffSelectUIMediator', BaseUIMediator)

function CityLegoBuffSelectUIMediator:OnCreate()
    ---@type CommonPopupBackLargeComponent
    self._child_popup_base_l = self:LuaObject("child_popup_base_l")
    self._p_text_title = self:Text("p_text_title", CityLegoI18N.UI_HintBuffSelect)
    self._p_table_buff = self:TableViewPro("p_table_buff")

    self._child_comp_btn_b_m_u2 = self:Button("child_comp_btn_b_m_u2", Delegate.GetOrCreate(self, self.OnClick))
    self._p_text = self:Text("p_text", "ui_activebuff")
end

---@param param CityLegoBuffSelectUIParameter
function CityLegoBuffSelectUIMediator:OnOpened(param)
    self.param = param
    
    ---@type CommonBackButtonData
    local backData = {}
    backData.title = I18N.Get(CityLegoI18N.UI_TitleBuffSelect)
    self._child_popup_base_l:FeedData(backData)

    self._p_table_buff:Clear()
    self.selectedBuffs = {}
    local _selectMap = {}
    for i, v in ipairs(self.param.legoBuilding.payload.BuffList) do
        _selectMap[v] = true
        table.insert(self.selectedBuffs, v)
    end

    local calculator = self.param.legoBuilding.buffCalculator
    ---@type table<number, {cfg:RoomTagBuffConfigCell, isSelected:boolean}>
    self.dataMap = {}
    for buffCfgId, unit in pairs(calculator.buffMap) do
        if unit.valid then
            local cfg = unit.buffCfg
            local isSelected = _selectMap[buffCfgId] == true
            self.dataMap[buffCfgId] = {cfg = cfg, isSelected = isSelected}
            self._p_table_buff:AppendData(self.dataMap[buffCfgId])
        end
    end

    g_Game.EventManager:AddListener(EventConst.UI_CITY_LEGO_BUFF_SELECT_CELL, Delegate.GetOrCreate(self, self.OnCellSelected))
end

function CityLegoBuffSelectUIMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_LEGO_BUFF_SELECT_CELL, Delegate.GetOrCreate(self, self.OnCellSelected))
end

---@param cfg RoomTagBuffConfigCell
function CityLegoBuffSelectUIMediator:OnCellSelected(cfg)
    for buffCfgId, data in pairs(self.dataMap) do
        if buffCfgId == cfg:Id() and data.isSelected then
            return
        end
    end

    local selectedBuffs = {}
    local first = nil
    for buffCfgId, data in pairs(self.dataMap) do
        if buffCfgId == cfg:Id() then
            data.isSelected = true
            table.insert(selectedBuffs, buffCfgId)
        elseif data.isSelected then
            if first == nil then
                first = data
                data.isSelected = false
            else
                table.insert(selectedBuffs, buffCfgId)
            end
        end
    end

    self._p_table_buff:UpdateOnlyAllDataImmediately()
    self.selectedBuffs = selectedBuffs
end

function CityLegoBuffSelectUIMediator:OnClick()
    self.param.legoBuilding:RequestSelectBuff(self.selectedBuffs, function(cmd, isSuccess, rsp)
        if not isSuccess then return end
        self:PlayLightVX()
    end)
end

function CityLegoBuffSelectUIMediator:PlayLightVX()
    local delay = 0
    for i = 0, self._p_table_buff._shownCellList.Count - 1 do
        local cellCs = self._p_table_buff._shownCellList[i]
        local cell = cellCs.Lua
        if cell then
            local flag, length = cell:TryPlayLightVX() 
            if flag then
                delay = math.max(delay, length)
            end
        end
    end

    if delay > 0 then
        self:IntervalRepeat(Delegate.GetOrCreate(self, self.CloseSelf), delay, 0)
    else
        self:CloseSelf()
    end
end

return CityLegoBuffSelectUIMediator