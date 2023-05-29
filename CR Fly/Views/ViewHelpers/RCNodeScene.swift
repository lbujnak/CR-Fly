import SwiftUI
import SceneKit
import SceneKit.ModelIO

struct RCNodeScene: View {
    
    static let sharedAlignment = RCNodeScene()
    static let sharedPreviewModel = RCNodeScene()
    static let sharedModel = RCNodeScene()
    
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
        self.cameraOrbit.addChildNode(self.cameraNode)
        self.cameraOrbit.eulerAngles.x -= .pi/4
        self.cameraOrbit.eulerAngles.y -= (.pi/4)*3
        
        self.sceneView = SceneView(scene: self.scene, options: [.autoenablesDefaultLighting,.allowsCameraControl])
        self.clearScene()
    }
    
    var body: some View { self.sceneView }

    func addModel(path: URL){
        self.clearScene()
        
        let asset = MDLAsset(url: path)
        let object = asset.object(at: 0) as! MDLMesh
        let modelNode = SCNNode(mdlObject: object)
        modelNode.eulerAngles = SCNVector3(x: -.pi/2, y: 0, z: 0)
        self.scene.rootNode.addChildNode(modelNode)
    }
    
    func clearScene(){
        scene.rootNode.childNodes.forEach { node in node.removeFromParentNode() }
        self.scene.rootNode.addChildNode(self.cameraOrbit)
        self.scene.rootNode.addChildNode(self.createGrid())
    }
    
    func addPointToScene(x: Float, y: Float, z: Float, r: String, g: String, b: String, scale: Float) {
        let sphere = SCNSphere(radius: (0.25*CGFloat(scale)))
        
        let red = CGFloat(Float(r)!) / 255.0
        let green = CGFloat(Float(g)!) / 255.0
        let blue = CGFloat(Float(b)!) / 255.0
        
        sphere.firstMaterial?.diffuse.contents = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
            
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(x: y*scale, y: z*scale, z: x*scale)
        self.scene.rootNode.addChildNode(sphereNode)
    }
    
    func addCameraToScene(yaw: Float, pitch: Float, roll: Float, x: Float, y: Float, z: Float, scale: Float){
        let rectangle = SCNBox(width: CGFloat(scale), height: CGFloat(scale), length: 0.1, chamferRadius: 0)
        
        rectangle.firstMaterial?.diffuse.contents = UIColor(Color.green)
            
        let rectangleNode = SCNNode(geometry: rectangle)
        rectangleNode.position = SCNVector3(x: y*scale, y: z*scale, z: x*scale)
        rectangleNode.eulerAngles.y = -(yaw * .pi / 180.0)
        rectangleNode.eulerAngles.z = (pitch * .pi / 180.0)
        rectangleNode.eulerAngles.x = (roll * .pi / 180.0) + .pi/2
        self.scene.rootNode.addChildNode(rectangleNode)
    }
    
    func createGrid() -> SCNNode {
        let grid = SCNNode()
        let gridSize: CGFloat = 150.0
        let gridSpacing: CGFloat = 0.5
        let gridLineWidth: CGFloat = 0.25
        
        // Create the X-axis line
        let xLine = SCNCylinder(radius: gridLineWidth, height: gridSize/10)
        xLine.firstMaterial?.diffuse.contents = UIColor(Color.green)
        let xAxisLine = SCNNode(geometry: xLine)
        xAxisLine.eulerAngles = SCNVector3(0.0, 0.0, .pi/2)
        xAxisLine.position = SCNVector3(-gridSpacing/2, 0.0, 0.0)
        grid.addChildNode(xAxisLine)
        
        // Create the Y-axis line
        let yLine = SCNCylinder(radius: gridLineWidth, height: gridSize/10)
        yLine.firstMaterial?.diffuse.contents = UIColor(Color.red)
        let yAxisLine = SCNNode(geometry: yLine)
        yAxisLine.position = SCNVector3(0.0, -gridSpacing/2, 0.0)
        grid.addChildNode(yAxisLine)
        
        // Create the Z-axis line
        let zLine = SCNCylinder(radius: gridLineWidth, height: gridSize/10)
        zLine.firstMaterial?.diffuse.contents = UIColor(Color.blue)
        let zAxisLine = SCNNode(geometry: zLine)
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
