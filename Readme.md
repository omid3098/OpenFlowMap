# OpenFlowmap

<!--- <img width="771" alt="image" src="https://github.com/omid3098/OpenFlowMap/assets/6388730/a94c2169-190a-4bd3-9f02-5c2f9037eaa1"> --->

![OpenFlowmap-debug](https://github.com/omid3098/OpenFlowMap/assets/6388730/99f03ee2-050b-4db9-bf24-742dc080bd9f)

![OpenFlowmap-water](https://github.com/omid3098/OpenFlowMap/assets/6388730/f5b50903-f05a-47c2-af22-92b22f1b82ab)

Generate flowmap dynamically from your scene.

**Note: It is not recommended to use this in real-time, as it is quite expensive.**

## Installation

### Manually

Clone this repository into your project's `Assets` folder.

### Unity Package Manager

TODO: Add UPM installation instructions

## Usage

- Create a new Flowmap_Plane in your scene. (Right click in the hierarchy -> OpenFlowmap)
  
  <img width="245" alt="image" src="https://github.com/omid3098/OpenFlowMap/assets/6388730/d53f2b88-c5b3-4def-8453-518cef7023ba">


- Drag and drop processors like _**RealisticFlow**_ and _**BlurEffect**_ to the Processors list. you can find them in _**OpenFlowmap/Data/Processors/**_ directory. Please note that the processors will be executed in the order they are in the list. so if you want to blur the flowmap, you need to add the blur processor after something like outer flow.
  - OuterFlow: This processor will push the flowmap in the direction of the normal of the mesh.
  - BlurEffect: This processor will blur the flowmap. useful for smoothing out the flowmap when you have a low number of rays.
  - RealisticFlow: This processor will simulate a realistic flow

    <img width="236" alt="image" src="https://github.com/omid3098/OpenFlowMap/assets/6388730/0decc163-7a15-425c-a865-1b8631437585">

- Select the Layermask to check for obstacles along the flow.
- Create a RenderTexture and assign it to the render texture field in the OpenFlowmap Behaviour
- You can enable ProcessEveryFrame to update the changes everyframe. like when you want to change the position of obstacles.

There are few sample shaders and materials in Sample directory. you can use them to visualize the flowmap. just drag and drop desired material to the flowmap plane.




## Example usage using sample processors:


https://github.com/omid3098/OpenFlowMap/assets/6388730/451b602e-d59a-4bdb-b596-2e5c0e3acdcf

