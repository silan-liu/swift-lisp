//
//  main.swift
//  SwiftLisp
//
//  Created by liusilan on 2021/6/12.
//

import Foundation


//var expr: SExpr = "(defun ff (x) (car x)"
//_ = expr.eval()
//
//expr = "(ff (quote (a b c)))"
//print("eval:\(expr.eval()!)")  //a

// 在 eval 时，判断是否需要计算表达式的值，因此第一次会将 (lambda (x) (car x)) 进行计算，调用到 lambda 定义方法，返回出临时函数的方法名。
var expr3: SExpr = "((lambda (x) (car x)) (c a b))"
print("eval:\(expr3.eval()!)")

//var expr1: SExpr = "(quote ((a b) c))"
//print("eval:\(expr1.eval()!)")  //a
//
