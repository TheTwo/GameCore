using UnityEngine;
using System.Collections;
namespace DragonReborn.Utilities
{
    public class ScrollingUVs : MonoBehaviour 
    {
        public int materialIndex = 0;
        public Vector2 uvAnimationRate = new Vector2( 1.0f, 0.0f );
     
        Vector2 uvOffset = Vector2.zero;

        private Renderer _renderer;
        private MaterialPropertyBlock mpb;
        private void Start()
        {
            _renderer = gameObject.GetComponent<Renderer>();
            mpb = new MaterialPropertyBlock();
            
            var offset =  _renderer.sharedMaterials[materialIndex].GetTextureOffset("_BaseMap");
            var scale =  _renderer.sharedMaterials[materialIndex].GetTextureScale("_BaseMap");
            Vector4 stValue = new Vector4(scale.x, scale.y, offset.x, offset.y);
            _renderer.GetPropertyBlock(mpb,materialIndex);
            mpb.SetVector("_BaseMap_ST",stValue);
            _renderer.SetPropertyBlock(mpb,materialIndex);
        }

        void LateUpdate()
        {
            if (_renderer.enabled)
            {
                uvOffset += (uvAnimationRate * Time.deltaTime);
                // _renderer.materials[materialIndex].SetTextureOffset(textureName, uvOffset);
                _renderer.GetPropertyBlock(mpb,materialIndex);
                 //_renderer.materials[materialIndex].SetTextureOffset("_BaseMap", uvOffset);
                var stValue = mpb.GetVector("_BaseMap_ST");
                stValue.z = uvOffset.x;
                stValue.w = uvOffset.y;
                mpb.SetVector("_BaseMap_ST",stValue);
                _renderer.SetPropertyBlock(mpb,materialIndex);
            }
        }

        private void OnBecameInvisible()
        {
            enabled = false;
        }

        private void OnBecameVisible()
        {
            enabled = true;
        }
    }
}