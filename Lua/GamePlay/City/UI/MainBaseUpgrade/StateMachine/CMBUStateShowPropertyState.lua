local CMBUState = require("CMBUState")
---@class CMBUStateShowPropertyState:CMBUState
---@field new fun():CMBUStateShowPropertyState
local CMBUStateShowPropertyState = class("CMBUStateShowPropertyState", CMBUState)
local ModuleRefer = require("ModuleRefer")
local CityLegoBuffDifferData = require("CityLegoBuffDifferData")
local I18N = require("I18N")

function CMBUStateShowPropertyState:Enter()
    self.autoStepDelay = 0.5
    self:AppendTableCell()
    if self.stateMachine:ReadBlackboard("isSkip", false) then
        self.uiMediator.stateMachine:ChangeState("ShowLv")
    end
end

function CMBUStateShowPropertyState:AppendTableCell()
    local data = {content = I18N.Get("city_main_bui_upgrade_effect_3")}
    self.uiMediator._p_table_content:AppendData(data, 0)
    
    ---@type CityLegoBuffDifferData[]
    local oldDataList = {}
    local oldLvCfg = ModuleRefer.CityConstructionModule:GetFurnitureLevelCell(self.uiMediator.furniture.furType, self.uiMediator.furniture.level - 1)
    local newLvCfg = self.uiMediator.furniture.furnitureCell

    local propertyList = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(oldLvCfg:Attr())
    if propertyList then
        for i, v in ipairs(propertyList) do
            local data = CityLegoBuffDifferData.new(v.type, v.originValue)
            table.insert(oldDataList, data)
        end
    end

    for i = 1, oldLvCfg:BattleAttrGroupsLength() do
        local battleGroup = oldLvCfg:BattleAttrGroups(i)
        local battleValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(battleGroup:Attr())
        if battleValues then
            for _, v in ipairs(battleValues) do
                if battleGroup:TextLength() == 0 then
                    local data = CityLegoBuffDifferData.new(v.type, v.originValue)
                    table.insert(oldDataList, data)
                else
                    for j = 1, battleGroup:TextLength() do
                        local prefix = battleGroup:Text(j)
                        local data = CityLegoBuffDifferData.new(v.type, v.originValue, nil, prefix)
                        table.insert(oldDataList, data)
                    end
                end
            end
        end
    end

    ---@type CityLegoBuffDifferData[]
    local newDataList = {}
    local newPropertyList = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(newLvCfg:Attr())
    if newPropertyList then
        for i, v in ipairs(newPropertyList) do
            local data = CityLegoBuffDifferData.new(v.type, v.originValue)
            table.insert(newDataList, data)
        end
    end

    for i = 1, newLvCfg:BattleAttrGroupsLength() do
        local battleGroup = newLvCfg:BattleAttrGroups(i)
        local battleValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(battleGroup:Attr())
        if battleValues then
            for _, v in ipairs(battleValues) do
                if battleGroup:TextLength() == 0 then
                    local data = CityLegoBuffDifferData.new(v.type, v.originValue)
                    table.insert(newDataList, data)
                else
                    for j = 1, battleGroup:TextLength() do
                        local prefix = battleGroup:Text(j)
                        local data = CityLegoBuffDifferData.new(v.type, v.originValue, nil, prefix)
                        table.insert(newDataList, data)
                    end
                end
            end
        end
    end

    ---@type table<string, CityLegoBuffDifferData>
    local propertyMap = {}
    for i, v in ipairs(oldDataList) do
        propertyMap[v:GetUniqueName()] = v
    end

    ---@type CityLegoBuffDifferData[]
    local toShowList = {}
    for i, newProp in ipairs(newDataList) do
        local oldProp = propertyMap[newProp:GetUniqueName()]
        --- 数值变化的词条
        if oldProp ~= nil then
            if newProp.oldValue ~= oldProp.oldValue then
                local data = CityLegoBuffDifferData.new(newProp.elementId, oldProp.oldValue, newProp.oldValue, oldProp.prefix)
                table.insert(toShowList, data)
            end
            propertyMap[newProp:GetUniqueName()] = nil
        --- 新增的词条
        else
            local data = CityLegoBuffDifferData.new(newProp.elementId, 0, newProp.oldValue, newProp.prefix)
            table.insert(toShowList, data)
        end
    end

    --- 删除的词条
    for _, oldProp in pairs(propertyMap) do
        local data = CityLegoBuffDifferData.new(oldProp.elementId, oldProp.oldValue, 0, oldProp.prefix)
        table.insert(toShowList, data)
    end

    for i, data in ipairs(toShowList) do
        ---@type {name:string, from:string, to:string}
        local data = {name = data:GetName(), from = data:GetOldValueText(), to = data:GetNewValueText()}
        self.uiMediator._p_table_content:AppendData(data, 1)
    end
    self.uiMediator._p_table_content:SetDataVisable(#toShowList, CS.TableViewPro.MoveSpeed.Normal)
end

function CMBUStateShowPropertyState:Tick(delta)
    self.autoStepDelay = self.autoStepDelay - delta
    if self.autoStepDelay <= 0 then
        self.uiMediator.stateMachine:ChangeState("ShowLv")
    end
end

function CMBUStateShowPropertyState:Exit()
    self.uiMediator:ShowTapToContinue()
end

function CMBUStateShowPropertyState:OnContinueClick() 
    self.stateMachine:WriteBlackboard("isSkip", true, true)
    self.uiMediator.stateMachine:ChangeState("ShowLv")
end

return CMBUStateShowPropertyState