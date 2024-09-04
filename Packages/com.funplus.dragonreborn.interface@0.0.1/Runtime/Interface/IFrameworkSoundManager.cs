using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    [UnityEngine.Scripting.RequireImplementors]
    public interface IFrameworkSoundManager : IFrameworkInterface<IFrameworkSoundManager>
    {
        void OnGameInitialize(object configParam);
        void Reset();
        void Tick(float delta);

        #region Features
        
        bool IsReady { get; }
        
        float BgmVolume { get; set; }
        float SfxVolume { get; set; }
        
        void InitSoundManager();
        void OnDependenceReady();
        void SetSceneListener(Transform listenerRoot);

        void SetResBaseAndAddPath();
        
        void PlayBgm(string eventName);
        void StopBgm();
        void PlayAmb(string eventName);
        void StopAmb();
        void SwitchAmb();
        float GetCustomRTPC(string parameterName);
        void SetCustomRTPC(string parameterName, float value);
        float GetCustomRTPCOnGameObj(string parameterName, GameObject go, uint playingId);
        void SetCustomRTPCOnGameObj(string parameterName, GameObject go, float value);
        void SetCustomRTPCByPlayingId(string parameterName, uint playingId, float value);
        
        SoundPlayingHandle Play(string eventName, GameObject go = null, bool autoDestroyOnEnd = false);
        void Stop(SoundPlayingHandle playingHandle);

        ISoundEffect Create(string eventName, bool playAfterCreate = true, Transform parent = null, bool autoDestroyOnEnd = true);
        void DestroySoundEffect(ISoundEffect soundEffect);
        
        void Load(string resName);
        void UnLoad(string resName);

        void RuntimeModifyBankLruLimit(int limit);

        #endregion
    }
}