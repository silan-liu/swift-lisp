//
//  main.swift
//  SwiftLisp
//
//  Created by liusilan on 2021/6/12.
//

import Foundation

let expr: SExpr = "(cons (TEST v b) (a c))"
print(expr.eval()!)

var exit = false
while !exit {
    print(">>>", terminator: " ")
    let input = readLine(strippingNewline: true)
    exit = input == "exit"

    if !exit {
        let e = SExpr.read(input!)

        print(e)
        print(e.eval()!)
    }
}
