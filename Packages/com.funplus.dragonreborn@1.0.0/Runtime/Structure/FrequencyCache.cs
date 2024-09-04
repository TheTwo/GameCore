using System;
using System.Collections;
using System.Collections.Generic;

namespace DragonReborn
{
    public class FrequencyCache<T>
    {
	    public class DataBlock
        {
            public string Name;
            public T Element;
        }

        private readonly LinkedList<DataBlock> _cache = new();
        private readonly Dictionary<string, LinkedListNode<DataBlock>> _lookup = new();
        private readonly Action<string, T> _onDelete;
        private int _cacheSize;

        public FrequencyCache(int size, Action<string, T> onDelete)
        {
            _cacheSize = size;
            _onDelete = onDelete;
        }

        public int CacheSize
        {
            get => _cacheSize;

            set
            {
                while (_cache.Count > value)
                {
                    var node = _cache.Last;
                    _onDelete?.Invoke(node.Value.Name, node.Value.Element);
                    _cache.Remove(node);
                }

                _cacheSize = value;
            }
        }

        public bool TryGet(string name, out T element)
        {
            if (!string.IsNullOrEmpty(name))
            {
                _lookup.TryGetValue(name, out var node);
                if (node != null)
                {
                    element = node.Value.Element;
                    _cache.Remove(node);
                    _cache.AddFirst(node);
                    return true;
                }
            }

            element = default(T);
            return false;
        }

        public bool Contains(string name)
        {
            return _lookup.ContainsKey(name);
        }

		public bool Remove(string name, bool doDelete)
		{
			if (!string.IsNullOrEmpty(name))
			{
				if (_lookup.TryGetValue(name, out var node))
				{
					if (doDelete)
					{
						_onDelete?.Invoke(node.Value.Name, node.Value.Element);
					}

					_cache.Remove(node);
					_lookup.Remove(name);
					return true;
				}
			}

			return false;
		}

        public T this[string name]
        {
	        set => Add(name, value);
	        get => TryGet(name, out var cache) ? cache : default;
        }

        public void Add(string name, T element)
        {
            if (string.IsNullOrEmpty(name))
            {
                return;
            }

            if (_lookup.ContainsKey(name))
            {
                return;
            }

            if (_cacheSize <= 0)
            {
                return;
            }

            LinkedListNode<DataBlock> node;
            if (_cacheSize == _cache.Count)
            {
                node = _cache.Last;

                _onDelete?.Invoke(node.Value.Name, node.Value.Element);
                _cache.Remove(node);
                _lookup.Remove(node.Value.Name);
            }
            else
            {
                node = new LinkedListNode<DataBlock>(new DataBlock());
            }

            node.Value.Name = name;
            node.Value.Element = element;

            _cache.AddFirst(node);
            _lookup[name] = node;
        }

        public void Clear()
        {
            if (_onDelete != null)
            {
                foreach (var block in _cache)
                {
                    _onDelete(block.Name, block.Element);
                }
            }

            _cache.Clear();
            _lookup.Clear();
        }

        public struct Enumerator : IEnumerator<KeyValuePair<string, T>>
        {
	        private readonly LinkedList<DataBlock> _cache;
	        private LinkedListNode<DataBlock> _node;

	        public Enumerator(LinkedList<DataBlock> cache)
	        {
		        _cache = cache;
		        _node = _cache.First;
		        Current = default;
	        }
	        
	        public bool MoveNext()
	        {
		        if (_node == null)
		        {
			        return false;
		        }
		        
		        var block = _node.Value;
		        Current = new KeyValuePair<string, T>(block.Name, block.Element);
		        _node = _node.Next;
		        return true;
	        }

	        public void Reset()
	        {
		        _node = _cache.First;
		        Current = default;
	        }

	        public KeyValuePair<string, T> Current { get; private set; }

	        object IEnumerator.Current => Current;

	        public void Dispose()
	        {
		        
	        }
        }

        public Enumerator GetEnumerator()
        {
	        return new Enumerator(_cache);
        }
    }
}
