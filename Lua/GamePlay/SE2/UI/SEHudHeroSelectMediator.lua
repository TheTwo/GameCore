local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local CommonDropDown = require("CommonDropDown")
local I18N = require('I18N')

local SORT_BY_QUALITY = 1
local SORT_BY_LEVEL = 2
--local SORT_BY_RANK = 3

---@class SEHudHeroSelectMediator : BaseUIMediator
local SEHudHeroSelectMediator = class('SEHudHeroSelectMediator', BaseUIMediator)

function SEHudHeroSelectMediator:ctor()
    self._heroCellList = {}
    self._sortMode = SORT_BY_QUALITY
    self._teamHeroList = {}
    self._selectedHeroIndex = 0
    self._selectedHeroConfig = nil
    self._focusedHeroConfigId = 0
    self._onClose = nil
    self._heroMap = {}
end

function SEHudHeroSelectMediator:OnCreate(param)
    self._teamHeroList = param.teamHeroList
    self._selectedHeroIndex = param.selectedHeroIndex
    self._selectedHeroConfig = param.selectedHeroConfig
    self._onClose = param.onClose
    if (self._selectedHeroConfig) then
        self._focusedHeroConfigId = self._selectedHeroConfig:Id()
    else
        self._focusedHeroConfigId = 0
    end
    self:InitObjects()
end

function SEHudHeroSelectMediator:OnShow(param)
    self:InitData()
    self:Refresh()
end

function SEHudHeroSelectMediator:OnHide(param)
    if (self._onClose) then
        self._onClose(param)
    end
end

---@param self SEHudHeroSelectMediator
function SEHudHeroSelectMediator:InitObjects()
    self._sortDropDown = self:LuaObject("child_dropdown")
    self._heroTable = self:TableViewPro("p_table_hero")
    self._closeButton = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnCloseBtnClick))
end

---@param self SEHudHeroSelectMediator
function SEHudHeroSelectMediator:InitData()
    local sortDropDownData = {}
    sortDropDownData.items = CommonDropDown.CreateData(
        "", I18N.Get("hero_quality"),
        "", I18N.Get("hero_level"),
        "", I18N.Get("hero_star")
    )
    sortDropDownData.defaultId = 1
    sortDropDownData.onSelect = Delegate.GetOrCreate(self, self.OnSortSelect)
    self._sortDropDown:FeedData(sortDropDownData)
end

---@param self SEHudHeroSelectMediator
function SEHudHeroSelectMediator:Refresh()
    self:RefreshData()
    self:RefreshUI()
end

---@param self SEHudHeroSelectMediator
function SEHudHeroSelectMediator:RefreshData()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if (not player) then
        g_Logger.Error("Can't get player!")
        return
    end
    local heroes = player.Hero.HeroInfos
    if (not heroes) then
        g_Logger.Error("Can't get hero list for player %s", player.ID)
        return
    end

    -- 英雄列表
    self._heroCellList = {}
    for cfgId, _ in pairs(heroes) do
        local heroCell = ModuleRefer.HeroModule:GetHeroByCfgId(cfgId)
        if (heroCell) then
            table.insert(self._heroCellList, heroCell)
        end
    end
end

---@param self SEHudHeroSelectMediator
function SEHudHeroSelectMediator:RefreshUI()
    -- 排序
    self:SortHero()

    -- 刷新
    self._heroTable:Clear()
    for _, cell in pairs(self._heroCellList) do
        local cellData = {
            nodeName = "child_card_hero_m",
            data = cell,
            onClick = Delegate.GetOrCreate(self, self.OnHeroClick),
            isInTeam = self._teamHeroList[cell.configCell:Id()] ~= nil,
            isSelected = cell.configCell:Id() == self._focusedHeroConfigId,
        }
        self._heroTable:AppendData(cellData)
    end
    self._heroTable:RefreshAllShownItem()
end

function SEHudHeroSelectMediator:SortHero()
    table.sort(self._heroCellList, function(a, b)
        local aid = a.configCell:Id()
        local bid = b.configCell:Id()

        -- 当前选定英雄最优先
        if (self._selectedHeroConfig) then
            local currentId = self._selectedHeroConfig:Id()
            if (aid == currentId) then
                return true
            elseif (bid == currentId) then
                return false
            end
        end

        -- 队内其他英雄优先
        if (self._teamHeroList[aid] and not self._teamHeroList[bid]) then
            return true
        elseif (not self._teamHeroList[aid] and self._teamHeroList[bid]) then
            return false
        end

        -- 按选定模式排序
        if (self._sortMode == SORT_BY_LEVEL) then
            -- 等级
            if (a.dbData.Level ~= b.dbData.Level) then
                return a.dbData.Level > b.dbData.Level
            end
        elseif (self._sortMode == SORT_BY_QUALITY) then
            -- 品质
            if (a.configCell:Quality() ~= b.configCell:Quality()) then
                return a.configCell:Quality() > b.configCell:Quality()
            end
        else
            -- 强化等级
            if (a.dbData.StarLevel ~= b.dbData.StarLevel) then
                return a.dbData.StarLevel > b.dbData.StarLevel
            end
        end

        -- 默认按ID由小到大
        return aid < bid
    end)
end

---@param self SEHudHeroSelectMediator
---@param id number
function SEHudHeroSelectMediator:OnSortSelect(id)
    self._sortMode = id
    self:RefreshUI()
end

---@param self SEHudHeroSelectMediator
---@param data HeroConfigCache
function SEHudHeroSelectMediator:OnHeroClick(data)
    self:CloseSelf(data.configCell)
end

---@param self SEHudHeroSelectMediator
function SEHudHeroSelectMediator:OnCloseBtnClick()
    self:CloseSelf()
end

return SEHudHeroSelectMediator
