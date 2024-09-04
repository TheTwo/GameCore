using ICSharpCode.SharpZipLib.GZip;
using System;
using System.IO;
using System.IO.Compression;
using System.Text;

namespace DragonReborn
{
    public class GzipUtils
    {
        public static bool IsGzipData(byte[] data)
        {
            if (data == null || data.Length < 2)
            {
                return false;
            }

            return (int) ((data[0] << 8) | data[1] & 0xFF) == 0x1f8b;
        }

        public static byte[] DecodeByGzip(byte[] data)
        {
            if (data == null)
            {
                return data;
            }

            if (IsGzipData(data))
            {
                GZipInputStream gzi = null;
                MemoryStream re = null;

                try
                {
                    gzi = new GZipInputStream(new MemoryStream(data));
                    re = new MemoryStream( );

                    int len = 0;
                    byte[] b = new byte[4096];

                    while ((len = gzi.Read(b, 0, b.Length)) != 0)
                    {
                        re.Write(b, 0, len);
                    }

                    re.Flush( );

                    return re.ToArray( );
                }
                catch (Exception e)
                {
                    NLogger.Error("[DecodeByGzip] Error = {0}", e);
                }
                finally
                {
                    if (gzi != null)
                    {
                        gzi.Close( );
                        gzi = null;
                    }

                    if (re != null)
                    {
                        re.Close( );
                        re = null;
                    }
                }
            }

            return data;
        }

        public static byte[] EncodeByGzip(string source)
        {
            try
            {
                byte[] buffer = Encoding.UTF8.GetBytes(source);
                var memoryStream = new MemoryStream();
                using (var gZipStream = new GZipStream(memoryStream, CompressionMode.Compress, true))
                {
                    gZipStream.Write(buffer, 0, buffer.Length);
                }
                memoryStream.Position = 0;
                var compressedData = new byte[memoryStream.Length];
                memoryStream.Read(compressedData, 0, compressedData.Length);
                return compressedData;//Convert.ToBase64String(compressedData);
            }
            catch (Exception e)
            {
                NLogger.Error(e.Message);
                throw;
            }           
        }

		public static byte[] EncodeByGzip(byte[] source)
		{
			try
			{				
				var memoryStream = new MemoryStream();
				using (var gZipStream = new GZipStream(memoryStream, CompressionMode.Compress, true))
				{
					gZipStream.Write(source, 0, source.Length);
				}
				memoryStream.Position = 0;
				var compressedData = new byte[memoryStream.Length];
				memoryStream.Read(compressedData, 0, compressedData.Length);
				return compressedData;
			}
			catch (Exception e)
			{
				NLogger.Error(e.Message);
				throw;
			}
		}
	}
}
