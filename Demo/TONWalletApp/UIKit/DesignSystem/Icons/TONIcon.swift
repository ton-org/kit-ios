import SwiftUI

// All cases below are backed by SVG imagesets in
// Demo/TONWalletApp/Assets.xcassets/DesignSystem/<Category>/<Name>.imageset/.
// Imported from `Downloads/Demo App UI Kit/`.
enum TONIcon: String, CaseIterable, Hashable {

    // MARK: - Tabbar
    case discoverFilled = "DiscoverFilled"
    case discoverOutline = "DiscoverOutline"
    case holdingsFilled = "HoldingsFilled"
    case holdingsOutline = "HoldingsOutline"
    case homeFilled = "HomeFilled"
    case homeOutline = "HomeOutline"

    // MARK: - 24 Standalone
    case arrowDownCircle = "ArrowDownCircle"
    case arrowRightCircle = "ArrowRightCircle"
    case arrowRightUpCircle = "ArrowRightUpCircle"
    case arrowUpCircle = "ArrowUpCircle"
    case calendar = "Calendar"
    case calendarDays = "CalendarDays"
    case chat = "Chat"
    case chevronDown = "ChevronDown"
    case chevronRight = "ChevronRight"
    case chevronUp = "ChevronUp"
    case circleMinus = "CircleMinus"
    case circlePlus = "CirclePlus"
    case coin = "Coin"
    case filter = "Filter"
    case gas = "Gas"
    case globus = "Globus"
    case headerArrowShare = "HeaderArrowShare"
    case headerStar = "HeaderStar"
    case headerStarOutline = "HeaderStarOutline"
    case holders = "Holders"
    case more = "More"
    case plusLarge = "PlusLarge"
    case sellIcon = "SellIcon"
    case send = "Send"
    case settings24 = "Settings24"
    case star24 = "Star24"
    case switchVertical24 = "SwitchVertical24"
    case ton = "TON"
    case toncoin = "Toncoin"
    case tonFill = "TonFill"
    case trend = "Trend"
    case volume = "Volume"
    case volume2 = "Volume2"
    case volume3 = "Volume3"
    case wallet = "Wallet"
    case wallet4 = "Wallet4"

    // MARK: - 20 Action
    case changeValue = "ChangeValue"
    case chevronBackSmall = "ChevronBackSmall"
    case chevronDownSmall = "ChevronDownSmall"
    case chevronForwardSmall = "ChevronForwardSmall"
    case chevronTopSmall = "ChevronTopSmall"
    case clear = "Clear"
    case close = "Close"
    case copy = "Copy"
    case doc = "Doc"
    case done = "Done"
    case failed = "Failed"
    case github = "Github"
    case globe = "Globe"
    case inProgress = "InProgress"
    case link20 = "Link20"
    case openLink = "OpenLink"
    case `switch` = "Switch"
    case telegram = "Telegram"

    // MARK: - 16 Badge / Status
    case activeCheck = "ActiveCheck"
    case activeDot = "ActiveDot"
    case headerShare = "HeaderShare"
    case hot = "Hot"
    case info = "Info"
    case loading = "Loading"
    case new = "New"
    case newSparkle = "NewSparkle"
    case padlock = "Padlock"
    case padlockOpen = "PadlockOpen"
    case present = "Present"
    case settings = "Settings"
    case star = "Star"
    case starFilled = "StarFilled"
    case switch16 = "Switch16"
    case tick = "Tick"
    case trending = "Trending"
    case upArrow = "UpArrow"
    case verifiedBadge = "VerifiedBadge"

    // MARK: - 12 Micro
    case trendDown = "TrendDown"
    case trendUp = "TrendUp"

    // MARK: - 40 Illustrative
    case bankCard40 = "BankCard40"
    case bankCard40Alt = "BankCard40Alt"
    case fee40 = "Fee40"
    case fee40Alt = "Fee40Alt"
    case hand40 = "Hand40"
    case holders40 = "Holders40"
    case present40 = "Present40"
    case qrCode40 = "QrCode40"
    case reward40 = "Reward40"
    case share40 = "Share40"
    case share40Alt = "Share40Alt"
    case telegramWallet40 = "TelegramWallet40"
    case toncoin40 = "Toncoin40"

    var image: Image { Image(rawValue) }

    enum Category: String, CaseIterable, Hashable {
        case tabbar = "Tabbar"
        case icons24 = "24 Standalone"
        case icons20 = "20 Action"
        case icons16 = "16 Badge / Status"
        case icons12 = "12 Micro"
        case icons40 = "40 Illustrative"
    }

    var category: Category {
        switch self {
        case .discoverFilled, .discoverOutline, .holdingsFilled, .holdingsOutline, .homeFilled, .homeOutline:
            return .tabbar
        case .arrowDownCircle, .arrowRightCircle, .arrowRightUpCircle, .arrowUpCircle, .calendar,
             .calendarDays, .chat, .chevronDown, .chevronRight, .chevronUp, .circleMinus, .circlePlus, .coin,
             .filter, .gas, .globus, .headerArrowShare, .headerStar, .headerStarOutline, .holders, .more,
             .plusLarge, .sellIcon, .send, .settings24, .star24, .switchVertical24, .ton, .toncoin, .tonFill,
             .trend, .volume, .volume2, .volume3, .wallet, .wallet4:
            return .icons24
        case .changeValue, .chevronBackSmall, .chevronDownSmall, .chevronForwardSmall, .chevronTopSmall,
             .clear, .close, .copy, .doc, .done, .failed, .github, .globe, .inProgress, .link20, .openLink,
             .`switch`, .telegram:
            return .icons20
        case .activeCheck, .activeDot, .headerShare, .hot, .info, .loading, .new, .newSparkle, .padlock,
             .padlockOpen, .present, .settings, .star, .starFilled, .switch16, .tick, .trending, .upArrow,
             .verifiedBadge:
            return .icons16
        case .trendDown, .trendUp:
            return .icons12
        case .bankCard40, .bankCard40Alt, .fee40, .fee40Alt, .hand40, .holders40, .present40, .qrCode40,
             .reward40, .share40, .share40Alt, .telegramWallet40, .toncoin40:
            return .icons40
        }
    }
}
