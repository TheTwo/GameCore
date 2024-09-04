using System;
using UnityEngine;

namespace DragonReborn.AssetTool
{
    public class AsyncRequest<T> : IAsyncRequest where T: AsyncOperation
    {
        private bool _needRemove;
        public bool NeedRemove => _needRemove;
        
        private T _request;
        private Action<T,object> _completeHandler;
        private object _userData;

		public static AsyncRequest<T> Create(T Req, Action<T,object> handler, object userData)
        {
            var inst = new AsyncRequest<T>
            {
                _request = Req,
                _completeHandler = handler,
                _userData = userData,
                _needRemove = false
            };
            return inst;
        }
        
        //外部无法构造这个类，需要用create
        private AsyncRequest()
        {

		}

		public bool CheckComplete()
        {
            if (_request.isDone && !_needRemove)
            {
				_needRemove = true;
				_completeHandler?.Invoke(_request, _userData);
				return true;
			}

			return false;
        }
    }
}
