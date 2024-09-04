-- local AllianceActivityDataProviderDefine = require("AllianceActivityDataProviderDefine")
-- local ConfigRefer = require("ConfigRefer")
-- local ArtResourceUtils = require("ArtResourceUtils")
-- local ModuleRefer = require("ModuleRefer")
-- local Delegate = require("Delegate")
-- local I18N = require("I18N")
-- local TimeFormatter = require("TimeFormatter")
-- local UIMediatorNames = require("UIMediatorNames")
-- local DBEntityType = require('DBEntityType')

-- local AllianceActivityCellData = require("AllianceActivityCellData")

-- ---@class AllianceActivityCellDataWorldEventBig:AllianceActivityCellData
-- ---@field super AllianceActivityCellData
-- ---@field new fun(id:number, battleData:wds.AllianceActivityBattleInfo)
-- local AllianceActivityCellDataWorldEventBig = class("AllianceActivityCellDataWorldEventBig", AllianceActivityCellData)

-- ---@param id number
-- ---@param battleData wds.AllianceActivityBattleInfo
-- function AllianceActivityCellDataWorldEventBig:ctor(id, battleData)
--     AllianceActivityCellDataWorldEventBig.super.ctor(self, id)
--     ---@type wds.AllianceActivityBattleInfo
--     self._battleData = battleData
--     self._cell = nil
-- end


-- function AllianceActivityCellDataWorldEventBig.GetSoureType()
--     return AllianceActivityDataProviderDefine.SourceType.AllianceExpeditionBig
-- end

-- ---@param cell AllianceWarActivityCell
-- function AllianceActivityCellDataWorldEventBig:OnCellEnter(cell)
--     self._cell = cell
--     local expeditionId = self._battleData.ExpeditionConfigId
--     local cfg = ConfigRefer.WorldExpeditionTemplate:Find(expeditionId)
--     self.isBigEvent = ModuleRefer.WorldEventModule:IsAllianceBigWorldEvent(expeditionId)
--     local entity = g_Game.DatabaseManager:GetEntity(self._battleData.ExpeditionEntityId, DBEntityType.Expedition)
--     local smallIcon = ModuleRefer.WorldEventModule:GetWorldEventPanelEventIconByEntity(entity)
--     g_Game.SpriteManager:LoadSprite(smallIcon, cell._p_icon_event_type)
--     g_Game.SpriteManager:LoadSprite(cfg:WorldTaskIcon(), cell._p_icon_event)

--     cell:ResetCell()
--     cell._p_text_event_name.text = I18N.Get(cfg:Name())
--     cell._p_text_event_desc.text = I18N.GetWithParams("alliance_assemble_coordinate_center", math.floor(self._battleData.BornPos.X), math.floor(self._battleData.BornPos.Y))
--     cell._p_btn_goto:SetVisible(true)
--     cell._p_text_event_status_desc_1:SetVisible(true)

--     local needAccept = entity.ExpeditionInfo.State == wds.ExpeditionState.ExpeditionNotice
--     if self.isBigEvent and needAccept then
--         cell._p_progress_event:SetVisible(false)
--         cell._p_text_event_status_desc_1.text = I18N.Get("alliance_assemble_wrold_get")
--     else
--         if self.isBigEvent then
--             local curValue = entity.ExpeditionInfo.Progress
--             local maxValue = 100
--             cell._p_progress_event.value = math.clamp01(curValue / maxValue)
--         else
--             local progress = entity.ExpeditionInfo.PersonalProgress[ModuleRefer.PlayerModule:GetPlayer().ID] or 0
--             local percent = math.clamp(progress / cfg:MaxProgress(), 0, 1)
--             cell._p_progress_event.value = percent
--             cell._p_text_event_status_desc_1.text = I18N.GetWithParams("alliance_assemble_wrold_schedule", percent * 100)
--         end
--         cell._p_progress_event:SetVisible(true)
--     end
-- end

-- ---@param cell AllianceWarActivityCell
-- function AllianceActivityCellDataWorldEventBig:OnCellExit(cell)
-- end

-- function AllianceActivityCellDataWorldEventBig:OnClickBtnPosition()
-- end

-- function AllianceActivityCellDataWorldEventBig:OnClickBtnGoto()
--     --Activity Center Tab Id
--     local cfgId = self.isBigEvent and 8 or ModuleRefer.WorldEventModule:GetPersonalOwnAllianceExpedition()
--     ModuleRefer.ActivityCenterModule:GotoActivity(cfgId)
--     if cfgId == nil then
--         ModuleRefer.ToastModule:AddSimpleToast("# ActivityCenterTab Id not found")
--         return
--     end
--     ModuleRefer.ActivityCenterModule:GotoActivity(cfgId)
-- end

-- function AllianceActivityCellDataWorldEventBig:SecTick(dt)
-- end

-- return AllianceActivityCellDataWorldEventBig
