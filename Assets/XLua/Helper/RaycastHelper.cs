using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using XLua;
#if USE_UNI_LUA
using LuaAPI = UniLua.Lua;
using RealStatePtr = UniLua.ILuaState;
using LuaCSFunction = UniLua.CSharpFunctionDelegate;
#else
#if CHECK_XLUA_API_CALL_ENABLE
using LuaAPI = XLua.LuaDLL.LuaDLLWrapper;
#else
using LuaAPI = XLua.LuaDLL.Lua;
#endif
using RealStatePtr = System.IntPtr;
using LuaCSFunction = XLua.LuaDLL.lua_CSFunction;
#endif

public static class RaycastHelper
{
    private class RaycastHitDistanceComparer : IComparer<RaycastHit>
    {
        public int Compare(RaycastHit x, RaycastHit y)
        {
            return x.distance.CompareTo(y.distance);
        }
    }
    
    private class RaycastHitDistanceReverseComparer : IComparer<RaycastHit>
    {
        public int Compare(RaycastHit x, RaycastHit y)
        {
            return y.distance.CompareTo(x.distance);
        }
    }

    private static RaycastHit[] _buffer = new RaycastHit[16];
    private static readonly RaycastHitDistanceComparer _distanceComparer = new RaycastHitDistanceComparer();
    private static readonly RaycastHitDistanceReverseComparer _distanceReverseComparer = new RaycastHitDistanceReverseComparer();

    [MonoPInvokeCallback(typeof(LuaCSFunction))]
    public static int RaycastNonAlloc(RealStatePtr L)
    {
        try
        {
            ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
            translator.Get<Ray>(L, 1, out var ray);
            var maxDistance = (float)LuaAPI.lua_tonumber(L, 2);
            var layerMask = LuaAPI.xlua_tointeger(L, 3);
            var ret = Physics.RaycastNonAlloc(ray, _buffer, maxDistance, layerMask);
            LuaAPI.xlua_pushinteger(L, ret);
            if (ret > 0)
            {
                Array.Sort(_buffer, 0, ret, _distanceComparer);
                LuaAPI.lua_newtable(L);
                for (int i = 0; i < ret; i++)
                {
                    LuaAPI.lua_pushnumber(L, i + 1);
                    translator.Push(L, _buffer[i].collider.gameObject);
                    LuaAPI.xlua_psettable(L, -3);
                }
                LuaAPI.lua_newtable(L);
                for (int i = 0; i < ret; i++)
                {
                    LuaAPI.lua_pushnumber(L, i + 1);
                    // translator.PushUnityEngineVector3(L, _buffer[i].point);
                    LuaAPI.xlua_psettable(L, -3);
                }
                return 3;
            }
            return 1;
        }
        catch (LuaStackTraceException e)
        {
            UnityEngine.Debug.LogException(e);
            return LuaAPI.luaL_error(L, "c# exception in RaycastNonAlloc: " + e);
        }
        catch (System.Exception e)
        {
            return LuaAPI.luaL_error(L, "c# exception in RaycastNonAlloc: " + e);
        }
    }
    
    [MonoPInvokeCallback(typeof(LuaCSFunction))]
    public static int BoxcastNonAlloc(RealStatePtr L)
    {
        try
        {
            ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
            UnityEngine.Vector3 _origin;translator.Get(L, 1, out _origin);
            UnityEngine.Vector3 _halfExtents;translator.Get(L, 2, out _halfExtents);
            UnityEngine.Vector3 _direction;translator.Get(L, 3, out _direction);
            UnityEngine.Quaternion _quaternion;translator.Get(L, 4, out _quaternion);
            var maxDistance = (float)LuaAPI.lua_tonumber(L, 5);
            var layerMask = LuaAPI.xlua_tointeger(L, 6);
            var ret = Physics.BoxCastNonAlloc(_origin, _halfExtents, _direction, _buffer, _quaternion, maxDistance, layerMask);
            LuaAPI.xlua_pushinteger(L, ret);
            if (ret > 0)
            {
                Array.Sort(_buffer, 0, ret, _distanceComparer);
                LuaAPI.lua_newtable(L);
                for (int i = 0; i < ret; i++)
                {
                    LuaAPI.lua_pushnumber(L, i + 1);
                    translator.Push(L, _buffer[i].collider.gameObject);
                    LuaAPI.xlua_psettable(L, -3);
                }
                LuaAPI.lua_newtable(L);
                for (int i = 0; i < ret; i++)
                {
                    LuaAPI.lua_pushnumber(L, i + 1);
                    // translator.PushUnityEngineVector3(L, _buffer[i].point);
                    LuaAPI.xlua_psettable(L, -3);
                }
                return 3;
            }
            return 1;
        }
        catch (LuaStackTraceException e)
        {
            UnityEngine.Debug.LogException(e);
            return LuaAPI.luaL_error(L, "c# exception in BoxRaycastNonAlloc: " + e);
        }
        catch (System.Exception e)
        {
            return LuaAPI.luaL_error(L, "c# exception in BoxRaycastNonAlloc: " + e);
        }
    }
    
    [LuaCallCSharp]
    public static Transform PhysicsRaycast(Ray ray, float maxDistance, int layerMask)
    {
        var count = Physics.RaycastNonAlloc(ray, _buffer, maxDistance, layerMask);
        if (count < 1)
        {
            return null;
        }
        else
        {
            return _buffer[0].transform;
        }
    }

    public static bool PhysicsRaycastOriginHit(Vector3 origin, Vector3 direction, float maxDistance, out RaycastHit hit)
    {
        return Physics.Raycast(origin, direction, out hit, maxDistance);
    }

    public static bool PhysicsRaycastOriginHitWithLayerMask(Vector3 origin, Vector3 direction, float maxDistance, int layerMask, out RaycastHit hit)
    {
        return Physics.Raycast(origin, direction, out hit, maxDistance, layerMask);
    }

    public static bool PhysicsRaycastRayHit(Ray ray, out RaycastHit hit)
    {
        return Physics.Raycast(ray, out hit);
    }

    public static bool PhysicsRaycastRayHitWithMask(Ray ray, float maxDistance, int layerMask, out Vector3 point)
    {
	    if (Physics.Raycast(ray, out var hit, maxDistance, layerMask))
	    {
		    point = hit.point;
		    return true;
	    }

	    point = Vector3.zero;
	    return false;
    }

    public static bool PhysicsRaycastRayHitByLayer(Ray ray, string[] names, out RaycastHit hit)
    {
        int layer = 0;
        for (int i = 0; i < names.Length; i++)
            layer |= 1 << LayerMask.NameToLayer(names[i]);
        return Physics.Raycast(ray, out hit, float.MaxValue, layer);
    }

    private static bool IsVisibleInUI(Transform trs, bool isBase)
    {
        var graphic = trs.GetComponent<Graphic>();
        if (graphic)
        {
            if (isBase && graphic.color.a < 0.001) return false;
            if (graphic.canvasRenderer && graphic.canvasRenderer.GetAlpha() < 0.001) return false;
            if (graphic.canvas && !graphic.canvas.enabled) return false;
        }
        var canvasGroup = trs.GetComponent<CanvasGroup>();
        if (canvasGroup && canvasGroup.alpha < 0.001) return false;
        var parent = trs.parent;
        return !parent || IsVisibleInUI(parent, false);
    }

    private static RaycastHit2D[] _2Dbuffer = new RaycastHit2D[10];
    public static bool Physics2DBoxCast(Vector2 origin, Vector2 size, float angle, Vector2 direction, float distance,
	    int layerMask, out RaycastHit2D hitInfo, int minDepth = 0, int maxDepth = 0, bool noCheckUIVisible = false)
    {
	    var number = Physics2D.BoxCastNonAlloc(origin, size, angle, direction, _2Dbuffer, distance, layerMask, minDepth, maxDepth);
	    if (number > 0)
        {
            if (noCheckUIVisible)
            {
                hitInfo = _2Dbuffer[0];
                return true;
            }
            for (var i = 0; i < number; i++)
            {
                if (!IsVisibleInUI(_2Dbuffer[i].transform, true)) continue;
                hitInfo = _2Dbuffer[i];
                return true;
            }

        }

	    hitInfo = default;
	    return false;
    }
    
    public static bool Physics2DBoxCastOutCentroid(Vector2 origin, Vector2 size, float angle, Vector2 direction, float distance, int layerMask, out Vector3 centroid, int minDepth = 0, int maxDepth = 0, bool noCheckUIVisible = false)
    {
	    var ret = Physics2DBoxCast(origin, size, angle, direction, distance, layerMask, out var hitInfo, minDepth,
		    maxDepth,noCheckUIVisible);
	    centroid = default;
	    if (ret)
	    {
		    centroid = hitInfo.centroid;
	    }

	    return ret;
    }
    
    public static bool PlaneRaycast(Plane plane, Ray ray, out Vector3 point)
    {
	    if (plane.Raycast(ray, out var enter))
	    {
		    point = ray.GetPoint(enter);
		    return true;
	    }

	    point = default;
	    return false;
    }
}