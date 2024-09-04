local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local TimeFormatter = require('TimeFormatter')
local CircleMenuButtonConfig = require('CircleMenuButtonConfig')
local DBEntityType = require("DBEntityType")
local DBEntityPath = require('DBEntityPath')
local AllianceAuthorityItem = require('AllianceAuthorityItem')
local UIMediatorNames = require('UIMediatorNames')
local KingdomMapUtils = require('KingdomMapUtils')
local CheckTroopTrusteeshipStateDefine = require("CheckTroopTrusteeshipStateDefine")
local CityUtils = require('CityUtils')

---@class TroopCircleMenuMediator : BaseUIMediator
---@field targetTroop wds.Troop
---@field troopCtrl TroopCtrl
---@field troopView TroopView
---@field compTroopInfoBottom CommonTimer
local TroopCircleMenuMediator = class('TroopCircleMenuMediator', BaseUIMediator)

function TroopCircleMenuMediator:ctor()
    
end

function TroopCircleMenuMediator:OnCreate()
    ---@type CircleMenuSimpleButtons
    self.compTroopInfoRight = self:LuaObject('child_circle_menu_simple_buttons')
    self.goTropInfoBottom = self:GameObject('p_trop_info_bottom')
    ---@type CommonTimer
    self.compTroopInfoBottom = self:LuaObject('p_trop_info_bottom')    
end


function TroopCircleMenuMediator:OnShow(param)    
    if not param.troopCtrl then
        self:CloseSelf()
        return
    end

    if self.troopCtrl ~= nil then
        self:UnRegisterDBChanged()
    end
    self.troopCtrl = param.troopCtrl    
    ---@type wds.Troop | wds.MapMob | wds.MobileFortress
    self.troopData = self.troopCtrl._data
    self:RegisterDBChanged()
       
    local slgModule = ModuleRefer.SlgModule
    local view = self.troopCtrl:GetCSView()
    if not view then
        self:CloseSelf()
        return
    end
        
    self:UpdateMapStates(self.troopData)
    self:OnMovePathInfoChanged(self.troopData.ID)
    self:StupButtons()

    UIHelper.SetWSTransAnchor(slgModule:GetCamera(),self.CSComponent.transform, view.transform)  

    local KingdomMapUtils = require("KingdomMapUtils")
    if KingdomMapUtils.IsNewbieState() then
        self.compTroopInfoRight:SetVisible(false)
    end
end

function TroopCircleMenuMediator:OnHide(param)
    if self.troopCtrl ~= nil then
        self:UnRegisterDBChanged()
        self.troopCtrl = nil
    end
    
end

function TroopCircleMenuMediator:RegisterDBChanged()
    g_Game.DatabaseManager:AddChanged(self.troopCtrl._dbEntityPath.MapStates.MsgPath,Delegate.GetOrCreate(self,self.UpdateMapStates))
    g_Game.EventManager:AddListener(EventConst.SLGTROOP_PATH_CHANGED,Delegate.GetOrCreate(self,self.OnMovePathInfoChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_MAPLABLE_CHANGED,Delegate.GetOrCreate(self,self.UpdateButtons))
    if self.troopData.TypeHash == wds.MobileFortress.TypeHash and ModuleRefer.SlgModule:IsMobileFortressBuilding(self.troopData) then
        g_Game.DatabaseManager:AddChanged(self.troopCtrl._dbEntityPath.MsgPath,Delegate.GetOrCreate(self,self.UpdateButtons))
    end
end

function TroopCircleMenuMediator:UnRegisterDBChanged()
    g_Game.DatabaseManager:RemoveChanged(self.troopCtrl._dbEntityPath.MapStates.MsgPath,Delegate.GetOrCreate(self,self.UpdateMapStates))
    g_Game.EventManager:RemoveListener(EventConst.SLGTROOP_PATH_CHANGED,Delegate.GetOrCreate(self,self.OnMovePathInfoChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_MAPLABLE_CHANGED,Delegate.GetOrCreate(self,self.UpdateButtons))
    if self.troopData.TypeHash == wds.MobileFortress.TypeHash and ModuleRefer.SlgModule:IsMobileFortressBuilding(self.troopData) then
        g_Game.DatabaseManager:RemoveChanged(self.troopCtrl._dbEntityPath.MsgPath,Delegate.GetOrCreate(self,self.UpdateButtons))
    end
end

function TroopCircleMenuMediator:UpdateButtons(data,changed)    
    self:StupButtons()
end

---@param data wds.Troop
function TroopCircleMenuMediator:UpdateMapStates(data,changed) 
    if not data or data.ID ~= self.troopData.ID then return end

    if data.MapStates.HideOnMap and not data.GatherInfo.InGather or not require('SlgUtils').IsTroopSelectable(data) then
        require('TimerUtility').DelayExecuteInFrame( function() self:CloseSelf() end,5 ) 
        return
    end     
end

function TroopCircleMenuMediator:OnMovePathInfoChanged(entityId)
    if entityId ~= self.troopData.ID then return end

    if  self.troopCtrl:IsSelf() then
        local data = self.troopData        
        if data.MapStates.Moving then            
            -- if not self.showMoveTimer then
                --self.showMoveTimer = true            
                self.goTropInfoBottom:SetVisible(true)
                local viewer = self.troopCtrl:GetTroopView()
                if viewer then
                    local endTime = viewer:GetMoveStopTime()
                    self.compTroopInfoBottom:RecycleTimer()     
                    self.compTroopInfoBottom:FeedData(                
                    ---@type CommonTimerData    
                    {
                        endTime = endTime,
                        needTimer = true,
                        intervalTime = 0.2
                    })
                end
            -- end
        else            
            self.goTropInfoBottom:SetVisible(false)
            --self.showMoveTimer = false
        end
    else
        self.goTropInfoBottom:SetVisible(false)
        --self.showMoveTimer = false
    end
end

---@param buttonDatas CircleMenuSimpleButtonData[]
function TroopCircleMenuMediator:SetupMyTroopButtons(buttonDatas)
    local slgModule = ModuleRefer.SlgModule
    --My Troop
    --回城按钮
    table.insert(buttonDatas, {
        buttonIcon = CircleMenuButtonConfig.ButtonIcons.IconTroopBackArraw,
        buttonBack = CircleMenuButtonConfig.ButtonBacks.BackNormal,
        buttonEnable = not self.troopCtrl:IsGoingBackToCity(),
        onClick = Delegate.GetOrCreate(self,self.OnButtonCallback_BackHome)
    })

    if not slgModule:IsInCity() and self.troopCtrl:IsGoingBackToCity() then
    --立即回城按钮
        local itemId,itemNeed = slgModule.dataCache:GetBackCityItem()
        if itemId and itemId > 0 then
            local itemIcon,itemBack = slgModule.dataCache:GetBackCityItemIcon()
            itemBack = CircleMenuButtonConfig.ButtonBacks.BackNormal
            local itemAmount = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)

            table.insert(buttonDatas,{
                buttonIcon = itemIcon,
                buttonBack = itemBack,
                number = itemNeed,
                buttonEnable = itemAmount >= itemNeed,
                onClick = Delegate.GetOrCreate(self,self.OnButtonCallback_BackHomeImmediately),
                onClickFailed = Delegate.GetOrCreate(self,self.OnButtonCallback_BackHomeImmediatelyFailed)
            })
        end
    end

    if not slgModule:IsInCity() then
        
        local autoState = self.troopData.MapStates.StateWrapper2.AutoBattle

        local cityLvl = CityUtils.GetBaseLevel()
        local minLvl = ConfigRefer.ConstMain:Autobattlehide()
        if cityLvl > minLvl then
            local icon = CircleMenuButtonConfig.ButtonIcons.IconTroopAtt
            local back = CircleMenuButtonConfig.ButtonBacks.BackNormal
            local btnEnable = not self.troopData.MapStates.StateWrapper2.AutoClearExpedition
            --自动战斗
            table.insert(buttonDatas,{
                    buttonIcon = icon,
                    buttonBack = back,
                    buttonEnable = btnEnable,
                    activeNoticeAnim = autoState,
                    onClick = Delegate.GetOrCreate(self,self.OnButtonCallback_AutoBattle),
                    onClickFailed = Delegate.GetOrCreate(self,self.OnButtonCallback_AutoBattleFailed)

                }    
            )
        end
    end       
end

---@param buttonDatas CircleMenuSimpleButtonData[]
function TroopCircleMenuMediator:SetupFirendButtons(buttonDatas)
    if self.troopData.TypeHash == wds.MobileFortress.TypeHash then            
        --强化移动堡垒
        -- if slgModule:IsMobileFortressBuilding(self.troopData) then
        --     --table.insert(buttonDatas, {
        --     --    buttonIcon = CircleMenuButtonConfig.ButtonIcons.IconInfo,
        --     --    buttonBack = CircleMenuButtonConfig.ButtonBacks.BackNormal,
        --     --    buttonEnable = true,
        --     --    onClick = Delegate.GetOrCreate(self,self.OnButtonCallback_MobileFortressDetail)
        --     --})
        --     table.insert(buttonDatas,{
        --         buttonIcon = CircleMenuButtonConfig.ButtonIcons.IconStrength,
        --         buttonBack = CircleMenuButtonConfig.ButtonBacks.BackNormal,
        --         buttonEnable = true,
        --         onClick = Delegate.GetOrCreate(self,self.OnButtonCallback_Strengthen),
        --     })
        -- end

        local hasAuthority = ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.MoveMobileFortress)
        if hasAuthority and self.troopCtrl._data.BehemothTroopInfo and self.troopCtrl._data.BehemothTroopInfo.MonsterTid ~= 0 then
            hasAuthority = ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.SummonBehemoth)
        end

        if ModuleRefer.AllianceModule:IsInAlliance() and hasAuthority then
            table.insert(buttonDatas,{
                buttonIcon = CircleMenuButtonConfig.ButtonIcons.IconStorage,
                buttonBack = CircleMenuButtonConfig.ButtonBacks.BackNegtive,
                buttonEnable = true,
                onClick = Delegate.GetOrCreate(self,self.OnButtonCallback_Remove)
            })
        end
    end
    
    --table.insert(buttonDatas, {
    --    buttonIcon = CircleMenuButtonConfig.ButtonIcons.IconInfo,
    --    buttonBack = CircleMenuButtonConfig.ButtonBacks.BackNormal,
    --    buttonEnable = true,
    --    onClick = Delegate.GetOrCreate(self,self.OnButtonCallback_TroopDestInfo)
    --})    
end

---@param buttonDatas CircleMenuSimpleButtonData[]
function TroopCircleMenuMediator:SetupEnemyTroopButtons(buttonDatas)
    --攻击按钮
    buttonDatas[1] = {
        buttonIcon = CircleMenuButtonConfig.ButtonIcons.IconTroopAtt,
        buttonBack = CircleMenuButtonConfig.ButtonBacks.BackNegtive,
        buttonEnable = true,
        onClick = Delegate.GetOrCreate(self,self.OnButtonCallback_AttackTarget)
    }   
end

function TroopCircleMenuMediator:StupButtons()

    if not self.troopCtrl or self.troopCtrl:IsMonster() or self.troopCtrl:IsPuppet() then        
        self.compTroopInfoRight:SetVisible(false)
        return
    end
    
    local slgModule = ModuleRefer.SlgModule
    ---@type CircleMenuSimpleButtonData[]
    local buttonDatas = {}
    if slgModule:IsMyTroop(self.troopData) then
        self:SetupMyTroopButtons(buttonDatas)
    elseif slgModule:IsMyAlliance(self.troopData) then
        self:SetupFirendButtons(buttonDatas)
    else
        --Enemy Troop
        self:SetupEnemyTroopButtons(buttonDatas)
    end

    if ModuleRefer.AllianceModule:IsInAlliance() and ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.ModifyMapLabel) then

        if ModuleRefer.SlgModule:HasSignalOnEntity(self.troopData.ID) then
            table.insert(buttonDatas, {
                buttonIcon = CircleMenuButtonConfig.ButtonIcons.IconUnmark,
                buttonBack = CircleMenuButtonConfig.ButtonBacks.BackNegtive,
                buttonEnable = true,
                onClick = Delegate.GetOrCreate(self,self.OnButtonCallback_RemoveBattleSignal)
            })
        else
            table.insert(buttonDatas, {
                buttonIcon = CircleMenuButtonConfig.ButtonIcons.IconMark,
                buttonBack = CircleMenuButtonConfig.ButtonBacks.BackNormal,
                buttonEnable = true,
                onClick = Delegate.GetOrCreate(self,self.OnButtonCallback_AddBattleSignal)
            })
        end
    end
    
    if #buttonDatas > 0 then
        self.compTroopInfoRight:SetVisible(true)
        self.compTroopInfoRight:FeedData(buttonDatas)    
    else
        self.compTroopInfoRight:SetVisible(false)
    end
end


function TroopCircleMenuMediator:OnButtonCallback_BackHome()       
    if self.troopCtrl then
        local function __OnButtonCallback_BackHome()
            ModuleRefer.SlgModule:ReturnToHome(self.troopCtrl.ID)            
            self:CloseSelf()
        end

        local isTrusteeship = ModuleRefer.SlgModule.troopManager:CheckTroopTrusteeshipState(self.troopCtrl,-1)
        if isTrusteeship == CheckTroopTrusteeshipStateDefine.State.None then
            __OnButtonCallback_BackHome()
        elseif isTrusteeship == CheckTroopTrusteeshipStateDefine.State.InEscrowPreparing then
            __OnButtonCallback_BackHome()
        elseif CheckTroopTrusteeshipStateDefine.IsStateCanCancel(isTrusteeship) then
            ModuleRefer.SlgModule.troopManager:CancelTroopTrusteeshipAndGoOn(self.troopCtrl,-1,function(cancel)
                if cancel then
                    __OnButtonCallback_BackHome()
                end
            end,isTrusteeship == CheckTroopTrusteeshipStateDefine.State.InAssemblePreparing)
        else
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_check_hosting_stop_title"))
        end
    end   
end

function TroopCircleMenuMediator:OnButtonCallback_BackHomeImmediately()
    if self.troopCtrl then
        ModuleRefer.SlgModule:ReturnToHomeImmediately(self.troopCtrl.ID)
        self:CloseSelf()
    end
end

function TroopCircleMenuMediator:OnButtonCallback_BackHomeImmediatelyFailed()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("slg_oneclickbackwarn"))
end

function TroopCircleMenuMediator:OnButtonCallback_TroopDestInfo()
    if self.troopCtrl then
        ModuleRefer.SlgModule:LookAtTroopDest(self.troopCtrl.ID)
    end
end

function TroopCircleMenuMediator:OnButtonCallback_AttackTarget()
    if self.troopData then       
        ---@type HUDSelectTroopListData
        local param = {}
        param.entity = self.troopData
        param.isSE = false
        require("HUDTroopUtils").StartMarch(param)
    end
end

function TroopCircleMenuMediator:OnButtonCallback_AutoBattle()
    if self.troopData then
        local autoBattleState = not self.troopData.MapStates.StateWrapper2.AutoBattle
        ModuleRefer.SlgModule:SetupTroopAutoBattleState(self.troopData.ID,autoBattleState, function(cmd, isSuccess, rsp)
                if isSuccess then
                    if autoBattleState then
                        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('autofight_start'))
                    else
                        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('autofight_stopalert'))
                    end
                end
                self:StupButtons()
            end
        )
    end
end

function TroopCircleMenuMediator:OnButtonCallback_AutoBattleFailed()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("autbobattle_conflict"))
end

function TroopCircleMenuMediator:OnButtonCallback_MobileFortressDetail()
    ---@type wds.MobileFortress
    local mobileFortress = self.troopCtrl._data
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(mobileFortress.MapBasics.Position)

    ModuleRefer.MapBuildingTroopModule:FocusBuilding(tileX, tileZ, function()
        ---@type MapBuildingParameter
        local param = {}
        param.EntityID = mobileFortress.ID
        param.Owner = mobileFortress.Owner
        param.MapBasics = mobileFortress.MapBasics
        param.Army = nil
        param.StrengthenArmy = mobileFortress.Strengthen
        param.Construction = mobileFortress.Construction
        param.EntityTypeHash = mobileFortress.TypeHash
        param.IsStrengthen = true
        g_Game.UIManager:Open(require('UIMediatorNames').MapBuildingTroopConstructionUIMediator, param)
    end)

    self:CloseSelf()
end

function TroopCircleMenuMediator:OnButtonCallback_Strengthen()   
    --Send Troop     
    require("KingdomTouchInfoOperation").SendTroopToEntity(self.troopData,wrpc.MovePurpose.MovePurpose_Strengthen)
end

function TroopCircleMenuMediator:OnButtonCallback_Reinforce()   
    --Send Troop    
    require("KingdomTouchInfoOperation").SendTroopToEntity(self.troopData,wrpc.MovePurpose.MovePurpose_Reinforce)
end

function TroopCircleMenuMediator:OnButtonCallback_Remove()
    require("KingdomTouchInfoOperation").RemoveMapBuildingById(self.troopData.ID, DBEntityType.MobileFortress)
    ModuleRefer.KingdomPlacingModule:EndBehemoth()
    self:CloseSelf()
end

-- function TroopCircleMenuMediator:OnButtonCallback_TroopInfo()
-- end

function TroopCircleMenuMediator:OnButtonCallback_AddBattleSignal()
    ---@type UIBattleSignalPopupMediatorParameter
    local parameter = {}
    parameter.troopId = self.troopData.ID
    parameter.entity = self.troopData
    parameter.name = self.troopData.Owner.PlayerName.String
    parameter.abbr = self.troopData.Owner.AllianceAbbr.String
    g_Game.UIManager:Open(require('UIMediatorNames').UIBattleSignalPopupMediator, parameter)    
end

function TroopCircleMenuMediator:OnButtonCallback_RemoveBattleSignal()
    local id,_ = ModuleRefer.SlgModule:GetSignalOnEntity(self.troopData.ID)
    if id then
        ModuleRefer.SlgModule:RemoveSignal(id)
    end    
    self:CloseSelf()
end


return TroopCircleMenuMediator
