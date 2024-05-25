import SwiftUI

/// `MeshWorkspaceView` serves as the primary interface for interacting with and managing 3D mesh data and associated projects. It integrates various UI components to facilitate operations such as project creation, modification, and visualization.
public struct MeshWorkspaceView: AppearableView {
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    private let viewController: ViewController
    
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    private let sceneController: SceneController
    
    /// Reference to the observable data class `SceneData` containing scene's operational data.
    @ObservedObject private var sceneData: SceneData
    
    /// Reference to the observable data class `SceneModelData` scene's model data.
    @ObservedObject private var sceneModelData: SceneModelData
    
    /// A `MeshRendererView` subview that renders the 3D mesh content.
    @State private var meshRendererView: MeshRendererView
    
    /// A boolean flag that manages the visibility of the information panel which displays project details and controls.
    @State private var infoBar = false
    
    /// A string that holds the name for a new project being created by the user.
    @State private var newProjectName = ""
    
    /// A boolean flag that manages the display of alerts for creating new projects.
    @State private var newProjectAlert = false
    
    /// A boolean flag that manages the display of alerts for confirming deletions of projects.
    @State private var deleteConfirmAlert = false
    
    /// Initializes `MeshWorkspaceView`.
    public init(viewController: ViewController, sceneController: SceneController) {
        self.viewController = viewController
        self.sceneController = sceneController
        self.sceneData = sceneController.sceneData
        self.sceneModelData = sceneController.sceneModelData
        self.meshRendererView = MeshRendererView(viewController: viewController, sceneData: sceneController.sceneData, sceneModelData: sceneController.sceneModelData)
    }
    
    /// Called when the object becomes visible within the user interface.
    public func appear() { }
    
    /// Called when the object is no longer visible within the user interface.
    public func disappear() { }
    
    /// Constructs the view hierarchy for the `MeshWorkspaceView`, organizing the layout into a stack of control bars and the 3D mesh rendering view.
    public var body: some View {
        ZStack {
            self.meshRendererView
            
            VStack(spacing: 10) {
                // MARK: TopBar
                HStack(spacing: 30) {
                    Button("←") {
                        self.viewController.displayPreviousView()
                    }.foregroundColor(.primary).font(.largeTitle)
                    
                    Spacer()
                    HStack {
                        if !self.sceneData.sceneConnected {
                            Text("Missing connection - not connected to RC Node.").font(.subheadline).foregroundColor(.red)
                        } else if self.sceneData.sceneConnLost {
                            Text("Missing connection - lost connection to RC Node.").font(.subheadline).foregroundColor(.red)
                        } else if !self.sceneData.openedProject.loaded {
                            Text("Missing project - create or open a project.").font(.subheadline).foregroundColor(.red)
                        } else if self.sceneData.exportedModelsURL == nil {
                            Text("Problem creating shared directory for 3D models - unable to preview/export.").font(.subheadline).foregroundColor(.red)
                        }
                    }
                    Spacer()
                    
                    if !self.sceneData.sceneConnected {
                        Button("Connect") {
                            self.viewController.displayView(type: .scannerView, addPreviousToHistory: true)
                        }.foregroundColor(.blue)
                    } else {
                        Image(systemName: "info.circle").foregroundColor(self.infoBar ? .secondary : .primary).font(.title2).padding([.horizontal], -40)
                            .onTapGesture {
                                if !self.infoBar {
                                    self.sceneController.manageProject(action: .refreshProject)
                                }
                                self.infoBar.toggle()
                            }
                    }
                }.padding(.top, 5)
                
                // Project info
                if self.infoBar, self.sceneData.sceneConnected {
                    self.createInfoPanel()
                }
                Spacer()
                
                // Bottom bar
                if self.sceneData.sceneConnected { self.createBottomBar() }
            }
            
            if self.sceneData.openedProject.loaded {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "plus.circle.fill").font(.custom("AddImg", size: 40)).foregroundColor(.primary).onTapGesture {
                            self.viewController.displayView(type: .albumView, addPreviousToHistory: true)
                        }
                        Spacer()
                    }
                }.padding([.bottom], 60).padding([.leading], 20)
            }
            
            // Display ProgressView, when interaction should be disabled
            if self.sceneData.disableUIInteraction {
                Color.gray.opacity(0.7).edgesIgnoringSafeArea(.all)
                ProgressView().scaleEffect(x: 2, y: 2, anchor: .center)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
    }
    
    /// Constructs an information panel that provides detailed project information and management options. This panel includes interactive elements for project administration such as creating, saving, closing, and deleting projects.
    private func createInfoPanel() -> some View {
        return HStack {
            Spacer()
            VStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Project Name:").bold()
                        if !self.sceneData.openedProject.loaded {
                            Menu {
                                ForEach(self.sceneData.projectList.sorted { $0.1 > $1.1 }, id: \.key) { item in
                                    Button(action: {
                                        self.sceneController.manageProject(action: .changeProjectTo(item.0))
                                    }, label: {
                                        Text("\(self.sceneData.openedProject.name == item.0 ? "✓ " : "")\(item.0)")
                                    }).tag(item.0)
                                    
                                }
                            } label: {
                                HStack {
                                    Text(self.sceneData.openedProject.name)
                                }.frame(width: 150, height: 20, alignment: .leading)
                            }.frame(width: 150).onTapGesture {
                                self.sceneController.manageProject(action: .refreshProject)
                            }
                        } else {
                            HStack {
                                Text(self.sceneData.openedProject.name)
                            }.frame(width: 150, height: 20, alignment: .leading)
                        }
                        
                        let cannotRefresh = !self.sceneData.sceneConnected || self.sceneData.openedProject.waitingOnTask.count != 0 || self.sceneData.openedProject.projectUpdateState != nil
                        
                        Image(systemName: "arrow.clockwise").foregroundColor(cannotRefresh ? .secondary : .primary).onTapGesture {
                            self.sceneController.manageProject(action: .refreshProject)
                        }.disabled(cannotRefresh).padding([.top, .trailing], 5)
                    }
                    
                    let project = self.sceneData.openedProject
                    Text("ImageCount: \(project.imageCnt != nil ? String(project.imageCnt!) : "...")")
                    Text("ComponentCount: \(project.componentCnt != nil ? String(project.componentCnt!) : "...")")
                    Text("PointCount: \(project.pointCnt != nil ? String(project.pointCnt!) : "...")")
                    Text("CameraCount: \(project.cameraCnt != nil ? String(project.cameraCnt!) : "...")")
                    
                    AnyView(self.sceneController.customProjectInfo(project: project))
                    
                    let disb = !project.loaded || self.sceneData.disableUIInteraction
                    HStack {
                        // Create Project Btn
                        Button {
                            self.newProjectAlert = true
                        } label: {
                            Text("New").foregroundColor(project.loaded ? .secondary : .primary).padding([.vertical], 5).padding([.horizontal], 8)
                        }.alert("Connect", isPresented: self.$newProjectAlert, actions: {
                            TextField("Project Name", text: self.$newProjectName)
                            Button("Create") {
                                self.sceneController.manageProject(action: .changeProjectTo(self.newProjectName))
                                self.newProjectName = ""
                            }
                            Button("Cancel") { self.newProjectName = "" }
                        }, message: {
                            Text("Please enter new project's name.")
                        }).background(Color.gray.opacity(project.loaded ? 0.5 : 1)).cornerRadius(10).disabled(project.loaded)
                        
                        // Save Project Btn
                        Button {
                            self.sceneController.manageProject(action: .saveProject)
                        } label: {
                            Text("Save").foregroundColor(disb ? .secondary : .primary).padding([.vertical], 5).padding([.horizontal], 8)
                        }.background(.secondary.opacity(disb ? 0.5 : 1)).cornerRadius(10).disabled(disb)
                        
                        // Close project Btn
                        Button {
                            self.sceneController.manageProject(action: .closeProject)
                        } label: {
                            Text("Close").foregroundColor(disb ? .secondary : .primary).padding([.vertical], 5).padding([.horizontal], 8)
                        }.background(.secondary.opacity(disb ? 0.5 : 1)).cornerRadius(10).disabled(disb)
                        
                        // Delete project Btn
                        Button {
                            self.deleteConfirmAlert = true
                        } label: {
                            Text("Delete").foregroundColor(disb ? .secondary : .primary).padding([.vertical], 5).padding([.horizontal], 8)
                        }.alert("Project deletion", isPresented: self.$deleteConfirmAlert, actions: {
                            Button("Delete") { self.sceneController.manageProject(action: .deleteProject) }
                            Button("Cancel") { }
                        }, message: {
                            Text("This action cannot be undone. Are you sure about deleting selected project?")
                        }).background(.secondary.opacity(disb ? 0.5 : 1)).cornerRadius(10).disabled(disb)
                    }
                    Button {
                        self.infoBar.toggle()
                        self.sceneController.disconnectScene()
                    } label: {
                        Text("Disconnect").foregroundColor(self.sceneData.openedProject.loaded ? .secondary : .primary).padding([.vertical], 5).padding([.horizontal], 8)
                    }.background(.secondary.opacity(self.sceneData.openedProject.loaded ? 0.5 : 1)).cornerRadius(10).disabled(self.sceneData.openedProject.loaded)
                }.padding([.vertical, .horizontal], 10).foregroundColor(.primary)
            }.background(.secondary.opacity(0.3)).cornerRadius(15).padding([.vertical], -20).padding([.horizontal])
        }
    }
    
    /// Creates a bottom bar that contains buttons for switching between different visualization modes of the 3D scene, such as alignment, preview, normal, and colorized views. Each button is enabled or disabled based on the project's data availability and current state.
    private func createBottomBar() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            let disab = self.sceneData.openedProject.pointCnt == nil || self.sceneData.openedProject.pointCnt == 0 || self.sceneData.exportedModelsURL == nil || self.sceneData.openedProject.projectUpdateState != nil
            HStack(spacing: 0) {
                self.createBottomBarButton(modelType: SceneModelData.SceneModelType.alignment, disabled: disab)
                self.createBottomBarButton(modelType: SceneModelData.SceneModelType.preview, disabled: disab)
                self.createBottomBarButton(modelType: SceneModelData.SceneModelType.normal, disabled: disab)
                self.createBottomBarButton(modelType: SceneModelData.SceneModelType.colorized, disabled: disab)
                
                Spacer()
                
                let disabRefresh = disab || self.sceneData.openedProject.waitingOnTask.count != 0
                
                Image(systemName: "arrow.clockwise").onTapGesture {
                    self.sceneController.refreshModel(modelType: self.sceneModelData.sceneModelType)
                }.padding([.horizontal], -40).foregroundColor(disabRefresh ? .secondary : .primary).disabled(disabRefresh)
            }.background(Color(UIColor.secondarySystemBackground).opacity(0.3).ignoresSafeArea())
            
            HStack {
                Spacer()
            }.frame(height: 5).background(Color(UIColor.secondarySystemBackground))
        }
    }
    
    /// Creates an individual button for the bottom bar in the MeshWorkspaceView, used to switch between different 3D scene visualizations.
    private func createBottomBarButton(modelType: SceneModelData.SceneModelType, disabled: Bool) -> some View {
        let isModelActive = self.sceneModelData.sceneModelType == modelType
        
        return Button {
            self.meshRendererView.changeScene(modelType: modelType)
        } label: {
            Text(modelType.rawValue).foregroundColor(isModelActive ? .primary : .secondary)
                .padding([.vertical], 8).padding([.horizontal], 15)
        }.background(Color(UIColor.secondarySystemBackground).opacity(isModelActive ? 1 : 0.3)).disabled(isModelActive || disabled)
    }
}
