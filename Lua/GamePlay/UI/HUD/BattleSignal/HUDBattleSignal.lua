local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local Utils = require('Utils')
local BattleSignalConfig = require('BattleSignalConfig')
---@class HUDBattleSignal : BaseUIComponent
local HUDBattleSignal = class('HUDBattleSignal', BaseUIComponent)

---@class BattleSignalData
---@field Type number
---@field X number
---@field Y number
---@field troopId number
---@field icon string
---@field content string
---@field vfxEffect string|nil
---@field vfxScale number|nil

function HUDBattleSignal:ctor()
    BaseUIComponent.ctor(self)
    self.slgModule = ModuleRefer.SlgModule
    self.followTroopID = 0
    self.IsAtTroop = false
end

function HUDBattleSignal:OnCreate()
    self.imgBase = self:Image('p_base')
    self.imgIcon = self:Image('p_icon')
    self.goGroupDetail = self:GameObject('p_group_detail')
    self.textRestraint = self:Text('p_text_restraint')
end

function HUDBattleSignal:OnHide(param)    
    if self.followTroopID and self.followTroopID >= 1 and not string.IsNullOrEmpty(self.followTroopTypePath) then
        g_Game.DatabaseManager:RemoveChanged(self.followTroopTypePath,Delegate.GetOrCreate(self,self.OnTroopEntityChanged))
    end
end

---@param param BattleSignalData
function HUDBattleSignal:OnFeedData(param)
    self.IsAtTroop = false
    g_Game.SpriteManager:LoadSprite(param.icon, self.imgIcon)
    if string.IsNullOrEmpty(param.Content) then        
        self.goGroupDetail:SetVisible(false)
    else
        self.goGroupDetail:SetVisible(true)
        self.textRestraint.text = I18N.Get(param.Content)
    end    
    if param.X > 0 and param.Y > 0 then
        self.followTroopID = 0
        self.followTroopTypePath = nil
        self.worldPos = CS.UnityEngine.Vector3(
            param.X * self.slgModule.unitsPerTileX ,
            0,
            param.Y * self.slgModule.unitsPerTileZ
        )   
        UIHelper.SetWSPosAnchor(self.slgModule:GetCamera(),self.CSComponent.transform,self.worldPos)   
        self:SetVisible(true)   
    elseif param.troopId and param.troopId > 0 then
        self.IsAtTroop = true
        self.followTroopID = param.troopId                        
        self.worldPos = nil
        self.followTroopTypePath = nil
        local troopData = self.slgModule:FindTroop(self.followTroopID)
        if troopData ~= nil then
            self.followTroopTypePath = self.slgModule:GetDBEntityTypeByWdsType(troopData.TypeHash).MapBasics.Position.MsgPath
            local ctrl = self.slgModule.troopManager:FindTroopCtrl(self.followTroopID)
            if ctrl and ctrl:GetCSView() then            
                self.followTrans = ctrl:GetCSView().transform
                UIHelper.SetWSTransAnchor(self.slgModule:GetCamera(),self.CSComponent.transform,ctrl:GetCSView().transform)
            else            
                local posWS = CS.UnityEngine.Vector3(
                    troopData.MapBasics.Position.X * self.slgModule.unitsPerTileX ,
                    0,
                    troopData.MapBasics.Position.Y * self.slgModule.unitsPerTileZ
                )   
                UIHelper.SetWSPosAnchor(self.slgModule:GetCamera(),self.CSComponent.transform,posWS)
            end
            --当TroopCtrl被删除后，使用wds.Troop的位置更新标记
            g_Game.DatabaseManager:AddChanged(self.followTroopTypePath,Delegate.GetOrCreate(self,self.OnTroopEntityChanged))
        end

        if self.followTroopTypePath then
            self:SetVisible(true)
        else
            self:SetVisible(false)
        end
    end
end

function HUDBattleSignal:OnTroopEntityChanged(entity,changed)
    if not self.followTroopID or self.followTroopID < 1 or entity.ID ~= self.followTroopID then
        return
    end

    if Utils.IsNull(self.followTrans) then
        local troopData = entity
        local posWS = CS.UnityEngine.Vector3(
            troopData.MapBasics.Position.X * self.slgModule.unitsPerTileX ,
            0,
            troopData.MapBasics.Position.Y * self.slgModule.unitsPerTileZ
        )   
        UIHelper.SetWSPosAnchor(self.slgModule:GetCamera(),self.CSComponent.transform,posWS)
    end
end

-- function HUDBattleSignal:OnTroopCtrlExist(troopId)
--     if not self.followTroopID or self.followTroopID < 1 or troopId ~= self.followTroopID then
--         return
--     end
--     self:RefreshFollowTroop()
-- end

function HUDBattleSignal:RefreshFollowTroop()
    if not self.followTroopID or self.followTroopID < 1 then return end
    local ctrl = self.slgModule.troopManager:FindTroopCtrl(self.followTroopID)
    if ctrl and ctrl:GetCSView() then            
        self.followTrans = ctrl:GetCSView().transform
        UIHelper.SetWSTransAnchor(self.slgModule:GetCamera(),self.CSComponent.transform,ctrl:GetCSView().transform)
        if self.followTroopTypePath == nil then
            local troopData = self.slgModule:FindTroop(self.followTroopID)
            if troopData ~= nil then
                self.followTroopTypePath = self.slgModule:GetDBEntityTypeByWdsType(troopData.TypeHash).MapBasics.Position.MsgPath
                g_Game.DatabaseManager:AddChanged(self.followTroopTypePath,Delegate.GetOrCreate(self,self.OnTroopEntityChanged))
            end
        end
        self:SetVisible(true)
    else
        self.followTrans = nil
        self:SetVisible(false)
    end
end

return HUDBattleSignal
