using System.Reflection;
using DG.Tweening;
using DragonReborn;
using UnityEngine;

#if UNITY_EDITOR
[MarkDomainReloading(nameof(DoCleanUp))]
#endif
// ReSharper disable once CheckNamespace
public static class DomainReloading
{
#if UNITY_EDITOR
    // 禁用域重载，处理游戏内的静态字段和静态事件
    // refer: https://docs.unity.cn/cn/2020.3/Manual/DomainReloading.html
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
    private static void Init()
    {
	    DoCleanUp();
    }

    private static void DoCleanUp()
    {
	    // 遍历 Singleton<> 子类，调用 DestroyInstance 方法
	    var assemblies = new string[] { "Assembly-CSharp"}; //, "Assembly-CSharp-firstpass" , "Funplus.DragonReborn.Runtime", "Funplus.DragonReborn.UIFramework.Runtime","Funplus.DragonReborn.GestureManager"};

	    foreach (var assembly in assemblies)
	    {
		    var types = Assembly.Load(assembly).GetTypes();

		    foreach (var type in types)
		    {
			    var baseType = type.BaseType; //获取元素类型的基类
			    if (baseType != null) //如果有基类
			    {
				    if (baseType.Name == typeof(Singleton<>).Name) //如果基类就是给定的父类
				    {
					    var method = type.GetMethod("DestroyInstance",
						    BindingFlags.FlattenHierarchy | BindingFlags.Static | BindingFlags.Public);
					    if (method != null)
					    {
						    method.Invoke(null, null);
					    }
				    }
			    }
		    }
	    }
		
	    // 通过反射设置 DoTween isQuitting 属性为 false
	    var dotween = typeof(DOTween);
	    var fild = dotween.GetField("isQuitting", BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static);
	    if (fild != null)
	    {
		    fild.SetValue(null, false);
	    }

	    DOTween.useSafeMode = true;

	    FrameworkInterfaceManager.Reset();

	    var needCallMethods = UnityEditor.TypeCache.GetMethodsWithAttribute<DomainReloadingCleanupAttribute>();
	    foreach (var needCallMethod in needCallMethods)
	    {
		    if (!needCallMethod.IsStatic) continue;
		    needCallMethod.Invoke(null, null);
	    }
    }
#endif 
}