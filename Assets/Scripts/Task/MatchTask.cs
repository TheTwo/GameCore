public class MatchTask : Task
{
    public MatchTask()
    {
    }

    public override bool IsTaskComplete(GameData gameData)
    {
        return gameData.MatchCount >= target;
    }

    public override string Description(GameData gameData)
    {
        return string.Format(Localization.GetLanguage("MatchTask"), target);
    }

    public override string Achievement
    {
        get
        {
            return "dddddddddd dddddddd";
        }
    }
}
