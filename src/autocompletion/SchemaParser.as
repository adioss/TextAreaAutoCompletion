package autocompletion {
import autocompletion.model.position.XmlAttributeEditionPosition;
import autocompletion.model.position.XmlAttributePosition;
import autocompletion.model.position.XmlBeginTagPosition;
import autocompletion.model.schema.SimpleSchemaDescription;

import flash.utils.Dictionary;

import mx.collections.ArrayCollection;

public class SchemaParser {
    public static const XS_NAMESPACE:String = "xs";
    public static const TNS_NAMESPACE:String = "tns";
    public static const PROCESS_TAG:String = "processTag";
    public static const PROCESS_ATTRIBUTE:String = "processAttribute";
    private static const W3_ORG_XMLSCHEMA:String = "http://www.w3.org/2001/XMLSchema";

    [Embed(source="/assets/camel-spring-2.9.1.xml")]
    private var CAMEL_SPRING_XSD:Class;

    public static var xsNameSpace:Namespace;
    public static var tnsNameSpace:Namespace;
    private var m_currentSchema:XML;
    private var m_schemaDescriptions:Dictionary = new Dictionary();
    private var m_abstractComplexTypes:Dictionary = new Dictionary();
    private var m_complexTypes:Dictionary = new Dictionary();
    private var m_elements:Dictionary = new Dictionary();
    private var m_simpleTypes:Dictionary = new Dictionary();

    public function SchemaParser(schemas:ArrayCollection) {
        m_currentSchema = CAMEL_SPRING_XSD.data as XML;
        xsNameSpace = m_currentSchema.namespace(SchemaParser.XS_NAMESPACE);
        tnsNameSpace = m_currentSchema.namespace(SchemaParser.TNS_NAMESPACE);
        initializeSchemas(schemas);
        initializeElements();
        initializeComplexTypes();
        initializeSimpleType();
    }

    //region Initialisation

    private function initializeSchemas(schemas:ArrayCollection):void {
        for each (var schema:XML in schemas) {
            extractNameSpace(schema);
        }
    }

    private function initializeSimpleType():void {
        var simpleTypes:XMLList = m_currentSchema.xsNameSpace::simpleType;
        for each (var simpleType:XML in simpleTypes) {
            m_simpleTypes[String(simpleType.attribute("name"))] = simpleType;
        }
    }

    public function initializeElements():void {
        var elements:XMLList = m_currentSchema.xsNameSpace::element;
        for each (var element:XML in elements) {
            m_elements[String(element.attribute("name"))] = element;
        }
    }

    public function initializeComplexTypes():void {
        var complexTypes:XMLList = m_currentSchema.xsNameSpace::complexType;
        for each (var complexType:XML in complexTypes) {
            var name:String = complexType.attribute("name");
            if ("@abstract" in complexType && parseBooleanAttribute(complexType, "abstract")) {
                m_abstractComplexTypes[name] = complexType;
            } else {
                m_complexTypes[name] = complexType;
            }
        }
    }

    //endregion

    public function retrieveTagCompletionInformation(position:XmlBeginTagPosition):ArrayCollection {
        if (position.parentTagName) {
            return findAvailableChildren(position.parentTagName, position.presetChars, PROCESS_TAG);
        }
        return null;
    }

    public function retrieveAttributeCompletionInformation(position:XmlAttributePosition, filterFunction:Function = null):ArrayCollection /* of String */ {
        var availableChildren:ArrayCollection = findAvailableChildren(position.currentTagName, position.presetChars, PROCESS_ATTRIBUTE, filterFunction);
        if (position.alreadyUsedAttributes != null) {
            for each (var alreadyUsedAttribute:String in position.alreadyUsedAttributes) {
                if (availableChildren.contains(alreadyUsedAttribute)) {
                    availableChildren.removeItemAt(availableChildren.getItemIndex(alreadyUsedAttribute));
                }
            }
        }
        return availableChildren;
    }

    public function retrieveAttributeEditionCompletionInformation(position:XmlAttributeEditionPosition):ArrayCollection /* of String */ {
        var result:ArrayCollection = null;
        var simpleType:XML = m_simpleTypes[position.currentAttributeName];
        if (simpleType != null) {
            var restriction:XMLList = simpleType.children();
            if (restriction != null && restriction.children() != null) {
                result = new ArrayCollection();
                for each (var enumeration:XML in restriction.children()) {
                    var item:String = enumeration.attribute("value");
                    result.addItem(item);
                }
            }
        } else {
            // not match in simpleTypes, find it to see if it's boolean type attribute
            var complexTypeName:String = String(m_currentSchema.xsNameSpace::element
                    .(attribute("name") == position.currentTagName)
                    .attribute("type").toXMLString())
                    .replace("tns:", "");
            // TODO: match ALL...not only here...
            var simpleTypeName:String = String(m_currentSchema.xsNameSpace::complexType
                    .(attribute("name") == complexTypeName)
                    ..xsNameSpace::attribute
                    .(attribute("name") == position.currentAttributeName)
                    .attribute("type").toXMLString())
                    .replace("xs:", "");
            if (simpleTypeName == "boolean") {
                result = new ArrayCollection(["true", "false"]);
            }
        }
        return result;
    }

    private function extractNameSpace(schema:XML):void {
        var namespaceDeclarations:Array = schema.namespaceDeclarations();
        var simpleSchema:SimpleSchemaDescription;
        for each (var namespaceDeclaration:Namespace in namespaceDeclarations) {
            simpleSchema = new SimpleSchemaDescription();
            if (namespaceDeclaration.uri == W3_ORG_XMLSCHEMA) {
                simpleSchema.standardPrefix = namespaceDeclaration.prefix.toString();
            } else {
                simpleSchema.schemaPrefix = namespaceDeclaration.prefix.toString();
                simpleSchema.schemaUri = namespaceDeclaration.uri.toString();
            }
            m_schemaDescriptions[simpleSchema.schemaPrefix] = simpleSchema;
        }
    }

    //region Tag processing
    private function findAvailableChildren(parent:String, presetChars:String, type:String, filterFunction:Function = null):ArrayCollection {
        return processComplexType(findComplexType(parent), presetChars, type, filterFunction);
    }

    private function findComplexType(parent:String):XML {
        var value:XML = m_elements[parent];
        if (value == null) {
            return null;
        }
        var type:String = value.attribute("type");
        var convertType:String = type.replace(SchemaParser.TNS_NAMESPACE + ":", "");
        var complexType:XML = m_complexTypes[convertType];
        return complexType;
    }

    private function processComplexType(complexType:XML, presetChars:String, type:String, filterFunction:Function):ArrayCollection {
        var result:ArrayCollection = new ArrayCollection();
        var complexTypeChildren:XMLList = complexType.children();
        for each (var complexTypeChild:XML in complexTypeChildren) {
            processContent(result, complexTypeChild, presetChars, type, filterFunction);
        }
        return result;
    }

    private function processContent(result:ArrayCollection, complexType:XML, presetChars:String, type:String, filterFunction:Function):void {
        var complexTypeLocalName:String = complexType.localName();
        if (complexTypeLocalName == "complexContent") {
            append(result, processComplexContent(complexType, presetChars, type, filterFunction));
        } else if (complexTypeLocalName == "sequence") {
            append(result, processSequence(complexType, presetChars, type));
        } else if (complexTypeLocalName == "attribute" && type == PROCESS_ATTRIBUTE) {
            appendAttribute(complexType, result, presetChars, filterFunction);
        } else {
            // TODO sur attribut par exemple
            // Alert.show("processComplexType?? : " + complexTypeLocalName);
        }
    }

    private function processComplexContent(complexType:XML, presetChars:String, type:String, filterFunction:Function):ArrayCollection {
        var result:ArrayCollection = new ArrayCollection();
        var complexContents:XMLList = complexType.children();
        for each (var complexContent:XML in complexContents) {
            var complexContentName:String = complexContent.localName();
            if ("extension" == complexContentName) {
                var base:String = complexContent.attribute("base");
                var baseType:String = base.replace(SchemaParser.TNS_NAMESPACE + ":", "");
                append(result, processExtension(baseType, presetChars, type, filterFunction));
            } else if ("sequence" == complexContentName) {
                append(result, processSequence(complexContent, presetChars, type));
            } else if (complexContentName == "attribute" && type == PROCESS_ATTRIBUTE) {
                appendAttribute(complexType, result, presetChars, filterFunction);
            }
            var extensionChildren:XMLList = complexContent.children();
            if (extensionChildren.length() > 0) {
                for each (var child:XML in extensionChildren) {
                    processContent(result, child, presetChars, type, filterFunction);
                }
            }
        }
        return result;
    }

    private function appendAttribute(complexType:XML, result:ArrayCollection, presetChars:String, filterFunction:Function = null):void {
        if (filterFunction != null) {
            if (filterFunction(complexType)) {
                appendItem(result, complexType.attribute("name"), presetChars);
            }
        } else {
            appendItem(result, complexType.attribute("name"), presetChars);
        }
    }

    private function processExtension(baseType:String, presetChars:String, type:String, filterFunction:Function):ArrayCollection {
        var result:ArrayCollection = new ArrayCollection();
        var complexType:XML = m_abstractComplexTypes[baseType];
        if (complexType == null) {
            complexType = m_complexTypes[baseType];
        }
        append(result, processComplexType(complexType, presetChars, type, filterFunction));
        return result;

    }

    private function processSequence(sequence:XML, presetChars:String, type:String):ArrayCollection {
        var result:ArrayCollection = new ArrayCollection();
        var sequenceChildren:XMLList = sequence.children();
        for each (var sequenceChild:XML in sequenceChildren) {
            var sequenceName:String = sequenceChild.localName();
            if ("element" == sequenceName && type == PROCESS_TAG) {
                var element:String = sequenceChild.attribute("ref");
                var item:String = element.replace(SchemaParser.TNS_NAMESPACE + ":", "");
                appendItem(result, item, presetChars);
            } else if ("choice" == sequenceName) {
                append(result, processChoice(sequenceChild, presetChars, type));
            }
        }
        return result;
    }


    private function processChoice(choice:XML, presetChars:String, type:String):ArrayCollection {
        var result:ArrayCollection = new ArrayCollection();
        var choiceChildren:XMLList = choice.children();
        for each (var choiceChild:XML in choiceChildren) {
            var choiceName:String = choiceChild.localName();
            if ("element" == choiceName && type == PROCESS_TAG) {
                var ref:String = choiceChild.attribute("ref");
                var item:String = ref.replace(SchemaParser.TNS_NAMESPACE + ":", "");
                appendItem(result, item, presetChars);
            }
        }
        return result;
    }

    //endregion

    //region Utils
    private function appendItem(result:ArrayCollection, item:String, presetChars:String):void {
        if (presetChars != null && presetChars != "" && item.indexOf(presetChars) != 0) {
            return;
        }
        result.addItem(item);
    }

    private static function append(result:ArrayCollection, processComplexContent:ArrayCollection):void {
        for each (var tag:String in processComplexContent) {
            if (!result.contains(tag) && tag != "") {
                result.addItem(tag);
            }
        }
    }

    private static function parseBooleanAttribute(complexType:XML, toParse:String):Boolean {
        return (complexType.@[toParse] == "true");
    }

    //endregion
}
}
