import Foundation
import Testing
@testable import CoreNetwork

@Suite
struct CertificatePinnerTests {
    // Generated with openssl. The expected pins come from:
    // openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
    private static let ecBase64 =
        "MIIBgzCCASmgAwIBAgIUdcQciQTx6/ZxTzLtmvzJA6Bqgk4wCgYIKoZIzj0EAwIwFjEUMBIGA1UEAwwLcGluLWVjLnRlc3Qw" +
        "IBcNMjYxMDA4MjIyOTAwWhgPMjEyNjA5MTQyMjI5MDBaMBYxFDASBgNVBAMMC3Bpbi1lYy50ZXN0MFkwEwYHKoZIzj0CAQYI" +
        "KoZIzj0DAQcDQgAEORarstZC5AC+Vwq/WYUY5nAIsRahNi8lFHBw9FhIZgzdDeJRh3Etb/D052OMGThQHZGUHANjBkRJWQWO" +
        "AOLIfaNTMFEwHQYDVR0OBBYEFPJJa6gQr6p1rqj3rVxLTc7de8mHMB8GA1UdIwQYMBaAFPJJa6gQr6p1rqj3rVxLTc7de8mH" +
        "MA8GA1UdEwEB/wQFMAMBAf8wCgYIKoZIzj0EAwIDSAAwRQIhAMozht+eM6TAXtowlUOevplK9LQOYpaWNvqR5L+vbqsUAiBn" +
        "JAUgl+02lWJFJ5XW2R58qCBY8RkaSkc29J9u1cmMnA=="
    private static let ecPin = "sha256/1JKzsIONBbQVgPAi8mq/HMDC0w8akW8nUn+y5kDLMq4="
    private static let rsaBase64 =
        "MIIDETCCAfmgAwIBAgIUfBdcHXdBWqE/CkDTF1fDIRdjshswDQYJKoZIhvcNAQELBQAwFzEVMBMGA1UEAwwMcGluLXJzYS50" +
        "ZXN0MCAXDTI2MTAwODIyMjkwMFoYDzIxMjYwOTE0MjIyOTAwWjAXMRUwEwYDVQQDDAxwaW4tcnNhLnRlc3QwggEiMA0GCSqG" +
        "SIb3DQEBAQUAA4IBDwAwggEKAoIBAQCPC6bBj8lVSeODFdIVhpW4YrKq/4sVLVcu268WTjxbVzLJ4PDwQyP0YvLBxPHc92dl" +
        "m96tauSnTtTm8+UQHVQfkNpSsvWteQgGIH83Hw/GeQEbHqAo3yydsNKWW1wqbqI2QbFwClcA4Zp5bhIIu09DxxHCIdhxdxk8" +
        "Il1Cu85SbRDgVMooTCnYnHEsF9SNnGBCWWFcEWHHuHqaWQuRol5phEWNOz6+kh7VeqvXksdGqgyV4FOMxO0wV+AA/01yNaiF" +
        "JDGmgbXD4rTZVqnH50BETG5aLsShq1HWcb/8Z7tSxuDXnBtl5L/QNeoiUr9x3VytaS3GzyY9TZlx+l1DuBxrAgMBAAGjUzBR" +
        "MB0GA1UdDgQWBBTvlHnsrBaVo/QRfYUTHyFTHaqk1zAfBgNVHSMEGDAWgBTvlHnsrBaVo/QRfYUTHyFTHaqk1zAPBgNVHRMB" +
        "Af8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQAaiCg9JIH6UAP7EhJf4XHkze7noiq2Bkd164hGQYoWjEjatJyRFnuH5qXi" +
        "WWuw36vZRWgObcMMC6IM1ieWSsyHGFdnZPfcZuy9CaBREezUFA+LLWeiF1kVQD90T4PuTEjHoIcU6HaBYBdc/lz6tFKu8yOm" +
        "GyOUgeWrY6zs5Rg/eQcqLLVBnLXT+2cG5wOycuLUCQtXhkDqZI0+5XhWW5hW1AOSfzIHyPmdK8oV1fjwm3ug7+BlH9XgHLNi" +
        "t2Rw942m9A7wPFiS25S/z4+15bKdeKpFEXUcDz4LqRDPObfWSS8AhqanAm6Jr9FQ8BHWCZCPV5EaCqJySc8QpLEU5Eoi"
    private static let rsaPin = "sha256/VzSRL46zu7XiLVwZhIaOCaCrM4IZu771frp58gfXiUM="

    private let ecCertificate: Data
    private let rsaCertificate: Data

    init() throws {
        ecCertificate = try #require(Data(base64Encoded: Self.ecBase64))
        rsaCertificate = try #require(Data(base64Encoded: Self.rsaBase64))
    }

    @Test
    func pin_ofEllipticCurveCertificate_matchesOpenSSL() {
        #expect(CertificatePinner.pin(forCertificateDER: ecCertificate) == Self.ecPin)
    }

    @Test
    func pin_ofRSACertificate_matchesOpenSSL() {
        #expect(CertificatePinner.pin(forCertificateDER: rsaCertificate) == Self.rsaPin)
    }

    @Test
    func pin_ofGarbage_isNil() {
        #expect(CertificatePinner.pin(forCertificateDER: Data([0x01, 0x02, 0x03])) == nil)
    }

    @Test
    func matches_whenAnyCertificateInChainIsPinned() {
        let pinner = CertificatePinner(pins: [Self.rsaPin])

        #expect(pinner.matches(chain: [ecCertificate, rsaCertificate]))
    }

    @Test
    func matches_whenNothingIsPinned_isFalse() {
        let pinner = CertificatePinner(pins: ["sha256/AAAA"])

        #expect(!pinner.matches(chain: [ecCertificate, rsaCertificate]))
    }

    @Test
    func isEnabled_onlyWithPins() {
        #expect(!CertificatePinner(pins: []).isEnabled)
        #expect(CertificatePinner(pins: [Self.ecPin]).isEnabled)
    }
}
