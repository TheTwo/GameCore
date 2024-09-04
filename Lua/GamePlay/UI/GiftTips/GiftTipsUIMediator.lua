---scene:scene_tips_gift_detail

local BaseUIMediator = require("BaseUIMediator")
local UIHelper = require('UIHelper')
local TipsRectTransformUtils = require('TipsRectTransformUtils')

---@class GiftTipsListInfoCell
---@field itemId number
---@field itemCount number
---@field titleText string
---@field itemCountText string
---@field iconShowCount boolean

---@class GiftTipsUIMediatorParameter
---@field listInfo table<number, GiftTipsListInfoCell>
---@field clickTrans CS.UnityEngine.Transform
---@field arrowDirection number|nil @ArrowDirectionDefine
---@field textDetail string

---@class GiftTipsUIMediator:BaseUIMediator
---@field new fun():GiftTipsUIMediator
---@field super BaseUIMediator
local GiftTipsUIMediator = class("GiftTipsUIMediator", BaseUIMediator)

local ArrowDirectionDefine = {
    Up = -1,
    Down = 1,
}

function GiftTipsUIMediator:OnCreate()
    self.goRoot = self:GameObject('')
    self.goContent = self:GameObject('content')
    self.tableviewproTableGift = self:TableViewPro('p_table_gift')

    self.goArrowTop = self:GameObject('p_arrow_top')
    self.goArrowBottom = self:GameObject('p_arrow_bottom')
    self.tableLayout = self:BindComponent("p_table_gift", typeof(CS.UnityEngine.UI.LayoutElement))
    self.transform = self:RectTransform('content')

    self.goTextDetail = self:GameObject('p_item_detail')
    self.textDetail = self:Text('p_text_detail')
end

-- {listInfo = {{titleText = xxxx}, {itemId = 1, itemCount = 100}}, clickTrans = xx}
---@param param GiftTipsUIMediatorParameter
function GiftTipsUIMediator:OnOpened(param)
    if not param then
        return
    end
    self:FillTable(param)
    self.clickTrans = param.clickTrans
    if self.clickTrans then
        self:SetPos(param.arrowDirection)
    else
        self.goContent.transform.localPosition = CS.UnityEngine.Vector3.zero
    end
end

function GiftTipsUIMediator:FillTable(param)
    local shouldAdapt = param.shouldAdapt
    if shouldAdapt == nil then
        shouldAdapt = true
    end
    self.tableviewproTableGift:Clear()
    if param.textDetail then
        self.tableviewproTableGift:AppendData(param.textDetail, 2)
    end
    for _, single in ipairs(param.listInfo) do
        if single.titleText then
            self.tableviewproTableGift:AppendData(single.titleText, 0, 0)
            self:HeightAdapt(shouldAdapt, 0, param.maxHeight)
        else
            self.tableviewproTableGift:AppendData(single, 1, 0)
            self:HeightAdapt(shouldAdapt, 1, param.maxHeight)
        end
    end
end

function GiftTipsUIMediator:LimitInScene()
    local anchorPos = self.clickTrans.position
    local halfScreenWidth = CS.UnityEngine.Screen.width / 2
    local clamp = halfScreenWidth - 350
    local uiCamera = g_Game.UIManager:GetUICamera()
    local uiPos = UIHelper.WorldPos2UIPos(uiCamera, anchorPos, self.goRoot.transform)
    local targetX =  uiPos.x
    local targetY = uiPos.y
    targetX = math.clamp(targetX, - clamp, clamp)
    if targetY > 0 then
        targetY = targetY - 50
    elseif targetY < 0 then
        targetY = targetY + 50
    end
    self.goContent.transform.localPosition = CS.UnityEngine.Vector3(targetX, targetY, 0)
end

function GiftTipsUIMediator:SetPos(arrowDirection)
    local leftBoundX = 0
    local rightBoundX = CS.UnityEngine.Screen.width
    local upBoundY = CS.UnityEngine.Screen.height / 2
    local downBoundY = - CS.UnityEngine.Screen.height / 2

    local scaleX = CS.UnityEngine.Screen.width / 1920
    local scaleY = CS.UnityEngine.Screen.height / 1080

    local anchorPos = self.clickTrans.position
    ---@type CS.UnityEngine.Camera
    local uiCamera = g_Game.UIManager:GetUICamera()
    local uiPos = uiCamera:WorldToScreenPoint(anchorPos)

    local halfUIHeight = math.max(self.transform.rect.height / 2, self.tableLayout.preferredHeight / 2) * scaleY
    local halfUIWidth = math.max(self.transform.rect.width / 2, self.tableLayout.preferredWidth / 2) * scaleX

    local direction = arrowDirection or ArrowDirectionDefine.Down

    local targetX = uiPos.x

    local uiLeftBoundX = uiPos.x - halfUIWidth
    local uiRightBoundX = uiPos.x + halfUIWidth

    local lOffsetX = leftBoundX - uiLeftBoundX
    local rOffsetX = uiRightBoundX - rightBoundX

    local arrowOffsetX = 0

    if uiLeftBoundX < leftBoundX then
        targetX = targetX + lOffsetX
        arrowOffsetX = -lOffsetX
    elseif uiRightBoundX > rightBoundX then
        targetX = targetX - rOffsetX
        arrowOffsetX = rOffsetX
    end
    
    local halfScreenHeight = CS.UnityEngine.Screen.height / 2
    if uiPos.y < halfScreenHeight then
        uiPos.y = 2 * halfScreenHeight - uiPos.y 
    end

    halfUIHeight = halfUIHeight / scaleY
    local localOffsetY = direction * halfUIHeight
    self.goContent.transform.position = uiCamera:ScreenToWorldPoint(CS.UnityEngine.Vector3(targetX, uiPos.y, 0))

    local uiUpBoundY = self.goContent.transform.localPosition.y + localOffsetY + halfUIHeight
    local uiDownBoundY = self.goContent.transform.localPosition.y + localOffsetY - halfUIHeight

    --- 上下超界优先反转 ---
    if uiUpBoundY > upBoundY then
        direction = ArrowDirectionDefine.Up
        localOffsetY = -halfUIHeight
    elseif uiDownBoundY < downBoundY then
        direction = ArrowDirectionDefine.Down
        localOffsetY = halfUIHeight
    end

    self.goContent.transform.localPosition = CS.UnityEngine.Vector3(self.goContent.transform.localPosition.x,
        self.goContent.transform.localPosition.y + localOffsetY, 0)

    --- 调整箭头位置 ---

    self.goArrowTop.transform.localPosition =
        CS.UnityEngine.Vector3(self.goArrowTop.transform.localPosition.x + arrowOffsetX,
        self.goArrowTop.transform.localPosition.y, 0)
    self.goArrowBottom.transform.localPosition =
        CS.UnityEngine.Vector3(self.goArrowBottom.transform.localPosition.x + arrowOffsetX,
        self.goArrowBottom.transform.localPosition.y, 0)

    self.goArrowTop:SetActive(direction == ArrowDirectionDefine.Up)
    self.goArrowBottom:SetActive(direction == ArrowDirectionDefine.Down)
    -- self.goArrowTop:SetVisible(false)
    -- self.goArrowBottom:SetVisible(false)
end

function GiftTipsUIMediator:HeightAdapt(shouldAdapt, cellIndex, maxHeight)
    if not shouldAdapt or not self.tableLayout then
        return
    end
    if not maxHeight then maxHeight = 800 end
    local curHeight = math.max(self.tableLayout.preferredHeight, self.tableLayout.minHeight)
    local cellHeight = self.tableviewproTableGift.cellPrefab[cellIndex]:GetComponent(typeof(CS.CellSizeComponent)).Height
    if curHeight + cellHeight > maxHeight then
        self.tableLayout.preferredHeight = maxHeight
    else
        self.tableLayout.preferredHeight = curHeight + cellHeight
    end
end


return GiftTipsUIMediator