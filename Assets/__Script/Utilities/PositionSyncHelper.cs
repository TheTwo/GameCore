using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PositionSyncHelper : MonoBehaviour
{
	[SerializeField]	
	private Transform target;	
	// Update is called once per frame
	void LateUpdate()
    {
		if (target == null)
		{
			enabled = false;			
			return;
		}
		transform.position = target.position;
    }

	public void SetTarget(Transform target)
	{
		this.target = target;
		enabled = true;
	}
}
