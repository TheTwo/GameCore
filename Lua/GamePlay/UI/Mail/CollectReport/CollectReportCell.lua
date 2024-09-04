local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local UIHelper = require("UIHelper")
local I18N = require("I18N")

---@class CollectReportCell : BaseUIComponent
---@field data wds.ResourceGatherInfo
---@field itemIcons BaseItemIcon[]
local CollectReportCell = class("CollectReportCell", BaseUIComponent)

function CollectReportCell:OnCreate(param)
    self.p_img_field = self:Image("p_img_territory")
    self.p_text_lv = self:Text("p_text_lv")
    self.p_text_name = self:Text("p_text_name")
    self.p_text_position_collect = self:Text("p_text_position_collect")
    self.p_btn_position = self:Button("p_btn_position", Delegate.GetOrCreate(self, self.OnCoordinateClicked))
    
    ---@type HeroInfoItemSmallComponent
    self.child_card_hero_s_ex = self:LuaObject("child_card_hero_s_ex")

    self.p_layout_resources = self:Transform("p_layout_resources")
    self.p_item_resource = self:LuaBaseComponent("p_item_resource")
    
    self.itemIcons = {}
end

---@param data wds.ResourceGatherInfo
function CollectReportCell:OnFeedData(data)
    self.data = data
    
    local resourceConfig = ConfigRefer.FixedMapBuilding:Find(data.ResourceFieldTid)
    if not resourceConfig then
        return
    end
    
    g_Game.SpriteManager:LoadSpriteAsync(resourceConfig:BubbleImage(), self.p_img_field)

    self.p_text_lv.text = ("Lv.%s"):format(resourceConfig:Level())
    self.p_text_name.text = I18N.Get(resourceConfig:Name())
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(data.Position)
    self.p_text_position_collect.text = KingdomMapUtils.CoordToXYString(tileX, tileZ)

    local heroCfg = ConfigRefer.Heroes:Find(data.TroopCaptainHeroTid)
    local heroResCfg =ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
    ---@type HeroInfoData
    local heroInfoData = {}
    heroInfoData.heroData = {}
    heroInfoData.heroData.id = data.TroopCaptainHeroTid
    heroInfoData.heroData.configCell = heroCfg
    heroInfoData.heroData.resCell = heroResCfg
    self.child_card_hero_s_ex:FeedData(heroInfoData)

    ---@type ItemConfigCell[]
    local itemConfigs = {}
    for itemID, _ in pairs(data.Items) do
        local itemConfig = ConfigRefer.Item:Find(itemID)
        table.insert(itemConfigs, itemConfig)
    end
    table.sort(itemConfigs, function(a, b) 
        return a:Sort() < b:Sort()
    end)

    table.clear(self.itemIcons)
    for i = 0, self.p_layout_resources.childCount - 1 do
        local child = self.p_layout_resources:GetChild(i)
        local component = child:GetComponent(typeof(CS.DragonReborn.UI.LuaBaseComponent))
        component:SetVisible(true)
        table.insert(self.itemIcons, component.Lua)
    end

    local configCount = table.nums(itemConfigs)
    local iconCount = table.nums(self.itemIcons)
    local index = 1
    while index <= configCount do
        local config = itemConfigs[index]
        ---@type BaseItemIcon
        local itemIcon
        if index > iconCount then
            itemIcon = UIHelper.DuplicateUIComponent(self.p_item_resource).Lua
            table.insert(self.itemIcons, itemIcon)
        else
            itemIcon = self.itemIcons[index]
        end

        ---@type ItemIconData
        local iconData = {}
        iconData.configCell = config
        iconData.count = data.Items[config:Id()]
        itemIcon:FeedData(iconData)
        
        index = index + 1
    end
    while index <= iconCount do
        ---@type BaseItemIcon
        local itemIcon = self.itemIcons[index]
        itemIcon:SetVisible(false)
        index = index + 1
    end
end

function CollectReportCell:OnCoordinateClicked()
    if not self.data then
        return
    end

    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Dialog)
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Popup)
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(self.data.Position)
    KingdomMapUtils.GotoCoordinate(tileX, tileZ)
end

return CollectReportCell