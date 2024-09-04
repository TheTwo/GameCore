// #define ENABLE_LOG_SHADER_VARIANTS
using System.Collections.Generic;
using UnityEditor.Build;
using UnityEditor.Rendering;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	public interface IShaderFinalProcessorLogger
	{
		void AppendLog(string logInfo);
	}

	public class ShaderFinalProcessor : IPreprocessShaders
	{

		public static IShaderFinalProcessorLogger RedirectLogger;
		
		public int callbackOrder => 99;

		/// <summary>
		/// Implement this interface to receive a callback before a shader snippet is compiled.
		/// </summary>
		/// <param name="shader">Shader that is being compiled.</param>
		/// <param name="snippet">Details about the specific shader code being compiled.</param>
		/// <param name="inputData">List of variants to be compiled for the specific shader code.</param>
		public void OnProcessShader(Shader shader, ShaderSnippetData snippet, IList<ShaderCompilerData> inputData)
		{
			var shaderName = shader.name;
			var passName = snippet.passName;
			var index = 0;
			if (inputData.Count > 0)
			{
				foreach (var compilerData in inputData)
				{
					var shaderKeywordSet = compilerData.shaderKeywordSet;
					var shaderKeywordSetKeywords = shaderKeywordSet.GetShaderKeywords();
					var keywords = new List<string>();
					foreach (var shaderKeyword in shaderKeywordSetKeywords)
					{
						keywords.Add(shaderKeyword.name);
					}
					var keywordsCombine = string.Join(";", keywords.ToArray());
					var logInfo =
						$"ShaderFinalProcessor: {shaderName}, Pass {passName}, Keywords_{index++} {keywordsCombine}";
					if (null != RedirectLogger)
						RedirectLogger.AppendLog(logInfo);
					else
						NLogger.Log(logInfo);
				}
			}
			else
			{
				var logInfo = $"ShaderFinalProcessor: {shaderName}, Pass {passName}, None";
				if (null != RedirectLogger)
					RedirectLogger.AppendLog(logInfo);
				else
					NLogger.Log(logInfo);
			}
		}
	}
}

