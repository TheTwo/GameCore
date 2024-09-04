local Delegate = require("Delegate")
local StoryDialogUIMediatorHelper = require("StoryDialogUIMediatorHelper")
local StoryDialogUIMediatorDialogPlayer = require("StoryDialogUIMediatorDialogPlayer")
local StoryDialogPlaceType = require("StoryDialogPlaceType")
local ConfigRefer = require("ConfigRefer")
local SetPortraitCallBack = require("SetPortraitCallBack")
local UIResourceType = require("UIResourceType")
---@type CS.DragonReborn.AssetTool.GameObjectCreateHelper
local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper
local Utils = require("Utils")

--- scene:scene_child_dialog_npc_left_1
local BaseUIComponent = require("BaseUIComponent")

---@class StoryDialogNPCTalkComponent:BaseUIComponent
---@field new fun():StoryDialogNPCTalkComponent
---@field super BaseUIComponent
---@field host StoryDialogUIMediator
local StoryDialogNPCTalkComponent = class('StoryDialogNPCTalkComponent', BaseUIComponent)

function StoryDialogNPCTalkComponent:ctor()
    StoryDialogNPCTalkComponent.super.ctor(self)
    ---@type table<number, StoryDialogUIMediatorDialogPlayerOperateTargets>
    self._modeTargets = nil
    self._goHelper = GameObjectCreateHelper.Create()
    self._lastLRMode = nil
    self._grayLeft = false
    self._grayRight = false
end

function StoryDialogNPCTalkComponent:OnCreate(param)
    -- npc share
    self._g_npc_root = self:GameObject("")
    self._lb_npc_talk = self:Text("p_text_talk_l")
    self._g_content_dialog = self:GameObject("content_dialog_l")
    self._g_next = self:GameObject("p_next_l")
    self._p_vfx_dialog_charactor_group = self:AnimTrigger("p_vfx_dialog_charactor_group")

    -- left npc node
    self._g_portrait_root_left = self:GameObject("p_portrait_root_l")
    self._g_portrait_root_left_trigger = self:AnimTrigger("p_portrait_root_l")
    self._g_content_option_left = self:GameObject("content_option_l")
    self._t_table_task_l = self:TableViewPro("p_table_task_l")
    self._g_base_name_left = self:GameObject("base_name_l")
    self._lb_npc_name_left = self:Text("p_text_name_l")
    
    -- right npc node
    self._g_portrait_root_right = self:GameObject("p_portrait_root_r")
    self._g_portrait_root_right_trigger = self:AnimTrigger("p_portrait_root_r")
    self._g_content_option_right = self:GameObject("content_option_r")
    self._t_table_task_r = self:TableViewPro("p_table_task_r")
    self._g_base_name_right = self:GameObject("base_name_r")
    self._lb_npc_name_right = self:Text("p_text_name_r")
    
    -- middle npc node
    self._g_portrait_root_center = self:GameObject("p_portrait_root_center")
end

function StoryDialogNPCTalkComponent:CloseSelf()
    self:GetParentBaseUIMediator():CloseSelf()
end

function StoryDialogNPCTalkComponent:InitForDialog()
    self._g_content_option_left:SetActive(false)
    self._g_content_option_right:SetActive(false)
    self._g_content_dialog:SetActive(true)
    ---@type table<number, StoryDialogUIMediatorDialogPlayerOperateTargets>
    self._modeTargets = {
        [1] = {
            nameTxt = self._lb_npc_name_left,
            portraitImgParent = self._g_portrait_root_left.transform,
            contentTxt = self._lb_npc_talk,
            nextFlag = self._g_next,
            slotIndex = 1
        },
        [2] = {
            nameTxt = self._lb_npc_name_right,
            portraitImgParent = self._g_portrait_root_right.transform,
            contentTxt = self._lb_npc_talk,
            nextFlag = self._g_next,
            slotIndex = 2
        },
        [3] = {
            nameTxt = self._lb_npc_name_left,
            portraitImgParent = self._g_portrait_root_center.transform,
            contentTxt = self._lb_npc_talk,
            nextFlag = self._g_next,
            slotIndex = 3
        },
    }
    ---@type StoryDialogUIMediatorDialogPlayerParameter
    local parameter = {}
    parameter.dialogQueue = StoryDialogUIMediatorHelper.MakeDialogQueue(self.host._param._dialogList)
    parameter.onDialogGroupEnd = Delegate.GetOrCreate(self, self.OnDialogGroupEnd)
    parameter.onGetOperateTargets = Delegate.GetOrCreate(self, self.GetOperateTargets)
    parameter.onPlayEffect = Delegate.GetOrCreate(self, self.PlayEffect)
    parameter.onSetBackground = Delegate.GetOrCreate(self, self.SetBackGround)
    parameter.onSetLRMode = Delegate.GetOrCreate(self, self.SetLRMode)
    parameter.onSetPortraitSpine = Delegate.GetOrCreate(self, self.SetPortraitSpine)
    self.host._dialogPlayer = StoryDialogUIMediatorDialogPlayer.new(parameter)
    self:StartNextDialog()
end

function StoryDialogNPCTalkComponent:InitForChoice()
    ---@type StoryDialogUIMediatorParameterChoiceProvider
    local cfg = self.host._param._choiceConfig
    local type = cfg:Type()
    table.clear(self.host._sideChoiceOptionData)
    self:SetChoiceLRMode(cfg, type)
    local playEnd,handle = self.host:PlayVoice(cfg:Voice())
    if not playEnd then
        self.host._runningVoiceHandle = handle
    end
end

function StoryDialogNPCTalkComponent:StartNextDialog()
    self.host._dialogPlayer:StartNextDialog()
end

function StoryDialogNPCTalkComponent:OnDialogGroupEnd()
    if self.host._param._dialogEndCallback then
        self.host._param._dialogEndCallback(self.host:GetRuntimeId())
    end
end

---@return StoryDialogUIMediatorDialogPlayerOperateTargets
function StoryDialogNPCTalkComponent:GetOperateTargets(mode)
    local ret = self._modeTargets[mode]
    if not ret then
        ret = self._modeTargets[1]
    end
    return ret
end

---@param screenEffect number
---@param mode number StoryDialogPlaceType
function StoryDialogNPCTalkComponent:PlayEffect(screenEffect, mode)
    local effectTime = 0
    if screenEffect > 0 then
        if mode == StoryDialogPlaceType.Left or mode == StoryDialogPlaceType.BothLeft then
            effectTime = self._g_portrait_root_left_trigger:GetTriggerTypeAnimLength(CS.FpAnimation.CommonTriggerType.Custom1)
            self._g_portrait_root_left_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        elseif mode == StoryDialogPlaceType.Right or mode == StoryDialogPlaceType.BothRight then
            effectTime = self._g_portrait_root_right_trigger:GetTriggerTypeAnimLength(CS.FpAnimation.CommonTriggerType.Custom1)
            self._g_portrait_root_right_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        else
            effectTime = self.host._p_vx_anim_trigger:GetTriggerTypeAnimLength(CS.FpAnimation.CommonTriggerType.Custom2)
            self.host._p_vx_anim_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
        end
    end
    return effectTime
end

function StoryDialogNPCTalkComponent:SetBackGround(show, img)
    self.host:SetBackGround(show, img)
end

---@param mode number StoryDialogPlaceType
function StoryDialogNPCTalkComponent:SetLRMode(mode)
    self._g_npc_root:SetActive(true)
    local showLeft = mode == StoryDialogPlaceType.Left or mode >= StoryDialogPlaceType.Both
    local showRight = mode == StoryDialogPlaceType.Right or mode >= StoryDialogPlaceType.Both
    self._g_portrait_root_center:SetVisible(mode == StoryDialogPlaceType.Center)
    
    self._g_portrait_root_left:SetVisible(showLeft)
    self._g_base_name_left:SetVisible(mode == StoryDialogPlaceType.Left or mode == StoryDialogPlaceType.Both or mode == StoryDialogPlaceType.BothLeft or mode == StoryDialogPlaceType.Center)
    self._g_base_name_right:SetVisible(mode == StoryDialogPlaceType.Right or mode == StoryDialogPlaceType.Both or mode == StoryDialogPlaceType.BothRight)
    self._g_portrait_root_right:SetVisible(showRight)
    if mode == StoryDialogPlaceType.BothLeft and self._lastLRMode ~= mode then
        self._grayLeft = false
        self._grayRight = true
        self._p_vfx_dialog_charactor_group:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
        self._p_vfx_dialog_charactor_group:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    elseif mode == StoryDialogPlaceType.BothRight and self._lastLRMode ~= mode then
        self._grayLeft = true
        self._grayRight = false
        self._p_vfx_dialog_charactor_group:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
        self._p_vfx_dialog_charactor_group:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    elseif self._lastLRMode ~= mode then
        self._grayLeft = false
        self._grayRight = false
        self._p_vfx_dialog_charactor_group:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
        self._p_vfx_dialog_charactor_group:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
    end
    self._lastLRMode = mode
end

StoryDialogNPCTalkComponent.ColorNormal = CS.UnityEngine.Color.white
StoryDialogNPCTalkComponent.ColorGray = CS.UnityEngine.Color.HSVToRGB(0,0,0.5)

---@param spineArtId number
---@param parent CS.UnityEngine.Transform
---@param useFlipX boolean
---@param slotIndex number
function StoryDialogNPCTalkComponent:SetPortraitSpine(spineArtId, parent, useFlipX, slotIndex)
    local cell = ConfigRefer.ArtResourceUI:Find(spineArtId)
    local lastSetPortrait = self.host._lastSetPortraits[slotIndex]
    if lastSetPortrait then
        if lastSetPortrait:IsSameSpineInfo(cell, useFlipX) then
            if slotIndex == 1 then
                lastSetPortrait:SetColor(self._grayLeft and StoryDialogNPCTalkComponent.ColorGray or StoryDialogNPCTalkComponent.ColorNormal)
            elseif slotIndex == 2 then
                lastSetPortrait:SetColor(self._grayRight and StoryDialogNPCTalkComponent.ColorGray or StoryDialogNPCTalkComponent.ColorNormal)
            end
            return
        end
        lastSetPortrait:Release()
        self.host._lastSetPortraits[slotIndex] = nil
    end
    if cell and cell:Type() == UIResourceType.Icon then
        self:SetPortraitImage(cell:Path(), parent, slotIndex, useFlipX, cell)
        return
    end
    local asset = cell and cell:Path() or string.Empty
    if not string.IsNullOrEmpty(asset) then
        lastSetPortrait = SetPortraitCallBack.new()
        lastSetPortrait:SetSpineInfo(cell, useFlipX)
        if slotIndex == 1 then
            lastSetPortrait:SetColor(self._grayLeft and StoryDialogNPCTalkComponent.ColorGray or StoryDialogNPCTalkComponent.ColorNormal)
        elseif slotIndex == 2 then
            lastSetPortrait:SetColor(self._grayRight and StoryDialogNPCTalkComponent.ColorGray or StoryDialogNPCTalkComponent.ColorNormal)
        end
        self.host._lastSetPortraits[slotIndex] = lastSetPortrait
        self._goHelper:Create(asset, parent, lastSetPortrait:GetCallBack())
    end
end

---@param pic string
---@param parent CS.UnityEngine.Transform
---@param cell ArtResourceUIConfigCell
function StoryDialogNPCTalkComponent:SetPortraitImage(pic, parent, slotIndex, useFlipX, cell)
    local lastSetPortrait = self.host._lastSetPortraits[slotIndex]
    if lastSetPortrait then
        lastSetPortrait:Release()
        self.host._lastSetPortraits[slotIndex] = nil
    end
    if not string.IsNullOrEmpty(pic) then
        lastSetPortrait = SetPortraitCallBack.new()
        lastSetPortrait:SetSpineInfo(cell, useFlipX)
        self.host._lastSetPortraits[slotIndex] = lastSetPortrait
        local go = CS.UnityEngine.GameObject("created_img_host:"..pic)
        go:SetLayerRecursively("UI")
        go.transform:SetParent(parent, false)
        ---@type CS.UnityEngine.UI.Image
        local img = go:AddComponent(typeof(CS.UnityEngine.UI.Image))
        img.preserveAspect = true
        ---@type LuaSpriteSetNotify
        local notify = go:AddLuaBehaviourWithType(typeof(CS.DragonReborn.LuaSpriteSetNotify),"LuaSpriteSetNotify", "LuaSpriteSetNotifySchema").Instance
        notify._callback = function()
            notify._callback = nil
            if Utils.IsNotNull(img) then
                img:SetNativeSize()
                ---@type CS.UnityEngine.RectTransform
                local rect = img.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
                local scale = lastSetPortrait._localScale or CS.UnityEngine.Vector3.one
                local pivot = lastSetPortrait._pivot or CS.UnityEngine.Vector2(0.5, 0.5)
                if lastSetPortrait._useFlipX then
                    pivot.x = 1 - pivot.x
                    scale.x = -1 * scale.x
                end
                rect.localScale = scale
                rect.pivot = pivot
                rect.anchoredPosition = CS.UnityEngine.Vector2.zero
            end
        end
        g_Game.SpriteManager:LoadSpriteAndNotify(pic, img, true)
        local callBack =  lastSetPortrait:GetCallBack()
        if callBack then
            callBack(go)
        end
    end
end

function StoryDialogNPCTalkComponent:SetChoiceLRMode(cfg, type)
    self._g_npc_root:SetActive(true)
    local isLeft = type == 2
    self._g_content_option_left:SetActive(isLeft)
    self._g_content_option_right:SetActive(not isLeft)
    self._g_portrait_root_left:SetVisible(isLeft)
    self._g_portrait_root_right:SetVisible(not isLeft)
    self._g_base_name_left:SetVisible(isLeft)
    self._g_base_name_right:SetVisible(not isLeft)
    self._lb_npc_talk.text = cfg:DialogText()
    self._g_content_dialog:SetActive(true)
    self._g_next:SetActive(false)
    local portrait_root
    local choice_table
    if isLeft then
        portrait_root = self._g_portrait_root_left.transform
        choice_table = self._t_table_task_l
        self._lb_npc_name_left.text = cfg:CharacterName()
    else
        portrait_root = self._g_portrait_root_right.transform
        choice_table = self._t_table_task_r
        self._lb_npc_name_right.text = cfg:CharacterName()
    end
    if cfg:IsCharacterImageSprite() then
        self:SetPortraitImage(cfg:CharacterImage(), portrait_root, isLeft and 1 or 2)
    else
        self:SetPortraitSpine(cfg:CharacterSpine(), portrait_root, (not isLeft), isLeft and 1 or 2)
    end

    choice_table:Clear()
    local onClick = Delegate.GetOrCreate(self.host, self.host.OnChoice)
    for i = 1, cfg:ChoiceLength() do
        local option = cfg:Choice(i)
        ---@type StoryDialogUiOptionCellData
        local data = {}
        data.index = i
        data.content = option.content
        data.onClick = onClick
        data.showIsOnGoing = option.showIsOnGoing
        data.showNumberPair = option.showNumberPair
        data.type = option.type
        data.requireNum = option.requireNum
        data.nowNum = option.nowNum
        data.showCreep = option.isOptionShowCreep
        table.insert(self.host._sideChoiceOptionData, data)
        choice_table:AppendData(data, (i-1) % 4)
    end
    self.host._p_vx_anim_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

return StoryDialogNPCTalkComponent