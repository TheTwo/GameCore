using System.Text;
using UnityEngine.Networking;

// ReSharper disable once CheckNamespace
namespace DragonReborn.Utilities
{
	public static class UnityWebRequestExt
	{
		public static UnityWebRequestAsyncOperation SendPostJsonString(string url, string jsonString)
		{
			var request = new UnityWebRequest(url, "POST");
			request.downloadHandler = new DownloadHandlerBuffer();
			if (!string.IsNullOrEmpty(jsonString))
			{
				var bytes = Encoding.UTF8.GetBytes(jsonString);
				request.SetRequestHeader("contentType", "application/json; charset=utf-8");
				request.SetRequestHeader("dataType", "json");
				request.uploadHandler = new UploadHandlerRaw(bytes);
				request.uploadHandler.contentType = "application/json; charset=utf-8";
			}
			return request.SendWebRequest();
		}
	}
}
