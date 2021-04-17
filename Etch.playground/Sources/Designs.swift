/*
   Design file. Includes Etching data structure, colours, and custom grids.
*/

import UIKit

// MARK: - Etching

/// The data structure used to store Etchings when loading and saving.
public struct Etching {
    public let title: String
    public let gridArray: [[UIColor]]

    public init(title: String, gridArray: [[UIColor]]) {
        self.title = title
        self.gridArray = gridArray
    }
}

// MARK: Colours

/// The set of colours used in the project.
public struct Colours {
    /// Brand colours used in UI.
    public static let brandWhite: UIColor = UIColor(red: 236 / 255, green: 252 / 255, blue: 246 / 255, alpha: 1)
    public static let brandPink: UIColor = UIColor(red: 250 / 255, green: 228 / 255, blue: 230 / 255, alpha: 1)
    public static let brandSalmon: UIColor = UIColor(red: 255 / 255, green: 205 / 255, blue: 182 / 255, alpha: 1)
    public static let brandBrown: UIColor = UIColor(red: 35 / 255, green: 26 / 255, blue: 19 / 255, alpha: 1)

    /// Colours to use in colour palette.
    public static let black: UIColor = UIColor(red: 0 / 255, green: 0 / 255, blue: 0 / 255, alpha: 1)
    public static let blue: UIColor = UIColor(red: 0 / 255, green: 0 / 255, blue: 255 / 255, alpha: 1)
    public static let red: UIColor = UIColor(red: 255 / 255, green: 0 / 255, blue: 0 / 255, alpha: 1)
    public static let tan: UIColor = UIColor(red: 203 / 255, green: 255 / 255, blue: 101 / 255, alpha: 1)
    public static let darkGreen: UIColor = UIColor(red: 0 / 255, green: 127 / 255, blue: 0 / 255, alpha: 1)
    public static let lightGreen: UIColor = UIColor(red: 0 / 255, green: 255 / 255, blue: 0 / 255, alpha: 1)
    public static let yellow: UIColor = UIColor(red: 255 / 255, green: 255 / 255, blue: 0 / 255, alpha: 1)
    public static let white: UIColor = UIColor(red: 255 / 255, green: 255 / 255, blue: 255 / 255, alpha: 1)
    public static let gray: UIColor = UIColor(red: 127 / 255, green: 127 / 255, blue: 127 / 255, alpha: 1)
    public static let cyan: UIColor = UIColor(red: 0 / 255, green: 255 / 255, blue: 255 / 255, alpha: 1)
    public static let orange: UIColor = UIColor(red: 255 / 255, green: 159 / 255, blue: 0 / 255, alpha: 1)
    public static let brown: UIColor = UIColor(red: 127 / 255, green: 127 / 255, blue: 0 / 255, alpha: 1)
    public static let pink: UIColor = UIColor(red: 255 / 255, green: 63 / 255, blue: 255 / 255, alpha: 1)
    public static let violet: UIColor = UIColor(red: 127 / 255, green: 127 / 255, blue: 255 / 255, alpha: 1)
    public static let brightGreen: UIColor = UIColor(red: 127 / 255, green: 255 / 255, blue: 0 / 255, alpha: 1)
    public static let magenta: UIColor = UIColor(red: 255 / 255, green: 0 / 255, blue: 127 / 255, alpha: 1)
}

// MARK: - CustomDesigns

/// Custom Etchings used in the gallery. All art is based on a 32x32 bit grid. Reference sources are linked beside pixel arrays.
public struct CustomDesigns {

    public var array: [Etching] = [Etching]()

    public init() { }
}
