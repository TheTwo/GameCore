using System;
using System.Reflection;
using UnityEngine;
using UnityEngine.Rendering;

namespace __Script.Utilities
{
    public static class ShaderUtils
    {
        public static readonly Func<Shader, string, int> GetShaderKeywordIndex;
        public static readonly Func<Shader, int> GetShaderKeywordCount;

        public static bool IsShaderHasKeyWord(Shader shader, string keyWord)
        {
            return GetShaderKeywordIndex(shader, keyWord) < GetShaderKeywordCount(shader);
        }

        static ShaderUtils()
        {
            Func<Shader, string, int> f = (_, _) => -1;
            MethodInfo method;
            try
            {
                method = typeof(LocalKeyword).GetMethod(nameof(GetShaderKeywordIndex),
                    BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
                if (method != null)
                    f =
                        (Func<Shader, string, int>)Delegate.CreateDelegate(typeof(Func<Shader, string, int>), method);
            }
            finally
            {
                GetShaderKeywordIndex = f;
            }
            Func<Shader, int> f2 = _ => -1;
            try
            {
                method = typeof(LocalKeyword).GetMethod(nameof(GetShaderKeywordCount),
                    BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
                if (method != null)
                    f2 =
                        (Func<Shader, int>)Delegate.CreateDelegate(typeof(Func<Shader, int>), method);
            }
            finally
            {
                GetShaderKeywordCount = f2;
            }
        }
    }
}