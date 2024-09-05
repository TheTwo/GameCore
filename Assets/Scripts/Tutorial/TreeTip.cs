using UnityEngine;

public class TreeTip : ITip
{
    public string Content
    {
        get
        {
            return Localization.GetLanguage("TreeTip");
        }
    }

    public bool ShouldShowTip(TutorialData tutorialData)
    {
        return tutorialData.MoveCount >= 4;
    }

    public void OnTipHide()
    {        
        Time.timeScale = 0.5f;

        Utils.ExecuteInSecs(1f, delegate()
        {
            Time.timeScale = 1f;
        });
    }
}
