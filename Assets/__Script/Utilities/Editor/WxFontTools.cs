using System.Collections.Generic;
using System.IO;
using System.Net;
using UnityEditor;
using UnityEngine;

public class WxFontTools:MonoScript
{
    static WxFontTools()
    {
        
    }
    
    // 将当前场景上所有 Text 所在transform， 增加 WxFont 组件
    [MenuItem("WxFont/Add WxFont Component")]
    public static void AddWxFontComponent()
    {
        var texts = FindObjectsOfType<UnityEngine.UI.Text>();
        foreach (var text in texts)
        {
            if (text.GetComponent<WxFont>() == null)
            {
                text.gameObject.AddComponent<WxFont>();
            }
        }
    }
    
    // 读取文本文件，获取所有包含的字符
    [MenuItem("WxFont/Get All Characters")]
    public static void GetAllCharacters()
    {
        var result = new List<string>();
        var text = File.ReadAllText(Application.dataPath + "/Resources/language.json");
        foreach (var c in text)
        {
            // 判断字符编码为Unicode 添加 Unicode 字符
            if (c >= 0x4E00 && c <= 0x9FA5)
            {
                if (!result.Contains(c.ToString()))
                {
                    result.Add(c.ToString());
                }
            }
        }
        
        File.WriteAllText(Application.dataPath + "/Resources/characters.txt", string.Join("", result));
    }
    
    // 更改所有字体为 MFYueYuan_Noncommercial-Regular
    [MenuItem("WxFont/Change Font")]
    public static void ChangeFont()
    {
        var texts = FindObjectsOfType<UnityEngine.UI.Text>();
        foreach (var text in texts)
        {
            text.font = Resources.Load<Font>("MFYueYuan_Noncommercial-Regular");
        }
    }
}