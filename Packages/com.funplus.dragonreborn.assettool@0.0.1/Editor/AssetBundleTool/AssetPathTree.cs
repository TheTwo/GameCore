using System;
using System.Collections.Generic;

// ReSharper disable once CheckNamespace
namespace DragonReborn.AssetTool.Editor
{
	public class AssetPathTree<T>
	{
		private readonly AssetPathNode _root = new();

		private class AssetPathNode
		{
			public readonly Dictionary<string, AssetPathNode> Children =
				new Dictionary<string, AssetPathNode>(StringComparer.OrdinalIgnoreCase);
			public T Content;
			public bool HasContent;
		}

		public void Clear()
		{
			_root.Children.Clear();
		}
		
		public void AddPath(string path, T content, char split)
		{
			var span = path.AsSpan();
			span = span.Trim(split);
			var currentNode = _root;
			var index = span.IndexOf(split);
			AssetPathNode node;
			string key;
			while (index > 0)
			{
				key = span[..index].ToString();
				if (!currentNode.Children.TryGetValue(key, out node))
				{
					node = new AssetPathNode();
					currentNode.Children.Add(key, node);
				}
				currentNode = node;
				span = span[(index + 1)..];
				index = span.IndexOf(split);
			}
			key = span.ToString();
			if (!currentNode.Children.TryGetValue(key, out node))
			{
				node = new AssetPathNode();
				currentNode.Children.Add(key, node);
			}
			node.Content = content;
			node.HasContent = true;
		}

		public bool TryMatch(string path, bool topMostMatch, char split,  out T content)
		{
			content = default;
			var span = path.AsSpan();
			span = span.Trim(split);
			var parentNode = _root;
			var index = span.IndexOf(split);
			AssetPathNode retNode = null;
			string key;
			AssetPathNode node;
			while (index > 0)
			{
				key = span[..index].ToString();
				if (!parentNode.Children.TryGetValue(key, out node))
				{
					if (null == retNode) return false;
					content = retNode.Content;
					return true;
				}
				if (node.HasContent)
				{
					if (topMostMatch)
					{
						content = node.Content;
						return true;
					}
					retNode = node;
				}
				parentNode = node;
				span = span[(index + 1)..];
				index = span.IndexOf(split);
			}
			key = span.ToString();
			if (!parentNode.Children.TryGetValue(key, out node))
			{
				if (null == retNode) return false;
				content = retNode.Content;
				return true;
			}
			if (node.HasContent)
			{
				content = node.Content;
				return true;
			}
			if (null == retNode) return true;
			content = retNode.Content;
			return true;
		}
	}
}
