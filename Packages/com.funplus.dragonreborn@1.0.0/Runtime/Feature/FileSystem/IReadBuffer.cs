using System;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	public interface IReadBuffer
	{
		IntPtr BeginReadPtr(int size);
		ReadOnlySpan<byte> EndReadPtr(IntPtr ptr);
		Span<byte> BeginReadSpan(int size);
		ReadOnlySpan<byte> EndReadSpan(in Span<byte> origin, int readSize);
		void ClearBuffer();
	}
}
