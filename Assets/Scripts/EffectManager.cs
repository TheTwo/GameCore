using UnityEngine;
using System.Collections;
using UnityEngine.UI;
using Com.Duoyu001.Pool.U3D;
using Com.Duoyu001.Pool;

public class EffectManager : MonoBehaviour
{
    public GameObject tap;
    public GameObject touch;
    public GameObject scoreFlare;

    public GameObject starAddEffect;

    public U3DAutoRestoreObjectPool flyTextPool;
    public U3DAutoRestoreObjectPool scoreEffectPool;

    private GameObject tapGameObject;
    private GameObject touchGameOjbect;
    private RectTransform touchRectTransform;

    private static EffectManager instance;

    public static EffectManager Instance
    {
        get
        {
            if(instance == null)
            {
                instance = FindObjectOfType<EffectManager>();
            }

            return instance;
        }
    }

    private UIController uiController;

    void Start()
    {
        uiController = FindObjectOfType<UIController>();

        flyTextPool.Init();
        scoreEffectPool.Init();
    }

    public void AddFlyText(string text, Vector3 position)
    {
        IAutoRestoreObject<GameObject> autoRestoreObjec = flyTextPool.Take();
        GameObject flyText = autoRestoreObjec.Get();
        TimeBaseChecker checker = flyText.GetComponent<TimeBaseChecker>();
        checker.Init(2f);
        autoRestoreObjec.Restore = checker;

        flyText.transform.SetParent(uiController.transform);
        
        flyText.transform.localScale = Vector3.one;
        
        RectTransform rectTransform = flyText.GetComponent<RectTransform>();
        
        Vector3 sp = Camera.main.WorldToScreenPoint(position) + Vector3.right * 100;

        rectTransform.anchorMax = Vector2.zero;
        rectTransform.anchorMin = Vector2.zero;

        rectTransform.anchoredPosition = uiController.transform.InverseTransformVector(sp);
        
        flyText.GetComponentInChildren<Text>().text = text;
    }

    public void CumulativeEffect(Text numLabel, int target)
    {
        StartCoroutine(CumulativeEffectEnumerator(numLabel, target));
    }

    IEnumerator CumulativeEffectEnumerator(Text numLabel, int target)
    {
        int current = int.Parse(numLabel.text);

        if(current >= target)
        {
            yield break;
        }

        while (current < target)
        {
            if(target > current + 100)
            {
                current += 100;
            }
            else
            {
                current ++;
            }
            
            numLabel.text = current.ToString();
            
            yield return new WaitForSeconds(0.02f);
        }
    }

    public void ShowTapTip()
    {
        if (tapGameObject == null)
        {
            tapGameObject = Instantiate(tap) as GameObject;

            tapGameObject.transform.SetParent(uiController.transform);
            
            tapGameObject.transform.localScale = Vector3.one;
            
            RectTransform rectTransform = tapGameObject.GetComponent<RectTransform>();              
            
//            rectTransform.anchorMax = Vector2.zero;
//            rectTransform.anchorMin = Vector2.zero;
            
            rectTransform.anchoredPosition = new Vector2(0, Screen.height / 4);
        }

        tapGameObject.SetActive(true);
    }

    public void HideTapTip()
    {
        tapGameObject.SetActive(false);
    }

    public void ShowTouch(Vector3 position)
    {
        if (touchGameOjbect == null)
        {
            touchGameOjbect = Instantiate(touch) as GameObject;
            touchGameOjbect.transform.SetParent(uiController.transform);            
            touchGameOjbect.transform.localScale = Vector3.one;

            touchRectTransform = touchGameOjbect.GetComponent<RectTransform>();
            touchRectTransform.anchorMax = Vector2.zero;
            touchRectTransform.anchorMin = Vector2.zero;
        }

        touchGameOjbect.GetComponent<Animator>().SetTrigger("Play");

        touchRectTransform.anchoredPosition = uiController.transform.InverseTransformVector(position);
    }

    public void AddScoreEffect(Vector3 from)
    {		
        IAutoRestoreObject<GameObject> autoRestoreObjec = scoreEffectPool.Take();
        GameObject scoreEffect = autoRestoreObjec.Get();
        TimeBaseChecker checker = scoreEffect.GetComponent<TimeBaseChecker>();
        checker.Init(2f);
        autoRestoreObjec.Restore = checker;
        
        scoreEffect.transform.SetParent(uiController.transform);      
        scoreEffect.transform.localScale = Vector3.one;

        Vector3 target = Camera.main.ScreenToWorldPoint(new Vector3( 0, Screen.height, Camera.main.nearClipPlane));
        Vector3[] paths = { from, target};
        iTween.MoveTo(scoreEffect, iTween.Hash("path", paths, "time", 0.5f));
    }

    public void ShowScoreFlare()
    {
        scoreFlare.SetActive(true);

        Invoke("HideFlare", 0.5f);
    }

    public void ShowStarAdd(int star)
    {
        if (starAddEffect == null)
        {
            return;
        }
        
        // starAddEffect.SetActive(true);
        // starAddEffect.GetComponentInChildren<Text>().text = "+ " + star;

        // Invoke("HideStarAdd", 2f);
    }

    private void HideFlare()
    {
        scoreFlare.SetActive(false);
    }

    private void HideStarAdd()
    {
        starAddEffect.SetActive(false);
    }

    public void ShowSpeedBoostEffect(Vector3 position)
    {
        // 创建加速特效
        GameObject speedEffect = Instantiate(Resources.Load("Effects/SpeedBoostEffect") as GameObject);
        speedEffect.transform.position = position;
        
        // 设置特效的父物体
        speedEffect.transform.parent = transform;
        
        // 2秒后销毁特效
        Destroy(speedEffect, 2f);
    }
}
