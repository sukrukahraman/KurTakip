import SwiftUI

/// Dynamic Type aware text styles. A custom font must use `Font.custom(_:size:relativeTo:)` so it still scales.
public struct KurTakipTypography: Sendable {
    public let largeTitle = Font.largeTitle.weight(.bold)
    public let title = Font.title2.weight(.semibold)
    public let headline = Font.headline
    public let body = Font.body
    public let callout = Font.callout
    public let caption = Font.caption
}
