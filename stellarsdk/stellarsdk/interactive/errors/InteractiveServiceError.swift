import Foundation

public enum InteractiveServiceError: Error {
    case invalidDomain
    case invalidToml
    case noInteractiveServerSet
    case parsingResponseFailed(message:String)
    case anchorError(message:String)
    case notFound(message:String?)
    case authenticationRequired
    case horizonError(error: HorizonRequestError)
}
