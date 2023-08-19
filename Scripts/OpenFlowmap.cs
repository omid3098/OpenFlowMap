using UnityEngine;
[ExecuteInEditMode]
public class OpenFlowmap : MonoBehaviour
{
    public LayerMask LayerMask;
    internal RayProjector RayProjector => m_rayProjector;
    internal int RayResolution => m_rayCount;

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
        if (transform.hasChanged)
        {
            transform.hasChanged = false;
            Initialize();
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