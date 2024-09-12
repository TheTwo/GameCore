using UnityEngine;
using System.Collections.Generic;
using Pathfinding.Serialization.JsonFx;

public class Localization
{
    private static bool inited;

    public class Source
    {
        public Dictionary<string, string[]> LocalizationDic = new Dictionary<string, string[]>();
    }

    private static Source source;

    private static int language = 0;

    public static Dictionary<string, string[]> LocalizationDic;

    public static string GetLanguage(string key)
    {
        if (!inited)
        {
            Init();
            inited = true;
        }

        if (LocalizationDic.ContainsKey(key))
        {
            return LocalizationDic [key] [language];
        }
        else
        {
            Debug.LogWarning("no key of : " + key);
            return "no key of : " + key;
        }
    }

    public static void Init()
    {
        string sourceString = Resources.Load<TextAsset>("language").ToString();
         
        LocalizationDic = JsonReader.Deserialize<Source>(sourceString).LocalizationDic;
    }


}
