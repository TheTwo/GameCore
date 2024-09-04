using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn.Sound
{
	public class SoundManager : Singleton<SoundManager>, IManager, ITicker, IFrameworkSoundManager
    {
        private static IFrameworkSoundManager _soundManagerImpl;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void SetSoundManagerImpl()
        {
            FrameworkInterfaceManager.QueryFrameInterface(out _soundManagerImpl);
        }

        public void OnGameInitialize(object configParam)
        {
            _soundManagerImpl.OnGameInitialize(configParam);
        }

        public void Reset()
        {
	        _soundManagerImpl.Reset();
        }

        public void Tick(float delta) => _soundManagerImpl.Tick(delta);

        public bool IsReady => _soundManagerImpl.IsReady;

        public float BgmVolume
        {
            get => _soundManagerImpl.BgmVolume;
            set => _soundManagerImpl.BgmVolume = value;
        }

        public float SfxVolume
        {
            get => _soundManagerImpl.SfxVolume;
            set => _soundManagerImpl.SfxVolume = value;
        }

        public void InitSoundManager() => _soundManagerImpl.InitSoundManager();

        public void OnDependenceReady() => _soundManagerImpl.OnDependenceReady();

        public void SetSceneListener(Transform listenerRoot) => _soundManagerImpl.SetSceneListener(listenerRoot);

        public void SetResBaseAndAddPath() => _soundManagerImpl?.SetResBaseAndAddPath();

        public void PlayBgm(string eventName) => _soundManagerImpl.PlayBgm(eventName);

        public void StopBgm() => _soundManagerImpl.StopBgm();
        
        public void PlayAmb(string eventName) => _soundManagerImpl.PlayAmb(eventName);

        public void StopAmb() => _soundManagerImpl.StopAmb();

        public float GetCustomRTPC(string parameterName) => _soundManagerImpl.GetCustomRTPC(parameterName);

        public void SetCustomRTPC(string parameterName, float value) => _soundManagerImpl.SetCustomRTPC(parameterName, value);
        
        public float GetCustomRTPCOnGameObj(string parameterName, GameObject go, uint playingId) => _soundManagerImpl.GetCustomRTPCOnGameObj(parameterName, go, playingId);
        
        public void SetCustomRTPCOnGameObj(string parameterName, GameObject go, float value) => _soundManagerImpl.SetCustomRTPCOnGameObj(parameterName, go, value);

        public void SetCustomRTPCByPlayingId(string parameterName, uint playingId, float value) =>
            _soundManagerImpl.SetCustomRTPCByPlayingId(parameterName, playingId, value);

        public SoundPlayingHandle Play(string eventName, GameObject go = null, bool autoDestroyOnEnd = false) 
            => _soundManagerImpl.Play(eventName, go, autoDestroyOnEnd);

        public void Stop(SoundPlayingHandle playingHandle) 
            => _soundManagerImpl.Stop(playingHandle);

        public void Load(string resName) => _soundManagerImpl.Load(resName);

        public void UnLoad(string resName) => _soundManagerImpl.UnLoad(resName);

        public void SwitchAmb() => _soundManagerImpl.SwitchAmb();

        public ISoundEffect Create(string eventName, bool playAfterCreate = true, Transform parent = null, bool autoDestroyOnEnd = true) 
            => _soundManagerImpl.Create(eventName, playAfterCreate, parent, autoDestroyOnEnd);

        public void DestroySoundEffect(ISoundEffect soundEffect) => _soundManagerImpl.DestroySoundEffect(soundEffect);

        public void RuntimeModifyBankLruLimit(int limit) => _soundManagerImpl.RuntimeModifyBankLruLimit(limit);

		public void OnLowMemory()
		{

		}
	}
}
