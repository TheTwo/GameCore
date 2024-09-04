using UnityEditor;

namespace DragonReborn
{
    public static class ClassNameCapture
    {
        [MenuItem("CONTEXT/Component/Copy Full Class Name")]
        static void GetClassName(MenuCommand cmd)
        {
            var type = cmd.context.GetType();
            var fullName = type.FullName;
            UnityEngine.GUIUtility.systemCopyBuffer = "CS." + fullName;
        }
    }
}