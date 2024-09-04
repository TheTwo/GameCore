---@class AStarAI
---@field new fun():AStarAI
local AStarAI = class("AStarAI")
local Delegate = require("Delegate")

function AStarAI:ctor()
    self.currentWaypoint = 0
    self.reachedEndOfPath = false
end

function AStarAI:Awake()
    self.trans = self.behaviour.transform
    self.seeker = self.behaviour.gameObject:GetComponent(typeof(CS.Pathfinding.Seeker))
end

function AStarAI:SeekPath(target, callback)
    self.callback = callback
    self.seeker:StartPath(self.trans.position, target, Delegate.GetOrCreate(self, self.OnPathComplete))
end

---@param path CS.Pathfinding.Path
function AStarAI:OnPathComplete(path)
    if not path.error then
        self.path = path
        self.reachedEndOfPath = 0
    end
end

function AStarAI:Update()
    if self.path == nil then
        return
    end

    local lastPos = self.trans.position
    self.reachedEndOfPath = false
    while true do
        local distanceToWaypoint = CS.UnityEngine.Vector3.Distance(lastPos, self.path.vectorPath[self.currentWaypoint])
        if distanceToWaypoint < self.nextWaypointDistance then
            if self.currentWaypoint + 1 < self.path.vectorPath.Count then
                self.currentWaypoint = self.currentWaypoint + 1
            else
                self.reachedEndOfPath = true
                break
            end
        else
            break
        end
    end
    
    local curTarget = self.path.vectorPath[self.currentWaypoint]
    if self.reachedEndOfPath then
        self.trans.position = CS.UnityEngine.Vector3.MoveTowards(lastPos, curTarget, self.speed * g_Game.Time.deltaTime)
        if CS.UnityEngine.Vector3.Distance(self.trans.position, curTarget) < self.nextWaypointDistance then
            if self.callback then
                self.callback()
            end
            self.path = nil
        end
    else
        local offset = curTarget - lastPos
        local velocity = offset.normalized * self.speed    
        self.trans.position = lastPos + velocity * g_Game.Time.deltaTime
    end
end

return AStarAI