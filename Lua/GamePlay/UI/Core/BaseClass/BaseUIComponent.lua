local I18N = require('I18N')
local Utils = require('Utils')
local ArtResourceUtils = require("ArtResourceUtils")
local ModuleRefer = require('ModuleRefer')

---@class BaseUIComponent
---@field CSComponent CS.DragonReborn.UI.BaseComponent
---@field OnCreate fun(param:table)
---@field OnOpened fun(param:table)
---@field OnShow fun(param:table)
---@field OnFeedData fun(param:table)
---@field OnHide fun(param:table)
---@field OnClose fun(param:table)
---@field OnUnityMessage fun(param:table) @接受通过GameObject发送来的消息
local BaseUIComponent = class('BaseUIComponent')
BaseUIComponent._currentSelectedGameObject = nil

---@param self BaseUIComponent
function BaseUIComponent:GetClearFunctions()
	self._clearFunctions = self._clearFunctions or {}
	return self._clearFunctions
end

---@param self BaseUIComponent
function BaseUIComponent:IsCreated()
	if self.CSComponent == nil then
		return false
	else
		return self.CSComponent.IsCreated
	end
end

---@param self BaseUIComponent
function BaseUIComponent:IsShow()
	if self.CSComponent == nil then
		return false
	else
		return self.CSComponent.IsShow
	end
end

---@param self BaseUIComponent
function BaseUIComponent:IsHide()
	if self.CSComponent == nil then
		return false
	else
		return self.CSComponent.IsHide
	end
end

function BaseUIComponent:ctor()
end

function BaseUIComponent:GetName()
	return GetClassName(self)
end

--OnCreate,
--OnOpened,
--OnShow,
--OnFeedData,
--OnHide,
--OnClose,
--call from C#
function BaseUIComponent:OnCreate(param)
	--重载方法
end

function BaseUIComponent:OnShow(param)
	--重载方法
end

function BaseUIComponent:OnOpened(param)
	--重载方法
end

function BaseUIComponent:OnFeedData(data)
	--重载方法
end

function BaseUIComponent:OnHide(param)
	--重载方法
end

function BaseUIComponent:OnClose(param)
	--重载方法
end

--Lua function

function BaseUIComponent:SetVisible(visible,param)
	-- if visible then
	-- 	self:Show(param)
	-- else
	-- 	self:Hide(param)
	-- end
	if Utils.IsNotNull(self.CSComponent) then
		self.CSComponent:SetVisible(visible,param)
	end
end

function BaseUIComponent:Show(param)
	if self.CSComponent ~= nil then
		self.CSComponent:Show(param)
	end
end

function BaseUIComponent:Hide(param)
	if self.CSComponent ~= nil then
		self.CSComponent:Hide(param)
	end
end

function BaseUIComponent:FeedData(data)
	if self.CSComponent ~= nil then
		self.CSComponent:FeedData(data)
	end
end
--清理函数，不要重载
function BaseUIComponent:InvokeClearFunctions()
	local toClear = self:GetClearFunctions()
	if toClear ~= nil then
		for _, v in ipairs(toClear) do
			v()
		end
		table.clear(toClear)
	end
end

--name节点名字  luaname lua脚本名 不填默认返回第一个
--function BaseUIComponent:BindLua(name,luaName)
--	local tms = self.CSComponent:GetComponentsWithUniqueName(name,typeof(CS.DragonReborn.INewLuaClass))
--	if IsNotNull(tms) then
--		for i= 0,tms.Length -1 do
--			if luaName == nil then
--				return tms[i].Lua
--			end
--			if  tms[i].LuaScriptPath == luaName then
--				return tms[i].Lua
--			end
--		end
--	end
--	return tms
--end

---@generic T
---@param type T
---@return T
function BaseUIComponent:BindComponent(name,type)
	local tm = self.CSComponent:GetWithUniqueName(name,type)
	-- if not tm then
	-- 	g_Logger.WarnChannel('BaseUIComponent','Can not Find Component(' .. type.FullName .. ') in ' .. name )
	-- end
	return tm
end

---@return CS.UnityEngine.GameObject
function BaseUIComponent:GameObject(name,isRequire)
	isRequire = isRequire or false
	local tm = self.CSComponent:GetTransformWithUniqueName(name,isRequire)
	if Utils.IsNull(tm) then
		return nil
	end
	return tm.gameObject
end

---@return CS.UnityEngine.RectTransform
function BaseUIComponent:Transform(name,isRequire)
	isRequire = isRequire or false
	local tm = self.CSComponent:GetTransformWithUniqueName(name,isRequire)
	return tm
end

---@return CS.UnityEngine.RectTransform
function BaseUIComponent:RectTransform(name,isRequire)
	isRequire = isRequire or false
	local rect = self.CSComponent:GetWithUniqueName(name,typeof(CS.UnityEngine.RectTransform),isRequire)
	return rect
end

---@return CS.UnityEngine.UI.Text
function BaseUIComponent:Text(name, localKey)
	local tm  = self.CSComponent:GetWithUniqueName(name,typeof(CS.UnityEngine.UI.Text))
	if tm ~= nil and localKey ~= nil then
		tm.text = I18N.Get(localKey)
	end
	return tm
end

---@return CS.DragonReborn.UI.LinkText
function BaseUIComponent:LinkText(name, func, localKey)
	local tm  = self.CSComponent:GetWithUniqueName(name,typeof(CS.DragonReborn.UI.LinkText))
	if tm ~= nil and func then
		local function clear()
			tm.onHrefClick = nil
		end
		table.insert(self:GetClearFunctions(), clear)
		tm.onHrefClick = func
	end
	if tm ~= nil and localKey ~= nil then
		tm.text = I18N.Get(localKey)
	end
	return tm
end

function BaseUIComponent:CanClick()
	--组件点击事件内置CD
	if self.clickTimer and g_Game.Time.realtimeSinceStartup - self.clickTimer < 0.3 then		
		return false
	end

	self.clickTimer = g_Game.Time.realtimeSinceStartup
	return true
end

---@param name string
---@param func function
---@param funcType string
---@return CS.UnityEngine.UI.Image
function BaseUIComponent:Image(name, func, funcType,isRequire)
	isRequire = isRequire or false
	local tm  = self.CSComponent:GetWithUniqueName(name,typeof(CS.UnityEngine.UI.Image),isRequire)
	if tm ~= nil and func ~= nil then
		if funcType == nil then
			funcType = "click"
		end

		if funcType == "down" then
			self:PointerDown(name, func)
		elseif funcType == "up" then
			self:PointerUp(name, func)
		elseif funcType == "click" then
			self:PointerClick(name, func)
		end
	end

	return tm
end

---@param name string
---@param onValueChanged fun(text:string)
---@param onEndEdit fun(text:string)
---@param onSubmit fun(text:string)
---@param placeholder string
---@return CS.UnityEngine.UI.InputField
function BaseUIComponent:InputField(name, onValueChanged, onEndEdit, onSubmit, placeholder)
	---@type CS.UnityEngine.UI.InputField
	local inputField = self.CSComponent:GetWithUniqueName(name, typeof(CS.UnityEngine.UI.InputField))
	inputField.placeholder.text = placeholder or ""

	local function callback()
		if Utils.IsNull(inputField) then
			return
		end

		if onValueChanged ~= nil then
			onValueChanged(inputField.text)
		end
	end

	local function onEndEditCallBack()
		if Utils.IsNull(inputField) then
			return
		end

		if onEndEdit ~= nil then
			onEndEdit(inputField.text)
		end
	end

    local function onSubmitCallBack(text)
        if Utils.IsNull(inputField) then
            return
        end

        if onSubmit ~= nil then
            onSubmit(text)
        end
    end

	local function clear()
		inputField.onValueChanged:RemoveAllListeners()
		inputField.onValueChanged:Invoke()
		inputField.onEndEdit:RemoveAllListeners()
		inputField.onEndEdit:Invoke()
        inputField.onSubmit:RemoveAllListeners()
        inputField.onSubmit:Invoke()
	end

	table.insert(self:GetClearFunctions(), clear)

	inputField.onValueChanged:AddListener(callback)
	inputField.onEndEdit:AddListener(onEndEditCallBack)
    inputField.onSubmit:AddListener(onSubmitCallBack)

	return inputField
end

---@param name string
---@param onValueChanged fun(isOn:boolean)
---@return CS.UnityEngine.UI.Toggle
function BaseUIComponent:Toggle(name, onValueChanged, playSFX)
	---@type CS.UnityEngine.UI.Toggle
	local toggle = self.CSComponent:GetWithUniqueName(name,typeof(CS.UnityEngine.UI.Toggle))

	if playSFX == nil then
		playSFX = true
	end

	local function callback()
		if Utils.IsNull(toggle) then
			return
		end

		if onValueChanged ~= nil then
			onValueChanged(toggle.isOn)
		end

		if toggle.isOn and playSFX then
			--播放声音
		end
	end

	local function clear()
		toggle.onValueChanged:RemoveAllListeners()
		toggle.onValueChanged:Invoke()
	end

	table.insert(self:GetClearFunctions(), clear)

	toggle.onValueChanged:AddListener(callback)
	return toggle
end

---@param name string
---@param func fun()
---@param playSfx string
---@return CS.UnityEngine.UI.Button
function BaseUIComponent:Button(name, func, playSfx)
	local tm  = self.CSComponent:GetWithUniqueName(name,typeof(CS.UnityEngine.UI.Button))
	if(func ~= nil and tm ~= nil)then
		self:ButtonImp(tm, func, playSfx)
	end
	return tm
end

function BaseUIComponent:ButtonImp(button, func, playSfx)
	if playSfx == nil then
		playSfx = true
	end

	local go = button.gameObject
	local downListener = CS.UIPointerDownListener.Get(go)
	downListener.onDown = function (x)
		BaseUIComponent._currentSelectedGameObject = go
	end

	local exitListener = CS.UIPointerExitListener.Get(go)
	exitListener.onExit = function (x)
		if BaseUIComponent._currentSelectedGameObject == go then
			BaseUIComponent._currentSelectedGameObject = nil
		end
	end

	local callback = function()

		if not self:CanClick() then
			return
		end

		if Utils.IsNull(go) then
			return
		end

		if BaseUIComponent._currentSelectedGameObject ~= go then
			return
		end

		--local sfxEvt = CS.DragonReborn.UIButtonClickEvent()
		--sfxEvt.playSFX = playSfx
		--sfxEvt.ButtonName = go.name
		--g_Game.EventManager:TriggerEvent(sfxEvt)

		local EventConst = require("EventConst")
		g_Game.EventManager:TriggerEvent(EventConst.UI_BUTTON_CLICK_PRE, self, go)

		func()

		-- 统计Button点击
		local uiMediator = self:GetParentBaseUIMediator()
		if uiMediator then
			ModuleRefer.FPXSDKModule:TrackUIButtonClick(uiMediator:GetName(), self:GetName(), go.name)
		end

		if BaseUIComponent._currentSelectedGameObject == go then
			BaseUIComponent._currentSelectedGameObject = nil
		end
	end

	button.onClick:AddListener(callback)
	local clear = function()
		button.onClick:RemoveAllListeners()
		button.onClick:Invoke()
		if (Utils.IsNotNull(downListener)) then
			downListener.onDown = nil
		end
		if (Utils.IsNotNull(exitListener)) then
			exitListener.onExit = nil
		end

		if BaseUIComponent._currentSelectedGameObject == go then
			BaseUIComponent._currentSelectedGameObject = nil
		end
	end
	table.insert(self:GetClearFunctions(), clear)
end

---@param name string
---@return CS.UnityEngine.UI.Slider
function BaseUIComponent:Slider(name, onValueChanged)
	local slider  = self.CSComponent:GetWithUniqueName(name,typeof(CS.UnityEngine.UI.Slider))

	if onValueChanged then
		local function callback(value)
			if Utils.IsNull(slider) then
				return
			end

			if onValueChanged ~= nil then
				onValueChanged(value)
			end
		end

		local function clear()
			slider.onValueChanged:RemoveAllListeners()
			slider.onValueChanged:Invoke()
		end

		table.insert(self:GetClearFunctions(), clear)

		slider.onValueChanged:AddListener(callback)
	end

	return slider
end

---@return CS.TableViewPro
function BaseUIComponent:TableViewPro(name)
	local tm  = self.CSComponent:GetWithUniqueName(name,typeof(CS.TableViewPro))
	return tm
end

function BaseUIComponent:ScrollRect(name)
	local tm = self.CSComponent:GetWithUniqueName(name, typeof(CS.UnityEngine.UI.ScrollRect))
	return tm
end

---@return CS.DragonReborn.UI.LuaBaseComponent
function BaseUIComponent:LuaBaseComponent(name)
	local tm  = self.CSComponent:GetWithUniqueName(name,typeof(CS.DragonReborn.UI.LuaBaseComponent))
	return tm
end

---得到绑定在节点上的Lua对象
---@param name string
---@return BaseUIComponent
function BaseUIComponent:LuaObject(name)
	local tm  = self:LuaBaseComponent(name)
	if tm then
		return tm.Lua
	else
		--g_Logger.WarnChannel('BaseUIComponent','LuaObject Cannot Find')
		return nil
	end
end

---@return CS.FpAnimation.FpAnimationCommonTrigger
function BaseUIComponent:AnimTrigger(name)
	local tm  = self.CSComponent:GetWithUniqueName(name, typeof(CS.FpAnimation.FpAnimationCommonTrigger),true)
	return tm
end

---@return CS.StatusRecordParent
function BaseUIComponent:StatusRecordParent(name)
    return self:BindComponent(name, typeof(CS.StatusRecordParent))
end

---@param name string
---@param func function
function BaseUIComponent:PointerDown(name, func)
	local tm = self.CSComponent:GetWithUniqueName(name, typeof(CS.UnityEngine.UI.MaskableGraphic))
	if tm ~= nil and func ~= nil then
		local listener = CS.UIPointerDownListener.Get(tm.gameObject)
		listener.onDown = func
		local clear = function()
			listener.onDown = nil
		end
		table.insert(self:GetClearFunctions(), clear)
	else
		if not tm then
			g_Logger.ErrorChannel('BaseUIComponent','PointerDown Bind Failed -- MaskableGraphic NOT FIND!')
		elseif not func then
			g_Logger.ErrorChannel('BaseUIComponent','PointerDown Bind Failed -- Event Callback function is nil')
		end
	end
end

---@param name string
---@param func function
function BaseUIComponent:PointerUp(name, func)
	local tm = self.CSComponent:GetWithUniqueName(name, typeof(CS.UnityEngine.UI.MaskableGraphic))
	if tm ~= nil and func ~= nil then
		local listener = CS.UIPointerUpListener.Get(tm.gameObject)
		listener.onUp = func
		local clear = function()
			listener.onUp = nil
		end
		table.insert(self:GetClearFunctions(), clear)
	else
		if not tm then
			g_Logger.ErrorChannel('BaseUIComponent','PointerUp Bind Failed -- MaskableGraphic NOT FIND!')
		elseif not func then
			g_Logger.ErrorChannel('BaseUIComponent','PointerUp Bind Failed -- Event Callback function is nil')
		end
	end
end

---@param name string
---@param func fun(param:CS.UnityEngine.GameObject,eventData:CS.UnityEngine.EventSystems.PointerEventData)
function BaseUIComponent:PointerClick(name, func)
	local tm = self.CSComponent:GetWithUniqueName(name, typeof(CS.UnityEngine.UI.MaskableGraphic))
	if tm ~= nil and func ~= nil then
		local listener = CS.UIPointerClickListener.Get(tm.gameObject)
		listener.onClick = function(param, eventData)
			if not self:CanClick() then
				return
			end
			func(param, eventData)
		end
		local clear = function()
			listener.onClick = nil
		end
		table.insert(self:GetClearFunctions(), clear)
	else
		if not tm then
			g_Logger.ErrorChannel('BaseUIComponent','PointerClick Bind Failed -- MaskableGraphic NOT FIND!')
		elseif not func then
			g_Logger.ErrorChannel('BaseUIComponent','PointerClick Bind Failed -- Event Callback function is nil')
		end
	end
end

---@param name string
---@param func function
function BaseUIComponent:ZoomEvent(name, func)
	local tm = self.CSComponent:GetWithUniqueName(name, typeof(CS.UnityEngine.UI.MaskableGraphic))
	if tm ~= nil and func ~= nil then
		local listener = CS.TouchPan.Get(tm.gameObject)
		listener.actionZoom = func
		local clear = function()
			listener.actionZoom = nil
		end
		table.insert(self:GetClearFunctions(), clear)
	else
		if not tm then
			g_Logger.ErrorChannel('BaseUIComponent','TouchPan Bind Failed -- MaskableGraphic NOT FIND!')
		elseif not func then
			g_Logger.ErrorChannel('BaseUIComponent','TouchPan Bind Failed -- Event Callback function is nil')
		end
	end
end

---@param name string
---@param onBeginDrag fun(go:CS.UnityEngine.GameObject, pointData:CS.UnityEngine.EventSystems.PointerEventData)
---@param onDrag fun(go:CS.UnityEngine.GameObject, pointData:CS.UnityEngine.EventSystems.PointerEventData)
---@param onEndDrag fun(go:CS.UnityEngine.GameObject, pointData:CS.UnityEngine.EventSystems.PointerEventData)
---@param dragParentList boolean @comment 是否向父节点的ScrollList传递拖拽消息，只有与父ScrollList方向大体相同的拖拽才会传递，注意！在一次拖拽过程中向父节点传递消息后，不再响应监听函数。
function BaseUIComponent:DragEvent(name, onBeginDrag, onDrag, onEndDrag, dragParentList, onSendToParent)
	dragParentList = dragParentList or false
	local tm = self.CSComponent:GetWithUniqueName(name, typeof(CS.UnityEngine.UI.MaskableGraphic))
	if tm ~= nil and (onBeginDrag ~= nil or onDrag ~= nil or onEndDrag ~= nil ) then
		local listener = CS.UIDragListener.Get(tm.gameObject,dragParentList)
		listener.onBeginDrag = onBeginDrag
		listener.onDrag = onDrag
		listener.onEndDrag = onEndDrag
		listener.onSendToParent = onSendToParent
		local clear = function()
			listener.onBeginDrag = nil
			listener.onDrag = nil
			listener.onEndDrag = nil
			listener.onSendToParent = nil
		end
		table.insert(self:GetClearFunctions(), clear)
	else
		if not tm then
			g_Logger.ErrorChannel('BaseUIComponent','DragEvent Bind Failed -- MaskableGraphic NOT FIND!')
		elseif onBeginDrag == nil and onDrag == nil and onEndDrag == nil then
			g_Logger.ErrorChannel('BaseUIComponent','DragEvent Bind Failed -- Event Callback function is nil')
		end
	end
end

---@param name string
---@param onCancelDrag fun(CS.UnityEngine.GameObject)
function BaseUIComponent:DragCancelEvent(name, onCancelDrag)
	local tm = self.CSComponent:GetWithUniqueName(name, typeof(CS.UnityEngine.UI.MaskableGraphic))
	if tm ~= nil and onCancelDrag ~= nil then
		local listener = CS.UIDragListener.Get(tm.gameObject)
		listener.onCancelDrag = onCancelDrag
		local clear = function()
			listener.onCancelDrag = nil
		end
		table.insert(self:GetClearFunctions(), clear)
	end
end

---@param name string
---@param onCancelDrag fun(CS.UnityEngine.GameObject)
function BaseUIComponent:DropDown(name,onDrop)
	local tm = self.CSComponent:GetWithUniqueName(name, typeof(CS.UnityEngine.UI.MaskableGraphic))
	if tm ~= nil and onDrop ~= nil then
		local listener = CS.UIDropListener.Get(tm.gameObject)
		listener.onDrop = onDrop
		local clear = function()
			listener.onDrop = nil
		end
		table.insert(self:GetClearFunctions(), clear)
	end
end

function BaseUIComponent:Joystick(name, onPointerDown, onPointerUp, onValueChanged, onPointerCancel)
	---@type CS.zFrame.UI.Joystick
	local tm = self.CSComponent:GetWithUniqueName(name, typeof(CS.zFrame.UI.Joystick))
	if tm ~= nil then
		if type(onPointerDown) == "function" then
			tm.OnPointerDown:AddListener(onPointerDown)
			local clear = function()
				tm.OnPointerDown:RemoveAllListeners()
			end
			table.insert(self:GetClearFunctions(), clear)
		end
		if type(onPointerDown) == "function" then
			tm.OnPointerUp:AddListener(onPointerUp)
			local clear = function()
				tm.OnPointerUp:RemoveAllListeners()
			end
			table.insert(self:GetClearFunctions(), clear)
		end
		if type(onValueChanged) == "function" then
			tm.OnValueChanged:AddListener(onValueChanged)
			local clear = function()
				tm.OnValueChanged:RemoveAllListeners()
			end
			table.insert(self:GetClearFunctions(), clear)
		end
		if type(onPointerCancel) == "function" then
			tm.OnPointerCancel:AddListener(onPointerCancel)
			local clear = function()
				tm.OnPointerCancel:RemoveAllListeners()
			end
			table.insert(self:GetClearFunctions(), clear)
		end
	end
	return tm
end

---@return CS.DragonReborn.UI.UIMediator
function BaseUIComponent:GetCSUIMediator()
	if self.CSComponent then
		return self.CSComponent:GetParentUIMediator()
	end
	return nil
end

---@return BaseUIMediator
function BaseUIComponent:GetParentBaseUIMediator()
	if self.CSComponent then
		local csMediator = self.CSComponent:GetParentUIMediator()
		if csMediator then
			return csMediator.Lua
		end
	end
	return nil
end

--这个方法调用需要保证iconid在ArtResourceUI配置表中
---@param iconId number ref@ArtResourceUI
---@param image CS.UnityEngine.UI.Image
function BaseUIComponent:LoadSprite(iconId, image)
	if Utils.IsNull(image) then
		g_Logger.ErrorChannel('BaseUIComponent', 'LoadSprite: image is null.')
		return
	end
	g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(iconId), image)
end

function BaseUIComponent:DelayExecute(func, delay, logicTick, param)
	local TimerUtility = require("TimerUtility")
	local tickerCache = self:GetParentBaseUIMediator():GetTickerCache()
	local timer = TimerUtility.DelayExecute(func, delay, logicTick, param)
	tickerCache[timer] = true
	return timer
end

function BaseUIComponent:StartFrameTicker(func, frameCount, loop, logicTick, param)
	local TimerUtility = require("TimerUtility")
	local tickerCache = self:GetParentBaseUIMediator():GetTickerCache()
	local timer = TimerUtility.StartFrameTimer(func, frameCount, loop, logicTick, param)
	tickerCache[timer] = true
	return timer
end

function BaseUIComponent:IntervalRepeat(func, interval, loopTimes, logicTick, param)
	local TimerUtility = require("TimerUtility")
	local tickerCache = self:GetParentBaseUIMediator():GetTickerCache()
	local timer = TimerUtility.IntervalRepeat(func, interval, loopTimes, logicTick, param)
	tickerCache[timer] = true
	return timer
end

function BaseUIComponent:StopTimer(timer)
	if not timer then return end

	local TimerUtility = require("TimerUtility")
	local tickerCache = self:GetParentBaseUIMediator():GetTickerCache()
	local has = tickerCache[timer]
	if has then
		tickerCache[timer] = nil
	end
	TimerUtility.StopAndRecycle(timer)
end

-- 获取component对应的父级component 优先获取luatable
--function BaseUIComponent:GetParentComp(level)
--	local parentComp = self.CSComponent:GetParentComp(level)
--	if IsNotNull(parentComp) and IsNotNull(parentComp.Lua) then
--		return parentComp.Lua
--	end
--	return parentComp
--end

-- 获取component对应的最近父级component 拥有属性或者方法 优先获取luatable
--function BaseUIComponent:GetNearComp(value)
--	local parentLevel = 1
--	local curParent = self:GetParentComp(parentLevel)
--	while IsNotNull(curParent)
--	do
--		if IsNotNull(curParent.Lua) then
--			if IsNotNull(curParent.Lua[value]) then
--				return curParent
--			end
--		else
--			if IsNotNull(curParent[value]) then
--				return curParent
--			end
--		end
--
--		parentLevel = parentLevel + 1
--		curParent = self:GetParentComp(parentLevel)
--	end
--
--	return nil
--end


return BaseUIComponent
