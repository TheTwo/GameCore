---@class CityCreepNodeCircleMenuHelper
local CityCreepNodeCircleMenuHelper = {}
local this = CityCreepNodeCircleMenuHelper
local TouchMenuBasicInfoDatum = require("TouchMenuBasicInfoDatum")
local CityCreepType = require("CityCreepType")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local TouchMenuUIDatum = require("TouchMenuUIDatum")
local TouchMenuPageDatum = require("TouchMenuPageDatum")
local TouchMenuCellPairDatum = require("TouchMenuCellPairDatum")
local CircleMenuButtonConfig = require("CircleMenuButtonConfig")
local NumberFormatter = require("NumberFormatter")
local TouchMenuCellPairTimeDatum = require("TouchMenuCellPairTimeDatum")
local TouchMenuHelper = require("TouchMenuHelper")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")
local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")
local TouchMenuMainBtnGroupData = require("TouchMenuMainBtnGroupData")
local TouchMenuCellProgressDatum = require("TouchMenuCellProgressDatum")
local TouchMenuCellTextDatum = require("TouchMenuCellTextDatum")
local TouchMenuCellTaskDatum = require("TouchMenuCellTaskDatum")
local TaskRewardType = require("TaskRewardType")
local TouchMenuCellRewardDatum = require("TouchMenuCellRewardDatum")
local TMCellRewardItemIconData = require("TMCellRewardItemIconData")

---@param cellTile CityCellTile
function CityCreepNodeCircleMenuHelper.GetTouchInfoData(cellTile)
    local cell = cellTile:GetCell()
    if cell == nil then return nil end
    if not cell:IsCreepNode() then return nil end

    local city = cellTile:GetCity()
    local creepCfg = city.creepManager:GetCreepConfig(cellTile:GetCell().configId)
    local basicData = TouchMenuBasicInfoDatum.new(this.GetName(creepCfg), "sp_icon_item_cyst", ("X:%d Y:%d"):format(cellTile.x, cellTile.y))
    local corePage = this.GetCorePage(basicData, cellTile, creepCfg)
    local recoverPage = nil
    if creepCfg:RelZoneRecover() > 0 then
        recoverPage = this.GetRecoverPage(basicData, cellTile, creepCfg)
    end
    return TouchMenuUIDatum.new(corePage, recoverPage):SetPos(cellTile:GetWorldCenter())
end

function CityCreepNodeCircleMenuHelper.GetName(creepCfg)
    if creepCfg and creepCfg:Type() == CityCreepType.Core then
        local zoneRecoverCfg = ConfigRefer.CityZoneRecover:Find(creepCfg:RelZoneRecover())
        if zoneRecoverCfg then
            return I18N.Get(zoneRecoverCfg:NameWithCreep())
        else
            --- 否则读默认名
            return I18N.Get("creep_core")
        end
    else
        return I18N.Get("creep_flower")
    end
end

---@param basicData TouchMenuBasicInfoDatum
---@param cellTile CityCellTile
---@param creepCfg CityCreepConfigCell
function CityCreepNodeCircleMenuHelper.GetCorePage(basicData, cellTile, creepCfg)
    local compsData = this.GetCoreTableCellData(cellTile, creepCfg)
    local buttonGroupData = this.GenerateButtons(cellTile, creepCfg)
    return TouchMenuPageDatum.new(basicData, compsData, buttonGroupData)
end

function CityCreepNodeCircleMenuHelper.GetRecoverPage(basicData, cellTile, creepCfg)
    local compsData = this.GetRecoverTableCellData(cellTile, creepCfg)
    local buttonGroupData = this.GenerateButtons(cellTile, creepCfg)
    return TouchMenuPageDatum.new(basicData, compsData, buttonGroupData)
end

---@param cellTile CityCellTile
---@param creepCfg CityCreepConfigCell
function CityCreepNodeCircleMenuHelper.GetCoreTableCellData(cellTile, creepCfg)
    local ret = {}
    local icon = CircleMenuButtonConfig.ButtonIcons.IconStrength
    if creepCfg and creepCfg:Type() == CityCreepType.Core then
        --- 存活节点
        local activeNode = cellTile:GetCity().creepManager:GetKernelRelativeActiveNodeCount(creepCfg)
        table.insert(ret, TouchMenuCellPairDatum.new(I18N.Get("creep_flower_amount"), ("%d"):format(activeNode), icon))
        --- 核心战力加成
        local multi = ConfigRefer.CityConfig:CreepTileAdditionRate()
        table.insert(ret, TouchMenuCellPairDatum.new(I18N.Get("provide_power_buff"), ("+%s"):format(NumberFormatter.Percent(multi * activeNode)), icon))
    --- 菌毯节点
    else
        --- 复活倒计时
        local nodeDB = cellTile:GetCity().creepManager:GetCreepDB(creepCfg:Id())
        if nodeDB.Removed then
            table.insert(TouchMenuCellPairTimeDatum.new(I18N.Get("reborn_count_down"),
                TouchMenuHelper.GetSecondTickCommonTimerData(cellTile:GetCity().creepManager:RespawnTime(nodeDB), TouchMenuHelper.CommonTimerCallback)))
        end
        --- 状态
        table.insert(ret, TouchMenuCellPairDatum.new(I18N.Get("infect_item_status"), I18N.Get(nodeDB.Removed and "status_inactive" or "status_active"), icon))
        --- 节点战力加成
        local activeCreep = 0
        local multi = ConfigRefer.CityConfig:CreepTileAdditionRate()
        table.insert(ret, TouchMenuCellPairDatum.new(I18N.Get("provide_power_buff"), ("+%s"):format(NumberFormatter.Percent(activeCreep * multi)), icon))
    end
    return ret
end

---@private
---@param cellTile CityCellTile
---@param creepCfg CityCreepConfigCell
function CityCreepNodeCircleMenuHelper.GenerateLeftWindows(cellTile, creepCfg)
    local ret = {}
    table.insert(ret, CityCreepNodeCircleMenuHelper.GenerateCreepSingleNameWindow(cellTile, creepCfg))
    table.insert(ret, CityCreepNodeCircleMenuHelper.GenerateCreepInfoWindow(cellTile, creepCfg))
    --- 如果当前核心关联了区域收复配置，则需额外显示区域收复信息的窗口
    if creepCfg:RelZoneRecover() > 0 then
        table.insert(ret, CityCreepNodeCircleMenuHelper.GenereteZoneRecoverWindow(cellTile, creepCfg))
    end
    return ret
end

---@private
---@param cellTile CityCellTile
---@param creepCfg CityCreepConfigCell
function CityCreepNodeCircleMenuHelper.GetRecoverTableCellData(cellTile, creepCfg)
    local ret = {}
    local city = cellTile:GetCity()
    local zoneRecoverCfg = ConfigRefer.CityZoneRecover:Find(creepCfg:RelZoneRecover())
    --- 收复进度组件
    table.insert(ret, TouchMenuCellProgressDatum.new(nil, I18N.Get(zoneRecoverCfg:EventName()),
        city.zoneManager:GetRecoverProgressByZoneRecoverCfg(zoneRecoverCfg)))
    --- 收复描述
    table.insert(ret, TouchMenuCellTextDatum.new(I18N.Get(zoneRecoverCfg:EventDesc())))
    local taskCollections = city.zoneManager:GetRecoverTasksFromZoneRecover(zoneRecoverCfg)
    for _, v in ipairs(taskCollections) do
        --- 收复任务逐条
        table.insert(ret, TouchMenuCellTaskDatum.new(v:Id()))
    end
    
    --- 有奖励条目时才添加奖励组件
    local rewardsMap = {}
    local mainTask = ConfigRefer.Task:Find(zoneRecoverCfg:RecoverTasks())
    for i = 1, mainTask:ReceiveRewardLength() do
        local receiveReward = mainTask:ReceiveReward(i)
        if receiveReward:Typ() == TaskRewardType.RewardItem then
            local itemGroupId = tonumber(receiveReward:Param())
            local itemGroupCfg = ConfigRefer.ItemGroup:Find(itemGroupId)
            if itemGroupCfg then
                for j = 1, itemGroupCfg:ItemGroupInfoListLength() do
                    local info = itemGroupCfg:ItemGroupInfoList(j)
                    local itemId = info:Items()
                    rewardsMap[itemId] = (rewardsMap[itemId] or 0) + info:Nums()
                end
            end
        end
    end
    local rewards = {}
    for k, v in pairs(rewardsMap) do
        local reward = {configCell = ConfigRefer.Item:Find(k), count = v}
        table.insert(rewards, TMCellRewardItemIconData.new(reward))
    end

    if #rewards > 0 then
        table.insert(ret, TouchMenuCellRewardDatum.new(I18N.Get("task_group_rewards"), rewards))
    end
    return ret
end

---@private
---@param cellTile CityCellTile
---@param creepCfg CityCreepConfigCell
function CityCreepNodeCircleMenuHelper.GenerateButtons(cellTile, creepCfg)
    local callback = function()
        local cell = cellTile:GetCell()
        local elementCfg = ConfigRefer.CityElementData:Find(cell.configId)
        local creepElementCfg = ConfigRefer.CityElementCreep:Find(elementCfg:ElementId())
        local serviceGroupCfg = ConfigRefer.NpcServiceGroup:Find(creepElementCfg:ServiceGroupId())
        local serviceCfg = ConfigRefer.NpcService:Find(serviceGroupCfg:Services(1))
        local serviceId = serviceCfg:Id()
        --- 需要先打开出征队伍编辑界面
        local chooseHeroUi = UIMediatorNames.SEHudPreviewMediator
        ---@type SEHudTroopMediatorParameter
        local uiParameter = {}
        uiParameter.IsEnterSEMode = true
        uiParameter.SeId = serviceCfg:ServiceParam()
		uiParameter.fromType = require("SEHudTroopMediatorDefine").FromType.City
		uiParameter.fromPosX = cellTile.x
		uiParameter.fromPosY = cellTile.y
        uiParameter.OverrideEnterBtnClickCallback = function(seId, heroIds)
            cellTile:GetCity().cityExplorerManager:RequestNpcService(cell.configId, serviceId, function(success, rsp)
                g_Game.UIManager:CloseByName(chooseHeroUi)
                if success then
                    if rsp and rsp.Result then
                        if rsp.Result ~= 0 then
                            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(string.format("进入SE副本检查失败,Result:%s", rsp.Result)))
                            return
                        end
                    end
                    require("GotoUtils").GotoSceneSe(seId, heroIds)
                else
                    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("se_error"))
                end
            end)
            return false
        end
        g_Game.UIManager:Open(chooseHeroUi, uiParameter)
    end
    local btnKey
    if creepCfg and creepCfg:Type() == CityCreepType.Core then
        btnKey = "button_eliminate_core"
    else
        btnKey = "button_eliminate"
    end
    --- 如果菌毯核心/节点已经被打死过了(Removed=True), 则按钮置灰
    local enableFunc = function()
        local creepDB = cellTile:GetCity().creepManager:GetCreepDB(creepCfg:Id())
        return creepCfg and not creepDB.Removed
    end
    --- 攻打按钮
    local attack = TouchMenuMainBtnDatum.new(I18N.Get(btnKey), callback)
    attack:SetEnable(enableFunc())
    return TouchMenuMainBtnGroupData.new(attack)
end

return CityCreepNodeCircleMenuHelper
