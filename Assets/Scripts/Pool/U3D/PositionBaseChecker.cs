using UnityEngine;

namespace Com.Duoyu001.Pool.U3D
{
    /* ==============================================================================
     * 功能描述：基于时间的回收检查器
     * 创 建 者：cjunhong
     * 邮    箱：john.cha@qq.com
     * Q      Q：327112182
     * 创建日期：2014/11/24 14:13:53
     * ==============================================================================*/
    public class PositionBaseChecker : MonoBehaviour, IAutoRestoreChecker
    {
        public bool Restore
        {
            get
            { 
                return Camera.main.WorldToScreenPoint(gameObject.transform.position).y < -5;
            }
        }
    }
}
