local BaseUIComponent = require ('BaseUIComponent')
local UIHelper = require('UIHelper')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local UIHeroLocalData = require('UIHeroLocalData')
local DBEntityPath = require("DBEntityPath")
local GotoUtils = require("GotoUtils")
local ConfigRefer = require('ConfigRefer')
local LockEquipParameter = require("LockEquipParameter")
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local I18N = require('I18N')
local EventConst = require("EventConst")
local LayoutRebuilder = CS.UnityEngine.UI.LayoutRebuilder

local Vector3 = CS.UnityEngine.Vector3

local CommonItemTipsDetails = class('CommonItemTipsDetails', BaseUIComponent)

function CommonItemTipsDetails:OnCreate()
    self.goRoot = self:GameObject("")
    self.textItemName = self:Text('p_text_item_name')
    self.textNeed = self:Text('p_text_need')
    self.tableviewproTableNeed = self:TableViewPro('p_table_need')
    self.goItem1 = self:GameObject('p_item_1')
    self.goGroupNeed = self:GameObject('p_group_need')
    self.imgIconAddtion1 = self:Image('p_icon_addtion_1')
    self.textAddtion1 = self:Text('p_text_addtion_1')
    self.textAddtionNumber1 = self:Text('p_text_addtion_number_1')
    self.imgIconItem1 = self:Image('p_icon_item_1')
    self.goItem2 = self:GameObject('p_item_2')
    self.imgIconAddtion2 = self:Image('p_icon_addtion_2')
    self.textAddtion2 = self:Text('p_text_addtion_2')
    self.textAddtionNumber2 = self:Text('p_text_addtion_number_2')
    self.imgIconItem2 = self:Image('p_icon_item_2')
    self.textItemContent = self:Text('p_text_item_content')
    self.goArrowR = self:GameObject('p_icon_arrow_e')
    self.goArrowB = self:GameObject('p_icon_arrow_s')
    self.goArrowL = self:GameObject('p_icon_arrow_w')
    self.goArrowT = self:GameObject('p_icon_arrow_n')
    self.goItems = {self.goItem1, self.goItem2}
    self.imgIconAddtions = {self.imgIconAddtion1, self.imgIconAddtion2}
    self.textAddtions = {self.textAddtion1, self.textAddtion2}
    self.textAddtionNumbers = {self.textAddtionNumber1, self.textAddtionNumber2}
    self.imgIconItems = {self.imgIconItem1, self.imgIconItem2}
end

function CommonItemTipsDetails:OnClose()

end

function CommonItemTipsDetails:OnFeedData(param)
    if not param then
        return
    end
    self:RefreshDetails(param)
    self.param = param
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.goRoot.transform)
    if self.param.clickTransform then
        self:LimitInScene()
    end
end

function CommonItemTipsDetails:RefreshDetails(param)
    if param.title then
        self.textItemName.text = param.title
    else
        self.textItemName.gameObject:SetActive(false)
    end
    if param.items then
        self.textNeed.text = param.itemTitle or I18N.Temp().hint_lake_item
        self.tableviewproTableNeed:Clear()
        for _, itemData in ipairs(param.items) do
            self.tableviewproTableNeed:AppendData(itemData)
        end
    else
        self.textNeed.gameObject:SetActive(false)
        self.tableviewproTableNeed.gameObject:SetActive(false)
    end
    if param.additions then
        for index, addition in ipairs(param.additions) do
            if addition.icon then
                g_Game.SpriteManager:LoadSprite(addition.icon, self.imgIconAddtions[index])
            else
                self.imgIconAddtions[index].gameObject:SetActive(false)
            end
            if addition.key then
                self.textAddtions[index].text = addition.key
            end
            if addition.value then
                self.textAddtionNumbers[index].text = addition.key
            end
            if addition.itemIcon then
                g_Game.SpriteManager:LoadSprite(addition.itemIcon, self.imgIconItems[index])
            else
                self.imgIconItems[index].gameObject:SetActive(false)
            end
        end
    else
        for _, item in ipairs(self.goItems) do
            item:SetActive(false)
        end
    end
    if param.desc then
        self.textItemContent.text = param.desc
    else
        self.textItemContent.gameObject:SetActive(false)
    end
end

function CommonItemTipsDetails:LimitInScene()
    local anchorPos = self.param.clickTransform.position
    local hight = self.param.clickTransform.rect.height
    local width = self.param.clickTransform.rect.width
    local uiCamera = g_Game.UIManager:GetUICamera()
    local localPos = UIHelper.WorldPos2UIPos(uiCamera, anchorPos, self.goRoot.transform)
    local rootSize = self.goRoot.transform.rect
    local halfRootWidth = rootSize.width / 2
    local halfRootHight = rootSize.height / 2
    local halfScreenWidth = g_Game.UIManager:GetUIRoot():GetComponent(typeof(CS.UIRoot)).referenceWidth / 2
    local halfScreenHeigh = g_Game.UIManager:GetUIRoot():GetComponent(typeof(CS.UIRoot)).referenceHeight / 2
    local showType = self.param.showType or CommonItemDetailsDefine.SHOW_TYPE.VERTICAL
    local isVertical = showType == CommonItemDetailsDefine.SHOW_TYPE.VERTICAL
    self.goArrowR:SetActive(not isVertical)
    self.goArrowL:SetActive(not isVertical)
    self.goArrowB:SetActive(isVertical)
    self.goArrowT:SetActive(isVertical)
    if isVertical then
        local targetY
        local targetArrow
        if localPos.y > 0 then
            self.goArrowB:SetActive(false)
            targetY = localPos.y - halfRootHight - hight
            targetArrow = self.goArrowT
            targetArrow.transform.localPosition  = Vector3(0, targetArrow.transform.localPosition.y)
        else
            self.goArrowT:SetActive(false)
            targetY = localPos.y + halfRootHight + width
            targetArrow = self.goArrowB
            targetArrow.transform.localPosition = Vector3(0, targetArrow.transform.localPosition.y)
        end
        local targetX = localPos.x
        if targetX > 0 and targetX + halfRootWidth > halfScreenWidth then
            targetX = halfScreenWidth - halfRootWidth - 40
            targetArrow.transform.localPosition = Vector3(localPos.x - targetX, targetArrow.transform.localPosition.y)
        end
        if targetX < 0 and targetX - halfRootWidth < - halfScreenWidth then
            targetX = - halfScreenWidth + halfRootWidth + 40
            targetArrow.transform.localPosition = Vector3(localPos.x - targetX, targetArrow.transform.localPosition.y)
        end
        self.goRoot.transform.localPosition = Vector3(targetX, targetY, 0)
    else
        local targetX
        local targetArrow
        if localPos.x > 0 then
            self.goArrowL:SetActive(false)
            targetX = localPos.x - halfRootWidth - width
            targetArrow = self.goArrowR
            targetArrow.transform.localPosition = Vector3(targetArrow.transform.localPosition.x, 0)
        else
            self.goArrowR:SetActive(false)
            targetX = localPos.x + halfRootWidth + width
            targetArrow = self.goArrowL
            targetArrow.transform.localPosition = Vector3(targetArrow.transform.localPosition.x, 0)
        end
        local targetY = localPos.y
        if targetY > 0 and targetY + halfRootHight > halfScreenHeigh then
            targetY = halfScreenHeigh - halfRootHight - 40
            targetArrow.transform.localPosition = Vector3(targetArrow.transform.localPosition.x, localPos.y - targetY)
        end
        if targetY < 0 and targetY - halfRootHight < - halfScreenHeigh then
            targetY = - halfScreenHeigh + halfRootHight + 40
            targetArrow.transform.localPosition = Vector3(targetArrow.transform.localPosition.x, localPos.y - targetY)
        end
        self.goRoot.transform.localPosition = Vector3(targetX, targetY, 0)
    end
end


return CommonItemTipsDetails
