import SwiftUI
import SceneKit
import SceneKit.ModelIO
import Foundation

struct PointCloudVertex {
    var x: Float, y: Float, z: Float
    let r: Float, g: Float, b: Float
}

struct RCNodeScene: View {
    
    static var sharedAlignment = RCNodeScene()
    static var sharedModels = [
        ProjectManagementService.modelType.preview: RCNodeScene(),
        ProjectManagementService.modelType.normal: RCNodeScene(),
        ProjectManagementService.modelType.colorized: RCNodeScene()
    ]
    
    let userDisplayScale = true
    
    private var hasXYZ = false
    private let scene : SCNScene
    private let cameraNode : SCNNode
    private let cameraOrbit : SCNNode
    private let sceneView : SceneView
    
    init(){
        self.scene = SCNScene()
        self.scene.background.contents = UIColor.black
        
        self.cameraNode = SCNNode()
        self.cameraNode.position = SCNVector3(x:0,y: 0,z:150)
        self.cameraNode.camera = SCNCamera()
        self.cameraNode.camera!.usesOrthographicProjection = true
        self.cameraNode.camera!.orthographicScale = 150
        self.cameraNode.camera!.zNear = 0
        self.cameraNode.camera!.zFar = 200
        
        self.cameraOrbit = SCNNode()
        self.cameraOrbit.addChildNode(self.cameraNode)
        self.cameraOrbit.eulerAngles.x -= .pi/4
        self.cameraOrbit.eulerAngles.y -= (.pi/4)*3
        
        self.sceneView = SceneView(scene: self.scene, options: [.autoenablesDefaultLighting,.allowsCameraControl])
        self.clearScene()
    }
    
    var body: some View { self.sceneView }

    mutating func addModel(path: URL){
        self.clearScene()
        self.scene.rootNode.addChildNode(self.createXYZ(scale: 1))
        
        let asset = MDLAsset(url: path)
        let object = asset.object(at: 0) as! MDLMesh
        let modelNode = SCNNode(mdlObject: object)
        modelNode.eulerAngles = SCNVector3(x: -.pi/2, y: 0, z: 0)
        self.scene.rootNode.addChildNode(modelNode)
    }
    
    mutating func clearScene(){
        self.hasXYZ = false
        scene.rootNode.childNodes.forEach { node in node.removeFromParentNode() }
        self.scene.rootNode.addChildNode(self.cameraOrbit)
        self.createGrid()
    }
    
    func addPointsToScene(cloud: inout [PointCloudVertex], scale: Float) {
        let vertexData = NSData(bytes: &cloud, length: MemoryLayout<PointCloudVertex>.size*cloud.count)
        let positionSource = SCNGeometrySource(data: vertexData as Data, semantic: SCNGeometrySource.Semantic.vertex, vectorCount: cloud.count, usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0, dataStride: MemoryLayout<PointCloudVertex>.size)
        let colorSource = SCNGeometrySource(data: vertexData as Data, semantic: SCNGeometrySource.Semantic.color, vectorCount: cloud.count, usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: MemoryLayout<Float>.size, dataOffset: MemoryLayout<Float>.size*3, dataStride: MemoryLayout<PointCloudVertex>.size)
        let elements = SCNGeometryElement(data: nil, primitiveType: .point, primitiveCount: cloud.count, bytesPerIndex: MemoryLayout<Int>.size)
        let pointCloud = SCNGeometry(sources: [positionSource, colorSource], elements: [elements])
        let material = SCNMaterial()
        material.lightingModel = .constant
        pointCloud.materials = [material]
        let pcNode = SCNNode(geometry: pointCloud)
        self.scene.rootNode.addChildNode(pcNode)
    }
    
    mutating func addCameraToScene(yaw: Float, pitch: Float, roll: Float, x: Float, y: Float, z: Float, scale: Float){
        if(!self.hasXYZ){
            self.scene.rootNode.addChildNode(self.createXYZ(scale: scale))
            self.hasXYZ = true
        }
        
        let cam = SCNSphere(radius: (0.2*CGFloat(scale)))
        cam.firstMaterial?.diffuse.contents = UIColor(Color.green)
            
        let camNode = SCNNode(geometry: cam)
        camNode.position = SCNVector3(x: y, y: z, z: x)
        self.scene.rootNode.addChildNode(camNode)
    }
    
    func createGrid() {
        // Create the grid plane
        let gridSize: CGFloat = 100.0
        
        let planeGeometry = SCNPlane(width: gridSize, height: gridSize)
        planeGeometry.firstMaterial?.diffuse.contents = UIColor(white: 0.5, alpha: 0.5)
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.eulerAngles = SCNVector3(-.pi/2.0, 0.0, 0.0)
        planeNode.position = SCNVector3(0.0, 0.0, 0.0)
        self.scene.rootNode.addChildNode(planeNode)
    }
    
    func createXYZ(scale: Float) -> SCNNode {
        let grid = SCNNode()
        let gridSize: CGFloat = 100.0
        let gridLineWidth: CGFloat = self.userDisplayScale ? CGFloat(0.15*scale) : CGFloat(0.15)
        
        // Create the X-axis line
        let xLine = SCNCylinder(radius: gridLineWidth, height: gridSize/20)
        xLine.firstMaterial?.diffuse.contents = UIColor(Color.red)
        let xAxisLine = SCNNode(geometry: xLine)
        grid.addChildNode(xAxisLine)
        
        // Create the Y-axis line
        let yLine = SCNCylinder(radius: gridLineWidth, height: gridSize/20)
        yLine.firstMaterial?.diffuse.contents = UIColor(Color.green)
        let yAxisLine = SCNNode(geometry: yLine)
        yAxisLine.eulerAngles = SCNVector3(0.0, 0.0, .pi/2)
        grid.addChildNode(yAxisLine)
        
        // Create the Z-axis line
        let zLine = SCNCylinder(radius: gridLineWidth, height: gridSize/20)
        zLine.firstMaterial?.diffuse.contents = UIColor(Color.blue)
        let zAxisLine = SCNNode(geometry: zLine)
        zAxisLine.eulerAngles = SCNVector3(.pi/2, 0.0, .pi/2)
        grid.addChildNode(zAxisLine)
        return grid
    }
}
