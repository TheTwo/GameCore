using System;

namespace DragonReborn
{
    /// <summary>
    /// DomainReloading will call all static method with this Attribute
    /// </summary>
    [AttributeUsage(AttributeTargets.Method, Inherited = false)]
    public class DomainReloadingCleanupAttribute : Attribute
    {
        
    }
}