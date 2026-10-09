import Testing
@testable import KurTakip

@MainActor
@Suite
struct RouterTests {
    @Test
    func navigate_pushesTheKey() {
        let router = Router()

        router.navigate(to: "detail")

        #expect(router.path.count == 1)
    }

    @Test
    func navigate_ignoresTheKeyThatIsAlreadyOnTop() {
        let router = Router()

        router.navigate(to: "detail")
        router.navigate(to: "detail")

        #expect(router.path.count == 1)
    }

    @Test
    func navigate_allowsTheSameKeyAfterAnotherScreen() {
        let router = Router()

        router.navigate(to: "a")
        router.navigate(to: "b")
        router.navigate(to: "a")

        #expect(router.path.count == 3)
    }

    @Test
    func goBack_onTheRoot_doesNothing() {
        let router = Router()

        router.goBack()

        #expect(router.path.isEmpty)
    }

    @Test
    func goBack_popsOneScreen() {
        let router = Router()
        router.navigate(to: "a")
        router.navigate(to: "b")

        router.goBack()

        #expect(router.path.count == 1)
    }

    @Test
    func navigate_afterTheSystemBackGesture_acceptsTheKeyAgain() {
        let router = Router()
        router.navigate(to: "detail")
        router.path.removeLast() // what the swipe-back gesture does

        router.navigate(to: "detail")

        #expect(router.path.count == 1)
    }

    @Test
    func reset_replacesTheStackWithTheGivenKeys() {
        let router = Router()
        router.navigate(to: "old")

        router.reset(to: ["list", "detail"])

        #expect(router.path.count == 2)
    }
}
