import CryptoKit
import Foundation
import Security

/// SPKI certificate pinning (HARD-01). A pin is `sha256/` + base64(SHA-256 of the certificate's
/// SubjectPublicKeyInfo), the same value `openssl` prints. Pin the intermediate and root, never the leaf.
public struct CertificatePinner: Sendable {
    private let pins: Set<String>

    public init(pins: [String]) {
        self.pins = Set(pins)
    }

    public var isEnabled: Bool { !pins.isEmpty }

    /// True when any certificate in the chain carries a configured pin.
    public func matches(chain: [Data]) -> Bool {
        chain.contains { Self.pin(forCertificateDER: $0).map(pins.contains) ?? false }
    }

    public static func pin(forCertificateDER der: Data) -> String? {
        guard let spki = SubjectPublicKeyInfo.extract(fromCertificate: [UInt8](der)) else { return nil }
        return "sha256/" + Data(SHA256.hash(data: spki)).base64EncodedString()
    }
}

/// Minimal DER walker: just enough to cut the SubjectPublicKeyInfo out of an X.509 certificate for any key type.
enum SubjectPublicKeyInfo {
    private static let sequenceTag: UInt8 = 0x30
    private static let versionTag: UInt8 = 0xA0
    private static let longFormFlag: UInt8 = 0x80
    private static let maxLengthBytes = 4
    /// serialNumber, signature, issuer, validity, subject
    private static let fieldsBeforeKey = 5

    private struct Element {
        let tag: UInt8
        let start: Int
        let contentStart: Int
        let end: Int
    }

    static func extract(fromCertificate der: [UInt8]) -> [UInt8]? {
        guard let certificate = element(in: der, at: 0), certificate.tag == sequenceTag,
              let tbs = element(in: der, at: certificate.contentStart), tbs.tag == sequenceTag
        else { return nil }
        var offset = tbs.contentStart
        if let first = element(in: der, at: offset), first.tag == versionTag { offset = first.end }
        for _ in 0..<fieldsBeforeKey {
            guard let field = element(in: der, at: offset) else { return nil }
            offset = field.end
        }
        guard let key = element(in: der, at: offset), key.tag == sequenceTag else { return nil }
        return Array(der[key.start..<key.end])
    }

    private static func element(in bytes: [UInt8], at offset: Int) -> Element? {
        guard offset >= 0, offset + 2 <= bytes.count else { return nil }
        var length = Int(bytes[offset + 1])
        var contentStart = offset + 2
        if bytes[offset + 1] & longFormFlag != 0 {
            let count = Int(bytes[offset + 1] & ~longFormFlag)
            guard count > 0, count <= maxLengthBytes, contentStart + count <= bytes.count else { return nil }
            length = bytes[contentStart..<(contentStart + count)].reduce(0) { ($0 << 8) | Int($1) }
            contentStart += count
        }
        let end = contentStart + length
        guard end <= bytes.count else { return nil }
        return Element(tag: bytes[offset], start: offset, contentStart: contentStart, end: end)
    }
}
