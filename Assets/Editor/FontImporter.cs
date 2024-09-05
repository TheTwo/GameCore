using UnityEngine;
using System.Collections;
using UnityEditor;
using System.Collections.Generic;

public class FontImporter : MonoBehaviour
{
   
    [MenuItem("Tools/LogAllLanguage")]
    public static void LogAllLanguage()
    {
        Localization.Init();
        
        string result = "~=+:1234567890";
        
        foreach (KeyValuePair<string, string[]> pair in Localization.LocalizationDic)
        {
            result += pair.Value [0] + pair.Value [1];
        }
        
        Debug.Log(result);
        
        TrueTypeFontImporter importer = TrueTypeFontImporter.GetAtPath("Assets/Font/MFYueYuan_Noncommercial-Regular.otf") as TrueTypeFontImporter;
        importer.customCharacters = result;
        importer.SaveAndReimport();
    }
   
}
