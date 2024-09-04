---Scene Name : scene_city_room_popup_formula
local BaseUIMediator = require ('BaseUIMediator')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityLegoI18N = require("CityLegoI18N")
local UIHelper = require("UIHelper")
local UIMediatorNames = require("UIMediatorNames")

---@class CityLegoBuffRouteMapUIMediator:BaseUIMediator
local CityLegoBuffRouteMapUIMediator = class('CityLegoBuffRouteMapUIMediator', BaseUIMediator)
local CityLegoBuffSelectUIParameter = require("CityLegoBuffSelectUIParameter")
local CastleSetRoomBuffParameter = require("CastleSetRoomBuffParameter")

function CityLegoBuffRouteMapUIMediator:OnCreate()
    self._p_group_type = self:GameObject("p_group_type")
    self._p_text_type = self:Text("p_text_type", CityLegoI18N.UI_TitleRoomType)
    ---@see CityLegoBuffRouteMapUIRoomTypeCell
    self._p_table_type = self:TableViewPro("p_table_type")

    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))

    self._p_viewport = self:BindComponent("p_viewport", typeof(CS.UnityEngine.UI.ScrollRect))
    self._p_content = self:Transform("p_content")

    self._p_containers_lv1_pool = self:Transform("p_containers_lv1_pool")
    self._p_container_lv1 = self:LuaBaseComponent("p_container_lv1")

    self._p_containers_empty_pool = self:Transform("p_containers_empty_pool")
    self._p_container_empty = self:LuaBaseComponent("p_container_empty")

    self._p_containers_locked_pool = self:Transform("p_containers_locked_pool")
    self._p_group_lock = self:LuaBaseComponent("p_group_lock")

    self._p_btn_set = self:Button("p_btn_set", Delegate.GetOrCreate(self, self.OnClickSelect))
    self._p_text_set = self:Text("p_text_set", CityLegoI18N.UI_HintBuffSelect)

    self._p_btn_back = self:Button("p_btn_back", Delegate.GetOrCreate(self, self.CloseSelf))
    self._p_btn_back:SetVisible(false)
end

---@param param CityLegoBuffRouteMapUIParameter
function CityLegoBuffRouteMapUIMediator:OnOpened(param)
    self.param = param
    self._p_btn_set:SetVisible(false)
    
    if param.legoBuilding == nil then
        self:InitRoomTypeTable()
    else
        self:InitBuffRouteMapTable()
    end

    g_Game.EventManager:AddListener(EventConst.UI_CITY_LEGO_BUFF_ROUTE_MAP_SELECT_ROOM_TYPE, Delegate.GetOrCreate(self, self.CloseSelf))
    g_Game.ServiceManager:AddResponseCallback(CastleSetRoomBuffParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnBuffChanged))
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateTick))
    self.checkTickCount = 100
end

function CityLegoBuffRouteMapUIMediator:OnClose(param)
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateTick))
    g_Game.ServiceManager:RemoveResponseCallback(CastleSetRoomBuffParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnBuffChanged))
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_LEGO_BUFF_ROUTE_MAP_SELECT_ROOM_TYPE, Delegate.GetOrCreate(self, self.CloseSelf))
end

function CityLegoBuffRouteMapUIMediator:InitRoomTypeTable()
    self._p_table_type:Clear()

    if not self.param.city.legoManager then return end
    if not self.param.city.legoManager.legoBuildings then return end

    for _, legoBuilding in pairs(self.param.city.legoManager.legoBuildings) do
        if legoBuilding:IsUnlocked() and not legoBuilding:IsFogMask() then
            self._p_table_type:AppendData(legoBuilding)
        end
    end

    self._p_viewport:SetVisible(false)
    self._p_group_type:SetActive(true)
end

function CityLegoBuffRouteMapUIMediator:InitBuffRouteMapTable()
    local roomCfg = ConfigRefer.Room:Find(self.param.legoBuilding.roomCfgId)
    if roomCfg == nil then return end

    local level = self.param.legoBuilding.roomLevel
    ---@type RoomLevelInfoConfigCell
    local currentLevelCfg = nil
    ---@type RoomLevelInfoConfigCell[]
    local lvCfgArray = {}
    ---@type RoomTagBuffUISpaceColumnConfigCell[]
    local spaceCfgArray = {}
    for i = 1, roomCfg:LevelInfosLength() do
        local levelCfgId = roomCfg:LevelInfos(i)
        local levelCfg = ConfigRefer.RoomLevelInfo:Find(levelCfgId)
        if levelCfg then
            if level >= levelCfg:Level() then
                if currentLevelCfg == nil then
                    currentLevelCfg = levelCfg
                elseif currentLevelCfg:Level() < levelCfg:Level() then
                    currentLevelCfg = levelCfg
                end
            end
            
            local levelUiCfg = ConfigRefer.RoomTagBuffUILevel:Find(levelCfg:UILevel())
            local index = 0
            if levelUiCfg then
                table.insert(lvCfgArray, levelCfg)
                index = #lvCfgArray - 1
            end

            local spaceUiCfg = ConfigRefer.RoomTagBuffUISpaceColumn:Find(levelCfg:UISpaceColumns())
            if spaceUiCfg then
                spaceCfgArray[index] = spaceUiCfg
            end
        end
    end

    if #lvCfgArray == 0 then return end

    if currentLevelCfg == nil then
        currentLevelCfg = lvCfgArray[1]
    end

    local showMaxCount = math.min(#lvCfgArray, currentLevelCfg:ShowUIColumnsCount())
    for i = 1, #lvCfgArray do
        if i <= showMaxCount then
            local v = lvCfgArray[i]
            ---@type CityLegoBuffRouteMapUILevelGroupData
            local data = {roomLvCfg = v, legoBuilding = self.param.legoBuilding}
            local comp = UIHelper.DuplicateUIComponent(self._p_container_lv1, self._p_content)
            comp:FeedData(data)

            if i < #lvCfgArray then
                local spaceCfg = spaceCfgArray[i]
                local space = UIHelper.DuplicateUIComponent(self._p_container_empty, self._p_content)
                ---@type CityLegoBuffRouteMapUISpaceData
                local data = {maxLength = spaceCfg ~= nil and spaceCfg:RowsLength() or 0, cfg = spaceCfg}
                space:FeedData(data)
            end
        else
            local v = lvCfgArray[i]
            local data = {roomLvCfg = v}
            local comp = UIHelper.DuplicateUIComponent(self._p_group_lock, self._p_content)
            comp:FeedData(data)
        end
    end

    self._p_viewport:SetVisible(true)
    self._p_group_type:SetActive(false)
end

function CityLegoBuffRouteMapUIMediator:OnLateTick()
    self.checkTickCount = self.checkTickCount - 1
    self._p_viewport.horizontal = self._p_viewport.transform.rect.width < self._p_content.rect.width
    self._p_viewport.vertical = self._p_viewport.transform.rect.height < self._p_content.rect.height

    if self.checkTickCount <= 0 then
        g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateTick))
    end
end

function CityLegoBuffRouteMapUIMediator:OnClickSelect()
    local param = CityLegoBuffSelectUIParameter.new(self.param.legoBuilding)
    g_Game.UIManager:Open(UIMediatorNames.CityLegoBuffSelectUIMediator, param)
end

function CityLegoBuffRouteMapUIMediator:OnBuffChanged(isSuccess, reply, rpc)
    if not isSuccess then return end
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_LEGO_BUFF_UPDATE_SELECTED)
end

return CityLegoBuffRouteMapUIMediator