//
//  Color.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 30.09.2025.
//
//  Copyright (c) 2025 TON Connect
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import SwiftUI

import SwiftUI

extension Color {
    // MARK: - Design System Colors
    struct TON {
        static let red50 = Color(hex: "#FEF3F3")
        static let red100 = Color(hex: "#FDE5E6")
        static let red200 = Color(hex: "#FBD0D2")
        static let red300 = Color(hex: "#F7AFB4")
        static let red400 = Color(hex: "#EF7C87")
        static let red500 = Color(hex: "#E75364")
        static let red600 = Color(hex: "#D93449")
        static let red700 = Color(hex: "#B71E35")
        static let red800 = Color(hex: "#99162D")
        static let red900 = Color(hex: "#811428")
        
        // Yellow
        static let yellow50 = Color(hex: "#FFFBF0")
        static let yellow100 = Color(hex: "#FFF6D6")
        static let yellow200 = Color(hex: "#FFEDB3")
        static let yellow300 = Color(hex: "#FFE085")
        static let yellow400 = Color(hex: "#FFCF4D")
        static let yellow500 = Color(hex: "#FBBA1F")
        static let yellow600 = Color(hex: "#D89B0D")
        static let yellow700 = Color(hex: "#A87607")
        static let yellow800 = Color(hex: "#8A5F09")
        static let yellow900 = Color(hex: "#74500C")
        
        // Green
        static let green50 = Color(hex: "#F3FEF3")
        static let green100 = Color(hex: "#E6FCE7")
        static let green300 = Color(hex: "#B8F0BA")
        static let green500 = Color(hex: "#5FD664")
        static let green600 = Color(hex: "#3FB546")
        static let green700 = Color(hex: "#2A8F30")
        static let green800 = Color(hex: "#227128")
        static let green900 = Color(hex: "#1F5E24")
        
        // Blue
        static let blue50 = Color(hex: "#F3F8FF")
        static let blue100 = Color(hex: "#E5F0FF")
        static let blue200 = Color(hex: "#D5E6FF")
        static let blue300 = Color(hex: "#BBD7FF")
        static let blue500 = Color(hex: "#4A9EFF")
        static let blue600 = Color(hex: "#2271F5")
        static let blue700 = Color(hex: "#0F56E0")
        static let blue800 = Color(hex: "#0D43B8")
        static let blue900 = Color(hex: "#123795")
        
        // Purple
        static let purple50 = Color(hex: "#FCF7FE")
        static let purple100 = Color(hex: "#F8ECFD")
        static let purple600 = Color(hex: "#B128E6")
        
        // Pink
        static let pink50 = Color(hex: "#FEF3F9")
        
        // Gray
        static let gray50 = Color(hex: "#FAFAFA")
        static let gray100 = Color(hex: "#F5F5F6")
        static let gray200 = Color(hex: "#EBEBEC")
        static let gray300 = Color(hex: "#DCDCDE")
        static let gray400 = Color(hex: "#AAABB0")
        static let gray500 = Color(hex: "#77787F")
        static let gray600 = Color(hex: "#5D5E64")
        static let gray700 = Color(hex: "#494A50")
        static let gray900 = Color(hex: "#1D1D23")
        
        // Black & White
        static let black = Color(hex: "#000000")
        static let white = Color(hex: "#FFFFFF")
    }
}

// MARK: - Design System Spacing
struct AppSpacing {
    static let base: CGFloat = 4 // 0.25rem = 4pt
    
    static func spacing(_ multiplier: CGFloat) -> CGFloat {
        return base * multiplier
    }
}

// MARK: - Design System Radius
struct AppRadius {
    static let standard: CGFloat = 10 // 0.625rem = 10pt
}

// MARK: - Design System Containers
struct AppContainer {
    static let md: CGFloat = 448 // 28rem = 448pt
    static let lg: CGFloat = 512 // 32rem = 512pt
    static let xl4: CGFloat = 896 // 56rem = 896pt
}

// MARK: - Design System Typography
struct AppFont {
    // Font Sizes
    static let xs: CGFloat = 12 // 0.75rem
    static let sm: CGFloat = 14 // 0.875rem
    static let base: CGFloat = 16 // 1rem
    static let lg: CGFloat = 18 // 1.125rem
    static let xl: CGFloat = 20 // 1.25rem
    static let xl2: CGFloat = 24 // 1.5rem
    static let xl3: CGFloat = 30 // 1.875rem
    
    // Line Heights
    static let xsLineHeight: CGFloat = 1 / 0.75
    static let smLineHeight: CGFloat = 1.25 / 0.875
    static let baseLineHeight: CGFloat = 1.5
    static let lgLineHeight: CGFloat = 1.75 / 1.125
    static let xlLineHeight: CGFloat = 1.75 / 1.25
    static let xl2LineHeight: CGFloat = 2 / 1.5
    static let xl3LineHeight: CGFloat = 1.2
    
    // Font Weights
    static let medium = Font.Weight.medium // 500
    static let semibold = Font.Weight.semibold // 600
    static let bold = Font.Weight.bold // 700
    
    // Letter Spacing
    static let trackingWide: CGFloat = 0.4 // 0.025em * 16
}

// MARK: - Typography Modifiers
extension View {
    
    func textXS(weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: AppFont.xs, weight: weight))
    }
    
    func textSM(weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: AppFont.sm, weight: weight))
    }
    
    func textBase(weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: AppFont.base, weight: weight))
    }
    
    func textLG(weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: AppFont.lg, weight: weight))
    }
    
    func textXL(weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: AppFont.xl, weight: weight))
    }
    
    func text2XL(weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: AppFont.xl2, weight: weight))
    }
    
    func text3XL(weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: AppFont.xl3, weight: weight))
    }
}

extension UIColor {
    
    convenience init(hex: String) {
        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Remove the # if it exists
        if hexFormatted.hasPrefix("#") {
            hexFormatted.remove(at: hexFormatted.startIndex)
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        
        if hexFormatted.count == 6 {
            // RGB (no alpha)
            let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(rgbValue & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b, alpha: 1.0)
        } else if hexFormatted.count == 8 {
            // RGBA (with alpha)
            let r = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
            let g = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
            let b = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0
            let a = CGFloat(rgbValue & 0x000000FF) / 255.0
            self.init(red: r, green: g, blue: b, alpha: a)
        } else {
            // Invalid hex string, return default black color
            self.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        }
    }
}

public extension Color {
    
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

public extension Color {
    
    var uiColor: UIColor {
        UIColor(self)
    }
}
