/// <summary>
/// Sound manager.
/// This script use for manager all sound(bgm,sfx) in game
/// </summary>

using UnityEngine;
using System.Collections.Generic;

public class SoundManager : MonoBehaviour {
	
	[System.Serializable]
	public class SoundGroup{
		public AudioClip audioClip;
		public string soundName;
	}
	
	public AudioSource bgmSound;

	
	public List<SoundGroup> sound_List = new List<SoundGroup>();

    private int muteFlag;
    private static SoundManager _instance;
	
	public static SoundManager instance
    {
        get
        {
            if (_instance == null)
            {
                _instance = GameObject.Find("GameController").GetComponent<SoundManager>();
            }

            return _instance;
        }
    }
	
	public void Start(){
		_instance = this;	

        if (PlayerPrefs.GetInt(GameData.SOUND_ENABLE) == 0)
        {
            _instance.muteFlag = 1;
        }
        else
        {
            _instance.muteFlag = 0;
        }
        

	}
	
	public void PlayingSound(string _soundName, float volume, Vector3 position){
        AudioSource.PlayClipAtPoint(sound_List[FindSound(_soundName)].audioClip, position, volume * muteFlag);
	}

    public void PlayingSound(string _soundName)
    {
        AudioSource.PlayClipAtPoint(sound_List[FindSound(_soundName)].audioClip, Camera.main.transform.position, 1f * muteFlag);
    }

    public void PlayingSound(string _soundName, float volume)
    {
        AudioSource.PlayClipAtPoint(sound_List[FindSound(_soundName)].audioClip, Camera.main.transform.position, volume * muteFlag);
    }
	
	private int FindSound(string _soundName){
		int i = 0;
		while( i < sound_List.Count ){
			if(sound_List[i].soundName == _soundName){
				return i;	
			}
			i++;
		}
		return i;
	}
	
	//Start BGM when loading complete
	public void startBGM()
	{
        if (_instance.muteFlag > 0 && !bgmSound.isPlaying)
        {
            bgmSound.Play();
        }
	}

    public void stopBMG()
    {
        bgmSound.Stop();
    }

    public void Mute(bool mute)
    {
        if (mute)
        {
            stopBMG();
            muteFlag = 0;
        }
        else
        {
            muteFlag = 1;
            startBGM();
        }
    }
	
}
