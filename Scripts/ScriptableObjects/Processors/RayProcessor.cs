using UnityEngine;

public abstract class RayProcessor : ScriptableObject
{
    protected OpenFlowmapBehaviour openFlowmapBehaviour;

    public void Register(OpenFlowmapBehaviour openFlowmap)
    {
        openFlowmapBehaviour = openFlowmap;
    }

    public virtual void Initialize() { }

    internal abstract void Execute(RayProjector rayProjector);

    private void OnValidate()
    {
        if (openFlowmapBehaviour != null)
        {
            openFlowmapBehaviour.RayProcessorOnValidate(this);
        }
    }

    internal virtual void Draw() { }
}
