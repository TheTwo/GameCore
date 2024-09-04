using UnityEngine;
using Unity.Mathematics;

public class U2DFacingCamera : U2DComponent
{
	public Camera FacingCamera;
	public float MaxScale = -1;
	[Range(0f, 0.1f)] public float OrthographicScale;
	public Vector3 screenOffsetDir;
	public float radius;
	public float facingOffset;
	public float yOffset;

	public static Camera MainCamera;
	private Transform trans;

	public float OrthographicScaleEffect => OrthographicScale * OrthographicScaleExtraScale;

	public float OrthographicScaleExtraScale { get; set; } = 1f;

	#region Camera Params
	private Camera __theCamera;
	private int lastFrameCount = -1;
	private float4x4 camSpaceMatrix;
	private float4x4 viewPortMatrix;
	private float4x4 viewPortMatrixInverse;
	private float4x4 camSpaceMatrixInverse;
	private float4 worldUpCS;
	private float3 camUpWS;
	private float3 camForawrdWS;
	#endregion

	private Camera theCamera
	{
		get
		{
			if (__theCamera == null)
			{
				theCamera = FacingCamera ? FacingCamera : MainCamera;
			}
			else if (__theCamera != (FacingCamera ? FacingCamera : MainCamera))
			{
				theCamera = FacingCamera ? FacingCamera : MainCamera;
			}
			return __theCamera;
		}

		set
		{
			if (value == null || __theCamera == value)
				return;
			__theCamera = value;
			lastFrameCount = -1;
			UpdateCameraValues();
		}
	}

	protected override void OnEnable()
	{
		trans = transform;
		trans.localPosition = Vector3.up * yOffset;
		if (OrthographicScaleEffect > 0)
		{
			trans.localScale = Vector3.zero;
		}

		screenOffsetDir.Normalize();

		base.OnEnable();
	}

	private void UpdateCameraValues()
	{
		if (lastFrameCount == Time.frameCount)
			return;
		lastFrameCount = Time.frameCount;

		camSpaceMatrix = __theCamera.worldToCameraMatrix;
		viewPortMatrix = __theCamera.projectionMatrix;
		viewPortMatrixInverse = math.inverse(viewPortMatrix);
		camSpaceMatrixInverse = math.inverse(camSpaceMatrix);
		worldUpCS = math.mul(camSpaceMatrix, new float4(0f, 1f, 0f, 0f));
		var camTrans = __theCamera.transform;
		camUpWS = camTrans.up;
		camForawrdWS = camTrans.forward;
	}

	private static bool PlaneRaycastInCS(float3 pNormal, float3 pPoint, float3 rayDir, out float enter)
	{
		float num = math.dot(rayDir, pNormal);
		//rayOrigin is zero in Camera Space
		float num2 = math.dot(pNormal, pPoint);//- math.dot(rayOrigin, pNormal); 
		if (math.abs(num - 0f) < math.EPSILON)
		{
			enter = 0f;
			return false;
		}
		enter = num2 / num;
		return enter > 0f;
	}


	public override void DoUpdate()
	{
		
	}

	public override void DoLateUpdate()
	{
		if (theCamera == null)
		{
			return;
		}
		UpdateCameraValues();
		var centerPos3 = (trans.parent != null) ? trans.parent.position : trans.position;
		//在摄像机空间中计算
		var centerPosCS = math.mul(camSpaceMatrix, new float4(centerPos3.x, centerPos3.y, centerPos3.z, 1));
		var centerPosVP = math.mul(viewPortMatrix, centerPosCS);
		if (centerPosVP.x < -centerPosVP.w
			|| centerPosVP.x > centerPosVP.w
			|| centerPosVP.y < -centerPosVP.w
			|| centerPosVP.y > centerPosVP.w
			)
		{
			if (OrthographicScaleEffect > 0)
			{
				transform.localScale = Vector3.zero;
			}
			return;
		}

		float4 finPosCS;
		if (screenOffsetDir.sqrMagnitude > 0 && radius > 0f && facingOffset > 0f)
		{
			//屏幕偏移方向计算出摄像机空间下的偏移的位置
			centerPosVP.x += screenOffsetDir.x;
			centerPosVP.y += screenOffsetDir.y;

			var vpOffsetPosCS = math.mul(viewPortMatrixInverse, centerPosVP);
			PlaneRaycastInCS(worldUpCS.xyz, centerPosCS.xyz, vpOffsetPosCS.xyz, out var distance);
			var offsetPosCS = vpOffsetPosCS.xyz * distance;

			var offsetDirCS = math.normalize(offsetPosCS - centerPosCS.xyz);
			finPosCS = new float4(centerPosCS.xyz + offsetDirCS * radius, 1f);
		}
		else
		{
			finPosCS = centerPosCS;
		}
		if (facingOffset > 0f)
		{
			//计算朝向摄像机的偏移          
			finPosCS.xyz -= math.normalize(finPosCS.xyz) * facingOffset;
		}
		
		if (OrthographicScaleEffect > 0f)
		{
			var scale = math.length(-finPosCS.xyz) * OrthographicScaleEffect;
			if (MaxScale > 0)
				scale = math.min(MaxScale, scale);
			trans.localScale = Vector3.one * scale;
			finPosCS += worldUpCS * yOffset * math.min(1, scale);
		}
		else
		{
			finPosCS += worldUpCS * yOffset;
		}

		trans.position = math.mul(camSpaceMatrixInverse, finPosCS).xyz;
		trans.rotation = Quaternion.LookRotation(camForawrdWS, camUpWS);
	}
}
