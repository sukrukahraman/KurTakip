import Foundation
import Security

/// Evaluates the system trust first, then requires one pinned certificate in the chain. With no pins configured the
/// default handling applies. A rejected challenge surfaces as a non-retried error (ERR-08).
final class PinningSessionDelegate: NSObject, URLSessionDelegate, Sendable {
    private let pinner: CertificatePinner

    init(pinner: CertificatePinner) {
        self.pinner = pinner
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard pinner.isEnabled,
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust
        else { return (.performDefaultHandling, nil) }
        guard SecTrustEvaluateWithError(trust, nil) else { return (.cancelAuthenticationChallenge, nil) }
        let chain = (SecTrustCopyCertificateChain(trust) as? [SecCertificate] ?? [])
            .map { SecCertificateCopyData($0) as Data }
        return pinner.matches(chain: chain)
            ? (.useCredential, URLCredential(trust: trust))
            : (.cancelAuthenticationChallenge, nil)
    }
}
