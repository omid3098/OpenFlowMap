using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(OpenFlowmap))]
public class OpenFlowmapEditor : Editor
{
    private OpenFlowmap openFlowmap;

    static bool m_showFlowVectors = false;
    static bool m_debug = false;
    static float m_vectorLength = 0.2f;

    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        openFlowmap = (OpenFlowmap)target;

        if (GUILayout.Button("Bake Flowmap"))
        {
            openFlowmap.BakeFlowmapTexture();
        }

        // A foldout group to show debug options
        // header: "Debug"
        m_debug = EditorGUILayout.Foldout(m_debug, "Debug");
        if (m_debug)
        {
            // A toggle to show the flowmap texture
            m_showFlowVectors = EditorGUILayout.Toggle("Show Flow Vectors", m_showFlowVectors);
            if (m_showFlowVectors)
            {
                m_vectorLength = EditorGUILayout.Slider("Vector Length", m_vectorLength, 0.1f, 1);
            }
        }
    }

    private void OnSceneGUI()
    {
        if (openFlowmap == null) openFlowmap = (OpenFlowmap)target;
        // show a button to enable visualization of the flowmap
        if (m_showFlowVectors)
        {
            VisualizeFlowmap();
        }
    }

    private void VisualizeFlowmap()
    {
        if (Event.current.type == EventType.Repaint)
        {
            OpenFlowmap openFlowmap = (OpenFlowmap)target;
            if (openFlowmap.FlowmapPoints == null) return;
            if (openFlowmap.FlowmapColors == null) return;
            for (int i = 0; i < openFlowmap.FlowmapPoints.Count; i++)
            {
                var pointPosition = openFlowmap.GetPointPosition(openFlowmap.FlowmapPoints[i].x, openFlowmap.FlowmapPoints[i].y);
                Color color = openFlowmap.FlowmapColors[i];
                color.a = 1;
                Handles.color = color;
                // Lets calculate the direction of the flow vector from the color
                Vector3 direction = new Vector3(color.r - 0.5f, 0, color.g - 0.5f);
                // Draw the flow vector
                Handles.DrawLine(pointPosition, pointPosition + (direction + Vector3.up) * m_vectorLength);
                // Handles.DrawLine(pointPosition, pointPosition + Vector3.up * 0.3f);
            }
        }
    }
}
