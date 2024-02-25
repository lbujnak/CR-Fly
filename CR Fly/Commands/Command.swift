import Foundation

protocol Command {
    func execute(completion: @escaping () -> Void)
}
