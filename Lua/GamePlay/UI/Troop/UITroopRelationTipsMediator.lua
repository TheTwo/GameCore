---scene: scene_troop_tips_relation
local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
---@class UITroopRelationTipsMediator : BaseUIMediator
local UITroopRelationTipsMediator = class('UITroopRelationTipsMediator', BaseUIMediator)

---@class UITroopRelationTipsMediatorParam
---@field tags2Num table<number, number>
---@field tiesId number

local DisplayPart = {
    Left = 1,
    Right = 2,
}

function UITroopRelationTipsMediator:ctor()
    self.curDisplayPart = DisplayPart.Left
    self.toggleOn = g_Game.PlayerPrefsEx:GetIntByUid('troop_relation_tips_toggle', 1) == 1
end

function UITroopRelationTipsMediator:OnCreate()
    self.textTitle = self:Text('p_text_title', 'formation_tagcountertitle')
    -- 切换
    self.textLeft = self:Text('p_txt_left', 'popup_battlestyle_title02')
    self.textRight = self:Text('p_txt_right', 'popup_battlestyle_title01')

    -- buff
    self.goBuff = self:GameObject('p_buff')
    self.textBuff = self:Text('p_text_detail_buff', 'troop_combo_match_buff_content')
    self.textStyle = self:Text('p_text_style', 'troop_combo_match_buff_tips_1')
    self.textBuffNum = self:Text('p_text_buff')

    self.textStylePet = self:Text('p_text_style_1', 'troop_combo_match_buff_tips_2')
    self.luaStyles = {}
    self.luaStyles[1] = self:LuaObject('p_icon_style_1')
    self.luaStyles[2] = self:LuaObject('p_icon_style_2')
    self.luaStyles[3] = self:LuaObject('p_icon_style_3')
    self.luaStyles[4] = self:LuaObject('p_icon_style_4')
    self.luaStyles[5] = self:LuaObject('p_icon_style_5')
    self.luaStyles[6] = self:LuaObject('p_icon_style_6')

    self.textEffect = self:Text('p_text_effect', 'popup_battlestyle_title03')

    self.tableEffects = self:TableViewPro('p_table_effect')

    self.textToggle = self:Text('p_text_hint_toggle', 'battlestyle_desc03')
    self.toggle = self:Button('child_toggle_set', Delegate.GetOrCreate(self, self.OnToggleClicked))
    self.statusToggle = self:StatusRecordParent('child_toggle_set')

    -- 克制关系
    self.goRelation = self:GameObject('p_relation')
    self.textStrength = self:Text('p_text_strength', 'formation_powertag')
    self.textStrategy = self:Text('p_text_strategy', 'formation_intelltag')
    self.textSkill = self:Text('p_text_skill', 'formation_skilltag')
    self.luaStrategy = self:LuaObject('p_icon_strategy')
    self.luaStrength = self:LuaObject('p_icon_strength')
    self.luaSkill = self:LuaObject('p_icon_skill')
    self.textDetail = self:Text('p_text_detail', 'troop_combo_restrain_tips')

    self.luaRelationTags = {}
    self.luaRelationTags[1] = self.luaStrength
    self.luaRelationTags[2] = self.luaStrategy
    self.luaRelationTags[3] = self.luaSkill

    self.luaExtraTag1 = self:LuaObject('p_icon_style_7')
    self.luaExtraTag2 = self:LuaObject('p_icon_style_8')
    self.textExtraHint = self:Text('p_text_tips', 'troop_combo_no_effect')
end

---@param param UITroopRelationTipsMediatorParam
function UITroopRelationTipsMediator:OnOpened(param)
    self.tags2Num = param.tags2Num
    self.tiesId = param.tiesId
    self.textDetail.text = I18N.GetWithParams('troop_combo_restrain_tips', "20%%")
    self:InitBuff()
    self:InitRelation()
end

function UITroopRelationTipsMediator:OnClose(param)
end

function UITroopRelationTipsMediator:InitBuff()
    local i = 1
    local keys = {}
    for k, _ in pairs(self.tags2Num) do
        table.insert(keys, k)
    end
    table.sort(keys, function(a, b)
        if self.tags2Num[a] ~= self.tags2Num[b] then
            return self.tags2Num[a] > self.tags2Num[b]
        else
            return a < b
        end
    end)
    for _, k in ipairs(keys) do
        for _ = 1, self.tags2Num[k] do
            if i <= #self.luaStyles then
                self.luaStyles[i]:FeedData({
                    tagId = k,
                })
                i = i + 1
            end
        end
    end
    for j = i, #self.luaStyles do
        self.luaStyles[j]:FeedData({
            tagId = 0,
        })
    end

    self.tableEffects:Clear()
    for _, cfg in ConfigRefer.TagTies:ipairs() do
        ---@type UITroopRelationCellData
        local data = {}
        data.tiesId = cfg:Id()
        data.isActivate = self.tiesId == cfg:Id()
        self.tableEffects:AppendData(data)
    end

    self.statusToggle:ApplyStatusRecord(self.toggleOn and 1 or 0)

    local sysId = 90105
    local isUnlock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysId)
    self.textToggle.gameObject:SetActive(isUnlock)
    self.toggle.gameObject:SetActive(isUnlock)
end

function UITroopRelationTipsMediator:InitRelation()
    for i = 1, #self.luaRelationTags do
        self.luaRelationTags[i]:FeedData({
            tagId = i,
        })
    end
    self.luaExtraTag1:FeedData({
        tagId = 4,
    })
    self.luaExtraTag2:FeedData({
        tagId = 5,
    })
end

function UITroopRelationTipsMediator:OnToggleClicked()
    if not self.toggleOn then
        self.toggleOn = true
        self.statusToggle:ApplyStatusRecord(1)
        g_Game.PlayerPrefsEx:SetIntByUid('troop_relation_tips_toggle', 1)
        g_Game.EventManager:TriggerEvent(EventConst.TROOP_HINT_TOGGLED, true)
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('toast_team_effect_switch_on'))
    else
        self.toggleOn = false
        self.statusToggle:ApplyStatusRecord(0)
        g_Game.PlayerPrefsEx:SetIntByUid('troop_relation_tips_toggle', 0)
        g_Game.EventManager:TriggerEvent(EventConst.TROOP_HINT_TOGGLED, false)
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('toast_team_effect_switch_off'))
    end
end

return UITroopRelationTipsMediator