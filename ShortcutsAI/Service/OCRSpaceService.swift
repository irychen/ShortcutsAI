//
//  OCRSpaceService.swift
//  ShortcutsAI
//
//  Created by fine on 2024/9/2.
//

import Foundation

// language
// [Optional]
// Arabic=ara
// Bulgarian=bul
// Chinese(Simplified)=chs
// Chinese(Traditional)=cht
// Croatian = hrv
// Czech = cze
// Danish = dan
// Dutch = dut
// English = eng
// Finnish = fin
// French = fre
// German = ger
// Greek = gre
// Hungarian = hun
// Korean = kor
// Italian = ita
// Japanese = jpn
// Polish = pol
// Portuguese = por
// Russian = rus
// Slovenian = slv
// Spanish = spa
// Swedish = swe
// Turkish = tur

public let languageOptions = [
    SelectOption(value: "ara", label: "Arabic"),
    SelectOption(value: "bul", label: "Bulgarian"),
    SelectOption(value: "chs", label: "Chinese (Simplified)"),
    SelectOption(value: "cht", label: "Chinese (Traditional)"),
    SelectOption(value: "hrv", label: "Croatian"),
    SelectOption(value: "cze", label: "Czech"),
    SelectOption(value: "dan", label: "Danish"),
    SelectOption(value: "dut", label: "Dutch"),
    SelectOption(value: "eng", label: "English"),
    SelectOption(value: "fin", label: "Finnish"),
    SelectOption(value: "fre", label: "French"),
    SelectOption(value: "ger", label: "German"),
    SelectOption(value: "gre", label: "Greek"),
    SelectOption(value: "hun", label: "Hungarian"),
    SelectOption(value: "kor", label: "Korean"),
    SelectOption(value: "ita", label: "Italian"),
    SelectOption(value: "jpn", label: "Japanese"),
    SelectOption(value: "pol", label: "Polish"),
    SelectOption(value: "por", label: "Portuguese"),
    SelectOption(value: "rus", label: "Russian"),
    SelectOption(value: "slv", label: "Slovenian"),
    SelectOption(value: "spa", label: "Spanish"),
    SelectOption(value: "swe", label: "Swedish"),
    SelectOption(value: "tur", label: "Turkish"),
]

class OCRSpaceService {
    let url = "https://api.ocr.space/parse/image"
    var apikey: String
    var language: String?
    var isTable = false

    init(apikey: String, language: String? = nil) {
        self.apikey = apikey
        self.language = language
    }
}
