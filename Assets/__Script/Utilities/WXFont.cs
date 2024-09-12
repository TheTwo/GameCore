using UnityEngine;
using UnityEngine.UI;
using WeChatWASM;

public class WxFont : MonoBehaviour
{
    private void Awake()
    {
        var text = GetComponent<Text>();
        if (text != null)
        {
            var fallbackFont = "https://a.unity.cn/client_api/v1/buckets/38abf271-e18c-4c8a-9c35-8c8104b5cbf3/content/MFYueYuan_Noncommercial-Regular.otf";
            WX.GetWXFont(fallbackFont, (font) =>
            {
                text.font = font;
            });
        }
    }
}