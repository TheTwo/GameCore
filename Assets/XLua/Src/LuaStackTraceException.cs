using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace XLua
{
    [Serializable]
    public class LuaStackTraceException : Exception
    {
        private const string FrameMessageRegex = @"\b(?<file>.+):(?<line>\d+):(?<message> .*)";
        private const string FrameFunctionRegex = @"(?<file>[^\s]*):(?<line>\d+): in (?:function|global|local|metamethod)(?<method>.*)";
        private const string FrameRegexCSharpCall = @"\s?\[C\]: in method ['""](?<method>.*)['""]";

        private readonly string[] StringDelimiters = new string[]
        {
            Environment.NewLine,
        };
        
        public LuaStackTraceException(string message) : base(message)
        {
            
        }

        public LuaStackTraceException(string message, Exception innerException) : base(message, innerException)
        {
	        
        }

        // /// <summary>
        // /// 使Firebase能够区分Lua的报错堆栈，使用LuaException Message重构StackTrace
        // /// </summary>
        public override string StackTrace
        {
            get
            {
                var luaStackTrace = GetLuaStackTrace(Message);
                return luaStackTrace + Environment.NewLine + base.StackTrace;
            }
        }

        /// <summary>
        /// 重建Lua层的报错堆栈
        /// </summary>
        /// <param name="message">LuaException Message</param>
        /// <returns></returns>
        private string GetLuaStackTrace(string message)
        {
            var list = new List<string>();
            var strArray = message.Split(StringDelimiters, StringSplitOptions.None);
            if (strArray.Length < 1)
                return string.Empty;

            foreach (var frame in strArray)
            {
                string regex;
                if (Regex.Matches(frame, FrameFunctionRegex).Count == 1)
                    regex = FrameFunctionRegex;
                else
                    continue;

                string simulateFrame = ParseLuaFrameString(frame, regex);
                if (simulateFrame != null)
                    list.Add(simulateFrame);
            }
            return string.Join(Environment.NewLine, list);
        }

        /// <summary>
        /// 解析Lua栈帧
        /// </summary>
        /// <param name="frame">栈帧</param>
        /// <param name="regex">匹配模式</param>
        /// <returns></returns>
        private string ParseLuaFrameString(string frame, string regex)
        {
            MatchCollection matchCollection = Regex.Matches(frame, regex);
            if (matchCollection.Count < 1)
                return string.Empty;
            Match match = matchCollection[0];
            Dictionary<string, string> map = new Dictionary<string, string>()
            {
                {"file", match.Groups["file"].Value},
                {"line", match.Groups["line"].Value},
                {"method", match.Groups["method"].Value},
            };

            var file = GetFileNameFromMatch(map["file"]);
            var line = map["line"];
            var cls = file;
            var method = GetMethodFromMatch(map["method"]) ?? "__method_at_"+line;
#if UNITY_EDITOR
            string[] search = {"Assets/__Lua"};
            var realPath = UnityEditor.AssetDatabase.FindAssets(file, search);
            if (realPath.Length > 0)
            {
                var path = UnityEditor.AssetDatabase.GUIDToAssetPath(realPath[0]);
                return $"{cls}.{method}(...) (at {path}:{line})";
            }
#endif
            return $"{cls}.{method}(...) __Lua/{file}:{line}";
        }

        private string GetFileNameFromMatch(string oriFile)
        {
            const char value = '\"';
            if (oriFile.IndexOf(value) == -1)
            {
                return oriFile;
            }

            return oriFile.Substring(oriFile.IndexOf(value) + 1, oriFile.LastIndexOf(value) - oriFile.IndexOf(value) - 1);
        }

        private const string RegexWithFunctionName = @"(?<name>\w+)\.(?<method>\w+)";
        private const string RegexWithLineNum = @"(?<name>\w+):(?<line>\d+)";

        private string GetMethodFromMatch(string oriMethod)
        {
            var match = Regex.Match(oriMethod, RegexWithFunctionName);
            if (match.Success)
            {
                return match.Groups["method"].Value;
            }

            match = Regex.Match(oriMethod, RegexWithLineNum);
            if (match.Success)
            {    
                return "__method_at_" + match.Groups["line"].Value;
            }

            return null;
        }
    }
}
