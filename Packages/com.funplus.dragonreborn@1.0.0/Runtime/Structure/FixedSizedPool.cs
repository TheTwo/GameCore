using System;
using System.Collections.Generic;

namespace DragonReborn
{
    public class FixedSizedPool<T>
    {
        private readonly List<T> _cache = new List<T>();
        private readonly Action<T> _onDelete;
        private int _size;

        public FixedSizedPool(int size, Action<T> onDelete)
        {
            _size = size;
            _onDelete = onDelete;
        }

        public bool Add(T o)
        {
            if (_cache.Contains(o))
            {
                return false;
            }

            if (_cache.Count + 1 > _size)
            {
                return false;
            }

            _cache.Add(o);

            return true;
        }

        public bool TryGet(out T result)
        {
            if (_cache.Count <= 0)
            {
                result = default;
                return false;
            }

            result = Pop();
            return true;
        }

        private T Pop()
        {
            if (_cache.Count <= 0)
            {
                throw new InvalidOperationException();
            }

            var lastIndex = _cache.Count - 1;
            var result = _cache[lastIndex];
            _cache.RemoveAt(lastIndex);
            return result;
        }

        public int Size
        {
            get => _size;

            set
            {
                while (_cache.Count > value)
                {
                    _onDelete?.Invoke(Pop());
                }

                _size = value;
            }
        }

        public void Clear()
        {
            while (_cache.Count > 0)
            {
                _onDelete?.Invoke(Pop());
            }
        }

        public void Remove(T go)
        {
            _cache.Remove(go);
        }
    }
}
