
#if USE_XLUA
using XLua;

// ReSharper disable once CheckNamespace
namespace DragonReborn.UI
{
	public sealed class LuaTableViewProExpandCell : LuaTableViewProCell
	{
		private LuaFunction[] _expendDataLuaFunctions;

		private enum ExpendLuaFuncType
		{
			GetChildCount,
			GetChildAt,
			GetPrefabIndex,
			IsExpanded,
			SetExpanded,
		}
		
		public override void FeedData(object data)
		{
			base.FeedData(data);
			if (__cellData is LuaTable luaTable)
			{
				_expendDataLuaFunctions = LuaUIUtility.InitAllLuaFunc(luaTable,typeof(ExpendLuaFuncType));
				if (!LuaUIUtility.InvokeLuaFunc(luaTable, _expendDataLuaFunctions, (int)ExpendLuaFuncType.IsExpanded,
					    out bool isExpanded)) return;
				var hasExpanded = HasExpanded();
				switch (isExpanded)
				{
					case true when !hasExpanded:
						Expand();
						break;
					case false when hasExpanded:
						Collapse();
						break;
				}
			}
			else
			{
				_expendDataLuaFunctions = null;
			}
		}

		private bool HasExpanded()
		{
			if (__cellData is not LuaTable luaTable) return false;
			if (!LuaUIUtility.InvokeLuaFunc(luaTable, _expendDataLuaFunctions, (int)ExpendLuaFuncType.GetChildCount,
				    out int childCount) || childCount <= 0) return false;
			if (!LuaUIUtility.InvokeLuaFunc(luaTable, _expendDataLuaFunctions, (int)ExpendLuaFuncType.GetChildAt,
				    1, out object childData)) return false;
			return -1 != TableView.GetDataIndex(childData);
		}
		
		private void Expand()
		{
			if (__cellData is not LuaTable luaTable) return;
			var startIndex = TableView.GetDataIndex(__cellData);
			if (!LuaUIUtility.InvokeLuaFunc(luaTable, _expendDataLuaFunctions, (int)ExpendLuaFuncType.GetChildCount,
				    out int childCount) || childCount <= 0) return;
			for (int i = childCount; i > 0; i--)
			{
				if (!LuaUIUtility.InvokeLuaFunc(luaTable, _expendDataLuaFunctions, (int)ExpendLuaFuncType.GetChildAt,
					    i, out object childData)) continue;
				if (!LuaUIUtility.InvokeLuaFunc(luaTable, _expendDataLuaFunctions, (int)ExpendLuaFuncType.GetPrefabIndex,
					    i, out int childIndex)) continue;
				TableView.InsertData(startIndex+1, childData, childIndex);
			}
			LuaUIUtility.InvokeLuaFunc(luaTable, _expendDataLuaFunctions, (int)ExpendLuaFuncType.SetExpanded, true);
		}

		private void Collapse()
		{
			if (__cellData is not LuaTable luaTable) return;
			if (!LuaUIUtility.InvokeLuaFunc(luaTable, _expendDataLuaFunctions, (int)ExpendLuaFuncType.GetChildCount,
				    out int childCount) || childCount <= 0) return;
			for (int i = 1; i <= childCount; i++)
			{
				if (!LuaUIUtility.InvokeLuaFunc(luaTable, _expendDataLuaFunctions, (int)ExpendLuaFuncType.GetChildAt,
					    i, out object childData)) continue;
				TableView.RemData(childData);
			}
			LuaUIUtility.InvokeLuaFunc(luaTable, _expendDataLuaFunctions, (int)ExpendLuaFuncType.SetExpanded, false);
		}
	}
}
#endif
