using System;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(U2DSpriteMesh))]
public class U2DSlider : MonoBehaviour
{
    [SerializeField] private U2DSpriteMesh m_SpriteMesh;
    [SerializeField] private float m_Progress = 1f;

    private bool m_Dirty;

    private void Awake()
    {
        if (m_SpriteMesh == null)
        {
            m_SpriteMesh = GetComponent<U2DSpriteMesh>();
        }
    }

    private void Start()
    {
        m_Dirty = true;
        Update();
    }

    public U2DSpriteMesh spriteMesh
    {
        set
        {
            if (m_SpriteMesh != value)
            {
                m_SpriteMesh = value;
                m_Dirty = true;
            }
        }

        get => m_SpriteMesh;
    }

    public float progress
    {
        set
        {
            var ratio = Mathf.Clamp(value, 0.0f, 1.0f);
            if (m_Progress != ratio)
            {
                m_Progress = ratio;
                m_Dirty = true;
                Update();
            }
        }

        get => m_Progress;
    }

    public Color color
    {
        set
        {
            if (m_SpriteMesh)
            {
                m_SpriteMesh.color = value;
            }
        }

        get
        {
            if (m_SpriteMesh)
            {
                return m_SpriteMesh.color;
            }

            return Color.black;
        }
    }

    private void Update()
    {
        if (m_Dirty)
        {
            if (m_SpriteMesh)
            {
                m_SpriteMesh.fillAmount = m_Progress;
            }

            m_Dirty = false;
        }
    }
}