using UnityEngine;

[CreateAssetMenu(fileName = "OpenFlowmap", menuName = "OpenFlowmap/OpenFlowmap", order = 1)]
public class OpenFlowmap : ScriptableObject
{
    public LayerMask LayerMask;
    internal RayProjector RayProjector => m_rayProjector;
    internal int RayResolution => m_rayCount;
    public int RayCount => m_rayCount;

    [SerializeField] int m_rayCount = 100;
    private RayProjector m_rayProjector;
    [SerializeField] Effector[] m_effectors;
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
        m_rayProjector = new RayProjector(m_size, m_plane, m_planeOrigin, m_rayCount);
        for (int i = 0; i < m_effectors.Length; i++)
        {
            Effector effector = m_effectors[i];
            if (effector != null)
            {
                effector.Register(this);
                effector.Initialize();
                effector.Execute();
            }
        }
    }

    public void Update()
    {
        m_rayProjector.Draw();
    }


    private void Dispose()
    {
    }

    private void OnDestroy()
    {
        Dispose();
    }
}