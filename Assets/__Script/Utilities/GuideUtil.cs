using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using DragonReborn;
public class GuideUtil
{
	const char cmdStart = '{';
	const char cmdSplit = ',';
	const char cmdEnd = '}';

	public static string[] SplitCmd(string cmdStr)
	{
		var chars = cmdStr.ToCharArray();
		int s = -1, p1 = -1, p2 = -1;
		var cmds = new List<string>();
		Queue<int> deep = new Queue<int>();
		for (int i = 0; i < chars.Length; i++)
		{
			switch (chars[i])
			{
				case cmdStart:
					s = i;
					p1 = -1;
					p2 = -1;
					break;
				case cmdSplit:
					if (s == -1) break;
					if (p1 < 0)
					{
						cmds.Add(cmdStr.Substring(s + 1, i - s - 1).Trim());
						p1 = i;
					}
					else if (p2 < 0)
					{
						cmds.Add(cmdStr.Substring(p1 + 1, i - p1 - 1).Trim());
						p2 = i;
					}
					else
					{
						Debug.LogError($"To Many Params:{cmds[cmds.Count - 2]},{cmds[cmds.Count - 1]},...");
					}
					break;
				case cmdEnd:
					if (s == -1) break;
					if (p1 < 0)
					{
						cmds.Add(cmdStr.Substring(s + 1, i - s - 1).Trim());
					}
					else if (p2 < 0)
					{
						cmds.Add(cmdStr.Substring(p1 + 1, i - p1 - 1).Trim());
					}
					else
					{
						cmds.Add(cmdStr.Substring(p2 + 1, i - p2 - 1).Trim());
					}
					s = -1;
					break;
			}
		}
		cmds.Reverse();
		return cmds.ToArray();
	}

	public static int SplitCmd(string cmdStr, string[] stack)
	{
		var chars = cmdStr.ToCharArray();
		int s = -1, p1 = -1, p2 = -1;
		//var cmds = new List<string>();
		var stackLength = stack.Length;
		var top = 0;
		Queue<int> deep = new Queue<int>();
		for (int i = 0; i < chars.Length; i++)
		{
			switch (chars[i])
			{
				case cmdStart:
					s = i;
					p1 = -1;
					p2 = -1;					
					break;
				case cmdSplit:
					if (s == -1) break;
					if (p1 < 0)
					{
						stack[top++] = (cmdStr.Substring(s + 1, i - s - 1).Trim());
						p1 = i;
					}
					else if (p2 < 0)
					{
						stack[top++] = (cmdStr.Substring(p1 + 1, i - p1 - 1).Trim());
						p2 = i;
					}
					else
					{
						Debug.LogError($"To Many Params:{stack[top - 2]},{stack[top - 1]},...");
					}
					break;
				case cmdEnd:
					if (s == -1) break;
					if (p1 < 0)
					{
						stack[top++] = (cmdStr.Substring(s + 1, i - s - 1).Trim());
					}
					else if (p2 < 0)
					{
						stack[top++] = (cmdStr.Substring(p1 + 1, i - p1 - 1).Trim());
					}
					else
					{
						stack[top++] = (cmdStr.Substring(p2 + 1, i - p2 - 1).Trim());
					}
					s = -1;
					break;
			}
			if (top >= stackLength)
			{
				Debug.LogError($"Stack is Full");
				break;
			}
		}
		return top;
	}

	public static string IntArray2Base64String(int[] intArray)
	{
		if (intArray == null || intArray.Length < 1) return String.Empty;
		byte[] dataBuffer = new byte[intArray.Length * sizeof(int)];
		Buffer.BlockCopy(intArray, 0, dataBuffer, 0, dataBuffer.Length);
		var zipData = GzipUtils.EncodeByGzip(dataBuffer);
		return Convert.ToBase64String(zipData);
	}

	public static int[] Base64String2IntArray(string base64Str)
	{
		byte[] zipBuffer = Convert.FromBase64String(base64Str);
		var dataBuffer = GzipUtils.DecodeByGzip(zipBuffer);
		int[] ints = new int[dataBuffer.Length / sizeof(int)];
		Buffer.BlockCopy(dataBuffer,0,ints,0,dataBuffer.Length);
		return ints;
	}
	
}
