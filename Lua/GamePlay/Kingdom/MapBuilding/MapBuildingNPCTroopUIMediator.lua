---scene_world_popup_defense_troop
local BaseUIMediator = require("BaseUIMediator")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local KingdomMapUtils = require("KingdomMapUtils")
local DBEntityPath = require("DBEntityPath")
local EventConst = require("EventConst")
local TileHighLightMap = require("TileHighLightMap")

---@class MapBuildingNPCTroopUIMediator : BaseUIMediator
---@field tile MapRetrieveResult
---@field army wds.Army
local MapBuildingNPCTroopUIMediator = class("MapBuildingNPCTroopUIMediator", BaseUIMediator)

function MapBuildingNPCTroopUIMediator:OnCreate(param)
    self:Text("p_text_title", "village_info_Garrison")
    self:Text('p_text_troop', "village_info_Garrison")
    self:Text('p_text_troop_progress', "village_info_Garrison")

    self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnCloseClicked))

    self.p_normal = self:GameObject("p_normal")
    self.p_empty = self:GameObject("p_empty")
    self.p_text_num = self:Text("p_text_num")
    self.p_text_empty = self:Text("p_text_empty")
    self.p_progress_slider = self:Slider("p_progress_slider")
    self.p_table_troop = self:TableViewPro("p_table_troop")
    self.p_icon_buff = self:Image("p_icon_buff")
    self:Button("p_icon_buff", Delegate.GetOrCreate(self, self.OnClickBuffIcon))
    self.p_text_buff_num = self:Text("p_text_buff_num")
end

function MapBuildingNPCTroopUIMediator:OnShow(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Village.Army.MsgPath, Delegate.GetOrCreate(self, self.OnArmyChanged))
end

function MapBuildingNPCTroopUIMediator:OnHide(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Village.Army.MsgPath, Delegate.GetOrCreate(self, self.OnArmyChanged))

    --ModuleRefer.MapBuildingTroopModule:ResetCamera()
    TileHighLightMap.HideTileHighlight(self.tile)
end

---@param param MapRetrieveResult
function MapBuildingNPCTroopUIMediator:OnOpened(param)
    self.__creepBuffCount = nil
    self.__creepBuffValue = nil
    self.tile = param
    self.army = self.tile.entity.Army
    local hp, hpMax = ModuleRefer.MapBuildingTroopModule:GetNpcTroopHP(self.army)
    self.p_progress_slider.value = hp / hpMax
    self.p_text_num.text = string.format("%s/%s", hp, hpMax)
    if hp > 0 and hpMax > 0 then
        self.p_normal:SetVisible(true)
        self.p_empty:SetVisible(false)
        self:RefreshTroopList()
    else
        self.p_normal:SetVisible(false)
        self.p_empty:SetVisible(true)
        self.p_text_empty.text = I18N.Get("village_info_all_dead")
    end
    local creepBuff,buffIcon,buffValue = ModuleRefer.MapCreepModule.GetCreepSpreadBuffCount(self.tile and self.tile.entity and self.tile.entity.CreepSpread)
    if creepBuff and creepBuff > 0 then
        self.__creepBuffCount = creepBuff
        self.__creepBuffValue = buffValue
        self.p_icon_buff:SetVisible(true)
        g_Game.SpriteManager:LoadSpriteAsync(buffIcon, self.p_icon_buff)
        if creepBuff > 1 then
            self.p_text_buff_num:SetVisible(true)
            self.p_text_buff_num.text = ("x%d"):format(creepBuff)
        else
            self.p_text_buff_num:SetVisible(false)
        end
    else
        self.p_icon_buff:SetVisible(false)
    end
end

function MapBuildingNPCTroopUIMediator:OnCloseClicked()
    self:CloseSelf()
end

function MapBuildingNPCTroopUIMediator:OnClickBuffIcon()
    if not self.__creepBuffCount or self.__creepBuffCount <= 0 then return end
    local content = I18N.GetWithParams("duzhu_qianghua", tostring(self.__creepBuffCount)) .. self.__creepBuffValue
    ModuleRefer.ToastModule:SimpleShowTextToastTip(content, self.p_icon_buff.transform:GetComponent(typeof(CS.UnityEngine.RectTransform)))
end

---@param army wds.Army
function MapBuildingNPCTroopUIMediator:OnArmyChanged(army)
    if self.army and army.ID ~= self.army.ID then
        return
    end
    self:RefreshTroopList()
end

function MapBuildingNPCTroopUIMediator:RefreshTroopList()
    self.p_table_troop:Clear()
    for _, armyMemberInfo in pairs(self.army.DummyTroopIDs) do
        if armyMemberInfo.Hp > 0 then
            self.p_table_troop:AppendDataEx(armyMemberInfo, 0, 0, 0)
        end
    end
    self.p_table_troop:RefreshAllShownItem()

    TileHighLightMap.ShowTileHighlight(self.tile)
end

return MapBuildingNPCTroopUIMediator

