using UnityEngine;
using System.Collections.Generic;
using Com.Duoyu001.Pool.U3D;
using Com.Duoyu001.Pool;

public class CubePool : MonoBehaviour
{
    public Transform level;
    public Node[] Nodes;

    public Dictionary<NodeType, U3DAutoRestoreObjectPool> pools = new Dictionary<NodeType, U3DAutoRestoreObjectPool>();

    public void Init()
    {
        for (int i = 0; i < Nodes.Length; i++)
        {
            GameObject obj = new GameObject();
            obj.name = "pool_" + i;
            
            U3DAutoRestoreObjectPool pool = obj.AddComponent<U3DAutoRestoreObjectPool>();
            pool.prefab = Nodes [i].gameObject;
            pool.maxNum = 100;
            pool.initNum = 10;
            pool.parent = level;

            pools.Add(Nodes [i].type, pool);
            
            pool.Init();
            
            obj.transform.parent = transform;
        }
    }

    public IAutoRestoreObject<GameObject> Take(NodeType type)
    {
        return pools [type].Take();
    }

    public void Restore(GameObject obj, NodeType type)
    {
        pools [type].Restore(obj);
    }

    public void Restore(Node node)
    {
        if (pools.ContainsKey(node.type))
        {
            pools [node.type].Restore(node.gameObject);
        }
    }


}
