/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains the object recognition view controller for the Breakfast Finder.
*/

import UIKit
import AVFoundation
import Vision

let audioIDObjectMapping: [String:Int] = [
    "person" : 2,
    "bottle" : 3,
    "chair"  : 4,
    "laptop" : 5,
]

class DrawingView: UIView {
    
    var heatmap: Array<Array<Double>>? = nil {
        didSet {
            DispatchQueue.main.async {
                self.setNeedsDisplay()
            }
        }
    }

    override func draw(_ rect: CGRect) {
    
        if let ctx = UIGraphicsGetCurrentContext() {
            
            ctx.clear(rect);
            
            guard let heatmap = self.heatmap else { return }
            
            let size = self.bounds.size
            let heatmap_w = heatmap.count
            let heatmap_h = heatmap.first?.count ?? 0
            let w = size.width / CGFloat(heatmap_w)
            let h = size.height / CGFloat(heatmap_h)
            
            for j in 0..<heatmap_h {
                for i in 0..<heatmap_w {
                    let value = heatmap[i][j]
                    var alpha: CGFloat = CGFloat(value)
                    if alpha > 1 {
                        alpha = 1
                    } else if alpha < 0 {
                        alpha = 0
                    }
                    
                    let rect: CGRect = CGRect(x: CGFloat(i) * w, y: CGFloat(j) * h, width: w, height: h)
                    
                    // gray
                    let color: UIColor = UIColor(white: 1-alpha, alpha: 1)
                    
                    let bpath: UIBezierPath = UIBezierPath(rect: rect)
                    
                    color.set()
                    bpath.fill()
                }
            }
        }
    }
}


class VisionObjectRecognitionViewController: ViewController {
    
    private var detectionOverlay: CALayer! = nil
    private var depthOverlay: CALayer! = nil
    let audioEngine = AudioEngine()
    var timer: Timer?
    
    static var latestCoordinates: [[Float32]] = []
    static var latestTotalItems: Int = 0
    static var latestItemLabelsStr: String = ""

    var drawingView: DrawingView = {
       let map = DrawingView()
        map.contentMode = .scaleToFill
        map.backgroundColor = .blue
        map.autoresizesSubviews = true
        map.clearsContextBeforeDrawing = true
        map.isOpaque = true
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()

    
    // Vision parts
    private var requests = [VNRequest]()
        
    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        
        guard let modelURL = Bundle.main.url(forResource: "ObjectDetector", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        
        guard let depthModelURL = Bundle.main.url(forResource: "FCRN", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }

        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let depthModel = try! VNCoreMLModel(for: MLModel(contentsOf: depthModelURL))

            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                        self.drawVisionRequestResults(results)
                    }
                })
            })
            
            let depthRecognition = VNCoreMLRequest(model: depthModel, completionHandler: { (request, error) in
                    // perform all the UI updates on the main queue
                    if let results = request.results as? [VNCoreMLFeatureValueObservation],
                        let heatmap = results.first?.featureValue.multiArrayValue {

                        let (convertedHeatmap, convertedHeatmapInt) = self.convertTo2DArray(from: heatmap)
                        DispatchQueue.main.async { [weak self] in
                            self?.drawingView.heatmap = convertedHeatmap
                            let average = Float32(convertedHeatmapInt.joined().reduce(0, +))/Float32(20480)
//                            print(average)
                        }
                    } else {
                        fatalError("Model failed to process image")
                    }
            })
            
            depthRecognition.imageCropAndScaleOption = .scaleFill
                        
            self.requests = [objectRecognition, depthRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
        
        return error
    }
    
    func drawVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        VisionObjectRecognitionViewController.latestTotalItems = 0
        VisionObjectRecognitionViewController.latestCoordinates = []
        VisionObjectRecognitionViewController.latestItemLabelsStr = ""
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
            
            var newBoundingBox = CGRect(x: objectObservation.boundingBox.midX, y: objectObservation.boundingBox.midY, width: objectObservation.boundingBox.width, height: objectObservation.boundingBox.height)
            
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            let width = bufferSize.width
            let height = bufferSize.height
            let x = objectObservation.boundingBox.midX * 2 - 1.0
            let y = objectObservation.boundingBox.midY
            let normalizedX: Int = Int(x/width * 128)
            let normalizedY: Int = Int(y/height * 160)
            
            guard let depth = drawingView.heatmap?[normalizedY][normalizedX] else {
                continue
            }
            if (topLabelObservation.identifier == "chair") {
                print("depth: \(depth)")
                print("midX: \(x)")
                print("midY: \(y)")
            }
            
            let areaOfBox = 
            
            let objectSound = audioIDObjectMapping[topLabelObservation.identifier, default: 1]
            
            let newObjectCoords = [Float32(x),
             Float32(y),
             Float32(depth),
             Float32(objectSound)]

            VisionObjectRecognitionViewController.latestCoordinates.append(newObjectCoords)
            
            VisionObjectRecognitionViewController.latestTotalItems+=1
            //print(topLabelObservation.identifier)
            //print(type (of: topLabelObservation.identifier))
            VisionObjectRecognitionViewController.latestItemLabelsStr+=topLabelObservation.identifier
            VisionObjectRecognitionViewController.latestItemLabelsStr+=", "
        
            //print(VisionObjectRecognitionViewController.latestItemLabels)
            
            
//            print("Detected Object: \(topLabelObservation.identifier)")
//            print("midX: \(objectObservation.boundingBox.midX)")
//            print("midY: \(objectObservation.boundingBox.midY)")
            
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            
            let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                            identifier: topLabelObservation.identifier,
                                                            confidence: topLabelObservation.confidence)
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
        }
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let exifOrientation = exifOrientationFromDeviceOrientation()
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    func setupTimer() {
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
    }
    
    @objc func timerFired() {
        // This method will be called every 2 seconds
        for (index, object) in VisionObjectRecognitionViewController.latestCoordinates.enumerated() {
            audioEngine.addNodeAndPlay(with: VisionObjectRecognitionViewController.latestCoordinates[index][0], y: VisionObjectRecognitionViewController.latestCoordinates[index][1], z: VisionObjectRecognitionViewController.latestCoordinates[index][2], distance: VisionObjectRecognitionViewController.latestCoordinates[index][2], type: Int(VisionObjectRecognitionViewController.latestCoordinates[index][3]) as NSNumber)

        }

    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    override func setupAVCapture() {
        super.setupAVCapture()
        
        // setup Vision parts
        setupLayers()
        updateLayerGeometry()
        setupVision()
        setupTimer()
        audioEngine.setupAudio()
        
//        fcrnLayer = fcrnView.layer
//        fcrnLayer.addSublayer(drawingView.layer)
        fcrnView.addSubview(drawingView)
        
        // start the capture
        startCaptureSession()
    }
    
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: yoloLayer.bounds.width,
                                         height: yoloLayer.bounds.height)
        detectionOverlay.position = CGPoint(x: yoloLayer.bounds.midX, y: yoloLayer.bounds.midY)
        
        yoloLayer.addSublayer(detectionOverlay)
        
//        fcrnLayer = fcrnView.layer
//        fcrnLayer.addSublayer(drawingView.layer)
    }
    
    func updateLayerGeometry() {
        let bounds = yoloLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
        
    }
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence:  %.2f", confidence))
        let largeFont = UIFont(name: "Helvetica", size: 24.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
    
}

extension ViewController {
    func convertTo2DArray(from heatmaps: MLMultiArray) -> (Array<Array<Double>>, Array<Array<Int>>) {
        guard heatmaps.shape.count >= 3 else {
            print("heatmap's shape is invalid. \(heatmaps.shape)")
            return ([], [])
        }
        let _/*keypoint_number*/ = heatmaps.shape[0].intValue
        let heatmap_w = heatmaps.shape[1].intValue
        let heatmap_h = heatmaps.shape[2].intValue
        
        var convertedHeatmap: Array<Array<Double>> = Array(repeating: Array(repeating: 0.0, count: heatmap_w), count: heatmap_h)
        
        var minimumValue: Double = Double.greatestFiniteMagnitude
        var maximumValue: Double = -Double.greatestFiniteMagnitude
        
        for i in 0..<heatmap_w {
            for j in 0..<heatmap_h {
                let index = i*(heatmap_h) + j
                let confidence = heatmaps[index].doubleValue
                guard confidence > 0 else { continue }
                convertedHeatmap[j][i] = confidence
                
                if minimumValue > confidence {
                    minimumValue = confidence
                }
                if maximumValue < confidence {
                    maximumValue = confidence
                }
            }
        }
        
        let minmaxGap = maximumValue - minimumValue
        
        for i in 0..<heatmap_w {
            for j in 0..<heatmap_h {
                convertedHeatmap[j][i] = (convertedHeatmap[j][i] - minimumValue) / minmaxGap
            }
        }
        
        var convertedHeatmapInt: Array<Array<Int>> = Array(repeating: Array(repeating: 0, count: heatmap_w), count: heatmap_h)
        for i in 0..<heatmap_w {
            for j in 0..<heatmap_h {
                if convertedHeatmap[j][i] >= 0.5 {
                    convertedHeatmapInt[j][i] = Int(1)
                } else {
                    convertedHeatmapInt[j][i] = Int(0)
                }
            }
        }
        
        return (convertedHeatmap,  convertedHeatmapInt)
    }
}
