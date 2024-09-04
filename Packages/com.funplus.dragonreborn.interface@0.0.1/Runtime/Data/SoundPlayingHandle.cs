using System;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    public readonly struct SoundPlayingHandle
    {
        // ReSharper disable once InconsistentNaming
        public static readonly SoundPlayingHandle INVALID = new SoundPlayingHandle(0, 0, string.Empty, null);
        
        private readonly uint _id;
        private readonly ulong _internalIndex;
        private readonly string _eventName;
        internal readonly Action<bool, uint, Action<uint>> _actoinEvent;
        
        public uint Id => _id;
        public string EventName => _eventName;

        public SoundPlayingHandle(uint id, ulong internalIndex, string eventName, Action<bool, uint, Action<uint>> actoinEvent)
        {
            _id = id;
            _internalIndex = internalIndex;
            _eventName = eventName;
            _actoinEvent = actoinEvent;
        }

        public bool IsValid()
        {
            return _id != 0;
        }
        
        public event Action<uint> OnEnd
        {
            add
            {
                if (null != _actoinEvent)
                    _actoinEvent.Invoke(true, _id, value);
                else
                    value?.Invoke(_id);
            }
            remove => _actoinEvent?.Invoke(false, _id, value);
        }
    }
}