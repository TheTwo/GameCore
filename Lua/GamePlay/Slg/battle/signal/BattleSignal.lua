local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local Utils = require('Utils')
local I18N = require('I18N')
local AllianceMapLabelType = require("AllianceMapLabelType")
local ConfigRefer = require("ConfigRefer")

-- local BattleSignalConfig = require('BattleSignalConfig')
---@class BattleSignal
---@field transform CS.UnityEngine.Transform
---@field iconBaseImg CS.U2DSpriteMesh
---@field iconImg CS.U2DSpriteMesh
---@field goGroupDetail CS.UnityEngine.GameObject
---@field textRestraint CS.U2DTextMesh
---@field tipTrigger CS.DragonReborn.LuaBehaviour
---@field aniTrigger CS.FpAnimation.FpAnimationCommonTrigger
---@field translateBtn CS.DragonReborn.LuaBehaviour
---@field translatingAni CS.UnityEngine.GameObject
---@field translateGroup CS.UnityEngine.GameObject
---@field vfxHolder CS.UnityEngine.Transform
---@field IsAtTroop boolean
---@field followTroopID number
---@field followTroopTypePath string
local BattleSignal = class('BattleSignal')

BattleSignal.global_translate_index = 0

function BattleSignal:ctor()
    self._showTranslate = false
    self._originContent = nil
    self._translatedContent = nil
    self._waitingTranslateIndex = nil
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self._vfx_handle = nil
end

function BattleSignal:OnEnable()
    self:SetupClickBtn()
end

function BattleSignal:OnDisable()
    ---@type MapUITrigger
    local trigger = self.translateBtn.Instance
    trigger:SetTrigger(nil)
end

---@param param BattleSignalData
function BattleSignal:FeedData(param)
    self._waitingTranslateIndex = nil
    self._showTranslate = false
    self.slgModule = ModuleRefer.SlgModule
    -- local param = BattleSignalConfig.MakeParameter(data)

    self.IsAtTroop = false
    g_Game.SpriteManager:LoadSprite(param.icon, self.iconImg)
    self._originContent = param.content
    self._translatedContent = nil
    self.translatingAni:SetVisible(false)

    if param.Type == AllianceMapLabelType.ConveneCenter then
        local allianceGatherPointConfigID = ConfigRefer.AllianceConsts:AllianceConveneLabel()
        local mapLabelConfig = ConfigRefer.AllianceMapLabel:Find(allianceGatherPointConfigID)
        local mapLabelContent = I18N.Get(mapLabelConfig:DefaultDesc())
        self.translateGroup:SetVisible(false)
        self._originContent = mapLabelContent
        self._translatedContent = mapLabelContent
        self:SetTipClickCallback()
    else
        self.translateGroup:SetVisible(true)
    end

    if string.IsNullOrEmpty(self._originContent) then        
        self.goGroupDetail:SetVisible(false)
    else
        self.goGroupDetail:SetVisible(true)
        self.textRestraint.text = self._originContent
        self:SetupClickBtn()
    end    
    if param.X > 0 and param.Y > 0 then
        self.followTroopID = 0
        -- self.followTroopTypePath = nil
        self.transform.position = CS.UnityEngine.Vector3(
            param.X * self.slgModule.unitsPerTileX ,
            0,
            param.Y * self.slgModule.unitsPerTileZ
        )        
        CS.TransformHelper.SetPositionSyncHelper(self.transform,nil)
    elseif param.troopId and param.troopId > 0 then
        self.IsAtTroop = true
        self.followTroopID = param.troopId                               
        -- self.followTroopTypePath = nil
        local troopData = self.slgModule:FindTroop(self.followTroopID)
        if troopData ~= nil then
            -- self.followTroopTypePath = self.slgModule:GetDBEntityTypeByWdsType(troopData.TypeHash).MapBasics.Position.MsgPath
            local ctrl = self.slgModule.troopManager:FindTroopCtrl(self.followTroopID)
            if ctrl and ctrl:GetCSView() then            
                local followTrans = ctrl:GetCSView().transform
                -- UIHelper.SetWSTransAnchor(self.slgModule:GetCamera(),self.CSComponent.transform,ctrl:GetCSView().transform)
                CS.TransformHelper.SetPositionSyncHelper(self.transform,followTrans)
            else            
                self.transform.position = CS.UnityEngine.Vector3(
                    troopData.MapBasics.Position.X * self.slgModule.unitsPerTileX ,
                    0,
                    troopData.MapBasics.Position.Y * self.slgModule.unitsPerTileZ
                )                   
                CS.TransformHelper.SetPositionSyncHelper(self.transform,nil)
            end
            --当TroopCtrl被删除后，使用wds.Troop的位置更新标记
            -- g_Game.DatabaseManager:AddChanged(self.followTroopTypePath,Delegate.GetOrCreate(self,self.OnTroopEntityChanged))
        end
    end
    if self._vfx_handle and self._vfx_handle.PrefabName ~= param.vfxEffect then
        self._vfx_handle:Delete()
        self._vfx_handle = nil
    end
    if not string.IsNullOrEmpty(param.vfxEffect) and param.vfxScale and not self._vfx_handle then
        local helper = ModuleRefer.SlgModule.signalManager.vfxCreateHelper
        if helper then
            self._vfx_handle = helper:Create(param.vfxEffect, self.vfxHolder, Delegate.GetOrCreate(self, self.OnVfxLoaded), param.vfxScale)
        end
    end
end

---@param go CS.UnityEngine.GameObject
function BattleSignal:OnVfxLoaded(go, scale)
    if Utils.IsNull(go) or not scale then
        return
    end
    go.transform.localScale = CS.UnityEngine.Vector3.one * scale
end

function BattleSignal:PlayDropDownAni()
    if Utils.IsNull(self.aniTrigger) then
        return
    end
    self.aniTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

function BattleSignal:OnClickTranslate()
    g_Logger.Log("OnClickTranslate")
    if self._showTranslate then
        self._showTranslate = false
        self.textRestraint.text = self._originContent
        self.translateBtn:SetVisible(true)
        self.translatingAni:SetVisible(false)
        self:SetupClickBtn()
    else
        if string.IsNullOrEmpty(self._originContent) then
            return
        end
        self._showTranslate = true
        if self._translatedContent ~= nil then
            self.textRestraint.text = self._translatedContent
            return
        end
        if self._waitingTranslateIndex then
            return
        end
        self.translateBtn:SetVisible(false)
        self.translatingAni:SetVisible(true)
        local chatSdk = CS.FunPlusChat.FPChatSdk
        self._waitingTranslateIndex = BattleSignal.global_translate_index
        local waitIdx = self._waitingTranslateIndex
        BattleSignal.global_translate_index = BattleSignal.global_translate_index + 1
        chatSdk.Translate(self._originContent, CS.FunPlusChat.FunLang.unknown, ModuleRefer.ChatSDKModule:GetUserLanguage(), function(result)
            if waitIdx ~= self._waitingTranslateIndex then
                return
            end
            self.translateBtn:SetVisible(true)
            self.translatingAni:SetVisible(false)
            self:SetupClickBtn()
            self._waitingTranslateIndex = nil
            self._translatedContent = result and result.data and result.data.targetText
            if self._showTranslate then
                self.textRestraint.text = self._translatedContent
            end
        end, "Livedata")
    end
end

function BattleSignal:OnClickTip()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_gathering_point_10"))
end

function BattleSignal:SetupClickBtn()
    ---@type MapUITrigger
    local trigger = self.translateBtn.Instance
    trigger:SetTrigger(Delegate.GetOrCreate(self, self.OnClickTranslate))
end

function BattleSignal:SetTipClickCallback()
    ---@type MapUITrigger
    local trigger = self.tipTrigger.Instance
    trigger:SetTrigger(Delegate.GetOrCreate(self, self.OnClickTip))
end

-- function BattleSignal:OnTroopEntityChanged(entity,changed)
--     if not self.followTroopID or self.followTroopID < 1 or entity.ID ~= self.followTroopID then
--         return
--     end

--     if Utils.IsNull(self.followTrans) then
--         local troopData = entity
--         local posWS = CS.UnityEngine.Vector3(
--             troopData.MapBasics.Position.X * self.slgModule.unitsPerTileX ,
--             0,
--             troopData.MapBasics.Position.Y * self.slgModule.unitsPerTileZ
--         )   
        
--     end
-- end


return BattleSignal