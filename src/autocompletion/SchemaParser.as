package autocompletion {
import autocompletion.model.position.XmlAttributeEditionPosition;
import autocompletion.model.position.XmlAttributePosition;
import autocompletion.model.position.XmlBeginTagPosition;
import autocompletion.model.schema.SchemaDescription;
import autocompletion.model.schema.SchemaInformation;

import flash.utils.Dictionary;

import mx.collections.ArrayCollection;

public class SchemaParser {
    public static const PROCESS_TAG:String = "processTag";
    public static const PROCESS_ATTRIBUTE:String = "processAttribute";
    private static const DEFAULT_SCHEMA_INDEX:String = "default";


//    private var m_currentSchema:XML;
    private var m_schemaDescriptions:Dictionary = new Dictionary();// SchemaDescription
    private var m_currentSchemaDescription:SchemaDescription;


    public function SchemaParser(schemas:ArrayCollection) {
        initializeSchemas(schemas);
    }

    //region Initialisation

    private function initializeSchemas(schemas:ArrayCollection):void {
        for each (var schema:XML in schemas) {
            extractNameSpace(schema);
        }
    }

    private function extractNameSpace(schema:XML):void {
        var namespaceDeclarations:Array = schema.namespaceDeclarations();
        var schemaDescription:SchemaDescription = new SchemaDescription(schema);
        var schemaInformation:SchemaInformation = new SchemaInformation();
        var prefix:String;
        for each (var namespaceDeclaration:Namespace in namespaceDeclarations) {
            if (namespaceDeclaration.uri == SchemaInformation.STANDARD_URI) {
                schemaInformation.standardPrefix = namespaceDeclaration.prefix.toString();
                schemaInformation.standardNameSpace = namespaceDeclaration;
            } else {
                schemaInformation.schemaPrefix = namespaceDeclaration.prefix.toString();
                schemaInformation.schemaUri = namespaceDeclaration.uri.toString();
                schemaInformation.schemaNameSpace = namespaceDeclaration;
            }
        }
        schemaDescription.schemaInformation = schemaInformation;
        schemaDescription.simpleTypes = getSchemaSimpleTypes(schema, schemaInformation.standardNameSpace);
        schemaDescription.elements = getSchemaElements(schema, schemaInformation.standardNameSpace);
        schemaDescription.complexTypes = getSchemaComplexTypes(schema, schemaInformation.standardNameSpace);
        schemaDescription.abstractComplexTypes = getAbstractComplexTypes(schema, schemaInformation.standardNameSpace);
        prefix = m_schemaDescriptions.length > 0 ? schemaInformation.schemaPrefix : DEFAULT_SCHEMA_INDEX;
        m_schemaDescriptions[prefix] = schemaDescription;
    }

    private static function getSchemaSimpleTypes(schema:XML, standardNameSpace:Namespace):Dictionary {
        var result:Dictionary = new Dictionary();
        var simpleTypes:XMLList = schema.standardNameSpace::simpleType;
        for each (var simpleType:XML in simpleTypes) {
            result[String(simpleType.attribute("name"))] = simpleType;
        }
        return result;
    }

    public static function getSchemaElements(schema:XML, standardNameSpace:Namespace):Dictionary {
        var result:Dictionary = new Dictionary();
        var elements:XMLList = schema.standardNameSpace::element;
        for each (var element:XML in elements) {
            result[String(element.attribute("name"))] = element;
        }
        return result;
    }

    public static function getSchemaComplexTypes(schema:XML, standardNameSpace:Namespace):Dictionary {
        var result:Dictionary = new Dictionary();
        var complexTypes:XMLList = schema.standardNameSpace::complexType;
        for each (var complexType:XML in complexTypes) {
            var name:String = complexType.attribute("name");
            result[name] = complexType;
        }
        return result;
    }

    public static function getAbstractComplexTypes(schema:XML, standardNameSpace:Namespace):Dictionary {
        var result:Dictionary = new Dictionary();
        var complexTypes:XMLList = schema.standardNameSpace::complexType;
        for each (var complexType:XML in complexTypes) {
            var name:String = complexType.attribute("name");
            if ("@abstract" in complexType && parseBooleanAttribute(complexType, "abstract")) {
                result[name] = complexType;
            }
        }
        return result;
    }

    //endregion

    public function retrieveTagCompletionInformation(position:XmlBeginTagPosition):ArrayCollection {
        if (position.parentTagName != null) {
            fillCurrentSchemaDescription(position.parentTagName);
            return findAvailableChildren(position.parentTagName, position.presetChars, PROCESS_TAG);
        }
        return null;
    }

    private function fillCurrentSchemaDescription(parentTagName:String):void {
        var index:String = DEFAULT_SCHEMA_INDEX;
        if (parentTagName.indexOf(":") != 0) {

        }
        m_currentSchemaDescription = m_schemaDescriptions[index];
    }

    public function retrieveAttributeCompletionInformation(position:XmlAttributePosition, filterFunction:Function = null):ArrayCollection /* of String */ {
        fillCurrentSchemaDescription(position.currentTagName);
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
        fillCurrentSchemaDescription(position.currentTagName);
        var result:ArrayCollection = null;
        var simpleType:XML = m_currentSchemaDescription.simpleTypes[position.currentAttributeName];
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
            var schema:XML = m_currentSchemaDescription.schema;
            var standardNameSpace:Namespace = m_currentSchemaDescription.schemaInformation.standardNameSpace;
            var complexTypeName:String = String(schema.standardNameSpace::element
                    .(attribute("name") == position.currentTagName)
                    .attribute("type").toXMLString())
                    .replace(m_currentSchemaDescription.schemaInformation.schemaPrefix + ":", "");
            // TODO: match ALL...not only here...
            var simpleTypeName:String = String(schema.standardNameSpace::complexType
                    .(attribute("name") == complexTypeName)..*::attribute
                    .(attribute("name") == position.currentAttributeName)
                    .attribute("type").toXMLString())
                    .replace(m_currentSchemaDescription.schemaInformation.standardPrefix + ":", "");
            if (simpleTypeName == "boolean") {
                result = new ArrayCollection(["true", "false"]);
            }
        }
        return result;
    }

    //region Tag processing
    private function findAvailableChildren(parent:String, presetChars:String, type:String, filterFunction:Function = null):ArrayCollection {
        return processComplexType(findComplexType(parent), presetChars, type, filterFunction);
    }

    private function findComplexType(parent:String):XML {
        var value:XML = m_currentSchemaDescription.elements[parent];
        if (value == null) {
            return null;
        }
        var type:String = value.attribute("type");
        var convertType:String = type.replace(m_currentSchemaDescription.schemaInformation.schemaPrefix + ":", "");
        var complexType:XML = m_currentSchemaDescription.complexTypes[convertType];
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
                var baseType:String = base.replace(m_currentSchemaDescription.schemaInformation.schemaPrefix + ":", "");
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
        var complexType:XML = m_currentSchemaDescription.abstractComplexTypes[baseType];
        if (complexType == null) {
            complexType = m_currentSchemaDescription.complexTypes[baseType];
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
                var item:String = element.replace(m_currentSchemaDescription.schemaInformation.schemaPrefix + ":", "");
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
                var item:String = ref.replace(m_currentSchemaDescription.schemaInformation.schemaPrefix + ":", "");
                appendItem(result, item, presetChars);
            }
        }
        return result;
    }

    //endregion

    //region Utils
    private static function appendItem(result:ArrayCollection, item:String, presetChars:String):void {
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
