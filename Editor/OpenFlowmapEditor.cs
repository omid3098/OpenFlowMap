using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(OpenFlowmap))]
public class OpenFlowmapEditor : Editor
{
    bool m_showVectors = true;
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        OpenFlowmap openFlowmap = (OpenFlowmap)target;
        m_showVectors = EditorGUILayout.Toggle("Show Flow Vectors", m_showVectors);

        if (GUILayout.Button("Bake Flowmap"))
        {
            openFlowmap.BakeFlowmapTexture();
        }
        // A checkbox to enable/disable the visualization of the flowmap
    }

    private void OnSceneGUI()
    {
        // show a button to enable visualization of the flowmap
        if (m_showVectors)
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
                Handles.DrawLine(pointPosition, pointPosition + Vector3.up * 0.3f);
            }
        }
    }
}
