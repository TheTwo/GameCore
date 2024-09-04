using System.Collections.Generic;

namespace DragonReborn
{
    public class LuaEnum
    {
        public readonly List<KeyValuePair<string, int>> Items = new List<KeyValuePair<string, int>>();

        public int GetIndex(int value)
        {
            for (var i = 0; i < Items.Count; i++)
            {
                if (Items[i].Value == value)
                {
                    return i;
                }
            }

            return 0;
        }

        public string[] GetOptions()
        {
            var options = new string[Items.Count];
            for (var i = 0; i < Items.Count; i++)
            {
                options[i] = Items[i].Key;
            }

            return options;
        }

        public int GetValueByIndex(int index)
        {
            return Items[index].Value;
        }

        public string GetNameByValue(int value)
        {
            if (Items.Count <= 0)
            {
                return string.Empty;
            }

            foreach (var item in Items)
            {
	            if (item.Value == value)
	            {
		            return item.Key;
	            }
            }

            return Items[0].Key;
        }
    }

}