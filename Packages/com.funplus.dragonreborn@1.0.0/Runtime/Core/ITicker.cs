namespace DragonReborn
{
	public enum TickInterval
	{
		One,
		Two,
	}
	
	[UnityEngine.Scripting.RequireImplementors]
	public interface ITicker
	{
		void Tick(float delta);
	}

	public interface ISecondTicker : ITicker
	{
		
	}

    public interface ITimeScaleIgnoredTicker : ITicker
    {
        
    }

    public interface ILateUpdateTicker : ITicker
    {
	    
    }
}

