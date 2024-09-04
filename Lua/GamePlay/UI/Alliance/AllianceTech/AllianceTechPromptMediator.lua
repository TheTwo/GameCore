local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local AttrValueType = require("AttrValueType")

local AllianceTechPromptMediator = class('AllianceTechPromptMediator', BaseUIMediator)
function AllianceTechPromptMediator:ctor()
    self._rewardList = {}
end

function AllianceTechPromptMediator:OnCreate()
    self.child_popup_base_s = self:LuaObject('child_popup_base_s')
    self.p_text_title_1 = self:Text('p_text_title_1')
    self.p_text_title_2 = self:Text('p_text_title_2')
    self.p_table = self:TableViewPro('p_table')
end

function AllianceTechPromptMediator:OnShow(param)
    self._group = ModuleRefer.AllianceTechModule:GetTechGroupByGroupId(param.groupId)
    self._groupData = ModuleRefer.AllianceTechModule:GetTechGroupStatus(param.groupId)
    local dataLv = math.clamp(self._groupData and self._groupData.Level or 0, 0, #self._group)
    local configIndex = math.clamp(dataLv, 1, #self._group)
    local config = self._group[configIndex]
    local attrGroup = ConfigRefer.AttrGroup:Find(config:Attr())
    local attr = attrGroup:AttrList(1)

    self.p_text_title_1.text = I18N.Get("alliance_tec_dengji")
    local name = config:AllianceAttrLabelName()
    if name ~= "" then
        self.p_text_title_2.text = I18N.Get(name)
    else
        self.p_text_title_2.text = I18N.Get(ConfigRefer.AttrElement:Find(attr:TypeId()):Name())
    end

    self.child_popup_base_s:FeedData({title = config:Name(), onClose = Delegate.GetOrCreate(self, self.OnClickClose)})

    self.p_table:Clear()
    for i = 1, #self._group do
        local cfg = self._group[i]
        local group = ConfigRefer.AttrGroup:Find(cfg:Attr())
        local temp = group:AttrList(1)
        local attrElement = ConfigRefer.AttrElement:Find(temp:TypeId())
        local value = self:SetAttrValue(attrElement:ValueType(), temp:Value())
        self.p_table:AppendData({level = i, data = value})
    end
end

function AllianceTechPromptMediator:OnHide(param)
end

function AllianceTechPromptMediator:Refresh(param)
end

function AllianceTechPromptMediator:OnClickClose(param)
    g_Game.UIManager:CloseByName("AllianceTechPromptMediator")
end

function AllianceTechPromptMediator:SetAttrValue(valueType, value)
    local res
    if AttrValueType.Percentages == valueType then
        res = ("%s%%"):format(value)
    elseif AttrValueType.OneTenThousand == valueType then
        res = ("%d%%"):format(math.floor(value / 100))
    else
        res = tostring(value)
    end
    return "+"..res
end
return AllianceTechPromptMediator
