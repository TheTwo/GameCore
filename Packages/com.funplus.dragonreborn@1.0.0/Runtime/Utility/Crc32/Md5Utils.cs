
using System.IO;
using System.Security.Cryptography;
using System.Text;

public class Md5Utils
{
    public static string GetFileMd5(string filePath)
    {
        if (File.Exists(filePath))
        {
            var bytes = File.ReadAllBytes(filePath);
            return GetMd5(bytes);
        }

        return string.Empty;
    }

    public static string GetMd5(byte[] bytes)
    {
        var md5 = MD5.Create();
        var md5Bytes = md5.ComputeHash(bytes);
        var builder = new StringBuilder();
        foreach (var b in md5Bytes)
        {
            builder.Append(b.ToString("x2"));
        }
        return builder.ToString().ToLower();
    }
    
    public static string GetMd5ByString(string s)
    {
        return GetMd5(Encoding.UTF8.GetBytes(s));
    }
}