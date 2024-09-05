using UnityEngine;

public class MoveTip : ITip
{
    public string Content
    {
        get
        {
            return Localization.GetLanguage("MoveTip");
        }
    }
    
    public bool ShouldShowTip(TutorialData tutorialData)
    {
        return tutorialData.MoveCount >= 4;
    }

    public void OnTipHide()
    {
        Debug.Log("move tip on hide");

//        GameObject.FindObjectOfType<Snake>().ChangeDirection();
    }
}
