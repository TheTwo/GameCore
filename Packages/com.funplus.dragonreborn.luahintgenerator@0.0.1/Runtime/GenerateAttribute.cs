using System;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    /// <summary>
    /// 
    /// </summary>
    [System.Diagnostics.Conditional("UNITY_EDITOR")]
    public class GenerateLuaHintAttribute : Attribute
    {
    }
    
    [System.Diagnostics.Conditional("UNITY_EDITOR")]
    public class GenerateLuaHintIgnoreType : Attribute
    {
    }
    
    [System.Diagnostics.Conditional("UNITY_EDITOR")]
    [AttributeUsage(AttributeTargets.Field)]
    public class GenerateLuaHintIgnoreGetter : Attribute
    {
    }
    
    [System.Diagnostics.Conditional("UNITY_EDITOR")]
	[AttributeUsage(AttributeTargets.Method, AllowMultiple = true)]
    public class ManuelWriteLibraryFunctionAttribute : Attribute
    {
	    public readonly string LibGlobalName;
	    public readonly string FunctionName;
	    public readonly (Type, string)[] ParameterPairs;
	    public readonly Type[] ReturnType;
		public readonly bool UseStringType;
		public readonly (string, string)[]ParameterStrPairs;
		public readonly string[] ReturnTypeStr;

	    public ManuelWriteLibraryFunctionAttribute(string libGlobalName, string functionName, Type returnType = null)
	    {
		    LibGlobalName = libGlobalName;
		    FunctionName = functionName;
		    ParameterPairs = Array.Empty<(Type, string)>();
		    ReturnType = returnType == null ? Array.Empty<Type>() : new []{returnType};
	    }
	    
	    public ManuelWriteLibraryFunctionAttribute(string libGlobalName, string functionName, Type par0Type, string par0Name, Type returnType = null)
	    {
		    LibGlobalName = libGlobalName;
		    FunctionName = functionName;
		    ParameterPairs = new[] { (par0Type, par0Name) };
		    ReturnType = returnType == null ? Array.Empty<Type>() : new []{returnType};
	    }
	    
	    public ManuelWriteLibraryFunctionAttribute(string libGlobalName, string functionName, Type par0Type, string par0Name, Type par1Type, string par1Name, Type returnType = null)
	    {
		    LibGlobalName = libGlobalName;
		    FunctionName = functionName;
		    ParameterPairs = new[] { (par0Type, par0Name), (par1Type, par1Name) };
		    ReturnType = returnType == null ? Array.Empty<Type>() : new []{returnType};
	    }
	    
	    public ManuelWriteLibraryFunctionAttribute(string libGlobalName, string functionName, Type par0Type, string par0Name, Type par1Type, string par1Name, Type par2Type, string par2Name, Type returnType = null)
	    {
		    LibGlobalName = libGlobalName;
		    FunctionName = functionName;
		    ParameterPairs = new[] { (par0Type, par0Name), (par1Type, par1Name), (par2Type, par2Name) };
		    ReturnType = returnType == null ? Array.Empty<Type>() : new []{returnType};
	    }
	    
	    public ManuelWriteLibraryFunctionAttribute(string libGlobalName, string functionName, Type par0Type, string par0Name, Type par1Type, string par1Name, Type par2Type, string par2Name, Type par3Type, string par3Name, Type returnType = null)
	    {
		    LibGlobalName = libGlobalName;
		    FunctionName = functionName;
		    ParameterPairs = new[] { (par0Type, par0Name), (par1Type, par1Name), (par2Type, par2Name), (par3Type, par3Name) };
		    ReturnType = returnType == null ? Array.Empty<Type>() : new []{returnType};
	    }
	    
	    public ManuelWriteLibraryFunctionAttribute(string libGlobalName, string functionName, Type par0Type, string par0Name, Type par1Type, string par1Name, Type par2Type, string par2Name, Type returnType0, Type returnType1)
	    {
		    LibGlobalName = libGlobalName;
		    FunctionName = functionName;
		    ParameterPairs = new[] { (par0Type, par0Name), (par1Type, par1Name), (par2Type, par2Name) };
		    ReturnType = new []{returnType0, returnType1};
	    }
	    
	    public ManuelWriteLibraryFunctionAttribute(string libGlobalName, string functionName
		    , Type par0Type, string par0Name
		    , Type par1Type, string par1Name
		    , Type par2Type, string par2Name
		    , Type par3Type, string par3Name
		    , Type par4Type, string par4Name
		    , Type par5Type, string par5Name
		    , Type returnType0, Type returnType1)
	    {
		    LibGlobalName = libGlobalName;
		    FunctionName = functionName;
		    ParameterPairs = new[] { (par0Type, par0Name), (par1Type, par1Name), (par2Type, par2Name), (par3Type, par3Name), (par4Type, par4Name), (par5Type, par5Name) };
		    ReturnType = new []{returnType0, returnType1};
	    }


		public ManuelWriteLibraryFunctionAttribute(string libGlobalName, string functionName, string returnType){
			UseStringType = true;
			LibGlobalName = libGlobalName;
		    FunctionName = functionName;
			ParameterStrPairs = Array.Empty<(string, string)>();
			ReturnTypeStr = returnType == null ? Array.Empty<string>() : new []{returnType};
		}

		public ManuelWriteLibraryFunctionAttribute(string libGlobalName, string functionName, string par0Type, string par0Name, string returnType = null){
			UseStringType = true;
			LibGlobalName = libGlobalName;
		    FunctionName = functionName;
			ParameterStrPairs = new []{(par0Type, par0Name)};
			ReturnTypeStr = returnType == null ? Array.Empty<string>() : new []{returnType};
		}

		public ManuelWriteLibraryFunctionAttribute(string libGlobalName, string functionName, string par0Type, string par0Name, string par1Type, string par1Name, string returnType = null){
			UseStringType = true;
			LibGlobalName = libGlobalName;
		    FunctionName = functionName;
			ParameterStrPairs = new []{(par0Type, par0Name), (par1Type, par1Name)};
			ReturnTypeStr = returnType == null ? Array.Empty<string>() : new []{returnType};
		}

		public ManuelWriteLibraryFunctionAttribute(string libGlobalName, string functionName, string par0Type, string par0Name, string par1Type, string par1Name, string par2Type, string par2Name,string returnType = null){
			UseStringType = true;
			LibGlobalName = libGlobalName;
		    FunctionName = functionName;
			ParameterStrPairs = new []{(par0Type, par0Name), (par1Type, par1Name), (par2Type, par2Name)};
			ReturnTypeStr = returnType == null ? Array.Empty<string>() : new []{returnType};
		}
    }
}