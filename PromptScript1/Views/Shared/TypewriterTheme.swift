import SwiftUI

// MARK: - Typewriter Theme Design System
// Classic scriptwriting aesthetic with black/white color scheme and typewriter fonts

struct TypewriterTheme {
    
    // MARK: - Colors
    struct Colors {
        static let paperWhite = Color(white: 0.98)
        static let inkBlack = Color.black
        static let typewriterGray = Color.gray
        static let lightGray = Color(white: 0.7)
        static let shadowGray = Color.black.opacity(0.1)
        
        // Base accent colors
        static let characterBlue = Color.blue
        static let sceneGreen = Color.green
        static let actionOrange = Color.orange
        static let dialogueRed = Color.red
        static let settingPurple = Color.purple
        
        // MARK: - Tab-Specific Color Themes
        struct Characters {
            static let background = Color(red: 0.96, green: 0.97, blue: 0.99)
            static let primary = Color.blue
            static let secondary = Color(red: 0.3, green: 0.5, blue: 0.8)
            static let accent = Color(red: 0.1, green: 0.4, blue: 0.9)
            static let cardBackground = Color.white
        }
        
        struct Scenes {
            static let background = Color(red: 0.96, green: 0.99, blue: 0.96)
            static let primary = Color.green
            static let secondary = Color(red: 0.3, green: 0.7, blue: 0.3)
            static let accent = Color(red: 0.2, green: 0.8, blue: 0.2)
            static let cardBackground = Color.white
        }
        
        struct Script {
            static let background = Color(red: 0.99, green: 0.98, blue: 0.96)
            static let primary = Color.orange
            static let secondary = Color(red: 0.8, green: 0.5, blue: 0.2)
            static let accent = Color(red: 0.9, green: 0.6, blue: 0.1)
            static let cardBackground = Color.white
        }
        
        struct Export {
            static let background = Color(red: 0.98, green: 0.96, blue: 0.99)
            static let primary = Color.purple
            static let secondary = Color(red: 0.6, green: 0.3, blue: 0.8)
            static let accent = Color(red: 0.7, green: 0.2, blue: 0.9)
            static let cardBackground = Color.white
        }
        
        struct Settings {
            static let background = Color(white: 0.97)
            static let primary = Color.black
            static let secondary = Color.gray
            static let accent = Color(white: 0.3)
            static let cardBackground = Color.white
        }
    }
    
    // MARK: - Fonts
    struct Fonts {
        static let typewriter = "Courier New"
        static let fallback = "American Typewriter"
        
        // Text styles
        static func title(_ size: CGFloat = 24) -> Font {
            .custom(typewriter, size: size).weight(.bold)
        }
        
        static func headline(_ size: CGFloat = 20) -> Font {
            .custom(typewriter, size: size).weight(.semibold)
        }
        
        static func body(_ size: CGFloat = 16) -> Font {
            .custom(typewriter, size: size)
        }
        
        static func caption(_ size: CGFloat = 12) -> Font {
            .custom(typewriter, size: size)
        }
        
        static func monospaced(_ size: CGFloat = 14) -> Font {
            .custom(typewriter, size: size)
        }
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let tiny: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
        static let huge: CGFloat = 24
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let light = Color.black.opacity(0.05)
        static let medium = Color.black.opacity(0.1)
        static let heavy = Color.black.opacity(0.2)
    }
}

// MARK: - Custom View Modifiers
extension View {
    
    /// Apply typewriter paper background
    func typewriterPaper() -> some View {
        self.background(TypewriterTheme.Colors.paperWhite)
    }
    
    /// Apply typewriter card styling
    func typewriterCard() -> some View {
        self
            .background(Color.white)
            .cornerRadius(TypewriterTheme.CornerRadius.large)
            .shadow(color: TypewriterTheme.Shadows.medium, radius: 2, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: TypewriterTheme.CornerRadius.large)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
    
    /// Apply typewriter button styling
    func typewriterButton(color: Color = TypewriterTheme.Colors.sceneGreen) -> some View {
        self
            .font(TypewriterTheme.Fonts.body())
            .foregroundColor(.white)
            .padding(.horizontal, TypewriterTheme.Spacing.large)
            .padding(.vertical, TypewriterTheme.Spacing.medium)
            .background(color)
            .cornerRadius(TypewriterTheme.CornerRadius.medium)
    }
    
    /// Apply typewriter text styling
    func typewriterText(size: CGFloat = 16, color: Color = TypewriterTheme.Colors.inkBlack) -> some View {
        self
            .font(TypewriterTheme.Fonts.body(size))
            .foregroundColor(color)
    }
    
    /// Apply typewriter title styling
    func typewriterTitle(size: CGFloat = 24) -> some View {
        self
            .font(TypewriterTheme.Fonts.title(size))
            .foregroundColor(TypewriterTheme.Colors.inkBlack)
    }
    
    /// Apply script label styling (like "CAST MEMBER", "SCENE", etc.)
    func scriptLabel(text: String, color: Color = TypewriterTheme.Colors.inkBlack) -> some View {
        HStack {
            Text(text)
                .font(TypewriterTheme.Fonts.caption(10))
                .foregroundColor(.white)
                .padding(.horizontal, TypewriterTheme.Spacing.small)
                .padding(.vertical, 2)
                .background(color)
                .cornerRadius(TypewriterTheme.CornerRadius.small)
            Spacer()
        }
    }
}

// MARK: - Animation Presets
extension Animation {
    static let typewriterBounce = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let typewriterPress = Animation.spring(response: 0.2, dampingFraction: 0.8)
    static let typewriterFade = Animation.easeInOut(duration: 0.3)
}

// MARK: - Icon System for Different Categories
struct TypewriterIcons {
    // Character icons
    static let character = "person.fill"
    static let characterPlaceholder = "person.2.square.stack"
    static let characterAge = "person.badge.clock"
    static let characterFeatures = "eye"
    
    // Scene icons
    static let scene = "film.stack"
    static let sceneEmpty = "plus.rectangle.on.folder"
    static let sceneCamera = "camera"
    static let sceneLocation = "location"
    
    // Script icons
    static let script = "doc.text"
    static let dialogue = "bubble.left"
    static let action = "figure.walk"
    static let note = "theatermasks"
    static let environment = "leaf"
    
    // UI icons
    static let add = "plus.circle.fill"
    static let edit = "pencil.circle"
    static let delete = "trash"
    static let arrow = "chevron.right"
    static let back = "chevron.left"
}
