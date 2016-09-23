//
//  Math.swift
//  RNG Bible
//
//  Created by Jonathan Gerber on 6/19/15.
//  Copyright (c) 2015 Malingo Studios. All rights reserved.
//

import Foundation

class Math {
    
    //Calculates the factorial of a given number
    static func factorial(number:Int) -> Float {
        if number == 0 { return 1 }
        
        let num = number + 1
        return tgammaf(Float(num));
    }
    
    //Calculates the binomial probability
    static func binomial(numTargets:Int, numHits:Int, numHitsDesired:Int) -> Float {
        
        let combination:Float = factorial(numHits) / (factorial(numHitsDesired) * factorial(numHits - numHitsDesired))
        let probability:Float = 1.0 / Float(numTargets)
        return Float(combination * Float(pow(probability, Float(numHitsDesired))) * Float(pow(1-probability, Float((numHits - numHitsDesired)))))
    }
    
    static func cumulativeBinomial(numTargets:Int, numHits:Int, numHitsDesired:Int) -> Float {
        var retVal = binomial(numTargets, numHits: numHits, numHitsDesired: numHitsDesired)
        for (var i = numHitsDesired + 1; i <= numHits; i++) {
            let newValue = binomial(numTargets, numHits: numHits, numHitsDesired: i)
            retVal += newValue
        }
        return retVal
    }
    
    //Calculates the binomial probability
    static func hypergeometric(total:Int, totalDesired:Int, numberOfDraws:Int, numberNeeded:Int = 1) -> Float {
        
        //for something like arcane missiles, does this work? i think so. how about flamewaker? dunno
        //total = all health (each minion capped at numOfHits? + min(heroHealth, numOfHits)), //desired = all acceptable hits //numberOfDraws = numHits, number needed = however many to kill desired minion (4, 1, 3, 1)
        
        let firstCombination1 = totalDesired
        let firstCombination2 = numberNeeded
        let firstCombination = factorial(firstCombination1) / (factorial(firstCombination2) * factorial(firstCombination1 - firstCombination2))
        
        let secondCombination1 = total - totalDesired
        let secondCombination2 = numberOfDraws - numberNeeded
        let secondCombination = factorial(secondCombination1) / (factorial(secondCombination2) * factorial(secondCombination1 - secondCombination2))
        
        let thirdCombination1 = total
        let thirdCombination2 = numberOfDraws
        let thirdCombination = factorial(thirdCombination1) / (factorial(thirdCombination2) * factorial(thirdCombination1 - thirdCombination2))

        let numerator = firstCombination * secondCombination
        let denominator = thirdCombination
       
        return numerator / denominator
    }
    
    static func cumulativeHypergeometric(total:Int, totalDesired:Int, numberOfDraws:Int, numberNeeded:Int = 1) -> Float {
        var retVal = hypergeometric(total, totalDesired: totalDesired, numberOfDraws: numberOfDraws, numberNeeded: numberNeeded)
        for (var i = numberNeeded+1; i <= totalDesired; i++) {
            if i <= numberOfDraws {
                let newValue = hypergeometric(total, totalDesired: totalDesired, numberOfDraws: numberOfDraws, numberNeeded: i)
                retVal += newValue
            }
        }
        return retVal
    }
    
    
    //Example scenario:  You have n targets on the board, each with unique number of health points. You have m random shots to destroy a specific target (each shot will hit a random target and reduce its health points by 1).  What is the likelihood that you will destroy the desired target (reduce its health points to 0)?
    //Runs the simulation 50,000 times to get the average likelihood of destroying the desired target.
    func performRandomHitsTest(targets:[[Int]], hits:Int, perHit:Int = 1, desiredTarget:Int) {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            //TODO: allow multiple targets
            var successes = 0
            
            for (var i = 0; i <= 50000; i+=1) {
                var newTargets = targets
                for (var n = 0; n < hits; n+=1) {
                    var targetsAlive = [Int]()
                    for (index, target) in newTargets.enumerate() {
                        if target.count > 0 {
                            targetsAlive.append(index)
                        }
                    }
                    let randomIndex = Int(arc4random_uniform(UInt32(targetsAlive.count)))
                    let randomTarget = targetsAlive[randomIndex]
                    newTargets[randomTarget].removeAtIndex(0)
                    if newTargets[desiredTarget].count == 0 {
                        successes += 1
                        break
                    }
                }
                if (i % 1000 == 0) {
                    let percentage:Float = (Float(successes) / Float(i)) * 100
                    let percentageString = String(format:"%.0f",percentage)
                    print("trials: \(i), successes: \(String(successes)), percentage: \(percentageString)")
                    
                }
            }
        })
    }
}