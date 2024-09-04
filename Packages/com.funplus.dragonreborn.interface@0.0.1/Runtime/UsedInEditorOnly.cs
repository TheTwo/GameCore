#if UNITY_EDITOR
// ReSharper disable CheckNamespace
using System;
[AttributeUsage(AttributeTargets.Class, AllowMultiple = false, Inherited = false)]
public class MarkDomainReloadingAttribute : Attribute
{
	public readonly string CleanUpMethodName;

	public MarkDomainReloadingAttribute(string cleanUpMethodName)
	{
		CleanUpMethodName = cleanUpMethodName;
	}
}
#endif