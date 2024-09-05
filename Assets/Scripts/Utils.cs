using UnityEngine;
using System.Collections;

public class Utils
{
    public static void ExecuteInSecs(float timeDelay, System.Action onFinished)
    {
        Utils.FindClass<GameController>().StartCoroutine(_ExecuteInSecs(timeDelay, onFinished));    
    }

    static IEnumerator _ExecuteInSecs(float timeDelay, System.Action onFinished)
    {
        yield return new WaitForSeconds(timeDelay);
        onFinished();
    }

    public static T FindClass<T>() where T : UnityEngine.Object
    {
        return UnityEngine.Object.FindObjectOfType(typeof(T)) as T;
    }
}
