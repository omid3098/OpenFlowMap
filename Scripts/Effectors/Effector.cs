using System;
using UnityEngine;

public abstract class Effector : MonoBehaviour
{
    protected OpenFlowmap openFlowmap;
    public void Register(OpenFlowmap openFlowmap)
    {
        this.openFlowmap = openFlowmap;
    }

    public virtual void Initialize() { }
    internal abstract void Execute();

    private void OnValidate()
    {
        if (openFlowmap != null)
        {
            openFlowmap.Initialize();
        }
    }
}