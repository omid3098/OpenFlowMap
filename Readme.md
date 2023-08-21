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

- Create a new OpenFlowmap object in your scene. (Right click in the hierarchy -> OpenFlowmap)
- OpenFlowmapBehaviour requires an OpenFlowmap configuration. Create a new one in your project (Right click in the project window -> Create -> OpenFlowmap -> OpenFlowmapConfig)
  You can set the layer mask, number of rays, what effectors to use, etc.
- Now you need some effectors to affect the flowmap. So far I have created these effectors:
  - OuterFlow: This effector will push the flowmap in the direction of the normal of the mesh.
  - GlobalFlowDirection: This effector will push the flowmap in a global direction.
  - BlurEffect: This effector will blur the flowmap. useful for smoothing out the flowmap when you have a low number of rays.
  - FlowmapRenderer: This effector will render the flowmap to a texture.
- Add the `OpenFlowmap` component to it.
