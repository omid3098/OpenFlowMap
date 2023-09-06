using System;
using UnityEngine;

[Obsolete("Use OpenFlowmapBehaviour.")]
[CreateAssetMenu(fileName = "OpenFlowmapConfig", menuName = "OpenFlowmap/OpenFlowmapConfig", order = 1)]
public class OpenFlowmapConfig : ScriptableObject
{
    public LayerMask LayerMask;
    [SerializeField] int m_rayCount = 100;
    [SerializeField, Range(0f, 1f)] float m_rayLength = 0.5f;
    [SerializeField] RayProcessor[] m_processors;
}
