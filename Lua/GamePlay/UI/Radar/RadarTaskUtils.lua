local RadarTaskUtils = {}
local Vector3 = CS.UnityEngine.Vector3
local RadarTaskBtnPosDic = {
    minX = -600, maxX = 600,
    minY = -350, maxY = 250,
}
local CellSize = 200
local countX = (RadarTaskBtnPosDic.maxX - RadarTaskBtnPosDic.minX) / CellSize + 1
local countY = (RadarTaskBtnPosDic.maxY - RadarTaskBtnPosDic.minY) / CellSize + 1
local RadarTaskBtnRadius = 60
local UnablePosDic = {
    --左上
    -- {row = 1, col = 1},
    -- {row = 1, col = 2},
    -- {row = 2, col = 1},
    --右上
    -- {row = 1, col = countX},
    -- {row = 1, col = countX - 1},
    -- {row = 2, col = countX},
    --左下
    {row = countY, col = 1},
    -- {row = countY, col = 2},
    -- {row = countY - 1, col = 1},
    --右下
    -- {row = countY, col = countX},
    -- {row = countY, col = countX - 1},
    -- {row = countY - 1, col = countX},

    --正中心
    -- {row = math.ceil(countY/2), col = math.ceil( countX/2)},
    {row = 2, col = 4},

}

function RadarTaskUtils.InitRadarTaskBtnPosBoard()
    RadarTaskUtils.MaxRow = countY
    RadarTaskUtils.MaxCol = countX
    RadarTaskUtils.RadarTaskBtnPosBoard = {}
    for i = 1, countY do
        RadarTaskUtils.RadarTaskBtnPosBoard[i] = {}
        for j = 1, countX do
            if RadarTaskUtils.CheckUnablePos(i, j) then
                RadarTaskUtils.RadarTaskBtnPosBoard[i][j] = 1
            else
                RadarTaskUtils.RadarTaskBtnPosBoard[i][j] = 0
            end
        end
    end
end

function RadarTaskUtils.CalculateBoardPos(posX, posY)
    if not RadarTaskUtils.RadarTaskBtnPosBoard then
        RadarTaskUtils.InitRadarTaskBtnPosBoard()
    end

    posX = RadarTaskUtils.FixPosX(posX)
    posY = RadarTaskUtils.FixPosY(posY)

    local row = -1
    local col = -1
    local tempRow, tempCol
    local modfRow, modfCol      --余数
    tempRow, modfRow = math.modf((RadarTaskBtnPosDic.maxY - posY) / CellSize)
    --row是从1开始,按照坐标取最近的行
    if modfRow < 0.5 then
        row = tempRow + 1
    else
        row = tempRow + 2
    end

    tempCol, modfCol = math.modf((posX - RadarTaskBtnPosDic.minX) / CellSize)
    if modfCol < 0.5 then
        col = tempCol + 1
    else
        col = tempCol + 2
    end

    return row, col
end

function RadarTaskUtils.SetBoardPosByWorldPos(posX, posY)
    return RadarTaskUtils.SetBoardPos(RadarTaskUtils.CalculateBoardPos(posX, posY))
end

function RadarTaskUtils.SetBoardPos(row, col)
    if not RadarTaskUtils.RadarTaskBtnPosBoard then
        RadarTaskUtils.InitRadarTaskBtnPosBoard()
    end

    if col < 1 or col > RadarTaskUtils.MaxCol then
        g_Logger.Error("RadarTaskUtils.SetBoardPosByWorldPos failed, col = " .. col )
        return false
    end
    if row < 1 or row > RadarTaskUtils.MaxRow then
        g_Logger.Error("RadarTaskUtils.SetBoardPosByWorldPos failed, row = " .. row )
        return false
    end
    if RadarTaskUtils.RadarTaskBtnPosBoard[row][col] == 0 then
        RadarTaskUtils.RadarTaskBtnPosBoard[row][col] = 1
        return true, row, col
    else
        return RadarTaskUtils.SetNearlyRandomBoardPos(row, col)
    end
end

function RadarTaskUtils.SetNearlyRandomBoardPos(row, col)
    local rowOffset = 0
    local colOffset = 0
    local isFind = false
    local findCount = 0     --最大循环300次
    local mRow = 0
    local mCol = 0
    while not isFind and findCount <= 300 do
        findCount = findCount + 1
       --循环30次没找到就扩大随机范围
        mRow = math.clamp(math.floor((findCount + 30) / 30), -RadarTaskUtils.MaxRow, RadarTaskUtils.MaxRow)
        mCol = math.clamp(math.floor((findCount + 30) / 30), -RadarTaskUtils.MaxCol, RadarTaskUtils.MaxCol)

        rowOffset = math.random(-mRow, mRow)
        colOffset = math.random(-mCol, mCol)
        if (rowOffset ~= 0 or colOffset ~= 0) and RadarTaskUtils.IsRowValid(row + rowOffset) and RadarTaskUtils.IsColValid(col + colOffset) then
            if RadarTaskUtils.RadarTaskBtnPosBoard[row + rowOffset][col + colOffset] == 0 then
                RadarTaskUtils.RadarTaskBtnPosBoard[row + rowOffset][col + colOffset] = 1
                isFind = true
            end
        end
    end
    if not isFind then
        g_Logger.Error("RadarTaskUtils.SetNearlyRandomBoardPos failed, row = " .. row + rowOffset .. ", col = " .. col + colOffset)
    else
        g_Logger.Log("RadarTaskUtils.SetNearlyRandomBoardPos Success, row = " .. row + rowOffset .. ", col = " .. col + colOffset)
    end
    return isFind, row + rowOffset, col + colOffset
end

function RadarTaskUtils.GetWorldPosByBoardPos(row, col)
    if not RadarTaskUtils.RadarTaskBtnPosBoard then
        RadarTaskUtils.InitRadarTaskBtnPosBoard()
    end
    local pos = Vector3.zero

    if row < 1 or row > RadarTaskUtils.MaxRow then
        g_Logger.Log("RadarTaskUtils.GetWorldPosByBoardPos Failed, row = " .. row)
        return pos
    end
    if col < 1 or col > RadarTaskUtils.MaxCol then
        g_Logger.Log("RadarTaskUtils.GetWorldPosByBoardPos Failed, col = " .. col)
        return pos
    end

    pos.x = RadarTaskBtnPosDic.minX + (col - 1) * CellSize
    pos.y = RadarTaskBtnPosDic.maxY - (row - 1) * CellSize
    return pos
end

function RadarTaskUtils.GetWorldPosWithOffsetByBoardPos(row, col)
    local pos = RadarTaskUtils.GetWorldPosByBoardPos(row, col)
    local offsetX = math.random(25, 35)
    local offsetY = math.random(25, 35)
    if math.random(1, 2) == 1 then
        offsetX = -offsetX
    end
    if math.random(1, 2) == 1 then
        offsetY = -offsetY
    end
    pos.x = pos.x + offsetX
    pos.y = pos.y + offsetY
    g_Logger.Log("RadarTaskUtils.GetWorldPosWithOffsetByBoardPos, row = " .. row .. ", col = " .. col ..
    ", offsetX = " .. offsetX .. ", offsetY = " .. offsetY.. ", PosX = " .. pos.x.. ", PosY = " .. pos.y)
    return pos
end

function RadarTaskUtils.DeleteRadarTaskBtnByBoardPos(row, col)
    if row < 1 or row > RadarTaskUtils.MaxRow then
        g_Logger.Log("RadarTaskUtils.DeleteRadarTaskBtnByBoardPos Failed, row = " .. row)
        return false
    end
    if col < 1 or col > RadarTaskUtils.MaxCol then
        g_Logger.Log("RadarTaskUtils.DeleteRadarTaskBtnByBoardPos Failed, col = " .. col)
        return false
    end
    if RadarTaskUtils.RadarTaskBtnPosBoard[row][col] == 1 then
        RadarTaskUtils.RadarTaskBtnPosBoard[row][col] = 0
        g_Logger.Log("RadarTaskUtils.DeleteRadarTaskBtnByBoardPos Success, col = " .. row .. ", col = " .. col)
        return true
    end
    return false
end

function RadarTaskUtils.DeleteRadarTaskBtnByWorldPos(posX, posY)
    return RadarTaskUtils.DeleteRadarTaskBtnByBoardPos(RadarTaskUtils.CalculateBoardPos(posX, posY))
end

function RadarTaskUtils.FixPosX(posX)
    return math.clamp(posX, RadarTaskBtnPosDic.minX, RadarTaskBtnPosDic.maxX)
end

function RadarTaskUtils.FixPosY(posY)
    return math.clamp(posY, RadarTaskBtnPosDic.minY, RadarTaskBtnPosDic.maxY)
end

function RadarTaskUtils.IsRowValid(row)
    return row >= 1 and row <= RadarTaskUtils.MaxRow
end

function RadarTaskUtils.IsColValid(col)
    return col >= 1 and col <= RadarTaskUtils.MaxCol
end

function RadarTaskUtils.ClearRadarTaskBtnPosBoard()
    if not RadarTaskUtils.RadarTaskBtnPosBoard then
        RadarTaskUtils.InitRadarTaskBtnPosBoard()
    else
        for i = 1, #RadarTaskUtils.RadarTaskBtnPosBoard do
            for j = 1, #RadarTaskUtils.RadarTaskBtnPosBoard[i] do
                if RadarTaskUtils.CheckUnablePos(i, j) then
                    RadarTaskUtils.RadarTaskBtnPosBoard[i][j] = 1
                else
                    RadarTaskUtils.RadarTaskBtnPosBoard[i][j] = 0
                end
            end
        end
    end
end 

function RadarTaskUtils.CheckUnablePos(row, col)
    for k, v in pairs(UnablePosDic) do
        if row == v.row and col == v.col then
            return true
        end
    end
    return false
end

--计算圆心位置与原点的夹角(与y轴正方向的夹角)
function RadarTaskUtils.CalcAngleByPos(x, y)
    local angle = 0
    if x == 0 and y == 0 then
        return angle
    end
    angle = math.atan(y/x) * 180 / math.pi
    angle = angle - angle % 0.1     --保留一位小数
    if x >= 0 then
        angle = 90 - angle
    elseif x < 0 then
        angle = 270 - angle
    end
    return angle
end

--计算圆心位置与原点的圆切角
function RadarTaskUtils.CalcTangentAngleByPos(x, y)
    local dis = math.sqrt(x * x + y * y)
    --把圆心包裹在内时就默认返回10
    if dis < RadarTaskBtnRadius then
        return 10
    end
    local angle = math.asin(RadarTaskBtnRadius / dis) * 180 / math.pi * 2
    angle = angle - angle % 0.1     --保留一位小数
    return angle
end

---@param angle number
---@param targetAngle number
function RadarTaskUtils.CheckAngleInRange(angle, targetAngle)
    -- 上下8度误差
    return angle <= targetAngle + 4 and angle >= targetAngle - 4
end

return RadarTaskUtils;