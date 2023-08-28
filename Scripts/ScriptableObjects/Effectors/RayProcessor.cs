using System;
using UnityEngine;

public abstract class RayProcessor : ScriptableObject
{
    protected OpenFlowmapConfig openFlowmapConfig;
    public void Register(OpenFlowmapConfig openFlowmap)
    {
        this.openFlowmapConfig = openFlowmap;
    }

    public virtual void Initialize() { }
    internal abstract void Execute();

    private void OnValidate()
    {
        if (openFlowmapConfig != null)
        {
            openFlowmapConfig.Initialize();
        }
    }

    internal virtual void Draw() { }
}