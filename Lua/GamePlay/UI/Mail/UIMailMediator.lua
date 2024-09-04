---scene:scene_mail

local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
local MailBoxType = require("MailBoxType")
local MailSubType = require("MailSubType")
local Utils = require("Utils")
local MailUtils = require("MailUtils")

---@type NotificationModule
local NM = ModuleRefer.NotificationModule
---@type MailModule
local Mail = ModuleRefer.MailModule
local ColorConsts = require("ColorConsts")
local UIHelper = require("UIHelper")
local EventConst = require("EventConst")
local SdkWrapper = require('SdkWrapper')
local TimeFormatter = require("TimeFormatter")
local ServiceDynamicDescHelper = require("ServiceDynamicDescHelper")

---@class UIMailMediator : BaseUIMediator
---@field super BaseUIMediator
local UIMailMediator = class('UIMailMediator', BaseUIMediator)

local MAIL_CONTENT_TEMPLATE_TEXT = 0
local MAIL_CONTENT_TEMPLATE_IMAGE = 1
local MAIL_CONTENT_TEMPLATE_RANK_TITLE = 2
local MAIL_CONTENT_TEMPLATE_RANK_COMP = 3

local BR_CELL_INDEX_OVERALL = 0
local BR_CELL_INDEX_HEADER = 1
local BR_CELL_INDEX_TEAM = 2
local BR_CELL_INDEX_BUILDING_HEADER = 3
local BR_CELL_INDEX_BUILDING = 4
local BR_CELL_INDEX_REWARD = 5
local BR_CELL_INDEX_EMPTY = 6
local BR_CELL_INDEX_POWERUP = 7
local BR_CELL_INDEX_SIMPLE = 8
local BR_CELL_INDEX_DETAIL_BUTTON = 9

---@alias TableTitleData {id:number, index:number, selected:boolean, onClick:fun(id:number)}

function UIMailMediator:ctor()
    UIMailMediator.super.ctor(self)
    ---@type table<number, wds.Mail>
    self._titleListData = {}
    ---@type table<number, TableTitleData>
    self._tableTitleData = {}
    self._selectedId = 0
    self._selectedType = MailBoxType.System
    self._mailMaxCount = 0
    self._favoriteMaxCount = 0
    self._favoriteMailCount = 0
    self._secondTimer = false
    self._waitingForRewardVideoFinish = false
end

function UIMailMediator:OnCreate()
    self:InitObjects()
end

function UIMailMediator:InitObjects()
    -- 页签与标题列表
    self.tabSystemButton = self:Button('p_btn_system', Delegate.GetOrCreate(self, self.OnTabSystemButtonClicked))
    self.tabSystemCtrl = self:StatusRecordParent('p_btn_system')
    self.tabSystemRedDot = self:GameObject("p_btn_system_reddot")
    
    self.tabPlayButton = self:Button('p_btn_play', Delegate.GetOrCreate(self, self.OnTabPlayButtonClicked))
    self.tabPlayCtrl = self:StatusRecordParent('p_btn_play')
    self.tabPlayRedDot = self:GameObject("p_btn_play_reddot")
    
    self.tabBattleButton = self:Button('p_btn_war', Delegate.GetOrCreate(self, self.OnTabBattleButtonClicked))
    self.tabBattleCtrl = self:StatusRecordParent('p_btn_war')
    self.tabBattleRedDot = self:GameObject("p_btn_war_reddot")

    self.tabResourceButton = self:Button('p_btn_res', Delegate.GetOrCreate(self, self.OnTabResourceButtonClicked))
    self.tabResourceCtrl = self:StatusRecordParent('p_btn_res')
    self.tabResourceRedDot = self:GameObject("p_btn_res_reddot")
    
    self.tabFavoriteButton = self:Button('p_btn_favorite', Delegate.GetOrCreate(self, self.OnTabFavoriteButtonClicked))
    self.tabFavoriteCtrl = self:StatusRecordParent('p_btn_favorite')
    
    self.tableTitleList = self:TableViewPro('p_table_tab')
    self.titleLine = self:GameObject("p_title_line")
    self.readAllButton = self:Button('p_title_read_all_btn', Delegate.GetOrCreate(self, self.OnReadAllButtonClicked))
    self.deleteReadButton = self:Button('p_title_delete_btn', Delegate.GetOrCreate(self, self.OnDeleteReadButtonClicked))
    self.titleRealAllText = self:Text('p_title_read_all_text', 'mail_btn_one_click_read')
    self.titleDeleteReadText = self:Text('p_title_delete_text', 'mail_btn_delete_reads')
    self.mailTitleGroup = self:GameObject("p_mail_title")

    -- 普通邮件
    self.panelContent = self:GameObject('p_content')
    self.mailTitleText = self:Text('p_text_mail_title')
    self.mailSenderNameText = self:Text('p_text_sender_name')
    self.mailSendTimeText = self:Text('p_text_sender_time')
    self.tableMailContentNoAttachment = self:TableViewPro('p_table_content')
    self.tableMailContentAttachment = self:TableViewPro('p_table_content_reward')
    self.panelAttachment = self:GameObject('p_reward_base')
    self.tableAttachment = self:TableViewPro('p_table_reward')
    self.panelExpireTime = self:GameObject('p_time')
    self.mailExpireTimeText = self:Text('p_text_expire_time')

    -- 空面板
    self.panelEmpty = self:GameObject('p_empty')
    self.emptyText = self:Text('p_text_empty', 'mail_tips_no_mail')

    -- 公用
    self.panelRight = self:GameObject("p_group_right")
    self.panelButtons = self:GameObject("p_btns")
    self.mailCountText = self:Text("p_text_amount")
    self.mailCountDescText = self:Text("p_text_mail", I18N.Temp().text_mail_count)
    self.backButton = self:LuaObject('child_common_btn_back')
    self.mailDeleteButton = self:Button('p_btn_mail_delete', Delegate.GetOrCreate(self, self.OnMailDeleteButtonClicked))
    self.mailDeleteButtonText = self:Text("p_text_delete_r", I18N.Temp().text_mail_delete)
    self.mailFavoriteButton = self:Button('p_btn_mail_favorite', Delegate.GetOrCreate(self, self.OnMailFavoriteButtonClicked))
    self.mailFavoriteButtonIconOff = self:GameObject("icon_mail_favorite_off")
    self.mailFavoriteButtonIconOn = self:GameObject("icon_mail_favorite_on")
    self.mailFavoriteText = self:Text("p_text_favorite", I18N.Temp().text_mail_mark)
    ---@type BistateButton
    self.mailClaimButton = self:LuaObject('p_mail_claim_btn')
    ---@type BistateButton
    self.mailAdButton = self:LuaObject("p_mail_ad_btn")
    self.mailGotoButton = self:Button('p_mail_goto_btn', Delegate.GetOrCreate(self, self.OnMailGotoButtonClicked))
    self.mailGotoText = self:Text('p_mail_goto_text', 'mail_btn_go_to')
    self.mailItemTemplateText = self:Text("p_item_text")
    self.mailItemTemplateTextCell = self:BindComponent("p_item_text", typeof(CS.CellSizeComponent))
    self.mailItemTemplateTextReward = self:Text("p_item_text_reward")
    self.mailItemTemplateTextRewardCell = self:BindComponent("p_item_text_reward", typeof(CS.CellSizeComponent))

    -- 战报
    self.panelContentBattle = self:GameObject("p_content_war")
    self.brTable = self:TableViewPro("p_table_war")
    self.p_vx_trigger = self:AnimTrigger("p_vx_trigger")

    -- 采集
    self.panelContentCollect = self:GameObject("p_content_collect")
    self.p_text_title = self:Text("p_text_title", I18N.Get("mining_info_collection_report"))
    self.p_text_content = self:Text("p_text_content", I18N.Get("mining_mail_sender"))
    self.p_text_time = self:Text("p_text_time")
    self.p_text_position = self:Text("p_text_position", I18N.Get("mining_info_collection_report_pos"))
    self.p_text_troop = self:Text("p_text_troop", I18N.Get("mining_info_collection_report_troop"))
    self.p_text_quantity = self:Text("p_text_quantity", I18N.Get("mining_info_collection_volume"))
    self.p_table_collect = self:TableViewPro("p_table_collect")


    -- 攻打排行榜
    self.rankTitle = self:GameObject('p_item_list')
    self.rankComp = self:GameObject('p_item_list_content')
    self.rankTitleReward = self:GameObject('p_item_list_reward')
    self.rankCompReward = self:GameObject('p_item_list_content_reward')

    self.rankTitleCell = self:BindComponent("p_item_list", typeof(CS.CellSizeComponent))
    self.rankCompCell = self:BindComponent("p_item_list_content", typeof(CS.CellSizeComponent))
    self.rankTitleRewardCell = self:BindComponent("p_item_list_reward", typeof(CS.CellSizeComponent))
    self.rankCompRewardCell = self:BindComponent("p_item_list_content_reward", typeof(CS.CellSizeComponent))
end

function UIMailMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.REWARD_VIDEO_FINISH, Delegate.GetOrCreate(self, self.OnRewardVideoFinish))
    g_Game.EventManager:AddListener(EventConst.MAIL_REFRESH, Delegate.GetOrCreate(self, self.RefreshMail))

    if (not self._secondTimer) then
        self._secondTimer = true
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecondTicker))
    end
    self:InitData()
    self:RefreshData(true)
    self:InitUI()
    self:RefreshUI()
end

function UIMailMediator:OnHide(param)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecondTicker))
end

function UIMailMediator:OnClose(param)
    self._secondTimer = false
    g_Game.EventManager:RemoveListener(EventConst.MAIL_REFRESH, Delegate.GetOrCreate(self, self.RefreshMail))
    g_Game.EventManager:RemoveListener(EventConst.REWARD_VIDEO_FINISH, Delegate.GetOrCreate(self, self.OnRewardVideoFinish))
end

---@param self UIMailMediator
---@param delta number
function UIMailMediator:SecondTicker(delta)
    -- self:SelectMail(self._selectedId, true)
    self:RefreshTime()
end

--- 初始化数据
---@param self UIMailMediator
function UIMailMediator:InitData()
    self.backButton:FeedData({title = I18N.Get("mail_mail")})
    self._titleListData = {}
    self._selectedId = 0
    self._selectedType = MailBoxType.System
    self._mailMaxCount = ConfigRefer.MailConst:TotalMailCount()
    self._favoriteMaxCount = ConfigRefer.MailConst:FavouriteMailMaxCount()
end

--- 刷新数据
---@param self UIMailMediator
---@param resetSelectedId boolean
function UIMailMediator:RefreshData(resetSelectedId)
    self._favoriteMailCount = Mail:GetFavoriteMailCount()
    self._totalMailCount = Mail:GetTotalMailCount()
    if (self._selectedType == MailBoxType.Favourite) then
        self._titleListData = Mail:GetFavoriteMailList()
    else
        self._titleListData = Mail:GetSortedMailIdList(self._selectedType)
    end
    if (resetSelectedId) then
        self._selectedId = 0
    end
end

--- 初始化UI
---@param self UIMailMediator
function UIMailMediator:InitUI()
    -- 系统红点
    NM:AttachToGameObject(Mail:GetRedDotSystem(), self.tabSystemRedDot)

    -- 玩法红点
    NM:AttachToGameObject(Mail:GetRedDotGamePlay(), self.tabPlayRedDot)

    -- 战报红点
    NM:AttachToGameObject(Mail:GetRedDotBattleReport(), self.tabBattleRedDot)

    -- 采集报告红点
    NM:AttachToGameObject(Mail:GetRedDotGatherReport(), self.tabResourceRedDot)

    -- Claim button
    if (self.mailClaimButton) then
        self.mailClaimButton:FeedData({onClick = Delegate.GetOrCreate(self, self.OnMailClaimButtonClicked)})
    end

    -- Ad Button
    if (self.mailAdButton) then
        self.mailAdButton:FeedData({onClick = Delegate.GetOrCreate(self, self.OnMailAdButtonClicked)})
    end
end

function UIMailMediator:RefreshMail()
    self:RefreshData()
    self:RefreshUI()
end

--- 刷新UI
---@param self UIMailMediator
function UIMailMediator:RefreshUI()
    -- 通用信息
    self:RefreshGeneralInfo()

    -- 邮件标题列表
    self:RefreshTitleList()

    -- 邮件内容
    self:RefreshSelectedMail()
end

--- 刷新通用信息
---@param self UIMailMediator
function UIMailMediator:RefreshGeneralInfo()
    if (self._totalMailCount >= self._mailMaxCount) then
        self.mailCountDescText.text = I18N.Get("mail_mail_full")
        self.mailCountDescText.color = UIHelper.TryParseHtmlString(ColorConsts.army_red)
    else
        self.mailCountDescText.text = I18N.Temp().text_mail_count
        self.mailCountDescText.color = UIHelper.TryParseHtmlString(ColorConsts.off_white)
    end
    self.mailCountText.text = string.format("%s/%s", self._totalMailCount, self._mailMaxCount)
end

--- 刷新邮件标题列表
---@param self UIMailMediator
function UIMailMediator:RefreshTitleList()
    self._tableTitleData = {}
    self.tableTitleList:Clear()
    local count = 0
    if (self._titleListData) then
        for index, item in pairs(self._titleListData) do
            ---@type TableTitleData
            local data = {}
            data.id = item.id
            data.index = index
            data.selected = (item.id == self._selectedId)
            data.onClick = Delegate.GetOrCreate(self, self.OnMailTitleItemClicked)
            self._tableTitleData[item.id] = data
            self.tableTitleList:AppendData(data)
            count = count + 1
        end
        self.tableTitleList:RefreshAllShownItem(false)
    end
    self.panelRight:SetActive(count > 0)
    self.panelButtons:SetActive(count > 0)
    self.panelEmpty:SetActive(count == 0)
    self.mailTitleGroup:SetActive(count > 0)
    self:ShowMainButtons(count > 0 and self._selectedType ~= MailBoxType.Favourite)
    if (count > 0 and self._selectedId == 0) then
        if (self._titleListData and #self._titleListData > 0) then
            self:SelectMail(self._titleListData[1].id)
        end
    end
end

--- 刷新选中的邮件
---@param self UIMailMediator
function UIMailMediator:RefreshSelectedMail()
    local mail = Mail:GetMail(self._selectedId)
    if (not mail) then
        return
    end

    if (mail.MailBoxType == MailBoxType.BattleReport) then
        -- 战报
        if mail.BattleReport.ReportType == wds.BattleReportType.BattleReportTypeTeamTrusteeship then
            self:ShowRallyReport(mail)
        else
            self:ShowBattleReport(mail)
        end
    elseif mail.MailBoxType == MailBoxType.GatherResource then
        -- 采集
        self:ShowCollectResource(mail)
    else
        -- 普通邮件
        self:ShowNormalMail(mail)
    end
end

--- 显示普通邮件
---@param self UIMailMediator
---@param mail wds.Mail
function UIMailMediator:ShowNormalMail(mail)
    self.panelContent:SetActive(true)
    self.panelContentBattle:SetActive(false)
    self.panelContentCollect:SetActive(false)

    if (not mail) then
        return
    end

    ---@type MailConfigCell
    local mailCfg
    if (mail.mailTid and mail.mailTid > 0) then
        mailCfg = ConfigRefer.Mail:Find(mail.mailTid)
    end

    -- 标题与基本信息
    local title = I18N.Get(mail.Title)
    local senderName = mail.Sender.Name
    local content = mail.Content.pureString
    if (mailCfg) then
        title = I18N.Get(mailCfg:Title())
        senderName = I18N.Get(mailCfg:Sender())
        -- 特殊处理， 视频激励邮件从本地取看过的状态
        if (mailCfg:AdVideo() > 0) then
            local _, _, _, cfg, watchTime = ModuleRefer.RewardVideoModule:GetRewardVideoStatus(mailCfg:AdVideo())
            content = ServiceDynamicDescHelper.ParseWithI18N(mailCfg:Text(), mailCfg:DynamicParamsDescLength(), mailCfg, mailCfg.DynamicParamsDesc, {}, {watchTime, cfg and cfg:Times() or 0}, {}, {})
        elseif mailCfg:HaveDynamicParams() and mail.DynamicParams then
            content = ServiceDynamicDescHelper.ParseWithI18N(mailCfg:Text(), mailCfg:DynamicParamsDescLength(), mailCfg, mailCfg.DynamicParamsDesc, mail.DynamicParams.StringParams,
                                                             mail.DynamicParams.IntParams, mail.DynamicParams.FloatParams, mail.DynamicParams.ConfigParams)
        else
            content = I18N.Get(mailCfg:Text())
        end
    end
    self.mailTitleText.text = title
    self.mailSenderNameText.text = senderName
    self.mailSendTimeText.text = Mail:GetElapsedTimeString(self._selectedId)

    ---@type CS.TableViewPro
    local table
    ---@type CS.UnityEngine.UI.Text
    local textTemplate

    ---@type CS.CellSizeComponent
    local textTemplateCell

    ---@type CS.CellSizeComponent
    local rankTitle

    ---@type CS.CellSizeComponent
    local rankComp

    -- 有附件
    if (Mail:HasAttachment(self._selectedId)) then
        self.tableMailContentNoAttachment.gameObject:SetActive(false)
        self.tableMailContentAttachment.gameObject:SetActive(true)
        table = self.tableMailContentAttachment
        textTemplate = self.mailItemTemplateTextReward
        textTemplateCell = self.mailItemTemplateTextRewardCell
        rankTitle = self.rankTitleRewardCell
        rankComp = self.rankCompRewardCell
        -- 无附件
    else
        self.tableMailContentNoAttachment.gameObject:SetActive(true)
        self.tableMailContentAttachment.gameObject:SetActive(false)
        table = self.tableMailContentNoAttachment
        textTemplate = self.mailItemTemplateText
        textTemplateCell = self.mailItemTemplateTextCell
        rankTitle = self.rankTitleCell
        rankComp = self.rankCompCell
    end

    -- 邮件正文
    table:Clear()
    -- 图片
    if (mailCfg and mailCfg:Picture() > 0) then
        table:AppendData({id = self._selectedId, cfg = mailCfg}, MAIL_CONTENT_TEMPLATE_IMAGE)
    end

    -- 文字
    local textHeight = CS.DragonReborn.UI.UIHelper.CalcTextHeight(content, textTemplate, textTemplateCell.Width)
    table:AppendDataEx({id = self._selectedId, text = content}, textTemplateCell.Width, textHeight, MAIL_CONTENT_TEMPLATE_TEXT)
    local contributeRankData = mail.StructParams.MailRuinRebuildContribution.RankList
    if #contributeRankData > 0 then
        -- 排行榜标题
        ---@type MailRankTitleCompParameter
        local param = 
        {
            RankType = mailCfg:RankType(),
        }
        table:AppendDataEx(param, rankTitle.Width, 0, MAIL_CONTENT_TEMPLATE_RANK_TITLE)
        for k,v in pairs(contributeRankData) do
            -- 排行榜玩家数据
            ---@type MailRankCompParameter
            local param = 
            {
                Damage = v.Contribution,
                PortraitInfo = v.PortraitInfo,
                Name = v.Name,
                Rank = v.Rank,
            }
            table:AppendDataEx(param, rankComp.Width, 0, MAIL_CONTENT_TEMPLATE_RANK_COMP)
        end
    end
    local rankData = mail.StructParams.MailRankList.MemberList
    if #rankData > 0 then
        -- 排行榜标题
        ---@type MailRankTitleCompParameter
        local param =
        {
            RankType = mailCfg:RankType(),
        }
        table:AppendDataEx(param, rankTitle.Width, 0, MAIL_CONTENT_TEMPLATE_RANK_TITLE)
        for k,v in pairs(rankData) do
            -- 排行榜玩家数据
            ---@type MailRankCompParameter
            local param = 
            {
                Damage = v.Damage,
                PortraitInfo = v.PortraitInfo,
                Name = v.Name,
                Rank = v.Rank,
            }
            table:AppendDataEx(param, rankComp.Width, 0, MAIL_CONTENT_TEMPLATE_RANK_COMP)
        end
    end
    table:RefreshAllShownItem()
end

--- 邮件标题条目点击
---@param self UIMailMediator
---@param id number 邮件ID
function UIMailMediator:OnMailTitleItemClicked(id)
    self:SelectMail(id)
end

--- 选择邮件
---@param self UIMailMediator
---@param id number 邮件ID
---@param force boolean 强制
function UIMailMediator:SelectMail(id, force)
    -- Debug
    if (UNITY_EDITOR) then
        g_Logger.LogChannel("Mail", "Select mail id: %s", id)
    end

    -- 设为已读
    self:SetMailAsRead(id)

    if (not force and self._selectedId == id) then
        return
    end

    -- 选定邮件
    if (self._selectedId > 0) then
        local oldItem = self._tableTitleData[self._selectedId]
        if (oldItem) then
            oldItem.selected = false
        end
    end
    local newItem = self._tableTitleData[id]
    if (newItem) then
        newItem.selected = true
    end
    self._selectedId = id
    local mail = Mail:GetMail(self._selectedId)
    local mailCfg = ConfigRefer.Mail:Find(mail.mailTid)
    if (mail) then
        -- 有附件
        if (Mail:HasAttachment(self._selectedId)) then
            local expired = Mail:IsExpired(self._selectedId)
            self.mailFavoriteButton.gameObject:SetActive(expired)
            -- 已领取
            if (mail.Claimed) then
                self.mailClaimButton.CSComponent.gameObject:SetActive(true)
                self.mailAdButton.CSComponent.gameObject:SetActive(false)
                self.mailClaimButton:SetButtonText(I18N.Get("mail_btn_claimed"))
                self.mailClaimButton:SetEnabled(false)
                self.panelExpireTime:SetActive(false)

                -- 激励视频邮件
            elseif (mailCfg and mailCfg:AdVideo() > 0) then
                self.mailClaimButton.CSComponent.gameObject:SetActive(false)
                self.mailAdButton.CSComponent.gameObject:SetActive(true)
                local canWatchVideo, canClaimReward, remainCdTime, rewardCfg = ModuleRefer.RewardVideoModule:GetRewardVideoStatus(mailCfg:AdVideo())
                if (not canWatchVideo and not canClaimReward) then
                    -- g_Logger.Error("激励视频邮件配置错误! id: %s", mailCfg:AdVideo())
                else
                    self.mailAdButton:SetButtonText(I18N.Get(mailCfg:GoText()))
                    -- 可观看视频
                    if (canWatchVideo) then
                        self.mailAdButton:SetEnabled(true)
                        self.panelExpireTime:SetActive(false)
                        if (not canClaimReward) then
                            self.mailAdButton:SetButtonText(I18N.Get(rewardCfg:ButtonName()))
                        end
                    else
                        if (canClaimReward) then
                            self.mailClaimButton.CSComponent.gameObject:SetActive(true)
                            self.mailAdButton.CSComponent.gameObject:SetActive(false)
                            self.mailClaimButton:SetButtonText(I18N.Get("mail_btn_receive"))
                            self.mailClaimButton:SetEnabled(true)
                        else
                            self.mailAdButton:SetEnabled(false)
                            self.mailAdButton:SetButtonText(TimeFormatter.SimpleFormatTime(remainCdTime))
                            self.panelExpireTime:SetActive(true)
                        end
                    end
                end

                -- 已过期
            elseif (expired) then
                self.mailClaimButton.CSComponent.gameObject:SetActive(true)
                self.mailAdButton.CSComponent.gameObject:SetActive(false)
                self.mailClaimButton:SetButtonText(I18N.Get("mail_btn_expired"))
                self.mailClaimButton:SetEnabled(false)
                self.panelExpireTime:SetActive(true)

                -- 未过期
            else
                self.mailClaimButton.CSComponent.gameObject:SetActive(true)
                self.mailAdButton.CSComponent.gameObject:SetActive(false)
                self.mailClaimButton:SetButtonText(I18N.Get("mail_btn_receive"))
                self.mailClaimButton:SetEnabled(true)
            end
            self.panelExpireTime:SetActive(true)
            self.panelAttachment:SetActive(true)
            self:RefreshAttachment()

            -- 无附件
        else
            self.mailFavoriteButton.gameObject:SetActive(true)
            self.mailAdButton.CSComponent.gameObject:SetActive(false)
            self.mailClaimButton.CSComponent.gameObject:SetActive(false)
            self.panelAttachment:SetActive(false)
            self.panelExpireTime:SetActive(false)
        end

        -- 有链接
        if (mail.mailSubType == MailSubType.Survey) then
            if (mailCfg) then
                local key = mailCfg:GoText()
                if (not Utils.IsNullOrEmpty(key)) then
                    -- g_Logger.Trace("*** 邮件: 使用链接指定的前往文字")
                    self.mailGotoText.text = I18N.Get(key)
                end
            end
            self.mailGotoButton.gameObject:SetActive(true)
        else
            self.mailGotoButton.gameObject:SetActive(false)
        end

        -- 删除与收藏按钮
        local favorite = (mail.Favourite == true)
        self.mailFavoriteButtonIconOff:SetActive(not favorite)
        self.mailFavoriteButtonIconOn:SetActive(favorite)
        self.mailDeleteButton.gameObject:SetActive(Mail:CanDelete(self._selectedId))
        self.mailFavoriteButton.gameObject:SetActive(Mail:CanFavorite(self._selectedId))
    end

    -- 刷新
    self.tableTitleList:RefreshAllShownItem()
    self:RefreshSelectedMail()
end

--- 刷新附件
---@param self UIMailMediator
function UIMailMediator:RefreshAttachment()
    local mail = Mail:GetMail(self._selectedId)
    if (not mail) then
        return
    end

    self.tableAttachment:Clear()
    ---@type CS.UnityEngine.UI.ScrollRect
    local scrollRect = self.tableAttachment.gameObject:GetComponent(typeof(CS.UnityEngine.UI.ScrollRect))
    if Utils.IsNotNull(scrollRect) and Utils.IsNotNull(scrollRect.viewport) then
        scrollRect.viewport.offsetMin = CS.UnityEngine.Vector2.zero
        scrollRect.viewport.offsetMax = CS.UnityEngine.Vector2.zero
    end
    local count = 0
    for _, item in pairs(mail.Attachments) do
        if (item) then
            local itemCfg = ConfigRefer.Item:Find(item.ItemID)
            if (itemCfg) then
                count = count + 1
                local data = {configCell = itemCfg, count = item.ItemNum, received = mail.Claimed == true, showTips = true}
                self.tableAttachment:AppendData(data)
            end
        end
    end
    -- self.tableAttachment:RefreshAllShownItem()
    if (count == 0) then
        g_Logger.Error("无有效的附件！请检查配置！")
        -- self.mailClaimButton.enabled = false
    end

    self:RefreshTime()
end

--- 刷新附件过期时间/激励视频CD时间
---@param self UIMailMediator
function UIMailMediator:RefreshTime()
    local mail = Mail:GetMail(self._selectedId)
    if (not mail) then
        return
    end
    local expired = Mail:IsExpired(self._selectedId)
    local mailCfg = ConfigRefer.Mail:Find(mail.mailTid)
    if (not mailCfg) then
        return
    end
    if (not mail.Claimed and mailCfg:AdVideo() > 0) then
        self.mailAdButton.CSComponent.gameObject:SetActive(true)
        local canWatchVideo, canClaimReward, remainCdTime, rewardCfg = ModuleRefer.RewardVideoModule:GetRewardVideoStatus(mailCfg:AdVideo())
        if (not canWatchVideo and not canClaimReward and remainCdTime and remainCdTime > 0) then
            self.mailAdButton:SetButtonText(TimeFormatter.SimpleFormatTime(remainCdTime))
            self.mailAdButton:SetEnabled(false)
        elseif (canClaimReward) then
            self.mailClaimButton:SetButtonText(I18N.Get("mail_btn_receive"))
            self.mailClaimButton.CSComponent.gameObject:SetActive(true)
            self.mailClaimButton:SetEnabled(true)
            self.mailAdButton.CSComponent.gameObject:SetActive(false)
        elseif (canWatchVideo) then
            self.mailClaimButton.CSComponent.gameObject:SetActive(false)
            self.mailAdButton.CSComponent.gameObject:SetActive(true)
            self.mailAdButton:SetButtonText(I18N.Get(rewardCfg:ButtonName()))
            self.mailAdButton:SetEnabled(true)
        else
            self.mailAdButton.CSComponent.gameObject:SetActive(false)
        end
        self.mailExpireTimeText.text = ""
    else
        self.mailAdButton.CSComponent.gameObject:SetActive(false)
        self.mailExpireTimeText.text = Mail:GetExpireTimeString(mail)
    end
end

--- 设置邮件为已读
---@param self UIMailMediator
---@param id number 邮件ID
function UIMailMediator:SetMailAsRead(id)
    if (not Mail:SetAsRead(id)) then
        return
    end

    local data = self._tableTitleData[id]
    if (data) then
        self.tableTitleList:RefreshAllShownItem()
    end
end

--- 点击系统页签
---@param self UIMailMediator
function UIMailMediator:OnTabSystemButtonClicked(args)
    if (self._selectedType == MailBoxType.System) then
        return
    end
    self.tabSystemCtrl:ApplyStatusRecord(0)
    self.tabPlayCtrl:ApplyStatusRecord(1)
    self.tabBattleCtrl:ApplyStatusRecord(1)
    self.tabResourceCtrl:ApplyStatusRecord(1)
    self.tabFavoriteCtrl:ApplyStatusRecord(1)
    self._selectedType = MailBoxType.System
    self.readAllButton.gameObject:SetActive(true)
    self.deleteReadButton.gameObject:SetActive(true)
    self:RefreshData(true)
    self:RefreshUI()
end

--- 点击玩法页签
---@param self UIMailMediator
function UIMailMediator:OnTabPlayButtonClicked(args)
    if (self._selectedType == MailBoxType.GamePlay) then
        return
    end
    self.tabSystemCtrl:ApplyStatusRecord(1)
    self.tabPlayCtrl:ApplyStatusRecord(0)
    self.tabBattleCtrl:ApplyStatusRecord(1)
    self.tabResourceCtrl:ApplyStatusRecord(1)
    self.tabFavoriteCtrl:ApplyStatusRecord(1)
    self._selectedType = MailBoxType.GamePlay
    self:RefreshData(true)
    self:RefreshUI()
end

--- 点击战斗页签
---@param self UIMailMediator
function UIMailMediator:OnTabBattleButtonClicked(args)
    if (self._selectedType == MailBoxType.BattleReport) then
        return
    end
    self.tabSystemCtrl:ApplyStatusRecord(1)
    self.tabPlayCtrl:ApplyStatusRecord(1)
    self.tabBattleCtrl:ApplyStatusRecord(0)
    self.tabResourceCtrl:ApplyStatusRecord(1)
    self.tabFavoriteCtrl:ApplyStatusRecord(1)
    self._selectedType = MailBoxType.BattleReport
    self:RefreshData(true)
    self:RefreshUI()
end

--- 点击采集页签
---@param self UIMailMediator
function UIMailMediator:OnTabResourceButtonClicked(args)
    if (self._selectedType == MailBoxType.GatherResource) then
        return
    end
    self.tabSystemCtrl:ApplyStatusRecord(1)
    self.tabPlayCtrl:ApplyStatusRecord(1)
    self.tabBattleCtrl:ApplyStatusRecord(1)
    self.tabResourceCtrl:ApplyStatusRecord(0)
    self.tabFavoriteCtrl:ApplyStatusRecord(1)
    self._selectedType = MailBoxType.GatherResource
    self:RefreshData(true)
    self:RefreshUI()
end

--- 点击收藏页签
---@param self UIMailMediator
function UIMailMediator:OnTabFavoriteButtonClicked(args)
    if (self._selectedType == MailBoxType.Favourite) then
        return
    end
    self.tabSystemCtrl:SetState(1)
    self.tabPlayCtrl:SetState(1)
    self.tabBattleCtrl:ApplyStatusRecord(1)
    self.tabResourceCtrl:ApplyStatusRecord(1)
    self.tabFavoriteCtrl:SetState(0)
    self._selectedType = MailBoxType.Favourite
    self:RefreshData(true)
    self:RefreshUI()
end

--- 设置主按钮显示
---@param self UIMailMediator
---@param show boolean
function UIMailMediator:ShowMainButtons(show)
    self.titleLine:SetActive(show)
    self.readAllButton.gameObject:SetActive(show)
    self.deleteReadButton.gameObject:SetActive(show)
end

--- 一键读取并领取
---@param self UIMailMediator
function UIMailMediator:OnReadAllButtonClicked(args)
    Mail:ReadAndClaimAll(self._selectedType, function()
        self.tableTitleList:RefreshAllShownItem()
        self:SelectMail(self._selectedId, true)
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("mail_tips_all_claimed"))
    end)
end

--- 删除所有已读邮件
---@param self UIMailMediator
function UIMailMediator:OnDeleteReadButtonClicked(args)
    -- 确认
    ---@type CommonConfirmPopupMediatorParameter
    local dialogParam = {}
    dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    dialogParam.title = I18N.Get("mail_delete_prompt")
    dialogParam.content = I18N.Get("mail_delete_text")
    dialogParam.confirmLabel = I18N.Get("mail_btn_delete")
    dialogParam.cancelLabel = I18N.Get("mail_btn_cancel")
    dialogParam.onConfirm = function(context)
        for i = #self._titleListData, 1, -1 do
            local item = self._titleListData[i]
            if (item) then
                if (Mail:CanDelete(item.id)) then
                    table.remove(self._titleListData, i)
                    self._totalMailCount = self._totalMailCount - 1
                end
            end
        end
        for index, item in ipairs(self._titleListData) do
            self._tableTitleData[item.id].index = index
        end
        Mail:DeleteAllRead(self._selectedType)
        self._selectedId = 0
        -- self:RefreshData(true)
        self:RefreshUI()

        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("mail_tips_all_deleted"))
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
end

--- 删除邮件
---@param self UIMailMediator
function UIMailMediator:OnMailDeleteButtonClicked(args)
    if (not Mail:Delete(self._selectedId)) then
        return
    end
    local data = self._tableTitleData[self._selectedId]
    self:RemoveDataFromTitleList(data)
    self._totalMailCount = self._totalMailCount - 1
    self:RefreshGeneralInfo()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("mail_tips_deleted"))
end

--- 从标题列表移除数据（并尝试选中新数据）
---@param self UIMailMediator
---@param data table
function UIMailMediator:RemoveDataFromTitleList(data)
    if (not data) then
        return
    end

    self:RefreshData()

    -- 列表已空
    if (#self._titleListData <= 0) then
        self:RefreshTitleList()
    else
        -- 列表调序
        for i = data.index, #self._titleListData do
            self._tableTitleData[self._titleListData[i].id].index = i
        end

        -- 尝试选中新的条目
        local newListItem = self._titleListData[data.index]
        if (not newListItem) then
            newListItem = self._titleListData[data.index - 1]
        end
        if (not newListItem) then
            self:RefreshTitleList()
        else
            self.tableTitleList:RemData(data)
            self.tableTitleList:RefreshAllShownItem()
            self:SelectMail(newListItem.id, true)
        end
    end
end

--- 点击收藏按钮
---@param self UIMailMediator
function UIMailMediator:OnMailFavoriteButtonClicked(args)
    if (not self._selectedId) then
        return
    end
    local data = self._tableTitleData[self._selectedId]

    -- 在收藏页签内必定是取消收藏（并从此列表中移除）
    if (self._selectedType == MailBoxType.Favourite) then
        Mail:UnFavorite(self._selectedId)
        self._favoriteMailCount = self._favoriteMailCount - 1
        self:RemoveDataFromTitleList(data)

        -- 其他页签（原地收藏/取消）
    else
        local isFavorite = Mail:IsFavorite(self._selectedId)
        -- 收藏已满
        if (self._favoriteMailCount >= self._favoriteMaxCount and not isFavorite) then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("mail_tips_full_favorite"))
            return
        end
        if (isFavorite) then
            self._favoriteMailCount = self._favoriteMailCount - 1
        else
            self._favoriteMailCount = self._favoriteMailCount + 1
        end
        Mail:ToggleFavorite(self._selectedId)
        self.tableTitleList:RefreshAllShownItem(false)
        self:SelectMail(data.id, true)
    end
end

--- 点击领取按钮
---@param self UIMailMediator
function UIMailMediator:OnMailClaimButtonClicked(args)
    if (not self._selectedId) then
        return
    end
    Mail:ClaimAttachment(self._selectedId, function()
        self.tableTitleList:RefreshAllShownItem()
        self:SelectMail(self._selectedId, true)
    end)
end

--- 点击前往按钮
---@param self UIMailMediator
function UIMailMediator:OnMailGotoButtonClicked(args)
    local mail = Mail:GetMail(self._selectedId)
    if (not mail) then
        return
    end

    ---@type MailConfigCell
    local mailCfg
    if (mail.mailTid and mail.mailTid > 0) then
        mailCfg = ConfigRefer.Mail:Find(mail.mailTid)
    end

    if (not mailCfg) then
        return
    end
    local url = mailCfg:Url()
    if (Utils.IsNullOrEmpty(url)) then
        return
    end

    local account = ModuleRefer.PlayerModule:GetAccountId()
    local langCode = g_Game.LocalizationManager:GetCurrentLanguageIsoCode() or ""
    url = CS.System.String.Format(url, account, langCode)

    CS.UnityEngine.Application.OpenURL(url)

    -- 服务器回调
    local msg = require("ClickMailLinkParameter").new()
    msg.args.MailID = mail.ID
    msg:Send()

end

function UIMailMediator:OnRewardVideoFinish()
    if (not self._waitingForRewardVideoFinish) then
        return
    end
    g_Logger.Trace("*** 视频播放完毕!!!")
    ---TODO
    self._waitingForRewardVideoFinish = false
end

function UIMailMediator:OnMailAdButtonClicked()
    local mail = Mail:GetMail(self._selectedId)
    local mailCfg = ConfigRefer.Mail:Find(mail.mailTid)
    local has, sdkIronSource = SdkWrapper.TryGetSdkModule(CS.SdkAdapter.SdkModels.SdkIronSource)
    if (has) then
        ---@type CS.SdkAdapter.SdkModels.SdkIronSource
        local ironSource = sdkIronSource

        -- 设置参数
        local params = {userid = tostring(ModuleRefer.PlayerModule:GetPlayerId()), conf_id = tostring(mailCfg:AdVideo()), func_type = "1", func_arg1 = tostring(self._selectedId)}
        local rewardCfg = ConfigRefer.RewardVideo:Find(params.conf_id)
        local failStr = "rv_video_loadfail"
        if (rewardCfg) then
            failStr = rewardCfg:LoadFailText()
        end

        g_Logger.Trace("*** 播放视频")
        if (not ironSource:ShowVideo(params)) then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(failStr))
        else
            self._waitingForRewardVideoFinish = true
        end
    end
end

---@param mail wds.Mail
function UIMailMediator:ShowRallyReport(mail)
    self.panelContent:SetActive(false)
    self.panelContentBattle:SetActive(true)
    self.panelContentCollect:SetActive(false)
    self.brTable:Clear()
    
    local reportData = mail.BattleReport

    -- 标题部分
    local title, sp = Mail:GetBattleReportTitle(reportData)
    
    -- 总览
    ---@type BattleReportOverviewCellData
    local overviewData =
    {
        result = mail.BattleReport.Result,
        attacker = reportData.TeamInfo.Captain,
        target = reportData.TeamInfo.MainTarget,
        sceneType = reportData.SceneType,
        titleImageSp = sp,
        titleTimeStr = Mail:GetElapsedTimeString(mail.ID)
    }
    self.brTable:AppendData(overviewData, BR_CELL_INDEX_OVERALL)

    local attackers = MailUtils.GetRallyTroops(reportData.TeamInfo.Attackers)
    local defenders = MailUtils.GetRallyTroops(reportData.TeamInfo.Targets)

    local attackerCount = #attackers
    local defenderCount = #defenders
    local count = math.max(attackerCount, defenderCount)

    -- 条目
    for i = 1, count do
        local teamData = {attacker = attackers[i], target = defenders[i]}
        self.brTable:AppendData(teamData, BR_CELL_INDEX_SIMPLE)
    end

    -- 集结详细信息按钮
    self.brTable:AppendData(mail, BR_CELL_INDEX_DETAIL_BUTTON)
end

--- 显示战报
---@param self UIMailMediator
---@param mail wds.Mail
function UIMailMediator:ShowBattleReport(mail)
    self.panelContent:SetActive(false)
    self.panelContentBattle:SetActive(true)
    self.panelContentCollect:SetActive(false)

    local reportData = mail.BattleReport

    -- 标题部分
    local title, sp = Mail:GetBattleReportTitle(reportData)

    -- 内容部分
    self.brTable:Clear()
    for _, record in ipairs(reportData.Records) do
        -- 总览
        ---@type BattleReportOverviewCellData
        local overviewData =
        {
            result = record.Result,
            attacker = record.Attacker.BasicInfo,
            target = record.Target.BasicInfo,
            sceneType = reportData.SceneType,
            titleImageSp = sp,
            titleTimeStr = Mail:GetElapsedTimeString(mail.ID),
            showHp = true
        }
        self.brTable:AppendData(overviewData, BR_CELL_INDEX_OVERALL)

        -- 题头
        ---@type BattleReportHeaderCellData
        local headerData = {record = record}
        self.brTable:AppendData(headerData, BR_CELL_INDEX_HEADER)

        -- 部队
        local attackers = MailUtils.GetHerosAndPets(record.Attacker)
        local defenders = MailUtils.GetHerosAndPets(record.Target)
        local count = math.max(#attackers, #defenders)
        
        for index = 1, count do
            ---@type BattleReportTeamCellData
            local teamData = {record = record, attacker = attackers[index], defender = defenders[index]}
            self.brTable:AppendData(teamData, BR_CELL_INDEX_TEAM)
        end

        -- 奖励
        if (record.Reward and record.Reward.RewardItems and record.Reward.RewardItems:Count() > 1) then
            ---@type BattleReportRewardCellData
            local rewardData = {reward = record.Reward}
            self.brTable:AppendData(rewardData, BR_CELL_INDEX_REWARD)
        end

        -- 我要变强
        if (record.Result == wds.BattleResult.BattleResult_Loss) then
            ---@type BattleReportPowerUpCellData
            local data = {onClick = Delegate.GetOrCreate(self, self.OnBattleReportPowerUpButtonClick)}
            self.brTable:AppendData(data, BR_CELL_INDEX_POWERUP)
        end

        -- 分隔
        self.brTable:AppendData({}, BR_CELL_INDEX_EMPTY)
    end

    -- 按钮状态
    self.mailGotoButton.gameObject:SetActive(false)
    self.mailAdButton.CSComponent.gameObject:SetActive(false)
    self.mailClaimButton.CSComponent.gameObject:SetActive(false)

    -- 删除与收藏按钮
    local favorite = (mail.Favourite == true)
    self.mailFavoriteButtonIconOff:SetActive(not favorite)
    self.mailFavoriteButtonIconOn:SetActive(favorite)
    self.mailDeleteButton.gameObject:SetActive(Mail:CanDelete(self._selectedId))
    self.mailFavoriteButton.gameObject:SetActive(Mail:CanFavorite(self._selectedId))
end

---@param mail wds.Mail
function UIMailMediator:ShowCollectResource(mail)
    self.panelContent:SetActive(false)
    self.panelContentBattle:SetActive(false)
    self.panelContentCollect:SetActive(true)

    ---@type wds.MailResourceField
    local mailResource = mail.GatherReport

    local length = table.nums(mailResource.GatherInfos)
    if length > 0 then
        local gatherInfo = mailResource.GatherInfos[length]
        self.p_text_time.text = TimeFormatter.TimeToLocalTimeZoneDateTimeStringUseFormat(gatherInfo.EndTime.Seconds, "yyyy/MM/dd HH:mm:ss")

        self.p_table_collect:Clear()
        for _, gatherInfo in ipairs(mailResource.GatherInfos) do
            self.p_table_collect:AppendData(gatherInfo)
        end
        self.p_table_collect:RefreshAllShownItem()
    else
        self.p_text_time.text = string.Empty
        self.p_table_collect:Clear()
    end
end

function UIMailMediator:OnBattleReportPowerUpButtonClick()
    g_Game.UIManager:Open(UIMediatorNames.UIStrengthenMediator)
end

return UIMailMediator
