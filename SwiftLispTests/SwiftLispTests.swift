//
//  SwiftLispTests.swift
//  SwiftLispTests
//
//  Created by liusilan on 2021/6/13.
//

import XCTest
import Foundation
@testable import SwiftLisp

class SwiftLispTests: XCTestCase {

    func eval(_ expr:String) -> SExpr {
        return SExpr(stringLiteral:expr).eval()!
    }
        
    func testBasic() {
        
        // car
        XCTAssertEqual(eval("(car ( cdr  ( quote (1 2 \"aaaa\"   4 5 true 6 7 () ))))"), .Atom("2"))
        XCTAssertEqual(eval("((car (quote (atom))) A)"), .Atom("true"))
        XCTAssertEqual(eval("((car (quote (atom))) ())"), .List([]))
        
        // cdr
        XCTAssertEqual(eval("(cdr (quote (1 2 3)))"), .List([.Atom("2"), .Atom("3")]))
        
        // quote
        XCTAssertEqual(eval("(quote (quote(quote (1 2))))"), .List([ .Atom("quote"), .List([.Atom("quote"), .List([.Atom("1"), .Atom("2")])])]))
        XCTAssertEqual(eval("(quote (A B C))"), .List([.Atom("A"), .Atom("B"), .Atom("C")]))
        
        // equal
        XCTAssertEqual(eval("(equal A A)"), .Atom("true"))
        XCTAssertEqual(eval("(equal () ())"), .Atom("true"))
        XCTAssertEqual(eval("(equal true true)"), .Atom("true"))
        XCTAssertEqual(eval("(equal (quote true) (atom A))"), .Atom("true"))
        XCTAssertEqual(eval("(equal A ())"), .List([]))
        
        // qutote
        XCTAssertEqual(eval("(quote A)"), .Atom("A"))
        XCTAssertEqual(eval("(quote 1)"), .Atom("1"))
        
        // atom
        XCTAssertEqual(eval("(atom A)"), .Atom("true"))
        XCTAssertEqual(eval("(atom (quote (A B)))"), .List([]))
        
        // cond
        XCTAssertEqual(eval("(cond ((atom (quote A)) (quote B)) ((quote true) (quote C)))"), .Atom("B"))
        
        // eavl
        XCTAssertEqual(eval("(eval (quote (atom (quote A)))"), .Atom("true"))
    }
    
     func testFunctionDefinitions() {
        // lambda
         XCTAssertEqual(eval("( (lambda (x y) (atom x)) () b)"), .List([]))
         XCTAssertEqual(eval("( (lambda (x y) (atom x)) a b)"), .Atom("true"))
        
        // defun
         XCTAssertEqual(eval("(defun TEST (x y) (atom x))"), .List([]))
         XCTAssertEqual(eval("(TEST a b)"), .Atom("true"))
         XCTAssertEqual(eval("(TEST (quote (1 2 3)) b)"), .List([]))
        
        // defun
        XCTAssertEqual(eval("(defun ff (x) (cond ((atom x) x) (true (ff (car x)))))"), .List([])) //Recoursive function
        XCTAssertEqual(eval("(ff (quote ((a b) c)))"), .Atom("a"))
     }

    func testAbbreviations() {
        XCTAssertEqual(eval("(defun null (x) (equal x ()))"), .List([]))
        XCTAssertEqual(eval("(defun cadr (x) (car (cdr x)))"), .List([]))
        XCTAssertEqual(eval("(defun cddr (x) (cdr (cdr x)))"), .List([]))
        XCTAssertEqual(eval("(defun and (p q) (cond (p q) (true ())))"), .List([]))
        XCTAssertEqual(eval("(defun or (p q) (cond (p p) (q q) (true ())) )"), .List([]))
        XCTAssertEqual(eval("(defun not (p) (cond (p ()) (true p))"), .List([]))
        XCTAssertEqual(eval("(defun alt (x) (cond ((or (null x) (null (cdr x))) x) (true (cons (car x) (alt (cddr x))))))"), .List([]))
        XCTAssertEqual(eval("(defun subst (x y z) (cond ((atom z) (cond ((equal z y) x) (true z))) (true (cons (subst x y (car z)) (subst x y (cdr z))))))"), .List([]))
        XCTAssertEqual(eval("(null a)"), .List([]))
        XCTAssertEqual(eval("(null ())"), .Atom("true"))
        XCTAssertEqual(eval("(and a b)"), .Atom("b"))
        XCTAssertEqual(eval("(or a ())"), .Atom("a"))
        XCTAssertEqual(eval("(not a)"), .List([]))
        XCTAssertEqual(eval("(alt (quote (A B C D E))"), .List([.Atom("A"), .Atom("C"), .Atom("E")]))
    }
}
