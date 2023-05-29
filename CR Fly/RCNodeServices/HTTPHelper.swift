import Foundation

class HTTPHelper {
    static var shared = HTTPHelper(ip: "", authToken: "")
    
    private var ip : String
    private var authToken : String
    
    init(ip: String, authToken: String) {
        self.ip = ip
        self.authToken = authToken
    }
    
    func changeParams(ip: String, authToken: String) {
        self.ip = ip
        self.authToken = authToken
    }
    
    //tol - time out limit
    func httpPattern(url: String, tol: Double, sessionID : String?, completionHandler: @escaping (Data?,[String: Any]?, HTTPURLResponse?, Bool) -> Void){
        let url = URL(string: "http://\(self.ip):8000\(url)")!
        var request = URLRequest(url: url, timeoutInterval: tol);
        
        request.setValue("close", forHTTPHeaderField: "Connection")
        request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        if(sessionID != nil){ request.setValue("\(sessionID!)", forHTTPHeaderField: "Session") }
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            let httpResponse = response as? HTTPURLResponse
            let jsonData = self.parseJsonData2D(data: data)
            var valid = true
            
            if(error != nil){ valid = false; GlobalAlertHelper.shared.showError(msg: String(describing: error!)) }
            else if(httpResponse!.statusCode / 100 != 2){
                valid = false
                GlobalAlertHelper.shared.showError(msg: String(describing: jsonData!["message"]!))
            }
            completionHandler(data,jsonData,httpResponse,valid)
        }.resume()
    }
    
    func createProjectTemplateFile(name: String, data: String, sessionID: String, completionHandler: @escaping (String?) -> Void){
        let request = self.preparePostRequest(url: "/project/upload?name=\(name).tpl&folder=output", sessionID: sessionID)
        let reqData = Data(data.utf8)
        
        URLSession.shared.uploadTask(with: request, from: reqData) { (data, response, error) in
            if(error != nil) { completionHandler(String(describing: error!)) }
            else if((response as! HTTPURLResponse).statusCode != 200){
                completionHandler("Status code not as expected: \((response as! HTTPURLResponse).statusCode)")
            } else { completionHandler(nil) }
        }.resume()
    }
    
    func parseJsonData1D(data: Data?) -> [String]?{
        var jsonData : [String]? = nil
        if(data != nil){
            jsonData = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String]
        }
        return jsonData
    }
    
    func parseJsonData2D(data: Data?) -> [String:Any]?{
        var jsonData : [String: Any]? = nil
        if(data != nil){
            jsonData = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
        }
        return jsonData
    }
    
    func parseJsonData3D(data: Data?) -> [[String: Any]]?{
        var jsonData : [[String: Any]]? = nil
        if(data != nil){
            jsonData = try? JSONSerialization.jsonObject(with: data!, options: []) as? [[String: Any]]
        }
        return jsonData
    }
    
    func preparePostRequest(url : String, sessionID : String) -> URLRequest{
        let url = URL(string: "http://\(self.ip):8000\(url)")!
        
        var request = URLRequest(url: url, timeoutInterval: 2);
        request.setValue("close", forHTTPHeaderField: "Connection")
        request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.setValue((sessionID), forHTTPHeaderField: "Session")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        return request
    }
    
    func prepareDownloadRequest(url : String, sessionID : String) -> URLRequest{
        let url = URL(string: "http://\(self.ip):8000\(url)")!
        
        var request = URLRequest(url: url, timeoutInterval: 2);
        request.setValue("close", forHTTPHeaderField: "Connection")
        request.setValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
        request.setValue((sessionID), forHTTPHeaderField: "Session")
        request.httpMethod = "GET"
        return request
    }
}
