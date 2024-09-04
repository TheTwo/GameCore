local UpdateAOIParameter = require("UpdateAOIParameter")

---@class RequestServiceBase
local RequestServiceBase = class("RequestServiceBase")

---@param mapSystem CS.Grid.MapSystem
function RequestServiceBase:Initialize(mapSystem)
    --子类重载此函数
end

function RequestServiceBase:Release()
    --子类重载此函数
end

---@param mapRequest CS.Grid.MapRequest
function RequestServiceBase:Send(mapRequest)
    local min = mapRequest.Min
    local max = mapRequest.Max
    local lod = mapRequest.Lod
    local leftBottom = mapRequest.LeftBottom
    local leftTop = mapRequest.LeftTop
    local rightTop = mapRequest.RightTop
    local rightBottom = mapRequest.RightBottom
    
    local param = UpdateAOIParameter.new()
    param.args.Lod = lod
    param.args.MinPos = wds.Vector3F.New(min.X, min.Y)
    param.args.MaxPos = wds.Vector3F.New(max.X, max.Y)
    if not mapRequest.IsEmpty then
        param.args.CpPoints:Add(wds.Vector3F.New(leftBottom.X, leftBottom.Y))
        param.args.CpPoints:Add(wds.Vector3F.New(leftTop.X, leftTop.Y))
        param.args.CpPoints:Add(wds.Vector3F.New(rightTop.X, rightTop.Y))
        param.args.CpPoints:Add(wds.Vector3F.New(rightBottom.X, rightBottom.Y))
    end

    param:Send()
end

return RequestServiceBase