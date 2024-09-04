using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;
using Random = UnityEngine.Random;

namespace DragonReborn
{
	public static class Utils
	{
		static public T AddMissingComponent<T>(this GameObject go) where T : Component
		{
			if (!go)
			{
				return null;
			}

			T comp = go.GetComponent<T> ();
			if (!comp)
			{
				comp = go.AddComponent<T> ();
			}
			return comp;
		}

		static public T AddMissingComponent<T>(this Component c) where T : Component
		{
			if (!c)
			{
				return null;
			}
			return AddMissingComponent<T>(c.gameObject);
		}

		static public void RemoveComponent<T>(this GameObject go) where T : Component
		{
			if (!go)
			{
				return;
			}

			var t = go.GetComponent<T>();
			if(t)
				GameObject.Destroy(t);
		}

		static public void RemoveComponent<T>(this Component c) where T : Component
		{
			if (!c)
			{
				return;
			}

			var t = c.GetComponent<T>();
			if(t)
				GameObject.Destroy(t);
		}

        static public void SetParticleColor(GameObject root, Color color)
        {
            var particles = root.GetComponentsInChildren<Renderer>(true);
            foreach (var particle in particles)
            {
                if (!particle.name.StartsWith("color_")) continue;
                foreach (var mat in particle.materials)
                {
                    mat.SetColor("_TintColor", color);
                }
            }
        }

		/// set gameobject visible with check "activeSelf"
		public static void SetVisible(this GameObject go, bool value)
		{
//			if(go.activeSelf ^ value)
			if(go!=null && go.activeSelf != value)
				go.SetActive(value);
		}

		public static void SetVisible(this Component c, bool value)
		{
			if(c !=null)
				SetVisible(c.gameObject, value);
		}
		
		public static void SetAnimationTime(this Animation animation, string clipName, float time)
		{
			if (animation != null)
			{
				AnimationState animationState = animation[clipName];
				if (animationState != null)
				{
					animationState.time = time;
				}
			}
		}
		
		public static bool GetCurrentAnimationNormalizedTime(this Animation animation, out float normalizedTime)
		{
			normalizedTime = default;
			if (animation == null || !animation.clip) return false;
			var animationState = animation[animation.clip.name];
			if (animationState == null) return false;
			normalizedTime = animationState.normalizedTime;
			return true;
		}
		
		public static bool GetCurrentAnimationNormalizedSpeed(this Animation animation, out float normalizedSpeed)
		{
			normalizedSpeed = default;
			if (animation == null || !animation.clip) return false;
			var animationState = animation[animation.clip.name];
			if (animationState == null) return false;
			normalizedSpeed = animationState.normalizedSpeed;
			return true;
		}

		public static void SetCurrentAnimationNormalizedTime(this Animation animation, float normalizedTime)
		{
			if (animation == null || !animation.clip) return;
			var animationState = animation[animation.clip.name];
			if (animationState != null)
			{
				animationState.normalizedTime = normalizedTime;
			}
		}
		
		public static void SetCurrentAnimationNormalizedSpeed(this Animation animation, float normalizedSpeed)
		{
			if (animation == null || !animation.clip) return;
			var animationState = animation[animation.clip.name];
			if (animationState != null)
			{
				animationState.normalizedSpeed = normalizedSpeed;
			}
		}

		public static float GetAnimationClipLength(this Animation animation, string clipName)
		{
			if (animation != null)
			{
				AnimationState animationState = animation[clipName];
				if (animationState != null)
				{
					return animationState.clip.length;
				}
			}
			return 0;
		}
		
		public static void SetAnimationSpeed(this Animation animation, string clipName, float speed)
		{
			if (animation != null)
			{
				AnimationState animationState = animation[clipName];
				if (animationState != null)
				{
					animationState.speed = speed;
				}
			}
		}

		public static void PlayAnimationClip(this Animation animation, string clipName)
		{
			if (animation != null)
			{
				AnimationState animationState = animation[clipName];
				if (animationState != null)
				{
					animation.Play(clipName);
				}
			}
		}

		public static void PlayAnimationClipEx(this Animation animation, string clipName, float speed, float normalizStartTime)
		{
			if (animation == null) return;
			AnimationState aState = animation[clipName];
			if (aState == null) return;			
			aState.normalizedTime = normalizStartTime;
			aState.speed = speed;
			animation.Play(clipName);
		}

		public static bool PlayAnimationClipAtIndex(this Animation animation, int index)
		{
			if (animation == null) return false;
			if (index < 0) return false;
			var clipCount = animation.GetClipCount();
			if (index >= clipCount) return false;
			var i = 0;
			foreach (AnimationState state in animation)
			{
				if (i++ != index) continue;
				animation.Play(state.clip.name);
				return true;
			}
			return false;
		}

		public static bool SetAnimationNormalizedTimeByIndex(this Animation animation, int index, float normalizedTime)
		{
			if (animation == null) return false;
			if (index < 0) return false;
			var clipCount = animation.GetClipCount();
			if (index >= clipCount) return false;
			var i = 0;
			foreach (AnimationState state in animation)
			{
				if (i++ != index) continue;
				animation.Play(state.clip.name);
				state.normalizedTime = normalizedTime;
				animation.Sample();
				return true;
			}
			return false;
		}

		public static bool IsNullOrEmpty<T>(this ICollection list)
		{
			return list == null || list.Count == 0;
		}

		public static bool IsNullOrEmpty<T>(this ICollection<T> list)
		{
			return list == null || list.Count == 0;
		}

		public static T GetRandomElement<T>(this List<T> list)
		{
			if (list.Count == 0)
				return default;

			return list[Random.Range(0, list.Count)];
		}
		
		// 非数组，List等情况下O(n)，否则O(1)
		public static T GetRandomElement<T>(this IEnumerable<T> enumerable)
		{
			if (!enumerable.Any())
				return default;
			
			return enumerable.ElementAt(Random.Range(0, enumerable.Count()));
		}

		public static bool IsNullOrEmpty(this string str)
		{
			return string.IsNullOrEmpty(str);
		}

        public static AnimationState GetAnimationState(this Animation animation, string clipName)
        {
            if (animation != null)
            {
                AnimationState animationState = animation[clipName];
                if (animationState == null)
                {
                    animationState = animation[clipName + "_u2"];
                }

                if (animationState != null)
                {
                    return animationState;
                }
            }
            return null;
        }
        
        public static void SetLayer(GameObject gameObject, int layer, bool allChildren = false )
        {
	        if (gameObject == null) return;
	        
	        gameObject.layer = layer;
	        if (allChildren)
	        {
		        Transform t = gameObject.transform;

		        for (int i = 0, imax = t.childCount; i < imax; ++i)
		        {
			        Transform child = t.GetChild(i);
			        if (child != null && child.gameObject != null)
			        {
				        SetLayer(child.gameObject, layer, true);    
			        }
		        }
	        }
        }

		public static void SetLightsLayerMask(GameObject gameObject, int layer)
		{
			if (gameObject == null) return;
			var lights = gameObject.GetComponentsInChildren<Light>();
			if (lights != null && lights.Length > 0)
			{
				if (layer <= 0)
				{
					for (int i = 0; i < lights.Length; i++)
					{
						lights[i].cullingMask = 0;
					}
				}
				else 
				{ 
					var litMask = 1 << layer;
					for (int i = 0; i < lights.Length; i++)
					{
						lights[i].cullingMask = litMask;
					}
				}
			}
		}

		public static void AddLightLayerMask(GameObject gameObject, int layer)
		{
			if (gameObject == null && layer > 0) return;
			var lights = gameObject.GetComponentsInChildren<Light>();
			if (lights != null && lights.Length > 0)
			{
				var litMask = 1 << layer;
				for (int i = 0; i < lights.Length; i++)
				{
					lights[i].cullingMask |= litMask;
				}
			}
		}

		/// <summary>
		///
		/// </summary>		
		/// <param name="A">Point in Circle </param>
		/// <param name="T">Point out Circle</param>
		/// <param name="r">Circle Radius</param>
		/// <returns></returns>
		public static Vector3 CalcPosOnCircleLocalXZ( Vector3 A, Vector3 T, float r)
		{
			//var O = Vector3.zero;
			A.y = 0f;
			T.y = 0f;

			var TA = A - T;
			var TO = - T;

			float pjtTO2TA = Vector2.Dot(TO, TA.normalized);
			var K = T + TA.normalized * pjtTO2TA;

			float Lkp = Mathf.Sqrt(Mathf.Max(0.01f, r * r - K.sqrMagnitude));
			return K + (T - K).normalized * Lkp;
		}

		public static int GetHashCode(string str)
		{
			return str.GetHashCode();
		}
	}
}
