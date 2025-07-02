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

import BoltTypesAssets
import BoltUtils

public extension EntryType {

  static let typeDict: [String: EntryType] = {
    return [
      "Snippet": EntryType(
        singular: "Snippet",
        plural: "Snippets",
        sortingOrder: 1,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-gray", in: BLTTypes.assetsBundle)
      ),
      "Class": EntryType(
        singular: "Class",
        plural: "Classes",
        sortingOrder: 2,
        aliases: ["cl", "tmplt", "specialization"],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: BLTTypes.assetsBundle)
      ),
      "_Struct": EntryType(
        singular: "_Struct",
        plural: "_Structs",
        sortingOrder: 3,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: BLTTypes.assetsBundle)
      ),
      "Tag": EntryType(
        singular: "Tag",
        plural: "Tags",
        sortingOrder: 4,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: BLTTypes.assetsBundle)
      ),
      "Trait": EntryType(
        singular: "Trait",
        plural: "Traits",
        sortingOrder: 5,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: BLTTypes.assetsBundle)
      ),
      "Database": EntryType(
        singular: "Database",
        plural: "Databases",
        sortingOrder: 6,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Protocol": EntryType(
        singular: "Protocol",
        plural: "Protocols",
        sortingOrder: 7,
        aliases: ["intf"],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: BLTTypes.assetsBundle)
      ),
      "Delegate": EntryType(
        singular: "Delegate",
        plural: "Delegates",
        sortingOrder: 8,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_blue", in: BLTTypes.assetsBundle)
      ),
      "Interface": EntryType(
        singular: "Interface",
        plural: "Interfaces",
        sortingOrder: 9,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: BLTTypes.assetsBundle)
      ),
      "Template": EntryType(
        singular: "Template",
        plural: "Templates",
        sortingOrder: 10,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: BLTTypes.assetsBundle)
      ),
      "Actor": EntryType(
        singular: "Actor",
        plural: "Actors",
        sortingOrder: 11,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-purple", in: BLTTypes.assetsBundle)
      ),
      "Indirection": EntryType(
        singular: "Indirection",
        plural: "Indirections",
        sortingOrder: 12,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Object": EntryType(
        singular: "Object",
        plural: "Objects",
        sortingOrder: 13,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: BLTTypes.assetsBundle)
      ),
      "Schema": EntryType(
        singular: "Schema",
        plural: "Schemas",
        sortingOrder: 14,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: BLTTypes.assetsBundle)
      ),
      "Category": EntryType(
        singular: "Category",
        plural: "Categories",
        sortingOrder: 15,
        aliases: ["cat", "Groups", "Pages"],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: BLTTypes.assetsBundle)
      ),
      "Collection": EntryType(
        singular: "Collection",
        plural: "Collections",
        sortingOrder: 16,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: BLTTypes.assetsBundle)
      ),
      "Framework": EntryType(
        singular: "Framework",
        plural: "Frameworks",
        sortingOrder: 17,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: BLTTypes.assetsBundle)
      ),
      "Module": EntryType(
        singular: "Module",
        plural: "Modules",
        sortingOrder: 18,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: BLTTypes.assetsBundle)
      ),
      "Library": EntryType(
        singular: "Library",
        plural: "Libraries",
        sortingOrder: 19,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: BLTTypes.assetsBundle)
      ),
      "Namespace": EntryType(
        singular: "Namespace",
        plural: "Namespaces",
        sortingOrder: 20,
        aliases: ["ns"],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: BLTTypes.assetsBundle)
      ),
      "Package": EntryType(
        singular: "Package",
        plural: "Packages",
        sortingOrder: 21,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: BLTTypes.assetsBundle)
      ),
      "Exception": EntryType(
        singular: "Exception",
        plural: "Exceptions",
        sortingOrder: 22,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-pink", in: BLTTypes.assetsBundle)
      ),
      "Struct": EntryType(
        singular: "Struct",
        plural: "Structs",
        sortingOrder: 23,
        aliases: ["Data Structures", "struct"],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: BLTTypes.assetsBundle)
      ),
      "Type": EntryType(
        singular: "Type",
        plural: "Types",
        sortingOrder: 24,
        aliases: ["tag", "tdef", "Public Types", "Protected Types", "Private Types", "Typedefs", "Package Types", "Data Types"],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: BLTTypes.assetsBundle)
      ),
      "Enum": EntryType(
        singular: "Enum",
        plural: "Enums",
        sortingOrder: 25,
        aliases: ["Enumerations", "enum"],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: BLTTypes.assetsBundle)
      ),
      "Diagram": EntryType(
        singular: "Diagram",
        plural: "Diagrams",
        sortingOrder: 26,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-purple", in: BLTTypes.assetsBundle)
      ),
      "Table": EntryType(
        singular: "Table",
        plural: "Tables",
        sortingOrder: 27,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: BLTTypes.assetsBundle)
      ),
      "Query": EntryType(
        singular: "Query",
        plural: "Queries",
        sortingOrder: 28,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-gray", in: BLTTypes.assetsBundle)
      ),
      "Component": EntryType(
        singular: "Component",
        plural: "Components",
        sortingOrder: 29,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: BLTTypes.assetsBundle)
      ),
      "Constructor": EntryType(
        singular: "Constructor",
        plural: "Constructors",
        sortingOrder: 30,
        aliases: ["Public Constructors"],
        colorResource: BoltColorResource(named: "type-colors/light-dark_brown", in: BLTTypes.assetsBundle)
      ),
      "Element": EntryType(
        singular: "Element",
        plural: "Elements",
        sortingOrder: 31,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: BLTTypes.assetsBundle)
      ),
      "Resource": EntryType(
        singular: "Resource",
        plural: "Resources",
        sortingOrder: 32,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: BLTTypes.assetsBundle)
      ),
      "Directive": EntryType(
        singular: "Directive",
        plural: "Directives",
        sortingOrder: 33,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Extension": EntryType(
        singular: "Extension",
        plural: "Extensions",
        sortingOrder: 34,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_blue", in: BLTTypes.assetsBundle)
      ),
      "Plugin": EntryType(
        singular: "Plugin",
        plural: "Plugins",
        sortingOrder: 35,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: BLTTypes.assetsBundle)
      ),
      "Filter": EntryType(
        singular: "Filter",
        plural: "Filters",
        sortingOrder: 36,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: BLTTypes.assetsBundle)
      ),
      "Service": EntryType(
        singular: "Service",
        plural: "Services",
        sortingOrder: 37,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: BLTTypes.assetsBundle)
      ),
      "Provider": EntryType(
        singular: "Provider",
        plural: "Providers",
        sortingOrder: 38,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Decorator": EntryType(
        singular: "Decorator",
        plural: "Decorators",
        sortingOrder: 39,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-purple", in: BLTTypes.assetsBundle)
      ),
      "Method": EntryType(
        singular: "Method",
        plural: "Methods",
        sortingOrder: 40,
        aliases: ["instm", "intfm", "clm", "intfcm", "Class Methods", "Instance Methods", "Public Methods", "Inherited Methods", "Private Methods", "Protected Methods", "instctr", "intfctr", "enumm", "intfsub", "enumcm", "structctr", "structcm", "enumctr", "instsub", "structsub", "structm"],
        colorResource: BoltColorResource(named: "type-colors/light-dark_blue", in: BLTTypes.assetsBundle)
      ),
      "Property": EntryType(
        singular: "Property",
        plural: "Properties",
        sortingOrder: 41,
        aliases: ["intfp", "instp", "Protected Properties", "Public Properties", "Inherited Properties", "Private Properties", "structp", "enump", "intfdata", "cldata"],
        colorResource: BoltColorResource(named: "type-colors/light-dark_blue", in: BLTTypes.assetsBundle)
      ),
      "Field": EntryType(
        singular: "Field",
        plural: "Fields",
        sortingOrder: 42,
        aliases: ["Data Fields"],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: BLTTypes.assetsBundle)
      ),
      "Header": EntryType(
        singular: "Header",
        plural: "Headers",
        sortingOrder: 43,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: BLTTypes.assetsBundle)
      ),
      "Response Code": EntryType(
        singular: "Response Code",
        plural: "Response Codes",
        sortingOrder: 44,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-green", in: BLTTypes.assetsBundle)
      ),
      "Attribute": EntryType(
        singular: "Attribute",
        plural: "Attributes",
        sortingOrder: 45,
        aliases: ["XML Attributes", "Public Attributes", "Static Public Attributes", "Protected Attributes", "Static Protected Attributes", "Private Attributes", "Static Private Attributes", "Package Attributes", "Static Package Attributes"],
        colorResource: BoltColorResource(named: "type-colors/dark-pink", in: BLTTypes.assetsBundle)
      ),
      "Aggregation": EntryType(
        singular: "Aggregation",
        plural: "Aggregations",
        sortingOrder: 46,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-blue", in: BLTTypes.assetsBundle)
      ),
      "Association": EntryType(
        singular: "Association",
        plural: "Associations",
        sortingOrder: 47,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-pink", in: BLTTypes.assetsBundle)
      ),
      "Index": EntryType(
        singular: "Index",
        plural: "Indexes",
        sortingOrder: 48,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: BLTTypes.assetsBundle)
      ),
      "Mixin": EntryType(
        singular: "Mixin",
        plural: "Mixins",
        sortingOrder: 49,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: BLTTypes.assetsBundle)
      ),
      "Event": EntryType(
        singular: "Event",
        plural: "Events",
        sortingOrder: 50,
        aliases: ["event", "Public Events", "Inherited Events", "Private Events"],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: BLTTypes.assetsBundle)
      ),
      "Signal": EntryType(
        singular: "Signal",
        plural: "Signals",
        sortingOrder: 51,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_blue", in: BLTTypes.assetsBundle)
      ),
      "Binding": EntryType(
        singular: "Binding",
        plural: "Bindings",
        sortingOrder: 52,
        aliases: ["binding"],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: BLTTypes.assetsBundle)
      ),
      "Foreign Key": EntryType(
        singular: "Foreign Key",
        plural: "Foreign Keys",
        sortingOrder: 53,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: BLTTypes.assetsBundle)
      ),
      "View": EntryType(
        singular: "View",
        plural: "Views",
        sortingOrder: 54,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_blue", in: BLTTypes.assetsBundle)
      ),
      "Special Form": EntryType(
        singular: "Special Form",
        plural: "Special Forms",
        sortingOrder: 55,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: BLTTypes.assetsBundle)
      ),
      "Record": EntryType(
        singular: "Record",
        plural: "Records",
        sortingOrder: 56,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: BLTTypes.assetsBundle)
      ),
      "Report": EntryType(
        singular: "Report",
        plural: "Reports",
        sortingOrder: 57,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: BLTTypes.assetsBundle)
      ),
      "Modifier": EntryType(
        singular: "Modifier",
        plural: "Modifiers",
        sortingOrder: 58,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: BLTTypes.assetsBundle)
      ),
      "Shortcut": EntryType(
        singular: "Shortcut",
        plural: "Shortcuts",
        sortingOrder: 59,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_blue", in: BLTTypes.assetsBundle)
      ),
      "Trigger": EntryType(
        singular: "Trigger",
        plural: "Triggers",
        sortingOrder: 60,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: BLTTypes.assetsBundle)
      ),
      "Helper": EntryType(
        singular: "Helper",
        plural: "Helpers",
        sortingOrder: 61,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Pipe": EntryType(
        singular: "Pipe",
        plural: "Pipes",
        sortingOrder: 62,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Relationship": EntryType(
        singular: "Relationship",
        plural: "Relationships",
        sortingOrder: 63,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: BLTTypes.assetsBundle)
      ),
      "Column": EntryType(
        singular: "Column",
        plural: "Columns",
        sortingOrder: 64,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: BLTTypes.assetsBundle)
      ),
      "Function": EntryType(
        singular: "Function",
        plural: "Functions",
        sortingOrder: 65,
        aliases: ["func", "ffunc", "signal", "slot", "dcop", "Public Member Functions", "Static Public Member Functions", "Protected Member Functions", "Static Protected Member Functions", "Private Member Functions", "Static Private Member Functions", "Package Functions", "Static Package Functions", "Function Prototypes", "Public Slots", "Signals", "Protected Slots", "Private Slots", "Members", "grammar"],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: BLTTypes.assetsBundle)
      ),
      "Expression": EntryType(
        singular: "Expression",
        plural: "Expressions",
        sortingOrder: 66,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-green", in: BLTTypes.assetsBundle)
      ),
      "Hook": EntryType(
        singular: "Hook",
        plural: "Hooks",
        sortingOrder: 67,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: BLTTypes.assetsBundle)
      ),
      "Procedure": EntryType(
        singular: "Procedure",
        plural: "Procedures",
        sortingOrder: 68,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_brown", in: BLTTypes.assetsBundle)
      ),
      "Subroutine": EntryType(
        singular: "Subroutine",
        plural: "Subroutines",
        sortingOrder: 69,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: BLTTypes.assetsBundle)
      ),
      "Builtin": EntryType(
        singular: "Builtin",
        plural: "Builtins",
        sortingOrder: 70,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: BLTTypes.assetsBundle)
      ),
      "Word": EntryType(
        singular: "Word",
        plural: "Words",
        sortingOrder: 71,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_blue", in: BLTTypes.assetsBundle)
      ),
      "Callback": EntryType(
        singular: "Callback",
        plural: "Callbacks",
        sortingOrder: 72,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: BLTTypes.assetsBundle)
      ),
      "Handler": EntryType(
        singular: "Handler",
        plural: "Handlers",
        sortingOrder: 73,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: BLTTypes.assetsBundle)
      ),
      "Control Structure": EntryType(
        singular: "Control Structure",
        plural: "Control Structures",
        sortingOrder: 74,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Annotation": EntryType(
        singular: "Annotation",
        plural: "Annotations",
        sortingOrder: 75,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-blue", in: BLTTypes.assetsBundle)
      ),
      "File": EntryType(
        singular: "File",
        plural: "Files",
        sortingOrder: 76,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: BLTTypes.assetsBundle)
      ),
      "Error": EntryType(
        singular: "Error",
        plural: "Errors",
        sortingOrder: 77,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: BLTTypes.assetsBundle)
      ),
      "Command": EntryType(
        singular: "Command",
        plural: "Commands",
        sortingOrder: 78,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-cyan", in: BLTTypes.assetsBundle)
      ),
      "Tactic": EntryType(
        singular: "Tactic",
        plural: "Tactics",
        sortingOrder: 79,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: BLTTypes.assetsBundle)
      ),
      "Environment": EntryType(
        singular: "Environment",
        plural: "Environments",
        sortingOrder: 80,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: BLTTypes.assetsBundle)
      ),
      "Provisioner": EntryType(
        singular: "Provisioner",
        plural: "Provisioners",
        sortingOrder: 81,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: BLTTypes.assetsBundle)
      ),
      "Axiom": EntryType(
        singular: "Axiom",
        plural: "Axioms",
        sortingOrder: 82,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-blue", in: BLTTypes.assetsBundle)
      ),
      "Lemma": EntryType(
        singular: "Lemma",
        plural: "Lemmas",
        sortingOrder: 83,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: BLTTypes.assetsBundle)
      ),
      "Inductive": EntryType(
        singular: "Inductive",
        plural: "Inductives",
        sortingOrder: 84,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Instance": EntryType(
        singular: "Instance",
        plural: "Instances",
        sortingOrder: 85,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_brown", in: BLTTypes.assetsBundle)
      ),
      "Global": EntryType(
        singular: "Global",
        plural: "Globals",
        sortingOrder: 86,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: BLTTypes.assetsBundle)
      ),
      "Union": EntryType(
        singular: "Union",
        plural: "Unions",
        sortingOrder: 87,
        aliases: ["union"],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: BLTTypes.assetsBundle)
      ),
      "Variable": EntryType(
        singular: "Variable",
        plural: "Variables",
        sortingOrder: 88,
        aliases: ["var", "Class Variable"],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: BLTTypes.assetsBundle)
      ),
      "Member": EntryType(
        singular: "Member",
        plural: "Members",
        sortingOrder: 89,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: BLTTypes.assetsBundle)
      ),
      "Block": EntryType(
        singular: "Block",
        plural: "Blocks",
        sortingOrder: 90,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-brown", in: BLTTypes.assetsBundle)
      ),
      "Constant": EntryType(
        singular: "Constant",
        plural: "Constants",
        sortingOrder: 91,
        aliases: ["clconst", "econst", "data", "Notifications", "enumelt", "structdata", "enumdata", "writerid"],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: BLTTypes.assetsBundle)
      ),
      "Macro": EntryType(
        singular: "Macro",
        plural: "Macros",
        sortingOrder: 92,
        aliases: ["macro"],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: BLTTypes.assetsBundle)
      ),
      "Value": EntryType(
        singular: "Value",
        plural: "Values",
        sortingOrder: 93,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_brown", in: BLTTypes.assetsBundle)
      ),
      "Variant": EntryType(
        singular: "Variant",
        plural: "Variants",
        sortingOrder: 94,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_brown", in: BLTTypes.assetsBundle)
      ),
      "Define": EntryType(
        singular: "Define",
        plural: "Defines",
        sortingOrder: 95,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: BLTTypes.assetsBundle)
      ),
      "Iterator": EntryType(
        singular: "Iterator",
        plural: "Iterators",
        sortingOrder: 96,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Literal": EntryType(
        singular: "Literal",
        plural: "Literals",
        sortingOrder: 97,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: BLTTypes.assetsBundle)
      ),
      "Widget": EntryType(
        singular: "Widget",
        plural: "Widgets",
        sortingOrder: 98,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_blue", in: BLTTypes.assetsBundle)
      ),
      "Keyword": EntryType(
        singular: "Keyword",
        plural: "Keywords",
        sortingOrder: 99,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Instruction": EntryType(
        singular: "Instruction",
        plural: "Instructions",
        sortingOrder: 100,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Request": EntryType(
        singular: "Request",
        plural: "Requests",
        sortingOrder: 101,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: BLTTypes.assetsBundle)
      ),
      "Message": EntryType(
        singular: "Message",
        plural: "Messages",
        sortingOrder: 102,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: BLTTypes.assetsBundle)
      ),
      "Option": EntryType(
        singular: "Option",
        plural: "Options",
        sortingOrder: 103,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-cyan", in: BLTTypes.assetsBundle)
      ),
      "Setting": EntryType(
        singular: "Setting",
        plural: "Settings",
        sortingOrder: 104,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: BLTTypes.assetsBundle)
      ),
      "Style": EntryType(
        singular: "Style",
        plural: "Styles",
        sortingOrder: 105,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: BLTTypes.assetsBundle)
      ),
      "Script": EntryType(
        singular: "Script",
        plural: "Scripts",
        sortingOrder: 106,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: BLTTypes.assetsBundle)
      ),
      "Notation": EntryType(
        singular: "Notation",
        plural: "Notations",
        sortingOrder: 107,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: BLTTypes.assetsBundle)
      ),
      "Abbreviation": EntryType(
        singular: "Abbreviation",
        plural: "Abbreviations",
        sortingOrder: 108,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-purple", in: BLTTypes.assetsBundle)
      ),
      "Projection": EntryType(
        singular: "Projection",
        plural: "Projection",
        sortingOrder: 109,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_brown", in: BLTTypes.assetsBundle)
      ),
      "Parameter": EntryType(
        singular: "Parameter",
        plural: "Parameters",
        sortingOrder: 110,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Syntax": EntryType(
        singular: "Syntax",
        plural: "Syntaxes",
        sortingOrder: 111,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: BLTTypes.assetsBundle)
      ),
      "Signature": EntryType(
        singular: "Signature",
        plural: "Signatures",
        sortingOrder: 112,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: BLTTypes.assetsBundle)
      ),
      "Conversion": EntryType(
        singular: "Conversion",
        plural: "Conversions",
        sortingOrder: 113,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-green", in: BLTTypes.assetsBundle)
      ),
      "Pattern": EntryType(
        singular: "Pattern",
        plural: "Patterns",
        sortingOrder: 114,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Test": EntryType(
        singular: "Test",
        plural: "Tests",
        sortingOrder: 115,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-yellow", in: BLTTypes.assetsBundle)
      ),
      "Operator": EntryType(
        singular: "Operator",
        plural: "Operators",
        sortingOrder: 116,
        aliases: ["opfunc"],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Statement": EntryType(
        singular: "Statement",
        plural: "Statements",
        sortingOrder: 117,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: BLTTypes.assetsBundle)
      ),
      "Role": EntryType(
        singular: "Role",
        plural: "Roles",
        sortingOrder: 118,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: BLTTypes.assetsBundle)
      ),
      "Register": EntryType(
        singular: "Register",
        plural: "Registers",
        sortingOrder: 119,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: BLTTypes.assetsBundle)
      ),
      "State": EntryType(
        singular: "State",
        plural: "States",
        sortingOrder: 120,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: BLTTypes.assetsBundle)
      ),
      "Alias": EntryType(
        singular: "Alias",
        plural: "Aliases",
        sortingOrder: 121,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-blue", in: BLTTypes.assetsBundle)
      ),
      "Device": EntryType(
        singular: "Device",
        plural: "Devices",
        sortingOrder: 122,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-purple", in: BLTTypes.assetsBundle)
      ),
      "Kind": EntryType(
        singular: "Kind",
        plural: "Kinds",
        sortingOrder: 123,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Node": EntryType(
        singular: "Node",
        plural: "Nodes",
        sortingOrder: 124,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-orange", in: BLTTypes.assetsBundle)
      ),
      "Flag": EntryType(
        singular: "Flag",
        plural: "Flags",
        sortingOrder: 125,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: BLTTypes.assetsBundle)
      ),
      "Sender": EntryType(
        singular: "Sender",
        plural: "Senders",
        sortingOrder: 126,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-dark_blue", in: BLTTypes.assetsBundle)
      ),
      "Data Source": EntryType(
        singular: "Data Source",
        plural: "Data Sources",
        sortingOrder: 127,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-purple", in: BLTTypes.assetsBundle)
      ),
      "Reference": EntryType(
        singular: "Reference",
        plural: "References",
        sortingOrder: 128,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-brown", in: BLTTypes.assetsBundle)
      ),
      "Given": EntryType(
        singular: "Given",
        plural: "Givens",
        sortingOrder: 129,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-dark_green", in: BLTTypes.assetsBundle)
      ),
      "Guide": EntryType(
        singular: "Guide",
        plural: "Guides",
        sortingOrder: 130,
        aliases: ["doc"],
        colorResource: BoltColorResource(named: "type-colors/light-blue", in: BLTTypes.assetsBundle)
      ),
      "Sample": EntryType(
        singular: "Sample",
        plural: "Samples",
        sortingOrder: 131,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-cyan", in: BLTTypes.assetsBundle)
      ),
      "Section": EntryType(
        singular: "Section",
        plural: "Sections",
        sortingOrder: 132,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-gray", in: BLTTypes.assetsBundle)
      ),
      "Entry": EntryType(
        singular: "Entry",
        plural: "Entries",
        sortingOrder: 133,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-purple", in: BLTTypes.assetsBundle)
      ),
      "Glossary": EntryType(
        singular: "Glossary",
        plural: "Glossaries",
        sortingOrder: 134,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/light-pink", in: BLTTypes.assetsBundle)
      ),
      "Unknown": EntryType(
        singular: "Unknown",
        plural: "Unknown",
        sortingOrder: 135,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-black", in: BLTTypes.assetsBundle)
      ),
      "Full-Text Search": EntryType(
        singular: "Full-Text Search",
        plural: "Full-Text Search",
        sortingOrder: 136,
        aliases: [],
        colorResource: BoltColorResource(named: "type-colors/dark-black", in: BLTTypes.assetsBundle)
      ),
    ]
  }()

}
