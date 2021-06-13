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


var expr:SExpr = "(cond ((atom (quote A)) (quote B)) ((quote true) (quote C)))"

print(expr)
dump(expr)
print(expr.eval()!)  //B

expr = "(car ( cdr  ( quote (1 2 \"aaaa\"   4 5 true 6 7 () ))))"
print(expr.eval()!)  //2

expr = "( (lambda (x y) (atom x)) a b)"
print(expr.eval()!)  //true

expr = "(defun ff (x) (cond ((atom x) x) (true (ff (car x)))))"
print(expr.eval()!)
expr = "(ff (quote ((a b) c)))"
print(expr.eval()!)  //a

expr = "(eval (quote (atom (quote A)))"
print(expr.eval()!)  //true

expr = "(defun alt (x) (cond ((or (null x) (null (cdr x))) x) (true (cons (car x) (alt (cddr x))))))"
print(expr.eval()!)
expr = "(alt (quote (A B C D E))"
print(expr.eval()!)
