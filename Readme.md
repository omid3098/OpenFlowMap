# OpenFlowmap

Generate flowmap dynamically from your scene.
Note: It is not recommended to use this in real-time, as it is quite expensive.

## Installation

### Manually

Clone this repository into your project's `Assets` folder.

### Unity Package Manager

TODO: Add UPM installation instructions

## Usage

Make sure Opaque Texture is enabled in your render pipeline asset.

- Create a new Flowmap_Plane in your scene. (Right click in the hierarchy -> OpenFlowmap)
- We need an OpenFlowmap configuration. Create a new one in your project (Right click in the project window -> Create -> OpenFlowmap -> OpenFlowmapConfig) and assign it to the OpenFlowmap object.
  You can set the layer mask, number of rays, ray processors to use, etc.
- Now you need some processors to affect the flowmap. So far I have implemented these processors:
  - OuterFlow: This processor will push the flowmap in the direction of the normal of the mesh.
  - GlobalFlowDirection: This processor will push the flowmap in a global direction.
  - BlurEffect: This processor will blur the flowmap. useful for smoothing out the flowmap when you have a low number of rays.
  - FlowmapRenderer: This processor will render the flowmap to a texture.
- Add the processors you want to use to the OpenFlowmap object. Please note that the processors will be executed in the order they are in the list. so if you want to blur the flowmap, you need to add the blur processor after something like outer flow. or putting the flowmap renderer at the end of the list.
- You can Render the flowmap to a texture by adding a FlowmapRenderer processor to the OpenFlowmap configuration.
