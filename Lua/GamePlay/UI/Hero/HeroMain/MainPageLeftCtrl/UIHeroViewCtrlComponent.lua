local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local UIHeroLocalData = require('UIHeroLocalData')
local NotificationType = require('NotificationType')
local I18N = require('I18N')
local HeroType = require('HeroType')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local ConfigRefer = require('ConfigRefer')
local UIMediatorNames = require('UIMediatorNames')
local AudioConsts = require("AudioConsts")
local CommonDropDown = require('CommonDropDown')

---@class UIHeroViewCtrlComponent : BaseUIComponent
---@field parentMediator UIHeroMainUIMediator
---@field heroList table<number,HeroConfigCache>
local UIHeroViewCtrlComponent = class('UIHeroViewCtrlComponent', BaseUIComponent)

function UIHeroViewCtrlComponent:ctor()
    self.module = ModuleRefer.HeroModule
    self.selectTagId = 0
end

function UIHeroViewCtrlComponent:OnCreate()
    self.tableviewproTableHero = self:TableViewPro('p_table_hero')
    self.tableHeroRect = self:RectTransform('p_table_hero')
    -- local lp = tableHeroRect.localPosition
    -- local ap = tableHeroRect.anchoredPosition
    -- local sd = tableHeroRect.sizeDelta
    -- tableHeroRect.pivot = CS.UnityEngine.Vector2(0, 1)
    -- ap.y = lp.y * -2
    -- tableHeroRect.anchoredPosition = ap
    -- sd.y = ap.y
    -- tableHeroRect.sizeDelta = sd
    self.goLine = self:GameObject("p_line")
    self.btnUnfold = self:Button('p_btn_unfold_1', Delegate.GetOrCreate(self, self.OnBtnUnfold1Clicked))

    self.btnLeft = self:Button('p_btn_left', Delegate.GetOrCreate(self, self.OnBtnChangeClicked))
    self.parentMediator = self:GetParentBaseUIMediator()
    self.firstOpen = true
    self.statusRecordParent = self:StatusRecordParent('')
    ---@type CommonDropDown
    self.child_dropdown = self:LuaBaseComponent('child_dropdown')

    -- 筛选
    self.btnAll = self:Button('p_btn_all', Delegate.GetOrCreate(self, self.OnBtnAllClicked))
    self.textAll = self:Text('p_text_all', "hero_pet_carried_all")
    self.statusBtnAll = self:StatusRecordParent('p_btn_all')
    self.luaTag1 = self:LuaObject("p_btn_attribute_01")
    self.luaTag2 = self:LuaObject("p_btn_attribute_02")
    self.luaTag3 = self:LuaObject("p_btn_attribute_03")
    self.luaTag4 = self:LuaObject("p_btn_attribute_04")
    self.luaTag5 = self:LuaObject("p_btn_attribute_05")
    self.luaFilters = {self.luaTag1, self.luaTag2, self.luaTag3, self.luaTag4, self.luaTag5}

    self.textHeroQuantity = self:Text('p_text_hero_quantity')
end

function UIHeroViewCtrlComponent:OnBtnChangeClicked()
    if self.heroType == HeroType.Citizen then
        self.module:SetHeroSelectType(HeroType.Heros)
    else
        self.module:SetHeroSelectType(HeroType.Citizen)
    end
    -- self.innerSelect = false
    self:RefreshList()
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_mail_individual)
end

function UIHeroViewCtrlComponent:PlayAnim()
    if self.module:GetHeroSelectType() == HeroType.Citizen then
    else
    end
end

function UIHeroViewCtrlComponent:OnShow()
    self.heros = {}
    self.isFold = true
    local node = ModuleRefer.NotificationModule:GetDynamicNode("HeroCitizenNode", NotificationType.HERO_CITIZEN)
    -- ModuleRefer.NotificationModule:AttachToGameObject(node, self.notifyNode.go, self.notifyNode.redDot)
    self.heroList = self.module:GetAllHeroConfig()
    self.sortList = self.module:GetSortHeroList()
    self:RefreshList()
    self:SetFilterContent()
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.tableHeroRect)
    g_Game.EventManager:AddListener(EventConst.HERO_ONCLICK_LIST, Delegate.GetOrCreate(self, self.PlayAnim))
    g_Game.EventManager:AddListener(EventConst.HERO_DATA_UPDATE, Delegate.GetOrCreate(self, self.LevelUpdate))
    g_Game.EventManager:AddListener(EventConst.HERO_STYLE_FILTER_CLICK, Delegate.GetOrCreate(self, self.OnFiltHeroes))
end

function UIHeroViewCtrlComponent:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.HERO_ONCLICK_LIST, Delegate.GetOrCreate(self, self.PlayAnim))
    g_Game.EventManager:RemoveListener(EventConst.HERO_DATA_UPDATE, Delegate.GetOrCreate(self, self.LevelUpdate))
    g_Game.EventManager:RemoveListener(EventConst.HERO_STYLE_FILTER_CLICK, Delegate.GetOrCreate(self, self.OnFiltHeroes))
end

function UIHeroViewCtrlComponent:RefreshLeftState(isInEquipTab)
    self.isInEquipTab = isInEquipTab
    self.btnUnfold.gameObject:SetActive(not isInEquipTab)
    -- self.innerSelect = false
    if self.isInEquipTab then
        self.tableviewproTableHero:Clear()
        local sortList = self.sortList
        local outList = ModuleRefer.HeroModule:GetHeroOutList()
        if outList and #outList then
            sortList = outList
            for _, heroId in ipairs(sortList) do
                local hero = self.heroList[heroId]
                if self.selectTagId == 0 or hero.configCell:AssociatedTagInfo() == self.selectTagId then
                    self.tableviewproTableHero:AppendData(hero)
                    self.tableviewproTableHero:AppendCellCustomName(hero.configCell:Name())
                end
            end
            self.btnUnfold.gameObject:SetActive(false)
        else
            for _, v in ipairs(sortList) do
                if v:HasHero() then
                    if self.selectTagId == 0 or v.configCell:AssociatedTagInfo() == self.selectTagId then
                        self.tableviewproTableHero:AppendData(v)
                        self.tableviewproTableHero:AppendCellCustomName(v.configCell:Name())
                    end
                end
            end
        end
        self.goLine:SetActive(#sortList >= 6)
        self.tableviewproTableHero:RefreshAllShownItem()
        local selectData = self.parentMediator:GetSelectHero()
        if selectData then
            self.tableviewproTableHero:SetToggleSelect(selectData)
            self.tableviewproTableHero:SetFocusData(selectData)
        end
        self.tableviewproTableHero:SetSelectedDataChanged(nil)
        self.tableviewproTableHero:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnInnerHeroSelect))
    else
        self:RefreshList()
    end
end

function UIHeroViewCtrlComponent:RefreshList()
    if self.isInEquipTab then
        return
    end
    if self.heroType ~= self.module:GetHeroSelectType() then
        g_Game.EventManager:TriggerEvent(EventConst.HERO_SELECT_MAINPAGE, UIHeroLocalData.MainUIPageType.MAIN_PAGE, UIHeroLocalData.MainUITabType.INFO)
    end
    self.heroType = self.module:GetHeroSelectType()
    if self.firstOpen then
        self.firstOpen = false
    end

    -- if self.innerSelect then
    --     self.innerSelect = false
    --     local selectData = self.parentMediator:GetSelectHero()
    --     self.tableviewproTableHero:RefreshAllShownItem()
    --     if selectData then
    --         self.tableviewproTableHero:SetSelectedDataChanged(nil)
    --         self.tableviewproTableHero:SetToggleSelect(selectData)
    --         self.tableviewproTableHero:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnInnerHeroSelect))
    --     end
    --     return
    -- end
    self.tableviewproTableHero:Clear()
    local sortList
    local outList = ModuleRefer.HeroModule:GetHeroOutList()
    local numHasHero = 0
    if outList and #outList then
        sortList = outList
        for _, heroId in ipairs(sortList) do
            local hero = self.heroList[heroId]
            if hero:HasHero() then
                numHasHero = numHasHero + 1
            end
            if self.selectTagId == 0 or hero.configCell:AssociatedTagInfo() == self.selectTagId then
                self.tableviewproTableHero:AppendData(hero)
                self.tableviewproTableHero:AppendCellCustomName(hero.configCell:Name())
            end
        end
        self.btnUnfold.gameObject:SetActive(false)
    else
        sortList = self.sortList
        for _, v in ipairs(sortList) do
            if v:HasHero() then
                numHasHero = numHasHero + 1
            end
            if self.selectTagId == 0 or v.configCell:AssociatedTagInfo() == self.selectTagId then
                self.tableviewproTableHero:AppendData(v)
                self.tableviewproTableHero:AppendCellCustomName(v.configCell:Name())
            end
        end
        self.btnUnfold.gameObject:SetActive(true)
    end
    self.goLine:SetActive(#sortList >= 6)
    self.tableviewproTableHero:RefreshAllShownItem()
    local selectData = self.parentMediator:GetSelectHero()
    if selectData then
        self.tableviewproTableHero:SetToggleSelect(selectData)
        self.tableviewproTableHero:SetFocusData(selectData)
    end
    self.tableviewproTableHero:SetSelectedDataChanged(nil)
    self.tableviewproTableHero:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnInnerHeroSelect))
    self.textHeroQuantity.text = ("%d / %d"):format(numHasHero, #sortList)
end

function UIHeroViewCtrlComponent:LevelUpdate(changeTable)
    if changeTable.Add then
        return
    end

    for k, v in pairs(changeTable) do
        local heroCfg = ConfigRefer.Heroes:Find(k)
        if heroCfg == nil then
            g_Logger.Error("策划没配英雄 ConfigRefer.Heroes："..k)
            goto continue
        end
        local name = ConfigRefer.Heroes:Find(k):Name()
        local index = self.tableviewproTableHero:GetIndexByCustomName(name)
        local cell = self.tableviewproTableHero:GetCell(index)
        if cell then
            cell:FeedData(self.heroList[k])
        end
        ::continue::
    end
end

function UIHeroViewCtrlComponent:OnOpened()
end

function UIHeroViewCtrlComponent:OnClose()
    self.tableviewproTableHero:SetSelectedDataChanged(nil)
end

function UIHeroViewCtrlComponent:OnFeedData()
end

function UIHeroViewCtrlComponent:OnInnerHeroSelect(_, data)
    -- self.innerSelect = true
    self:OnHeroSelect(_, data)
end

---OnHeroSelect
---@param data HeroConfigCache
function UIHeroViewCtrlComponent:OnHeroSelect(_, data)
    if data == nil or data.configCell == nil then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.HERO_SELECT_HERO, data.id)
end

function UIHeroViewCtrlComponent:OnBtnUnfold1Clicked(args)
    self.isFold = not self.isFold
    if self.isFold then
        self.sortList = self.module:GetSortHeroList()
        self:RefreshList()
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.tableHeroRect)
    end
    self.statusRecordParent:ApplyStatusRecord(self.isFold and 0 or 1)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
end

function UIHeroViewCtrlComponent:SetFilterContent()
    ---@type CommonDropDownData
    local levelDropDownData = {}
    levelDropDownData.items = CommonDropDown.CreateData('', I18N.Get("hero_btn_default_sort"), '', I18N.Get("hero_btn_quality"), '', I18N.Get("hero_btn_level"), '', I18N.Get("hero_btn_strengthen"))
    levelDropDownData.defaultId = 1
    levelDropDownData.onSelect = Delegate.GetOrCreate(self, self.OnSortSelect)
    levelDropDownData.onClick = function()
        g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
    end
    self.child_dropdown:FeedData(levelDropDownData)
    for i, tag in ConfigRefer.AssociatedTag:ipairs() do
        local luaTag = self.luaFilters[i]
        if luaTag then
            ---@type UIHeroAttrFilterBtnData
            local data = {}
            data.index = i
            data.tagId = tag:Id()
            luaTag:FeedData(data)
        end
    end
end

function UIHeroViewCtrlComponent:OnFiltHeroes(index, tagId)
    self.selectTagId = tagId
    self.statusBtnAll:ApplyStatusRecord(0)
    for i, luaTag in ipairs(self.luaFilters) do
        luaTag:SetSelect(i == index)
    end
    self:RefreshList()
end

function UIHeroViewCtrlComponent:OnBtnAllClicked()
    self:OnFiltHeroes(0, 0)
    self.statusBtnAll:ApplyStatusRecord(1)
end

function UIHeroViewCtrlComponent:OnSortSelect(id)
    if id == UIHeroLocalData.HeroSortType.QUALITY then
        table.sort(self.sortList, function(l, r)
            if l:HasHero() and r:HasHero() then
                if (l.dbData and l.dbData.RealLevel or -1) == (r.dbData and r.dbData.RealLevel or -1) then
                else
                    return (l.dbData and l.dbData.RealLevel or -1) > (r.dbData and r.dbData.RealLevel or -1)
                end
            elseif l:HasHero() or r:HasHero() then
                return l:HasHero()
            end

            -- 默认 品质>Id
            if l.configCell:Quality() == r.configCell:Quality() then
                return l.configCell:Id() > r.configCell:Id()
            else
                return l.configCell:Quality() > r.configCell:Quality()
            end
        end)
    elseif id == UIHeroLocalData.HeroSortType.LEVEL then
        table.sort(self.sortList, function(l, r)
            if l:HasHero() and r:HasHero() then
                if (l.dbData and l.dbData.RealLevel or -1) == (r.dbData and r.dbData.RealLevel or -1) then
                else
                    return (l.dbData and l.dbData.RealLevel or -1) > (r.dbData and r.dbData.RealLevel or -1)
                end
            elseif l:HasHero() or r:HasHero() then
                return l:HasHero()
            end

            -- 默认 品质>Id
            if l.configCell:Quality() == r.configCell:Quality() then
                return l.configCell:Id() > r.configCell:Id()
            else
                return l.configCell:Quality() > r.configCell:Quality()
            end
        end)
    elseif id == UIHeroLocalData.HeroSortType.STRENGTH then
        table.sort(self.sortList, function(l, r)
            if l:HasHero() and r:HasHero() then
                if (l.dbData and l.dbData.StarLevel or -1) == (r.dbData and r.dbData.StarLevel or -1) then
                else
                    return (l.dbData and l.dbData.StarLevel or -1) > (r.dbData and r.dbData.StarLevel or -1)
                end
            elseif l:HasHero() or r:HasHero() then
                return l:HasHero()
            end

            -- 默认 品质>Id
            if l.configCell:Quality() == r.configCell:Quality() then
                return l.configCell:Id() > r.configCell:Id()
            else
                return l.configCell:Quality() > r.configCell:Quality()
            end
        end)
    else
        self.sortList = self.module:GetSortHeroList()
    end
    -- self.module:SaveSortId(id)
    self:RefreshList()
end
return UIHeroViewCtrlComponent;
