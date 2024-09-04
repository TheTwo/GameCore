// ReSharper disable once CheckNamespace
namespace DragonReborn
{
    public abstract class FrameInterfaceDescriptor
    {
        protected abstract IFrameworkInterface DoCreateInterface();

        internal IFrameworkInterface InternalCreateInterface()
        {
            return DoCreateInterface();
        }
    }
    
    public abstract class FrameInterfaceDescriptor<T> : FrameInterfaceDescriptor where T : IFrameworkInterface<T>
    {
        protected sealed override IFrameworkInterface DoCreateInterface()
        {
            return Create();
        }

        protected abstract T Create();
    }
}