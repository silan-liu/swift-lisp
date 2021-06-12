//
//  Eval.swift
//  SwiftLisp
//
//  Created by liusilan on 2021/6/12.
//

import Foundation

// 内置方法
enum Builtins: String {
    case quote, car, cdr, equal, atom, cond, lambda, defun, list, println, eval
    
    /// 是否需要跳过计算，留给方法自行计算
    /// - Parameter atom: 原子值
    /// - Returns: 不需要计算返回 true
    static func shouldSkip(_ atom: String) -> Bool {
        return atom == Builtins.quote.rawValue
            || atom == Builtins.lambda.rawValue
            || atom == Builtins.defun.rawValue
            || atom == Builtins.cond.rawValue
    }
}

extension SExpr {
    
    /// 计算表达式的值，locals 与 values 是一一对应关系
    /// - Parameters:
    ///   - locals: 变量名
    ///   - values: 变量对应的值
    /// - Returns: 结果
    func eval(with locals: [SExpr]? = nil, for values: [SExpr]? = nil) -> SExpr? {
        var node = self
        
        switch node {
        case .Atom:
            return evalVariable(node, with: locals, for: values)
            
        case var .List(elements):
            var skip = false
            
            // 方法调用，是否需要计算值
            if elements.count > 1, case let .Atom(value) = elements[0] {
                skip = Builtins.shouldSkip(value)
            }
            
            if !skip {
                // 计算表达式的值
                elements = elements.compactMap({ expr in
                    return expr.eval(with: locals, for: values)
                })
            }
            
            node = .List(elements)
            
            // 方法调用
            if elements.count > 0, case let .Atom(value) = elements[0] {
                // 先找自定义方法，再找内置方法
                if let f = localContext[value] ?? defaultEnvironment[value] {
                    return f(node, locals, values)
                }
            }
            
            // 非方法调用，返回本身
            return node
        }
    }
    
    
    /// 计算变量的值
    /// - Parameters:
    ///   - v: 表达式
    ///   - locals: 变量名 [x,y]
    ///   - values: 变量对应的值 [1,2]
    /// - Returns: 结果
    func evalVariable(_ v: SExpr, with locals: [SExpr]? = nil, for values: [SExpr]? = nil) -> SExpr {
        guard let locals = locals, let values = values else {
            return v
        }
        
        // 如果 v 在 locals 中，则取对应的值
        if locals.contains(v) {
            guard let index = locals.firstIndex(of: v) else { return v }
            return values[index]
        }
        
        return v
    }
}

// 方法定义
// 第一个参数为传入的符号值，第二个为变量，第三个为变量对应的值
// 第二、三个参数只有在 lambda 和 defun 才有值
//
// lambda 为匿名函数：((lambda (v1 ... vn) e) e1 ... en)，v1 ... vn 将使用对应 e1 .. en 的值，再来计算 e 的值
// expr = "( (lambda (x y) (atom x)) a b)"
// 自定义函数 test：(defun test(v1 ... vn) e)
// expr = "(defun ff (x) (cond ((atom x) x) (true (ff (car x)))))"

public typealias Function = (SExpr, [SExpr]?, [SExpr]?) -> SExpr

// 自定义方法 map，key 为方法名，value 是方法
public var localContext = [String: Function]()

// 内置方法定义
private var defaultEnvironment: [String: Function] = {
    
    var env : [String: Function] = [:]
    
    // quote
    // (quote e) -> e
    // params = .List([quote, e])
    env[Builtins.quote.rawValue] = { params, vars, values in
        // 只有两个参数
        guard case let .List(parameters) = params, parameters.count == 2 else {
            return .List([])
        }
        
        return parameters[1]
    }
    
    // (car(A B))，丢弃第一个元素，返回剩余元素列表
    // params = (car(A B))
    env[Builtins.car.rawValue] = { params, vars, values in
        guard case let .List(parameters) = params, parameters.count == 2 else {
            return .List([])
        }
        
        // 第二个参数是传入的列表值
        guard case let .List(elements) = parameters[1], elements.count > 0 else {
            return .List([])
        }
        
        let result = SExpr.List(Array(elements.dropFirst()))
        
        print("car: \(result)")
        
        return result
    }
    
    // defun
    // (defun test(x y) e)
    // params = (defun test(x y) e)
    // (test (a b))
    env[Builtins.defun.rawValue] = { params, vars, values in
        // 有 4 个参数，defun、方法名test、vars 列表、e
        guard case let .List(parameters) = params, parameters.count == 4 else {
            return .List([])
        }
        
        // 提取方法名
        guard case let .Atom(funName) = parameters[1] else {
            return .List([])
        }
        
        // 提取 vars 列表
        guard case let .List(varList) = parameters[2] else {
            return .List([])
        }
        
        // 方法体
        let funcBody = parameters[3]
        
        // 定义方法，进行包装
        let f: Function = { params, vars, values in
            guard case var .List(p) = params else {
                return .List([])
            }
            
            // 去掉调用方法名
            p = Array(p.dropFirst())
            
            // p 是调用函数时传入实际的值，将 varList 用 p 中的值进行替换
            // 比如 test(x y)，调用时 test(1 2)，那么在计算方法体表达式时 x 被替换为 1，y 被替换 2
            if let result = funcBody.eval(with: varList, for: p) {
                return result
            }
            
            return .List([])
        }
        
        // 保存本地方法
        localContext[funName] = f
        return .List([])
    }
    
    env[Builtins.lambda.rawValue] = { params, vars, values in
        // 有 3 个参数，defun、vars 列表、e
        guard case let .List(parameters) = params, parameters.count == 3 else {
            return .List([])
        }
        
        // 提取 vars 列表
        guard case let .List(varList) = parameters[1] else {
            return .List([])
        }
        
        // 方法体
        let funcBody = parameters[2]
        
        // 临时方法名
        let funName = "tmp$" + String(arc4random_uniform(UInt32.max))
        
        // 定义方法，进行包装
        let f: Function = { params, vars, values in
            guard case var .List(p) = params else {
                return .List([])
            }
            
            // 执行完后，删除临时方法
            localContext[funName] = nil
            
            // 去掉调用方法名
            p = Array(p.dropFirst())
            
            // p 是调用函数时传入实际的值，将 varList 用 p 中的值进行替换
            // 比如 test(x y)，调用时 test(1 2)，那么在计算方法体表达式时 x 被替换为 1，y 被替换 2
            if let result = funcBody.eval(with: varList, for: p) {
                return result
            }
            
            return .List([])
        }
        
        // 保存本地方法
        localContext[funName] = f
        
        // 返回方法名，用于在 eval 时调用
        return .Atom(funName)
    }
    
    // (eval expr)
    env[Builtins.eval.rawValue] = { params, vars, values in
        guard case let .List(parameters) = params, parameters.count == 2 else {
            return .List([])
        }
        
        let expr = parameters[1]
        return expr.eval(with: vars, for: values)!
    }
    
    return env
}()
