local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class TouchMenuBasicInfo:BaseUIComponent
local TouchMenuBasicInfo = class('TouchMenuBasicInfo', BaseUIComponent)

function TouchMenuBasicInfo:OnCreate()
    --- 等级
    -- self._p_icon_level = self:GameObject("p_icon_level")
    self._p_text_level = self:Text("p_text_level")

    --- 名字
    self._p_text_name = self:Text("p_text_name")

    --- 背景图
    self._p_base_title = self:Image("p_base_title")

    --- 坐标
    self._p_text_position = self:Text("p_text_position")

    --- 建筑图片
    self._p_img_buiding = self:GameObject("p_img_buiding")
    self._p_img_front = self:Image("p_img_front")

    --- 玩家头像/联盟头像
    self.goHeadPlayer = self:GameObject("p_child_ui_head_player")
    self._p_child_ui_head_player = self:LuaBaseComponent("p_child_ui_head_player")

    --- TipsButton
    self._child_comp_btn_detail = self:GameObject("child_comp_btn_detail")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickTips))
end

---@param data TouchMenuBasicInfoDatum
function TouchMenuBasicInfo:OnFeedData(data)
    self.data = data
    self._p_text_name.text = data.name

    local showLevel = data:ShowLevel()
    self._p_text_level:SetVisible(showLevel)
    if showLevel then
        self._p_text_level.text = data:GetLevelText()
    end

    local showCoord = data:ShowCoord()
    self._p_text_position:SetVisible(showCoord)
    if showCoord then
        self._p_text_position.text = data:GetCoordText()
    end

    local showBack = data:ShowBackground()
    self._p_base_title:SetVisible(showBack)
    if showBack then
        g_Game.SpriteManager:LoadSprite(data.background, self._p_base_title)
    end

    local showImage = data:ShowImage()
    self._p_img_buiding:SetActive(showImage)
    if showImage then
        if tonumber(data.image) ~= nil then
            self:LoadSprite(data.image, self._p_img_front)
        else
            g_Game.SpriteManager:LoadSprite(data.image, self._p_img_front)
        end
        self._p_img_front:SetNativeSize()
    end

    local showPlayerInfo = data:ShowHeadPlayer()
    if showPlayerInfo then
        self.goHeadPlayer:SetActive(true)
        self._p_child_ui_head_player:FeedData(data.owner)
    else
        self.goHeadPlayer:SetActive(false)
    end

    self._child_comp_btn_detail:SetActive(data:ShowTipsButton())
    self._p_btn_detail:SetVisible(data.tipsOnClick ~= nil)

end

function TouchMenuBasicInfo:OnClickTips()
    self.data.tipsOnClick()
end

return TouchMenuBasicInfo