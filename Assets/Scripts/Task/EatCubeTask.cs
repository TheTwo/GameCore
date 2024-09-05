public class EatCubeTask : Task
{
    public EatCubeTask()
    {
    }

    public override bool IsTaskComplete(GameData gameData)
    {
        return gameData.Score >= target;
    }
    
    public override string Description(GameData gameData)
    {
        return string.Format(Localization.GetLanguage("EatCubeTask"), target);
    }  

    public override string Achievement
    {

        get
        {
            return Localization.GetLanguage("EatCubeTask_Achievement_" + Target);
        }
    }
}
