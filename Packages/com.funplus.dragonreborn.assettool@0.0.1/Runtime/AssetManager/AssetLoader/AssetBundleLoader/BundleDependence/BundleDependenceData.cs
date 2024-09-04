using System.Collections.Generic;

namespace DragonReborn.AssetTool
{
    public class BundleDependenceData
    {
        public string BundleName;
        public IReadOnlyList<string> Dependence;
		//public string Hash;

        public bool HasDependence()
        {
            return Dependence != null && Dependence.Count > 0;
        }
    }
}
