local BaseUIComponent = require ('BaseUIComponent')
local LuaReusedComponentPool = require('LuaReusedComponentPool')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local CityLegoBuffDifferData = require("CityLegoBuffDifferData")
local ConfigRefer = require("ConfigRefer")

local I18N = require("I18N")

---@class CityLegoBuildingUIPage_Details:BaseUIComponent
local CityLegoBuildingUIPage_Details = class('CityLegoBuildingUIPage_Details', BaseUIComponent)

function CityLegoBuildingUIPage_Details:OnCreate()
    self._p_text_furniture_name = self:Text("p_text_furniture_name")
    self._p_text_description = self:Text("p_text_description")

    self._p_property_vertical = self:Transform("p_property_vertical")
    self._p_property = self:LuaBaseComponent("p_property")
    self._pool_property = LuaReusedComponentPool.new(self._p_property, self._p_property_vertical)

    self._p_score = self:LuaObject("p_score")

    self._p_img_special = self:Image("p_img_special")
    self._p_btn = self:GameObject("p_btn")
    self._child_comp_btn_b_l = self:Button("child_comp_btn_b_l", Delegate.GetOrCreate(self, self.OnClickSpecial))
    self._p_text_goto = self:Text("p_text_goto")
end

---@param param CityFurnitureDetailsUIParameter
function CityLegoBuildingUIPage_Details:OnFeedData(param)
    self.param = param
    self.cellTile = self.param.cellTile
    self.city = self.cellTile:GetCity()

    self._p_text_furniture_name.text = self.cellTile:GetName()
    self._p_text_description.text = self.cellTile:GetDescription()

    local furniture = self.cellTile:GetCell()
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(furniture.furType)
    if furniture.furnitureCell:AddScore() > 0 and typCfg:HideAddScore() == false then
        self._p_score:SetVisible(true)
        self._p_score:FeedData(furniture)
    else
        self._p_score:SetVisible(false)
    end

    self:UpdatePropertyCurrent()
    self:UpdateSpecialData()
end

function CityLegoBuildingUIPage_Details:UpdatePropertyCurrent()
    if self._p_property == nil then return end
    self._pool_property:HideAll()
    self.lvCell = self.param.furLvCfg
    local propertyList = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(self.lvCell:Attr()) or {}
    ---@type CityLegoBuffDifferData[]
    local dataList = {}
    if propertyList then
        for i, v in ipairs(propertyList) do
            local data = CityLegoBuffDifferData.new(v.type, v.originValue)
            table.insert(dataList, data)
        end
    end
    
    for i = 1, self.lvCell:BattleAttrGroupsLength() do
        local battleGroup = self.lvCell:BattleAttrGroups(i)
        local battleValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(battleGroup:Attr())
        if battleValues then
            for _, v in ipairs(battleValues) do
                if battleGroup:TextLength() == 0 then
                    local data = CityLegoBuffDifferData.new(v.type, v.originValue)
                    table.insert(dataList, data)
                else
                    for j = 1, battleGroup:TextLength() do
                        local prefix = battleGroup:Text(j)
                        local data = CityLegoBuffDifferData.new(v.type, v.originValue, nil, prefix)
                        table.insert(dataList, data)
                    end
                end
            end
        end
    end

    for i, data in ipairs(dataList) do
        if data.value == 0 then goto continue end
        local item = self._pool_property:GetItem()
        item:FeedData(data)
        ::continue::
    end
end

function CityLegoBuildingUIPage_Details:UpdateSpecialData()
    if self.param.specialData == nil then
        self._p_img_special:SetVisible(false)
        self._p_btn:SetVisible(false)
        return
    end

    self._p_img_special:SetVisible(true)
    self._p_btn:SetVisible(true)
    self._p_text_goto.text = I18N.Get(self.param.specialData.buttonI18N)
    g_Game.SpriteManager:LoadSprite(self.param.specialData.image, self._p_img_special)
end

function CityLegoBuildingUIPage_Details:OnClickSpecial()
    if not self.param.specialData then return end
    if not self.param.specialData.onClick then return end
    self.param.specialData.onClick()
end

return CityLegoBuildingUIPage_Details