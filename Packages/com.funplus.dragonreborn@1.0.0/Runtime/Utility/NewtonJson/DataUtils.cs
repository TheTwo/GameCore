using System;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace DragonReborn
{
    public static class DataUtils
    {
        private const string CHANNEL = "DataUtils";

        public static T FromJson<T>(string json)
        {
            T result = default;

            try
            {
                result = JsonConvert.DeserializeObject<T>(json);
            }
            catch (Exception e)
            {
                if (false == string.IsNullOrEmpty(json) && json.Length > 2048)
                {
                    NLogger.WarnChannel(CHANNEL, "Parse {0} fail, reason: {1}", json.Substring(0, 2048), e);
                }
                else
                {
                    NLogger.WarnChannel(CHANNEL, "Parse {0} fail, reason: {1}", json, e);
                }
            }

            return result;
        }

        public static bool FromJson(Type targetType, string json, out object result)
        {
	        result = default;

	        try
	        {
		        result = JsonConvert.DeserializeObject(json, targetType);
		        return result != null;
	        }
	        catch (Exception e)
	        {
		        if (false == string.IsNullOrEmpty(json) && json.Length > 2048)
		        {
			        NLogger.WarnChannel(CHANNEL, "Parse {0} fail, reason: {1}", json.Substring(0, 2048), e);
		        }
		        else
		        {
			        NLogger.WarnChannel(CHANNEL, "Parse {0} fail, reason: {1}", json, e);
		        }
	        }
	        return false;
        }

        public static bool FromGameAssetJsonFile(Type targetType, string relativePath, bool decode, out object result)
        {
	        return FromJson(targetType, IOUtils.ReadGameAssetAsText(relativePath, decode), out result);
        }
        
        public static bool FromStreamingAssetJsonFile(Type targetType, string relativePath, bool decode, out object result)
        {
	        return FromJson(targetType, IOUtils.ReadStreamingAssetAsText(relativePath, decode), out result);
        }

        public static string ToJson(object data, Formatting format = Formatting.None)
        {
            string result = string.Empty;

            try
            {
                result = JsonConvert.SerializeObject(data, format);
            }
            catch (Exception e)
            {
                NLogger.WarnChannel(CHANNEL, e.ToString());
            }

            return result;
        }

        public static T ToObject<T>(JToken token)
        {
            try
            {
                return token.ToObject<T>();
            }
            catch (Exception e)
            {
                NLogger.WarnChannel(CHANNEL, e.ToString());
            }

            return default(T);
        }
    }
}
