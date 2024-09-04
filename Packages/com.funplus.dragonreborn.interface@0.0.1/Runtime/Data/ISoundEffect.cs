using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    public interface ISoundEffect
    {
        GameObject GameObj { get; }
        string EventName { get; }
        void Reset();
        bool IsAlive { get; }
        bool IsPlaying { get; }
        void Play();
        void Stop();
    }
}