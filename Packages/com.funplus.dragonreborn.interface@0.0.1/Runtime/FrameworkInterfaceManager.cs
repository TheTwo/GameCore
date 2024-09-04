using System;
using System.Collections.Generic;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    public static partial class FrameworkInterfaceManager
    {
        private static bool _interfacesGenerated;
        
        private static readonly Dictionary<Type, FrameInterfaceDescriptor> RegisterMap = new Dictionary<Type, FrameInterfaceDescriptor>();
        
        public static readonly Dictionary<Type, IFrameworkInterface> CreatedInterface = new Dictionary<Type, IFrameworkInterface>();

        public static void Reset()
        {
            RegisterMap.Clear();
            CreatedInterface.Clear();
            _interfacesGenerated = false;
            
            _luaExecutor = null;
            foreach (var frameLuaExecutorReceiver in LuaExecutorReceivers)
            {
	            frameLuaExecutorReceiver.OnReleaseExecutor();
            }
            LuaExecutorReceivers.Clear();
        }
        
        public static bool RegisterFrameInterface<T>(FrameInterfaceDescriptor<T> frameInterfaceDescriptor) where T : IFrameworkInterface<T>
        {
            var t = typeof(T);
            if (_interfacesGenerated)
            {
                UnityEngine.Debug.LogErrorFormat("{0}.{1}({2}) refused by InterfacesGenerated",nameof(FrameworkInterfaceManager), nameof(RegisterFrameInterface) ,t);
                return false;
            }
            if (RegisterMap.ContainsKey(t))
            {
                return false;
            }
            RegisterMap.Add(t, frameInterfaceDescriptor);
            return true;
        }

        public static bool QueryFrameInterface<T>(out T ret)
        {
            if (!_interfacesGenerated)
            {
                ret = default;
                UnityEngine.Debug.LogErrorFormat("{0}.{1}({2}) refused by none InterfacesGenerated",nameof(FrameworkInterfaceManager), nameof(QueryFrameInterface) , typeof(T));
                return false;
            }
            if (CreatedInterface.TryGetValue(typeof(T), out var iFrameworkInterface) 
                && iFrameworkInterface is T typedInterface)
            {
                ret = typedInterface;
                return true;
            }
            ret = default;
            return false;
        }

        private static void GenerateInterfaces()
        {
            _interfacesGenerated = true;
            foreach (var (type, frameInterfaceDescriptor) in RegisterMap)
            {
                try
                {
                    CreatedInterface.Add(type, frameInterfaceDescriptor.InternalCreateInterface());
                }
                catch (Exception e)
                {
                    UnityEngine.Debug.LogException(e);
                }
            }
            // for shortcut
            if (QueryFrameInterface(out IFrameworkLogger logger))
            {
                NLogger.LoggerImpl = logger;
            }
        }

        private static readonly HashSet<IFrameLuaExecutorReceiver> LuaExecutorReceivers = new();

        private static IFrameLuaExecutorReceiver.LuaExecutor _luaExecutor;

        public static void SetupLuaExecutor(IFrameLuaExecutorReceiver.LuaExecutor content)
        {
	        if (_luaExecutor == content) return;
	        _luaExecutor = content;
	        foreach (var frameLuaExecutorReceiver in LuaExecutorReceivers)
	        {
		        frameLuaExecutorReceiver.OnReleaseExecutor();
	        }
	        if (null == content) return;
	        {
		        foreach (var frameLuaExecutorReceiver in LuaExecutorReceivers)
		        {
			        frameLuaExecutorReceiver.OnSetupExecutor(_luaExecutor);
		        }
	        }
        }

        public static void RegisterLuaExecutorReceiver<T>(T receiver) where T : class ,IFrameLuaExecutorReceiver
        {
	        if (null == receiver) return;
	        if (!LuaExecutorReceivers.Add(receiver)) return;
	        if (null == _luaExecutor) return;
	        receiver.OnSetupExecutor(_luaExecutor);
        }

        public static void UnRegisterLuaExecutorReceiver<T>(T receiver) where T : class, IFrameLuaExecutorReceiver
        {
	        if (null == receiver) return;
	        if (!LuaExecutorReceivers.Remove(receiver)) return;
	        if (null == _luaExecutor) return;
	        receiver.OnReleaseExecutor();
        }
    }
}
