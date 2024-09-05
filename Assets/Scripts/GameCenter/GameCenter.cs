using UnityEngine;

public class GameCenter : MonoBehaviour {

	// Use this for initialization
	void Start () {
        //C#
        Social.localUser.Authenticate (success => {
            if (success) {
                Debug.Log ("Authentication successful");
                string userInfo = "Username: " + Social.localUser.userName + 
                    "\nUser ID: " + Social.localUser.id + 
                        "\nIsUnderage: " + Social.localUser.underage;
                Debug.Log (userInfo);

            }
            else
                Debug.Log ("Authentication failed");
        });
	}
}