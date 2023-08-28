using UnityEngine;

[ExecuteInEditMode]
public class OpenFlowmapBehaviour : MonoBehaviour
{
    [SerializeField] OpenFlowmapConfig m_openFlowmapConfig;
    [SerializeField] bool m_drawGizmos = true;

    private MeshRenderer m_meshRenderer;
    private MeshFilter m_meshFilter;
    private void Awake()
    {
        Initialize();
    }

    public void Initialize()
    {
        if (m_openFlowmapConfig != null)
        {
            m_meshFilter = GetComponent<MeshFilter>();
            m_meshRenderer = GetComponent<MeshRenderer>();
            m_openFlowmapConfig.SetData(m_meshFilter.sharedMesh.bounds.size, new Plane(transform.up, transform.position), transform.position);
            m_openFlowmapConfig.Initialize();
        }
    }

    private void OnValidate()
    {
        Initialize();
    }

    private void Update()
    {
        if (m_openFlowmapConfig != null && m_drawGizmos)
            m_openFlowmapConfig.Draw();

        if (transform.hasChanged)
        {
            transform.hasChanged = false;
            Initialize();
        }
    }
}
