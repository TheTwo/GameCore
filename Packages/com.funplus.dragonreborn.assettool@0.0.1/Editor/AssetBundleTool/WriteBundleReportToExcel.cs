using System;
using System.Collections.Generic;
using System.IO;
using NPOI.SS.UserModel;
using NPOI.XSSF.UserModel;
using UnityEngine;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
    public static class WriteBundleReportToExcel
    {
        public static void WriteExcelReport(string writeFullPath, IDetailManifest detailManifest)
        {
            var wb = new XSSFWorkbook();
            WriteBundleSheet(wb, detailManifest);
            WriteAssetSheet(wb, detailManifest);
            using var fs = new FileStream(writeFullPath, FileMode.Create);
            wb.Write(fs);
            fs.Close();
        }

        private static void WriteBundleSheet(XSSFWorkbook wb, IDetailManifest detailManifest)
        {
            var sheet1 = wb.CreateSheet("BundleDepCount");
            sheet1.SetColumnWidth(0, 100 * 256);
            var tempList = new List<KeyValuePair<string, int>>(detailManifest.Bundle2Dep.Count);
            var maxCount = 0;
            foreach (var kv in detailManifest.Bundle2Dep)
            {
                if (kv.Value.Count > maxCount) maxCount = kv.Value.Count;
                tempList.Add(new KeyValuePair<string, int>(kv.Key, kv.Value.Count));
            }
            
            var styleLevels = new List<KeyValuePair<float, ICellStyle>>();
            var baseStyle = wb.CreateCellStyle();
            var integerFormat = wb.CreateDataFormat().GetFormat("0");
            baseStyle.FillPattern = FillPattern.SolidForeground;
            baseStyle.FillForegroundColor = IndexedColors.White.Index;
            baseStyle.DataFormat = integerFormat;
            styleLevels.Add(new KeyValuePair<float, ICellStyle>(0, baseStyle));
            if (maxCount > 1)
            {
                var step = maxCount * 1f / 4;
                for (int i = 0; i < 4; i++)
                {
                    var limitValue = step * i;
                    Color32 color = Color.HSVToRGB(0, i * 0.25f, 1);
                    var levelStyle = (XSSFCellStyle)wb.CreateCellStyle();
                    levelStyle.FillPattern = FillPattern.SolidForeground;
                    levelStyle.SetFillForegroundColor(new XSSFColor(System.Drawing.Color.FromArgb(color.r, color.g, color.b)));
                    baseStyle.DataFormat = integerFormat;
                    styleLevels.Add(new KeyValuePair<float, ICellStyle>(limitValue, levelStyle));
                }
            }
            tempList.Sort((a,b)=>string.CompareOrdinal(a.Key, b.Key));
            var titleRow = sheet1.CreateRow(0);
            var cell = titleRow.CreateCell(0);
            cell.SetCellType(CellType.String);
            cell.SetCellValue("BundleName");
            cell = titleRow.CreateCell(1);
            cell.SetCellType(CellType.String);
            cell.SetCellValue("Dependence Count");
            sheet1.CreateFreezePane(1, 1);
            for (int i = 0; i < tempList.Count; i++)
            {
                var data = tempList[i];
                var rowIndex = i + 1;
                var row = sheet1.CreateRow(rowIndex);
                var bundleCell = row.CreateCell(0);
                bundleCell.SetCellType(CellType.String);
                bundleCell.SetCellValue(data.Key);
                var countCell = row.CreateCell(1);
                countCell.SetCellType(CellType.Numeric);
                countCell.SetCellValue(data.Value);
                countCell.CellStyle = GetStyleForCount(data.Value);
            }
            
            ICellStyle GetStyleForCount(int count)
            {
                for (var i = styleLevels.Count - 1; i >= 0; i--)
                {
                    if (count >= styleLevels[i].Key)
                    {
                        return styleLevels[i].Value;
                    }
                    
                }
                return baseStyle;
            }
        }

        private static void WriteAssetSheet(XSSFWorkbook wb, IDetailManifest detailManifest)
        {
            var sheet1 = wb.CreateSheet("AssetDepCount");
            sheet1.SetColumnWidth(0, 100 * 256);
            var tempList = new List<Tuple<string, int, int>>(detailManifest.Asset2DepBundle.Count);
            var maxCount = 0;
            foreach (var kv in detailManifest.Asset2DepBundle)
            {
                if (kv.Value.Count > maxCount) maxCount = kv.Value.Count;
                detailManifest.Asset2DepAsset.TryGetValue(kv.Key, out var assetDepCount);
                tempList.Add(Tuple.Create(kv.Key, kv.Value.Count, assetDepCount?.Count ?? 0));
            }
            
            var styleLevels = new List<KeyValuePair<float, ICellStyle>>();
            var baseStyle = wb.CreateCellStyle();
            var integerFormat = wb.CreateDataFormat().GetFormat("0");
            baseStyle.FillPattern = FillPattern.SolidForeground;
            baseStyle.FillForegroundColor = IndexedColors.White.Index;
            baseStyle.DataFormat = integerFormat;
            styleLevels.Add(new KeyValuePair<float, ICellStyle>(0, baseStyle));
            if (maxCount > 1)
            {
                var step = maxCount * 1f / 4;
                for (int i = 0; i < 4; i++)
                {
                    var limitValue = step * i;
                    Color32 color = Color.HSVToRGB(0, i * 0.25f, 1);
                    var levelStyle = (XSSFCellStyle)wb.CreateCellStyle();
                    levelStyle.FillPattern = FillPattern.SolidForeground;
                    levelStyle.SetFillForegroundColor(new XSSFColor(System.Drawing.Color.FromArgb(color.r, color.g, color.b)));
                    baseStyle.DataFormat = integerFormat;
                    styleLevels.Add(new KeyValuePair<float, ICellStyle>(limitValue, levelStyle));
                }
            }
            tempList.Sort((a,b)=>string.CompareOrdinal(a.Item1, b.Item1));
            var titleRow = sheet1.CreateRow(0);
            var cell = titleRow.CreateCell(0);
            cell.SetCellType(CellType.String);
            cell.SetCellValue("AssetPath");
            cell = titleRow.CreateCell(1);
            cell.SetCellType(CellType.String);
            cell.SetCellValue("Dependence BundleCount");
            cell = titleRow.CreateCell(2);
            cell.SetCellType(CellType.String);
            cell.SetCellValue("Dependence AssetCountCount");
            sheet1.CreateFreezePane(1, 1);
            for (int i = 0; i < tempList.Count; i++)
            {
                var (assetPath, depBundleCount, depAssetCount) = tempList[i];
                var rowIndex = i + 1;
                var row = sheet1.CreateRow(rowIndex);
                var bundleCell = row.CreateCell(0);
                bundleCell.SetCellType(CellType.String);
                bundleCell.SetCellValue(assetPath);
                var countCell = row.CreateCell(1);
                countCell.SetCellType(CellType.Numeric);
                countCell.SetCellValue(depBundleCount);
                countCell.CellStyle = GetStyleForCount(depBundleCount);
                countCell = row.CreateCell(2);
                countCell.SetCellType(CellType.Numeric);
                countCell.SetCellValue(depAssetCount);
                countCell.CellStyle = GetStyleForCount(0);
            }
            
            ICellStyle GetStyleForCount(int count)
            {
                for (var i = styleLevels.Count - 1; i >= 0; i--)
                {
                    if (count >= styleLevels[i].Key)
                    {
                        return styleLevels[i].Value;
                    }
                    
                }
                return baseStyle;
            }
        }
    }
}
