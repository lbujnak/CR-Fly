import SwiftUI

/// `AppWrapperView` functions as a dynamic container within the application, managing and responding to changes in media and project status. It provides UI components that react to these statuses by displaying relevant information and controls.
public struct AppWrapperView: View {
    /// `StatusBarState` defines the possible states for the status bar visibility within the `AppWrapperView`. This enum helps manage the UI logic for displaying status information related to ongoing operations like media downloads or uploads and project updates.
    public enum StatusBarState {
        /// The status bar is temporarily hidden but can be shown based on certain conditions or user interaction.
        case hidden
        /// The status bar is actively displayed, showing current operations and statuses.
        case showing
    }
    
    /// Reference to the `ViewController` responsible for managing navigation, presentation of different views within the application and displaying errors.
    @ObservedObject private var viewController: ViewController
    
    /// Reference to an instance of `DroneController` that facilitates communication and control of the drone.
    private let droneController: DroneController
    
    /// Reference to an instance of `SceneController` that manages broader scene-related operations.
    private let sceneController: SceneController
    
    /// Reference to the observable data class `DroneData` containing drone's operational data.
    @ObservedObject private var droneData: DroneData
    
    /// Reference to the observable data class `SceneData` containing scene's operational data.
    @ObservedObject private var sceneData: SceneData
    
    /// Variable that track of the current visibility state of the status bar, managed by the `StatusBarState` enum. It starts as `disabled` and changes based on the application's status such as media operations or user interactions.
    @State private var barState: StatusBarState = .showing
    
    /// Initializes the `AppWrapperView`.
    public init(viewController: ViewController, droneController: DroneController = CRFly.shared.droneController, sceneController: SceneController = CRFly.shared.sceneController) {
        self.viewController = viewController
        self.droneController = droneController
        self.sceneController = sceneController
        self.droneData = droneController.droneData
        self.sceneData = sceneController.sceneData
    }
    
    /// Constructs the primary container for the application's user interface, dynamically adjusting the visibility of a status bar based on the ongoing media or project operations.
    public var body: some View {
        ZStack {
            AnyView(self.viewController.currentView.1)
            
            if self.droneData.mediaDownloadState != nil || self.sceneData.mediaUploadState != nil ||
                self.sceneData.openedProject.projectUpdateState != nil || !self.sceneData.openedProject.waitingOnTask.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        HStack(spacing: 0) {
                            if self.barState == .showing {
                                VStack(alignment: .leading, spacing: 10) {
                                    if self.sceneData.openedProject.projectUpdateState != nil {
                                        self.projectUpdateStatus()
                                    }
                                    if !self.sceneData.openedProject.waitingOnTask.isEmpty {
                                        self.projectDisplayTasks()
                                    }
                                    if self.droneData.mediaDownloadState != nil {
                                        self.mediaDownloadStatus()
                                    }
                                    if self.sceneData.mediaUploadState != nil {
                                        self.mediaUploadStatus()
                                    }
                                }.padding(.all, 10)
                            }
                            
                            Button(action: {
                                withAnimation {
                                    self.barState = (self.barState == .showing) ? .hidden : .showing
                                }
                            }, label: {
                                Image(systemName: "chevron.compact." + (self.barState == .showing ? "left" : "right"))
                                    .foregroundColor(.primary).font(.largeTitle)
                            }).frame(width: 40, height: 60)
                        }.background(Color(UIColor.secondarySystemBackground).opacity(0.7)).cornerRadius(10)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }.alert(self.viewController.alertErrors.first?.0 ?? "Something unexpected happened...",
                isPresented: self.$viewController.showAlertError,
                actions: {
            if let firstError = self.viewController.alertErrors.first {
                ForEach(firstError.2.indices, id: \.self) { index in
                    Button(firstError.2[index].label) {
                        firstError.2[index].action()
                        self.viewController.clearAlertError()
                    }
                }
            }
        },message: {
            if let firstError = self.viewController.alertErrors.first {
                firstError.1
            } else {
                Text("Unknown error")
            }
        }).onChange(of: self.viewController.showAlertError, {(_,new) in
            if !new, !self.viewController.alertErrors.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    self.viewController.showAlertError = true
                }
            }
        })
    }
    
    /// Provides a view that displays the current status of a project update, including descriptive text.
    private func projectUpdateStatus() -> some View {
        VStack(alignment: .leading) {
            Text("Updating project '\(self.sceneData.openedProject.name)':").font(.caption).frame(width: 360, alignment: .leading)
            HStack {
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .primary)).scaledToFit()
                Text("\(self.sceneData.openedProject.projectUpdateState!.description)")
                    .foregroundColor(.primary).font(.caption).padding(.leading, 10)
            }.frame(width: 320, height: 30, alignment: .leading).padding(.leading, 20)
        }
    }
    
    /// Displays a list of ongoing tasks associated with a project, showing a progress and task descriptions.
    private func projectDisplayTasks() -> some View {
        var taskDescriptionAmount: [String: Int] = [:]
        var displayProgressFor = ""
        for (_, val) in self.sceneData.openedProject.waitingOnTask {
            let currAmount = taskDescriptionAmount[val.1.taskDescription] ?? 0
            taskDescriptionAmount[val.1.taskDescription] = currAmount + 1
            
            if val.1.taskState == "started" {
                displayProgressFor = val.1.taskDescription
            }
        }
        
        return VStack(alignment: .leading) {
            Text("Tasks in project '\(self.sceneData.openedProject.name)':").font(.caption).frame(width: 360, alignment: .leading)
            HStack {
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .primary)).scaledToFit()
                VStack(alignment: .leading) {
                    if(displayProgressFor != "") {
                        Text("\(Int(Float(self.sceneData.openedProject.progress ?? 0)*100))% \(displayProgressFor) (\(taskDescriptionAmount[displayProgressFor]!)x)")
                    }
                    
                    ForEach(taskDescriptionAmount.sorted(by: { $0.key.count < $1.key.count }).map(\.key), id: \.self) { key in
                        if(key != displayProgressFor) {
                            Text("\(key) (\(taskDescriptionAmount[key]!)x)")
                        }
                    }
                }.padding(.leading, 10)
            }.foregroundColor(.primary).font(.caption).frame(width: 320, alignment: .leading).padding(.leading, 20)
        }.frame(minHeight: 30)
    }
    
    /// Generates a view detailing the status of media downloads from a drone, including download progress, speed, and controls to pause or resume the download.
    private func mediaDownloadStatus() -> some View {
        let downloadState = self.droneData.mediaDownloadState!
        var perc = Float(downloadState.transferedBytes) / Float(downloadState.totalBytes)
        
        if perc.isInfinite || perc.isNaN {
            perc = 0
        }
        
        return VStack(alignment: .leading) {
            Text("Downloading files from the drone to this device:").font(.caption)
            HStack {
                if downloadState.transferForcePaused {
                    Text(String(format: "%d%% | Preparing download (%d/%d) files", Int(perc * 100), downloadState.transferedMedia, downloadState.totalMedia)).foregroundColor(.red).font(.caption).frame(width: 265, alignment: .leading)
                } else if downloadState.transferPaused {
                    Text(String(format: "%d%% | Paused download of (%d/%d) files", Int(perc * 100), downloadState.transferedMedia, downloadState.totalMedia)).foregroundColor(.primary).font(.caption).frame(width: 265, alignment: .leading)
                } else {
                    Text(String(format: "%d%% | Downloading (%d/%d) files at %@", Int(perc * 100), downloadState.transferedMedia, downloadState.totalMedia, self.formatTransferSpeed(transferSpeed: downloadState.transferSpeed))).foregroundColor(.primary).font(.caption)
                        .frame(width: 265, alignment: .leading)
                }
                
                Image(systemName: downloadState.transferPaused ? "play.fill" : "pause.fill").onTapGesture {
                    self.droneController.manageDownload(action: downloadState.transferPaused ? .resumeTransfer : .pauseTransfer)
                }.padding(.leading, 20).foregroundColor(downloadState.transferForcePaused ? .secondary : .primary).disabled(downloadState.transferForcePaused)
                
                Image(systemName: "xmark").onTapGesture {
                    self.droneController.manageDownload(action: .stopTransfer)
                }.padding(.horizontal, 20).foregroundColor(.primary)
            }.frame(height: 30).padding(.leading, 20)
            
            ProgressView(value: perc).frame(width: 355).padding(.top, -13).padding(.leading, 20)
        }
    }
    
    /// Constructs a view that shows the upload status of media files to a project, displaying upload progress and speed.
    private func mediaUploadStatus() -> some View {
        let uploadState = self.sceneData.mediaUploadState!
        var perc = Float(uploadState.transferedBytes) / Float(uploadState.totalBytes)
        
        if perc.isInfinite || perc.isNaN {
            perc = 0
        }
        
        return VStack(alignment: .leading) {
            Text("Uploading files to project '\(self.sceneData.openedProject.name)':").font(.caption).frame(width: 360, alignment: .leading)
            HStack {
                if uploadState.transferForcePaused {
                    Text(String(format: "%d%% | Waiting for download (%d/%d) files", Int(perc * 100), uploadState.transferedMedia, uploadState.totalMedia)).foregroundColor(.red).font(.caption).frame(width: 265, alignment: .leading)
                } else if uploadState.transferPaused {
                    Text(String(format: "%d%% | Paused upload of (%d/%d) files", Int(perc * 100), uploadState.transferedMedia, uploadState.totalMedia)).foregroundColor(.primary).font(.caption).frame(width: 265, alignment: .leading)
                } else {
                    Text(String(format: "%d%% | Uploading (%d/%d) files at %@", Int(perc * 100), uploadState.transferedMedia, uploadState.totalMedia, self.formatTransferSpeed(transferSpeed:  uploadState.transferSpeed))).foregroundColor(.primary).font(.caption)
                        .frame(width: 265, alignment: .leading)
                }
                
                Image(systemName: uploadState.transferPaused ? "play.fill" : "pause.fill")
                    .onTapGesture {
                        self.sceneController.manageUpload(action: uploadState.transferPaused ? .resumeTransfer : .pauseTransfer)
                    }.padding(.leading, 20).foregroundColor(uploadState.transferForcePaused ? .secondary : .primary).disabled(uploadState.transferForcePaused)
                
                Image(systemName: "xmark")
                    .onTapGesture {
                        self.sceneController.manageUpload(action: .stopTransfer)
                    }.padding([.horizontal], 20).foregroundColor(.primary)
            }.frame(height: 30).padding(.leading, 20)
            
            ProgressView(value: perc).frame(width: 355).padding(.top, -13).padding(.leading, 20)
        }
    }
    
    private func formatTransferSpeed(transferSpeed: Double) -> String {
        if transferSpeed >= 100_000_000 {
            return String(format: "%.2f GB/s", transferSpeed/1_000_000_000)
        } else if transferSpeed >= 100_000 {
            return String(format: "%.2f MB/s", transferSpeed/1_000_000)
        } else if transferSpeed >= 100 {
            return String(format: "%.2f kB/s", transferSpeed/1_000)
        } else {
            return String(format: "%.2f B/s", transferSpeed)
        }
    }
}
