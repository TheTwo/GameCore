---@class UnmanagedMemoryEecoder
local UnmanagedMemoryEecoder = {}

---@param data table | CS.DragonReborn.SLG.Troop.TroopData
function UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopData(data)
	local size = 72
	size = size + 4
	if data.heroName and #data.heroName > 0 then 
		size = size + #data.heroName * 4
	end
	size = size + 4
	if data.heroScale and #data.heroScale > 0 then 
		size = size + #data.heroScale * 4
	end
	size = size + 4
	if data.heroOffset and #data.heroOffset > 0 then 
		size = size + #data.heroOffset * 8
	end
	size = size + 4
	if data.heroBattleOffset and #data.heroBattleOffset > 0 then 
		size = size + #data.heroBattleOffset * 8
	end
	size = size + 4
	if data.heroType and #data.heroType > 0 then 
		size = size + #data.heroType * 4
	end
	size = size + 4
	if data.heroState and #data.heroState > 0 then 
		size = size + #data.heroState * 4
	end
	size = size + 4
	if data.heroNormalAtkId and #data.heroNormalAtkId > 0 then 
		size = size + #data.heroNormalAtkId * 4
	end
	size = size + 4
	if data.petName and #data.petName > 0 then 
		size = size + #data.petName * 4
	end
	size = size + 4
	if data.petScale and #data.petScale > 0 then 
		size = size + #data.petScale * 4
	end
	size = size + 4
	if data.petOffset and #data.petOffset > 0 then 
		size = size + #data.petOffset * 8
	end
	size = size + 4
	if data.petBattleOffset and #data.petBattleOffset > 0 then 
		size = size + #data.petBattleOffset * 8
	end
	size = size + 4
	if data.petState and #data.petState > 0 then 
		size = size + #data.petState * 4
	end
	size = size + 4
	if data.petNormalAtkId and #data.petNormalAtkId > 0 then 
		size = size + #data.petNormalAtkId * 4
	end
	return size
end


---@param data table | CS.DragonReborn.SLG.Troop.TroopViewManager.TroopSkillData
function UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopViewManager_TroopSkillData(data)
	local size = 164
	size = size + UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopViewManager_TroopSkillFloatingTextParam(data.skillName)
	size = size + 4
	if data.targetInfo and #data.targetInfo > 0 then 
		for i = 1, #data.targetInfo do
			size = size + UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopViewManager_TroopSkillTargetInfo(data.targetInfo[i])
		end
	end
	size = size + 4
	if data.moveInfo and #data.moveInfo > 0 then 
		for i = 1, #data.moveInfo do
			size = size + UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopViewManager_TroopSkillMovementInfo(data.moveInfo[i])
		end
	end
	return size
end


---@param data table | CS.DragonReborn.SLG.Troop.TroopViewManager.TroopSkillFloatingTextParam
function UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopViewManager_TroopSkillFloatingTextParam(data)
	local size = 30
	return size
end


---@param data table | CS.DragonReborn.SLG.Troop.TroopViewManager.TroopSkillTargetInfo
function UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopViewManager_TroopSkillTargetInfo(data)
	local size = 12
	size = size + 4
	if data.losses and #data.losses > 0 then 
		for i = 1, #data.losses do
			size = size + UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopViewManager_TroopSkillFloatingTextParam(data.losses[i])
		end
	end
	size = size + 4
	if data.buffInfos and #data.buffInfos > 0 then 
		for i = 1, #data.buffInfos do
			size = size + UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopViewManager_TroopSkillBuffInfo(data.buffInfos[i])
		end
	end
	return size
end


---@param data table | CS.DragonReborn.SLG.Troop.TroopViewManager.TroopSkillBuffInfo
function UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopViewManager_TroopSkillBuffInfo(data)
	local size = 20
	size = size + UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopViewManager_TroopSkillFloatingTextParam(data.info)
	return size
end


---@param data table | CS.DragonReborn.SLG.Troop.TroopViewManager.TroopSkillMovementInfo
function UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopViewManager_TroopSkillMovementInfo(data)
	local size = 20
	return size
end


---@param data table | CS.DragonReborn.SLG.Troop.TroopViewManager.TroopRoundData
function UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopViewManager_TroopRoundData(data)
	local size = 20
	size = size + 4
	if data.infos and #data.infos > 0 then 
		for i = 1, #data.infos do
			size = size + UnmanagedMemoryEecoder.MemsizeDragonReborn_SLG_Troop_TroopViewManager_TroopSkillFloatingTextParam(data.infos[i])
		end
	end
	size = size + 4
	if data.heroIndexes and #data.heroIndexes > 0 then 
		size = size + #data.heroIndexes * 4
	end
	size = size + 4
	if data.heroStates and #data.heroStates > 0 then 
		size = size + #data.heroStates * 4
	end
	size = size + 4
	if data.petIndexes and #data.petIndexes > 0 then 
		size = size + #data.petIndexes * 4
	end
	size = size + 4
	if data.petStates and #data.petStates > 0 then 
		size = size + #data.petStates * 4
	end
	return size
end


---@param data table | CS.DragonReborn.SLG.Troop.TroopData
---@param memPtr number @memory Ptr
---@param stringCache {uid:number,stringList:string[]}
function UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopData(memPtr,data,stringCache)
	if not memPtr then return end
	if data then
		Unmanaged.WriteByte(memPtr,1)
	else
		Unmanaged.WriteByte(memPtr,0)
		return
	end
	Unmanaged.WriteInt64(memPtr,data.id or 0)
	Unmanaged.WriteInt32(memPtr,data.serverType or 0)
	Unmanaged.WriteInt32(memPtr,data.heroAIType or 0)
	Unmanaged.WriteInt32(memPtr,data.troopType or 0)
if data.position then
	Unmanaged.WriteFloat(memPtr,data.position.x)
	Unmanaged.WriteFloat(memPtr,data.position.y)
	Unmanaged.WriteFloat(memPtr,data.position.z)
else
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
end
if data.direction then
	Unmanaged.WriteFloat(memPtr,data.direction.x)
	Unmanaged.WriteFloat(memPtr,data.direction.y)
	Unmanaged.WriteFloat(memPtr,data.direction.z)
else
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
end
	Unmanaged.WriteFloat(memPtr,data.moveSpeed or 0)
	Unmanaged.WriteFloat(memPtr,data.rotateSpeed or 0)
	Unmanaged.WriteFloat(memPtr,data.radius or 0)
	if not data.heroName then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.heroName)
		for i = 1,#data.heroName do
			if data.heroName[i] then
		Unmanaged.WriteInt32(memPtr,stringCache.uid)
		stringCache.stringList[stringCache.uid + 1] = data.heroName[i]
		stringCache.uid = stringCache.uid + 1
	else
		Unmanaged.WriteInt32(memPtr,-1)
	end
		end
	end
	if not data.heroScale then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.heroScale)
		for i = 1,#data.heroScale do
			Unmanaged.WriteFloat(memPtr,data.heroScale[i] or 0)
		end
	end
	if not data.heroOffset then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.heroOffset)
		for i = 1,#data.heroOffset do
		if data.heroOffset[i] then
	Unmanaged.WriteFloat(memPtr,data.heroOffset[i].x)
	Unmanaged.WriteFloat(memPtr,data.heroOffset[i].y)
else
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
end
		end
	end
	if not data.heroBattleOffset then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.heroBattleOffset)
		for i = 1,#data.heroBattleOffset do
		if data.heroBattleOffset[i] then
	Unmanaged.WriteFloat(memPtr,data.heroBattleOffset[i].x)
	Unmanaged.WriteFloat(memPtr,data.heroBattleOffset[i].y)
else
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
end
		end
	end
	if not data.heroType then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.heroType)
		for i = 1,#data.heroType do
			Unmanaged.WriteInt32(memPtr,data.heroType[i] or 0)
		end
	end
	if not data.heroState then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.heroState)
		for i = 1,#data.heroState do
			Unmanaged.WriteInt32(memPtr,data.heroState[i] or 0)
		end
	end
	if not data.heroNormalAtkId then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.heroNormalAtkId)
		for i = 1,#data.heroNormalAtkId do
			Unmanaged.WriteInt32(memPtr,data.heroNormalAtkId[i] or 0)
		end
	end
	if not data.petName then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.petName)
		for i = 1,#data.petName do
			if data.petName[i] then
		Unmanaged.WriteInt32(memPtr,stringCache.uid)
		stringCache.stringList[stringCache.uid + 1] = data.petName[i]
		stringCache.uid = stringCache.uid + 1
	else
		Unmanaged.WriteInt32(memPtr,-1)
	end
		end
	end
	if not data.petScale then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.petScale)
		for i = 1,#data.petScale do
			Unmanaged.WriteFloat(memPtr,data.petScale[i] or 0)
		end
	end
	if not data.petOffset then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.petOffset)
		for i = 1,#data.petOffset do
		if data.petOffset[i] then
	Unmanaged.WriteFloat(memPtr,data.petOffset[i].x)
	Unmanaged.WriteFloat(memPtr,data.petOffset[i].y)
else
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
end
		end
	end
	if not data.petBattleOffset then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.petBattleOffset)
		for i = 1,#data.petBattleOffset do
		if data.petBattleOffset[i] then
	Unmanaged.WriteFloat(memPtr,data.petBattleOffset[i].x)
	Unmanaged.WriteFloat(memPtr,data.petBattleOffset[i].y)
else
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
end
		end
	end
	if not data.petState then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.petState)
		for i = 1,#data.petState do
			Unmanaged.WriteInt32(memPtr,data.petState[i] or 0)
		end
	end
	if not data.petNormalAtkId then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.petNormalAtkId)
		for i = 1,#data.petNormalAtkId do
			Unmanaged.WriteInt32(memPtr,data.petNormalAtkId[i] or 0)
		end
	end
	Unmanaged.WriteInt32(memPtr,data.layerMask or 0)
	Unmanaged.WriteFloat(memPtr,data.attackRange or 0)
	Unmanaged.WriteByte(memPtr,data.simpleMode and 1 or 0)
	Unmanaged.WriteByte(memPtr,data.syncUnitStateOff and 1 or 0)
end


---@param data table | CS.DragonReborn.SLG.Troop.TroopViewManager.TroopSkillData
---@param memPtr number @memory Ptr
---@param stringCache {uid:number,stringList:string[]}
function UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopViewManager_TroopSkillData(memPtr,data,stringCache)
	if not memPtr then return end
	if data then
		Unmanaged.WriteByte(memPtr,1)
	else
		Unmanaged.WriteByte(memPtr,0)
		return
	end
	Unmanaged.WriteInt64(memPtr,data.skillId or 0)
	Unmanaged.WriteInt64(memPtr,data.actorId or 0)
	Unmanaged.WriteInt32(memPtr,data.heroIndex or 0)
	Unmanaged.WriteInt32(memPtr,data.petIndex or 0)
	Unmanaged.WriteInt64(memPtr,data.targetId or 0)
	Unmanaged.WriteInt32(memPtr,data.targetHeroIndex or 0)
	Unmanaged.WriteInt32(memPtr,data.targetPetIndex or 0)
	Unmanaged.WriteInt32(memPtr,data.priority or 0)
	Unmanaged.WriteInt32(memPtr,data.stageType or 0)
	Unmanaged.WriteInt32(memPtr,data.skillConfigId or 0)
	Unmanaged.WriteInt32(memPtr,data.skillType or 0)
	UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopViewManager_TroopSkillFloatingTextParam(memPtr,data.skillName,stringCache)
if data.releasePosition then
	Unmanaged.WriteFloat(memPtr,data.releasePosition.x)
	Unmanaged.WriteFloat(memPtr,data.releasePosition.y)
	Unmanaged.WriteFloat(memPtr,data.releasePosition.z)
else
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
end
if data.releaseDirection then
	Unmanaged.WriteFloat(memPtr,data.releaseDirection.x)
	Unmanaged.WriteFloat(memPtr,data.releaseDirection.y)
	Unmanaged.WriteFloat(memPtr,data.releaseDirection.z)
else
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
end
if data.targetPosition then
	Unmanaged.WriteFloat(memPtr,data.targetPosition.x)
	Unmanaged.WriteFloat(memPtr,data.targetPosition.y)
	Unmanaged.WriteFloat(memPtr,data.targetPosition.z)
else
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
end
	Unmanaged.WriteInt32(memPtr,data.camShake or 0)
	Unmanaged.WriteInt32(memPtr,data.camNoise or 0)
if data.camMoveExtents then
	Unmanaged.WriteFloat(memPtr,data.camMoveExtents.x)
	Unmanaged.WriteFloat(memPtr,data.camMoveExtents.y)
	Unmanaged.WriteFloat(memPtr,data.camMoveExtents.z)
else
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
end
if data.camRotateExtents then
	Unmanaged.WriteFloat(memPtr,data.camRotateExtents.x)
	Unmanaged.WriteFloat(memPtr,data.camRotateExtents.y)
	Unmanaged.WriteFloat(memPtr,data.camRotateExtents.z)
else
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
end
	Unmanaged.WriteFloat(memPtr,data.camSpeed or 0)
	Unmanaged.WriteFloat(memPtr,data.camDuration or 0)
	if not data.targetInfo then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.targetInfo)
		for i = 1,#data.targetInfo do
			UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopViewManager_TroopSkillTargetInfo(memPtr,data.targetInfo[i],stringCache)
		end
	end
	if not data.moveInfo then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.moveInfo)
		for i = 1,#data.moveInfo do
			UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopViewManager_TroopSkillMovementInfo(memPtr,data.moveInfo[i],stringCache)
		end
	end
	Unmanaged.WriteInt32(memPtr,data.rangeType or 0)
	if data.rangeVfxPath then
		Unmanaged.WriteInt32(memPtr,stringCache.uid)
		stringCache.stringList[stringCache.uid + 1] = data.rangeVfxPath
		stringCache.uid = stringCache.uid + 1
	else
		Unmanaged.WriteInt32(memPtr,-1)
	end
if data.rangeVfxScale then
	Unmanaged.WriteFloat(memPtr,data.rangeVfxScale.x)
	Unmanaged.WriteFloat(memPtr,data.rangeVfxScale.y)
	Unmanaged.WriteFloat(memPtr,data.rangeVfxScale.z)
else
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
end
	Unmanaged.WriteFloat(memPtr,data.rangeOffset or 0)
	Unmanaged.WriteFloat(memPtr,data.rangeVfxDuration or 0)
	Unmanaged.WriteFloat(memPtr,data.rangeVfxSpeed or 0)
end


---@param data table | CS.DragonReborn.SLG.Troop.TroopViewManager.TroopSkillFloatingTextParam
---@param memPtr number @memory Ptr
---@param stringCache {uid:number,stringList:string[]}
function UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopViewManager_TroopSkillFloatingTextParam(memPtr,data,stringCache)
	if not memPtr then return end
	if data then
		Unmanaged.WriteByte(memPtr,1)
	else
		Unmanaged.WriteByte(memPtr,0)
		return
	end
	Unmanaged.WriteInt32(memPtr,data.type or 0)
	Unmanaged.WriteInt32(memPtr,data.style or 0)
	Unmanaged.WriteInt32(memPtr,data.intValue or 0)
	if data.strValue then
		Unmanaged.WriteInt32(memPtr,stringCache.uid)
		stringCache.stringList[stringCache.uid + 1] = data.strValue
		stringCache.uid = stringCache.uid + 1
	else
		Unmanaged.WriteInt32(memPtr,-1)
	end
	Unmanaged.WriteFloat(memPtr,data.duration or 0)
if data.offset then
	Unmanaged.WriteFloat(memPtr,data.offset.x)
	Unmanaged.WriteFloat(memPtr,data.offset.y)
	Unmanaged.WriteFloat(memPtr,data.offset.z)
else
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
end
end


---@param data table | CS.DragonReborn.SLG.Troop.TroopViewManager.TroopSkillTargetInfo
---@param memPtr number @memory Ptr
---@param stringCache {uid:number,stringList:string[]}
function UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopViewManager_TroopSkillTargetInfo(memPtr,data,stringCache)
	if not memPtr then return end
	if data then
		Unmanaged.WriteByte(memPtr,1)
	else
		Unmanaged.WriteByte(memPtr,0)
		return
	end
	Unmanaged.WriteInt64(memPtr,data.targetId or 0)
	if not data.losses then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.losses)
		for i = 1,#data.losses do
			UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopViewManager_TroopSkillFloatingTextParam(memPtr,data.losses[i],stringCache)
		end
	end
	if not data.buffInfos then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.buffInfos)
		for i = 1,#data.buffInfos do
			UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopViewManager_TroopSkillBuffInfo(memPtr,data.buffInfos[i],stringCache)
		end
	end
	Unmanaged.WriteInt32(memPtr,data.spState or 0)
end


---@param data table | CS.DragonReborn.SLG.Troop.TroopViewManager.TroopSkillBuffInfo
---@param memPtr number @memory Ptr
---@param stringCache {uid:number,stringList:string[]}
function UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopViewManager_TroopSkillBuffInfo(memPtr,data,stringCache)
	if not memPtr then return end
	if data then
		Unmanaged.WriteByte(memPtr,1)
	else
		Unmanaged.WriteByte(memPtr,0)
		return
	end
	Unmanaged.WriteInt32(memPtr,data.buffId or 0)
	if data.vfxPath then
		Unmanaged.WriteInt32(memPtr,stringCache.uid)
		stringCache.stringList[stringCache.uid + 1] = data.vfxPath
		stringCache.uid = stringCache.uid + 1
	else
		Unmanaged.WriteInt32(memPtr,-1)
	end
	Unmanaged.WriteFloat(memPtr,data.yOffset or 0)
	Unmanaged.WriteFloat(memPtr,data.scale or 0)
	Unmanaged.WriteInt32(memPtr,data.buffState or 0)
	UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopViewManager_TroopSkillFloatingTextParam(memPtr,data.info,stringCache)
end


---@param data table | CS.DragonReborn.SLG.Troop.TroopViewManager.TroopSkillMovementInfo
---@param memPtr number @memory Ptr
---@param stringCache {uid:number,stringList:string[]}
function UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopViewManager_TroopSkillMovementInfo(memPtr,data,stringCache)
	if not memPtr then return end
	if data then
		Unmanaged.WriteByte(memPtr,1)
	else
		Unmanaged.WriteByte(memPtr,0)
		return
	end
	Unmanaged.WriteInt64(memPtr,data.targetId or 0)
if data.targetPosition then
	Unmanaged.WriteFloat(memPtr,data.targetPosition.x)
	Unmanaged.WriteFloat(memPtr,data.targetPosition.y)
	Unmanaged.WriteFloat(memPtr,data.targetPosition.z)
else
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
end
end


---@param data table | CS.DragonReborn.SLG.Troop.TroopViewManager.TroopRoundData
---@param memPtr number @memory Ptr
---@param stringCache {uid:number,stringList:string[]}
function UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopViewManager_TroopRoundData(memPtr,data,stringCache)
	if not memPtr then return end
	if data then
		Unmanaged.WriteByte(memPtr,1)
	else
		Unmanaged.WriteByte(memPtr,0)
		return
	end
	Unmanaged.WriteInt64(memPtr,data.troopId or 0)
if data.position then
	Unmanaged.WriteFloat(memPtr,data.position.x)
	Unmanaged.WriteFloat(memPtr,data.position.y)
	Unmanaged.WriteFloat(memPtr,data.position.z)
else
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
	Unmanaged.WriteFloat(memPtr,0)
end
	if not data.infos then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.infos)
		for i = 1,#data.infos do
			UnmanagedMemoryEecoder.Encode_DragonReborn_SLG_Troop_TroopViewManager_TroopSkillFloatingTextParam(memPtr,data.infos[i],stringCache)
		end
	end
	if not data.heroIndexes then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.heroIndexes)
		for i = 1,#data.heroIndexes do
			Unmanaged.WriteInt32(memPtr,data.heroIndexes[i] or 0)
		end
	end
	if not data.heroStates then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.heroStates)
		for i = 1,#data.heroStates do
			Unmanaged.WriteInt32(memPtr,data.heroStates[i] or 0)
		end
	end
	if not data.petIndexes then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.petIndexes)
		for i = 1,#data.petIndexes do
			Unmanaged.WriteInt32(memPtr,data.petIndexes[i] or 0)
		end
	end
	if not data.petStates then
		Unmanaged.WriteInt32(memPtr,0)
	else
		Unmanaged.WriteInt32(memPtr,#data.petStates)
		for i = 1,#data.petStates do
			Unmanaged.WriteInt32(memPtr,data.petStates[i] or 0)
		end
	end
end

return UnmanagedMemoryEecoder
