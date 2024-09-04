using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using CsvHelper;
using UnityEngine;

namespace DragonReborn
{
	public sealed class SsrCsvConfigReader
	{
		public static string PATH_CSV_FOLDER = Path.Combine(Application.dataPath, "../../../../ssr-config/trunk/config/csv");
		public const string ART_RESOURCE = "ArtResource.csv";
		public const string ART_RESOURCE_UI = "ArtResourceUI.csv";
		public const string BUILDING_TYPES = "BuildingTypes.csv";
		public const string BUILDING_LEVEL = "BuildingLevel.csv";

		public static List<T> ReadConfigCellsFromPath<T>(string path, int ignoreLineExceptHeader = 2) where T:class
		{
			using var stream = new StreamReader(path);
			using var reader = new CsvReader(stream, new CultureInfo("zh-CN"), true);

			try
			{
				var skipLine = ignoreLineExceptHeader;
				var ret = new List<T>();
				reader.Read();
				reader.ReadHeader();
				while (reader.Read())
				{
					if (skipLine > 0)
					{
						skipLine--;
						continue;
					}

					T record = reader.GetRecord<T>();
					ret.Add(record);
				}

				return ret;
			}
			catch(Exception e)
			{
				NLogger.Error(e.ToString());
				return null;
			}
		}
	}
}
