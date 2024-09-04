---
--- Created by wupei. DateTime: 2022/2/24
---

local BuffClientEnum = {
    RunningState = {
        NotRunning = 0,
        Running = 1,
        End = 2,
    },
    Stage = {
        Add = "Add",
        Persist = "Persist",
        End = "End",
        Logic = "Logic",
    }
}
return BuffClientEnum
