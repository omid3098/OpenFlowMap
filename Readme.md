# OpenFlowmap
<img width="791" alt="image" src="https://github.com/omid3098/OpenFlowMap/assets/6388730/0f6024ef-055c-4a36-aa34-98d81eb61822">

Generate flowmap dynamically from your scene.

**Note: It is not recommended to use this in real-time, as it is quite expensive.**
## Installation

### Manually

Clone this repository into your project's `Assets` folder.

### Unity Package Manager

TODO: Add UPM installation instructions

## Usage

- Create a new Flowmap_Plane in your scene. (Right click in the hierarchy -> OpenFlowmap)
  
  <img width="226" alt="image" src="https://github.com/omid3098/OpenFlowMap/assets/6388730/b8ff21a2-131b-4d62-b568-6d2129fef768">

- We need an OpenFlowmap configuration. Create a new one in your project (Right click in the project window -> Create -> OpenFlowmap -> OpenFlowmapConfig) and assign it to the OpenFlowmap object.
  You can set the layer mask, number of rays, ray processors to use, etc.
  <img width="223" alt="image" src="https://github.com/omid3098/OpenFlowMap/assets/6388730/8f441560-6dba-43e3-ad29-a9110c455b31">

- Now you need some processors to affect the flowmap. So far I have implemented these processors:
  - OuterFlow: This processor will push the flowmap in the direction of the normal of the mesh.
  - GlobalFlowDirection: This processor will push the flowmap in a global direction.
  - BlurEffect: This processor will blur the flowmap. useful for smoothing out the flowmap when you have a low number of rays.
  - FlowmapRenderer: This processor will render the flowmap to a texture.

- Add the processors you want to use to the OpenFlowmap object. Please note that the processors will be executed in the order they are in the list. so if you want to blur the flowmap, you need to add the blur processor after something like outer flow. or putting the flowmap renderer at the end of the list.
- Or use available ones in Data->Processors directory (drag them into the processors field of the configuration file)
  
  <img width="205" alt="image" src="https://github.com/omid3098/OpenFlowMap/assets/6388730/6321e75f-299e-4d13-a868-dd03a54de50b">
- You can Render the flowmap to a texture by adding a FlowmapRenderer processor to the OpenFlowmap configuration. it will create a texture at the same directory as your scene file. (feel free to change it)
