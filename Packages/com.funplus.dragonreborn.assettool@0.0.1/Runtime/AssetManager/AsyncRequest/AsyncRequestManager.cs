using System.Collections.Generic;

namespace DragonReborn.AssetTool
{
    public class AsyncRequestManager : Singleton<AsyncRequestManager>, ITicker
    {
        private List<IAsyncRequest> _allTask;
        private List<IAsyncRequest> _addTask;
        private bool _isTicking = false;
    
        public int RequestMaxCount { get; set; }
    
        public void Initialize()
        {
            _allTask = new List<IAsyncRequest>();
            _addTask = new List<IAsyncRequest>();
        }
        
        public void Reset()
        {
            _allTask.Clear();
            _addTask.Clear();
		}

        public void AddTask(IAsyncRequest req)
        {
            //遍历中加入的任务，下一帧再处理
            if (_isTicking)
            {
                _addTask.Add(req);
            }
            else
            {
                _allTask.Add(req);
            }
        }
    
        public void Tick(float delta)
        {
            _isTicking = true;

            var count = 0;
            foreach (var req in _allTask)
            {
                if (req.CheckComplete())
                {
                    count++;
                    if (count >= RequestMaxCount)
                    {
                        break;
                    }
                }
            }

            _allTask.RemoveAll(x=> x.NeedRemove);
        
            _isTicking = false;
            _allTask.AddRange(_addTask);
            _addTask.Clear();
        }

        public bool IsBusy()
        {
            return _allTask.Count != 0 || _addTask.Count != 0;
        }
    }
}
