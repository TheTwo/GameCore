--- scene:scene_world_popup_conquer_succeed

local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local EventConst = require("EventConst")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceVillageOccupationNoticeMediatorParameter
---@field payload wrpc.VillageReportParam
---@field endQueueTriggerGuide number

---@class AllianceVillageOccupationNoticeMediator:BaseUIMediator
---@field new fun():AllianceVillageOccupationNoticeMediator
---@field super BaseUIMediator
local AllianceVillageOccupationNoticeMediator = class('AllianceVillageOccupationNoticeMediator', BaseUIMediator)

function AllianceVillageOccupationNoticeMediator:ctor()
    AllianceVillageOccupationNoticeMediator.super.ctor(self)
    self._closeTriggerGuide = nil
end

function AllianceVillageOccupationNoticeMediator:OnCreate(param)
    self._p_img_building = self:Image("p_img_building")
    self._p_text_title = self:Text("p_text_title")
    self._p_text_detail = self:Text("p_text_detail")
    self._p_text_title_1 = self:Text("p_text_title_1", "village_info_Top_three_kill")
    self._p_text_title_2 = self:Text("p_text_title_2", "village_info_top_three_destroy")
    self._p_text_hint = self:Text("p_text_hint", "village_info_Click_to_close")
    self._p_group_first = self:GameObject("p_group_first")
    self._p_text_first = self:Text("p_text_first", "village_info_First_occupation")
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))
    self._p_group_rank = self:GameObject("p_group_rank")
    
    ---@type AllianceVillageOccupationNoticePlayerCell[]
    self._killPlayers = {}
    for i = 1, 3 do
        self._killPlayers[i] = self:LuaObject(("p_player_kill_%02d"):format(i))
    end
    ---@type AllianceVillageOccupationNoticePlayerCell[]
    self._damagePlayers = {}
    for i = 1, 3 do
        self._damagePlayers[i] = self:LuaObject(("p_player_battle_%02d"):format(i))
    end
end

---@param param wrpc.VillageReportParam | AllianceVillageOccupationNoticeMediatorParameter
function AllianceVillageOccupationNoticeMediator:OnOpened(param)
    self._closeTriggerGuide = nil
    if param then
        if param.endQueueTriggerGuide then
            self._closeTriggerGuide = param.endQueueTriggerGuide
        end
        if param.payload then
            param = param.payload
        end
        local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
        if allianceData then
            self:DoOpened(param, allianceData.AllianceBasicInfo)
            return
        end
    end
    self:CloseSelf()
end

function AllianceVillageOccupationNoticeMediator:OnClose(data)
    if self._closeTriggerGuide then
        ModuleRefer.GuideModule:CallGuide(self._closeTriggerGuide)
        self._closeTriggerGuide = nil
    end
end

---@param param wrpc.VillageReportParam
---@param alliance wds.AllianceBasicInfo
function AllianceVillageOccupationNoticeMediator:DoOpened(param, alliance)
    self._p_group_first:SetVisible(param.IsFirst)
    
    local territory = ConfigRefer.Territory:Find(param.TerritoryId)
    local village= ConfigRefer.FixedMapBuilding:Find(territory:VillageId())
    local pos = territory:VillagePosition()
    self._p_text_detail.text = I18N.GetWithParams("village_Marquee_occupied", ("%s"):format(alliance.Abbr), alliance.Name, village:Level(), I18N.Get(village:Name()), pos:X(), pos:Y())
    g_Game.SpriteManager:LoadSprite(village:BigImage(), self._p_img_building)

    if param.Type == wrpc.VillageOccupyType.VillageOccupyType_Declare then
        self._p_text_title.text = I18N.Get("village_info_Successful")
        self._p_group_rank:SetVisible(true)
        if #param.SoldierRank == 2 then
            self._killPlayers[1]:SetVisible(false)
            self._killPlayers[2]:SetVisible(true)
            self._killPlayers[2]:FeedData({rank = 1, player = param.SoldierRank[1]})
            self._killPlayers[3]:SetVisible(true)
            self._killPlayers[3]:FeedData({rank = 2, player = param.SoldierRank[2]})
        else
            for i = 1, 3 do
                local p = param.SoldierRank[i]
                if p then
                    self._killPlayers[i]:SetVisible(true)
                    self._killPlayers[i]:FeedData({rank = i, player = p})
                else
                    self._killPlayers[i]:SetVisible(false)
                end
            end
        end
        if #param.ConstructRank == 2 then
            self._damagePlayers[1]:SetVisible(false)
            self._damagePlayers[2]:SetVisible(true)
            self._damagePlayers[2]:FeedData({rank = 1, player = param.ConstructRank[1]})
            self._damagePlayers[3]:SetVisible(true)
            self._damagePlayers[3]:FeedData({rank = 2, player = param.ConstructRank[2]})
        else
            for i = 1, 3 do
                local p = param.ConstructRank[i]
                if p then
                    self._damagePlayers[i]:SetVisible(true)
                    self._damagePlayers[i]:FeedData({rank = i, player = p})
                else
                    self._damagePlayers[i]:SetVisible(false)
                end
            end
        end
    else
        self._p_text_title.text = I18N.Get("village_outpost_info_successfully_constructed")
        self._p_group_rank:SetVisible(false)
    end
end

function AllianceVillageOccupationNoticeMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
end

function AllianceVillageOccupationNoticeMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
end

function AllianceVillageOccupationNoticeMediator:OnLeaveAlliance(allianceId)
    self:CloseSelf()
end

return AllianceVillageOccupationNoticeMediator