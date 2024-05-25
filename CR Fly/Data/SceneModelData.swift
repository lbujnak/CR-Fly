import Foundation

/// `SceneModelData` is an observable data model class that encapsulates the state of various 3D models and scene representations in an application. It tracks the current type of model displayed, point cloud data, camera positions, and the scale at which models are displayed, making it essential for managing and rendering 3D content dynamically.
public class SceneModelData: ObservableObject {
    /// `SceneModelType` is an enumeration within the `SceneModelData` class that categorizes the types of 3D models managed in the application. It is used to specify and switch between different rendering modes and model details, supporting various visualization needs in 3D scene handling.
    public enum SceneModelType: String, CaseIterable {
        /// Represents a model that is used for aligning or positioning other elements within the scene. Typically involves simpler, geometry-focused visuals.
        case alignment = "Alignment"
        
        /// Indicates a model that provides a preliminary view of the scene, often used for initial assessments or reviews before final processing.
        case preview = "Preview Model"
        
        /// Denotes the standard rendering of the model, usually without advanced texturing or colorization, focusing on the structural aspects.
        case normal = "Normal Model"
        
        /// Refers to models that include colorized textures, offering a more detailed and visually enriched representation of the scene.
        case colorized = "Colorized Texture"
    }
    
    /// An enum `SceneModelType` that defines the type of model currently being managed or displayed. It helps in switching between different model views like alignment, preview, normal, or colorized textures.
    @Published var sceneModelType: SceneModelType = .alignment
    
    /// An array of `MeshRendererView.PointVertex`, representing the vertex data for point clouds used in 3D modeling and rendering.
    @Published var pointCloud: [MeshRendererView.PointVertex] = []
    
    /// An array of `MeshRendererView.CameraVertex`, which stores the positions and orientations of cameras used in the scene, typically for alignment purposes.
    @Published var alignmentCameras: [MeshRendererView.CameraVertex] = []
    
    /// A dictionary mapping `SceneModelType` to URLs where model data files are stored, allowing for quick access and management of different 3D model files.
    @Published var savedModels: [SceneModelType: DocURL] = [:]
    
    /// A float that determines the scale at which models are displayed, influencing the zoom level and granularity of models in the rendering view.
    @Published var displayScale: Float = 1
}
