local CityStateDefault = require("CityStateDefault")
local CityStateEnterRadar = class("CityStateEnterRadar", CityStateDefault)

function CityStateEnterRadar:Enter()
    CityStateDefault.Enter(self)
end

function CityStateEnterRadar:Exit()
    CityStateDefault.Exit(self)
end

function CityStateEnterRadar:OnClick()

end

function CityStateEnterRadar:OnClickTrigger()

end

return CityStateEnterRadar