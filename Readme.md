# OpenFlowmap

<img width="771" alt="image" src="https://github.com/omid3098/OpenFlowMap/assets/6388730/a94c2169-190a-4bd3-9f02-5c2f9037eaa1">


Generate flowmap dynamically from your scene.

**Note: It is not recommended to use this in real-time, as it is quite expensive.**

## Installation

### Manually

Clone this repository into your project's `Assets` folder.

### Unity Package Manager

TODO: Add UPM installation instructions

## Usage

- Create a new Flowmap_Plane in your scene. (Right click in the hierarchy -> OpenFlowmap)

  <img width="269" alt="image" src="https://github.com/omid3098/OpenFlowMap/assets/6388730/3e2ef15a-f0ce-4e36-b625-2c07bef80903">


- We need an OpenFlowmap configuration. Create a new one in your project (Right click in the project window -> Create -> OpenFlowmap -> OpenFlowmapConfig) and assign it to the OpenFlowmap object.
  You can set the layer mask, number of rays, ray processors to use, etc.

  <img width="268" alt="image" src="https://github.com/omid3098/OpenFlowMap/assets/6388730/75bfa26f-5fb3-4492-a554-2ee37ccb769c">


- Now you need some processors to affect the flowmap. So far I have implemented these processors:

  - OuterFlow: This processor will push the flowmap in the direction of the normal of the mesh.
  - GlobalFlowDirection: This processor will push the flowmap in a global direction.
  - BlurEffect: This processor will blur the flowmap. useful for smoothing out the flowmap when you have a low number of rays.
  - FlowmapRenderer: This processor will render the flowmap to a texture.

- Add the processors you want to use to the OpenFlowmap object. Please note that the processors will be executed in the order they are in the list. so if you want to blur the flowmap, you need to add the blur processor after something like outer flow. or putting the flowmap renderer at the end of the list.
- Or use available ones in Sample->Data->Processors directory (drag them into the processors field of the configuration file)

  <img width="262" alt="image" src="https://github.com/omid3098/OpenFlowMap/assets/6388730/2f7a690e-df2a-4584-858a-62ef23da1e8b">

- You can Render the flowmap to a texture by adding a FlowmapRenderer processor to the OpenFlowmap configuration. it will create a texture at the same directory as your scene file. (feel free to change it)

There are few sample shaders and materials in Sample -> Shaders directory. you can use them to visualize the flowmap. just drag and drop desired material to the flowmap plane.






## Example usage using sample processors:

https://github.com/omid3098/OpenFlowMap/assets/6388730/b84016ae-eb9d-4331-acdd-f3b3f8d9a665

