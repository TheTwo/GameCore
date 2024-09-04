local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local HeroType = require('HeroType')
local TimerUtility = require("TimerUtility")

local SORT_BY_QUALITY = 1
local SORT_BY_LEVEL = 2
--local SORT_BY_RANK = 3

-- local SOLDIER_CALSS_ALL = 1
-- local SOLDIER_CALSS_INFANTRY = 2
-- local SOLDIER_CALSS_CAVALRY = 3
-- local SOLDIER_CALSS_ARCHER = 4



---@class TeamInfo
---@field index number
---@field heroes number[]|RepeatedField

---@class HeroSelectionMediatorParam
---@field teamInfo TeamInfo
---@field otherTeamsInfo TeamInfo[]
---@field selectedHeroIndex number
---@field onHeroSelect fun(heroId:number):boolean
---@field onClose fun(heroId:number):void
---@field heroSortType number

---@class TeamInfo
---@field _teamIndex number
---@field _index number

---@class HeroSelectionComponent : BaseUIMediator
---@field _heroCellList HeroConfigCache[]
---@field _teamInfo TeamInfo
---@field _otherTeamsInfo table<number,TeamInfo> @HeroConfigId,info
---@field _focusedHeroConfigId number
local HeroSelectionComponent = class('HeroSelectionComponent', BaseUIComponent)

HeroSelectionComponent.HeroSelectionSortType = {
    Normal = -1,
    Slg = 1
}

function HeroSelectionComponent:ctor()
    self._heroCellList = nil
    self._sortMode = SORT_BY_QUALITY
    -- self._filtMode = SOLDIER_CALSS_ALL
    self._teamInfo = nil
    self._otherTeamsInfo = nil
    self._focusedHeroConfigId = 0
    self._onClose = nil
end

function HeroSelectionComponent:OnCreate(param)
    -- self._singleDropDown = self:LuaObject("child_dropdown")

    -- self._doubleDropDown = self:GameObject('p_dropdown')
    self._sortTypeDropDown = self:LuaObject('child_dropdown_lv')
    self._classTypeDropDown = self:LuaObject('child_dropdown_class')

    self._heroTable = self:TableViewPro("p_table_hero")
    self._closeButton = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnCloseBtnClick))

	-- 动效
	self._animation = self:BindComponent("", typeof(CS.UnityEngine.Animation))

	self._noHeroText = self:Text("p_text_empty_hero", "formation_nohero")
end

---@param param HeroSelectionMediatorParam
function HeroSelectionComponent:OnShow(param)
    if not param or not param.teamInfo then
        return
    end
    self._teamInfo = param.teamInfo
    if param.otherTeamsInfo and #param.otherTeamsInfo then
        self._otherTeamsInfo = {}
        for __, info in pairs(param.otherTeamsInfo) do
            local teamIndex = info.index
            for index, hero in pairs(info.heroes) do
                self._otherTeamsInfo[hero] ={ _teamIndex = teamIndex, _index = index }
            end
        end
    end

    self._heroSortType = param.heroSortType or -1
    self._onClose = param.onClose
    self._onHeroSelect = param.onHeroSelect

    self:InitData()
    self:Refresh()
    g_Game.EventManager:AddListener(EventConst.SLGTROOP_HERO_CHANGED,Delegate.GetOrCreate(self,self.OnHeroChanged))

	-- 动效
	if (self._animation) then
		self._animation:Play("anim_vx_ui_slg_troop_bottom_open")
	end
end

function HeroSelectionComponent:OnHide(param)
    if (self._onClose) then
        self._onClose(param)
    end
    g_Game.EventManager:RemoveListener(EventConst.SLGTROOP_HERO_CHANGED,Delegate.GetOrCreate(self,self.OnHeroChanged))
end

function HeroSelectionComponent:OnHeroChanged()
    self:RefreshData()
    self:RefreshUI()
end

---@param self HeroSelectionComponent
function HeroSelectionComponent:InitData()
    -- local sortDropDownData = {}
    -- sortDropDownData.items = CommonDropDown.CreateData(
    --     "", "hero_quality",
    --     "", "hero_level",
    --     "", "hero_star"
    -- )
    -- sortDropDownData.defaultId = self._sortMode
    -- sortDropDownData.onSelect = Delegate.GetOrCreate(self, self.OnSortSelect)

    -- self._sortTypeDropDown:FeedData(sortDropDownData)

    -- local filterDropDownData = {}
    -- filterDropDownData.defaultId = self._filtMode
    -- filterDropDownData.onSelect = Delegate.GetOrCreate(self, self.OnFilterSelect)
    -- self._classTypeDropDown:FeedData(filterDropDownData)

end

---@param self HeroSelectionComponent
function HeroSelectionComponent:Refresh()
    if not self._teamInfo then return end
    self:RefreshData()
    self:RefreshUI()
end

---@param self HeroSelectionComponent
function HeroSelectionComponent:RefreshData()
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
        if heroCell
            and not heroCell.isHide
            and heroCell.configCell and heroCell.configCell:Type() == HeroType.Heros
            and not table.ContainsValue( self._teamInfo.heroes,cfgId)
        then
            table.insert(self._heroCellList, heroCell)
        end
    end
    local _selectedHeroIndex = self:GetParentBaseUIMediator().curHeroIndex
    local _selectedHeroId = 0

    if self._teamInfo and #self._teamInfo.heroes > 0 and self._teamInfo.heroes then
        _selectedHeroId = self._teamInfo.heroes[_selectedHeroIndex]
    end
    if _selectedHeroId and _selectedHeroId > 0 then
        self._focusedHeroConfigId = _selectedHeroId
    else
        self._focusedHeroConfigId = 0
    end

end

---@param self HeroSelectionComponent
function HeroSelectionComponent:RefreshUI()
    -- 排序
    self:SortHero()
    --filter
    -- local targetUnitType = -1
    -- if self._filtMode ~= SOLDIER_CALSS_ALL then
    --     if self._filtMode == SOLDIER_CALSS_INFANTRY then
    --         targetUnitType = UnitType.Infantry
    --     elseif self._filtMode == SOLDIER_CALSS_CAVALRY then
    --         targetUnitType = UnitType.Cavalry
    --     elseif self._filtMode == SOLDIER_CALSS_ARCHER then
    --         targetUnitType = UnitType.Archer
    --     end
    -- end
    -- 刷新
    self._heroTable:Clear()
    self._herosData = {}
    for _, cell in pairs(self._heroCellList) do
        -- if targetUnitType >= 0 and cell.configCell:UnitType() ~= targetUnitType then
        --     goto HeroSelectionMediator_RefreshUI_Continue
        -- end
        local heroId = cell.configCell:Id()
        local cellData = {
            nodeName = "child_card_hero_m",
            data = cell,
            onClick = Delegate.GetOrCreate(self, self.OnHeroClick),
            isInCurTeam = table.ContainsValue( self._teamInfo.heroes,heroId),
            isSelected = heroId == self._focusedHeroConfigId,
        }
        if self._otherTeamsInfo[heroId] ~= nil then
            cellData.isInOtherTeam = true
            cellData.teamIndex = self._otherTeamsInfo[heroId]._teamIndex
        else
            cellData.isInOtherTeam = false
        end
        self._herosData[heroId] = cellData
        self._heroTable:AppendData(cellData)
        -- ::HeroSelectionMediator_RefreshUI_Continue::
    end
	self._noHeroText.gameObject:SetActive(#self._heroCellList == 0)
    --self._heroTable:RefreshAllShownItem(false)
end

---@param a HeroConfigCache
---@param b HeroConfigCache
---@return boolean
function HeroSelectionComponent:SortHero_Normal(a,b)
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

    local aIsIn = table.ContainsValue(self._teamInfo.heroes,aid)
    local bIsIn = table.ContainsValue(self._teamInfo.heroes,bid)

    -- 队内其他英雄优先
    if (aIsIn and not bIsIn) then
        return true
    elseif (not bIsIn and bIsIn) then
        return false
    end

    -- -- 按选定模式排序
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
end


---@param a HeroConfigCache
---@param b HeroConfigCache
---@return boolean
function HeroSelectionComponent:SortHero_Slg(a,b)
    local aid = a.configCell:Id()
    local bid = b.configCell:Id()
    local aIsIn = table.ContainsValue(self._teamInfo.heroes,aid)
    local bIsIn = table.ContainsValue(self._teamInfo.heroes,bid)

    -- 队内其他英雄优先
    if (aIsIn and not bIsIn) then
        return true
    elseif (not aIsIn and bIsIn) then
        return false
    elseif (aIsIn and bIsIn) then
        --队内排序优先
        return table.indexof(self._teamInfo.heroes,aid) <  table.indexof(self._teamInfo.heroes,bid)
    end
    --队内排序优先
     if self._otherTeamsInfo[aid] and self._otherTeamsInfo[bid]
        and self._otherTeamsInfo[aid]._teamIndex > 0
        and self._otherTeamsInfo[aid]._teamIndex == self._otherTeamsInfo[bid]._teamIndex
    then
        return self._otherTeamsInfo[aid]._index < self._otherTeamsInfo[bid]._index
     end

    local aUnitType = a.configCell:UnitType()
    local bUnitType = b.configCell:UnitType()
    if aUnitType ~= bUnitType then
        if aUnitType == self._curUnitType and bUnitType ~= self._curUnitType then
            return true
        elseif aUnitType ~= self._curUnitType and bUnitType == self._curUnitType then
            return false
        else
            return aUnitType < bUnitType
        end
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

    return aid < bid
end

function HeroSelectionComponent:SortHero()
    ---@type fun(a:HeroConfigCache,b:HeroConfigCache):boolean
    local comparer = nil
    if self._heroSortType and self._heroSortType > 0 then
        if self._heroSortType == HeroSelectionComponent.HeroSelectionSortType.Slg then
            self._curUnitType = -1
            if self._teamInfo and self._teamInfo.heroes and #self._teamInfo.heroes > 0 then

                for index, tid in ipairs(self._teamInfo.heroes) do
                    local cfg = ConfigRefer.Heroes:Find(tid)
                    if cfg then
                        self._curUnitType = cfg:UnitType()
                        break
                    end
                end


            end
            comparer = Delegate.GetOrCreate(self,self.SortHero_Slg)
        else
            comparer = Delegate.GetOrCreate(self,self.SortHero_Normal)
        end
    else
        comparer = Delegate.GetOrCreate(self,self.SortHero_Normal)
    end

    table.sort(self._heroCellList, comparer)
end

---@param self HeroSelectionComponent
---@param id number
function HeroSelectionComponent:OnSortSelect(id)
    self._sortMode = id
    self:RefreshUI()
end

function HeroSelectionComponent:OnFilterSelect(id)
    self._filtMode = id
    self:RefreshUI()
end

---@param self HeroSelectionComponent
---@param data HeroConfigCache
function HeroSelectionComponent:OnHeroClick(data)
    local heroId = data.configCell:Id()
    local canSelect = true
    if self._onHeroSelect  then
        canSelect = self._onHeroSelect(heroId)
    end
    if canSelect then
        local celldata = self._herosData[heroId]
        self._focusedHeroConfigId = heroId
        self._heroTable:SetToggleSelect(celldata)
    end
    self:Refresh()
end

---@param self HeroSelectionComponent
function HeroSelectionComponent:OnCloseBtnClick()
	self._heroTable:Clear()
	self._heroTable:RefreshAllShownItem()

	-- 动效
	if (self._animation) then
		self._animation:Play("anim_vx_ui_slg_troop_bottom_close")
	end

	TimerUtility.DelayExecute(function()
		self:SetVisible(false)
	end, 0.1)
end

return HeroSelectionComponent
