--- scene:scene_league_tips_building_position

local Delegate = require("Delegate")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local Utils = require("Utils")
local EventConst = require("EventConst")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceBuildingPositionMediatorParameter
---@field position {x:number,y:number}[]
---@field clickRectTrans CS.UnityEngine.RectTransform
---@field parentMediatorId number

---@class AllianceBuildingPositionMediator:BaseUIMediator
---@field new fun():AllianceBuildingPositionMediator
---@field super BaseUIMediator
local AllianceBuildingPositionMediator = class('AllianceBuildingPositionMediator', BaseUIMediator)

function AllianceBuildingPositionMediator:ctor()
    BaseUIMediator.ctor(self)
    self._cellLimitCount = 4
    self._clickRect = nil
end

function AllianceBuildingPositionMediator:OnCreate(param)
    self._p_content = self:Transform("p_content")
    self._p_table_detail = self:TableViewPro("p_table_detail")
    self._p_table_detail_rect = self:RectTransform("p_table_detail")
    self._p_table_detail_layout = self:BindComponent("p_table_detail", typeof(CS.UnityEngine.UI.LayoutElement))
    self._p_icon_arrow_r = self:GameObject("p_icon_arrow_r")
    self._p_icon_arrow_l = self:GameObject("p_icon_arrow_l")
    self._p_vx_trigger = self:AnimTrigger("p_vx_trigger")
end

---@param data AllianceBuildingPositionMediatorParameter
function AllianceBuildingPositionMediator:OnOpened(data)
    self._data = data
    local cellHeight = self._p_table_detail:GetMinCellHeight()
    local cellDataCount = table.nums(data.position)
    self._p_table_detail:Clear()
    if cellDataCount <= self._cellLimitCount then
        self._p_table_detail_layout.preferredHeight = cellDataCount * cellHeight
    else
        self._p_table_detail_layout.preferredHeight = (self._cellLimitCount + 0.5) * cellHeight
    end
    self._p_table_detail_rect:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Vertical, self._p_table_detail_layout.preferredHeight)
    local clickGO = Delegate.GetOrCreate(self, self.OnClickGoToButton)
    for i, v in pairs(data.position) do
        ---@type AllianceBuildingPositionMediatorCellData
        local cellData = {}
        cellData.content = ("X:%d, Y:%d"):format(v.x, v.y)
        cellData.onclick = clickGO
        cellData.context = v
        self._p_table_detail:AppendData(cellData)
    end
    self:LimitInScreenView(data.clickRectTrans)
    self._p_vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

function AllianceBuildingPositionMediator:OnShow(param) 
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdateTick))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
end

function AllianceBuildingPositionMediator:OnHide(param)
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdateTick))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
end

---@param clickRectTrans CS.UnityEngine.RectTransform
function AllianceBuildingPositionMediator:LimitInScreenView(clickRectTrans)
    local clickPosRect = clickRectTrans.rect
    local centerPos = CS.UnityEngine.Vector3(clickPosRect.center.x, clickPosRect.center.y)
    local worldPos = clickRectTrans:TransformPoint(centerPos)
    local uiCamera = g_Game.UIManager:GetUICamera()
    local viewPortPos = uiCamera:WorldToViewportPoint(worldPos)
    local isLeft = viewPortPos.x <= 0.5
    self._p_icon_arrow_r:SetVisible(not isLeft)
    self._p_icon_arrow_l:SetVisible(isLeft)
    local edge
    if isLeft then
        edge = CS.UnityEngine.Vector3(clickPosRect.max.x, clickPosRect.center.y)
    else
        edge = CS.UnityEngine.Vector3(clickPosRect.min.x, clickPosRect.center.y)
    end
    local edgeWorldPos = clickRectTrans:TransformPoint(edge)
    local contentPos = self._p_content.parent:InverseTransformPoint(edgeWorldPos)
    self._p_content.localPosition = contentPos

    local p = self._p_table_detail_rect.pivot
    p.x = isLeft and -0.1 or 1.1
    self._p_table_detail_rect.pivot = p
    self._p_table_detail_rect.anchoredPosition = CS.UnityEngine.Vector2.zero
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_table_detail_rect)
    ---@type CS.UnityEngine.Vector3[]
    local fourCornersArray = CS.System.Array.CreateInstance(typeof(CS.UnityEngine.Vector3), 4)
    self._p_table_detail_rect:GetWorldCorners(fourCornersArray)
    local lt = uiCamera:WorldToViewportPoint(fourCornersArray[1])
    local yChange = 0
    if lt.y > 1 then
        lt.y = 1
        local wp = uiCamera:ViewportToWorldPoint(lt)
        yChange = wp.y - fourCornersArray[1].y
    else
        local lb = uiCamera:WorldToViewportPoint(fourCornersArray[0])
        if lb.y < 0 then
            lb.y = 0
            local wp = uiCamera:ViewportToWorldPoint(lt)
            yChange = wp.y - fourCornersArray[0].y
        end
    end
    if math.abs(yChange) > 0.001 then
        local wp = self._p_table_detail_rect.position
        wp.y = wp.y + yChange
        self._p_table_detail_rect.position = wp
    end
    local worldY = self._p_content.transform.position.y
    local posArrow = self._p_icon_arrow_l.transform.position
    posArrow.y = worldY
    self._p_icon_arrow_l.transform.position = posArrow
    posArrow = self._p_icon_arrow_r.transform.position
    posArrow.y = worldY
    self._p_icon_arrow_r.transform.position = posArrow
end

---@param pos {x:number, y:number}
function AllianceBuildingPositionMediator:OnClickGoToButton(pos)
    AllianceWarTabHelper.GoToCoord(pos.x, pos.y)
    self:CloseSelf()
    if self._data and self._data.parentMediatorId then
        g_Game.UIManager:Close(self._data.parentMediatorId)
    end
end

function AllianceBuildingPositionMediator:LateUpdateTick()
    if not self._data or Utils.IsNull(self._data.clickRectTrans) then
        return
    end
    self:LimitInScreenView(self._data.clickRectTrans)
end

function AllianceBuildingPositionMediator:OnLeaveAlliance(allianceId)
    self:CloseSelf()
end

return AllianceBuildingPositionMediator