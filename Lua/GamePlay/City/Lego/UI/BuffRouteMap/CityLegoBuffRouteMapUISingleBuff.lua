local BaseUIComponent = require ('BaseUIComponent')
local CityLegoI18N = require('CityLegoI18N')
local ConfigRefer = require('ConfigRefer')
local Utils = require('Utils')
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

local I18N = require("I18N")
local UIHelper = require("UIHelper")

---@class CityLegoBuffRouteMapUISingleBuff:BaseUIComponent
local CityLegoBuffRouteMapUISingleBuff = class('CityLegoBuffRouteMapUISingleBuff', BaseUIComponent)

---@class CityLegoBuffRouteMapUISingleBuffData
---@field cfg RoomTagBuffUIRowConfigCell
---@field legoBuilding CityLegoBuilding
---@field level number

function CityLegoBuffRouteMapUISingleBuff:OnCreate()
    --- 左侧连线
    self._p_line_l = self:GameObject("p_line_l")
    self._p_line_l_lock = self:GameObject("p_line_l_lock")
    self._p_line_l_unlock = self:GameObject("p_line_l_unlock")

    self._p_content_m = self:GameObject("p_content_m")

    --- 正在使用的Buff
    self._p_top = self:GameObject("p_top")
    self._p_using = self:GameObject("p_using")
    self._p_toggle_choose = self:Toggle("p_toggle_choose", Delegate.GetOrCreate(self, self.OnToggleChoose))
    self._p_text_using = self:Text("p_text_using", CityLegoI18N.UI_HintBuffRouteCurrentUsing)

    --- buff详情信息
    self._p_middle = self:GameObject("p_middle")
    --- buff图标
    self._p_icon_room = self:Image("p_icon_room")
    --- buff名字
    self._p_text_room_name = self:Text("p_text_room_name")
    --- buff公式根节点
    self._p_formula_content = self:Transform("p_formula_content")
    --- buff公式元素模板根节点
    self._p_template_formula_element = self:Transform("p_template_formula_element")
    --- buff公式元素:家具
    self._p_item_furniture = self:LuaBaseComponent("p_item_furniture")
    --- buff公式元素:加号
    self._icon_add = self:GameObject("icon_add")

    self._p_group_buff = self:Transform("p_group_buff")
    self._p_item_buff = self:LuaBaseComponent("p_item_buff")
    self._buff_attr_pool = LuaReusedComponentPool.new(self._p_item_buff, self._p_group_buff)

    self._p_line_r = self:GameObject("p_line_r")
    self._p_line_r_lock = self:GameObject("p_line_r_lock")
    self._p_line_r_unlock = self:GameObject("p_line_r_unlock")

    self._p_lock = self:GameObject("p_lock")
end

---@param data CityLegoBuffRouteMapUISingleBuffData
function CityLegoBuffRouteMapUISingleBuff:OnFeedData(data)
    self:RemoveListener()
    self:AddEventListener()

    self.data = data

    self._p_line_l:SetActive(true)
    self._p_line_r:SetActive(true)

    self._p_line_l_lock:SetActive(false)
    self._p_line_l_unlock:SetActive(data.cfg:HasPrev())

    self._p_line_r_lock:SetActive(false)
    self._p_line_r_unlock:SetActive(data.cfg:HasNext())

    local usingBuffMap = {}
    for i, v in ipairs(data.legoBuilding.payload.BuffList) do
        usingBuffMap[v] = true
    end
    self._p_using:SetActive(usingBuffMap[data.cfg:BuffCfgId()] == true)

    local buffCfg = ConfigRefer.RoomTagBuff:Find(data.cfg:BuffCfgId())
    if buffCfg then
        local levelMeet = self.data.level <= self.data.legoBuilding.roomLevel
        local tagMeet = true

        g_Game.SpriteManager:LoadSprite(buffCfg:BuffIcon(), self._p_icon_room)
        self._p_text_room_name.text = I18N.Get(buffCfg:BuffName())

        for i = self._p_formula_content.childCount - 1, 0, -1 do
            local child = self._p_formula_content:GetChild(i)
            if Utils.IsNotNull(child) then
                UIHelper.DeleteUIGameObject(child.gameObject)
            end
        end

        local providerMap = data.legoBuilding.buffCalculator:GetTagProviderMap(buffCfg)
        for i = 1, buffCfg:RoomTagListLength() do
            local roomTag = buffCfg:RoomTagList(i)
            local tagCfg = ConfigRefer.RoomTag:Find(roomTag)
            ---@type CityLegoBuffRouteMapUIFormulaElementData
            local data = {cfg = tagCfg, legoBuilding = data.legoBuilding, provider = providerMap[i]}
            local comp = UIHelper.DuplicateUIComponent(self._p_item_furniture, self._p_formula_content)
            comp:FeedData(data)
            tagMeet = tagMeet and providerMap[i] ~= nil

            if i < buffCfg:RoomTagListLength() then
                UIHelper.DuplicateUIGameObject(self._icon_add, self._p_formula_content)
            end
        end

        local buffValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(buffCfg:GolbalAttr())
        if buffValues then
            for i, v in ipairs(buffValues) do
                local elementCfg = ConfigRefer.AttrElement:Find(v.type)
                local desc = I18N.Get(elementCfg:Name())
                local value = ModuleRefer.AttrModule:GetAttrValueShowTextByTypeWithSign(v.type, v.originValue)
                local item = self._buff_attr_pool:GetItem()
                item:FeedData({desc = desc, value = value})
            end
        end

        for i = 1, buffCfg:BattleAttrGroupsLength() do
            local battleGroup = buffCfg:BattleAttrGroups(i)
            local battleValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(battleGroup:Attr())
            if battleValues then
                if battleGroup:TextLength() == 0 then
                    for _, v in ipairs(battleValues) do
                        local elementCfg = ConfigRefer.AttrElement:Find(v.type)
                        local desc = I18N.Get(elementCfg:Name())
                        local value = ModuleRefer.AttrModule:GetAttrValueShowTextByTypeWithSign(v.type, v.originValue)
                        local item = self._buff_attr_pool:GetItem()
                        item:FeedData({desc = desc, value = value})
                    end
                else
                    for _, v in ipairs(battleValues) do
                        for j = 1, battleGroup:TextLength() do
                            local prefix = battleGroup:Text(j)
                            local elementCfg = ConfigRefer.AttrElement:Find(v.type)
                            local desc = I18N.GetWithParams(prefix, I18N.Get(elementCfg:Name()))
                            local value = ModuleRefer.AttrModule:GetAttrValueShowTextByTypeWithSign(v.type, v.originValue)
                            local item = self._buff_attr_pool:GetItem()
                            item:FeedData({desc = desc, value = value})
                        end
                    end
                end
            end
        end

        self.canUse = levelMeet and tagMeet
        self._p_lock:SetActive(not self.canUse)
        self._p_toggle_choose:SetVisible(self.canUse)
        self._p_toggle_choose:SetIsOnWithoutNotify(usingBuffMap[data.cfg:BuffCfgId()] == true)
    else
        self.canUse = false
        self._p_lock:SetActive(false)
        self._p_toggle_choose:SetVisible(false)
    end
end

function CityLegoBuffRouteMapUISingleBuff:OnClose()
    self:RemoveListener()
end

function CityLegoBuffRouteMapUISingleBuff:AddEventListener()
    g_Game.EventManager:AddListener(EventConst.UI_CITY_LEGO_BUFF_UPDATE_SELECTED, Delegate.GetOrCreate(self, self.OnUpdateSelected))
end

function CityLegoBuffRouteMapUISingleBuff:RemoveListener()
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_LEGO_BUFF_UPDATE_SELECTED, Delegate.GetOrCreate(self, self.OnUpdateSelected))
end

function CityLegoBuffRouteMapUISingleBuff:OnUpdateSelected()
    if not self.data then return end

    local usingBuffMap = {}
    for i, v in ipairs(self.data.legoBuilding.payload.BuffList) do
        usingBuffMap[v] = true
    end
    local isUsing = usingBuffMap[self.data.cfg:BuffCfgId()] == true
    self._p_using:SetActive(isUsing)
    self._p_toggle_choose:SetIsOnWithoutNotify(isUsing)
end

function CityLegoBuffRouteMapUISingleBuff:OnToggleChoose(value)
    self._p_toggle_choose:SetIsOnWithoutNotify(not value)
    if not value then return end

    self.data.legoBuilding:RequestSelectBuff({self.data.cfg:BuffCfgId()})
end

return CityLegoBuffRouteMapUISingleBuff