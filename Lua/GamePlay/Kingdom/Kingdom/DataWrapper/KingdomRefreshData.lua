local ModuleRefer = require("ModuleRefer")

local MapHUDCreate = CS.Kingdom.MapHUDCreate
local ListCreate = CS.System.Collections.Generic.List(typeof(MapHUDCreate))
local ListInt64 = CS.System.Collections.Generic.List(typeof(CS.System.Int64))
local ListInt32 = CS.System.Collections.Generic.List(typeof(CS.System.Int32))
local ListString = CS.System.Collections.Generic.List(typeof(CS.System.String))
local ListBoolean = CS.System.Collections.Generic.List(typeof(CS.System.Boolean))
local ListColor = CS.System.Collections.Generic.List(typeof(CS.UnityEngine.Color))


---@class KingdomRefreshData
---
---@field hudManager CS.Kingdom.MapHUDManager
---@field staticMapData CS.Grid.StaticMapData
---
---@field creates CS.System.Collections.Generic.List(typeof(CS.Kingdom.MapHUDCreate))
---@field removes CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---
---@field refreshSpriteIDs CS.System.Collections.Generic.List(typeof(CS.System.Int64))
---@field refreshSpriteIndices CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---@field refreshSpriteNames CS.System.Collections.Generic.List(typeof(CS.System.String))
---@field refreshTextIDs CS.System.Collections.Generic.List(typeof(CS.System.Int64))
---@field refreshTextIndices CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---@field refreshTextContents CS.System.Collections.Generic.List(typeof(CS.System.String))
---@field refreshVisibleIDs CS.System.Collections.Generic.List(typeof(CS.System.Int64))
---@field refreshVisibleIndices CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---@field refreshVisibleStates CS.System.Collections.Generic.List(typeof(CS.System.Boolean))
---@field refreshColorIDs CS.System.Collections.Generic.List(typeof(CS.System.Int64))
---@field refreshColorIndices CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---@field refreshColors CS.System.Collections.Generic.List(typeof(CS.UnityEngine.Color))
---@field refreshClickIDs CS.System.Collections.Generic.List(typeof(CS.System.Int64))
---@field refreshClickIndices CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---
---@field spriteMaterialIDs CS.System.Collections.Generic.List(typeof(CS.System.Int64))
---@field spriteMaterialIndices CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---@field textMaterialIDs CS.System.Collections.Generic.List(typeof(CS.System.Int64))
---@field textMaterialIndices CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---@field matSprite CS.UnityEngine.Material
---@field matText CS.UnityEngine.Material
---@field fadeInSpriteMaterialIDs CS.System.Collections.Generic.List(typeof(CS.System.Int64))
---@field fadeInSpriteMaterialIndices CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---@field matFadeInSprite CS.UnityEngine.Material
---@field fadeInTextMaterialIDs CS.System.Collections.Generic.List(typeof(CS.System.Int64))
---@field fadeInTextMaterialIndices CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---@field matFadeInText CS.UnityEngine.Material
---@field fadeOutSpriteMaterialIDs CS.System.Collections.Generic.List(typeof(CS.System.Int64))
---@field fadeOutSpriteMaterialIndices CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---@field matFadeOutSprite CS.UnityEngine.Material
---@field fadeOutTextMaterialIDs CS.System.Collections.Generic.List(typeof(CS.System.Int64))
---@field fadeOutTextMaterialIndices CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---@field matFadeOutText CS.UnityEngine.Material
---
---@field dataRefreshed boolean
---@field dataRemoved boolean
---@field materialChanged boolean
local KingdomRefreshData = class("KingdomRefreshData")

function KingdomRefreshData:ctor()
    self.creates = ListCreate()
    self.removes = ListInt64()
    
    self.refreshSpriteIDs = ListInt64()
    self.refreshSpriteIndices = ListInt32()
    self.refreshSpriteNames = ListString()
    
    self.refreshTextIDs = ListInt64()
    self.refreshTextIndices = ListInt32()
    self.refreshTextContents = ListString()
    
    self.refreshVisibleIDs = ListInt64()
    self.refreshVisibleIndices = ListInt32()
    self.refreshVisibleStates = ListBoolean()

    self.refreshColorIDs = ListInt64()
    self.refreshColorIndices = ListInt32()
    self.refreshColors = ListColor()
    
    self.refreshClickIDs = ListInt64()
    self.refreshClickIndices = ListInt32()

    self.spriteMaterialIDs = ListInt64()
    self.spriteMaterialIndices = ListInt32()

    self.textMaterialIDs = ListInt64()
    self.textMaterialIndices = ListInt32()

    self.fadeInSpriteMaterialIDs = ListInt64()
    self.fadeInSpriteMaterialIndices = ListInt32()

    self.fadeInTextMaterialIDs = ListInt64()
    self.fadeInTextMaterialIndices = ListInt32()

    self.fadeOutSpriteMaterialIDs = ListInt64()
    self.fadeOutSpriteMaterialIndices = ListInt32()

    self.fadeOutTextMaterialIDs = ListInt64()
    self.fadeOutTextMaterialIndices = ListInt32()

end

---@param hudManager CS.Kingdom.MapHUDManager
---@param staticMapData CS.Grid.StaticMapData
function KingdomRefreshData:Initialize(hudManager, staticMapData)
    self.hudManager = hudManager
    self.staticMapData = staticMapData
end

function KingdomRefreshData:InitMaterials()
    self.matSprite = ModuleRefer.MapHUDModule.spriteECSMaterial
    self.matText = ModuleRefer.MapHUDModule.textECSMaterial
    self.matFadeInSprite = ModuleRefer.MapHUDModule.fadeInSpriteECSMaterial
    self.matFadeInText = ModuleRefer.MapHUDModule.fadeInTextECSMaterial
    self.matFadeOutSprite = ModuleRefer.MapHUDModule.fadeOutSpriteECSMaterial
    self.matFadeOutText = ModuleRefer.MapHUDModule.fadeOutTextECSMaterial
end

function KingdomRefreshData:Dispose()
    self.matSprite = nil
    self.matText = nil
    self.matFadeInSprite = nil
    self.matFadeInText = nil
    self.matFadeOutSprite = nil
    self.matFadeOutText = nil
    
    self.hudManager = nil 
    self.staticMapData = nil
end

function KingdomRefreshData:IsDataRefreshed()
    return self.dataRefreshed
end

function KingdomRefreshData:IsDataRemoved()
    return self.dataRemoved
end

function KingdomRefreshData:IsMaterialChanged()
    return self.materialChanged
end

function KingdomRefreshData:UpdateData()
    self.hudManager:AddOrUpdateHuds(self.creates)
    self.hudManager:SetNodeVisible(self.refreshVisibleIDs, self.refreshVisibleIndices, self.refreshVisibleStates)
    self.hudManager:SetColors(self.refreshColorIDs, self.refreshColorIndices, self.refreshColors)
    self.hudManager:UpdateSpriteData(self.refreshSpriteIDs, self.refreshSpriteIndices, self.refreshSpriteNames)
    self.hudManager:UpdateTextData(self.refreshTextIDs, self.refreshTextIndices, self.refreshTextContents)
    self.hudManager:SetClickCallback(self.refreshClickIDs, self.refreshClickIndices)
    self.dataRefreshed = false
end

function KingdomRefreshData:Remove()
    self.hudManager:RemoveHuds(self.removes)
    self.dataRemoved = false
end

function KingdomRefreshData:UpdateMaterials()
    self.hudManager:SetMaterials(self.spriteMaterialIDs, self.spriteMaterialIndices, self.matSprite)
    self.hudManager:SetMaterials(self.textMaterialIDs, self.textMaterialIndices, self.matText)
    self.hudManager:SetMaterials(self.fadeInSpriteMaterialIDs, self.fadeInSpriteMaterialIndices, self.matFadeInSprite)
    self.hudManager:SetMaterials(self.fadeInTextMaterialIDs, self.fadeInTextMaterialIndices, self.matFadeInText)
    self.hudManager:SetMaterials(self.fadeOutSpriteMaterialIDs, self.fadeOutSpriteMaterialIndices, self.matFadeOutSprite)
    self.hudManager:SetMaterials(self.fadeOutTextMaterialIDs, self.fadeOutTextMaterialIndices, self.matFadeOutText)
    self.materialChanged = false
end

function KingdomRefreshData:Refresh()
    self.hudManager:Tick()
end

---@param position CS.UnityEngine.Vector3
function KingdomRefreshData:CreateHUD(id, prefabName, position, dataLod)
    if string.IsNullOrEmpty(prefabName) then
        return false
    end
    
    local create = MapHUDCreate()
    create.ID = id
    create.X = position.x
    create.Y = position.y
    create.Z = position.z
    create.Prefab = prefabName
    create.Lod = dataLod
    self.creates:Add(create)
    self.dataRefreshed = true
    return true
end

function KingdomRefreshData:RemoveHUD(id)
    self.removes:Add(id)
    self.dataRemoved = true
end

function KingdomRefreshData:ClearRemoves()
    self.removes:Clear()
end

function KingdomRefreshData:ClearRefreshes()
    self.creates:Clear()
    self:ResetSprite()
    self:ResetText()
    self:ResetVisible()
    self:ResetColor()
    self:ResetClick()
end

function KingdomRefreshData:ClearMaterial()
    self.spriteMaterialIDs:Clear()
    self.spriteMaterialIndices:Clear()
    self.textMaterialIDs:Clear()
    self.textMaterialIndices:Clear()
    self.fadeInSpriteMaterialIDs:Clear()
    self.fadeInSpriteMaterialIndices:Clear()
    self.fadeInTextMaterialIDs:Clear()
    self.fadeInTextMaterialIndices:Clear()
    self.fadeOutSpriteMaterialIDs:Clear()
    self.fadeOutSpriteMaterialIndices:Clear()
    self.fadeOutTextMaterialIDs:Clear()
    self.fadeOutTextMaterialIndices:Clear()
end

function KingdomRefreshData:ResetSprite()
    self.refreshSpriteIDs:Clear()
    self.refreshSpriteIndices:Clear()
    self.refreshSpriteNames:Clear()
end

function KingdomRefreshData:ResetText()
    self.refreshTextIDs:Clear()
    self.refreshTextIndices:Clear()
    self.refreshTextContents:Clear()
end

function KingdomRefreshData:ResetVisible()
    self.refreshVisibleIDs:Clear()
    self.refreshVisibleIndices:Clear()
    self.refreshVisibleStates:Clear()
end

function KingdomRefreshData:ResetColor()
    self.refreshColorIDs:Clear()
    self.refreshColorIndices:Clear()
    self.refreshColors:Clear()
end

function KingdomRefreshData:ResetClick()
    self.refreshClickIDs:Clear()
    self.refreshClickIndices:Clear()
end


function KingdomRefreshData:SetActive(id, index, state)
    self.refreshVisibleIDs:Add(id)
    self.refreshVisibleIndices:Add(index)
    self.refreshVisibleStates:Add(state)
    self.dataRefreshed = true
end

function KingdomRefreshData:SetColor(id, index, color)
    self.refreshColorIDs:Add(id)
    self.refreshColorIndices:Add(index)
    self.refreshColors:Add(color)
    self.dataRefreshed = true
end

function KingdomRefreshData:SetSprite(id, index, sprite)
    self.refreshSpriteIDs:Add(id)
    self.refreshSpriteIndices:Add(index)
    self.refreshSpriteNames:Add(sprite)
    self.dataRefreshed = true
end

function KingdomRefreshData:SetText(id, index, content)
    self.refreshTextIDs:Add(id)
    self.refreshTextIndices:Add(index)
    self.refreshTextContents:Add(tostring(content))
    self.dataRefreshed = true
end

function KingdomRefreshData:SetClick(id, index)
    self.refreshClickIDs:Add(id)
    self.refreshClickIndices:Add(index)
    self.dataRefreshed = true
end

function KingdomRefreshData:SetSpriteStay(id, index)
    self.spriteMaterialIDs:Add(id)
    self.spriteMaterialIndices:Add(index)
    self.materialChanged = true
end

function KingdomRefreshData:SetTextStay(id, index)
    self.textMaterialIDs:Add(id)
    self.textMaterialIndices:Add(index)
    self.materialChanged = true
end

function KingdomRefreshData:SetSpriteFadeIn(id, index)
    self.fadeInSpriteMaterialIDs:Add(id)
    self.fadeInSpriteMaterialIndices:Add(index)
    self.materialChanged = true
end

function KingdomRefreshData:SetTextFadeIn(id, index)
    self.fadeInTextMaterialIDs:Add(id)
    self.fadeInTextMaterialIndices:Add(index)
    self.materialChanged = true
end

function KingdomRefreshData:SetSpriteFadeOut(id, index)
    self.fadeOutSpriteMaterialIDs:Add(id)
    self.fadeOutSpriteMaterialIndices:Add(index)
    self.materialChanged = true
end

function KingdomRefreshData:SetTextFadeOut(id, index)
    self.fadeOutTextMaterialIDs:Add(id)
    self.fadeOutTextMaterialIndices:Add(index)
    self.materialChanged = true
end


return KingdomRefreshData