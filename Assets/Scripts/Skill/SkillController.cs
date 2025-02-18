using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public enum SKILL  
{
    CHANGE_COLOR,
    DESTROY_TAIL,
    BOOST_SPEED
}

public class SkillController : MonoBehaviour
{
    public Button skillButton0;
    public Button skillButton1;
    public Button skillButton2;

    public GameController gameController;
    
    // Start is called before the first frame update
    void Start()
    {
        skillButton0.onClick.AddListener(() =>
        {
            Debug.Log("Skill 0");
            OnSkillButtonClick(SKILL.CHANGE_COLOR);
        });
        
        skillButton1.onClick.AddListener(() =>
        {
            Debug.Log("Skill 1");
            OnSkillButtonClick(SKILL.DESTROY_TAIL);
        });
        
        skillButton2.onClick.AddListener(() =>
        {
            Debug.Log("Skill 2");
            OnSkillButtonClick(SKILL.BOOST_SPEED);
        });
    }

    private void OnSkillButtonClick(SKILL skill)
    {
        gameController.UseSkill(skill);
    }
}
