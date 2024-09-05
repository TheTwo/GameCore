public class LevelTip : ITip
{ 
    public string Content
    {
        get
        {
            return Localization.GetLanguage("LevelTip");
        }
    }
    
    public bool ShouldShowTip(TutorialData tutorialData)
    {
        return tutorialData.Score >= GameConfig.LevelScore[1];
    }

    public void OnTipHide()
    {
    }
}
