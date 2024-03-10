import Foundation

class CommandQueueController: NSObject {
    
    private var isExecutingCommand = false
    private var commandQueue: [Command] = []
    
    public func pushCommand(command: Command) {
        self.commandQueue.append(command)
        if(!self.isExecutingCommand) {
            processNextCommand()
        }
    }
    
    public func clearCommandQueue(){
        self.commandQueue.removeAll()
    }
    
    private func processNextCommand() {
        guard !self.isExecutingCommand, !self.commandQueue.isEmpty else { return }
        
        self.isExecutingCommand = true
        let command = self.commandQueue.removeFirst()
        command.execute {
            self.isExecutingCommand = false
            self.processNextCommand()
        }
    }
}
