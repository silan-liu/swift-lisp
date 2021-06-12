//
//  Core.swift
//  SwiftLisp
//
//  Created by liusilan on 2021/6/12.
//

import Foundation

// 表达式定义
public enum SExpr {
    case Atom(String)
    case List([SExpr])
}

// 比较 SExpr 是否相等
extension SExpr: Equatable {
    public static func ==(lhs: SExpr, rhs: SExpr) -> Bool {
        switch (lhs, rhs) {
        
        // 都为 atom
        case let (.Atom(l), .Atom(r)):
            return l == r
            
        case let (.List(l), .List(r)):
            // 长度不等
            guard l.count == r.count else {
                return false
            }
            
            // 逐个遍历比较
            for (idx, e) in l.enumerated() {
                if e != r[idx] {
                    return false
                }
            }
            
            return true
            
        default:
            return false
        }
    }
}

extension SExpr: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .Atom(value):
            return "\(value)"
            
        case let .List(expr):
            var desc = "("
            
            for (idx, e) in expr.enumerated() {
                desc  += "\(e)"

                if idx != expr.count - 1 {
                    desc  += " "
                }
            }

            desc += ")"
            
            return desc
        }
    }
}

extension SExpr {
    
    enum Token {
        // 左括号
        case pOpen
        
        // 右括号
        case pClose
        
        // 字符串
        case text(String)
    }
    
    public static func read(_ expr: String) -> SExpr {
        let tokens = tokenize(expr)
        let (_, expr) = parse(tokens: tokens)
        
        return expr ?? .List([])
    }
        
    /// 将字符串解析为 token
    /// - Parameter expr: 输入表达式
    /// - Returns: token 列表
    /// - "A (B)" -> [.text("a"), .pOpen, .text("B"), .pClose]
    static func tokenize(_ expr: String) -> [Token] {
        var res = [Token]()
        var tmpText  = ""
        
        for c in expr {
            switch c {
            case "(":
                // A (B C)，遍历到 (，A 作为一个 token
                if tmpText != "" {
                    res.append(.text(tmpText))
                    tmpText = ""
                }
                
                res.append(.pOpen)
                
            case ")":
                // (B)，遍历到 )，B 作为一个 token
                if tmpText != "" {
                    res.append(.text(tmpText))
                    tmpText = ""
                }
                
                res.append(.pClose)
                
            case " ":
                // A B，遍历到到 A 后面的空格，A 作为一个 token
                if tmpText != "" {
                    res.append(.text(tmpText))
                    tmpText = ""
                }
                
            default:
                tmpText.append(c)
            }
        }
        
        return res
    }
    
    /// 将 node 节点添加到 list，如果 list 为空，则直接返回 node
    /// - Parameters:
    ///   - list: list
    ///   - node: 待添加节点
    /// - Returns: 表达式
    static func appendNode(list: SExpr?, node: SExpr) -> SExpr {
        // 假如 list 是列表，将 node 添加到列表中
        if list != nil, case var .List(elements) = list! {
            elements.append(node)
            return .List(elements)
        } else {
            return node
        }
    }
        
    /// 解析 token 生成 SExpr 结构
    /// - Parameters:
    ///   - tokens: token 列表
    ///   - node: 父节点
    /// - Returns: (剩余 token，表达式)
    static func parse(tokens: [Token], parentNode: SExpr? = nil) -> (remaining: [Token], expr: SExpr?) {
        var i = 0
        var parentNode = parentNode
        var remainTokens = tokens
        
        while remainTokens.count > 0 {
            let token = remainTokens[i]
            
            switch token {
            // 列表开始
            case .pOpen:
                // ( 之后的 token 列表
                let tokenList = Array(remainTokens[(i+1)..<remainTokens.count])
                
                // 空列表
                let rootNode = SExpr.List([])
                
                // 递归调用，返回与之匹配 ) 的子节点表达式
                let (remainList, node) = parse(tokens: tokenList, parentNode: rootNode)
                assert(node != nil)
                
                // 添加子节点到列表
                parentNode = appendNode(list: parentNode, node: node!)
                
                // 更新变量
                remainTokens = remainList
                i = 0
                
            case .pClose:
                // 匹配的右 )，直接返回剩余token + 子节点
                let tokenList = Array(remainTokens[(i+1)..<remainTokens.count])

                return (tokenList, parentNode)
                
            case let .text(value):
                // 添加到父节点
                parentNode = appendNode(list: parentNode, node: SExpr.Atom(value))
            }
            
            i += 1
        }
        
        return ([], parentNode)
    }
}

// 可直接通过字符串初始化为 SExpr
// let expr: SExpr = "(A B C)"
extension SExpr: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = SExpr.read(value)
    }
    
    public init(unicodeScalarLiteral value: String) {
        self.init(stringLiteral: value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(stringLiteral: value)
    }
}
