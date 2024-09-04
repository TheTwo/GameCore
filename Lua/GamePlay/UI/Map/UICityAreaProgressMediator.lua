local BaseUIMediator = require ('BaseUIMediator')
local TouchInfoTemplatePrefabNames = require("TouchInfoTemplatePrefabNames")
local I18N = require('I18N')
local LuaBaseComponent = CS.DragonReborn.UI.LuaBaseComponent
local GameObject = CS.UnityEngine.GameObject
local LayoutRebuilder = CS.UnityEngine.UI.LayoutRebuilder
local Delegate = require("Delegate")
local UIHelper = require('UIHelper')

---@class UICityAreaProgressMediator : BaseUIMediator
local UICityAreaProgressMediator = class('UICityAreaProgressMediator', BaseUIMediator)

function UICityAreaProgressMediator:OnCreate()
    self.anchorRoot = self:Transform("p_root")
    self.leftRoot = self:GameObject("p_city_info_left")
    self.secondaryRoot = self:Transform("p_group_secondary")
    self.templateRoot = self:Transform("p_template_root")
    self.bgTrans = self:Transform("p_window")
    self.btnComp = self:LuaBaseComponent("child_touch_circle_group_btn")
end

function UICityAreaProgressMediator:OnOpened(param)
    self.data = param
    self.templateRoot.gameObject:SetActive(false)
    self:CollectComponents()
    self:ClearComponents()
    self:InstantiateLeftWindows()

    local btn = UIHelper.DuplicateUIComponent(self.btnComp, self.cloneWindow)
    btn:FeedData({text = I18N.Temp().btn_goto, func = param.otherFunc})
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.anchorRoot)
end

function UICityAreaProgressMediator:CollectComponents()
    self.componentPrefabMap = {}
    for type, prefabName in pairs(TouchInfoTemplatePrefabNames) do
        self.componentPrefabMap[type] = self:LuaBaseComponent(prefabName)
    end
end

function UICityAreaProgressMediator:ClearComponents()
    local secondaryComponents = self.secondaryRoot:GetComponentsInChildren(typeof(LuaBaseComponent))
    for i = 0, secondaryComponents.Length - 1 do
        local component = secondaryComponents[i]
        UIHelper.DeleteUIComponent(component)
    end
    for i = 0, self.secondaryRoot.childCount - 1 do
        GameObject.Destroy(self.secondaryRoot:GetChild(i).gameObject)
    end
end

function UICityAreaProgressMediator:InstantiateLeftWindows()
    -- 无需分页
    if not self.data.windowToggleData.showToggle then
        self:InstantiateMultiLeftWindows()
    else
        local imageIds = self.data.windowToggleData.toggleImageIds
        local idCount = imageIds ~= nil and #imageIds or 0
        if idCount == 1 then
            self:InstantiateMultiLeftWindows()
        elseif idCount ~= #self.data.windowData - 1 then
            g_Logger.Error(("标签数量与左侧窗口数不符, 标签数为%d, 窗口数为%d"):format(idCount, #self.data.windowData - 1))
            self:InstantiateMultiLeftWindows()
        end
    end
end

function UICityAreaProgressMediator:InstantiateMultiLeftWindows()
    for i = 2, #self.data.windowData do
        self.cloneWindow = self:InstantiateWindow(self.bgTrans, self.data.windowData[i], self.secondaryRoot)
    end
    self.leftRoot:SetActive(#self.data.windowData > 1)
end

function UICityAreaProgressMediator:InstantiateWindow(template, windowData, parent)
    local infoBg = GameObject.Instantiate(template, parent)
    for _, v in ipairs(windowData.data) do
        self:InstantiateComp(v.typ, v.compData, infoBg)
    end
    return infoBg
end

function UICityAreaProgressMediator:InstantiateComp(typ, data, parent)
    local compTemplate = self.componentPrefabMap[typ]
    if compTemplate then
        local comp = UIHelper.DuplicateUIComponent(compTemplate, parent)
        comp:FeedData(data)
    else
        g_Logger.Error(("不存在的模板类型 %d"):format(typ))
    end
end

return UICityAreaProgressMediator
