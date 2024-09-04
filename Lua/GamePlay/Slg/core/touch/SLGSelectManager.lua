---
--- Created by wupei. DateTime: 2022/1/14
---
local ModuleRefer = require('ModuleRefer')
local DBEntityType = require('DBEntityType')
local AbstractManager = require("AbstractManager")
local EventConst = require('EventConst')
local UIMediatorNames = require('UIMediatorNames')

---@class SelectTroopData
---@field presetIndex number
---@field entityData wds.Troop
---@field ctrl TroopCtrl

---@class SLGSelectManager : AbstractManager
local SLGSelectManager = class('SLGSelectManager',AbstractManager)

---@param selectTroopData SelectTroopData
function SLGSelectManager.GetSelectTroopDataId(selectTroopData)
    if selectTroopData == nil then
        return 0
    end

    if selectTroopData.entityData == nil then
        return 0
    end

    return selectTroopData.entityData.ID
end

---@protected
function SLGSelectManager:ctor(...)
    AbstractManager.ctor(self, ...)
   
    ---@type SelectTroopData[]
    self._selectedTroops = {}

    ---@type VirtualTroopCtrl
    self._virtualCtrl = nil
end

function SLGSelectManager:Awake()

end

function SLGSelectManager:OnDestroy()
    if self._virtualCtrl then
        self._virtualCtrl:OnDestroyEntity()
        self._virtualCtrl = nil
    end
end

---@param troop wds.MobileFortress
function SLGSelectManager:RefreshMobileFortressMoveArea(troop)
    if troop and 
       troop.TypeHash == DBEntityType.MobileFortress and
       ModuleRefer.PlayerModule:IsFriendly(troop.Owner) 
    then
        ModuleRefer.KingdomPlacingModule:StartBehemoth()
    else
        ModuleRefer.KingdomPlacingModule:EndBehemoth()
    end
end

---@param presetIndex number 
---@param entity wds.Troop | wds.MobileFortress | wds.MapMob
---@param ctrl TroopCtrl
function SLGSelectManager:SetSelectData(presetIndex,entity,ctrl)
    if ctrl or presetIndex > 0 then
        ---@type SelectTroopData
        local data =
        {
            presetIndex = presetIndex,
            entityData = entity,
            ctrl = ctrl
        }
        
        table.insert(self._selectedTroops, data)
    end
    if ctrl ~= nil then        
        ctrl:SetSelected(true)                 
        self:RefreshMobileFortressMoveArea(ctrl:GetData())
    else
        self:RefreshMobileFortressMoveArea(nil)        
    end        
    g_Game.EventManager:TriggerEvent(EventConst.SLGTROOP_SELECTION)

    if self:GetSelectCount() > 1 then
        local allData = self:GetAllSelected()
        for key, data in pairs(allData) do
            if data and data.ctrl then
                data.ctrl:SetViewDirty()
            end
        end
    end
end

function SLGSelectManager:RemoveSelectData(index)
    local data = self._selectedTroops[index]
    if not data then return end
    table.remove(self._selectedTroops,index)    
    g_Game.EventManager:TriggerEvent(EventConst.SLGTROOP_SELECTION)            
    if data.ctrl then
        data.ctrl:SetSelected(false)
        data.ctrl:SetFocus(false)      
    end
    if data.entityData and data.entityData.TypeHash == DBEntityType.MobileFortress then
        self:RefreshMobileFortressMoveArea(nil)        
    end
    if self:GetSelectCount() < 2 then
        local allSelectTroopDatas = self:GetAllSelected()
        for key, selectTroopData in pairs(allSelectTroopDatas) do
            if selectTroopData and selectTroopData.ctrl then
                selectTroopData.ctrl:SetViewDirty()
            end
        end
    end
end

---@param ctrl TroopCtrl
function SLGSelectManager:SetSelect(ctrl)
    if not self._selectedTroops[1]         
        or self._selectedTroops[1].ctrl ~= ctrl 
        or (self._selectedTroops[1].ctrl == ctrl and ctrl ~= nil and not ctrl:IsSelected())
        or #self._selectedTroops > 1 
    then        
        self:ClearAllSelect()        
        local entityData = nil
        local presetIndex = -1
        if ctrl then
            presetIndex = self._module.troopManager:GetTroopPresetIndex(ctrl._data)
            entityData = ctrl._data
        end
        self:SetSelectData(
            presetIndex,
            entityData
            ,ctrl
        )
    end
end


---@param ctrl TroopCtrl
function SLGSelectManager:AddSelect(ctrl)
    if not ctrl or self:IsCtrlSelected(ctrl) then return end   
 
    local entityData = nil
    local presetIndex = -1
    if ctrl then
        presetIndex = self._module.troopManager:GetTroopPresetIndex(ctrl._data)
        entityData = ctrl._data
    end

    self:SetSelectData(
        presetIndex,
        entityData
        ,ctrl
    )
end
---@return TroopCtrl
function SLGSelectManager:GetSelectTroopCtrl()   

    local data = self:GetFirstSelected()
    if data then
        return data.ctrl
    end
    return nil    
end

---@param ctrl TroopCtrl
function SLGSelectManager:CancelSelect(ctrl)
    if not ctrl  then return end    
    local index = -1
    if self._selectedTroops and #self._selectedTroops > 0 then
        for i, value in ipairs(self._selectedTroops) do
            if value.ctrl == ctrl then
                index = i
                break
            end
        end                       
    end 
    if index > 0 then
        self:RemoveSelectData(index)       
        self._module:CloseTroopMenu()        
        if ctrl:IsMonster() then            
            g_Game.UIManager:CloseAllByName(UIMediatorNames.TouchMenuUIMediator)
        end
    end           
end

function SLGSelectManager:GetAllSelected()
    return self._selectedTroops 
end

---@return SelectTroopData
function SLGSelectManager:GetFirstSelected()   
    if not self._selectedTroops or #self._selectedTroops < 1 then
        return nil
    end     
    return self._selectedTroops[1] 
end

function SLGSelectManager:IsFirstSelected(ctrl)
    if not ctrl then return false end
    if self._selectedTroops and self._selectedTroops[1] and self._selectedTroops[1].ctrl == ctrl then
        return true
    else
        return false
    end
end

function SLGSelectManager:IsTroopSelect(TroopId)
    if not self._selectedTroops or #self._selectedTroops < 1 then
        return false
    end
    for key, value in pairs(self._selectedTroops) do
        if value and value.entityData and value.entityData.ID == TroopId then
            return true
        end
    end
    return false    
end

function SLGSelectManager:IsCtrlSelected(ctrl)
    if not ctrl then return false end   
    if self._selectedTroops and #self._selectedTroops > 0 then
        for key, value in pairs(self._selectedTroops) do
            if value.ctrl == ctrl then
                return true
            end
        end                             
    end
    return false
end

function SLGSelectManager:GetVirtualCtrl(position)
    if not self._virtualCtrl then
        self._virtualCtrl = require('VirtualTroopCtrl').new()
    end
    if position then
        self._virtualCtrl:SetPosition(position)
    end
    return self._virtualCtrl
end

function SLGSelectManager:SetSelectPreset(index)            
    if not self._selectedTroops[1] or self._selectedTroops[1].presetIndex ~= index or #self._selectedTroops > 1 then        
        self:ClearAllSelect()   
        local info = self._module.troopManager:GetTroopInfoByPresetIndex(index)
        if info then
            local ctrl = nil
            local entityData = nil
            entityData = info.entityData
            if entityData then
                ctrl = self._module.troopManager:FindTroopCtrl(entityData.ID)
            end
            self:SetSelectData(index,entityData,ctrl)
        end
    end
end

function SLGSelectManager:AddSelectPreset(index)
    if not index or index < 1 or self:IsPresetSelect(index) then 
        return
    end
    local info = self._module.troopManager:GetTroopInfoByPresetIndex(index)
    if info then
        local ctrl = nil
        local entityData = nil
        entityData = info.entityData
        if entityData then
            ctrl = self._module.troopManager:FindTroopCtrl(entityData.ID)
        end
        self:SetSelectData(index,entityData,ctrl)
    end
end

function SLGSelectManager:CancelSelectPreset(index)
    if not index or index < 1 or not self:IsPresetSelect(index) then
        return
    end
    local dataIndex = -1
    if self._selectedTroops and #self._selectedTroops > 0 then
        for i, value in ipairs(self._selectedTroops) do
            if value.presetIndex == index then
                dataIndex = i
                break
            end
        end                       
    end
    self:RemoveSelectData(dataIndex)
end

-- function SLGSelectManager:GetSelectPreset()
--     if self._selectDatas and self._selectDatas[1] then
--         return self._selectDatas[1].presetIndex
--     else
--         return nil
--     end    
-- end

function SLGSelectManager:IsPresetSelect(index)
    if not self._selectedTroops or #self._selectedTroops < 1 then
        return false
    end
    for key, value in pairs(self._selectedTroops) do
        if value and value.presetIndex == index then
            return true
        end
    end
    return false  
end


function SLGSelectManager:GetSelectCount()    
    return self._selectedTroops and #self._selectedTroops or 0
end

function SLGSelectManager:GetMySelectCount()
    local count = 0
    for _, troop in pairs(self._selectedTroops) do
        if troop.presetIndex > 0 then
            count = count + 1
        end
    end
    return count
end

function SLGSelectManager:ClearAllSelect()
    if #self._selectedTroops > 0 then
        for i = 1, #self._selectedTroops do
            local curCtrl = self._selectedTroops[i].ctrl
            if curCtrl ~= nil then
                curCtrl:SetSelected(false)
                curCtrl:SetFocus(false)
            end
        end
    end    
    self._selectedTroops = {}    
    if ModuleRefer.KingdomPlacingModule:IsPlacing() then
        ModuleRefer.KingdomPlacingModule:EndBehemoth()
    end
end

function SLGSelectManager:RefreshSelectedData()
    if not self._selectedTroops or #self._selectedTroops < 1 then
        return false
    end

    for index, value in ipairs(self._selectedTroops) do
        if value and value.presetIndex > 0  then
            local info = self._module.troopManager:GetTroopInfoByPresetIndex(value.presetIndex)
            if not info or not info.entityData then
                self._selectedTroops[index].entityData = nil
                self._selectedTroops[index].ctrl = nil
            else
                self._selectedTroops[index].entityData = info.entityData
                self._selectedTroops[index].ctrl = self._module.troopManager:FindTroopCtrl(info.entityData.ID)
            end
        end
    end
end


return SLGSelectManager
