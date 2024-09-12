using UnityEngine;

public class HeadNode : BasicNode
{
    public int role;
    public GameObject fx;
//    Transform m_EyeLeft;
//    Transform m_EyeRight;
//    float m_EyeTimer;
//    float m_QuaternionLerpTimer;
//    float eyeColorTimer = 1f;
//    Quaternion m_StartEyeRotation;
//    Quaternion m_EndEyeRotation;
//    Quaternion m_EyeInitialRotation;
//    Color eyeColor = Color.white;

//    void Start()
//    {
//        m_EyeLeft = transform.FindChild("Eye Left");
//        m_EyeRight = transform.FindChild("Eye Right");
//
//        if (m_EyeLeft)
//        {
//            m_EyeInitialRotation = m_EyeLeft.localRotation;
//        }
//        
//        m_StartEyeRotation = m_EyeInitialRotation * Quaternion.Euler(Vector3.zero);
//        m_EndEyeRotation = m_EyeInitialRotation * Quaternion.Euler(Vector3.zero);
//    }

    public override void MoveBy(Vector3 step, Snake snake, GameData gameData)
    {
        targetPosition = transform.position + step;
        StartCoroutine(Move(snake, gameData));
//        transform.localScale = Vector3.one;
    }

    public void SetEyeColor(Color color)
    {
//        eyeColor = color;
    }

 //   public override void OnUpdate()
//    {
//        m_EyeTimer -= Time.deltaTime;
//        m_QuaternionLerpTimer += Time.deltaTime;
//        eyeColorTimer -= Time.deltaTime;
//        
//        if (m_EyeLeft && m_EyeRight)
//        {
//            if (m_EyeTimer < 0.0f)
//            {
//                m_EyeTimer = UnityEngine.Random.Range(2.0f, 3.0f);
//                m_QuaternionLerpTimer = 0.0f;
//                
//                float randomXAngle = UnityEngine.Random.Range(-45, 45);
//                float randomZAngle = UnityEngine.Random.Range(-45, 45);
//                m_StartEyeRotation = m_EyeLeft.transform.localRotation;
//                m_EndEyeRotation = m_EyeInitialRotation * Quaternion.Euler(randomXAngle, 0.0f, randomZAngle);
//
//
//            }
//            
//            Quaternion lerpedRotation = Quaternion.Lerp(m_StartEyeRotation, m_EndEyeRotation, Mathf.Clamp01(m_QuaternionLerpTimer * 2));
//            
//            m_EyeLeft.transform.localRotation = lerpedRotation;
//            m_EyeRight.transform.localRotation = lerpedRotation;
//        }
//
//        if (eyeColorTimer > 0.2f)
//        {
//            m_EyeLeft.renderer.material.color = eyeColor;
//            m_EyeRight.renderer.material.color = eyeColor;
//        }
//        else
//        {
//            m_EyeLeft.renderer.material.color = Color.white;
//            m_EyeRight.renderer.material.color = Color.white;
//        }
//
//        if (eyeColorTimer < 0f)
//        {
//            eyeColorTimer = 1f;
//        }
  //  }

    public void ShowExplosionFX()
    {
        if (fx == null)
        {
            return;
        }
        fx.SetActive(true);
    }

    public void HideExplosionFX()
    {
        if (fx == null)
        {
            return;
        }
        fx.SetActive(false);
    }
}
