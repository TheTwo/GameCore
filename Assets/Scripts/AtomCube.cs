using UnityEngine;
using System.Collections;

public class AtomCube : BasicNode
{
    public void Bomb()
    { 
        for(int i =0; i<transform.childCount; i++)
        {
            Transform child = transform.GetChild(i);
            child.gameObject.SetActive(true);
            child.localPosition = Vector3.zero;
        }
//
//        Rigidbody[] bodies = GetComponentsInChildren<Rigidbody>();
//
//        foreach (Rigidbody body in bodies)
//        {
//            body.AddExplosionForce(200, transform.position, 5, 10);
//        }

//        StartCoroutine(Remove());
    }

    IEnumerator Remove()
    {
        while(transform.childCount > 0)
        {
            transform.GetChild(0).gameObject.SetActive(false);
            yield return new WaitForSeconds(UnityEngine.Random.value * 0.3f);
        }

        level.Restore(this);

        yield return null;
    }
}
