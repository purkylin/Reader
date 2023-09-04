import Kingdom
import Foundation

let a = 17
let b = 25

let (result, code) = #stringify(a + b)
let tm = #buildTimestamp

// print("The value \(result) was produced by the code \"\(code)\"")

let tt = Date(timeIntervalSince1970: tm)
let zz = #buildTime
print("from timestamp: \(tt), from string: \(zz)")
