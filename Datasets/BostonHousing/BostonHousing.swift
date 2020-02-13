// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Python
import TensorFlow

public struct BostonHousing {
    public let trainPercentage:Float = 0.8
    public let numRecords: Int
    public let numColumns: Int
    public let numTrainRecords: Int
    public let numTestRecords: Int
    public let xTrain: Tensor<Float>
    public let yTrain: Tensor<Float>
    public let xTest: Tensor<Float>
    public let yTest: Tensor<Float>

    /// Use Python and shell calls to download and extract the Boston Housing dataset if not already done
    /// This can fail for many reasons (e.g. lack of `wget` or an Internet connection)
    static func downloadBostonHousingIfNotPresent() -> String {
        let subprocess = Python.import("subprocess")
        let path = Python.import("os.path")
        let filepath = "./tabular-batches-py"
        let isdir = Bool(path.isdir(filepath))!
        if !isdir {
            print("Downloading Boston Housing data...")
            let command = """
                mkdir tabular-batches-py
                cd tabular-batches-py
                wget -nv -O housing.data https://archive.ics.uci.edu/ml/machine-learning-databases/housing/housing.data
                """
            subprocess.call(command, shell: true)
        }

        return try! String(contentsOfFile:"./tabular-batches-py/housing.data", encoding: String.Encoding.utf8)
    }
    
    public init() {
        let data = BostonHousing.downloadBostonHousingIfNotPresent()

        // Convert Space Separated CSV with no Header
        let dataRecords: [[Float]] = data.split(separator: "\n").map{ String($0).split(separator: " ").compactMap{ Float(String($0)) } }

        let numRecords = dataRecords.count
        let numColumns = dataRecords[0].count

        let dataFeatures = dataRecords.map{ Array($0[0..<numColumns-1]) }
        let dataLabels = dataRecords.map{ Array($0[(numColumns-1)...]) }

        self.numRecords = numRecords
        self.numColumns = numColumns
        self.numTrainRecords = Int(ceil(Float(numRecords) * trainPercentage))
        self.numTestRecords = numRecords - numTrainRecords

        let xTrain = Array(Array(dataFeatures[0..<numTrainRecords]).joined())
        let xTest = Array(Array(dataFeatures[numTrainRecords...]).joined())
        let yTrain = Array(Array(dataLabels[0..<numTrainRecords]).joined())
        let yTest = Array(Array(dataLabels[numTrainRecords...]).joined())

        let xTrainDeNorm = Tensor<Float>(xTrain).reshaped(to: TensorShape([numTrainRecords, numColumns-1]))
        let xTestDeNorm = Tensor<Float>(xTest).reshaped(to: TensorShape([numTestRecords, numColumns-1]))

        // Normalize
        let mean = xTrainDeNorm.mean(alongAxes: 0)
        let std = xTrainDeNorm.standardDeviation(alongAxes: 0)

        self.xTrain = (xTrainDeNorm - mean)/std
        self.xTest = (xTestDeNorm - mean)/std
        self.yTrain = Tensor<Float>(yTrain).reshaped(to: TensorShape([numTrainRecords, 1]))
        self.yTest = Tensor<Float>(yTest).reshaped(to: TensorShape([numTestRecords, 1]))
    }
}