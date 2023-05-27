import SwiftUI
import SceneKit

struct RCNodeScene: View {
    
    static let shared = RCNodeScene()
    
    private let scene : SCNScene
    private let cameraNode : SCNNode
    private let cameraOrbit : SCNNode
    private let sceneView : SceneView
    
    init(){
        self.scene = SCNScene()
        self.scene.background.contents = UIColor.black
        
        self.cameraNode = SCNNode()
        self.cameraNode.position = SCNVector3(x:0,y: 0,z:100)
        self.cameraNode.camera = SCNCamera()
        self.cameraNode.camera!.usesOrthographicProjection = true
        self.cameraNode.camera!.orthographicScale = 100
        self.cameraNode.camera!.zNear = 0
        self.cameraNode.camera!.zFar = 200
        
        self.cameraOrbit = SCNNode()
        self.cameraOrbit.addChildNode(cameraNode)
        self.scene.rootNode.addChildNode(cameraOrbit)
        self.cameraOrbit.eulerAngles.x -= .pi/4
        self.cameraOrbit.eulerAngles.y -= (.pi/4)*3
        
        
        self.sceneView = SceneView(scene: self.scene, options: [.autoenablesDefaultLighting,.allowsCameraControl])
        self.addModelsToScene()
    }
    
    var body: some View {
        self.sceneView
    }
    
    
    func addModelsToScene() {
        let sphereNode1 = SCNNode(geometry: SCNSphere(radius: 1))
        let sphereNode11 = SCNNode(geometry: SCNSphere(radius: 1))
        let sphereNode2 = SCNNode(geometry: SCNSphere(radius: 1))
        let sphereNode22 = SCNNode(geometry: SCNSphere(radius: 1))
        let sphereNode3 = SCNNode(geometry: SCNSphere(radius: 1))
        let sphereNode33 = SCNNode(geometry: SCNSphere(radius: 1))
        let sphereNode4 = SCNNode(geometry: SCNSphere(radius: 1))
        let sphereNode44 = SCNNode(geometry: SCNSphere(radius: 1))
        
        sphereNode1.position = SCNVector3(x: -10, y: -10, z: 10)
        sphereNode11.position = SCNVector3(x: 10, y: -10, z: 10)
        sphereNode2.position = SCNVector3(x: -10, y: 10, z: 10)
        sphereNode22.position = SCNVector3(x: 10, y: 10, z: 10)
        sphereNode3.position = SCNVector3(x: -10, y: -10, z: -10)
        sphereNode33.position = SCNVector3(x: 10, y: -10, z: -10)
        sphereNode4.position = SCNVector3(x: -10, y: 10, z: -10)
        sphereNode44.position = SCNVector3(x: 10, y: 10, z: -10)
        
        //scene.rootNode.addChildNode(lightNode)
        self.scene.rootNode.addChildNode(sphereNode1)
        self.scene.rootNode.addChildNode(sphereNode11)
        self.scene.rootNode.addChildNode(sphereNode2)
        self.scene.rootNode.addChildNode(sphereNode22)
        self.scene.rootNode.addChildNode(sphereNode3)
        self.scene.rootNode.addChildNode(sphereNode33)
        self.scene.rootNode.addChildNode(sphereNode4)
        self.scene.rootNode.addChildNode(sphereNode44)
        self.scene.rootNode.addChildNode(self.createGrid())
    }
    
    func createGrid() -> SCNNode {
        let grid = SCNNode()
        let gridSize: CGFloat = 100.0
        let gridSpacing: CGFloat = 0.5
        let gridLineWidth: CGFloat = 0.5
        
        // Create the X-axis line
        let xAxisLine = SCNNode(geometry: SCNCylinder(radius: gridLineWidth, height: gridSize))
        xAxisLine.position = SCNVector3(0.0, -gridSpacing/2, 0.0)
        grid.addChildNode(xAxisLine)
        
        // Create the Y-axis line
        let yAxisLine = SCNNode(geometry: SCNCylinder(radius: gridLineWidth, height: gridSize))
        yAxisLine.eulerAngles = SCNVector3(0.0, 0.0, .pi/2)
        yAxisLine.position = SCNVector3(-gridSpacing/2, 0.0, 0.0)
        grid.addChildNode(yAxisLine)
        
        // Create the Z-axis line
        let zAxisLine = SCNNode(geometry: SCNCylinder(radius: gridLineWidth, height: gridSize))
        zAxisLine.eulerAngles = SCNVector3(.pi/2, 0.0, .pi/2)
        zAxisLine.position = SCNVector3(0.0, 0.0, -gridSpacing / 2.0)
        grid.addChildNode(zAxisLine)
        
        // Create the grid plane
        let planeGeometry = SCNPlane(width: gridSize, height: gridSize)
        planeGeometry.firstMaterial?.diffuse.contents = UIColor(white: 0.5, alpha: 0.5)
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.eulerAngles = SCNVector3(-.pi/2.0, 0.0, 0.0)
        planeNode.position = SCNVector3(0.0, 0.0, 0.0)
        grid.addChildNode(planeNode)
        
        return grid
    }
}
