import SwiftUI
import Foundation

class RCNodeCommunicationService : NSObject, ObservableObject {
    
    @ObservedObject static var shared = RCNodeCommunicationService()
    
    @Published var ip = "192.168.10.15"
    @Published var autorized = false;
    @Published var authToken = ""; //674746F1-C361-413B-B427-BD769E7BE96E
    
    func connectToRC(completionHandler: @escaping (String?) -> Void) {
        let url = URL(string: "http://\(self.ip):8000/node/status")!
        
        var request = URLRequest(url: url, timeoutInterval: 2);
        request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completionHandler(String(describing: error));
                return
            }
            
            if let response = response as? HTTPURLResponse {
                print("Response HTTP Status code: \(response.statusCode)")
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
                        if(json["status"] != nil){
                            //DispatchQueue.main.async {
                            self.autorized = true
                            self.checkForConnection()
                            completionHandler(nil)
                        }
                        else{ completionHandler("AuthRequired") }
                    }
                } catch let error as NSError {
                    completionHandler("Failed read response: \(error.localizedDescription)")
                    return
                }
            }
        }
        task.resume()
    }
    
    func checkForConnection(){
        
    }
}

