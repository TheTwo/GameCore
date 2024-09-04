local WarningToolsForDesigner = {}

function WarningToolsForDesigner.DisplayEditorDialog(title, message, ok)
    if not UNITY_EDITOR then return end

    if CS.LogicRepoUtils.IsSsrLogicRepoExist() then return end

    if string.IsNullOrEmpty(title) and string.IsNullOrEmpty(message) then return end
    local _title = title or "系统错误"
    local _message = message or "系统错误"
    local _ok = ok or "确认"

    return CS.UnityEditor.EditorUtility.DisplayDialog(_title, _message, _ok)
end

WarningToolsForDesigner.NotifyEditorGameView = nil
WarningToolsForDesigner.GameViewType = nil

function WarningToolsForDesigner.DisplayGameViewAndSceneViewNotification(message)
    if not UNITY_EDITOR then return end
    if string.IsNullOrEmpty(message) then return end
    if not WarningToolsForDesigner.GameViewType then
        WarningToolsForDesigner.GameViewType = typeof(CS.UnityEditor.EditorWindow).Assembly:GetType("UnityEditor.GameView")
    end
    if not WarningToolsForDesigner.GameViewType then return end
    local gameViews = CS.UnityEngine.Resources.FindObjectsOfTypeAll(WarningToolsForDesigner.GameViewType)
    if not gameViews or gameViews.Length <= 0 then return end
    local messageContent = CS.UnityEngine.GUIContent(message)
    for i = 0, gameViews.Length - 1 do
        gameViews[i]:ShowNotification(messageContent)
    end
end

return WarningToolsForDesigner