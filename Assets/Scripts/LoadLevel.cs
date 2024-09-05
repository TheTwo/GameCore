using UnityEngine;
using System.Collections;

public class LoadLevel : MonoBehaviour {
    IEnumerator Start() {
        AsyncOperation async = Application.LoadLevelAsync("MainScene");
        yield return async;
        Debug.Log("Loading complete");
        Application.LoadLevel("MainScene");
    }

}
