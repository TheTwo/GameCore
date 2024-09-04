using DragonReborn;
using UnityEngine;

public abstract class U2DComponent : MonoBehaviour, IUpdater
{
	protected virtual void OnEnable()
	{
		Updater.Add(this);
	}

	protected virtual void OnDisable()
	{
		Updater.Remove(this);
	}

	public abstract void DoUpdate();
	public abstract void DoLateUpdate();
}
