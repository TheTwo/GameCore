local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local UIHelper = require('UIHelper')
local I18N = require('I18N')

---@class CommonDropDownData
---@field defaultId number
---@field items CommonDropDownItemData[]
---@field onSelect fun(number)
---@field autoFlip boolean

---@class CommonDropDown : BaseUIComponent
---@field itemDatas CommonDropDownItemData[]
local CommonDropDown = class('CommonDropDown', BaseUIComponent)

function CommonDropDown:ctor()

end

function CommonDropDown:OnCreate()
    self.btnDropdown = self:Button('', Delegate.GetOrCreate(self, self.OnBtnChildDropdownClicked))
    self.goInfo = self:GameObject('info')
    self.imgIconTroops = self:Image('p_icon_troops');
    self.textLabel = self:Text('p_text_label');
    self.goList = self:GameObject('p_list');
    self.goArrow = self:GameObject("p_arrow");
    self.goItem1 = self:LuaBaseComponent('p_item_1');
    self.goItemList = {}
    table.insert(self.goItemList,self.goItem1)
    self.rectList = self:RectTransform('p_list')
    self.rectInfo = self:RectTransform('info')
    self.rectItem = self:RectTransform('p_item_1')
end


function CommonDropDown:OnShow(param)
    self.goList:SetVisible(false)
    if self.goMask then
         UIHelper.HideDropDownBlockMask(self.CSComponent.gameObject,self.goMask)
    end
    self.showList = false
    ---@type CS.UnityEngine.RectTransform
    local goListRect = self.goList:GetComponent(typeof(CS.UnityEngine.RectTransform))
    ---@type CS.UnityEngine.RectTransform
    local goInfoRect = self.goInfo:GetComponent(typeof(CS.UnityEngine.RectTransform))
    local listDir = goListRect.rect.center - goInfoRect.rect.center
    self.arrowAngle_Show = nil
    if math.abs(listDir.x) < math.abs(listDir.y) then
        if listDir.y > 0 then
            --down
            self.arrowAngle_Show = CS.UnityEngine.Vector3(0, 0, 180)
        else
            --up
            self.arrowAngle_Show = CS.UnityEngine.Vector3(0, 0, 0)
        end
    else
        if listDir.x > 0 then
            --right
            self.arrowAngle_Show = CS.UnityEngine.Vector3(0, 0, -90)
        else
            --left
            self.arrowAngle_Show = CS.UnityEngine.Vector3(0, 0, 90)
        end
    end
    self.arrowAngle_Hide = CS.UnityEngine.Vector3(0, 0, self.arrowAngle_Show.z + 180)
    self.goArrow.transform.localEulerAngles = self.arrowAngle_Show
end

function CommonDropDown:OnOpened(param)
end

function CommonDropDown:OnClose(param)
    if self.offset then
        local y = self.goList.transform.localPosition.y - self.offset
        self.goList.transform.localPosition = CS.UnityEngine.Vector3(self.goList.transform.localPosition.x, y, 0)
    end
end

---OnFeedData
---@param param CommonDropDownData
function CommonDropDown:OnFeedData(param)
    if not param then
        return
    end
    local itemCount = #param.items
    if itemCount < 1 then
        return
    end
    self.itemDatas = param.items
    self.onClick = param.onClick
    self.autoFlip = param.autoFlip or false
    local onCellClick = Delegate.GetOrCreate(self,self.OnItemSelect)
    local setupCount = 0
    local max = math.min( #self.itemDatas, #self.goItemList)

    for i = 1, max do
        local itemData = self.itemDatas[i]
        itemData.onClick = onCellClick
        itemData.selected = itemData.id == param.defaultId
        self.goItemList[i]:FeedData(itemData)
        setupCount = setupCount + 1
    end

    if setupCount < itemCount then
        for i = setupCount+1, itemCount do
            local subItem = UIHelper.DuplicateUIComponent(self.goItem1)
            local itemData = self.itemDatas[i]
            itemData.onClick = onCellClick
            itemData.selected = itemData.id == param.defaultId
            subItem:FeedData(itemData)
            table.insert(self.goItemList,subItem)
        end
    elseif setupCount < #self.goItemList then
        for i = setupCount+1,#self.goItemList do
            self.goItemList[i]:SetVisible(false)
        end
    end
    if self.autoFlip then
        local downBoundY = 0
        local halfHeight = self.rectItem.rect.height / 2 * itemCount

        local uiCamera = g_Game.UIManager:GetUICamera()
        local uiPos = uiCamera:WorldToScreenPoint(self.goList.transform.position)

        local uiDownBoundY = uiPos.y - halfHeight * 2

        if uiDownBoundY < downBoundY then
            local offset = 2 * halfHeight + self.rectInfo.rect.height
            local y = self.goList.transform.localPosition.y + offset
            self.goList.transform.localPosition = CS.UnityEngine.Vector3(self.goList.transform.localPosition.x, y, 0)
        end
    end
    self.onSelect = param.onSelect
    self.curSelectId = param.defaultId
    self:UpdateInfo(param.defaultId)
end

function CommonDropDown:UpdateItemData()
    for i = 1,  #self.itemDatas do
        local itemData = self.itemDatas[i]
        itemData.selected = itemData.id == self.curSelectId
        self.goItemList[i]:FeedData(itemData)
    end
end


function CommonDropDown:SelectItem(id)
    self.goList:SetVisible(false)
    if self.arrowAngle_Show then
        self.goArrow.transform.localEulerAngles = self.arrowAngle_Show
    end
    if self.goMask then
         UIHelper.HideDropDownBlockMask(self.CSComponent.gameObject,self.goMask)
    end
    self.showList = false
    self.curSelectId = id
    if self.onSelect then
        self.onSelect(id)
    end
    self:UpdateInfo(id)
    self:UpdateItemData()
end

function CommonDropDown:UpdateInfo(id)
    ---@type CommonDropDownItemData
    local itemData = nil
    for i, v in pairs(self.itemDatas) do
        if v.id == id then
            itemData = v
            break
        end
    end

    if itemData then
        if string.IsNullOrEmpty(itemData.iconName) then
            self.imgIconTroops:SetVisible(false)
        else
            self.imgIconTroops:SetVisible(true)
            g_Game.SpriteManager:LoadSprite(itemData.iconName, self.imgIconTroops)
        end
        self.textLabel.text = I18N.Get(itemData.showText)
        UIHelper.ResetContent(self.goInfo)
    end
end

function CommonDropDown:OnBtnChildDropdownClicked(args)
    if self.onClick then
        self.onClick()
    end
    if self.showList then
        self.goList:SetVisible(false)
        if self.goMask then
             UIHelper.HideDropDownBlockMask(self.CSComponent.gameObject,self.goMask)
        end
        self.showList = false
        self.goArrow.transform.localEulerAngles =  self.arrowAngle_Show
    else
        self.goList:SetVisible(true)
        self.goMask = UIHelper.ShowDropDownBlockMask(self.CSComponent.gameObject,self.goMask)

        self.showList = true
        self.goArrow.transform.localEulerAngles =  self.arrowAngle_Hide

    end

end

function CommonDropDown:HideSelf()
    self.goList:SetVisible(false)
    if self.goMask then
        UIHelper.HideDropDownBlockMask(self.CSComponent.gameObject,self.goMask)
    end
    self.showList = false
    if self.arrowAngle_Show then
        self.goArrow.transform.localEulerAngles = self.arrowAngle_Show
    end
end

function CommonDropDown:OnItemSelect(id)
    self:SelectItem(id)
end

---工具方法
---@param params string[] @[icon,text,icon,text]
---@return CommonDropDownItemData[]
function CommonDropDown.CreateData(...)
    local params = table.pack(...);
    if params == nil then
        return nil;
    end
    local paramCount = #params
    assert(paramCount % 2 == 0)
    ---@type CommonDropDownData
    local retItemDataSet = {}
    for i = 0, paramCount / 2 - 1 do
        ---@type CommonDropDownItemData
        local data = {
            id = i + 1,
            iconName = params[i * 2 + 1],
            text = params[i * 2 + 2 ],
            showText =  params[i * 2 + 2 ]
        }
        table.insert(retItemDataSet,data)
    end
    return retItemDataSet;
end

---@param params string[] @[icon,text,showText,icon,text,showText]
---@return CommonDropDownItemData[]
function CommonDropDown.CreateDataEx(...)
    local params = table.pack(...);
    if params == nil then
        return nil;
    end
    local paramCount = #params
    assert(paramCount % 3 == 0)
    ---@type CommonDropDownData
    local retItemDataSet = {}
    for i = 0, paramCount / 3 - 1 do
        ---@type CommonDropDownItemData
        local data = {
            id = i + 1,
            iconName = params[i * 3 + 1],
            text = params[i * 3 + 2 ],
            showText =  params[i * 3 + 3 ]
        }
        table.insert(retItemDataSet,data)
    end
    return retItemDataSet;
end

return CommonDropDown;
