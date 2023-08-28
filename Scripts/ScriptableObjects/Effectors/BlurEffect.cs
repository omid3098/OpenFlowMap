using UnityEngine;
[CreateAssetMenu(fileName = "BlurEffect", menuName = "OpenFlowmap/Processor/BlurEffect")]
public class BlurEffect : RayProcessor
{
    [SerializeField, Range(0, 5)] int m_blurSize = 1;
    internal override void Execute()
    {
        var rays = openFlowmapConfig.RayProjector.GetRays();
        BlurRays(rays, m_blurSize);
    }

    void BlurRays(Ray[] rays, int size)
    {
        var width = openFlowmapConfig.RayCount;

        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < width; y++)
            {
                var rayIndex = x * width + y;
                var ray = rays[rayIndex];
                var averageDirection = Vector3.zero;
                int count = 0;

                for (int i = -size; i <= size; i++)
                {
                    for (int j = -size; j <= size; j++)
                    {
                        int xPos = Mathf.Clamp(x + i, 0, width - 1);
                        int yPos = Mathf.Clamp(y + j, 0, width - 1);

                        averageDirection += rays[xPos * width + yPos].direction;
                        count++;
                    }
                }

                averageDirection /= count;
                var newRay = new Ray(ray.origin, averageDirection);
                rays[rayIndex] = newRay;
            }
        }
    }
}
