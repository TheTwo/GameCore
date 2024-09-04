using UnityEngine;
using System;
using System.Reflection;
 
public class ReflectionTools
{
	public static void Call(string typeName, string methodName, params object[] args)
	{
		Call<object>(typeName, methodName, args);
	}
 
	public static T Call<T>(string typeName, string methodName, params object[] args)
	{
		Type type = Type.GetType(typeName);
		T defaultValue = default(T);
		if(null == type) return defaultValue;
        
		Type[] argTypes = new Type[args.Length];
		for(int i=0, count = args.Length; i< count; ++i)
		{
			argTypes[i] = null != args[i] ? args[i].GetType() : null;
		}
		MethodInfo method = type.GetMethod(methodName, BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic, null, argTypes, null);
		if(null == method)
		{
			Debug.LogError(string.Format("method {0} does not exist!",methodName));
			return defaultValue;
		}
		object result = method.Invoke(null, args);
		if(null == result)
			return defaultValue;
		if(!(result is T))
		{
			Debug.LogError(string.Format("method {0} cast failed!",methodName));
			return defaultValue;
		}
		return (T)result;
	}
}
