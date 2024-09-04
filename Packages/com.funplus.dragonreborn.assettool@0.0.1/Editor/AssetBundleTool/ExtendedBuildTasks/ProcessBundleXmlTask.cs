using System.Collections.Generic;
using System.IO;
using UnityEditor.Build.Pipeline;
using UnityEditor.Build.Pipeline.Injector;
using UnityEditor.Build.Pipeline.Interfaces;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	/// <summary>
	/// 将构建bundle 生成的link.xml 移动到指定位置， 用于构建APK/IPA stripCode时 保护被资源引用的到类型的代码
	/// </summary>
    public class ProcessBundleXmlTask : IBuildTask
    {
        private readonly string _targetPath;
        // ReSharper disable once InconsistentNaming
        private const string k_LinkXml = "link.xml";

        private ProcessBundleXmlTask(string targetPath)
        {
            _targetPath = targetPath;
        }

        public static bool AddToBuildTasks(IList<IBuildTask> buildTasks, string targetPath)
        {
            if (null == buildTasks) return false;
            if (string.IsNullOrWhiteSpace(targetPath)) return false;
            for (int i = buildTasks.Count - 1; i >= 0; i--)
            {
                var task = buildTasks[i];
                if (task is ProcessBundleXmlTask)
                {
                    buildTasks.RemoveAt(i);
                    break;
                }
            }
            for (var i = buildTasks.Count - 1; i >= 0; i--)
            {
                var task = buildTasks[i];
                if (task is UnityEditor.Build.Pipeline.Tasks.GenerateLinkXml)
                {
                    buildTasks.Insert(i + 1, new ProcessBundleXmlTask(targetPath));
                    return true;
                }
            }
            return false;
        }
        
#pragma warning disable 649
        [InjectContext(ContextUsage.In)]
        // ReSharper disable once InconsistentNaming
        // ReSharper disable once ArrangeTypeMemberModifiers
        IBuildParameters m_Parameters;
#pragma warning restore 649

        ReturnCode IBuildTask.Run()
        {
            if (!m_Parameters.WriteLinkXML)
                return ReturnCode.SuccessNotRun;
            var linkPath = m_Parameters.GetOutputFilePathForIdentifier(k_LinkXml);
            if (!File.Exists(linkPath)) return ReturnCode.MissingRequiredObjects;
            File.Copy(linkPath, _targetPath, true);
            File.Delete(linkPath);
            return ReturnCode.Success;
        }

        int IBuildTask.Version => 1;
    }
}
