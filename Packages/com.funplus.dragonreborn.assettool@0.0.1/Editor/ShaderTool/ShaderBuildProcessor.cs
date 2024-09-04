// #define ENABLE_LOG_SHADER_VARIANTS
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEditor.Build;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Rendering;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	public class ShaderBuildProcessor : IPreprocessShaders
	{
		public int callbackOrder => -1;

		/// <summary>
		/// Implement this interface to receive a callback before a shader snippet is compiled.
		/// </summary>
		/// <param name="shader">Shader that is being compiled.</param>
		/// <param name="snippet">Details about the specific shader code being compiled.</param>
		/// <param name="inputData">List of variants to be compiled for the specific shader code.</param>
		public void OnProcessShader(Shader shader, ShaderSnippetData snippet, IList<ShaderCompilerData> inputData)
		{
			// 剔除shader变体
			if (shader.name.Contains("TerrainEngine") 
				|| shader.name.Contains("Universal Render Pipeline/Terrain")
				|| shader.name.Contains("Universal Render Pipeline/Lit")
				|| shader.name.Contains("Hidden/Nature")
				)
			{
				inputData.Clear();
				return;
			}
			
			for (int i = inputData.Count - 1; i >= 0; i--)
			{
				ShaderCompilerData input = inputData[i];
				//Global And Local Keyword
				// if (input.shaderKeywordSet.IsEnabled(new ShaderKeyword("_ADDITIONAL_LIGHT_SHADOWS")) || input.shaderKeywordSet.IsEnabled(new ShaderKeyword(shader, "_ADDITIONAL_LIGHT_SHADOWS")))
				// {
				// 	inputData.RemoveAt(i);
				// }
			}
		}
	}
}

