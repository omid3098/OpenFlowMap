using System.Collections.Generic;
using UnityEngine;

public class Flowmap
{
    public int Resolution { get; }
    private Color[] FlowmapColors { get; }
    private Texture2D FlowmapTexture { get; }

    public Flowmap(int resolution)
    {
        Resolution = resolution;
        FlowmapColors = new Color[resolution * resolution];
        FlowmapTexture = new Texture2D(resolution, resolution, TextureFormat.RG32, false, true)
        {
            filterMode = FilterMode.Bilinear,
            wrapMode = TextureWrapMode.Clamp
        };

        for (int y = 0; y < resolution; y++)
        {
            for (int x = 0; x < resolution; x++)
            {
                int index = y * resolution + x;
                FlowmapColors[index] = new Color(0.5f, 0.5f, 0, 1);
            }
        }
    }

    public Texture GetTexture()
    {
        // Iterate over the flowmap colors and set the pixels, flipping the Y-axis
        for (int u = 0; u < Resolution; u++)
        {
            for (int v = 0; v < Resolution; v++)
            {
                int index = u * Resolution + v;
                int flippedV = Resolution - v - 1; // Flip the Y-axis
                int flippedU = Resolution - u - 1; // Flip the X-axis
                // The lower left corner of the texture is 0,0 
                FlowmapTexture.SetPixel(flippedU, flippedV, FlowmapColors[index]);
            }
        }
        FlowmapTexture.Apply(false, false);
        return FlowmapTexture;
    }

    public void SetColor(int x, int y, Color color) => FlowmapColors[x * Resolution + y] = color;
    public Color GetColor(int x, int y) => FlowmapColors[x * Resolution + y];

    public void Dispose()
    {
        if (FlowmapTexture != null)
        {
            Object.DestroyImmediate(FlowmapTexture);
        }
    }
}