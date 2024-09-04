using System;
using System.Diagnostics.Contracts;
using System.Runtime.InteropServices;
using Unity.Collections.LowLevel.Unsafe;

// ReSharper disable once CheckNamespace
// ReSharper disable once StructCanBeMadeReadOnly
public unsafe ref struct LuaArrayTableRef
{
	private readonly bool _isValid;
	private readonly LuaArrayTable* _ptr;

	[Pure]
	public bool IsTableSizeFit(int needSize)
	{
		if (!_isValid)
			return false;
		return _ptr->sizearray >= needSize;
	}

	public LuaArrayTableRef(IntPtr intPtr)
	{
		if (intPtr == IntPtr.Zero) 
			throw new ArgumentNullException($"{nameof(intPtr)} is null, make sure context code is binded to xlua!");
		_ptr = (LuaArrayTable*)intPtr;
		_isValid = true;
	}

	[Pure]
	public ref LuaTValue ValueRefAtIndex(int index)
	{
		if (!_isValid)
			throw new ArgumentNullException($"{nameof(_ptr)} is null, make sure context code is binded to xlua!");
		return ref UnsafeUtility.ArrayElementAsRef<LuaTValue>(_ptr->array, index);
	}
}

// ReSharper disable once StructCanBeMadeReadOnly
public ref struct LuaValueArrayTableRef<T> where T : unmanaged
{
	private readonly LuaArrayTableRef _array;
	public readonly int Length;

	public T this[int index]
	{
		get
		{
			if (index < 0 || index >= Length)
				throw new ArgumentOutOfRangeException();
			ref var v = ref _array.ValueRefAtIndex(index);
			return v.To(out T ret) ? ret : default;
		}
		set
		{
			if (index < 0 || index >= Length)
				throw new ArgumentOutOfRangeException();
			ref var v = ref _array.ValueRefAtIndex(index);
			v.Set(value);
		}
	}

	public LuaValueArrayTableRef(ref LuaArrayTableRef array, int length)
	{
		if (!array.IsTableSizeFit(length))
		{
			throw new ArgumentOutOfRangeException();
		}
		_array = array;
		Length = length;
	}
}

[StructLayout(LayoutKind.Sequential)]
public unsafe struct LuaArrayTable
{
	// ReSharper disable InconsistentNaming
	// ReSharper disable IdentifierTypo
	// ReSharper disable UnassignedField.Global
	// ReSharper disable BuiltInTypeReferenceStyle
	// ReSharper disable UnusedMember.Global
	public IntPtr next;
	public Byte tt;
	public Byte marked;
	public Byte flags;
	public Byte lsizenode;
	public UInt32 sizearray; // sizearray not equals to count of array elements, it's array memory size
	public LuaTValue* array;
	public IntPtr node;
	public IntPtr lastfree;
	public IntPtr metatable;
	public IntPtr gclist;
	// ReSharper restore UnusedMember.Global
	// ReSharper restore BuiltInTypeReferenceStyle
	// ReSharper restore UnassignedField.Global
	// ReSharper restore IdentifierTypo
	// ReSharper restore InconsistentNaming
}

[StructLayout(LayoutKind.Explicit, Size = 16)]
public struct LuaTValue
{
	// ReSharper disable MemberCanBePrivate.Global
	// ReSharper disable FieldCanBeMadeReadOnly.Global
	// ReSharper disable BuiltInTypeReferenceStyle
	[FieldOffset(0)] public IntPtr gc;
	[FieldOffset(0)] public IntPtr p;
	[FieldOffset(0)] public int b;
	[FieldOffset(0)] public IntPtr f;
	[FieldOffset(0)] public long i;
	[FieldOffset(0)] public double n;
	[FieldOffset(8)] public Int32 tt_;
	// ReSharper restore BuiltInTypeReferenceStyle
	// ReSharper restore FieldCanBeMadeReadOnly.Global
	// ReSharper restore MemberCanBePrivate.Global
}

public static class LuaArrayTableHelper
{
	// ReSharper disable InconsistentNaming
	// ReSharper disable IdentifierTypo
	// ReSharper disable ShiftExpressionZeroLeftOperand
	/* basic types */
	private const int LUA_TNONE = -1;
	private const int LUA_TNIL = 0;
	private const int LUA_TBOOLEAN = 1;
	private const int LUA_TLIGHTUSERDATA = 2;
	private const int LUA_TNUMBER = 3;
	private const int LUA_TSTRING = 4;
	private const int LUA_TTABLE = 5;
	private const int LUA_TFUNCTION = 6;
	private const int LUA_TUSERDATA = 7;
	private const int LUA_TTHREAD = 8;
	private const int LUA_NUMTAGS = 9;
	
	public enum LuaValueType
	{
		TNONE = LUA_TNONE,
		TNIL = LUA_TNIL,
		TBOOLEAN = LUA_TBOOLEAN,
		TLIGHTUSERDATA = LUA_TLIGHTUSERDATA,
		TNUMBER = LUA_TNUMBER,
		TSTRING = LUA_TSTRING,
		TTABLE = LUA_TTABLE,
		TFUNCTION = LUA_TFUNCTION,
		TUSERDATA = LUA_TUSERDATA,
		TTHREAD = LUA_TTHREAD,
		NUMTAGS = LUA_NUMTAGS,
	}
	
	/*
	** tags for Tagged Values have the following use of bits:
	** bits 0-3: actual tag (a LUA_T* value)
	** bits 4-5: variant bits
	** bit 6: whether value is collectable
	*/
	
	/*
	** LUA_TFUNCTION variants:
	** 0 - Lua function
	** 1 - light C function
	** 2 - regular C function (closure)
	*/
	
	/* Variant tags for functions */
	private const int LUA_TLCL = (LUA_TFUNCTION | (0 << 4));  /* Lua closure */
	private const int LUA_TLCF = (LUA_TFUNCTION | (1 << 4));  /* light C function */
	private const int LUA_TCCL = (LUA_TFUNCTION | (2 << 4));  /* C closure */
	
	/* Variant tags for strings */
	private const int LUA_TSHRSTR = (LUA_TSTRING | (0 << 4));  /* short strings */
	private const int LUA_TLNGSTR = (LUA_TSTRING | (1 << 4));  /* long strings */
	
	/* Variant tags for numbers */
	private const int LUA_TNUMFLT = LUA_TNUMBER | (0 << 4); /* float numbers */
	private const int LUA_TNUMINT = LUA_TNUMBER | (1 << 4); /* integer numbers */

	/* Bit mark for collectable types */
	private const int BIT_ISCOLLECTABLE = (1 << 6);
	
	// ReSharper restore ShiftExpressionZeroLeftOperand
	// ReSharper restore IdentifierTypo
	// ReSharper restore InconsistentNaming

	public static bool IsCollectable(this in LuaTValue value)
	{
		return (value.tt_ & BIT_ISCOLLECTABLE) != 0;
	}

	public static LuaValueType ValueType(this in LuaTValue value)
	{
		const int typeMask = 0b1111;
		return (LuaValueType)(value.tt_ & typeMask);
	}

	public static bool To<T>(this in LuaTValue value, out T retValue) where T : unmanaged
	{
		var t = typeof(T);
		// ReSharper disable once SwitchStatementMissingSomeEnumCasesNoDefault
		switch (value.tt_)
		{
			case LUA_TNUMFLT:
				switch (Type.GetTypeCode(t))
				{
					case TypeCode.Double:
						var doubleValue = value.n;
						retValue = UnsafeUtility.As<double, T>(ref doubleValue);
						return true;
					case TypeCode.Single:
						var floatValue = (float)value.n;
						retValue = UnsafeUtility.As<float, T>(ref floatValue);
						return true;
					case TypeCode.Byte:
						var byteValue = (byte)value.n;
						retValue = UnsafeUtility.As<byte, T>(ref byteValue);
						return true;
					case TypeCode.Int32:
						var intValue = (int)value.n;
						retValue = UnsafeUtility.As<int, T>(ref intValue);
						return true;
					case TypeCode.Int64:
						var longValue = (long)value.n;
						retValue = UnsafeUtility.As<long, T>(ref longValue);
						return true;
				}
				break;
			case LUA_TNUMINT:
				switch (Type.GetTypeCode(t))
				{
					case TypeCode.Double:
						var doubleValue = (double)value.i;
						retValue = UnsafeUtility.As<double, T>(ref doubleValue);
						return true;
					case TypeCode.Single:
						var floatValue = (float)value.i;
						retValue = UnsafeUtility.As<float, T>(ref floatValue);
						return true;
					case TypeCode.Byte:
						var byteValue = (byte)value.i;
						retValue = UnsafeUtility.As<byte, T>(ref byteValue);
						return true;
					case TypeCode.Int32:
						var intValue = (int)value.i;
						retValue = UnsafeUtility.As<int, T>(ref intValue);
						return true;
					case TypeCode.Int64:
						var longValue = value.i;
						retValue = UnsafeUtility.As<long, T>(ref longValue);
						return true;
				}
				break;
		}
		throw new NotImplementedException();
	}

	public static void Set<T>(this ref LuaTValue target, T value) where T : unmanaged
	{
		var t = typeof(T);
		// ReSharper disable once SwitchStatementMissingSomeEnumCasesNoDefault
		// ReSharper disable once SwitchStatementHandlesSomeKnownEnumValuesWithDefault
		switch (Type.GetTypeCode(t))
		{
			case TypeCode.Double:
				target.tt_ = LUA_TNUMFLT;
				var doubleValue = UnsafeUtility.As<T, double>(ref value);
				target.n = doubleValue;
				break;
			case TypeCode.Single:
				target.tt_ = LUA_TNUMFLT;
				var floatValue = UnsafeUtility.As<T, float>(ref value);
				target.n = floatValue;
				break;
			case TypeCode.Byte:
				target.tt_ = LUA_TNUMINT;
				var byteValue = UnsafeUtility.As<T, byte>(ref value);
				target.i = byteValue;
				break;
			case TypeCode.Int32:
				target.tt_ = LUA_TNUMINT;
				var intValue = UnsafeUtility.As<T, int>(ref value);
				target.i = intValue;
				break;
			case TypeCode.Int64:
				target.tt_ = LUA_TNUMINT;
				var longValue = UnsafeUtility.As<T, long>(ref value);
				target.i = longValue;
				break;
			default:
				throw new NotImplementedException();
		}
	}
}
