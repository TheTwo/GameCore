public class EatCubeTip : ITip
{
    public string Content
    {
        get
        {
            return Localization.GetLanguage("EatCubeTip");
        }
    }
    
    public bool ShouldShowTip(TutorialData tutorialData)
    {
        return tutorialData.MoveCount >= 13;
    }

    public void OnTipHide()
    {
    }
}
