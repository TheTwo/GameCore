#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using DragonReborn;
using XLua;

namespace XLua
{
    public class CheckLuaStackTraceException
    {
        private static readonly string FrameArgsRegex = "\\s?\\(.*\\)";
        private static readonly string FrameRegexWithoutFileInfo = "(?<class>[^\\s]+)\\.(?<method>[^\\s\\.]+)" + FrameArgsRegex;
        private static readonly string FrameRegexWithFileInfo = FrameRegexWithoutFileInfo + " .*[/|\\\\](?<file>.+):(?<line>\\d+)";
        private static readonly string MonoFilenameUnknownString = "<filename unknown>";
        private static readonly string[] StringDelimiters = new string[1]
        {
            Environment.NewLine
        };
    
        public static void Test(LuaStackTraceException e)
        {
            var ex = ParseStackTraceString(e.StackTrace);
            
            var strArray = e.StackTrace.Split(StringDelimiters, StringSplitOptions.None);
            if (strArray.Length > ex.Length)
            {
                UnityEngine.Debug.LogWarning("Not Every LuaException StackTrace Formation Matches");
            }

            if (strArray.Length > 0 && ex.Length == 0)
            {
                UnityEngine.Debug.LogError("All LuaException StackTrace Formation Doesn't Match");
            }
        }

        public static Dictionary<string, string>[] ParseStackTraceString(string stackTrace)
        {
            List<Dictionary<string, string>> dictionaryList = new List<Dictionary<string, string>>();
            string[] strArray = stackTrace.Split(StringDelimiters, StringSplitOptions.None);
            if (strArray.Length < 1)
                return dictionaryList.ToArray();
            foreach (string str in strArray)
            {
                string regex;
                if (Regex.Matches(str, FrameRegexWithFileInfo).Count == 1)
                    regex = FrameRegexWithFileInfo;
                else if (Regex.Matches(str, FrameRegexWithoutFileInfo).Count == 1)
                    regex = FrameRegexWithoutFileInfo;
                else
                    continue;
                Dictionary<string, string> frameString = ParseFrameString(regex, str);
                if (frameString != null)
                    dictionaryList.Add(frameString);
            }
            return dictionaryList.ToArray();
        }
        
        private static Dictionary<string, string> ParseFrameString(
            string regex,
            string frameString)
        {
            MatchCollection matchCollection = Regex.Matches(frameString, regex);
            if (matchCollection.Count < 1)
                return (Dictionary<string, string>) null;
            Match match = matchCollection[0];
            if (!match.Groups["class"].Success || !match.Groups["method"].Success)
                return (Dictionary<string, string>) null;
            string str1 = !match.Groups["file"].Success ? match.Groups["class"].Value : match.Groups["file"].Value;
            string str2 = !match.Groups["line"].Success ? "0" : match.Groups["line"].Value;
            if (str1 == MonoFilenameUnknownString)
            {
                str1 = match.Groups["class"].Value;
                str2 = "0";
            }
            return new Dictionary<string, string>()
            {
                {
                    "class",
                    match.Groups["class"].Value
                },
                {
                    "method",
                    match.Groups["method"].Value
                },
                {
                    "file",
                    str1
                },
                {
                    "line",
                    str2
                }
            };
        }
    }
}
#endif