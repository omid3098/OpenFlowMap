using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(OpenFlowmapBehaviour))]
public class OpenFlowmapBehaviourEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        if (GUILayout.Button("Save Flowmap"))
        {
            string path = EditorUtility.SaveFilePanelInProject("Save Flowmap", "flowmap", "png", "Save the current flowmap as png");
            if (!string.IsNullOrEmpty(path) && target is OpenFlowmapBehaviour flowmap)
            {
                flowmap.SaveTexture(path);

                // Refresh the AssetDatabase after saving the file
                AssetDatabase.Refresh();

                var textureImporter = AssetImporter.GetAtPath(path) as TextureImporter;
                textureImporter.textureType = TextureImporterType.NormalMap;
                textureImporter.textureCompression = TextureImporterCompression.Uncompressed;
                textureImporter.crunchedCompression = false;
                textureImporter.SaveAndReimport();
            }
        }
    }
}
