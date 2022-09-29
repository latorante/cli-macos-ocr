//
//  main.swift
//
//
//  Created by Martin Picha on 28/9/22.
//

import Foundation
import ArgumentParser

//
// Inspiration:
// - https://github.com/chamzzzzzz/mac-ocr-cli
// - https://github.com/ughe/macocr
//

struct OCRCli: ParsableCommand {
    
    static let configuration = CommandConfiguration(
        abstract: "Read text from an image file using native macOs Vision OCR"
    )

    @Argument(help: "Path to image file to read text from")
    var filePath: String
    
    @Flag(help: "Recognition level to accurate, default is fast")
    var accurate = false
    
    @Flag(help: "Use language correction")
    var languageCorrection = false
    
    @Flag(help: "Use single line output - works only if not using JSON output")
    var singleLineOutput = false
    
    @Flag(help: "Outputs JSON object with boudning box information. This ignores --single-line-output")
    var json = false
    
    func validate() throws {
        guard !filePath.isEmpty else {
            throw ValidationError("'<filePath>' must be defined.")
        }
    }
    
    func run() {
        
        let recognizer = OCR(
            filePath: filePath,
            accurate: accurate,
            languageCorrection: languageCorrection,
            singleLineOutput: singleLineOutput,
            json: json
        )
        recognizer.perform()
    
        if recognizer.error != nil {
            print(recognizer.error!.localizedDescription)
            return
        }
    
        guard let result = recognizer.result() else {
            print("Unknown error")
            return
        }
    
        print(result)
    }
}

OCRCli.main()
