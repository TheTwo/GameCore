using System;
using System.CodeDom;
using Microsoft.CSharp;

// ReSharper disable once CheckNamespace
namespace DragonReborn.CSharpReflectionTool
{
    public static class ReflectionTypeNameHelper
    {
        public static string TypeNameToHandWriteFormat(this Type type)
        {
            using (var p = new CSharpCodeProvider())
            {
                var r = new CodeTypeReference(type);
                return p.GetTypeOutput(r);
            }
        }
    }
}

