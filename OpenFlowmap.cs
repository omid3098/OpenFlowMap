using System;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class OpenFlowmap : MonoBehaviour
{
    public enum Resolution { _32x32 = 32, _64x64 = 64, _128x128 = 128, _256x256 = 256, _512x512 = 512, _1024x1024 = 1024 }
    public Resolution m_textureResolution = Resolution._128x128;
    public LayerMask LayerMask;

    [SerializeField] int m_rayCount = 100;

    private MeshRenderer m_meshRenderer;
    private MeshFilter m_meshFilter;
    private RayProjector m_rayProjector;
    [SerializeField] Effector[] m_effectors;

    private void Awake()
    {
        m_meshFilter = GetComponent<MeshFilter>();
        m_meshRenderer = GetComponent<MeshRenderer>();
        Initialize();
    }

    private void OnValidate() => Initialize();

    public void Initialize()
    {
        m_rayProjector = new RayProjector(transform, m_meshFilter.sharedMesh.bounds.size, m_rayCount);
        m_effectors = GetComponents<Effector>();
        foreach (var effector in m_effectors)
        {
            effector.Register(this);
            effector.Initialize();
        }
        foreach (var effector in m_effectors)
        {
            effector.Execute();
        }
    }

    private void Update()
    {
        m_rayProjector.Draw();
    }

    internal RayProjector RayProjector => m_rayProjector;

    private void Dispose()
    {
    }

    private void OnDestroy()
    {
        Dispose();
    }
}