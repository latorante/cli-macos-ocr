//
//  OCR.swift
//  
//
//  Created by Martin Picha on 28/9/22.
//

import Foundation
import Cocoa
import Vision

//
// JSON Response Type
//
struct Response: Codable {
    let text: String?
    let box: [Int]?
    let confidence: Double?
}

//
// Error Messages
//
enum OCRError: LocalizedError {
    case loadImageFailed(file: String)
    case convertImageFailed(file: String)
    case performFailed(error: Error)
    case recognizeFailed(error: Error)

    var errorDescription: String? {
        switch self {
        case .loadImageFailed(let file):
            return "load image failed. (\(file))"
        case .convertImageFailed(let file):
            return "convert image failed. (\(file))"
        case .performFailed(error: let error):
            return "perform failed. (\(error))"
        case .recognizeFailed(error: let error):
            return "recognize failed. (\(error))"
        }
    }
}

//
// Helper for quick Object => JSON string conversion
//
public func convertObjectIntoJsonString<T: Codable>(_ data: T) -> String {
    do {
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(data)
        let encodedJsonString = String(data: encodedData, encoding: .utf8)
        return encodedJsonString!
    } catch {
        // Nothing to see here
        return ""
    }
}


class OCR {
    
    var filePath: String
    var accurate = false
    var languageCorrection = false
    var singleLineOutput = false
    var json = false
    
    var imageWidth: Int
    var imageHeight: Int
    
    var error: Error?
    var observations: [VNRecognizedTextObservation]?

    init(
        filePath: String,
        accurate: Bool,
        languageCorrection: Bool,
        singleLineOutput: Bool,
        json: Bool
    ) {
        self.filePath = filePath
        self.accurate = accurate
        self.languageCorrection = languageCorrection
        self.singleLineOutput = singleLineOutput
        self.json = json
        self.imageWidth = 0
        self.imageHeight = 0
    }

    func perform() {
       
        guard let image = NSImage(contentsOfFile: self.filePath) else {
            self.error = OCRError.loadImageFailed(file: self.filePath)
            return
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            self.error = OCRError.convertImageFailed(file: self.filePath)
            return
        }

        self.imageWidth = cgImage.width
        self.imageHeight = cgImage.height
        
        let request = VNRecognizeTextRequest(completionHandler: self.requestCompletionHandler)
        request.recognitionLevel = accurate ? VNRequestTextRecognitionLevel.accurate : VNRequestTextRecognitionLevel.fast
        if #available(macOS 11, *) {
            request.revision = VNRecognizeTextRequestRevision2
        } else {
            request.revision = VNRecognizeTextRequestRevision1
        }
        request.usesLanguageCorrection = languageCorrection
        request.recognitionLanguages = ["en-US", "cs-CZ"]

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            self.error = OCRError.performFailed(error: error)
        }
    }

    func requestCompletionHandler(request: VNRequest, error: Error?) {
        if error != nil {
            self.error = OCRError.recognizeFailed(error: error!)
            return
        }
        self.observations = request.results as? [VNRecognizedTextObservation]
    }

    func result() -> String? {
        if self.error != nil {
            return nil
        }
        // Json object with information about each line
        if(self.json){
            var lines: [Response] = []
            if let observations = self.observations {
                for observation in observations {
                    let boudingBox = VNImageRectForNormalizedRect(observation.boundingBox, self.imageWidth, self.imageHeight)
                    lines.append(
                        Response(
                            text: observation.topCandidates(1).first?.string ?? "",
                            box: [
                                Int(boudingBox.origin.x),
                                Int(boudingBox.origin.y),
                                Int(boudingBox.size.width),
                                Int(boudingBox.size.height)
                            ],
                            confidence: Double(observation.confidence)
                        )
                    )
                }
            }
            return convertObjectIntoJsonString(lines)
        } else {
            var lines: [String] = []
            if let observations = self.observations {
                for observation in observations {
                    let text = observation.topCandidates(1).first?.string ?? ""
                    lines.append(text)
                }
            }
            return lines.joined(separator: singleLineOutput ? "" : "\n")
        }
    }
}
