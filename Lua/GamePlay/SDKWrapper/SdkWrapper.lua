
---@class SdkWrapper 
local SdkWrapper = sealedClass('SdkWrapper')

---@generic T:CS.SdkAdapter.SdkModelWrapper
---@param sdkModuleType T
---@return boolean, T
function SdkWrapper.TryGetSdkModule(sdkModuleType)
    return CS.SdkAdapter.SdkWrapper.Instance:GetByType(typeof(sdkModuleType)) 
end

return SdkWrapper
