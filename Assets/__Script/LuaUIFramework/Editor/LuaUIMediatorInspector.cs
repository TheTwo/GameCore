using UnityEditor;
namespace DragonReborn.UI.Editor
{
   #if USE_XLUA
   [CustomEditor(typeof(LuaUIMediator),true)]
   public class LuaUIMediatorInspector : UnityEditor.Editor
   {
      private LuaUIMediator editorObj = null;
      private void OnEnable()
      {
         editorObj = target as LuaUIMediator;
      }
      
      public override void OnInspectorGUI()
      {
         
         base.OnInspectorGUI();
         LuaBaseComponentEditorUtility.OnInspectorGUI(editorObj );
      }

      
   }
   #endif
}
