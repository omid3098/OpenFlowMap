using System;
using UnityEngine;

public abstract class Effector : MonoBehaviour
{
    protected OpenFlowmap m_openFlowmap;
    public void Register(OpenFlowmap openFlowmap)
    {
        m_openFlowmap = openFlowmap;
    }

    public abstract void Initialize();
    internal abstract void Execute(RayProjector m_rayProjector);

    private void OnValidate()
    {
        if (m_openFlowmap != null)
        {
            m_openFlowmap.Initialize();
        }
    }
}