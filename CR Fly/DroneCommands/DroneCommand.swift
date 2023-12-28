import Foundation

protocol DroneCommand {
    func execute(completion: @escaping () -> Void)
}
