using System;
using System.Collections.Generic;
using System.IO;
using DragonReborn;
using ICSharpCode.SharpZipLib.Zip;

public static class SharpZipUtils
{
	public static void ZipFolder(string srcFolder, string destZipPath, string[] targetFilenames, int level = 9)
	{
		try
		{
			// Depending on the directory this could be very large and would require more attention
			// in a commercial package.
			string[] filenames = null;
			if (targetFilenames != null)
			{
				filenames = targetFilenames;
			}
			else
			{
				filenames = Directory.GetFiles(srcFolder, "*.*", SearchOption.AllDirectories);
			}


			// 'using' statements guarantee the stream is closed properly which is a big source
			// of problems otherwise.  Its exception safe as well which is great.
			FileInfo fileInfo = new FileInfo(destZipPath);

			if (!Directory.Exists(fileInfo.DirectoryName))
			{
				Directory.CreateDirectory(fileInfo.DirectoryName);
			}

			if (File.Exists(destZipPath))
			{
				File.Delete(destZipPath);
			}

			using (ZipOutputStream s = new ZipOutputStream(File.Create(destZipPath)))
			{

				s.SetLevel(level); // 0 - store only to 9 - means best compression

				byte[] buffer = new byte[4096];

				foreach (string file in filenames)
				{

					if (file.Contains(".meta"))
					{
						continue;
					}

					// Using GetFileName makes the result compatible with XP
					// as the resulting path is not absolute.
					ZipEntry entry = new ZipEntry(file.Substring(srcFolder.Length + 1));

					// Setup the entry data as required.

					// Crc and size are handled by the library for seakable streams
					// so no need to do them here.

					// Could also use the last write time or similar for the file.
					entry.DateTime = DateTime.Now;
					s.PutNextEntry(entry);

					using (FileStream fs = File.OpenRead(file))
					{

						// Using a fixed size buffer here makes no noticeable difference for output
						// but keeps a lid on memory usage.
						int sourceBytes;
						do
						{
							sourceBytes = fs.Read(buffer, 0, buffer.Length);
							s.Write(buffer, 0, sourceBytes);
						} while (sourceBytes > 0);
					}
				}

				// Finish/Close arent needed strictly as the using statement does this automatically

				// Finish is important to ensure trailing information for a Zip file is appended.  Without this
				// the created file would be invalid.
				s.Finish();

				// Close is important to wrap things up and unlock the file.
				s.Close();
			}
		}
		catch (Exception ex)
		{
			NLogger.Error(ex.ToString());

			// No need to rethrow the exception as for our purposes its handled.
		}
	}


	/// <summary>
	/// 功能：解压zip格式的文件。
	/// </summary>
	/// <param name="zipFilePath">压缩文件路径</param>
	/// <param name="unZipDir">解压文件存放路径,为空时默认与压缩文件同一级目录下，跟压缩文件同名的文件夹</param>
	/// <param name="err">出错信息</param>
	/// <returns>解压是否成功</returns>
	public static bool UnZipFile(string zipFilePath, string unZipDir, out string err)
	{
		err = "";
		if (zipFilePath == string.Empty)
		{
			err = "压缩文件不能为空！";
			return false;
		}
		if (!File.Exists(zipFilePath))
		{
			err = "压缩文件不存在！";
			return false;
		}

		try
		{
			using (ZipInputStream s = new ZipInputStream(File.OpenRead(zipFilePath)))
			{
				ZipEntry theEntry;
				while ((theEntry = s.GetNextEntry()) != null)
				{
					string directoryName = Path.GetDirectoryName(theEntry.Name);
					string fileName = Path.GetFileName(theEntry.Name);
					if (directoryName.Length > 0)
					{
						Directory.CreateDirectory(Path.Combine(unZipDir, directoryName));
					}

					if (fileName != String.Empty)
					{
						using (FileStream streamWriter = File.Create(Path.Combine(unZipDir, theEntry.Name)))
						{

							int size = 2048;
							byte[] data = new byte[2048];
							while (true)
							{
								size = s.Read(data, 0, data.Length);
								if (size > 0)
								{
									streamWriter.Write(data, 0, size);
								}
								else
								{
									break;
								}
							}
						}
					}
				}//while
			}
		}
		catch (Exception ex)
		{
			err = ex.Message;
			return false;
		}
		return true;
	}

	public static bool UnZipFile(string zipFilePath, List<byte[]> buffers)
	{
		buffers.Clear();

		if (string.IsNullOrEmpty(zipFilePath))
		{
			NLogger.ErrorChannel("SharpZipUtils", $"UnZipFile: Invalid path.");
			return false;
		}
		
		try
		{
			const int bufferSize = 2048;
			var buffer = new byte[bufferSize];

			using var s = new ZipInputStream(File.OpenRead(zipFilePath));
			while (s.GetNextEntry() != null)
			{
				using var ms = new MemoryStream();
				using var br = new BinaryWriter(ms);

				while (true)
				{
					var size = s.Read(buffer, 0, bufferSize);
					if (size > 0)
					{
						br.Write(buffer, 0, size);
					}
					else
					{
						break;
					}
				}

				var bytes = ms.ToArray();
				buffers.Add(bytes);
			}
		}
		catch(Exception e)
		{
			NLogger.ErrorChannel("SharpZipUtils", $"UnZipFile: {e}");
			return false;
		}
		
		return true;
	}
}
