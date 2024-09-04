local Utils = require("Utils")
local I18N = require("I18N")
local ArtResourceUtils = require("ArtResourceUtils")
local StoryDialogPlaceType = require("StoryDialogPlaceType")

---@class StoryDialogUIMediatorDialogPlayer
---@field new fun(param:StoryDialogUIMediatorDialogPlayerParameter):StoryDialogUIMediatorDialogPlayer
local StoryDialogUIMediatorDialogPlayer = sealedClass('StoryDialogUIMediatorDialogPlayer')

---@class StoryDialogUIMediatorDialogPlayerOperateTargets
---@field nameTxt CS.UnityEngine.UI.Text
---@field portraitImgParent CS.UnityEngine.Transform
---@field headIcon CS.UnityEngine.UI.Image
---@field contentTxt CS.UnityEngine.UI.Text
---@field nextFlag CS.UnityEngine.GameObject
---@field slotIndex number

---@class StoryDialogUIMediatorDialogPlayerParameter
---@field dialogQueue StoryDialogUIMediatorDialogQueue
---@field onDialogGroupEnd fun()
---@field onGetOperateTargets fun(mode:number):StoryDialogUIMediatorDialogPlayerOperateTargets
---@field onPlayEffect fun(screenEffect:number, mode:number):number
---@field onSetBackground fun(show:boolean,img:string)
---@field onSetLRMode fun(mode:number)
---@field onSetPortraitSpine fun(spineArtId:number, parent:CS.UnityEngine.Transform,useFlipX:boolean, slotIndex:number)
---@field onSetHeadIcon fun(pic:string, headIcon:CS.UnityEngine.UI.Image)
---@field onSetChatPosition fun(config:StoryDialogConfigCell)
---@field noTyperEffect boolean

---@param param StoryDialogUIMediatorDialogPlayerParameter
function StoryDialogUIMediatorDialogPlayer:ctor(param)
    self._runningVoiceHandle = nil
    self._autoStatus = 0
    self._speedMode = 1
    
    self._parameter = param
    self._dialogPlayQueue = param.dialogQueue
    self._onDialogGroupEnd = param.onDialogGroupEnd
end

function StoryDialogUIMediatorDialogPlayer:StartNextDialog()
    local q = self._dialogPlayQueue
    if (not q) or (q._currentIndex >= #q._queue) then
        if q then
            if q._voiceHandle then
                g_Game.SoundManager:Stop(q._voiceHandle)
            end
            self._runningVoiceHandle = nil
            q._typerStyle:StopTyping()
        end
        self._dialogPlayQueue = nil
        self:OnDialogGroupEnd()
        return
    end
    q._typerStyle:SetIntervalMultiple((self._autoStatus == 1) and (1.0 / self._speedMode) or 1.0)
    q._currentIndex = q._currentIndex + 1
    local d = q._queue[q._currentIndex]
    q._delayLeftTime = d:WaitTime()
    q._effectListTime = self:PlayEffect(d:ShakingScreen(), d:Type())
    if q._voiceHandle then
        g_Game.SoundManager:Stop(q._voiceHandle)
    end
    q._voiceHandle = nil
    self._runningVoiceHandle = nil
    q._voiceEnd, q._voiceHandle = self:PlayVoice(d:DubbingRes() > 0 and ArtResourceUtils.GetAudio(d:DubbingRes()) or string.Empty)
    if not q._voiceEnd then
        self._runningVoiceHandle = q._voiceHandle
        q._voiceHandle:OnEnd('+', function(id) q._voiceEnd = true  end)
    end
    local backGround = d:Background() > 0 and ArtResourceUtils.GetUIItem(d:Background()) or string.Empty
    if string.IsNullOrEmpty(backGround) then
        self:SetBackground(false)
    else
        self:SetBackground(true, backGround)
    end
    local lor = d:Type()
    self:SetLRMode(lor)
    ---@type StoryDialogUIMediatorDialogPlayerOperateTargets
    local operateTargets
    if lor >= StoryDialogPlaceType.Both then
        operateTargets = self:GetOperateTargets(StoryDialogPlaceType.Left)
        self:DoSetLRSetPortrait(d,operateTargets,StoryDialogPlaceType.Left)
        self:DoSetLRSetPortrait(d, self:GetOperateTargets(StoryDialogPlaceType.Right), StoryDialogPlaceType.Right)
    else
        operateTargets = self:GetOperateTargets(lor)
        self:DoSetLRSetPortrait(d, operateTargets, lor)
    end
    self:SetChatPosition(d)
    local contentTxt = operateTargets.contentTxt
    if not self._parameter.noTyperEffect then
        q._playingTyping = self:PlayTyping(q._typerStyle, I18N.Get(d:DialogKey()), contentTxt, q, 0.02, function()
            if operateTargets and Utils.IsNotNull(operateTargets.nextFlag) then
                operateTargets.nextFlag:SetVisible(true)
            end
        end)
        q._delayLeftTime = q._delayLeftTime + q._typerStyle:CalculateTime(0.012)
    else
        q._playingTyping = false
        contentTxt.text = I18N.Get(d:DialogKey())
    end
end

---@param d StoryDialogConfigCell
---@param operateTargets StoryDialogUIMediatorDialogPlayerOperateTargets
function StoryDialogUIMediatorDialogPlayer:DoSetLRSetPortrait(d, operateTargets, lor)
    local nameTxt = operateTargets.nameTxt
    local portraitImg = operateTargets.portraitImgParent
    local nextFlag = operateTargets.nextFlag
    local headIcon = operateTargets.headIcon
    if Utils.IsNotNull(nextFlag) then
        nextFlag:SetVisible(false)
    end
    if Utils.IsNotNull(nameTxt) then
        local nameTextI18N
        if lor == StoryDialogPlaceType.Right then
            nameTextI18N = d:CharacterNameRight()
        end
        if string.IsNullOrEmpty(nameTextI18N) then
            nameTextI18N = d:CharacterName()
        end
        nameTxt.text = I18N.Get(nameTextI18N)
    end
    if Utils.IsNotNull(portraitImg) then
        local portraitAsset = 0
        local useFlipX = false
        if lor == StoryDialogPlaceType.Right then
            portraitAsset = d:CharacterImageRight()
            useFlipX = true
        end
        if portraitAsset <= 0 then
            portraitAsset = d:CharacterImage()
        end
        self:SetPortraitSpine(portraitAsset, portraitImg, useFlipX, operateTargets.slotIndex)
    end
    if Utils.IsNotNull(headIcon) then
        local headIconAsset
        if lor == StoryDialogPlaceType.Right then
            headIconAsset = ArtResourceUtils.GetUIItem(d:CharacterSmallImageRight())
        end
        if string.IsNullOrEmpty(headIconAsset) then
            headIconAsset = ArtResourceUtils.GetUIItem(d:CharacterSmallImage())
        end
        self:SetHeadIcon(headIconAsset, headIcon)
    end
end

function StoryDialogUIMediatorDialogPlayer:OnClickDialogNext()
    local q = self._dialogPlayQueue
    if q then
        --if self._autoStatus > 0 then
        --    return
        --end
        if q._effectListTime > 0 then
            return
        end
        local completeNow = false
        if q._playingTyping then
            q._typerStyle:CompleteTyping()
            q._playingTyping = false
            completeNow = true
        end
        if completeNow then
            return
        end
        if not q._voiceEnd then
            if q._voiceHandle then
                g_Game.SoundManager:Stop(q._voiceHandle)
            end 
            self._runningVoiceHandle = nil
            q._voiceHandle = nil
            q._voiceEnd = true
            -- completeNow = true
        end
        self:StartNextDialog()
    end
end

---@param status number
function StoryDialogUIMediatorDialogPlayer:SwitchAutoStatus(status)
    self._autoStatus = status
    if self._autoStatus ~= 1 then
        self._speedMode = 1
    end
    self:SetupTypeSpeed()
    return self._autoStatus
end

function StoryDialogUIMediatorDialogPlayer:ToggleAutoStatus()
    self._autoStatus = self._autoStatus + 1
    if self._autoStatus > 2 then
        self._autoStatus = 1
    end
    if self._autoStatus ~= 1 then
        self._speedMode = 1
    end
    self:SetupTypeSpeed()
    return self._autoStatus
end

function StoryDialogUIMediatorDialogPlayer:GetAutoStatus()
    return self._autoStatus
end

---@param status number
function StoryDialogUIMediatorDialogPlayer:SwitchPlaySpeedModeStatus(status)
    self._speedMode = status
end

function StoryDialogUIMediatorDialogPlayer:TogglePlaySpeedMode()
    if self._autoStatus ~= 1 then
        self._speedMode = 1
    else
        self._speedMode = self._speedMode + 1
        if self._speedMode > 2 then
            self._speedMode = 1
        end
    end
    self:SetupTypeSpeed()
    return self._speedMode
end

function StoryDialogUIMediatorDialogPlayer:SetupTypeSpeed()
    if self._dialogPlayQueue and self._dialogPlayQueue._typerStyle then
        self._dialogPlayQueue._typerStyle:SetIntervalMultiple(1.0 / self._speedMode)
    end
end

function StoryDialogUIMediatorDialogPlayer:GetPlaySpeedMode()
    return self._speedMode
end

---@param screenEffect number
---@param mode number StoryDialogPlaceType
function StoryDialogUIMediatorDialogPlayer:PlayEffect(screenEffect, mode)
    if self._parameter.onPlayEffect then
        return self._parameter.onPlayEffect(screenEffect, mode)
    end
    return 0
end

function StoryDialogUIMediatorDialogPlayer:OnDialogGroupEnd()
    if self._onDialogGroupEnd then
        self._onDialogGroupEnd()
        self._onDialogGroupEnd = nil
    end
end

function StoryDialogUIMediatorDialogPlayer:SetBackground(show, img)
    if self._parameter.onSetBackground then
        self._parameter.onSetBackground(show, img)
    end
end

---@param mode number StoryDialogPlaceType
function StoryDialogUIMediatorDialogPlayer:SetLRMode(mode)
    if self._parameter.onSetLRMode then
        self._parameter.onSetLRMode(mode)
    end
end

---@param mode number
---@return StoryDialogUIMediatorDialogPlayerOperateTargets
function StoryDialogUIMediatorDialogPlayer:GetOperateTargets(mode)
    return self._parameter.onGetOperateTargets(mode)
end

---@param config StoryDialogConfigCell
function StoryDialogUIMediatorDialogPlayer:SetChatPosition(config)
    if self._parameter.onSetChatPosition then
        self._parameter.onSetChatPosition(config)
    end
end

---@param spineArtId number
---@param parent CS.UnityEngine.Transform
---@param useFlipX boolean
---@param slot number
function StoryDialogUIMediatorDialogPlayer:SetPortraitSpine(spineArtId, parent, useFlipX, slotIndex)
    if self._parameter.onSetPortraitSpine then
        self._parameter.onSetPortraitSpine(spineArtId, parent, useFlipX, slotIndex)
    end
end

---@param pic string
---@param image CS.UnityEngine.UI.Image
function StoryDialogUIMediatorDialogPlayer:SetHeadIcon(pic, image)
    if self._parameter.onSetHeadIcon then
        self._parameter.onSetHeadIcon(pic, image)
    end
end

---@param typer TyperStyle
---@param content string
---@param label CS.UnityEngine.UI.Text
---@param dialogPlayQueue table
---@param speed number
---@param typeEnd fun()
function StoryDialogUIMediatorDialogPlayer:PlayTyping(typer, content, label, dialogPlayQueue, speed, typeEnd)
    if string.IsNullOrEmpty(content) then
        return false
    end
    if Utils.IsNull(label) then
        return false
    end
    typer:Initialize(content, function(text)
        if Utils.IsNotNull(label) then
            label.text = text
        end
    end, function()
        dialogPlayQueue._playingTyping = false
        if typeEnd then
            typeEnd()
        end
    end, speed)
    typer:StartTyping()
    return true
end

function StoryDialogUIMediatorDialogPlayer:Tick(delta)
    local q = self._dialogPlayQueue
    if not q then
        return
    end
    local mul = (self._autoStatus == 1) and self._speedMode or 1
    if q._delayLeftTime > 0 then
        q._delayLeftTime = q._delayLeftTime - delta * mul
    end
    if q._effectListTime > 0 then
        q._effectListTime = q._effectListTime - delta * mul
    end
    if self._autoStatus ~= 1 then
        return
    end
    if (not q._voiceEnd) or q._playingTyping then
        return
    end
    if q._delayLeftTime <= 0 and q._effectListTime <= 0 then
        self:StartNextDialog()
    end
end

function StoryDialogUIMediatorDialogPlayer:PlayVoice(voice)
    if string.IsNullOrEmpty(voice) then
        return true, nil
    end
    return false, g_Game.SoundManager:Play(voice)
end

function StoryDialogUIMediatorDialogPlayer:GetCurrentIndex()
    return self._dialogPlayQueue and self._dialogPlayQueue._currentIndex
end

function StoryDialogUIMediatorDialogPlayer:CleanUp()
    if self._dialogPlayQueue and self._dialogPlayQueue._typerStyle then
        self._dialogPlayQueue._typerStyle:StopTyping()
    end
end

return StoryDialogUIMediatorDialogPlayer

