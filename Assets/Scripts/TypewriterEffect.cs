using UnityEngine;
using System.Collections;
using UnityEngine.UI;
using System;

public class TypewriterEffect : MonoBehaviour
{
    private Text text;
    private Action callBack;

    void Awake()
    {
        text = GetComponent<Text>();
    }

    public void Run(Action callBack)
    {
        this.callBack = callBack;
        StartCoroutine("CoroutineRun");
    }

    IEnumerator CoroutineRun()
    {
        string totalString = text.text;
        int totalCount = totalString.Length;

        int displayCount = 0;

        while(displayCount <= totalCount)
        {
            text.text = totalString.Substring(0, displayCount++);
            yield return new WaitForSeconds(0.05f);
        }

//        yield return new WaitForSeconds(0.5f);
        callBack();
        yield return null;
    }
}
