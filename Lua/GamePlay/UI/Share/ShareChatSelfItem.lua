local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local ChatShareType = require("ChatShareType")
local ChatShareUtils = require("ChatShareUtils")
local KingdomMapUtils = require("KingdomMapUtils")
local UIMediatorNames = require("UIMediatorNames")
local AllianceWarTabHelper = require("AllianceWarTabHelper")

---@class ShareChatSelfItem : BaseUIComponent
local ShareChatSelfItem = class('ShareChatSelfItem', BaseUIComponent)


function ShareChatSelfItem:OnCreate()
    self.textCoord = self:Text('p_text_coord_r')
    self.textCoordNum = self:Text('p_text_coord_num_r')

    self.goName = self:GameObject('name')
    self.textLv = self:Text('p_text_lv_r')
    self.textName = self:Text('p_text_name_item_r')

    self.goReward = self:GameObject('p_reward_r')
    self.goRewardItem1 = self:GameObject('p_item_4')
    self.goRewardItem2 = self:GameObject('p_item_5')
    self.goRewardItem3 = self:GameObject('p_item_6')
    self.luaGoRewardItem1 = self:LuaObject('child_item_standard_s4')
    self.luaGoRewardItem2 = self:LuaObject('child_item_standard_s5')
    self.luaGoRewardItem3 = self:LuaObject('child_item_standard_s6')
    self.textReward = self:Text('p_text_reward_r')

    self.goItem = self:GameObject('p_item_r')
    self.imgItem = self:Image('p_icon_item_r')
    self.imgPower = self:Image('p_icon_power_r')
    self.textItemNum = self:Text('p_text_number_r')

    self.imgIcon = self:Image('p_icon_coord_r')
	self.btnShareCoordR = self:Button("p_btn_coord_r", Delegate.GetOrCreate(self, self.OnClickShareCoord))

    self.goRewardItemList = {self.goRewardItem1, self.goRewardItem2, self.goRewardItem3}
    self.luaGoRewardItemList = {self.luaGoRewardItem1, self.luaGoRewardItem2, self.luaGoRewardItem3}

    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecondUpdate))
end

function ShareChatSelfItem:OnOpened(param)
    --TODO
end

---@param param ShareChatItemParam
function ShareChatSelfItem:RefreshGroupItemInfo(param)
    if not param then
        return
    end
    self.isActive = true

    self.param = param
    if param.x and param.y then
        self.textCoordNum.text = string.format("X:%d Y:%d", param.x, param.y)
    end

    if param.level then
        self.textLv.text = string.format("Lv.%d", param.level)
    else
        self.textLv.text = ""
    end
    if param.name then
        self.textName.text = param.name
    else
        self.textName.text = ""
    end

    self.goReward:SetActive(false)
    self.goItem:SetActive(false)
    self.imgItem.gameObject:SetActive(false)
    self.imgPower.gameObject:SetActive(false)
    self.textReward.gameObject:SetActive(false)
    local configID = ChatShareUtils.GetConfigIDByType(param.type)
    self.shareConfig = ConfigRefer.ChatShare:Find(configID)
    if not string.IsNullOrEmpty(param.customPic) then
        g_Game.SpriteManager:LoadSprite(param.customPic, self.imgIcon)
    elseif self.shareConfig and not string.IsNullOrEmpty(self.shareConfig:RightIcon()) then
        g_Game.SpriteManager:LoadSprite(self.shareConfig:RightIcon(), self.imgIcon)
    end
    if not self.shareConfig then
        return
    end
    self.textCoord.text = I18N.Get(self.shareConfig:Title())
    if param.type == ChatShareType.WorldEvent then
        local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(param.configID)
        if not eventCfg then
            return
        end
        --取阶段3的奖励
        local itemGroupConfig = ConfigRefer.ItemGroup:Find(eventCfg:PartProgressReward(3):Reward())
        if itemGroupConfig then
            self.goReward:SetActive(true)
            self.goItem:SetActive(false)
            self.textReward.gameObject:SetActive(true)
            self.textReward.text = I18N.Get("chat_share_reward_text")
            local max = itemGroupConfig:ItemGroupInfoListLength() > 3 and 3 or itemGroupConfig:ItemGroupInfoListLength()
            local index = 1
            for i = 1, max do
                index = i
                local itemGroup = itemGroupConfig:ItemGroupInfoList(i)
                self.goRewardItemList[i]:SetActive(true)
                self.luaGoRewardItemList[i]:OnFeedData({configCell = ConfigRefer.Item:Find(itemGroup:Items()), showTips = false})
            end
            for i = index + 1, 3 do
                self.goRewardItemList[i]:SetActive(false)
            end
        end
    elseif param.type == ChatShareType.ResourceField and param.resourceYield then
        self.goItem:SetActive(true)
        self.imgItem.gameObject:SetActive(true)
        local resourceCfg = ConfigRefer.FixedMapBuilding:Find(param.configID)
        if not resourceCfg then
            return
        end
        local outputItem = ConfigRefer.Item:Find(resourceCfg:OutputResourceItem())
        if not outputItem then
            return
        end
        g_Game.SpriteManager:LoadSprite(outputItem:Icon(), self.imgItem)
        self.textItemNum.text = string.format("+%d/h", param.resourceYield)
    elseif param.type == ChatShareType.SlgMonster and param.combatValue then
        self.goItem:SetActive(true)
        self.imgPower.gameObject:SetActive(true)
        self.textItemNum.text = string.format("%d", param.combatValue)
        g_Game.SpriteManager:LoadSprite(self.shareConfig:LeftIcon(), self.imgPower)
    elseif param.type == ChatShareType.AllianceMark then
        self.goItem:SetActive(true)
        self.textItemNum.text = param.shareDesc
    elseif param.type == ChatShareType.SlgBuilding then
        if param.shareDesc then
            self.goItem:SetActive(true)
            if type(param.shareDesc) == "number" then
                self.textItemNum.text = I18N.GetWithParams("village_outpost_info_under_construction_2", param.shareDesc) .. "%"
            end
        else
            self.goItem:SetActive(false)
        end
    end

    --计算生命周期
    if param.shareTime and self.shareConfig then
        self.endTime = param.shareTime + self.shareConfig:ExpireTime()
        local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
        local remainTime = self.endTime - curTime
        if remainTime < 0 then
            --TODO 失效
            self.isActive = false
            g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecondUpdate))
        end
    end
end

function ShareChatSelfItem:SecondUpdate()
    if self.endTime and self.isActive then
        local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
        local remainTime = self.endTime - curTime
        if remainTime < 0 then
            --TODO 失效
            self.isActive = false
            g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecondUpdate))
        end
    end
    
end


function ShareChatSelfItem:OnClose(param)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecondUpdate))
end

function ShareChatSelfItem:OnClickShareCoord()
    if not self.isActive then
        if self.shareConfig then
            local text = I18N.Get(self.shareConfig:ExpireTips())   
            if not string.IsNullOrEmpty(text) then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(self.shareConfig:ExpireTips()))
            else
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("guide_failed"))
            end
            return
        end
    end
	if not self.param.x or not self.param.y then
		return
	end
    if self.param.context and self.param.context.__name == "VillageFastForwardToSelectTroopDelegate" then
        AllianceWarTabHelper.GoToCoord(self.param.x,self.param.y, true, nil, nil, self.param.context)
        self:GetParentBaseUIMediator():CloseSelf()
        return
    end
    local scene = g_Game.SceneManager.current
    if not scene then
        return
    end
    if scene:IsInCity() then
        local callback = function()
            self:OnClickShareCoord()
        end
        scene:LeaveCity(callback)
        return
    end

    g_Game.UIManager:CloseByName(UIMediatorNames.UIChatMediator)
	local staticMapData = KingdomMapUtils.GetStaticMapData()
	local pos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(self.param.x,self.param.y, KingdomMapUtils.GetMapSystem())
    local callback = function()
        if not ModuleRefer.MapFogModule:IsFogUnlocked(self.param.x, self.param.y) then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("chat_share_expired"))
        end
    end
	KingdomMapUtils.GetBasicCamera():LookAt(pos, 2, callback)
    KingdomMapUtils.GetBasicCamera():SetSize(KingdomMapUtils.GetCameraLodData().mapCameraEnterSize)
end


return ShareChatSelfItem