local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require("ModuleRefer")
local HeroCardPopupMediator = class('HeroCardPopupMediator',BaseUIMediator)

local ONE_PAGE_NUM = 10

function HeroCardPopupMediator:OnCreate()
    BaseUIMediator.OnCreate(self)
    self.compChildPopupBaseL = self:LuaObject('child_popup_base_l')
    self.compTabList = self:LuaObject('p_tab_btn_list')
    self.compTabRecord = self:LuaObject('p_tab_btn_record')
    self.goGroupList = self:GameObject('p_group_list')
    self.tableviewproTableList = self:TableViewPro('p_table_list')
    self.goGroupRecord = self:GameObject('p_group_record')
    self.textTitleRecord = self:Text('p_text_title_record')
    self.textDetail = self:Text('p_text_detail')
    self.textType1 = self:Text('p_text_type_1', I18N.Get("gacha_info_cate_history_type"))
    self.textName1 = self:Text('p_text_name_1', I18N.Get("gacha_info_cate_history_name"))
    self.textTime1 = self:Text('p_text_time_1', I18N.Get("gacha_info_cate_history_time"))
    self.tableviewproTableRecord = self:TableViewPro('p_table_record')
    self.textPage = self:Text('p_text_page')
    self.btnLeft = self:Button('p_btn_left', Delegate.GetOrCreate(self, self.OnBtnLeftClicked))
    self.btnRight = self:Button('p_btn_right', Delegate.GetOrCreate(self, self.OnBtnRightClicked))

    self.textContent = self:Text('p_text_content')
    self.transComtent = self.textContent.transform:GetComponent(typeof(CS.UnityEngine.RectTransform))

    self.tabs = {self.compTabList, self.compTabRecord}
    self.tabNames = {I18N.Get("gacha_info_cate_content"), I18N.Get("gacha_info_cate_history")}
    self.tabGos = {self.goGroupList, self.goGroupRecord}
end

function HeroCardPopupMediator:OnOpened(selectType)
    self.selectType = selectType
    self.compChildPopupBaseL:FeedData({title = I18N.Get("gacha_info_title")})
    for i = 1, #self.tabs do
        local callback = function()
            self:RefrehSelectState(i)
        end
        self.tabs[i]:FeedData({callback = callback, text = self.tabNames[i]})
    end
    self.tableviewproTableList:Clear()
    local gachaTypeCfg = ConfigRefer.GachaType:Find(self.selectType)
    self.tableviewproTableList:AppendDataEx({title = I18N.Get(gachaTypeCfg:Name())}, 0, 0, 0, -1, 0)
    self.tableviewproTableList:AppendDataEx({title = I18N.Get("gacha_info_cate_content_title_3")}, 0, 0, 1, -1, 0)
    local height1 = CS.DragonReborn.UI.UIHelper.CalcTextHeight(I18N.Get("gacha_info_cate_content_info"),self.textContent, self.transComtent.sizeDelta.x)
    self.tableviewproTableList:AppendDataEx({content = I18N.Get("gacha_info_cate_content_info")}, -1, height1, 4, -1, 0)
    self.tableviewproTableList:AppendDataEx({}, 0, 0, 5, -1, 0)
    self.tableviewproTableList:AppendDataEx({title = I18N.Get("gacha_info_cate_content_title_2")}, 0, 0, 1, -1, 0)
    self.tableviewproTableList:AppendDataEx({qualityText = I18N.Get("equip_quality5"), probablilityText = I18N.Get(gachaTypeCfg:ShowSSRRate())}, 0, 0, 6, -1, 0)
    local height2 = CS.DragonReborn.UI.UIHelper.CalcTextHeight(I18N.Get(gachaTypeCfg:ShowSSRContent()),self.textContent, self.transComtent.sizeDelta.x)
    self.tableviewproTableList:AppendDataEx({content = I18N.Get(gachaTypeCfg:ShowSSRContent())}, -1, height2, 4, -1, 0)
    self.tableviewproTableList:AppendDataEx({qualityText = I18N.Get("equip_quality4"), probablilityText = I18N.Get(gachaTypeCfg:ShowSRRate())}, 0, 0, 6, -1, 0)
    local height3 = CS.DragonReborn.UI.UIHelper.CalcTextHeight(I18N.Get(gachaTypeCfg:ShowSRContent()),self.textContent, self.transComtent.sizeDelta.x)
    self.tableviewproTableList:AppendDataEx({content = I18N.Get(gachaTypeCfg:ShowSRContent())}, -1, height3, 4, -1, 0)
    self.tableviewproTableList:AppendDataEx({qualityText = I18N.Get("equip_quality3"), probablilityText = I18N.Get(gachaTypeCfg:ShowRRate())}, 0, 0, 6, -1, 0)
    local height4 = CS.DragonReborn.UI.UIHelper.CalcTextHeight(I18N.Get(gachaTypeCfg:ShowRContent()),self.textContent, self.transComtent.sizeDelta.x)
    self.tableviewproTableList:AppendDataEx({content = I18N.Get(gachaTypeCfg:ShowRContent())}, -1, height4, 4, -1, 0)
    self.tableviewproTableList:AppendDataEx({qualityText = I18N.Get("equip_quality2"), probablilityText = I18N.Get(gachaTypeCfg:ShowNRate())}, 0, 0, 6, -1, 0)
    local height5 = CS.DragonReborn.UI.UIHelper.CalcTextHeight(I18N.Get(gachaTypeCfg:ShowNContent()),self.textContent, self.transComtent.sizeDelta.x)
    self.tableviewproTableList:AppendDataEx({content = I18N.Get(gachaTypeCfg:ShowNContent())}, -1, height5, 4, -1, 0)
    self:RefrehSelectState(1)
    self.initRecord = false
end

function HeroCardPopupMediator:OnClose(param)

end

function HeroCardPopupMediator:RefrehSelectState(index)
    for i = 1, #self.tabs do
        self.tabs[i]:ChangeSelectTab(i == index)
        self.tabGos[i]:SetActive(i == index)
    end
    if index == 2 and not self.initRecord then
        self.initRecord = true
        self:InitRecordList()
    end
end

function HeroCardPopupMediator:InitRecordList()
    local gachaTypeCfg = ConfigRefer.GachaType:Find(self.selectType)
    self.textTitleRecord.text = I18N.Get("gacha_info_cate_history_title")
    self.textDetail.text = I18N.Get("gacha_info_cate_history_info")
    local gachaInfo = ModuleRefer.HeroCardModule:GetGachaInfo()
    local gachaPoolInfo = (gachaInfo.Data or {})[self.selectType]
    self.recordList = gachaPoolInfo and gachaPoolInfo.Record or {}
    self.revertList = {}
    for i = 1, #self.recordList do
        table.insert(self.revertList, 1, self.recordList[i])
    end
    self.recordNum = #self.recordList
    self.pageCount = math.ceil(self.recordNum / ONE_PAGE_NUM)
    self.textPage.text = ""
    self.btnLeft.gameObject:SetActive(self.pageCount > 1)
    self.btnRight.gameObject:SetActive(self.pageCount > 1)
    if self.pageCount > 0 then
        self.curPage = 1
        self:RefreshList()
    end
end

function HeroCardPopupMediator:RefreshList()
    local pageStart = self.curPage * 10 - 9
    local pageEnd = self.curPage * 10
    self.tableviewproTableRecord:Clear()
    for i = 1, self.recordNum do
        if i >= pageStart and i <= pageEnd then
            if self.revertList[i] then
                self.tableviewproTableRecord:AppendData({index = i, info = self.revertList[i]})
            end
        end
    end
    self.textPage.text = self.curPage .. "/" .. self.pageCount
    self.btnLeft.gameObject:SetActive(self.curPage > 1)
    self.btnRight.gameObject:SetActive(self.curPage < self.pageCount)
end

function HeroCardPopupMediator:OnBtnLeftClicked(args)
    self.curPage = self.curPage - 1
    if self.curPage <= 0 then
        self.curPage = 1
    end
    self:RefreshList()
end

function HeroCardPopupMediator:OnBtnRightClicked(args)
    self.curPage = self.curPage + 1
    if self.curPage >= self.pageCount then
        self.curPage = self.pageCount
    end
    self:RefreshList()
end

return HeroCardPopupMediator