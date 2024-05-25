import Foundation
import SceneKit
import SceneKit.ModelIO
import SwiftUI

/// `MeshRendererView` is a SwiftUI view that renders 3D meshes and point clouds using SceneKit, particularly geared towards displaying 3D scans and related data. It incorporates camera controls, environmental settings, and dynamic rendering based on the data provided by scene models. This view is instrumental in visualizing complex 3D data within the application, supporting interactions such as zooming, panning, and rotating the view.
public struct MeshRendererView: View {
    /// Defines a point in a point cloud, including its position and color in a three-dimensional space.
    public struct PointVertex {
        /// The x-coordinate of the point.
        let x: Float
        
        /// The y-coordinate of the point.
        let y: Float
        
        /// The z-coordinate of the point.
        let z: Float
        
        /// Red color component of the point.
        let r: Float
        
        /// Green color component of the point.
        let g: Float
        
        /// Blue color component of the point.
        let b: Float
    }
    
    /// Represents the orientation and position of a camera in a three-dimensional space.
    public struct CameraVertex {
        /// Rotation around the vertical axis (up), in radians.
        let yaw: Float
        
        /// Rotation around the lateral axis (side to side), in radians.
        let pitch: Float
        
        /// Rotation around the longitudinal axis (through the front to back), in radians.
        let roll: Float
        
        /// The x-coordinate of the camera's position.
        let x: Float
        
        /// The y-coordinate of the camera's position.
        let y: Float
        
        /// The z-coordinate of the camera's position.
        let z: Float
    }
    
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController: ViewController
    
    /// Reference to the observable data class `SceneData` containing scene's operational data.
    private var sceneData: SceneData
    
    /// Reference to the observable data class `SceneModelData` scene's model data.
    @ObservedObject private var sceneModelData: SceneModelData
    
    /// The main SceneKit scene which displays all 3D content.
    @State private var scene: SCNScene
    
    /// A SceneKit view embedded in SwiftUI for 3D rendering.
    @State private var sceneView: SceneView
    
    /// A node in the SceneKit scene that allows the camera to orbit around the scene content.
    @State private var cameraOrbit: SCNNode
    
    @Environment(\.colorScheme) var colorScheme
    
    /// Initializes the MeshRendererView by setting up the initial scene configuration including camera, lighting, and grid. Prepares the view for dynamic updates based on scene model data.
    public init(viewController: ViewController, sceneData:SceneData, sceneModelData: SceneModelData) {
        self.viewController = viewController
        self.sceneData = sceneData
        self.sceneModelData = sceneModelData
        
        let scene = SCNScene()
        scene.background.contents = UIColor.systemBackground
        
        let cameraNode = SCNNode()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 200)
        cameraNode.camera = SCNCamera()
        cameraNode.camera!.zNear = 0.1
        cameraNode.camera!.zFar = 10000
        
        let cameraOrbit = SCNNode()
        cameraOrbit.position = SCNVector3(x: 0, y: 0, z: 0)
        cameraOrbit.addChildNode(cameraNode)
        cameraOrbit.eulerAngles.x -= .pi / 4
        cameraOrbit.eulerAngles.y += 3 * (.pi / 2)
        scene.rootNode.addChildNode(cameraOrbit)
        self.scene = scene
        self.cameraOrbit = cameraOrbit
        self.sceneView = SceneView(scene: scene, options: [.autoenablesDefaultLighting, .allowsCameraControl])
        self.createGrid()
        
        self.changeScene()
    }
    
    /// Reacts to changes in the scene model and updates the SceneKit scene accordingly.
    public func changeScene(modelType: SceneModelData.SceneModelType? = nil) {
        if modelType != nil {
            self.sceneModelData.sceneModelType = modelType!
        }
        
        self.clearScene()
        
        switch self.sceneModelData.sceneModelType {
        case .alignment:
            self.sceneDisplayPointCloud()
        case .preview, .normal, .colorized:
            self.sceneDisplayModel()
        }
    }
    
    /// Represents the SwiftUI body of the MeshRendererView. Manages dynamic scene updates and user interactions.
    public var body: some View {
        self.sceneView
            .onChange(of: self.colorScheme) { _, newScheme in
                self.scene.background.contents = (newScheme == .dark) ? UIColor.black : .white
            }
            .onChange(of: self.sceneModelData.savedModels[.preview]) { _, _ in
                if self.sceneModelData.sceneModelType == .preview { self.changeScene() }
            }
            .onChange(of: self.sceneModelData.savedModels[.normal]) { _, _ in
                if self.sceneModelData.sceneModelType == .normal { self.changeScene() }
            }
            .onChange(of: self.sceneModelData.savedModels[.colorized]) { _, _ in
                if self.sceneModelData.sceneModelType == .colorized { self.changeScene() }
            }
            .onChange(of: self.sceneModelData.pointCloud.count) { _, _ in
                if self.sceneModelData.sceneModelType == .alignment { self.changeScene() }
            }
            .onChange(of: self.sceneModelData.alignmentCameras.count) { _, _ in
                if self.sceneModelData.sceneModelType == .alignment { self.changeScene() }
            }
            .onAppear { self.changeScene() }.onDisappear(perform: self.clearScene)
    }
    
    /// Configures the visual grid in the scene, which helps in orienting within the 3D space.
    private func createGrid() {
        // Create the grid plane
        let gridSize: CGFloat = 100.0
        
        let planeGeometry = SCNPlane(width: gridSize, height: gridSize)
        planeGeometry.firstMaterial?.diffuse.contents = UIColor(white: 0.5, alpha: 0.5)
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.eulerAngles = SCNVector3(-.pi / 2.0, 0.0, 0.0)
        planeNode.position = SCNVector3(0.0, 0.0, 0.0)
        self.scene.rootNode.addChildNode(planeNode)
    }
    
    /// Generates a coordinate system indicator for the scene, providing visual context for axis orientation.
    private func createXYZ(scale: Float) -> SCNNode {
        let grid = SCNNode()
        let gridSize: CGFloat = 100.0
        let gridLineWidth = CGFloat(0.15 * min(scale, 1))
        
        // Create the X-axis line
        let xLine = SCNCylinder(radius: gridLineWidth, height: gridSize / 20)
        xLine.firstMaterial?.diffuse.contents = UIColor(Color.red)
        let xAxisLine = SCNNode(geometry: xLine)
        grid.addChildNode(xAxisLine)
        
        // Create the Y-axis line
        let yLine = SCNCylinder(radius: gridLineWidth, height: gridSize / 20)
        yLine.firstMaterial?.diffuse.contents = UIColor(Color.green)
        let yAxisLine = SCNNode(geometry: yLine)
        yAxisLine.eulerAngles = SCNVector3(0.0, 0.0, .pi / 2)
        grid.addChildNode(yAxisLine)
        
        // Create the Z-axis line
        let zLine = SCNCylinder(radius: gridLineWidth, height: gridSize / 20)
        zLine.firstMaterial?.diffuse.contents = UIColor(Color.blue)
        let zAxisLine = SCNNode(geometry: zLine)
        zAxisLine.eulerAngles = SCNVector3(.pi / 2, 0.0, .pi / 2)
        grid.addChildNode(zAxisLine)
        return grid
    }
    
    /// Removes all non-permanent nodes from the scene to prepare for new content.
    private func clearScene() {
        self.scene.rootNode.childNodes.forEach { node in node.removeFromParentNode() }
        self.scene.rootNode.addChildNode(self.cameraOrbit)
        self.cameraOrbit.position = SCNVector3(x: 0, y: 0, z: 0)
        self.createGrid()
    }
    
    /// Displays a 3D model in the scene, loading it from a specified path.
    private func sceneDisplayModel() {
        let path = self.sceneModelData.savedModels[self.sceneModelData.sceneModelType]
        
        if path != nil {
            do {
                if let fileSize = try path!.getAttributesOfItem()[FileAttributeKey.size] as? Int64 {
                    if fileSize > 500000000 {
                        self.viewController.showSimpleAlert(title: "Error Rendering \(self.sceneModelData.sceneModelType.rawValue)", msg: Text("The file could not be rendered as it exceeded the maximum allowed size of 500MB. Please try running the reconstruction again if it was previously performed in RealityCapture."))
                        return
                    }
                }
            } catch {
                self.viewController.showSimpleAlert(title: "Error Rendering \(self.sceneModelData.sceneModelType.rawValue)", msg: Text("Model's file size for could not be retrieved."))
                return
            }
            
            // Start loading model on background thread
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.async {
                    self.sceneData.disableUIInteraction = true
                }
                let asset = MDLAsset(url: path!.getURL())
                asset.loadTextures()
                DispatchQueue.main.async {
                    let object = asset.object(at: 0) as! MDLMesh
                    let modelNode = SCNNode(mdlObject: object)
                    modelNode.eulerAngles = SCNVector3(x: 0, y: .pi, z: 0)
                    
                    for object in modelNode.geometry?.materials ?? [] {
                        object.emission.contents = UIColor.black
                    }
                    self.scene.rootNode.addChildNode(modelNode)
                    self.sceneData.disableUIInteraction = false
                }
            }
        }
    }
    
    /// Renders a point cloud in the scene, showing points and camera positions if available.
    private func sceneDisplayPointCloud() {
        let pointCloud = self.sceneModelData.pointCloud
        let cameras = self.sceneModelData.alignmentCameras
        if pointCloud.count > 0 || cameras.count > 0 {
            self.scene.rootNode.addChildNode(self.createXYZ(scale: self.sceneModelData.displayScale))
            
            if pointCloud.count > 0 {
                let vertexData = NSData(bytes: pointCloud, length: MemoryLayout<PointVertex>.size * pointCloud.count)
                let positionSource = SCNGeometrySource(data: vertexData as Data, semantic: SCNGeometrySource.Semantic.vertex, vectorCount: pointCloud.count, usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0, dataStride: MemoryLayout<PointVertex>.size)
                let colorSource = SCNGeometrySource(data: vertexData as Data, semantic: SCNGeometrySource.Semantic.color, vectorCount: pointCloud.count, usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: MemoryLayout<Float>.size, dataOffset: MemoryLayout<Float>.size * 3, dataStride: MemoryLayout<PointVertex>.size)
                let elements = SCNGeometryElement(data: nil, primitiveType: .point, primitiveCount: pointCloud.count, bytesPerIndex: MemoryLayout<Int>.size)
                let pointCloud = SCNGeometry(sources: [positionSource, colorSource], elements: [elements])
                let material = SCNMaterial()
                material.lightingModel = .constant
                pointCloud.materials = [material]
                let pcNode = SCNNode(geometry: pointCloud)
                self.scene.rootNode.addChildNode(pcNode)
            }
            if cameras.count > 0 {
                for camera in cameras {
                    let cam = SCNSphere(radius: 0.2)
                    cam.firstMaterial?.diffuse.contents = UIColor(Color.green)
                    
                    let camNode = SCNNode(geometry: cam)
                    camNode.position = SCNVector3(x: camera.y, y: camera.z, z: camera.x)
                    self.scene.rootNode.addChildNode(camNode)
                }
            }
        }
    }
}
