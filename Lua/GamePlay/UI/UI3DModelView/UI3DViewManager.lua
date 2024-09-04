local ShadowDistanceControl = require('ShadowDistanceControl')
local KingdomMapUtils = require("KingdomMapUtils")
local CameraConst = require('CameraConst')
local UI3DViewConst = require('UI3DViewConst')
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")

---@class UI3DViewerParam
---@field envPath string
---@field shadowDistance number
---@field shadowCascades number
---@field type number @UI3DViewManager.TroopViewType
---@field preCallback fun(viewer:UI3DAbstractView) @callback when viewer is Created
---@field callback fun(viewer:UI3DAbstractView) @callback when Env is Loaded
---@field useShadowPiece boolean

---@class UI3DViewerManager
---@field ui3DRoot UI3DRoot
---@field curViewer UI3DAbstractView
local UI3DViewManager = class("UI3DViewerManager")

function UI3DViewManager:ctor()
    self.ui3DViewrPool = {}
    self.viewDataStack = {}
    self.viewDataStackTop = 0
    self.ui3DRoot = nil
    self.curViewer = nil
end

function UI3DViewManager:Init()
     ---@type CS.DragonReborn.AssetTool.GameObjectCreateHelper
     local creater = CS.DragonReborn.AssetTool.GameObjectCreateHelper.Create()
     creater:Create(ManualResourceConst.ui3d_root, nil,function(go)
        if go then
            ---@type UI3DRoot
            self.ui3DRoot = go:GetLuaBehaviour('UI3DRoot').Instance
        end
     end,0,true)
end

---@param runtimeId number @runtimeId of an UIMediator
---@param viewerType number @UI3DViewType
---@param data UI3DViewerParam
---@param inPlaceId number @若相同则替换直接栈顶
function UI3DViewManager:OpenUI3DView(runtimeId,viewerType,data, inPlaceId)
    if not self.ui3DRoot or not data then return nil end
    local shadowDistance = data.shadowDistance or 48
    local shadowCascades = data.shadowCascades or 1

    CS.RenderPiplineUtil.SetShadowDistance(shadowDistance)
    ShadowDistanceControl.ChangeShadowCascades(shadowCascades)

    if self.viewDataStackTop > 0 then
        local curViewData = self.viewDataStack[self.viewDataStackTop]
        if inPlaceId and inPlaceId == curViewData.inPlaceId then
            self.viewDataStack[self.viewDataStackTop] = {
                runtimeId = runtimeId,
                viewerType = viewerType,
                data = data,
                loadingState = 0,
                inPlaceId = inPlaceId
            }
        else
            local hasSame = false
            for i = 1, self.viewDataStackTop do
                if self.viewDataStack[i].runtimeId == runtimeId then
                    hasSame = true
                    self.viewDataStack[i].data = data
                    break
                end
            end

            if not hasSame then
                self.viewDataStackTop = self.viewDataStackTop + 1
                self.viewDataStack[self.viewDataStackTop] = {
                    runtimeId = runtimeId,
                    viewerType = viewerType,
                    data = data,
                    loadingState = 0,
                    inPlaceId = inPlaceId
                }
            end
        end
    else
        self.viewDataStackTop = self.viewDataStackTop + 1
        self.viewDataStack[self.viewDataStackTop] = {
            runtimeId = runtimeId,
            viewerType = viewerType,
            data = data,
            loadingState = 0,
            inPlaceId = inPlaceId
        }
    end

    if self.curViewer and self.curViewer:GetType() == viewerType then
        self.viewDataStack[self.viewDataStackTop].loadingState = 2
        self.curViewer:SetVisible(true)
        self.curViewer:FeedData(data)
        self.ui3DRoot:Enable()
    else
        if self.curViewer then
            self.curViewer:Clear()
            self.curViewer:SetVisible(false)
            self.curViewer = nil
        end

        if self.ui3DViewrPool[viewerType] then
            self.viewDataStack[self.viewDataStackTop].loadingState = 2
            self.curViewer = self.ui3DViewrPool[viewerType]
            self.curViewer:SetVisible(true)
            self.curViewer:FeedData(data)
            self.ui3DRoot:Enable()
        else

            local ui3dViewName = nil

            if viewerType == UI3DViewConst.ViewType.ModelViewer then
                ui3dViewName = "UI3DModelView"
            elseif viewerType == UI3DViewConst.ViewType.TroopViewer then
                ui3dViewName = "UI3DTroopModelView"
            end
            if self._creater then
                self._creater:CancelAllCreate()
                self._creater = nil
            end
            self.viewDataStack[self.viewDataStackTop].loadingState = 1
            local viewStackIndex = self.viewDataStackTop
            ---@type CS.DragonReborn.AssetTool.GameObjectCreateHelper
            self._creater = require(ui3dViewName).CreateViewer(self.ui3DRoot:Transform(),function(go)
                if not go then
                    --g_Logger.ErrorChannel("UI3DViewManager","OpenUI3DView failed, go is nil")
                    if self.viewDataStack[viewStackIndex].data and self.viewDataStack[viewStackIndex].data.callback then
                        self.viewDataStack[viewStackIndex].data.callback(nil)
                    end
                    return
                end
                self.curViewer = go:GetLuaBehaviour(ui3dViewName).Instance
                if not self.curViewer then
                    --g_Logger.ErrorChannel("UI3DViewManager","OpenUI3DView failed, Can not Find LuaBehaviour:" .. ui3dViewName)
                    if self.viewDataStack[viewStackIndex].data and self.viewDataStack[viewStackIndex].data.callback then
                        self.viewDataStack[viewStackIndex].data.callback(nil)
                    end
                    return
                end

                if self.curViewer:GetType() ~= viewerType then
                    if self.viewDataStack[viewStackIndex].data and self.viewDataStack[viewStackIndex].data.callback then
                        self.viewDataStack[viewStackIndex].data.callback(nil)
                    end
                    return
                end
                self.viewDataStack[viewStackIndex].loadingState = 2
                self.curViewer:Init(self.ui3DRoot)
                self.ui3DViewrPool[self.curViewer:GetType()] = self.curViewer
                self.curViewer:SetVisible(true)
                self.curViewer:FeedData(data)
                self.ui3DRoot:Enable()
                self._creater = nil
            end)
        end
    end
end


function UI3DViewManager:CloseUI3DView(runtimeId)
    -- if not self.curViewer then
    --     return
    -- end

    if self.viewDataStackTop > 0 then
        local curViewData = self.viewDataStack[self.viewDataStackTop]
        if curViewData and curViewData.runtimeId == runtimeId then
            self.viewDataStack[self.viewDataStackTop] = nil
            self.viewDataStackTop = self.viewDataStackTop - 1
            if curViewData.loadingState < 2 then
                if self._creater then
                    self._creater:CancelAllCreate()
                    self._creater = nil
                end
            end
            if self.viewDataStackTop > 0 then
                local viewData = self.viewDataStack[self.viewDataStackTop]
                self:OpenUI3DView(viewData.runtimeId,viewData.viewerType,viewData.data)
                return
            end
        else
            return
        end
    end

    --CS.RenderPiplineUtil.SetShadowDistance(70)
    local scene = g_Game.SceneManager.current
    if scene ~= nil then
        local basicCamera = scene.basicCamera
        if basicCamera then
            local cameraSize = basicCamera:GetSize()
            if scene.IsInCity and scene:IsInCity() then
                scene.stateMachine:GetCurrentState():OnSizeChanged(cameraSize, cameraSize)
            else
                local sizeList = KingdomMapUtils.GetCameraLodData().mapCameraSizeList
                local shadowDistanceList = KingdomMapUtils.GetCameraLodData().mapShadowDistanceList
                ShadowDistanceControl.SetEnable(true)
                ShadowDistanceControl.RefreshShadow(basicCamera.mainCamera, cameraSize, sizeList, shadowDistanceList, CameraConst.MapShadowCascadeSizeThreshold)
            end
        end
    end
    if self.curViewer then
        self.curViewer:Clear()
        self.curViewer:SetVisible(false)
    end
    self.ui3DRoot:Disable()
    self.curViewer = nil

	Utils.FullGC()
end

function UI3DViewManager:CloseAllViewer()
end

function UI3DViewManager:Clear()
     if self.ui3DRoot then
        local go = self.ui3DRoot:GameObject()
        if go then
            CS.UnityEngine.GameObject.Destroy(go)
        end
        self.ui3DRoot = nil
    end
end


-- ---@private
-- ---@param modelPath string
-- ---@param envPath string
-- ---@param backgroundTexName string
-- ---@param callback fun(viewer:UI3DModelView)
-- function UIManager:SetupUIModeViewInternal(modelPath,envPath,backgroundTexName, callback)
--     if not self.modelViewer.behaviour.gameObject.activeSelf then
--         self.modelViewer.behaviour.gameObject:SetActive(true)
--     end
--     self.modelViewer:Init(self.ui3DRoot)
--     if not envPath then
--         self.modelViewer:SetupDefaultBack(backgroundTexName)
--         self.modelViewer:SetupModel(modelPath, callback)
--         self.ui3DRoot:Enable()
--     else
--         self.modelViewer:SetupEnv(envPath, function()
--             self.modelViewer:SetupModel(modelPath, callback)
--             self.ui3DRoot:Enable()
--         end)
--     end
-- end

function UI3DViewManager:UICam3D()
    if self.ui3DRoot then
        return self.ui3DRoot.UICam3D
    end
end

function UI3DViewManager:SetRenderShadow(enable)
    self:UICam3D():GetUniversalAdditionalCameraData().renderShadows = enable
end

function UI3DViewManager:InitCameraTransform(cameraSetting)
    local camera = self:UICam3D()
    if cameraSetting.fov then
        camera.fieldOfView = cameraSetting.fov
    end
    if cameraSetting.nearCp then
        camera.nearClipPlane = cameraSetting.nearCp
    end
    if cameraSetting.farCp then
        camera.farClipPlane = cameraSetting.farCp
    end
    if  cameraSetting.localPos then
        camera.transform.localPosition = cameraSetting.localPos
    end
    if cameraSetting.rotation then
        camera.transform.localEulerAngles = cameraSetting.rotation
    end
end

function UI3DViewManager:IsEnabled()
    if self.ui3DRoot then
        return self.ui3DRoot:IsEnabled()
    end
    return false
end

function UI3DViewManager:Enable()
    if self.ui3DRoot then
        self.ui3DRoot:Enable()
    end
end

function UI3DViewManager:Disable()
    if self.ui3DRoot then
        self.ui3DRoot:Disable()
    end
end

function UI3DViewManager:GetBackgroundBounds(gameObject)
    if self.ui3DRoot then
        return self.ui3DRoot:GetBackgroundBounds(gameObject)
    end
end

return UI3DViewManager
