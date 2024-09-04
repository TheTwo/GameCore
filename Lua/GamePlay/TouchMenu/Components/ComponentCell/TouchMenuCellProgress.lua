local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local NumberFormatter = require("NumberFormatter")

---@class TouchMenuCellProgress:BaseUIComponent
local TouchMenuCellProgress = class('TouchMenuCellProgress', BaseUIComponent)

function TouchMenuCellProgress:OnCreate()
    self._p_icon_root = self:GameObject("p_icon_root")
    self._p_icon_item = self:Image("p_icon_item")

    self._p_text_01 = self:Text("p_text_01")
    self._child_time = self:LuaBaseComponent("child_time")
    self._p_icon = self:Image("p_icon")
    self._p_text_02 = self:Text("p_text_02")

    self._p_progress_slider = self:Slider("p_progress_slider")
    
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnGotoClicked))

    self._p_icon_buff = self:Image("p_icon_buff")
    self._p_icon_buff_btn = self:Button("p_icon_buff", Delegate.GetOrCreate(self, self.OnClickBuffIcon))
    self._p_text_buff_num = self:Text("p_text_buff_num")
end

---@param data TouchMenuCellProgressDatum
function TouchMenuCellProgress:OnFeedData(data)
    self.data = data
    self.data:BindUICell(self)
end

function TouchMenuCellProgress:OnClose()
    if self.data then
        self.data:UnbindUICell()
        self.data = nil
    end
end

function TouchMenuCellProgress:UpdateHeader(spritePath, titleText)
    local isShow = not string.IsNullOrEmpty(spritePath)
    self._p_icon_root:SetActive(isShow)
    if isShow then
        g_Game.SpriteManager:LoadSprite(spritePath, self._p_icon_item)
    end

    self._p_text_01.text = titleText
end

function TouchMenuCellProgress:UpdateProgress(progress, showProgressNumber,customProgressNumber)
    local showProgress = progress ~= nil
    self._p_progress_slider:SetVisible(progress ~= nil)
    if showProgress then
        self._p_progress_slider.value = progress
    end
    self._p_text_02:SetVisible(showProgressNumber and showProgress)
    if showProgressNumber and showProgress then
        if customProgressNumber then
            self._p_text_02.text = customProgressNumber()
        else
            self._p_text_02.text = NumberFormatter.Percent(progress)
        end
    end
end

---@param commonTimerData CommonTimerData
function TouchMenuCellProgress:UpdateCommonTimer(commonTimerData)
    self._child_time:SetVisible(commonTimerData ~= nil)
    if commonTimerData then
        self._child_time:FeedData(commonTimerData)
    end
end

function TouchMenuCellProgress:UpdateSubImage(spritePath)
    local isShow = not string.IsNullOrEmpty(spritePath)
    self._p_icon:SetVisible(isShow)
    if isShow then
        g_Game.SpriteManager:LoadSprite(spritePath, self._p_icon)
    end
end

function TouchMenuCellProgress:UpdateGoto(gotoCallback)
    self._p_btn_goto:SetVisible(gotoCallback)
end

function TouchMenuCellProgress:UpdateCreepBuff(icon, count)
    if count and count > 0 then
        self._p_icon_buff:SetVisible(true)
        g_Game.SpriteManager:LoadSpriteAsync(icon, self._p_icon_buff)
        if count > 1 then
            self._p_text_buff_num:SetVisible(true)
            self._p_text_buff_num.text = ("x%d"):format(count)
        else
            self._p_text_buff_num:SetVisible(false)
        end
    else
        self._p_icon_buff:SetVisible(false)
    end
end

function TouchMenuCellProgress:OnGotoClicked()
    if self.data.gotoCallback and type(self.data.gotoCallback) == "function" then
        self.data.gotoCallback()
    end
end

function TouchMenuCellProgress:OnClickBuffIcon()
	if (self.data.onClickCreepBuffIcon) then
		self.data.onClickCreepBuffIcon(self._p_icon_buff_btn.transform:GetComponent(typeof(CS.UnityEngine.RectTransform)), self.data)
	end
end


return TouchMenuCellProgress