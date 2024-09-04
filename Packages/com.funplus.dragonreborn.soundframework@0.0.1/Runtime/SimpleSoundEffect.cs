using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn.Sound
{
    public class SimpleSoundEffect : MonoBehaviour, ISoundEffect
    {
        public GameObject GameObj => gameObject;

        private string _eventName;
        public string EventName => _eventName;

        private bool _isPlaying;
        public bool IsPlaying => _isPlaying;

        private SoundPlayingHandle _soundPlayingHandle;

        public bool IsAlive
        {
            get
            {
                try
                {
                    return (bool) gameObject;
                }
                catch
                {
                    return false;
                }
            }
        }

        private bool _destroyOnEnd;
        
        public bool DestroyOnEnd => _destroyOnEnd;

        public void Initialize(string eventName,bool destroyOnEnd)
        {
            Reset();
            _eventName = eventName;
            _destroyOnEnd = destroyOnEnd;
        }
        
        public void Play()
        {
            if (_isPlaying || string.IsNullOrWhiteSpace(_eventName) || !IsAlive) return;
            _soundPlayingHandle = SoundManager.Instance.Play(_eventName,gameObject,_destroyOnEnd);
            _isPlaying = true;
        }
        
        public void Stop()
        {
            if (_isPlaying && _soundPlayingHandle.IsValid() && IsAlive)
            {
                SoundManager.Instance.Stop(_soundPlayingHandle);
                _isPlaying = false;
            }
            _soundPlayingHandle = SoundPlayingHandle.INVALID;
        }

        public void Attach(Transform parent)
        {
            transform.SetParent(parent, false);
        }

        public void Reset()
        {
            Stop();
        }
    }
}