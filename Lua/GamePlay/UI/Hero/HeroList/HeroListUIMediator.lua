local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local UIHeroLocalData = require('UIHeroLocalData')
local CommonDropDown = require('CommonDropDown')
local HeroType = require('HeroType')
local I18N = require('I18N')
local AudioConsts = require("AudioConsts")

---@class HeroListData
---@field selectedHero HeroConfigCache
---@field heroList table<number,HeroConfigCache>
---@field public onHeroSelect fun(data:HeroConfigCache):void

---@class HeroListUIMediator : BaseUIMediator
------@field heroList HeroConfigCache[]
local HeroListUIMediator = class('HeroListUIMediator', BaseUIMediator)

function HeroListUIMediator:ctor()
    self.filter = -1
    self.module = ModuleRefer.HeroModule
end

function HeroListUIMediator:OnCreate()
    self.tableviewproTableHero = self:TableViewPro('p_table_hero');
    ---@type CommonDropDown
    --self.dropDown_TroopType = self:LuaBaseComponent('child_dropdown_troops')
    ---@type CommonDropDown
    self.dropDown_Level = self:LuaBaseComponent('child_dropdown_array')
    ---@type CommonBackButtonComponent
    self.commonBack = self:LuaBaseComponent('child_common_btn_back')
    self.goPadding = self:GameObject('p_pading')
    self.btnLeft = self:Button('p_btn_left', Delegate.GetOrCreate(self, self.OnBtnLeftClicked))
    self.goLeftSelect = self:GameObject('p_select_left')
    self.btnRight = self:Button('p_btn_right', Delegate.GetOrCreate(self, self.OnBtnRightClicked))
    self.goRightSelect = self:GameObject('p_select_right')
    self.textTxtLeft = self:Text('p_txt_left', I18N.Get("hero_type_battle"))
    self.textTxtLeftSelect = self:Text('p_txt_left_select', I18N.Get("hero_type_battle"))
    self.textTxtRight = self:Text('p_txt_right', I18N.Get("hero_type_city"))
    self.textTxtRightSelect = self:Text('p_txt_right_select', I18N.Get("hero_type_city"))
end

function HeroListUIMediator:OnBtnLeftClicked()
    self.goLeftSelect:SetActive(true)
    self.goRightSelect:SetActive(false)
    self.btnLeft.gameObject:SetActive(false)
    self.btnRight.gameObject:SetActive(true)
    self.selectedHero = nil
    self.module:SetHeroSelectType(HeroType.Heros)
    g_Game.EventManager:TriggerEvent(EventConst.HERO_ONCLICK_LIST)
    self:RefreshList()
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_mail_individual)
end

function HeroListUIMediator:OnBtnRightClicked()
    self.goLeftSelect:SetActive(false)
    self.goRightSelect:SetActive(true)
    self.btnLeft.gameObject:SetActive(true)
    self.btnRight.gameObject:SetActive(false)
    self.selectedHero = nil
    self.module:SetHeroSelectType(HeroType.Citizen)
    g_Game.EventManager:TriggerEvent(EventConst.HERO_ONCLICK_LIST)
    self:RefreshList()
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_mail_individual)
end


---@param param HeroListData
function HeroListUIMediator:OnShow(param)
    if param == nil then return end
    local heroType = self.module:GetHeroSelectType()
    self.goPadding:SetActive(false) -- 这个版本临时隐藏内政英雄切换按钮
    self.goLeftSelect:SetActive(heroType == HeroType.Heros)
    self.goRightSelect:SetActive(heroType == HeroType.Citizen)
    self.btnLeft.gameObject:SetActive(heroType == HeroType.Citizen)
    self.btnRight.gameObject:SetActive(heroType == HeroType.Heros)
    self.filter = -1
    self.selectedHero = param.selectedHero
    self:RefreshList()
end

function HeroListUIMediator:RefreshList()
    self.heroList = self.module:GetSortHeroList()
    self:SetHeroTable()
    self.tableviewproTableHero:SetSelectedDataChanged(nil)
    self.tableviewproTableHero:SetSelectedDataChanged(Delegate.GetOrCreate(self,self.OnCellSelect))

    ---@type CommonBackButtonData
    self.commonBack:FeedData({ title = I18N.Get("hero_hero") })

    ---Setup Drop Down
    -- ---@type CommonDropDownData
    -- local troopTypeDropDownData = {}
    -- troopTypeDropDownData.items = CommonDropDown.CreateData(
    --         '',I18N.Get("hero_btn_all"),
    --         'sp_icon_survivor_type_1',I18N.Get("hero_btn_type_1"),
    --         'sp_icon_survivor_type_3',I18N.Get("hero_btn_type_2"),
    --         'sp_icon_survivor_type_2',I18N.Get("hero_btn_type_3")
    -- )
    -- troopTypeDropDownData.defaultId = 1
    -- troopTypeDropDownData.onSelect = Delegate.GetOrCreate(self,self.OnTroopFilterSelect)
    -- troopTypeDropDownData.onClick = function()
    --     g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
    --     if self.dropDown_Level then
    --         self.dropDown_Level.Lua:HideSelf()
    --     end
    -- end
    --self.dropDown_TroopType:FeedData(troopTypeDropDownData)

    ---@type CommonDropDownData
    local levelDropDownData = {}
    levelDropDownData.items = CommonDropDown.CreateData(
            '', I18N.Get("hero_btn_default_sort"),
            '', I18N.Get("hero_btn_quality"),
            '',I18N.Get("hero_btn_level"),
            '',I18N.Get("hero_btn_strengthen")

    )
    levelDropDownData.defaultId = ModuleRefer.HeroModule:GetSortId()
    levelDropDownData.onSelect = Delegate.GetOrCreate(self,self.OnSortSelect)
    levelDropDownData.onClick = function()
        g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
        -- if self.dropDown_TroopType then
        --     self.dropDown_TroopType.Lua:HideSelf()
        -- end
    end
    self.dropDown_Level:FeedData(levelDropDownData)
    --self.dropDown_TroopType:SetVisible(false)
    self:OnSortSelect(ModuleRefer.HeroModule:GetSortId())
end

function HeroListUIMediator:OnHide(param)
    self.tableviewproTableHero:SetSelectedDataChanged(nil)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_cancel)
end

function HeroListUIMediator:OnOpened(param)

end

function HeroListUIMediator:OnClose(param)
end


---OnCellSelect
---@param data HeroConfigCache
function HeroListUIMediator:OnCellSelect(last,data)
    if self.initializing then return end
    g_Game.EventManager:TriggerEvent(EventConst.HERO_SELECT_HERO,data.id)
    self:CloseSelf()
end

function HeroListUIMediator:OnTroopFilterSelect(id)
    -- local UnitType = {
    --     Infantry = 0,  'sp_icon_survivor_type_1'
    --     Cavalry = 1,   'sp_icon_survivor_type_3'
    --     Archer = 2,    'sp_icon_survivor_type_2'
    -- }
    self:SetHeroTable(id - 2)
end

function HeroListUIMediator:OnSortSelect(id)
    if id == UIHeroLocalData.HeroSortType.QUALITY then
        table.sort(self.heroList,function(l, r)
            if l.configCell:Quality() == r.configCell:Quality() then
                return l.configCell:Id() > r.configCell:Id()
            else
                return l.configCell:Quality() > r.configCell:Quality()
            end
        end)
    elseif id == UIHeroLocalData.HeroSortType.LEVEL then
        table.sort(self.heroList,function(l, r)
            if ( l.dbData and l.dbData.Level or -1) == (r.dbData and r.dbData.Level or -1 )then
                return l.configCell:Id() > r.configCell:Id()
            else
                return ( l.dbData and l.dbData.Level or -1) > (r.dbData and r.dbData.Level or -1 )
            end
        end)
    elseif id == UIHeroLocalData.HeroSortType.STRENGTH then
        table.sort(self.heroList,function(l, r)
            if (l.dbData and l.dbData.StarLevel or 0) == (r.dbData and r.dbData.StarLevel or 0)then
                return l.configCell:Id() > r.configCell:Id()
            else
                return (l.dbData and l.dbData.StarLevel or 0) > (r.dbData and r.dbData.StarLevel or 0)
            end
        end)
    else
        self.heroList = self.module:GetSortHeroList()
    end
    self:SetHeroTable()
    ModuleRefer.HeroModule:SaveSortId(id)
end


function HeroListUIMediator:SetHeroTable(filter)
    -- if not self.heroList then return end
    -- if filter then
    --     self.filter = filter
    -- end
    --  --防止初始化过程中消息触发，形成循环逻辑
    --  self.initializing = true
    --  self.tableviewproTableHero:Clear()
    --  for _, v in pairs(self.heroList) do
    --     if self.filter < 0 then
    --       self.tableviewproTableHero:AppendData(v)
    --     elseif  self.filter == v.configCell:UnitType() then
    --         self.tableviewproTableHero:AppendData(v)
    --     end
    --  end
    --  self.tableviewproTableHero:RefreshAllShownItem(false)
    --  if self.selectedHero then
    --      self.tableviewproTableHero:SetToggleSelect(self.selectedHero)
    --  end
    -- self.initializing = false
end

return HeroListUIMediator;
