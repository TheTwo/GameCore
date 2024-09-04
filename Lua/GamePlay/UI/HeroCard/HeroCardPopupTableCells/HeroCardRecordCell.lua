local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local FunctionClass = require('FunctionClass')
local I18N = require('I18N')
local TimeFormatter = require("TimeFormatter")
local HeroCardRecordCell = class('HeroCardRecordCell',BaseTableViewProCell)

function HeroCardRecordCell:OnCreate(param)
    self.goBase = self:GameObject('p_base')
    self.textType = self:Text('p_text_type')
    self.textName = self:Text('p_text_name')
    self.textTime = self:Text('p_text_time')
end

function HeroCardRecordCell:OnFeedData(data)
    local info = data.info
    local itemId = info.ItemId
    local timeStamp = info.Timestamp
    self.goBase:SetActive(data.index % 2 ~= 0)
    local itemCfg = ConfigRefer.Item:Find(itemId)
    if itemCfg:FunctionClass() == FunctionClass.AddHero then
        local heroId = tonumber(itemCfg:UseParam(1))
        self.textType.text = I18N.Get("hero_hero")
        self.textName.text = I18N.Get(ConfigRefer.Heroes:Find(heroId):Name())
    elseif itemCfg:FunctionClass() == FunctionClass.AddPet then
        local petId = tonumber(itemCfg:UseParam(1))
        self.textType.text = I18N.Get("pet_title0")
        self.textName.text = I18N.Get(ConfigRefer.Pet:Find(petId):Name())
    else
        self.textType.text = I18N.Get("item_title")
        self.textName.text = I18N.Get(itemCfg:NameKey())
    end
    self.textTime.text = TimeFormatter.GetFormatCompleteTime(timeStamp.timeSeconds * 1000)
end

return HeroCardRecordCell
