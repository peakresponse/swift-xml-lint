import CLibxml2

func xpathLocation(for node: UnsafeMutablePointer<_xmlNode>) -> String {
    var components: [String] = []
    var current: UnsafeMutablePointer<_xmlNode>? = node
    while let n = current, n.pointee.type == XML_ELEMENT_NODE {
        guard let rawName = n.pointee.name else { break }
        let name = String(cString: rawName)
        let (index, total) = siblingIndex(of: n)
        components.append(total > 1 ? "\(name)[\(index)]" : name)
        current = n.pointee.parent
    }
    return "/" + components.reversed().joined(separator: "/")
}

func xpathLocation(forLine targetLine: Int, in doc: xmlDocPtr) -> String {
    guard let root = xmlDocGetRootElement(doc) else { return "" }
    var best: UnsafeMutablePointer<_xmlNode>? = nil
    var bestLine = 0
    walkNodes(root) { node in
        let line = Int(xmlGetLineNo(node))
        if line <= targetLine && line >= bestLine {
            bestLine = line
            best = node
        }
    }
    return best.map { xpathLocation(for: $0) } ?? ""
}

private func siblingIndex(of node: UnsafeMutablePointer<_xmlNode>) -> (index: Int, total: Int) {
    guard let rawName = node.pointee.name else { return (1, 1) }
    var index = 1
    var prev = node.pointee.prev
    while let p = prev {
        if p.pointee.type == XML_ELEMENT_NODE, let pName = p.pointee.name, strcmp(pName, rawName) == 0 {
            index += 1
        }
        prev = p.pointee.prev
    }
    var total = index
    var next = node.pointee.next
    while let n = next {
        if n.pointee.type == XML_ELEMENT_NODE, let nName = n.pointee.name, strcmp(nName, rawName) == 0 {
            total += 1
        }
        next = n.pointee.next
    }
    return (index, total)
}

private func walkNodes(_ node: UnsafeMutablePointer<_xmlNode>, _ visit: (UnsafeMutablePointer<_xmlNode>) -> Void) {
    var current: UnsafeMutablePointer<_xmlNode>? = node
    while let n = current {
        if n.pointee.type == XML_ELEMENT_NODE {
            visit(n)
            if let child = n.pointee.children {
                walkNodes(child, visit)
            }
        }
        current = n.pointee.next
    }
}
