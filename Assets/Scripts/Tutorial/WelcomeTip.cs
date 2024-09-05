public class WelcomeTip : ITip
{
    public string Content
    {
        get
        {
            return Localization.GetLanguage("WelcomeTip");
        }
    }
    
    public bool ShouldShowTip(TutorialData tutorialData)
    {
        return tutorialData.MoveCount > 0;
    }

    public void OnTipHide()
    {

    }
}
