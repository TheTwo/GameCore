public class ScoreTask : Task
{
    public ScoreTask()
    {

    }

    public override bool IsTaskComplete(GameData gameData)
    {
        return gameData.Score >= target;
    }

    public override string Description(GameData gameData)
    {
        return string.Format(Localization.GetLanguage("ScoreTask"), target);
    }

    public override string Achievement
    {
        get
        {
            return Localization.GetLanguage("ScoreTask_Achievement_" + target);
        }
    }
}
