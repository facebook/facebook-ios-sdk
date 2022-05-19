//
//  LocatedTag.swift
//  Mustache
//
//  Created by Gwendal Roué on 09/07/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

protocol LocatedTag: Tag {
    var templateID: TemplateID? { get }
    var lineNumber: Int { get }
}
