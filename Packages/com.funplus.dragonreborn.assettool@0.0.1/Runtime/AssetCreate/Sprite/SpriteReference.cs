using System;
using UnityEngine;
using UnityEngine.UI;

namespace DragonReborn.AssetTool
{
	[DisallowMultipleComponent]
    public class SpriteReference : MonoBehaviour, ISpriteReference
    {
        private string _spName = string.Empty;
        private Action<string> _onDestroyCallback;

        public bool Activated { get; private set; }

		private string _requestSpriteName = string.Empty;
		private SpriteManager.RendererType _requestRendererType = SpriteManager.RendererType.Image;

	    private void Awake()
	    {
			Activated = true;

			RecoverRequest();
		}

		public void SaveRequest(string spriteName, SpriteManager.RendererType rendererType)
		{
			_requestSpriteName = spriteName;
			_requestRendererType = rendererType;
		}

		private void RecoverRequest()
		{
			if (!string.IsNullOrEmpty(_requestSpriteName))
			{
				if (_requestRendererType == SpriteManager.RendererType.Image)
				{
					var image = GetComponent<Image>();
					SpriteManager.Instance.LoadSprite(_requestSpriteName, image);
				}
				else if (_requestRendererType == SpriteManager.RendererType.SpriteRenderer)
				{
					var spriteRenderer = GetComponent<SpriteRenderer>();
					SpriteManager.Instance.LoadSprite(_requestSpriteName, spriteRenderer);
				}
				else if (_requestRendererType == SpriteManager.RendererType.U2DSpriteMesh)
				{
					var spriteMesh = GetComponent<U2DSpriteMesh>();
					SpriteManager.Instance.LoadSprite(_requestSpriteName, spriteMesh);
				}

				_requestSpriteName = string.Empty;
			}
		}

		/// <summary>
        /// Sprite组件在OnDestroy时，自动清理引用计数
        /// </summary>
        private void OnDestroy()
        {
            SetSpriteName(string.Empty);
        }

		public void SetSpriteName(string spriteName)
        {
			if (!string.IsNullOrEmpty(_spName))
            {
				_onDestroyCallback?.Invoke(_spName);
			}

			_spName = spriteName;
		}

        public void SetOnDestroyCallback(Action<string> callback)
        {
            _onDestroyCallback = callback;
        }
    }
}
