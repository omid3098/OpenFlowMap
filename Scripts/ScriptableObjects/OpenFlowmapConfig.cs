using UnityEngine;

[CreateAssetMenu(fileName = "OpenFlowmapConfig", menuName = "OpenFlowmap/OpenFlowmapConfig", order = 1)]
public class OpenFlowmapConfig : ScriptableObject
{
    public LayerMask LayerMask;
    internal RayProjector RayProjector => m_rayProjector;
    internal int RayResolution => m_rayCount;
    public int RayCount => m_rayCount;

    public Vector3 Size { get => m_size; }
    public Vector3 PlaneOrigin { get => m_planeOrigin; }
    public Plane Plane { get => m_plane; }

    [SerializeField] int m_rayCount = 100;
    [SerializeField, Range(0f, 1f)] float m_rayLength = 0.5f;
    private RayProjector m_rayProjector;
    [SerializeField] RayProcessor[] m_processors;
    private Vector3 m_size;
    private Plane m_plane;
    private Vector3 m_planeOrigin;

    public void SetData(Vector3 size, Plane plane, Vector3 planeOrigin)
    {
        m_size = size;
        m_plane = plane;
        m_planeOrigin = planeOrigin;
    }

    private void OnValidate() => Initialize();

    public void Initialize()
    {
        m_rayProjector = new RayProjector(
            m_size,
            m_plane,
            m_planeOrigin,
            m_rayCount,
            m_rayLength);
        for (int i = 0; i < m_processors.Length; i++)
        {
            RayProcessor effector = m_processors[i];
            if (effector != null)
            {
                effector.Register(this);
                effector.Initialize();
                effector.Execute();
            }
        }
    }

    public void Draw()
    {
        m_rayProjector.Draw();
        foreach (var processor in m_processors)
        {
            processor.Draw();
        }
    }

    private void Dispose()
    {
    }

    private void OnDestroy()
    {
        Dispose();
    }
}