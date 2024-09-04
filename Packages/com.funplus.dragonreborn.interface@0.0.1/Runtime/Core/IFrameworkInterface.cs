
// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    public interface IFrameworkInterface
    {
    }

    public interface IFrameworkInterface<T> : IFrameworkInterface where T : IFrameworkInterface<T>
    {
        
    }
}