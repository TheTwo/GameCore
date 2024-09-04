using UnityEditor;

namespace DragonReborn
{
    public static class LuaHintExporte
    {
        [MenuItem("DragonReborn/本地生成/3. 生成 Lua 提示 %#&H", false, 3)]
        public static void DoExport()
        {
            ConfigReferExporter.GenerateConfigReferV3();
            ModuleReferExporter.GenerateModuleRefer();
            EmmyLuaCfgExporter.GenerateCfgJson();
            // Generator.DoGenerate();
        }
    }
}