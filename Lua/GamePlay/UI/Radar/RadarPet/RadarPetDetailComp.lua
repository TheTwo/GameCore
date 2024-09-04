local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ManualUIConst = require('ManualUIConst')
local LuaReusedComponentPool = require('LuaReusedComponentPool')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class RadarPetDetailComp : BaseTableViewProCell
---@field data HeroConfigCache
local RadarPetDetailComp = class('RadarPetDetailComp', BaseTableViewProCell)

function RadarPetDetailComp:ctor()
end

function RadarPetDetailComp:OnCreate()
    ---@type UIHeroAssociateIconComponent
    self.child_icon_style = self:LuaObject('child_icon_style')

    ---@type UIPetWorkTypeComp
    self.p_type = self:LuaBaseComponent("p_type")
    self.p_layout_type = self:Transform("p_layout_type")
    self.pool_type_info_main = LuaReusedComponentPool.new(self.p_type, self.p_layout_type)
    self.p_text_style = self:Text('p_text_style')
    self.transform = self:Transform('')
end

function RadarPetDetailComp:OnFeedData(param)
    local cfgId = ModuleRefer.RadarModule:GetRadarTraceSelectPet()
    local petCfg = ModuleRefer.PetModule:GetPetCfg(cfgId)
    self.p_text_style.text = I18N.Get(petCfg:Name())
    -- 工种
    self.pool_type_info_main:HideAll()
    for i = 1, petCfg:PetWorksLength() do
        local petWorkCfg = ConfigRefer.PetWork:Find(petCfg:PetWorks(i))
        local workType = petWorkCfg:Type()
        local level = petWorkCfg:Level()
        local param = {level = level, name = ModuleRefer.PetModule:GetPetWorkTypeStr(workType), icon = ModuleRefer.PetModule:GetPetWorkTypeIcon(workType)}
        local itemMain = self.pool_type_info_main:GetItem().Lua
        itemMain:FeedData(param)
    end

    -- 类型
    local tagId = petCfg:AssociatedTagInfo()
    self.child_icon_style:FeedData({tagId = tagId})

    -- self.transform.localPosition = CS.UnityEngine.Vector3(-110,0,0)
end

return RadarPetDetailComp
