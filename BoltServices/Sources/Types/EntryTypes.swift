//
// Copyright (C) 2023 Bolt Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

import BoltUtils

public extension EntryType {

  static let typeDict: [String: EntryType] = {
    return [
      "Snippet": EntryType(
        singular: "Snippet",
        plural: "Snippets",
        sortingOrder: 1,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-gray", in: Bundle.module)
      ),
      "Class": EntryType(
        singular: "Class",
        plural: "Classes",
        sortingOrder: 2,
        aliases: ["cl", "tmplt", "specialization"],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: Bundle.module)
      ),
      "_Struct": EntryType(
        singular: "_Struct",
        plural: "_Structs",
        sortingOrder: 3,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: Bundle.module)
      ),
      "Tag": EntryType(
        singular: "Tag",
        plural: "Tags",
        sortingOrder: 4,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: Bundle.module)
      ),
      "Trait": EntryType(
        singular: "Trait",
        plural: "Traits",
        sortingOrder: 5,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: Bundle.module)
      ),
      "Database": EntryType(
        singular: "Database",
        plural: "Databases",
        sortingOrder: 6,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_green", in: Bundle.module)
      ),
      "Protocol": EntryType(
        singular: "Protocol",
        plural: "Protocols",
        sortingOrder: 7,
        aliases: ["intf"],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: Bundle.module)
      ),
      "Delegate": EntryType(
        singular: "Delegate",
        plural: "Delegates",
        sortingOrder: 8,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_blue", in: Bundle.module)
      ),
      "Interface": EntryType(
        singular: "Interface",
        plural: "Interfaces",
        sortingOrder: 9,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: Bundle.module)
      ),
      "Template": EntryType(
        singular: "Template",
        plural: "Templates",
        sortingOrder: 10,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: Bundle.module)
      ),
      "Actor": EntryType(
        singular: "Actor",
        plural: "Actors",
        sortingOrder: 11,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-purple", in: Bundle.module)
      ),
      "Indirection": EntryType(
        singular: "Indirection",
        plural: "Indirections",
        sortingOrder: 12,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: Bundle.module)
      ),
      "Object": EntryType(
        singular: "Object",
        plural: "Objects",
        sortingOrder: 13,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: Bundle.module)
      ),
      "Schema": EntryType(
        singular: "Schema",
        plural: "Schemas",
        sortingOrder: 14,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: Bundle.module)
      ),
      "Category": EntryType(
        singular: "Category",
        plural: "Categories",
        sortingOrder: 15,
        aliases: ["cat", "Groups", "Pages"],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: Bundle.module)
      ),
      "Collection": EntryType(
        singular: "Collection",
        plural: "Collections",
        sortingOrder: 16,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: Bundle.module)
      ),
      "Framework": EntryType(
        singular: "Framework",
        plural: "Frameworks",
        sortingOrder: 17,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: Bundle.module)
      ),
      "Module": EntryType(
        singular: "Module",
        plural: "Modules",
        sortingOrder: 18,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: Bundle.module)
      ),
      "Library": EntryType(
        singular: "Library",
        plural: "Libraries",
        sortingOrder: 19,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: Bundle.module)
      ),
      "Namespace": EntryType(
        singular: "Namespace",
        plural: "Namespaces",
        sortingOrder: 20,
        aliases: ["ns"],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: Bundle.module)
      ),
      "Package": EntryType(
        singular: "Package",
        plural: "Packages",
        sortingOrder: 21,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: Bundle.module)
      ),
      "Exception": EntryType(
        singular: "Exception",
        plural: "Exceptions",
        sortingOrder: 22,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-pink", in: Bundle.module)
      ),
      "Struct": EntryType(
        singular: "Struct",
        plural: "Structs",
        sortingOrder: 23,
        aliases: ["Data Structures", "struct"],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: Bundle.module)
      ),
      "Type": EntryType(
        singular: "Type",
        plural: "Types",
        sortingOrder: 24,
        aliases: ["tag", "tdef", "Public Types", "Protected Types", "Private Types", "Typedefs", "Package Types", "Data Types"],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: Bundle.module)
      ),
      "Enum": EntryType(
        singular: "Enum",
        plural: "Enums",
        sortingOrder: 25,
        aliases: ["Enumerations", "enum"],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: Bundle.module)
      ),
      "Diagram": EntryType(
        singular: "Diagram",
        plural: "Diagrams",
        sortingOrder: 26,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-purple", in: Bundle.module)
      ),
      "Table": EntryType(
        singular: "Table",
        plural: "Tables",
        sortingOrder: 27,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: Bundle.module)
      ),
      "Query": EntryType(
        singular: "Query",
        plural: "Queries",
        sortingOrder: 28,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-gray", in: Bundle.module)
      ),
      "Component": EntryType(
        singular: "Component",
        plural: "Components",
        sortingOrder: 29,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: Bundle.module)
      ),
      "Constructor": EntryType(
        singular: "Constructor",
        plural: "Constructors",
        sortingOrder: 30,
        aliases: ["Public Constructors"],
        colorResource: BoltColorResource(named: "type-colors/light-dark_brown", in: Bundle.module)
      ),
      "Element": EntryType(
        singular: "Element",
        plural: "Elements",
        sortingOrder: 31,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: Bundle.module)
      ),
      "Resource": EntryType(
        singular: "Resource",
        plural: "Resources",
        sortingOrder: 32,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: Bundle.module)
      ),
      "Directive": EntryType(
        singular: "Directive",
        plural: "Directives",
        sortingOrder: 33,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_green", in: Bundle.module)
      ),
      "Extension": EntryType(
        singular: "Extension",
        plural: "Extensions",
        sortingOrder: 34,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_blue", in: Bundle.module)
      ),
      "Plugin": EntryType(
        singular: "Plugin",
        plural: "Plugins",
        sortingOrder: 35,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: Bundle.module)
      ),
      "Filter": EntryType(
        singular: "Filter",
        plural: "Filters",
        sortingOrder: 36,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: Bundle.module)
      ),
      "Service": EntryType(
        singular: "Service",
        plural: "Services",
        sortingOrder: 37,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: Bundle.module)
      ),
      "Provider": EntryType(
        singular: "Provider",
        plural: "Providers",
        sortingOrder: 38,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: Bundle.module)
      ),
      "Decorator": EntryType(
        singular: "Decorator",
        plural: "Decorators",
        sortingOrder: 39,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-purple", in: Bundle.module)
      ),
      "Method": EntryType(
        singular: "Method",
        plural: "Methods",
        sortingOrder: 40,
        aliases: ["instm", "intfm", "clm", "intfcm", "Class Methods", "Instance Methods", "Public Methods", "Inherited Methods", "Private Methods", "Protected Methods", "instctr", "intfctr", "enumm", "intfsub", "enumcm", "structctr", "structcm", "enumctr", "instsub", "structsub", "structm"],
        colorResource: BoltColorResource(named: "type-colors/light-dark_blue", in: Bundle.module)
      ),
      "Property": EntryType(
        singular: "Property",
        plural: "Properties",
        sortingOrder: 41,
        aliases: ["intfp", "instp", "Protected Properties", "Public Properties", "Inherited Properties", "Private Properties", "structp", "enump", "intfdata", "cldata"],
        colorResource: BoltColorResource(named: "type-colors/light-dark_blue", in: Bundle.module)
      ),
      "Field": EntryType(
        singular: "Field",
        plural: "Fields",
        sortingOrder: 42,
        aliases: ["Data Fields"],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: Bundle.module)
      ),
      "Header": EntryType(
        singular: "Header",
        plural: "Headers",
        sortingOrder: 43,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: Bundle.module)
      ),
      "Response Code": EntryType(
        singular: "Response Code",
        plural: "Response Codes",
        sortingOrder: 44,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-green", in: Bundle.module)
      ),
      "Attribute": EntryType(
        singular: "Attribute",
        plural: "Attributes",
        sortingOrder: 45,
        aliases: ["XML Attributes", "Public Attributes", "Static Public Attributes", "Protected Attributes", "Static Protected Attributes", "Private Attributes", "Static Private Attributes", "Package Attributes", "Static Package Attributes"],
        colorResource: BoltColorResource(named: "type-colors/dark-pink", in: Bundle.module)
      ),
      "Aggregation": EntryType(
        singular: "Aggregation",
        plural: "Aggregations",
        sortingOrder: 46,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-blue", in: Bundle.module)
      ),
      "Association": EntryType(
        singular: "Association",
        plural: "Associations",
        sortingOrder: 47,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-pink", in: Bundle.module)
      ),
      "Index": EntryType(
        singular: "Index",
        plural: "Indexes",
        sortingOrder: 48,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: Bundle.module)
      ),
      "Mixin": EntryType(
        singular: "Mixin",
        plural: "Mixins",
        sortingOrder: 49,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: Bundle.module)
      ),
      "Event": EntryType(
        singular: "Event",
        plural: "Events",
        sortingOrder: 50,
        aliases: ["event", "Public Events", "Inherited Events", "Private Events"],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: Bundle.module)
      ),
      "Signal": EntryType(
        singular: "Signal",
        plural: "Signals",
        sortingOrder: 51,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_blue", in: Bundle.module)
      ),
      "Binding": EntryType(
        singular: "Binding",
        plural: "Bindings",
        sortingOrder: 52,
        aliases: ["binding"],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: Bundle.module)
      ),
      "Foreign Key": EntryType(
        singular: "Foreign Key",
        plural: "Foreign Keys",
        sortingOrder: 53,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: Bundle.module)
      ),
      "View": EntryType(
        singular: "View",
        plural: "Views",
        sortingOrder: 54,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_blue", in: Bundle.module)
      ),
      "Special Form": EntryType(
        singular: "Special Form",
        plural: "Special Forms",
        sortingOrder: 55,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: Bundle.module)
      ),
      "Record": EntryType(
        singular: "Record",
        plural: "Records",
        sortingOrder: 56,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: Bundle.module)
      ),
      "Report": EntryType(
        singular: "Report",
        plural: "Reports",
        sortingOrder: 57,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: Bundle.module)
      ),
      "Modifier": EntryType(
        singular: "Modifier",
        plural: "Modifiers",
        sortingOrder: 58,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: Bundle.module)
      ),
      "Shortcut": EntryType(
        singular: "Shortcut",
        plural: "Shortcuts",
        sortingOrder: 59,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_blue", in: Bundle.module)
      ),
      "Trigger": EntryType(
        singular: "Trigger",
        plural: "Triggers",
        sortingOrder: 60,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: Bundle.module)
      ),
      "Helper": EntryType(
        singular: "Helper",
        plural: "Helpers",
        sortingOrder: 61,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_green", in: Bundle.module)
      ),
      "Pipe": EntryType(
        singular: "Pipe",
        plural: "Pipes",
        sortingOrder: 62,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: Bundle.module)
      ),
      "Relationship": EntryType(
        singular: "Relationship",
        plural: "Relationships",
        sortingOrder: 63,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: Bundle.module)
      ),
      "Column": EntryType(
        singular: "Column",
        plural: "Columns",
        sortingOrder: 64,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: Bundle.module)
      ),
      "Function": EntryType(
        singular: "Function",
        plural: "Functions",
        sortingOrder: 65,
        aliases: ["func", "ffunc", "signal", "slot", "dcop", "Public Member Functions", "Static Public Member Functions", "Protected Member Functions", "Static Protected Member Functions", "Private Member Functions", "Static Private Member Functions", "Package Functions", "Static Package Functions", "Function Prototypes", "Public Slots", "Signals", "Protected Slots", "Private Slots", "Members", "grammar"],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: Bundle.module)
      ),
      "Expression": EntryType(
        singular: "Expression",
        plural: "Expressions",
        sortingOrder: 66,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-green", in: Bundle.module)
      ),
      "Hook": EntryType(
        singular: "Hook",
        plural: "Hooks",
        sortingOrder: 67,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: Bundle.module)
      ),
      "Procedure": EntryType(
        singular: "Procedure",
        plural: "Procedures",
        sortingOrder: 68,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_brown", in: Bundle.module)
      ),
      "Subroutine": EntryType(
        singular: "Subroutine",
        plural: "Subroutines",
        sortingOrder: 69,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: Bundle.module)
      ),
      "Builtin": EntryType(
        singular: "Builtin",
        plural: "Builtins",
        sortingOrder: 70,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: Bundle.module)
      ),
      "Word": EntryType(
        singular: "Word",
        plural: "Words",
        sortingOrder: 71,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_blue", in: Bundle.module)
      ),
      "Callback": EntryType(
        singular: "Callback",
        plural: "Callbacks",
        sortingOrder: 72,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: Bundle.module)
      ),
      "Handler": EntryType(
        singular: "Handler",
        plural: "Handlers",
        sortingOrder: 73,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: Bundle.module)
      ),
      "Control Structure": EntryType(
        singular: "Control Structure",
        plural: "Control Structures",
        sortingOrder: 74,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: Bundle.module)
      ),
      "Annotation": EntryType(
        singular: "Annotation",
        plural: "Annotations",
        sortingOrder: 75,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-blue", in: Bundle.module)
      ),
      "File": EntryType(
        singular: "File",
        plural: "Files",
        sortingOrder: 76,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: Bundle.module)
      ),
      "Error": EntryType(
        singular: "Error",
        plural: "Errors",
        sortingOrder: 77,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: Bundle.module)
      ),
      "Command": EntryType(
        singular: "Command",
        plural: "Commands",
        sortingOrder: 78,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-cyan", in: Bundle.module)
      ),
      "Tactic": EntryType(
        singular: "Tactic",
        plural: "Tactics",
        sortingOrder: 79,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: Bundle.module)
      ),
      "Environment": EntryType(
        singular: "Environment",
        plural: "Environments",
        sortingOrder: 80,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: Bundle.module)
      ),
      "Provisioner": EntryType(
        singular: "Provisioner",
        plural: "Provisioners",
        sortingOrder: 81,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: Bundle.module)
      ),
      "Axiom": EntryType(
        singular: "Axiom",
        plural: "Axioms",
        sortingOrder: 82,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-blue", in: Bundle.module)
      ),
      "Lemma": EntryType(
        singular: "Lemma",
        plural: "Lemmas",
        sortingOrder: 83,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: Bundle.module)
      ),
      "Inductive": EntryType(
        singular: "Inductive",
        plural: "Inductives",
        sortingOrder: 84,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: Bundle.module)
      ),
      "Instance": EntryType(
        singular: "Instance",
        plural: "Instances",
        sortingOrder: 85,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_brown", in: Bundle.module)
      ),
      "Global": EntryType(
        singular: "Global",
        plural: "Globals",
        sortingOrder: 86,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: Bundle.module)
      ),
      "Union": EntryType(
        singular: "Union",
        plural: "Unions",
        sortingOrder: 87,
        aliases: ["union"],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: Bundle.module)
      ),
      "Variable": EntryType(
        singular: "Variable",
        plural: "Variables",
        sortingOrder: 88,
        aliases: ["var", "Class Variable"],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: Bundle.module)
      ),
      "Member": EntryType(
        singular: "Member",
        plural: "Members",
        sortingOrder: 89,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: Bundle.module)
      ),
      "Block": EntryType(
        singular: "Block",
        plural: "Blocks",
        sortingOrder: 90,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: Bundle.module)
      ),
      "Constant": EntryType(
        singular: "Constant",
        plural: "Constants",
        sortingOrder: 91,
        aliases: ["clconst", "econst", "data", "Notifications", "enumelt", "structdata", "enumdata", "writerid"],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: Bundle.module)
      ),
      "Macro": EntryType(
        singular: "Macro",
        plural: "Macros",
        sortingOrder: 92,
        aliases: ["macro"],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: Bundle.module)
      ),
      "Value": EntryType(
        singular: "Value",
        plural: "Values",
        sortingOrder: 93,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_brown", in: Bundle.module)
      ),
      "Variant": EntryType(
        singular: "Variant",
        plural: "Variants",
        sortingOrder: 94,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_brown", in: Bundle.module)
      ),
      "Define": EntryType(
        singular: "Define",
        plural: "Defines",
        sortingOrder: 95,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: Bundle.module)
      ),
      "Iterator": EntryType(
        singular: "Iterator",
        plural: "Iterators",
        sortingOrder: 96,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: Bundle.module)
      ),
      "Literal": EntryType(
        singular: "Literal",
        plural: "Literals",
        sortingOrder: 97,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: Bundle.module)
      ),
      "Widget": EntryType(
        singular: "Widget",
        plural: "Widgets",
        sortingOrder: 98,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_blue", in: Bundle.module)
      ),
      "Keyword": EntryType(
        singular: "Keyword",
        plural: "Keywords",
        sortingOrder: 99,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: Bundle.module)
      ),
      "Instruction": EntryType(
        singular: "Instruction",
        plural: "Instructions",
        sortingOrder: 100,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: Bundle.module)
      ),
      "Request": EntryType(
        singular: "Request",
        plural: "Requests",
        sortingOrder: 101,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: Bundle.module)
      ),
      "Message": EntryType(
        singular: "Message",
        plural: "Messages",
        sortingOrder: 102,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: Bundle.module)
      ),
      "Option": EntryType(
        singular: "Option",
        plural: "Options",
        sortingOrder: 103,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-cyan", in: Bundle.module)
      ),
      "Setting": EntryType(
        singular: "Setting",
        plural: "Settings",
        sortingOrder: 104,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: Bundle.module)
      ),
      "Style": EntryType(
        singular: "Style",
        plural: "Styles",
        sortingOrder: 105,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: Bundle.module)
      ),
      "Script": EntryType(
        singular: "Script",
        plural: "Scripts",
        sortingOrder: 106,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: Bundle.module)
      ),
      "Notation": EntryType(
        singular: "Notation",
        plural: "Notations",
        sortingOrder: 107,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: Bundle.module)
      ),
      "Abbreviation": EntryType(
        singular: "Abbreviation",
        plural: "Abbreviations",
        sortingOrder: 108,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-purple", in: Bundle.module)
      ),
      "Projection": EntryType(
        singular: "Projection",
        plural: "Projection",
        sortingOrder: 109,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_brown", in: Bundle.module)
      ),
      "Parameter": EntryType(
        singular: "Parameter",
        plural: "Parameters",
        sortingOrder: 110,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: Bundle.module)
      ),
      "Syntax": EntryType(
        singular: "Syntax",
        plural: "Syntaxes",
        sortingOrder: 111,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: Bundle.module)
      ),
      "Signature": EntryType(
        singular: "Signature",
        plural: "Signatures",
        sortingOrder: 112,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: Bundle.module)
      ),
      "Conversion": EntryType(
        singular: "Conversion",
        plural: "Conversions",
        sortingOrder: 113,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: Bundle.module)
      ),
      "Pattern": EntryType(
        singular: "Pattern",
        plural: "Patterns",
        sortingOrder: 114,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: Bundle.module)
      ),
      "Test": EntryType(
        singular: "Test",
        plural: "Tests",
        sortingOrder: 115,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: Bundle.module)
      ),
      "Operator": EntryType(
        singular: "Operator",
        plural: "Operators",
        sortingOrder: 116,
        aliases: ["opfunc"],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: Bundle.module)
      ),
      "Statement": EntryType(
        singular: "Statement",
        plural: "Statements",
        sortingOrder: 117,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: Bundle.module)
      ),
      "Role": EntryType(
        singular: "Role",
        plural: "Roles",
        sortingOrder: 118,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: Bundle.module)
      ),
      "Register": EntryType(
        singular: "Register",
        plural: "Registers",
        sortingOrder: 119,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: Bundle.module)
      ),
      "State": EntryType(
        singular: "State",
        plural: "States",
        sortingOrder: 120,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: Bundle.module)
      ),
      "Alias": EntryType(
        singular: "Alias",
        plural: "Aliases",
        sortingOrder: 121,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-blue", in: Bundle.module)
      ),
      "Device": EntryType(
        singular: "Device",
        plural: "Devices",
        sortingOrder: 122,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-purple", in: Bundle.module)
      ),
      "Kind": EntryType(
        singular: "Kind",
        plural: "Kinds",
        sortingOrder: 123,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: Bundle.module)
      ),
      "Node": EntryType(
        singular: "Node",
        plural: "Nodes",
        sortingOrder: 124,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: Bundle.module)
      ),
      "Flag": EntryType(
        singular: "Flag",
        plural: "Flags",
        sortingOrder: 125,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: Bundle.module)
      ),
      "Sender": EntryType(
        singular: "Sender",
        plural: "Senders",
        sortingOrder: 126,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_blue", in: Bundle.module)
      ),
      "Data Source": EntryType(
        singular: "Data Source",
        plural: "Data Sources",
        sortingOrder: 127,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-purple", in: Bundle.module)
      ),
      "Reference": EntryType(
        singular: "Reference",
        plural: "References",
        sortingOrder: 128,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: Bundle.module)
      ),
      "Given": EntryType(
        singular: "Given",
        plural: "Givens",
        sortingOrder: 129,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: Bundle.module)
      ),
      "Guide": EntryType(
        singular: "Guide",
        plural: "Guides",
        sortingOrder: 130,
        aliases: ["doc"],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: Bundle.module)
      ),
      "Sample": EntryType(
        singular: "Sample",
        plural: "Samples",
        sortingOrder: 131,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-cyan", in: Bundle.module)
      ),
      "Section": EntryType(
        singular: "Section",
        plural: "Sections",
        sortingOrder: 132,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-gray", in: Bundle.module)
      ),
      "Entry": EntryType(
        singular: "Entry",
        plural: "Entries",
        sortingOrder: 133,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: Bundle.module)
      ),
      "Glossary": EntryType(
        singular: "Glossary",
        plural: "Glossaries",
        sortingOrder: 134,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: Bundle.module)
      ),
      "Unknown": EntryType(
        singular: "Unknown",
        plural: "Unknown",
        sortingOrder: 135,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-black", in: Bundle.module)
      ),
      "Full-Text Search": EntryType(
        singular: "Full-Text Search",
        plural: "Full-Text Search",
        sortingOrder: 136,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-black", in: Bundle.module)
      ),
    ]
  }()

}
