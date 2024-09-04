using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;
using DragonReborn.CSharpReflectionTool;
using UnityEditor;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    [GenerateLuaHintIgnoreType]
    public static class Generator
    {
        private delegate bool CheckType(Type type);
        private delegate bool CheckConstructor(Type type, ConstructorInfo constructorInfo, ISet<Type> processedType);
        private delegate bool CheckMethod(Type type, MethodInfo methodInfo, ISet<Type> processedType);
        private delegate bool CheckField(Type type, FieldInfo fieldInfo, ISet<Type> processedType);
        private delegate bool CheckProperty(Type type, PropertyInfo propertyInfo, ISet<Type> processedType);

        private static readonly Type StringType = typeof(string);
        private static readonly Type CollectType = typeof(IEnumerable<Type>);
        private static readonly Type CollectFpmType = typeof(IEnumerable<MemberInfo>);
        private static readonly Type BoolType = typeof(bool);
        private static readonly Type TypeType = typeof(Type);
        private static readonly Type MethodType = typeof(MethodInfo);
        private static readonly Type PropertyType = typeof(PropertyInfo);
        private static readonly Type FieldType = typeof(FieldInfo);
        private static readonly Type ObsoleteAttributeType = typeof(ObsoleteAttribute);
        private static readonly Type VoidType = typeof(void);
        private static readonly Type ObjectType = typeof(object);
        private static readonly Type ValueType = typeof(ValueType);
        private static readonly Type ExtensionAttributeType = typeof(ExtensionAttribute);
        // ReSharper disable once InconsistentNaming
        private static readonly Type ISetTypeType = typeof(ISet<Type>);

        private static readonly HashSet<Type> ParameterRefLikeTypes = new HashSet<Type>();

        // [MenuItem("DragonReborn/XLua/生成C#类智能提示文件", false, 20)]
        public static void DoGenerate()
        {
            var config = TypeCache.GetFieldsWithAttribute<GenerateLuaHintOutputPathAttribute>();
            var outputNameFormat = "Generated{0}LuaHint.lua";
            var outputSplit = "_";
            var outputNameSkipZero = true;
            var outputPath = Path.Combine(Application.dataPath, "../../../../ssr-logic/Lua");
            var outputFileLineLimit = 5000;
            
            if (config.Count > 0)
            {
                foreach (var c in config)
                {
                    if (!c.IsStatic || c.FieldType != StringType) continue;
                    var overridePath = (string)c.GetValue(null);
                    if (string.IsNullOrWhiteSpace(overridePath)) continue;
                    var attr = c.GetCustomAttribute<GenerateLuaHintOutputPathAttribute>();
                    outputPath = overridePath;
                    outputNameFormat = attr.NameIndexFormat;
                    outputSplit = attr.Splitter;
                    outputNameSkipZero = attr.SkipZero;
                    outputFileLineLimit = attr.LineLimit;
                    break;
                }
            }
            
            var dir = Path.GetDirectoryName(outputPath);
            if (string.IsNullOrWhiteSpace(dir) || !Directory.Exists(dir))
            {
                if (EditorUtility.DisplayDialog("导出路径问题", "导出路径文件夹不存在 检查 GenerateLuaHintOutputPath 标签", "选择其他位置", "取消"))
                {
                    outputPath = EditorUtility.SaveFilePanel("选择保存Generated_LuaHint.lua 的位置", Application.dataPath,
                        "Generated_LuaHint", "lua");
                    if (string.IsNullOrWhiteSpace(outputPath))
                    {
                        Debug.LogWarning("导出已经取消");
                        return;
                    }
                    dir = Path.GetDirectoryName(outputPath);
                    if (!Directory.Exists(dir))
                    {
                        Debug.LogError("导出路径文件夹不存在");
                        return;
                    }
                }
                else
                {
                    Debug.LogWarning("导出已经取消");
                    return;
                }
            }

            outputPath = Path.GetFullPath(outputPath);
            var hintTypes = TypeCache.GetTypesWithAttribute<GenerateLuaHintAttribute>().ToList();
            var hintTypeGetter = TypeCache.GetFieldsWithAttribute<GenerateLuaHintAttribute>();
            foreach (var getter in hintTypeGetter)
            {
                if (!getter.IsStatic) continue;
                if (!CollectType.IsAssignableFrom(getter.FieldType)) continue;
                hintTypes.AddRange((IEnumerable<Type>)getter.GetValue(null));
            }

            var processingTypes = new HashSet<Type>(hintTypes);
            if (processingTypes.Count <= 0)
            {
                Debug.LogWarning("导出已经取消, 没有要导出的类型 - 1");
                return;
            }

            var ignoreTypes = new HashSet<Type>(TypeCache.GetTypesWithAttribute<GenerateLuaHintIgnoreType>());
            var ignoreTypeGetter = TypeCache.GetFieldsWithAttribute<GenerateLuaHintIgnoreType>();
            foreach (var getter in ignoreTypeGetter)
            {
                if (!getter.IsStatic) continue;
                if (!CollectType.IsAssignableFrom(getter.FieldType)) continue;
                ignoreTypes.UnionWith((IEnumerable<Type>)getter.GetValue(null));
            }
            
            var ignoreFields = new HashSet<FieldInfo>();
            var ignoreProperties = new HashSet<PropertyInfo>();
            var ignoreMethods = new HashSet<MethodInfo>();
            var ignoreGetter = TypeCache.GetFieldsWithAttribute<GenerateLuaHintIgnoreGetter>();
            foreach (var field in ignoreGetter)
            {
                if (!field.IsStatic || !CollectFpmType.IsAssignableFrom(field.FieldType)) continue;
                var types = (IEnumerable<MemberInfo>)field.GetValue(null);
                foreach (var memberInfo in types)
                {
                    switch (memberInfo)
                    {
                        case FieldInfo f:
                            ignoreFields.Add(f);
                            break;
                        case PropertyInfo p:
                            ignoreProperties.Add(p);
                            break;
                        case MethodInfo m:
                            ignoreMethods.Add(m);
                            break;
                        case Type t:
                            ignoreTypes.Add(t);
                            break;
                    }
                }
            }
            
            processingTypes.ExceptWith(ignoreTypes);
            if (processingTypes.Count <= 0)
            {
                Debug.LogWarning("导出已经取消, 没有要导出的类型 - 2");
                return;
            }
            
            ParameterRefLikeTypes.Clear();
            var parameterRefLikeTypeGetters = TypeCache.GetFieldsWithAttribute<ParameterRefLikeTypesForHintAttribute>();
            foreach (var getter in parameterRefLikeTypeGetters)
            {
                if (!getter.IsStatic) continue;
                if (!CollectType.IsAssignableFrom(getter.FieldType)) continue;
                ParameterRefLikeTypes.UnionWith((IEnumerable<Type>)getter.GetValue(null));
            }

            var filterForType = TypeCache.GetMethodsWithAttribute<GenerateLuaHintFilterForTypeAttribute>().Where(m =>
            {
                if (!m.IsStatic || m.ReturnType != BoolType) return false;
                var pars = m.GetParameters();
                if (pars.Length != 1) return false;
                return pars[0].ParameterType == TypeType;
            }).Select(m => (CheckType)Delegate.CreateDelegate(typeof(CheckType), m)).ToList();
            filterForType.Insert(0, DefaultGenerateLuaHintFilterType);

            processingTypes.RemoveWhere(t => filterForType.Any(checker => !checker.Invoke(t)));
            
            if (processingTypes.Count <= 0)
            {
                Debug.LogWarning("导出已经取消, 没有要导出的类型 - 3");
                return;
            }

            var filterForConstructor = new List<CheckConstructor>()
            {
	            DefaultGenerateLuaHintFilterConstructor
            };
            
            var filterForField = TypeCache.GetMethodsWithAttribute<GenerateLuaHintFilterForFieldAttribute>().Where(m =>
            {
                if (!m.IsStatic || m.ReturnType != BoolType) return false;
                var pars = m.GetParameters();
                if (pars.Length != 3) return false;
                return pars[0].ParameterType == TypeType && pars[1].ParameterType == FieldType && ISetTypeType.IsAssignableFrom(pars[2].ParameterType);
            }).Select(m => (CheckField)Delegate.CreateDelegate(typeof(CheckField), m)).ToList();
            filterForField.Insert(0, DefaultGenerateLuaHintFilterField);
            
            var filterForProperty = TypeCache.GetMethodsWithAttribute<GenerateLuaHintFilterForPropertyAttribute>().Where(
                m =>
                {
                    if (!m.IsStatic || m.ReturnType != BoolType) return false;
                    var pars = m.GetParameters();
                    if (pars.Length != 3) return false;
                    return pars[0].ParameterType == TypeType && pars[1].ParameterType == PropertyType && ISetTypeType.IsAssignableFrom(pars[2].ParameterType);
                }).Select(m => (CheckProperty)Delegate.CreateDelegate(typeof(CheckProperty), m)).ToList();
            filterForProperty.Insert(0, DefaultGenerateLuaHintFilterProperty);

            var filterForMethod = TypeCache.GetMethodsWithAttribute<GenerateLuaHintFilterForMethodAttribute>().Where(
                m =>
                {
                    if (!m.IsStatic || m.ReturnType != BoolType) return false;
                    var pars = m.GetParameters();
                    if (pars.Length != 3) return false;
                    return pars[0].ParameterType == TypeType && pars[1].ParameterType == MethodType && ISetTypeType.IsAssignableFrom(pars[2].ParameterType);
                }).Select(m => (CheckMethod)Delegate.CreateDelegate(typeof(CheckMethod), m)).ToList();
            filterForMethod.Insert(0, DefaultGenerateLuaHintFilterMethod);
            
            var toWrite = new ExportWrite((index) =>
            {
	            if (outputNameSkipZero && index == 0)
	            {
		            return (Path.Combine(outputPath, string.Format(outputNameFormat, outputSplit)), outputFileLineLimit);
	            }
	            return (Path.Combine(outputPath, string.Format(outputNameFormat, $"{outputSplit}{index}{outputSplit}")), outputFileLineLimit);
            });
            var oldFileNamePattern = string.Format(outputNameFormat, $"{outputSplit}*{outputSplit}");
            var folder = new DirectoryInfo(outputPath);
            foreach (var oldFile in folder.GetFiles(oldFileNamePattern, SearchOption.TopDirectoryOnly))
            {
	            oldFile.Delete();
            }

            var manuelWriteLib = TypeCache.GetMethodsWithAttribute<ManuelWriteLibraryFunctionAttribute>().SelectMany(m=>m.GetCustomAttributes<ManuelWriteLibraryFunctionAttribute>()).ToList();
            DoProcess(processingTypes, ignoreFields, ignoreProperties, ignoreMethods, filterForConstructor, filterForField, filterForProperty, filterForMethod, manuelWriteLib, toWrite);
            toWrite.FinishFile();
            // File.WriteAllText(outputPath, toWrite.ToString(), Encoding.UTF8);
            Debug.Log($"导出完成, 导出到:{outputPath}");
            // EditorUtility.DisplayDialog("导出完成", $"导出到:{outputPath}", "确定");
        }

        private static void DoProcess(ISet<Type> processingTypes
            , ISet<FieldInfo> ignoreFields
            , ISet<PropertyInfo> ignoreProperties
            , ISet<MethodInfo> ignoreMethods
            , IList<CheckConstructor> filterForConstructor
            , IList<CheckField> filterForField
            , IList<CheckProperty> filterForProperty
            , IList<CheckMethod> filterForMethod
            , IList<ManuelWriteLibraryFunctionAttribute> manuelWriteLib
            , ExportWrite toWrite
        )
        {
	        toWrite.NextBlock(true);
            toWrite.AppendLine($"-- For EmmyLua Annotations,AUTO GENERATED BY DragonReborn.LuaHintGenerator. do not modify. Time:{DateTime.Now:s}");
            toWrite.AppendLine("error(\"don't run\")");
            toWrite.AppendLine("---@generic T");
            toWrite.AppendLine("---@param t T");
            toWrite.AppendLine("function typeof(t)");
            toWrite.AppendLine("\treturn t");
            toWrite.AppendLine("end");
            var extMethod = new ConcurrentDictionary<Type, ConcurrentDictionary<MethodInfo, Type>>();
            var toWriteTypes = new ConcurrentBag<ExportInfo>();
            Parallel.ForEach(processingTypes, processingType =>
            {
                var info = new ExportInfo(processingType);
                toWriteTypes.Add(info);
                var constructors = processingType.GetConstructors(BindingFlags.Public | BindingFlags.Instance);
                if (constructors.Length > 0)
                {
	                info.ConstructorInfos = new List<ConstructorInfo>();
	                foreach (var constructorInfo in constructors)
	                {
		                if (filterForConstructor.Any(c => !c(processingType, constructorInfo, processingTypes))) continue;
		                info.ConstructorInfos.Add(constructorInfo);
	                }
                }
                var fields =
                    processingType.GetFields(BindingFlags.Public | BindingFlags.Static | BindingFlags.Instance | BindingFlags.DeclaredOnly);
                if (fields.Length > 0)
                {
                    info.FieldInfos = new List<FieldInfo>();
                    foreach (var fieldInfo in fields)
                    {
                        if (ignoreFields.Contains(fieldInfo)) continue;
                        if (filterForField.Any(c => !c(processingType, fieldInfo, processingTypes))) continue;
                        info.FieldInfos.Add(fieldInfo);
                    }

                    if (processingType.IsEnum)
                    {
	                    info.FieldInfos.Sort((a, b) =>
	                    {
		                    switch (a.IsStatic)
		                    {
			                    case true when b.IsStatic:
			                    {
				                    var aValue = a.GetValue(null);
				                    var bValue = b.GetValue(null);
				                    if (aValue is IComparable aCv && bValue is IComparable bCv)
				                    {
					                    return aCv.CompareTo(bCv);
				                    }
				                    break;
			                    }
			                    case true:
				                    return -1;
			                    default:
			                    {
				                    if (b.IsStatic)
				                    {
					                    return 1;
				                    }
				                    break;
			                    }
		                    }
		                    return StringComparer.Ordinal.Compare(a.Name, b.Name);
	                    });
                    }
                    else
                    {
	                    info.FieldInfos.Sort((a,b)=>StringComparer.Ordinal.Compare(a.Name, b.Name));
                    }
                }
                var properties =
                    processingType.GetProperties(BindingFlags.Public | BindingFlags.Static | BindingFlags.Instance | BindingFlags.DeclaredOnly);
                if (properties.Length > 0)
                {
                    info.PropertyInfos = new List<PropertyInfo>();
                    foreach (var propertyInfo in properties)
                    {
                        if (ignoreProperties.Contains(propertyInfo)) continue;
                        if (filterForProperty.Any(c => !c(processingType, propertyInfo, processingTypes))) continue;
                        info.PropertyInfos.Add(propertyInfo);
                    }
                    info.PropertyInfos.Sort((a,b)=>StringComparer.Ordinal.Compare(a.Name, b.Name));
                }
                var methods =
                    processingType.GetMethods(BindingFlags.Public | BindingFlags.Static | BindingFlags.Instance | BindingFlags.DeclaredOnly);
                if (methods.Length > 0)
                {
                    info.MethodInfos = new List<MethodInfo>();
                    foreach (var methodInfo in methods)
                    {
                        if (ignoreMethods.Contains(methodInfo)) continue;
                        if (filterForMethod.Any(c => !c(processingType, methodInfo, processingTypes))) continue;
                        if (methodInfo.IsDefined(ExtensionAttributeType))
                        {
                            var extType = methodInfo.GetParameters()[0].ParameterType;
                            if (processingTypes.Contains(extType))
                            {
                                var h = extMethod.GetOrAdd(extType, _ => new ConcurrentDictionary<MethodInfo, Type>());
                                h.AddOrUpdate(methodInfo, processingType, (_, _) => processingType);
                                continue;
                            }
                        }
                        info.MethodInfos.Add(methodInfo);
                    }
                    info.MethodInfos.Sort((a,b)=>StringComparer.Ordinal.Compare(a.Name, b.Name));
                }
            });
            Parallel.ForEach(toWriteTypes, info =>
            {
                if (!extMethod.TryGetValue(info.Type, out var d)) return;
                if (null == info.ExtMethods)
                {
                    info.ExtMethods = new List<KeyValuePair<MethodInfo, Type>>(d);
                }
                else
                {
                    info.ExtMethods.AddRange(d);
                }
                info.ExtMethods.Sort((a,b)=>StringComparer.Ordinal.Compare(a.Key.Name, b.Key.Name));
            });
            var l = new List<ExportInfo>(toWriteTypes);
            l.Sort((a,b)=>StringComparer.Ordinal.Compare(a.Type.FullName, b.Type.FullName));
            var classWrite = toWrite.CreateSubWriter();
            var typeDefineWrite = toWrite.CreateSubWriter();
            var typeNamespaceList = new NamespaceTreeNode("CS");
            foreach (var exportInfo in l)
            {
	            classWrite.NextBlock();
	            classWrite.AppendLine(string.Empty);
                classWrite.Append("---@class ");
                var (isCsType,isNaturalInLuaType) = PrintTypeName(classWrite, exportInfo.Type, processingTypes, out var fullTypeName);
                if (null != exportInfo.Type.BaseType 
                    && ObjectType != exportInfo.Type.BaseType 
                    && ValueType != exportInfo.Type.BaseType 
                    && !exportInfo.Type.IsEnum)
                {
                    classWrite.Append(processingTypes.Contains(exportInfo.Type.BaseType) ? ":" : " @:");
                    var (baseTypeName,isNaturalInLua,baseInCs) = GetTypeName(exportInfo.Type.BaseType, processingTypes);
                    if (!isNaturalInLua) classWrite.Append("\"");
                    if (baseInCs) classWrite.Append("CS.");
                    classWrite.Append(baseTypeName);
                    if (!isNaturalInLua) classWrite.Append("\"");
                }
                
                if (exportInfo.Type.IsEnum)
                {
	                classWrite.Append($" @Enum: {Type.GetTypeCode(exportInfo.Type)}");
	                if (exportInfo.Type.GetCustomAttribute<FlagsAttribute>() != null)
	                {
		                classWrite.Append(" [Flags]");
	                }
                }else if (exportInfo.Type.IsInterface)
                {
	                classWrite.Append(" @Interface");
                }

                if (exportInfo.Type.IsValueType && !exportInfo.Type.IsPrimitive && !exportInfo.Type.IsEnum)
                {
	                classWrite.Append(" @Struct");
	                AppendConstructorInfo(classWrite, null, exportInfo, processingTypes);
                }
                if (exportInfo.ConstructorInfos?.Count > 0)
                {
	                foreach (var constructorInfo in exportInfo.ConstructorInfos)
	                {
		                AppendConstructorInfo(classWrite, constructorInfo, exportInfo, processingTypes);
	                }
                }
                if (exportInfo.FieldInfos?.Count > 0)
                {
	                foreach (var tempField in exportInfo.FieldInfos)
                    {
	                    classWrite.AppendLine(string.Empty);
	                    classWrite.Append("---@field ");
	                    classWrite.Append(tempField.Name);
	                    classWrite.Append(" ");
                        PrintTypeName(classWrite, tempField.FieldType, processingTypes);
                        if (exportInfo.Type.IsEnum && tempField.IsStatic)
                        {
	                        classWrite.Append($" @value: {Convert.ChangeType(tempField.GetValue(null), exportInfo.Type.GetEnumUnderlyingType())}");
                        }
                    }
                }
                if (exportInfo.PropertyInfos?.Count > 0)
                {
                    foreach (var tempPropertyInfo in exportInfo.PropertyInfos)
                    {
	                    classWrite.AppendLine(string.Empty);
	                    classWrite.Append("---@field ");
	                    classWrite.Append(tempPropertyInfo.Name);
	                    classWrite.Append(" ");
                        PrintTypeName(classWrite, tempPropertyInfo.PropertyType, processingTypes);
                        if (tempPropertyInfo.CanRead && tempPropertyInfo.CanWrite)
                        {
	                        classWrite.Append(" @ -Read,Write");
                        }else if (tempPropertyInfo.CanRead)
                        {
	                        classWrite.Append(" @ -Read");
                        }else if (tempPropertyInfo.CanWrite)
                        {
	                        classWrite.Append(" @ -Write");
                        }
                    }
                }
                if (exportInfo.MethodInfos?.Count > 0)
                {
                    foreach (var methodInfo in exportInfo.MethodInfos)
                    {
                        AppendMethodInfo(classWrite, methodInfo, exportInfo, processingTypes);
                    }
                }
                if (exportInfo.ExtMethods?.Count > 0)
                {
                    foreach (var methodInfo in exportInfo.ExtMethods)
                    {
                        AppendMethodInfo(classWrite, methodInfo.Key, exportInfo, processingTypes);
                        classWrite.Append(" @in:");
                        PrintTypeName(classWrite, methodInfo.Value, processingTypes);
                    }
                }
                classWrite.AppendLine(string.Empty);
                if (!isCsType || !isNaturalInLuaType) continue;
                typeDefineWrite.NextBlock();
                typeDefineWrite.AppendLine(string.Empty);
                typeDefineWrite.Append("---@type CS.");
                typeDefineWrite.AppendLine(fullTypeName);
                typeDefineWrite.Append("CS.");
                typeDefineWrite.Append(fullTypeName);
                typeDefineWrite.Append(" = nil");
                typeNamespaceList.AddChild(fullTypeName);
            }

            toWrite.AppendLine(string.Empty);
            typeNamespaceList.WriteTo(toWrite, "", " = {}\n");
            toWrite.AppendSamePage(typeDefineWrite);
            toWrite.Append(classWrite);

            var collectForManuel = new Dictionary<string, List<ManuelWriteLibraryFunctionAttribute>>();
            foreach (var attribute in manuelWriteLib)
            {
	            if (string.IsNullOrWhiteSpace(attribute.LibGlobalName) | string.IsNullOrWhiteSpace(attribute.FunctionName))
		            continue;
	            if (!collectForManuel.TryGetValue(attribute.LibGlobalName, out var list))
	            {
		            list = new List<ManuelWriteLibraryFunctionAttribute>();
		            collectForManuel.Add(attribute.LibGlobalName, list);
	            }
	            list.Add(attribute);
            }

            if (collectForManuel.Count > 0)
            {
	            foreach (var (_, list) in collectForManuel)
	            {
		            list.Sort((a, b) =>
		            {
			            var ret = string.CompareOrdinal(a.FunctionName, b.FunctionName);
			            if (ret != 0) return ret;
			            var aCount = a.ParameterPairs?.Length ?? 0;
			            var bCount = b.ParameterPairs?.Length ?? 0;
			            return aCount.CompareTo(bCount);
		            });
	            }
	            var libList = collectForManuel.ToList();
	            libList.Sort((a, b) => string.CompareOrdinal(a.Key, b.Key));
	            toWrite.NextBlock(false);
	            toWrite.AppendLine(string.Empty);
	            toWrite.AppendLine("-- Manuel Define, Generate from ManuelWriteLibraryFunctionAttribute");
	            foreach (var (libName, libFuncList) in libList)
	            {
		            toWrite.AppendLine(string.Empty);
		            toWrite.Append("---@class ");
		            toWrite.Append(libName);
		            foreach (var attribute in libFuncList)
		            {
			            toWrite.AppendLine(string.Empty);
			            
			            toWrite.Append("---@field ");
			            toWrite.Append(attribute.FunctionName);
			            toWrite.Append(" fun(");
                        if (attribute.UseStringType)
                        {
                            if (attribute.ParameterStrPairs is { Length: > 0 })
			                {
				                var (paraType, paraName) = attribute.ParameterStrPairs[0];
				                toWrite.Append(paraName);
				                toWrite.Append(":");
				                toWrite.Append(paraType);
				                for (var i = 1; i < attribute.ParameterStrPairs.Length; i++)
				                {
					                var (otherParaType, otherParaName) = attribute.ParameterStrPairs[i];
					                toWrite.Append(",");
					                toWrite.Append(otherParaName);
					                toWrite.Append(":");
					                toWrite.Append(paraType);
				                }
			                }
                            
			                toWrite.Append(")");
			                if (attribute.ReturnTypeStr is { Length: > 0 })
			                {
				                toWrite.Append(":");
				                var retType = attribute.ReturnTypeStr[0];
                                toWrite.Append(retType);
				                for (var i = 1; i < attribute.ReturnTypeStr.Length; i++)
				                {
					                toWrite.Append(",");
					                retType = attribute.ReturnTypeStr[i];
					                toWrite.Append(retType);
				                }
			                }
                        }
                        else
                        {
                            if (attribute.ParameterPairs is { Length: > 0 })
			                {
				                var (paraType, paraName) = attribute.ParameterPairs[0];
				                toWrite.Append(paraName);
				                toWrite.Append(":");
				                PrintTypeName(toWrite, paraType.IsByRef ? paraType.GetElementType() : paraType,
					                processingTypes);
				                for (var i = 1; i < attribute.ParameterPairs.Length; i++)
				                {
					                var (otherParaType, otherParaName) = attribute.ParameterPairs[i];
					                toWrite.Append(",");
					                toWrite.Append(otherParaName);
					                toWrite.Append(":");
					                PrintTypeName(toWrite,
						                otherParaType.IsByRef ? otherParaType.GetElementType() : otherParaType,
						                processingTypes);
				                }
			                }

			                toWrite.Append(")");
			                if (attribute.ReturnType is { Length: > 0 })
			                {
				                toWrite.Append(":");
				                var retType = attribute.ReturnType[0];
				                PrintTypeName(toWrite, retType.IsByRef ? retType.GetElementType() : retType,
					                processingTypes);
				                for (var i = 1; i < attribute.ReturnType.Length; i++)
				                {
					                toWrite.Append(",");
					                retType = attribute.ReturnType[i];
					                PrintTypeName(toWrite, retType.IsByRef ? retType.GetElementType() : retType,
						                processingTypes);
				                }
			                }
                        }
			            
		            }
		            toWrite.AppendLine(string.Empty);
		            toWrite.NextBlock(false);
	            }
            }

            static void AppendConstructorInfo(IWriter toWrite, ConstructorInfo constructorInfo, ExportInfo exportInfo,
	            ISet<Type> processingTypes)
            {
	            IReadOnlyList<ParameterInfo> parameterInfos = constructorInfo?.GetParameters() ?? Array.Empty<ParameterInfo>();
	            if (exportInfo.Type.IsValueType 
	                && !exportInfo.Type.IsPrimitive 
	                && !exportInfo.Type.IsEnum
	                && constructorInfo != null 
	                && parameterInfos.Count <= 0)
	            {
		            // struct default constructor write when constructorInfo is null
		            return;
	            }
	            toWrite.AppendLine(string.Empty);
	            toWrite.Append("---@field __ctor");
	            toWrite.Append(" fun(");
	            var extraReturnTypes= AppendParameters(toWrite, parameterInfos, processingTypes);
	            toWrite.Append(")");
	            toWrite.Append(":");
	            PrintTypeName(toWrite, exportInfo.Type,
		            processingTypes);
	            if (null == extraReturnTypes) return;
	            foreach (var returnType in extraReturnTypes)
	            {
		            toWrite.Append(",");
		            PrintTypeName(toWrite, returnType, processingTypes);
	            }
            }

            static void AppendMethodInfo(IWriter toWrite, MethodInfo methodInfo, ExportInfo exportInfo, ISet<Type> processingTypes)
            {
                toWrite.AppendLine(string.Empty);
                toWrite.Append("---@field ");
                toWrite.Append(methodInfo.Name);
                toWrite.Append(" fun(");
                var extraReturnTypes= AppendParameters(toWrite, methodInfo, processingTypes, exportInfo.Type);
                toWrite.Append(")");
                if (methodInfo.ReturnType == VoidType && !(extraReturnTypes?.Count > 0)) return;
                toWrite.Append(":");
                var fistReturnType = true;
                if (methodInfo.ReturnType != VoidType)
                {
	                PrintTypeName(toWrite, methodInfo.ReturnType.IsByRef ? methodInfo.ReturnType.GetElementType() : methodInfo.ReturnType,
		                processingTypes);
                                
	                fistReturnType = false;
                }
                if (!(extraReturnTypes?.Count > 0)) return;
                foreach (var returnType in extraReturnTypes)
                {
	                if (fistReturnType)
	                {
		                fistReturnType = false;
	                }
	                else
	                {
		                toWrite.Append(",");
	                }
                                
	                PrintTypeName(toWrite, returnType, processingTypes);
                }
            }
        }

        private static (string,bool,bool) GetTypeName(Type type, ISet<Type> processingTypes)
        {
            if (!type.IsEnum)
            {
                switch (Type.GetTypeCode(type))
                {
                    case TypeCode.Boolean:
                        return ("boolean", true, false);
                    case TypeCode.SByte:
                    case TypeCode.Byte:
                    case TypeCode.Int16:
                    case TypeCode.UInt16:
                    case TypeCode.Int32:
                    case TypeCode.UInt32:
                    case TypeCode.Int64:
                    case TypeCode.UInt64:
                    case TypeCode.Single:
                    case TypeCode.Double:
                        return ("number", true, false);
                    case TypeCode.String:
                        return ("string", true, false);
                    case TypeCode.Object:
	                    if (type == ObjectType)
		                    return ("System.Object", true, true);
	                    if (string.CompareOrdinal(type.FullName, "XLua.LuaTable") == 0)
		                    return ("table", true, false);
	                    break;
                }
            }
            if (processingTypes.Contains(type))
            {
                return (PatchForFullName(type), true, true);
            }
            if (!type.IsArray || !type.HasElementType) return (PatchForFullName(type), false, true);
            var (typeName, naturalInLua, inCs) = GetTypeName(type.GetElementType(), processingTypes);
            return naturalInLua ? ($"{typeName}[]", true, inCs) : (PatchForFullName(type), false, inCs);

            static string PatchForFullName(Type type)
            {
                return type.TypeNameToHandWriteFormat();
            }
        }
        
        private static (bool,bool) PrintTypeName(IWriter toWrite, Type type, ISet<Type> processingTypes, out string fullTypeName)
        {
	        var (typeName, isNaturalInLua, baseInCs) = GetTypeName(type, processingTypes);
	        if (!isNaturalInLua) toWrite.Append("\"");
	        if (baseInCs) toWrite.Append("CS.");
	        toWrite.Append(typeName);
	        fullTypeName = typeName;
	        if (!isNaturalInLua) toWrite.Append("\"");
	        return (baseInCs,isNaturalInLua);
        }

        private static void PrintTypeName(IWriter toWrite, Type type, ISet<Type> processingTypes)
        {
	        PrintTypeName(toWrite, type, processingTypes, out _);
        }

        private static List<Type> AppendParameters(IWriter toWrite, IReadOnlyList<ParameterInfo> pars,
            ISet<Type> processingTypes)
        {
	        List<Type> extraReturnTypes = null;

            var firstArg = true;
            int paramStartIndex = 0;
            for (int i = paramStartIndex; i < pars.Count; i++)
            {
                var p = pars[i];

                // 处理ref 既是参数也是返回值
                if (p.ParameterType.IsByRef && !p.IsIn)
                {
	                extraReturnTypes ??= new List<Type>();
                    extraReturnTypes.Add(p.ParameterType.HasElementType ? p.ParameterType.GetElementType() : p.ParameterType);
                }

                if (firstArg)
                {
                    firstArg = false;
                }
                else
                {
                    toWrite.Append(",");
                }

                toWrite.Append(p.Name);
                toWrite.Append(":");
                PrintTypeName(toWrite, p.ParameterType.IsByRef ? p.ParameterType.GetElementType() : p.ParameterType,
                    processingTypes);
            }

            return extraReturnTypes;
        }

        private static List<Type> AppendParameters(IWriter toWrite, MethodInfo methodInfo,
            ISet<Type> processingTypes, Type type)
        {
	        List<Type> extraReturnTypes = null;

            var firstArg = true;
            int paramStartIndex = 0;
            var pars = methodInfo.GetParameters();
            if (!methodInfo.IsStatic)
            {
                toWrite.Append("self:");
                PrintTypeName(toWrite, type, processingTypes);
                firstArg = false;
            }else if (methodInfo.IsDefined(ExtensionAttributeType))
            {
                var extType = pars[0].ParameterType;
                if (extType == type)
                {
                    toWrite.Append("self:");
                    PrintTypeName(toWrite, extType, processingTypes);
                    firstArg = false;
                    paramStartIndex = 1;
                }
            }
            for (int i = paramStartIndex; i < pars.Length; i++)
            {
                var p = pars[i];
                if (p.IsOut)
                {
                    if (p.ParameterType.HasElementType && p.ParameterType.IsByRef)
                    {
	                    extraReturnTypes ??= new List<Type>();
                        extraReturnTypes.Add(p.ParameterType.GetElementType());
                    }
                    else
                    {
	                    extraReturnTypes ??= new List<Type>();
                        extraReturnTypes.Add(p.ParameterType);
                    }
                    continue;
                }

                // 处理ref 既是参数也是返回值
                if (p.ParameterType.IsByRef && !p.IsIn)
                {
	                extraReturnTypes ??= new List<Type>();
                    extraReturnTypes.Add(p.ParameterType.HasElementType ? p.ParameterType.GetElementType() : p.ParameterType);
                }

                if (firstArg)
                {
                    firstArg = false;
                }
                else
                {
                    toWrite.Append(",");
                }

                toWrite.Append(p.Name);
                toWrite.Append(":");
                PrintTypeName(toWrite, p.ParameterType.IsByRef ? p.ParameterType.GetElementType() : p.ParameterType,
                    processingTypes);
            }

            return extraReturnTypes;
        }

        private static bool DefaultGenerateLuaHintFilterType(Type type)
        {
            if (!type.IsEnum)
            {
                switch (Type.GetTypeCode(type))
                {
                    case TypeCode.Empty:
                    case TypeCode.DBNull:
                    case TypeCode.Boolean:
                    case TypeCode.Char:
                    case TypeCode.SByte:
                    case TypeCode.Byte:
                    case TypeCode.Int16:
                    case TypeCode.UInt16:
                    case TypeCode.Int32:
                    case TypeCode.UInt32:
                    case TypeCode.Int64:
                    case TypeCode.UInt64:
                    case TypeCode.Single:
                    case TypeCode.Double:
                    case TypeCode.String:
                        return false;
                }
            }
            if (type.IsGenericType) return false;
            if (type.IsByRefLike) return false;
            if (type.IsDefined(typeof(ObsoleteAttribute))) return false;
            return true;
        }

        private static bool DefaultGenerateLuaHintFilterConstructor(Type type, ConstructorInfo constructorInfo,
	        ISet<Type> processedType)
        {
	        if (constructorInfo.IsDefined(ObsoleteAttributeType)) return false;
	        var pars = constructorInfo.GetParameters();
	        if (pars.Any(pt => pt.ParameterType.IsByRefLike && !ParameterRefLikeTypes.Contains(pt.ParameterType))) return false;
	        return true;
        }

        private static bool DefaultGenerateLuaHintFilterMethod(Type type, MethodInfo methodInfo, ISet<Type> processedType)
        {
	        if (methodInfo.DeclaringType != methodInfo.ReflectedType &&
	            processedType.Contains(methodInfo.DeclaringType)) return false;
	        if (methodInfo.IsSpecialName) return false;
            if (methodInfo.IsGenericMethod) return false;
            if (methodInfo.ReturnType.IsByRefLike) return false;
            if (methodInfo.IsDefined(ObsoleteAttributeType)) return false;
            if (string.CompareOrdinal("ToString", methodInfo.Name) == 0) return false;
            if (string.CompareOrdinal("GetHashCode", methodInfo.Name) == 0) return false;
            if (string.CompareOrdinal("Equals", methodInfo.Name) == 0) return false;
            if (string.CompareOrdinal("GetType", methodInfo.Name) == 0) return false;
            if (string.CompareOrdinal("GetTypeCode", methodInfo.Name) == 0) return false;
            if (type.IsEnum)
            {
                if (string.CompareOrdinal("HasFlag", methodInfo.Name) == 0) return false;
                if (string.CompareOrdinal("CompareTo", methodInfo.Name) == 0) return false;
            }
            var pars = methodInfo.GetParameters();
            if (pars.Any(pt => pt.ParameterType.IsByRefLike && !ParameterRefLikeTypes.Contains(pt.ParameterType))) return false;
            return true;
        }

        private static bool DefaultGenerateLuaHintFilterField(Type type, FieldInfo fieldInfo, ISet<Type> processedType)
        {
            if (fieldInfo.IsDefined(ObsoleteAttributeType)) return false;
            if (fieldInfo.DeclaringType != fieldInfo.ReflectedType &&
                processedType.Contains(fieldInfo.DeclaringType)) return false;
            if (type.IsEnum)
            {
                if (string.CompareOrdinal("value__", fieldInfo.Name) == 0) return false;
            }
            return true;
        }
        
        private static bool DefaultGenerateLuaHintFilterProperty(Type type, PropertyInfo propertyInfo, ISet<Type> processedType)
        {
            if (propertyInfo.IsDefined(ObsoleteAttributeType)) return false;
            if (propertyInfo.DeclaringType != propertyInfo.ReflectedType &&
                processedType.Contains(propertyInfo.DeclaringType)) return false;
            return true;
        }

        private class ExportInfo
        {
            public readonly Type Type;
            public List<ConstructorInfo> ConstructorInfos;
            public List<FieldInfo> FieldInfos;
            public List<MethodInfo> MethodInfos;
            public List<KeyValuePair<MethodInfo, Type>> ExtMethods;
            public List<PropertyInfo> PropertyInfos;

            public ExportInfo(Type type) 
            {
                Type = type;
            }
        }

        private class NamespaceTreeNode
        {
	        private bool _isEndClass;
	        private readonly string _name;
	        private Dictionary<string, NamespaceTreeNode> _children;

	        public NamespaceTreeNode(string name)
	        {
		        _name = name;
	        }

	        public void AddChild(ReadOnlySpan<char> partFullName)
	        {
		        _children ??= new Dictionary<string, NamespaceTreeNode>();
		        var sp = partFullName.IndexOf('.');
		        var childName = sp <= 0 ? partFullName.ToString() : partFullName[..sp].ToString();
		        if (!_children.TryGetValue(childName, out var child))
		        {
			        child = new NamespaceTreeNode(childName);
			        _children.Add(childName, child);
			        child._isEndClass = sp <= 0;
		        }
		        if (sp <= 0 || sp >= partFullName.Length - 1) return;
		        child.AddChild(partFullName[(sp + 1)..]);
	        }

	        public void WriteTo(IWriter toWrite, string prefix = null, string ext = null)
	        {
		        if (_isEndClass) return;
		        toWrite.Append(prefix);
		        toWrite.Append(_name);
		        toWrite.Append(ext);
		        if (_children is not { Count: > 0 }) return;
		        var values = _children.Values.ToArray();
		        Array.Sort(values, (a,b)=>string.CompareOrdinal(a._name, b._name));
		        prefix = string.Concat(prefix, _name, ".");
		        foreach (var namespaceTreeNode in values)
		        {
			        namespaceTreeNode.WriteTo(toWrite, prefix, ext);
		        }
	        }
        }

        private interface IWriter
        {
	        void NextBlock();
	        void AppendLine(string lineContent);
	        void Append(string content);
        }
        
        private class ExportWrite : IWriter
        {
	        private readonly StringBuilder _baseBuilder = new();

	        private readonly Func<int, (string, int)> _writeTargetGetter;

	        private (string, int)? _currentSaveInfo;

	        private int _currentIndex;

	        public ExportWrite(Func<int, (string, int)> writeTargetGetter)
	        {
		        _writeTargetGetter = writeTargetGetter;
	        }

	        public IWriter CreateSubWriter()
	        {
		        return new Writer();
	        }
	        
	        public void NextBlock()
	        {
		        NextBlock(false);
	        }

	        public void NextBlock(bool forceWriteContent)
	        {
		        if (null == _currentSaveInfo)
		        {
			        _currentSaveInfo = _writeTargetGetter(_currentIndex++);
			        return;
		        }
		        var (filePath, limit) = _currentSaveInfo.Value;
		        var content = _baseBuilder.ToString();
		        var lineCount = GetLineCount(content);
		        if (lineCount < limit && !forceWriteContent)
			        return;
		        _baseBuilder.Clear();
		        _currentSaveInfo = _writeTargetGetter(_currentIndex++);
		        File.WriteAllText(filePath, content);
	        }

	        public void FinishFile()
	        {
		        if (null == _currentSaveInfo)
			        return;
		        var (filePath, _) = _currentSaveInfo.Value;
		        File.WriteAllText(filePath, _baseBuilder.ToString());
		        _baseBuilder.Clear();
		        _currentSaveInfo = null;
	        }

	        public void Append(IWriter iWriter)
	        {
		        if (iWriter is not Writer writer) return;
		        NextBlock(true);
		        foreach (var content in writer.PullContent())
		        {
			        _baseBuilder.Append(content);
			        NextBlock(false);
		        }
	        }

	        public void AppendSamePage(IWriter iWriter)
	        {
		        if (iWriter is not Writer writer) return;
		        foreach (var content in writer.PullContent())
		        {
			        _baseBuilder.Append(content);
		        }
	        }

	        public void AppendLine(string lineContent)
	        {
		        _baseBuilder.AppendLine(lineContent);
	        }
	        
	        public void Append(string content)
	        {
		        _baseBuilder.Append(content);
	        }
	        
	        private static int GetLineCount(ReadOnlySpan<char> str)
	        {
		        if (str.IsEmpty)
			        return 0;
		        if (str.IsWhiteSpace())
			        return 1;
		        int idx;
		        var count = 0;
		        while ((idx = str.IndexOf('\n')) != -1 && idx < str.Length - 1)
		        {
			        count++;
			        str = str[(idx + 1)..];
		        }
		        return count + 1;
	        }

	        private class Writer : IWriter
	        {
		        private readonly StringBuilder _sb = new();

		        private readonly Queue<string> _blockContent = new();

		        public void NextBlock()
		        {
			        var content = _sb.ToString();
			        if (string.IsNullOrEmpty(content))
				        return;
			        _sb.Clear();
			        _blockContent.Enqueue(content);
		        }

		        public void AppendLine(string lineContent)
		        {
			        _sb.AppendLine(lineContent);
		        }

		        public void Append(string content)
		        {
			        _sb.Append(content);
		        }

		        public IEnumerable<string> PullContent()
		        {
			        NextBlock();
			        return _blockContent;
		        }
	        }
        }
    }
}