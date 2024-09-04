---Scene Name : scene_build_touch_repair
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CastleBuildingRepairBaseParameter = require("CastleBuildingRepairBaseParameter")
local CastleBuildingRepairWallParameter = require("CastleBuildingRepairWallParameter")
local CastleSafeAreaWallRepairParameter = require("CastleSafeAreaWallRepairParameter")
local EventConst = require("EventConst")
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')

---@class CityBuildingRepairBlockBaseUIMediator:BaseUIMediator
local CityBuildingRepairBlockBaseUIMediator = class('CityBuildingRepairBlockBaseUIMediator', BaseUIMediator)

function CityBuildingRepairBlockBaseUIMediator:OnCreate()
    self._p_table_material = self:TableViewPro("p_table_material")
    self._p_drag_vfx = self:BindComponent("p_drag_vfx", typeof(CS.FpAnimation.FpAnimatorTotalCommander))
    self._p_drag_out_vfx = self:BindComponent("p_drag_out_vfx", typeof(CS.FpAnimation.FpAnimatorTotalCommander))
end

---@param param CityBuildingRepairBlockDatum
function CityBuildingRepairBlockBaseUIMediator:OnOpened(param)
    ModuleRefer.InventoryModule:ForceInitCache()
    self._p_table_material:Clear()
    local costItems = param:GetCostItemIconData()
    for i, v in ipairs(costItems) do
        self._p_table_material:AppendData({itemIconData = v, block = param, host = self})
    end
    self.param = param

    self.param:AddEventListener()
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingRepairBaseParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnRepairBaseCallback))
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingRepairWallParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnRepairWallCallback))
    g_Game.ServiceManager:AddResponseCallback(CastleSafeAreaWallRepairParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnRepairSafeAreaWallCallback))
    g_Game.EventManager:AddListener(EventConst.UI_CITY_REPAIR_BLOCK_TRIGGER_OPEN_ANIM, Delegate.GetOrCreate(self, self.TriggerOpenAnim))
    g_Game.EventManager:AddListener(EventConst.UI_CITY_REPAIR_BLOCK_TRIGGER_CLOSE_ANIM, Delegate.GetOrCreate(self, self.TriggerCloseAnim))
end

function CityBuildingRepairBlockBaseUIMediator:OnHide()
    self._p_table_material:Clear()
end

function CityBuildingRepairBlockBaseUIMediator:OnClose(param)
    self.param:RemoveEventListener()
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingRepairBaseParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnRepairBaseCallback))
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingRepairWallParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnRepairWallCallback))
    g_Game.ServiceManager:RemoveResponseCallback(CastleSafeAreaWallRepairParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnRepairSafeAreaWallCallback))
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_REPAIR_BLOCK_TRIGGER_OPEN_ANIM, Delegate.GetOrCreate(self, self.TriggerOpenAnim))
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_REPAIR_BLOCK_TRIGGER_CLOSE_ANIM, Delegate.GetOrCreate(self, self.TriggerCloseAnim))
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_REPAIR_BLOCK_CLOSED)

    self.param = nil
    self.backHandle = nil
end

function CityBuildingRepairBlockBaseUIMediator:OnCellBeginDrag()
    self._p_drag_out_vfx:StopAll()
    self._p_drag_vfx:PlayAll()
end

function CityBuildingRepairBlockBaseUIMediator:OnCellEndDrag()
    self._p_drag_vfx:StopAll()
    self._p_drag_out_vfx:PlayAll()
end

function CityBuildingRepairBlockBaseUIMediator:TriggerOpenAnim()
    self.CSComponent:TriggerAllAnim(FpAnimTriggerEvent.OnShow)
end

function CityBuildingRepairBlockBaseUIMediator:TriggerCloseAnim()
    self.CSComponent:TriggerAllAnim(FpAnimTriggerEvent.OnClose)
end

---@param data {itemIconData:ItemIconData, block:CityBuildingRepairBlockDatum}
function CityBuildingRepairBlockBaseUIMediator:RequestCost(data)
    local ret = self.param:RequestCost(data.itemIconData.configCell:Id())
    self._p_table_material:RemData(data)
    return ret
end

function CityBuildingRepairBlockBaseUIMediator:OnRepairBaseCallback(isSuccess, reply)
    if not isSuccess then
        self._p_table_material:Clear()
        local costItems = self.param:GetCostItemIconData()
        for i, v in ipairs(costItems) do
            self._p_table_material:AppendData({itemIconData = v, block = self.param})
        end
    end
end

function CityBuildingRepairBlockBaseUIMediator:OnRepairWallCallback(isSuccess, reply)
    if not isSuccess then
        self._p_table_material:Clear()
        local costItems = self.param:GetCostItemIconData()
        for i, v in ipairs(costItems) do
            self._p_table_material:AppendData({itemIconData = v, block = self.param})
        end
    end
end

function CityBuildingRepairBlockBaseUIMediator:OnRepairSafeAreaWallCallback(isSuccess, reply)
    if not isSuccess then
        self._p_table_material:Clear()
        local costItems = self.param:GetCostItemIconData()
        for i, v in ipairs(costItems) do
            self._p_table_material:AppendData({itemIconData = v, block = self.param})
        end
    end
end

return CityBuildingRepairBlockBaseUIMediator