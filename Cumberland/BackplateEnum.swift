//
//  BackplateEnum.swift
//  Cumberland
//
//  Created by Mike Stoddard on 3/31/26.
//

enum ThemeType: String, CaseIterable
{
    case defaultTheme = "Default"
    case purpleTheme = "Purple"
    case halloweenTheme = "Halloween"
    case whimsicalTheme = "Whimsical"
} //end ThemeType

enum ModeType: String, CaseIterable
{
    case lightMode = "Light"
    case darkMode = "Dark"
}

enum SubjectType: String, CaseIterable
{
    case lines = "Lines"
    case pen = "Pen"
    case cat = "Cat"
}

struct BackplateEnum
{
    func getImage(theme: ThemeType, mode: ModeType, subject: SubjectType) -> String
    {
        return "\(theme.rawValue)-\(mode.rawValue)-\(subject.rawValue)"
    }
    
} //end BackplateEnum
