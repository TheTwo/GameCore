using System;
using System.IO;

namespace DragonReborn
{
	public class SafetyUtils
	{
		public static string FromBase64StringXor(string str)
		{
			var buffer = Convert.FromBase64String(str);
			CodeByteBuffer(buffer);
			return System.Text.Encoding.UTF8.GetString(buffer);
		}

		public static string ToBase64StringXor(string str)
		{
			var buffer = System.Text.Encoding.UTF8.GetBytes(str);
			CodeByteBuffer(buffer);
			return Convert.ToBase64String(buffer);
		}

		public static bool CodeByteBuffer(byte[] byteData)
		{
			try
			{
				if (byteData != null)
				{
					long len = byteData.Length;
					for (int i = 0; i < len; i += 2)
					{
						byte check = (byte)((len * i) % byte.MaxValue);
						byteData[i] ^= check;
					}
					return true;
				}
			}
			catch
			{
				return false;
			}
			return false;
		}

		public static int GetHeadOffset(string hashValue)
		{
			int offset = 0;
			try
			{
				for (int i = 8; i < 16; i++)
				{
					var c = hashValue[i];
					int value = 0;
					if (c - 'a' >= 0)
					{
						value = (c - 'a') + 10;
					}
					else
					{
						value = c - '0';
					}
					offset += value;
				}
			}
			catch (Exception e)
			{
				NLogger.Error($"GetBundleOffset {hashValue} Exception:{e}");
			}

			return offset;
		}

#if UNITY_EDITOR
		/// <summary>
		/// 增加头部偏移，加密
		/// </summary>
		/// <param name="hashValue"></param>
		/// <param name="bundlePath"></param>
		/// <exception cref="Exception"></exception>
		public static void EncryptHeadOffset(string hashValue, string bundlePath)
		{
			var offset = GetHeadOffset(hashValue);
			var byteData = File.ReadAllBytes(bundlePath);
			if (byteData == null)
			{
				throw new Exception("SetBundleHeadOffset byteData is null");
			}

			var newByteData = new byte[byteData.Length + offset];
			for (int i = 0; i < offset; i++)
			{
				int index = (i % 16) * 2 + 1;
				newByteData[i] = (byte)((hashValue[index] + i + 1) % byte.MaxValue);
			}
			Buffer.BlockCopy(byteData, 0, newByteData, offset, byteData.Length);
			File.WriteAllBytes(bundlePath, newByteData);
		}

		/// <summary>
		/// 移除头部偏移，解密
		/// </summary>
		/// <param name="hashValue"></param>
		/// <param name="oldPath"></param>
		/// <exception cref="Exception"></exception>
		public static void DecryptHeadOffset(string hashValue, string oldPath, string newPath)
		{
			var offset = GetHeadOffset(hashValue);

			var byteData = File.ReadAllBytes(oldPath);
			if (byteData == null)
			{
				throw new Exception("SetBundleHeadOffset byteData is null");
			}

			var newByteData = new byte[byteData.Length - offset];
			Buffer.BlockCopy(byteData, offset, newByteData, 0, byteData.Length - offset);
			File.WriteAllBytes(newPath, newByteData);
		}

		/// <summary>
		/// 执行一次加密，再执行一次解密
		/// </summary>
		/// <param name="filePath"></param>
		/// <exception cref="System.Exception"></exception>
		public static void EncryptXOR(string filePath)
		{
			FileStream fs = File.Open(filePath, FileMode.Open);
			if (fs != null)
			{
				byte[] buffers = new byte[fs.Length];
				fs.Read(buffers, 0, (int)fs.Length);

				byte[] buffersEncode = new byte[fs.Length];
				Buffer.BlockCopy(buffers, 0, buffersEncode, 0, buffers.Length);

				long len = buffers.Length;
				for (int i = 0; i < len; i += 2)
				{
					byte check = (byte)((len * i) % byte.MaxValue);
					buffersEncode[i] ^= check;
				}

				fs.Seek(0, SeekOrigin.Begin);
				fs.Write(buffersEncode, 0, buffersEncode.Length);
				fs.Close();

				//check
				{
					byte[] content = File.ReadAllBytes(filePath);
					len = content.Length;
					for (int i = 0; i < len; i += 2)
					{
						byte check = (byte)((len * i) % byte.MaxValue);
						content[i] ^= check;
						if (content[i] != buffers[i])
						{
							throw new System.Exception("EncodeFile Error!!! " + filePath);
						}
					}
				}
			}
		}
#endif
	}
}
