using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class BackgroundController : MonoBehaviour
{
    public List<Sprite> planeSprites;
    public List<Sprite> treeSprites;
    public Sprite roundTree;
    GameObject[] planes;
    GameObject[] trees;
    int level = -1;
    public void Init()
    {
        planes = GameObject.FindGameObjectsWithTag("Plane");
        trees = GameObject.FindGameObjectsWithTag("Tree");
    }

    public void ChangePlane(int lv)
    {
        if (level == lv) return;
        level = lv;
            
        foreach (var t in planes)
        {
            SpriteRenderer sprite = t.GetComponent<SpriteRenderer> ();
            if (sprite != null)
            {
                sprite.sprite =  planeSprites[(lv - 1) % planeSprites.Count];
            }
        }              
     
        Sprite tree = treeSprites [(lv - 1) % 3];
        foreach (var t in trees)
        {
            SpriteRenderer sprite = t.GetComponent<SpriteRenderer> ();

            if (sprite == null) continue;
            sprite.sprite = Random.value < 0.3f ? roundTree : tree;
        }
    }
}
