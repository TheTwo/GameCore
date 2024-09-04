using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using XLua;

namespace DragonReborn
{
    // 已经添加到XLuaConfig
    public static class UnityObjectExtension
    {
        private static readonly List<LuaBehaviour> Behaviours = new();
        private static readonly List<Component> Components = new();

        public static bool IsClassOf(this LuaBehaviour behaviour, string className)
        {
            LuaTable klass = null;
            string cname = null;
            behaviour.Instance?.Get("__class", out klass);
            
            do
            {
                klass?.Get("__cname", out cname);
                
                if (cname == className)
                {
                    return true;
                }
                
                klass?.Get("super", out klass);
            } while (klass != null);

            return false;
        }
        
        public static LuaBehaviour GetLuaBehaviour(this GameObject go, string name)
        {
            if (go == null)
            {
                return null;
            }

            LuaBehaviour result = null;
            
            go.GetComponents(Behaviours);
            foreach (var behaviour in Behaviours)
            {
                if (behaviour.IsClassOf(name))
                {
                    result = behaviour;
                    break;
                }
            }

            Behaviours.Clear();

            return result;
        }
        
        public static void GetLuaBehaviours(this GameObject go, string name, LuaTable behaviours)
        {
            if (go == null)
            {
                return;
            }

            go.GetComponents(Behaviours);
            var l = behaviours.Length;
            foreach (var behaviour in Behaviours)
            {
                if (behaviour.IsClassOf(name))
                {
                    behaviours.Set(++l, behaviour);
                }
            }

            Behaviours.Clear();
        }

        public static LuaBehaviour GetLuaBehaviourInChildren(this GameObject go, string name, bool includeInactive)
        {
            if (go == null)
            {
                return null;
            }

            LuaBehaviour result = null;

            go.GetComponentsInChildren(includeInactive, Behaviours);
            foreach (var behaviour in Behaviours)
            {
                if (behaviour.IsClassOf(name))
                {
                    result = behaviour;
                    break;
                }
            }

            Behaviours.Clear();

            return result;
        }
        
        public static void GetLuaBehavioursInChildren(this GameObject go, string name, LuaTable behaviours,
	        bool includeInactive)
        {
	        if (go == null)
	        {
		        return;
	        }

	        go.GetComponentsInChildren(includeInactive, Behaviours);
	        var l = behaviours.Length;
	        foreach (var behaviour in Behaviours)
	        {
		        if (behaviour.IsClassOf(name))
		        {
			        behaviours.Set(++l, behaviour);
		        }
	        }

	        Behaviours.Clear();
        }

        public static void GetLuaBehavioursInChildren(this GameObject go, string name, List<LuaBehaviour> behaviours,
            bool includeInactive)
        {
            if (go == null)
            {
                return;
            }

            go.GetComponentsInChildren(includeInactive, Behaviours);
            foreach (var behaviour in Behaviours)
            {
                if (behaviour.IsClassOf(name))
                {
                    behaviours.Add(behaviour);
                }
            }

            Behaviours.Clear();
        }

        public static LuaBehaviour GetLuaBehaviourInParent(this GameObject go, string name, bool includeInactive)
        {
	        if (go == null)
	        {
		        return null;
	        }

	        LuaBehaviour result = null;
	        go.GetComponentsInParent(includeInactive, Behaviours);
	        foreach (var behaviour in Behaviours)
	        {
		        if (behaviour.IsClassOf(name))
		        {
			        result = behaviour;
			        break;
		        }
	        }
	        
	        Behaviours.Clear();
	        return result;
        }
        
        public static void GetLuaBehavioursInParent(this GameObject go, string name, List<LuaBehaviour> behaviours,
	        bool includeInactive)
        {
	        if (go == null)
	        {
		        return;
	        }

	        go.GetComponentsInParent(includeInactive, Behaviours);
	        foreach (var behaviour in Behaviours)
	        {
		        if (behaviour.IsClassOf(name))
		        {
			        behaviours.Add(behaviour);
		        }
	        }

	        Behaviours.Clear();
        }

        public static LuaBehaviour AddLuaBehaviourWithType(this GameObject go, Type type, string script, string schema = default)
        {
	        if (!typeof(LuaBehaviour).IsAssignableFrom(type))
	        {
		        throw new ArgumentException($"type:{type.FullName} is not a LuaBehaviour");
	        }
	        
	        var behaviour = (LuaBehaviour)go.AddComponent(type);
	        behaviour.scriptName = script;
	        behaviour.schemaName = schema;
	        if (go.activeInHierarchy)
	        {
		        behaviour.Awake();
	        }
	        return behaviour;
        }

        public static LuaBehaviour AddLuaBehaviour(this GameObject go, string script, string schema = default)
        {
            var behaviour = go.AddComponent<LuaBehaviour>();
            behaviour.scriptName = script;
            behaviour.schemaName = schema;
            if (go.activeInHierarchy)
            {
                behaviour.Awake();
            }

            return behaviour;
        }

        public static LuaBehaviour AddMissingLuaBehaviour(this GameObject go, string script, string schema = default)
        {
            var behaviour = go.GetLuaBehaviour(script);
            if (!behaviour)
            {
                behaviour = go.AddLuaBehaviour(script, schema);
            }

            return behaviour;
        }
        
        public static LuaBehaviour GetLuaBehaviour(this Component component, string name)
        {
            if (component == null)
            {
                return null;
            }

            return component.gameObject.GetLuaBehaviour(name);
        }

        public static LuaBehaviour GetLuaBehaviourInChildren(this Component component, string name, bool includeInactive)
        {
            if (component == null)
            {
                return null;
            }

            return component.gameObject.GetLuaBehaviourInChildren(name, includeInactive);
        }

        public static void GetLuaBehavioursInChildren(this Component component, string name, List<LuaBehaviour> behaviours,
            bool includeInactive)
        {
            if (component == null)
            {
                return;
            }

            component.gameObject.GetLuaBehavioursInChildren(name, behaviours, includeInactive);
        }

        public static void GetComponentsInChildrenByType(this GameObject go, Type type,
            List<Component> results, bool includeInactive)
        {
            if (go == null || type == null || results == null)
            {
                return;
            }

            go.GetComponentsInChildren(includeInactive, Components);
            foreach (var component in Components)
            {
                if (component.GetType() == type)
                {
                    results.Add(component);
                }
            }

            Components.Clear();
        }

        public static void GetComponentsInChildrenByType(this Component component, Type type,
            List<Component> results, bool includeInactive)
        {
            if (component == null)
            {
                return;
            }

            component.gameObject.GetComponentsInChildrenByType(type, results, includeInactive);
        }
        
        public static void GetComponentsInChildrenOfType(this GameObject go, Type type,
	        List<Component> results, bool includeInactive)
        {
	        if (go == null || type == null || results == null)
	        {
		        return;
	        }

	        go.GetComponentsInChildren(includeInactive, Components);
	        foreach (var component in Components)
	        {
		        var compType = component.GetType();
		        if (compType == type || compType.IsSubclassOf(type))
		        {
			        results.Add(component);
		        }
	        }

	        Components.Clear();
        }
        
        public static void GetComponentsInChildrenOfType(this Component component, Type type,
	        List<Component> results, bool includeInactive)
        {
	        if (component == null)
	        {
		        return;
	        }

	        component.gameObject.GetComponentsInChildrenOfType(type, results, includeInactive);
        }

        public static bool IsNull(this UnityEngine.Object o)
        {
            return o == null;
        }

        public static unsafe void GetChildrenMeshBoundsViewport(this GameObject go, Camera camera, out bool ret,
	        out Vector2 minViewport, out Vector2 maxViewport)
        {
	        using (ListPool<Renderer>.Get(out var meshes))
	        {
		        go.GetComponentsInChildren(meshes);
		        ret = meshes.Count > 0;
		        minViewport = new Vector2(float.MaxValue, float.MaxValue);
		        maxViewport = new Vector2(float.MinValue, float.MinValue);
		        // minView2World = new Vector3(float.MaxValue, float.MaxValue, float.MaxValue);
		        // maxView2World = new Vector3(float.MinValue, float.MinValue, float.MinValue);

		        if (ret)
		        {
			        var corners = new Vector3[4];
			        var bigBounds = new Bounds();
			        var u2dWidgetMeshCorner = new List<Vector3>();
			        foreach (var meshRenderer in meshes)
			        {
				        // 粒子不参与计算
				        if (meshRenderer is ParticleSystemRenderer)
					        continue;
			        
				        var u2d = meshRenderer.GetComponent<U2DWidgetMesh>();
				        if (!u2d)
				        {
					        var bounds = meshRenderer.bounds;
					        if (bigBounds.extents == Vector3.zero)
						        bigBounds = bounds;
					        else
						        bigBounds.Encapsulate(bounds);
				        }
				        else
				        {
					        fixed (Vector3* cornerBuffer = corners)
					        {
						        U2DUtils.CalculateRectCorners(u2d.rect, cornerBuffer);
						        U2DUtils.TransformCorners(cornerBuffer, u2d.transform.localToWorldMatrix);    
					        }
				        
					        u2dWidgetMeshCorner.AddRange(corners);
				        }
			        }

			        var worldCorners = GetBoundsCorners(in bigBounds);
			        var viewportCorners = new Vector3[worldCorners.Length + u2dWidgetMeshCorner.Count];
			        u2dWidgetMeshCorner.AddRange(worldCorners);
			        for (int i = 0; i < u2dWidgetMeshCorner.Count; i++)
			        {
				        viewportCorners[i] = camera.WorldToViewportPoint(u2dWidgetMeshCorner[i]);
			        }

			        for (int i = 0; i < viewportCorners.Length; i++)
			        {
				        minViewport = Vector2.Min(minViewport, viewportCorners[i]);
				        maxViewport = Vector2.Max(maxViewport, viewportCorners[i]);
			        }
		        }
	        }
        }

        public static Vector3[] GetBoundsCorners(in Bounds bounds)
        {
	        if (bounds.extents == Vector3.zero)
		        return Array.Empty<Vector3>();
	        
	        Vector3[] corners = new Vector3[8];

	        corners[0] = bounds.min; // 左下后
	        corners[1] = new Vector3(bounds.min.x, bounds.min.y, bounds.max.z); // 左下前
	        corners[2] = new Vector3(bounds.max.x, bounds.min.y, bounds.max.z); // 右下前
	        corners[3] = new Vector3(bounds.max.x, bounds.min.y, bounds.min.z); // 右下后
	        corners[4] = new Vector3(bounds.min.x, bounds.max.y, bounds.min.z); // 左上后
	        corners[5] = new Vector3(bounds.min.x, bounds.max.y, bounds.max.z); // 左上前
	        corners[6] = bounds.max; // 右上前
	        corners[7] = new Vector3(bounds.max.x, bounds.min.y, bounds.min.z); // 右上后

	        return corners;
        }

        /// <summary>
        /// 平铺RectTransform.GetWorldCorner结果
        /// </summary>
        public static void GetTiledWorldCorner(this RectTransform trans, out Vector3 lb, out Vector3 lt,
	        out Vector3 rt, out Vector3 rb)
        {
	        Vector3[] dump = new Vector3[4];
	        trans.GetWorldCorners(dump);
	        lb = dump[0];
	        lt = dump[1];
	        rt = dump[2];
	        rb = dump[3];
        }
    }
}
