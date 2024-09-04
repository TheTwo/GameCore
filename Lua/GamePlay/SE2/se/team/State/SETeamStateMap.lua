local SETeamStateMap = {
    Names = {
        Idle = "SETeamStateIdle",
        Move = "SETeamStateMove",
    },

    StateMap = {
        SETeamStateIdle = require("SETeamStateIdle"),
        SETeamStateMove = require("SETeamStateMove"),
    }
}
return SETeamStateMap