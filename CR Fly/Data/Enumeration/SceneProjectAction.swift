import Foundation

/// `SceneProjectAction` defines a set of actions applicable to a project within an application that handles scene management or similar tasks. This enum facilitates clear and concise representation of operations that can be performed on a project, allowing easier management of project states and interactions through a unified interface.
public enum SceneProjectAction {
    /// Refreshes the current project, reloading its data and view components.
    case refreshProject
    
    /// Represents an action to change the current project. Requires a string value that specifies the new project identifier.
    case changeProjectTo(String)
    
    /// Saves the current state of the project to persistent storage.
    case saveProject
    
    /// Closes the current project, cleaning up resources and potentially prompting the user to save changes.
    case closeProject
    
    /// Permanently deletes the project, removing all associated data and files.
    case deleteProject
}
