//
//  KalmanFilterHelper.swift
//  snow-buddy
//
//  Created by Zill-e-Rahim on 4/10/2025.
//

import CoreLocation
import Foundation

class KalmanFilter {
     var q: Double        // process noise
     var r: Double        // measurement noise
     var x: Double = 0.0  // value
     var p: Double = 1.0  // estimation error covariance
     var k: Double = 0.0  // kalman gain
     var isInitialized = false
    
    init(processNoise: Double = 0.125, measurementNoise: Double = 1.0) {
        self.q = processNoise
        self.r = measurementNoise
    }
    
    func filter(_ measurement: Double) -> Double {
        if !isInitialized {
            x = measurement
            isInitialized = true
            return measurement
        }
        
        // prediction update
        p = p + q
        
        // measurement update
        k = p / (p + r)
        x = x + k * (measurement - x)
        p = (1 - k) * p
        
        return x
    }
    
    func reset() {
        isInitialized = false
    }
}
