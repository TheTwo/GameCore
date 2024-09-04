local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require("ConfigRefer")
local EventConst = require("EventConst")
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local EquipDrawingCell = class('EquipDrawingCell',BaseTableViewProCell)
local EQUIP_ICON = {ArtResourceUIConsts.sp_hero_icon_equipment_weapon, ArtResourceUIConsts.sp_hero_icon_equipment_head,
        ArtResourceUIConsts.sp_hero_icon_equipment_clothes, ArtResourceUIConsts.sp_hero_icon_equipment_belt, ArtResourceUIConsts.sp_hero_icon_equipment_shoes}

function EquipDrawingCell:OnCreate(param)
    self.compChildItemStandardS = self:LuaBaseComponent('child_item_standard_s')
end

function EquipDrawingCell:OnFeedData(data)
    if not data then
        return
    end
    self.compChildItemStandardS.Lua:ChangeSelectStatus(false)
    self.data = data
    local itemData = {}
    itemData.configCell = data.configCell
    itemData.count = data.count
    itemData.onClick = Delegate.GetOrCreate(self, self.OnIconClick)
    self.compChildItemStandardS:FeedData(itemData)
    local drawingId = data.configCell:DrawingId()
    local drawingCfg = ConfigRefer.Drawing:Find(drawingId)
    local fixQuality = drawingCfg:FixQuality()
    local fixEquipType = drawingCfg:FixEquipType()
    -- local fixSuitId = drawingCfg:FixSuitId()
    -- if fixSuitId > 0 then
    --     self.compChildItemStandardS.Lua:ChangeSuitIcon(ConfigRefer.Suit:Find(fixSuitId):Icon())
    -- end
    self.compChildItemStandardS.Lua:ChangeQuality(fixQuality)
    if fixEquipType > 0 then
        self.compChildItemStandardS.Lua:ChangeIcon(EQUIP_ICON[fixEquipType])
    end
end

function EquipDrawingCell:Select()
    self.compChildItemStandardS.Lua:ChangeSelectStatus(true)
end

function EquipDrawingCell:UnSelect()
    self.compChildItemStandardS.Lua:ChangeSelectStatus(false)
end

function EquipDrawingCell:OnIconClick()
    local HeroEquipForgeRoomUIMediator = g_Game.UIManager:FindUIMediatorByName(require( 'UIMediatorNames').HeroEquipForgeRoomUIMediator)
    HeroEquipForgeRoomUIMediator.tableviewproTableDrawing:SetToggleSelect(self.data)
    g_Game.EventManager:TriggerEvent(EventConst.HERO_ONCLICK_DRAWING, self.data)
    -- local param = {}
    -- param.clickTransform = self.compChildItemStandardS.gameObject.transform
    -- param.drawingId = self.data.configCell:DrawingId()
    -- param.itemType = CommonItemDetailsDefine.ITEM_TYPE.DRAWING
    -- g_Game.UIManager:Open('PopupItemDetailsUIMediator', param)
end

return EquipDrawingCell
