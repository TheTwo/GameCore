// #define FINDSMOOTHASTARPATHHELPER_USE_ASTARPATHFINDING
using System;
using System.Collections.Generic;
using UnityEngine;
#if FINDSMOOTHASTARPATHHELPER_USE_ASTARPATHFINDING
using Pathfinding;
#else
using UnityEngine.AI;
#endif

// ReSharper disable once CheckNamespace
namespace DragonReborn.Utilities
{
    public static class FindSmoothAStarPathHelper
    {
#if FINDSMOOTHASTARPATHHELPER_USE_ASTARPATHFINDING
	    private static readonly Filter CachedFilter = new Filter();
	    private static List<Vector3> _buffer = new List<Vector3>();

	    public static PathHelperHandle FindPath(Vector3 startPos, Vector3 endPos, Action<List<Vector3>> callBack)
	    {
		    var handle = PathHelperHandle.Get(callBack);
            var path = ABPath.Construct(startPos, endPos, handle.ResultFromAStarPath);
            path.Claim(handle);
            AstarPath.StartPath(path);
            return handle;
        }

	    public static PathHelperHandle RandomPath(Vector3 startPos, int length ,Action<List<Vector3>> callBack)
	    {
		    var handle = PathHelperHandle.Get(callBack);
		    var path = Pathfinding.RandomPath.Construct(startPos, length, handle.ResultFromAStarPath);
		    path.Claim(handle);
		    AstarPath.StartPath(path);
		    return handle;
	    }

        private static void RayCastApply(Path p)
        {
	        var points = p.vectorPath;
	        if (null == points || points.Count <= 3) return;
	        CachedFilter.Path = p;
	        
	        // Use the same graph mask as the path.
	        // We don't want to use the tag mask or other options for this though since then the linecasting will be will confused.
	        var cachedNnConstraint = NNConstraint.None;
	        cachedNnConstraint.graphMask = p.nnConstraint.graphMask;

	        if (ValidateLine(null, null, p.vectorPath[0], p.vectorPath[p.vectorPath.Count-1], CachedFilter.CachedDelegate, cachedNnConstraint)) {
		        // A very common case is that there is a straight line to the target.
		        var s = p.vectorPath[0];
		        var e = p.vectorPath[p.vectorPath.Count-1];
		        points.ClearFast();
		        points.Add(s);
		        points.Add(e);
	        } else
	        {
		        for (int it = 0; it < 2; it++) {
			        if (it != 0) {
				        Polygon.Subdivide(points, _buffer, 3);
				        Pathfinding.Util.Memory.Swap(ref _buffer, ref points);
				        _buffer.ClearFast();
				        points.Reverse();
			        }

			        points = ApplyGreedy(p, points, CachedFilter.CachedDelegate, cachedNnConstraint);
		        }
		        points.Reverse();
	        }
	        p.vectorPath = points;
        }
        
        /// <summary>
		/// Check if a straight path between v1 and v2 is valid.
		/// If both n1 and n2 are supplied it is assumed that the line goes from the center of n1 to the center of n2 and a more optimized graph linecast may be done.
		/// </summary>
		private static bool ValidateLine (GraphNode n1, GraphNode n2, Vector3 v1, Vector3 v2, Func<GraphNode, bool> filter, NNConstraint nnConstraint) {
#if !ASTAR_NO_GRID_GRAPH
	        bool betweenNodeCenters = n1 != null && n2 != null;
#endif
	        if (n1 == null) n1 = AstarPath.active.GetNearest(v1, nnConstraint).node;
	        if (n2 == null) n2 = AstarPath.active.GetNearest(v2, nnConstraint).node;

	        if (n1 != null && n2 != null) {
		        // Use graph raycasting to check if a straight path between v1 and v2 is valid
		        NavGraph graph = n1.Graph;
		        NavGraph graph2 = n2.Graph;

		        if (graph != graph2) {
			        return false;
		        }

		        var rayGraph = graph as IRaycastableGraph;
#if !ASTAR_NO_GRID_GRAPH
		        GridGraph gg = graph as GridGraph;
		        if (betweenNodeCenters && gg != null) {
			        // If the linecast is exactly between the centers of two nodes on a grid graph then a more optimized linecast can be used.
			        // This method is also more stable when raycasting along a diagonal when the line just touches an obstacle.
			        // The normal linecast method may or may not detect that as a hit depending on floating point errors
			        // however this method never detect it as an obstacle (and that is very good for this component as it improves the simplification).
			        return !gg.Linecast(n1 as GridNodeBase, n2 as GridNodeBase, filter);
		        } else
#endif
		        if (rayGraph != null) {
			        return !rayGraph.Linecast(v1, v2, out GraphHitInfo _, null, filter);
		        }
	        }
			return true;
		}
        
        private static List<Vector3> ApplyGreedy (Path p, List<Vector3> points, Func<GraphNode, bool> filter, NNConstraint nnConstraint) {
	        bool canBeOriginalNodes = points.Count == p.path.Count;
	        int startIndex = 0;

	        while (startIndex < points.Count) {
		        Vector3 start = points[startIndex];
		        var startNode = canBeOriginalNodes && points[startIndex] == (Vector3)p.path[startIndex].position ? p.path[startIndex] : null;
		        _buffer.Add(start);

		        // Do a binary search to find the furthest node we can see from this node
		        int mn = 1, mx = 2;
		        while (true) {
			        int endIndex = startIndex + mx;
			        if (endIndex >= points.Count) {
				        mx = points.Count - startIndex;
				        break;
			        }
			        Vector3 end = points[endIndex];
			        var endNode = canBeOriginalNodes && end == (Vector3)p.path[endIndex].position ? p.path[endIndex] : null;
			        if (!ValidateLine(startNode, endNode, start, end, filter, nnConstraint)) break;
			        mn = mx;
			        mx *= 2;
		        }

		        while (mn + 1 < mx) {
			        int mid = (mn + mx)/2;
			        int endIndex = startIndex + mid;
			        Vector3 end = points[endIndex];
			        var endNode = canBeOriginalNodes && end == (Vector3)p.path[endIndex].position ? p.path[endIndex] : null;

			        if (ValidateLine(startNode, endNode, start, end, filter, nnConstraint)) {
				        mn = mid;
			        } else {
				        mx = mid;
			        }
		        }
		        startIndex += mn;
	        }

	        Pathfinding.Util.Memory.Swap(ref _buffer, ref points);
	        _buffer.ClearFast();
	        return points;
        }
        
        private static void ClearFast<T>(this List<T> list) {
	        if (list.Count*2 < list.Capacity) {
		        list.RemoveRange(0, list.Count);
	        } else {
		        list.Clear();
	        }
        }
        
        private static List<Vector3> SmoothSimple (List<Vector3> path, int subdivisions = 2, float strength = 0.5f, int iterations = 2) {
			if (path.Count < 2) return path;

			List<Vector3> subdivided;

			{
				subdivisions = Mathf.Max(subdivisions, 0);

				if (subdivisions > 10) {
					Debug.LogWarning("Very large number of subdivisions. Cowardly refusing to subdivide every segment into more than " + (1 << subdivisions) + " subsegments");
					subdivisions = 10;
				}

				int steps = 1 << subdivisions;
				subdivided = Pathfinding.Util.ListPool<Vector3>.Claim((path.Count-1)*steps + 1);
				Polygon.Subdivide(path, subdivided, steps);
			}

			if (strength > 0) {
				for (int it = 0; it < iterations; it++) {
					Vector3 prev = subdivided[0];

					for (int i = 1; i < subdivided.Count-1; i++) {
						Vector3 tmp = subdivided[i];

						// prev is at this point set to the value that subdivided[i-1] had before this loop started
						// Move the point closer to the average of the adjacent points
						subdivided[i] = Vector3.Lerp(tmp, (prev+subdivided[i+1])/2F, strength);

						prev = tmp;
					}
				}
			}
			return subdivided;
		}

        private class Filter {
	        public Path Path;
	        public readonly Func<GraphNode, bool> CachedDelegate;

	        public Filter() {
		        CachedDelegate = CanTraverse;
	        }

	        bool CanTraverse (GraphNode node) {
		        return Path.CanTraverse(node);
	        }
        }
        
#endif

        public class PathHelperHandle
        {
	        private static readonly Stack<PathHelperHandle> Pool = new Stack<PathHelperHandle>();

#if FINDSMOOTHASTARPATHHELPER_USE_ASTARPATHFINDING
	        public readonly OnPathDelegate ResultFromAStarPath;
#else
	        public readonly Action<ArraySegment<Vector3>> ResultFromNavmeshCall;
#endif
	        

	        private bool _released;

	        private XLua.LuaTable _pathByPath;
	        
	        private XLua.LuaFunction _callBack;

	        private PathHelperHandle()
	        {
#if FINDSMOOTHASTARPATHHELPER_USE_ASTARPATHFINDING
		        ResultFromAStarPath = CallAndClear;
#else
				ResultFromNavmeshCall = CallNavMesh;
#endif
	        }

	        public static PathHelperHandle Get(XLua.LuaFunction callBack, XLua.LuaTable pathBypass)
	        {
		        var ret = Pool.Count > 0 ? Pool.Pop() : new PathHelperHandle();
		        ret._released = false;
		        ret._callBack = callBack;
		        ret._pathByPath = pathBypass;
		        return ret;
	        }
	        
	        public void Release()
	        {
		        if (_released) return;
		        _released = true;
		        _callBack = null;
		        _pathByPath = null;
		        Recycle(this);
	        }

#if FINDSMOOTHASTARPATHHELPER_USE_ASTARPATHFINDING

	        private void CallAndClear(Path p)
	        {
		        if (!_released)
		        {
			        if (null != p.vectorPath)
			        {
				        RayCastApply(p);
				        var smoothed = SmoothSimple(p.vectorPath);
				        _callBack?.Invoke(smoothed);
				        if (smoothed != p.vectorPath)
					        Pathfinding.Util.ListPool<Vector3>.Release(smoothed);
			        }
			        else
			        {
				        _callBack?.Invoke(null);
			        }
		        }
		        p.Release(this, true);
		        Release();
	        }
#else
	        private void CallNavMesh(ArraySegment<Vector3> p)
	        {
		        if (!_released)
		        {
			        if (p.Count > 1)
			        {
				        if (null != _callBack)
				        {
					        _pathByPath.Clear();
					        _pathByPath.AddRange(p);
					        _callBack?.Action(_pathByPath);
					        _pathByPath = null;
				        }
			        }
			        else
			        {
				        _callBack?.Action<XLua.LuaTable>(null);
			        }
		        }
		        Release();
	        }
#endif
	        
	        private static void Recycle(PathHelperHandle pathHelperHandle)
	        {
		        pathHelperHandle._callBack = null;
		        Pool.Push(pathHelperHandle);
	        }
        }
    }
}