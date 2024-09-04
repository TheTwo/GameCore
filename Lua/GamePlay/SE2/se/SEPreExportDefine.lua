local SEPreExportDefineConst = require("SEPreExportDefineConst")
local ConfigRefer = require("ConfigRefer")

---@class SEPreExportDefine
local SEPreExportDefine = {}

SEPreExportDefine.CLICK_MOVE_THRESHOLD = 1

SEPreExportDefine.ROTATE_ANGLE_PER_SECOND = (ConfigRefer.ConstSe.SETurnSpeed and ConfigRefer.ConstSe:SETurnSpeed()) or 720

SEPreExportDefine.WARMUP_ASSET_UI_GRAY = SEPreExportDefineConst.WARMUP_ASSET_UI_GRAY
SEPreExportDefine.WARMUP_ASSET_MAT_PET_FRESNEL_02 = SEPreExportDefineConst.WARMUP_ASSET_MAT_PET_FRESNEL_02
SEPreExportDefine.WARMUP_ASSET_MAT_PET_FRESNEL_03 = SEPreExportDefineConst.WARMUP_ASSET_MAT_PET_FRESNEL_03
SEPreExportDefine.WARMUP_ASSET_MAT_PET_FRESNEL_05_RED = SEPreExportDefineConst.WARMUP_ASSET_MAT_PET_FRESNEL_05_RED

return SEPreExportDefine