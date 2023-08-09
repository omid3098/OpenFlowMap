using NUnit.Framework;
using UnityEngine;

public class OpenFlowmapTests
{
    private OpenFlowmap flowmap;

    [SetUp]
    public void Setup()
    {
        GameObject gameObject = new GameObject();
        gameObject.AddComponent<MeshRenderer>();
        var _collider = gameObject.AddComponent<BoxCollider>();
        _collider.size = new Vector3(1, 0.001f, 1);
        flowmap = gameObject.AddComponent<OpenFlowmap>();
        flowmap.resolutionEnum = OpenFlowmap.Resolution._32x32;
        flowmap.radius = 0.2f;
        flowmap.layerMask = LayerMask.GetMask("Water");
        flowmap.InitializeFlowmapPoints();
    }

    [Test]
    public void TestFlowmapPointsInitialized()
    {
        Assert.AreEqual(flowmap.FlowmapPoints.Count, 32 * 32);
    }

    [Test]
    public void TestFlowmapColorsInitialized()
    {
        Assert.AreEqual(flowmap.FlowmapColors.Count, 32 * 32);
    }

    [Test]
    public void TestGetPointPosition()
    {
        Vector3 pointPosition = flowmap.GetPointPosition(0, 0);
        Assert.AreEqual(new Vector3(-0.5f, 0, -0.5f), pointPosition);

        pointPosition = flowmap.GetPointPosition(31, 31);
        // get the two leading digits after the decimal point
        pointPosition.x = Mathf.Round(pointPosition.x * 100) / 100;
        pointPosition.z = Mathf.Round(pointPosition.z * 100) / 100;

        Assert.AreEqual(new Vector3(0.47f, 0, 0.47f), pointPosition);
    }

    [Test]
    public void TestGetFlowDirectionColor()
    {
        GameObject sphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        sphere.transform.position = new Vector3(0, 0, 0);
        Collider[] hitColliders = new Collider[1];
        hitColliders[0] = sphere.GetComponent<Collider>();
        Color color = flowmap.GetFlowDirectionColor(hitColliders, new Vector3(0, 0, 0));
        Assert.AreEqual(color, new Color(0.5f, 0.5f, 0, 1));
        Object.DestroyImmediate(sphere);
    }

    [Test]
    public void TestFindFlowPoints()
    {
        flowmap.GetFlowPoints();
        Assert.AreEqual(flowmap.FlowmapColors.Count, 32 * 32);
    }

    [Test]
    public void TestGetFlowmapTexture()
    {
        Texture texture = flowmap.GetFlowmapTexture();
        Assert.AreEqual(texture.width, 32);
        Assert.AreEqual(texture.height, 32);
    }
}