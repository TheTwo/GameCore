---Scene Name : scene_city_popup_egg
local CityCommonRightPopupUIMediator = require ('CityCommonRightPopupUIMediator')
local I18N = require('I18N')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local CityHatchI18N = require("CityHatchI18N")
local ModuleRefer = require("ModuleRefer")
local CityUtils = require("CityUtils")
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local TimeFormatter = require("TimeFormatter")
local ConfigRefer = require("ConfigRefer")
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")

---@class CityHatchEggUIMediator:CityCommonRightPopupUIMediator
local CityHatchEggUIMediator = class('CityHatchEggUIMediator', CityCommonRightPopupUIMediator)

function CityHatchEggUIMediator:OnCreate()
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))
    self._p_focus_target = self:Transform("p_focus_target")
    self._p_btn_exit = self:Button("p_btn_exit", Delegate.GetOrCreate(self, self.CloseSelf))

    self._p_content = self:StatusRecordParent("p_content")
    ---@type CityHatchEggUISelectPanel
    self._p_group_left = self:LuaObject("p_group_left")
    self._canvas_group_left = self:BindComponent("p_group_left", typeof(CS.UnityEngine.CanvasGroup))
    ---家具名
    self._p_text_title = self:Text("p_text_title")
    ---已拥有蛋数量
    self._p_btn_egg_storehouse = self:Button("p_btn_egg_storehouse", Delegate.GetOrCreate(self, self.OnClickOwnedEgg))
    self._p_text_number_egg = self:Text("p_text_number_egg")
    ---秒开详情
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickDetails))
    self._p_text_time = self:Text("p_text_time")
    ---秒开入口按钮
    self._p_btn_batch = self:Button("p_btn_batch", Delegate.GetOrCreate(self, self.OnClickHatchImmediatelyBubble))
    self._p_text_batch = self:Text("p_text_batch", CityHatchI18N.UIButton_BatchHatch)
    self._p_text_batch_number = self:Text("p_text_batch_number")
    self._vx_trigger_batch = self:AnimTrigger("vx_trigger_batch")
    ---秒开按钮气泡组
    self._p_group_bubble_open_all = self:Transform("p_group_bubble_open_all")
    self._p_btn_open_1 = self:LuaBaseComponent("p_btn_open_1")
    self._pool_bubble_batch_open = LuaReusedComponentPool.new(self._p_btn_open_1, self._p_group_bubble_open_all)
    ---右侧底部秒开按钮
    self._p_group_bubble_open = self:Transform("p_group_bubble_open")
    self._p_btn_open_all = self:LuaBaseComponent("p_btn_open_all")
    self._pool_batch_open = LuaReusedComponentPool.new(self._p_btn_open_all, self._p_group_bubble_open)
    ---走时间条的孵化成功特效
    self._p_finish = self:GameObject("p_finish")
    ---选蛋入口
    self._p_btn_egg = self:Button("p_btn_egg", Delegate.GetOrCreate(self, self.OnClickSelectEgg))
    self._icon_empty = self:GameObject("icon_empty")
    self._p_text_empty = self:Text("p_text_empty", CityHatchI18N.UIHint_NoEgg)
    ---选好的蛋图标
    self._p_icon_egg = self:Image("p_icon_egg")
    self._p_btn_change = self:Button("p_btn_change", Delegate.GetOrCreate(self, self.OnClickSelectEgg))
    ---蛋不舒服的提示文本
    self._p_bubble_1 = self:GameObject("p_bubble_1")
    self._p_text_content_1 = self:Text("p_text_content_1")
    ---蛋不舒服Goto
    self._p_bubble_2 = self:GameObject("p_bubble_2")
    self._p_text_content_2 = self:Text("p_text_content_2")
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickGotoBuildBuffFurniture))
    ---底部按钮组
    self._group_bottom = self:GameObject("group_bottom")
    self._p_time_need = self:GameObject("p_time_need")
    self.canvas_time_need = self:BindComponent("p_time_need", typeof(CS.UnityEngine.CanvasGroup))
    ---@type CommonTimer
    self._child_time = self:LuaObject("child_time")
    ---花钱秒时间按钮
    self._btn_e = self:GameObject("btn_e")
    ---@type GoldenCostPreviewButton
    self._child_comp_btn_e_l = self:LuaObject("child_comp_btn_e_l")
    ---普通开始按钮
    self._btn_b = self:GameObject("btn_b")
    ---@type BistateButton
    self._child_comp_btn_b = self:LuaObject("child_comp_btn_b")
    ---孵蛋进度条
    self._p_progress = self:GameObject("p_progress")
    self._p_progress_n = self:Slider("p_progress_n")
    ---蛋名字
    self._p_text_name = self:Text("p_text_name")
    ---@type CommonTimer
    self._child_time_progress = self:LuaObject("child_time_progress")

    ---开始孵蛋后的特效
    self._p_egg_trigger = self:AnimTrigger("p_egg_trigger")

    ---蛋详情Tips
    ---@type CommonItemDetails
    self._child_tips_item = self:LuaObject("child_tips_item")
    ---左侧底部开蛋小按钮点出的tips
    self._group_left = self:GameObject("group_left")
    self._p_group_list_eggs = self:LuaObject("p_group_list_eggs")

    self._vx_trigger = self:AnimTrigger("vx_trigger")
end

---@param param CityHatchEggUIParameter
function CityHatchEggUIMediator:OnOpened(param)
    self.param = param
    self.city = param.city
    self.param:OnMediatorOpen(self)

    self._p_text_title.text = param:GetTitle()
    self._p_text_time.text = I18N.GetWithParams("animal_work_interface_desc16", TimeFormatter.TimerStringFormat(param:GetHatchTimeDecrease(), true))

    self._p_text_number_egg.text = tostring(param:GetOwnedEggCount())
    self._p_text_batch_number.text = ("x%d"):format(param:GetCanHatchImmediatelyCount())

    self._p_group_bubble_open_all:SetVisible(false)

    self:UpdateUI(true)
    CityCommonRightPopupUIMediator.OnOpened(self, param)
    g_Game.EventManager:AddListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.OnItemCountChange))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
    g_Game.EventManager:AddListener(EventConst.UI_BUTTON_CLICK_PRE, Delegate.GetOrCreate(self, self.OnButtonClickPre))
end

function CityHatchEggUIMediator:OnClose(param)
    CityCommonRightPopupUIMediator.OnClose(self, param)
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
    g_Game.EventManager:RemoveListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.OnItemCountChange))
    g_Game.EventManager:RemoveListener(EventConst.UI_BUTTON_CLICK_PRE, Delegate.GetOrCreate(self, self.OnButtonClickPre))
    if self.param then
        self.param:OnMediatorClose(self)
    end
    self:RemoveTicker()
end

---@return CS.UnityEngine.RectTransform
function CityHatchEggUIMediator:GetFocusAnchor()
    return self._p_focus_target
end

---@return CS.UnityEngine.Vector3
function CityHatchEggUIMediator:GetWorldTargetPos()
    return self.param:GetWorldTargetPos()
end

---@return BasicCamera
function CityHatchEggUIMediator:GetBasicCamera()
    return self.city:GetCamera()
end

---@return number
function CityHatchEggUIMediator:GetZoomSize()
    return self.param:GetZoomSize()
end

function CityHatchEggUIMediator:OnClickHatchImmediatelyBtn()
    self:OnClickHatchImmediatelyImpl(self._pool_batch_open, self._p_group_bubble_open)
end

function CityHatchEggUIMediator:OnClickHatchImmediatelyBubble()
    self:OnClickHatchImmediatelyImpl(self._pool_bubble_batch_open, self._p_group_bubble_open_all)
end

function CityHatchEggUIMediator:OnClickHatchImmediatelyImpl(pool, parent)
    local count = self.param:GetCanHatchImmediatelyCount()
    parent:SetVisible(count > 0)
    if count <= 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("animal_work_interface_desc18"))
        return
    end

    pool:HideAll()
    if count >= 30 then
        local comp = pool:GetItem()
        comp:FeedData({param = self.param, count = 30})
    end

    if count >= 10 then
        local comp = pool:GetItem()
        comp:FeedData({param = self.param, count = 10})
    else
        local comp = pool:GetItem()
        comp:FeedData({param = self.param, count = count})
    end
end

function CityHatchEggUIMediator:OnClickOwnedEgg()
    self:HideTips()
    self:ShowOwnedEggs()
end

function CityHatchEggUIMediator:OnClickSelectEgg()
    if self.param:GetOwnedEggCount() <= 0 then
        self._p_group_left:SetVisible(false)
        self.city.petManager:GotoEarnPetEgg()
        return
    end

    self._p_group_left:SetVisible(true)
    self._p_group_left:FeedData(self.param:GetSelectPanelData())
    if self.param:IsSelected() then
        self:ShowTips()
    end
end

function CityHatchEggUIMediator:OnClickGotoBuildBuffFurniture()

end

function CityHatchEggUIMediator:UpdateSelectPanel()
    self._p_group_left:RefreshTable()
end

function CityHatchEggUIMediator:UpdateOwnedEggsList()
    self._p_group_list_eggs:RefreshTable()
end

function CityHatchEggUIMediator:UpdateUI(isFirst)
    self.isFirst = isFirst
    self:RemoveTicker()
    self:ResetVX()
    if self.param:IsFinished() then
        self._p_content:ApplyStatusRecord(3)
        self:UpdatePanelFinished(isFirst)
        self:PlayCanClaimEggVX()
    elseif self.param:IsUndergoing() then
        self._p_content:ApplyStatusRecord(2)
        self:UpdatePanelUndergoing(isFirst)
        if self.param:IsAnyHeatingFurnitureActive() then
            self:PlayHotEggVX()
        else
            self:PlayNormal()
        end
    else
        if self.param:IsSelected() and not self.param:IsSelectImmediatelyRecipe() then
            self._p_content:ApplyStatusRecord(1)
            self:UpdatePanelIdle()
        else
            self._p_content:ApplyStatusRecord(0)
            if self.param:GetCanHatchImmediatelyCount() > 0 then
                self:UpdatePanelCanOpenImmediately()
            else
                self:UpdatePanelIdle()
            end
        end
    end
    self:UpdateSelectPanel()
    if not isFirst then
        self._pool_bubble_batch_open:HideAll()
        self._p_group_bubble_open_all:SetVisible(false)
    end
end

function CityHatchEggUIMediator:UpdatePanelFinished(isFirst)
    self._p_btn_batch:SetVisible(isFirst and self.param:GetCanHatchImmediatelyCount() > 0)
    self._p_btn_egg_storehouse:SetVisible(false)
    self._p_finish:SetActive(true)
    self._icon_empty:SetActive(false)
    self._p_text_empty:SetVisible(false)
    self._p_icon_egg:SetVisible(true)
    self._p_btn_change:SetVisible(false)
    self._p_bubble_1:SetActive(false)
    self._p_bubble_2:SetActive(false)
    self._p_time_need:SetActive(false)
    self._child_time:SetVisible(false)
    self._p_progress:SetActive(false)
    self._p_group_bubble_open:SetVisible(false) -- 2024-04-11 孵蛋界面，批量开启的0s蛋不占队列，在孵蛋的同时也可以开0s的
    self._child_comp_btn_b:SetVisible(true)
    self._child_comp_btn_e_l:SetVisible(false)
    self._child_tips_item:SetVisible(false)

    self._group_left:SetActive(true)

    g_Game.SpriteManager:LoadSprite(self.param:GetProcessEggIcon(), self._p_icon_egg)
    ---@type BistateButtonParameter
    local buttonData = {
        onClick = Delegate.GetOrCreate(self, self.OnClickClaimEgg),
        buttonText = I18N.Get(CityHatchI18N.UIButton_Claim),
    }
    self._child_comp_btn_b:FeedData(buttonData)
end

function CityHatchEggUIMediator:UpdatePanelUndergoing(isFirst)
    self._p_btn_batch:SetVisible(isFirst and self.param:GetCanHatchImmediatelyCount() > 0)
    self._p_btn_egg_storehouse:SetVisible(false)
    self._p_finish:SetActive(false)
    self._icon_empty:SetActive(false)
    self._p_text_empty:SetVisible(false)
    self._p_icon_egg:SetVisible(true)
    self._p_btn_change:SetVisible(false)
    self._p_bubble_1:SetActive(false)
    self._p_bubble_2:SetActive(false)
    self._p_time_need:SetActive(false)
    self._child_time:SetVisible(false)
    self._p_progress:SetActive(true)
    self._child_tips_item:SetVisible(false)

    self._child_comp_btn_b:SetVisible(false)
    self._child_comp_btn_e_l:SetVisible(true)

    self._group_left:SetActive(true)

    g_Game.SpriteManager:LoadSprite(self.param:GetProcessEggIcon(), self._p_icon_egg)
    self._p_text_name.text = self.param:GetSelectedEggName()
    self:UpdatePanelUndergoingTick()
    self:AddTicker()
end

function CityHatchEggUIMediator:UpdatePanelCanOpenImmediately()
    self._p_btn_batch:SetVisible(false)
    self._p_btn_egg_storehouse:SetVisible(false)
    self._p_finish:SetActive(false)
    self._icon_empty:SetActive(false)
    self._p_text_empty:SetVisible(false)
    self._p_time_need:SetActive(false)
    self._child_time:SetVisible(false)
    self._p_progress:SetActive(false)
    self._child_tips_item:SetVisible(false)
    self._child_comp_btn_b:SetVisible(false)
    self._child_comp_btn_e_l:SetVisible(false)
    self._group_left:SetActive(true)

    self:OnClickHatchImmediatelyBtn()

    self.param:OnlyShowCanHatchImmediately(true)
    self._p_group_left:SetVisible(true)
    self._p_group_left:FeedData(self.param:GetSelectPanelData())
end

function CityHatchEggUIMediator:UpdatePanelUndergoingTick()
    ---@type GoldenCostPreviewButtonData
    self._priceButtonData = self._priceButtonData or {
        onClick = Delegate.GetOrCreate(self, self.OnClickSpeedUp),
        buttonText = I18N.Get(CityHatchI18N.UIButton_SpeedUp),
    }
    self._priceButtonData.costInfo = nil
    self._child_comp_btn_e_l:FeedData(self._priceButtonData)

    self._p_progress_n.value = self.param:GetHatchProgress()
    self._timerData = self._timerData or {needTimer = false}
    self._timerData.fixTime = self.param:GetRemainTime()
    self._child_time_progress:FeedData(self._timerData)
end

function CityHatchEggUIMediator:OnClickClaimEgg(clickData, rectTransform)
    self.param:RequestClaim(rectTransform)
end

function CityHatchEggUIMediator:AddTicker()
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.UpdatePanelUndergoingTick))
end

function CityHatchEggUIMediator:RemoveTicker()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.UpdatePanelUndergoingTick))
end

function CityHatchEggUIMediator:UpdatePanelIdle()
    self.param:OnlyShowCanHatchImmediately(false)
    local isSelected = self.param:IsSelected()
    local needShowBuffBubble = self.param:NeedShowBuffBubble()

    local immediatelyOpen = self.param:GetCanHatchImmediatelyCount() > 0
    self._p_btn_batch:SetVisible(false)
    self._p_btn_egg_storehouse:SetVisible(false)
    if immediatelyOpen then
        self._vx_trigger_batch:PlayAll(CS.FpAnimation.CommonTriggerType.Custom6)
    else
        self._vx_trigger_batch:ResetAll(CS.FpAnimation.CommonTriggerType.Custom6)
    end

    self._p_finish:SetActive(false)
    self._icon_empty:SetActive(not isSelected)
    self._p_text_empty:SetVisible(not isSelected)
    self._p_icon_egg:SetVisible(isSelected)
    self._p_btn_change:SetVisible(isSelected)
    self._p_bubble_1:SetActive(needShowBuffBubble)
    self._p_bubble_2:SetActive(needShowBuffBubble)
    self._p_time_need:SetActive(isSelected)
    self._child_time:SetVisible(isSelected)

    if isSelected then
        self:ShowTips()
    else
        self:HideTips()
    end

    self._p_progress:SetActive(false)
    self._group_left:SetActive(true)
    self._p_group_bubble_open:SetVisible(false)

    self._p_group_left:SetVisible(true)
    self._p_group_left:FeedData(self.param:GetSelectPanelData())

    if isSelected then
        g_Game.SpriteManager:LoadSprite(self.param:GetSelectedEggIcon(), self._p_icon_egg)
        self._timerData = self._timerData or {needTimer = false}
        self._timerData.fixTime = self.param:GetCurrentRecipeCfgOriginCostTime()
        self._child_time:FeedData(self._timerData)
        ---@type GoldenCostPreviewButtonData
        self._priceButtonData = self._priceButtonData or {
            onClick = Delegate.GetOrCreate(self, self.OnClickSpeedUp),
            buttonText = I18N.Get(CityHatchI18N.UIButton_SpeedUp),
        }
        self._priceButtonData.costInfo = {icon = self.param:GetSpeedUpCoinIcon()}
        self._priceButtonData.costInfo.need = self.param:GetSpeedUpCoinNeed()
        self._priceButtonData.costInfo.own = self.param:GetSpeedUpCoinOwn()
        self._child_comp_btn_e_l:SetVisible(true)
        self._child_comp_btn_e_l:FeedData(self._priceButtonData)
        ---@type BistateButtonParameter
        local buttonData = {
            onClick = Delegate.GetOrCreate(self, self.OnClickStartHatch),
            buttonText = I18N.Get(CityHatchI18N.UIButton_Start),
        }
        self._child_comp_btn_b:SetVisible(true)
        self._child_comp_btn_b:FeedData(buttonData)
    else
        self._child_comp_btn_b:SetVisible(false)
        self._child_comp_btn_e_l:SetVisible(false)
    end
end

function CityHatchEggUIMediator:OnClickStartHatch(clickData, rectTransform)
    self:CloseSelectPanel()
    self:HideTips()
    self:HideButtom()

    self._p_btn_change.gameObject:SetActive(false)

    if self.param:CanHatchCurrentEggImmediately() then
        self.param:RequestDirectOpenEggs({[self.param.recipeId] = 1}, rectTransform)
    else
        self:PlayStartHatchVX(function()
            self.param:RequestStart(rectTransform)
        end)
    end
end

function CityHatchEggUIMediator:OnItemCountChange()
    self._p_text_number_egg.text = tostring(self.param:GetOwnedEggCount())
    self._p_text_batch_number.text = ("x%d"):format(self.param:GetCanHatchImmediatelyCount())
end

function CityHatchEggUIMediator:OnFurnitureUpdate(city, batchEvt)
    if self.city ~= city then return end
    if not batchEvt.Change then return end
    if not batchEvt.Change[self.param.cellTile:GetCell().singleId] then return end

    self:UpdateUI(self.isFirst)
end

function CityHatchEggUIMediator:CloseSelectPanel()
    self._p_group_left:SetVisible(false)
end

---@param gameObj CS.UnityEngine.GameObject
function CityHatchEggUIMediator:OnButtonClickPre(baseComponent, gameObj)
    -- self:CloseSelectPanel()
    -- self:HideTips()
    if baseComponent ~= self then
        -- self._p_group_bubble_open:SetVisible(false)
        return
    end

    if gameObj ~= self._p_btn_batch.gameObject then
        -- 2024-04-11 孵蛋界面，批量开启的0s蛋不占队列，在孵蛋的同时也可以开0s的
        -- self._p_group_bubble_open:SetVisible(false)
    end
end

function CityHatchEggUIMediator:OnClickSpeedUp(rectTransform)
    self:CloseSelectPanel()
    self:HideTips()
    if self._priceButtonData and self._priceButtonData.costInfo and
        self._priceButtonData.costInfo.need > self._priceButtonData.costInfo.own then
        ModuleRefer.ConsumeModule:GotoShop()
        return
    end
    self.param:RequestSpeedUp(rectTransform)
end

function CityHatchEggUIMediator:PlayHotEggVX()
    self._p_egg_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
    self._p_egg_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom3)
    self._p_egg_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

function CityHatchEggUIMediator:PlayNormal()
    self._p_egg_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self._p_egg_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
    self._p_egg_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
end

function CityHatchEggUIMediator:PlayCanClaimEggVX()
    self._p_egg_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self._p_egg_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
    self._p_egg_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom3)
    self._p_egg_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom4)
end

function CityHatchEggUIMediator:PlaySelectEggVX()
    self._p_egg_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom5)
end

function CityHatchEggUIMediator:PlayStartHatchVX(callback)
    self._vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom7, callback)
end

function CityHatchEggUIMediator:ResetVX()
    self._vx_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom7)
    self._p_egg_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self._p_egg_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
    self._p_egg_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom3)
    self._p_egg_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom4)
    self._canvas_group_left.alpha = 1
    self.canvas_time_need.alpha = 1
    self._group_bottom:SetActive(true)
end

function CityHatchEggUIMediator:OnClickDetails()
    CityUtils.OpenCommonSimpleTips(I18N.Get("furniture_egg_tips"), self._p_btn_detail.transform)
end

function CityHatchEggUIMediator:ShowTips()
    local isSelected = self.param:IsSelected()
    self._child_tips_item:SetVisible(isSelected)
    if isSelected then
        local recipe = ConfigRefer.CityWorkProcess:Find(self.param.recipeId)
        self._child_tips_item:FeedData({itemId = recipe:Output(), itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM})
    end
end

function CityHatchEggUIMediator:HideTips()
    self._child_tips_item:SetVisible(false)
end

function CityHatchEggUIMediator:HideButtom()
    self._group_bottom:SetActive(false)
end

function CityHatchEggUIMediator:ShowOwnedEggs()
    self.param:IsTipsCell(true)
    self._p_group_list_eggs:SetVisible(true)
    self._p_group_list_eggs:FeedData(self.param:GetSelectPanelData())
    self.param:IsTipsCell(false)
    self:ShowTips()
end

function CityHatchEggUIMediator:HideOwnedEggs()
    self._p_group_list_eggs:SetVisible(false)
end

return CityHatchEggUIMediator