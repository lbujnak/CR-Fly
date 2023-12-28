import SwiftUI
import DJISDK

struct AlbumBottomBar: View {
    
    @Binding var selectMode: Bool
    @Binding var selectedItems : [DJIMediaFile]
    
    @ObservedObject var appData = CRFly.shared.appData
    
    var body: some View {
        HStack(spacing: 50){
            let clr_tr_disab : Bool = (self.selectedItems.count == 0)
            Image(systemName: "trash").foregroundColor(clr_tr_disab ? .secondary : .primary).onTapGesture {
                // TODO: Command? Nie Command?
            }.disabled(clr_tr_disab)
            
            Spacer()
            Button("Clear"){ self.selectedItems.removeAll() }.foregroundColor(clr_tr_disab ? .secondary : .primary).disabled(clr_tr_disab)
            
            Spacer()
            Button("Select All"){
                for (_,files) in self.appData.djiAlbumMedia {
                    for file in files {
                        self.selectedItems.append(file)
                    }
                }
            }.foregroundColor(.primary)
            
            Spacer()
            if(self.appData.mediaSavable){
                let dwnldDisabled = self.appData.mediaDownloadState != nil || clr_tr_disab
                let uploadDisabled = dwnldDisabled || self.appData.mediaUploadState != nil || (self.appData.projectName == nil)
                
                Image(systemName: "tray.and.arrow.down").foregroundColor(dwnldDisabled ? .secondary : .primary).onTapGesture {
                    CRFly.shared.droneController.pushCommand(command: DownloadDroneMedia(selectedItems: self.selectedItems))
                    self.selectMode = false
                    self.selectedItems.removeAll()
                }.disabled(dwnldDisabled)
            
                Image(systemName: "square.and.arrow.up").foregroundColor(uploadDisabled ? .secondary : .primary).onTapGesture {
                    //libController.prepareFilesToUpload(selected: self.selectedItems)
                    self.selectMode = false
                    self.selectedItems.removeAll()
                }.disabled(uploadDisabled)
            }
        }.frame(height: 40).background(Color(UIColor.secondarySystemBackground).ignoresSafeArea()).foregroundColor(.gray)
    }
}
