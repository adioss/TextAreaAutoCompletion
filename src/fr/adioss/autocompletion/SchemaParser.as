/**
 *
 * User: A.PAILHES
 * Date: 01/08/12
 * Time: 00:21
 */
package fr.adioss.autocompletion {
    import flash.utils.Dictionary;

    import fr.adioss.autocompletion.model.position.XmlAttributeEditionPosition;
    import fr.adioss.autocompletion.model.position.XmlAttributePosition;
    import fr.adioss.autocompletion.model.position.XmlBeginTagPosition;
    import fr.adioss.autocompletion.model.schema.SchemaDescription;
    import fr.adioss.autocompletion.model.schema.SchemaInformation;

    import mx.collections.ArrayCollection;

    /**
     * Bean used to parse multiple XSD
     * - pre parse xsd to accelerate search of
     * - find available tag names for a parent tag name
     * - find available attributes for a tag name
     * - find available values for an attribute
     */
    public class SchemaParser {
        private static const PROCESS_TAG:String = "processTag";
        private static const PROCESS_ATTRIBUTE:String = "processAttribute";
        private static const DEFAULT_SCHEMA_INDEX:String = "default";
        private static const DEFAULT_SCHEMA_PREFIX:String = "xs";
        private static const XML_NAMESPACE_DECLARATION:String = "xmlns";

        private var m_schemaDescriptions:Dictionary = new Dictionary();// of SchemaDescription
        private var m_currentSchemaDescription:SchemaDescription;

        public function SchemaParser(schemas:ArrayCollection) {
            initializeSchemas(schemas);
        }

        //region Initialisation

        private function initializeSchemas(schemas:ArrayCollection):void {
            for each (var schema:XML in schemas) {
                initializeSchema(schema);
            }
        }

        /**
         * initialize schema description
         */
        private function initializeSchema(schema:XML):void {
            var namespaceDeclarations:Array = schema.namespaceDeclarations();
            var schemaDescription:SchemaDescription = new SchemaDescription(schema);
            var schemaInformation:SchemaInformation = new SchemaInformation();
            var prefix:String;
            for each (var namespaceDeclaration:Namespace in namespaceDeclarations) {
                if (namespaceDeclaration.uri == SchemaInformation.STANDARD_URI) {
                    schemaInformation.standardNameSpace = namespaceDeclaration;
                } else {
                    schemaInformation.schemaNameSpace = namespaceDeclaration;
                }
            }
            if (schema.hasOwnProperty("@targetNamespace")) {
                schemaDescription.schemaInformation = schemaInformation;
                schemaInformation.targetNamespace = schema.attribute("targetNamespace").toXMLString();
                schemaDescription.simpleTypes = getSchemaSimpleTypes(schema, schemaInformation.standardNameSpace);
                schemaDescription.elements = getSchemaElements(schema, schemaInformation.standardNameSpace);
                schemaDescription.complexTypes = getSchemaComplexTypes(schema, schemaInformation.standardNameSpace);
                schemaDescription.abstractComplexTypes = getAbstractComplexTypes(schema, schemaInformation.standardNameSpace);
                // by default, take schema prefix, otherwise xs1, xs2...
                var schemaIndex:String = DEFAULT_SCHEMA_PREFIX + SchemaParser.countDictionaryKeys(m_schemaDescriptions);
                prefix = countDictionaryKeys(m_schemaDescriptions) > 0 ? schemaIndex : DEFAULT_SCHEMA_INDEX;
                schemaDescription.prefix = prefix;

                // looking for parent tag
                var possibleChildTags:ArrayCollection = new ArrayCollection();
                var childWithNoParentTags:ArrayCollection = new ArrayCollection();
                if (schemaDescription.elements != null) {
                    for (var elementName:String in schemaDescription.elements) {
                        if (!childWithNoParentTags.contains(elementName)) {
                            // find possible children => elementName correspond to parentTagName
                            var tagList:ArrayCollection = retrieveTagCompletionInformation(new XmlBeginTagPosition(elementName, ""), schemaDescription);
                            if (tagList != null && tagList.length > 0) {
                                possibleChildTags.addAll(tagList);
                            }
                            childWithNoParentTags.addItem(elementName);
                            childWithNoParentTags = notIntersect(childWithNoParentTags, possibleChildTags);
                        } else {
                            childWithNoParentTags.removeItemAt(childWithNoParentTags.getItemIndex(elementName));
                        }
                    }
                    schemaDescription.rootTagNames = childWithNoParentTags;
                }
                m_schemaDescriptions[prefix] = schemaDescription;

            } else {
                trace("No targetNamespace: ignore it");
            }
        }

        /**
         * get current schema description based on preset char
         * if ":" is found, extract prefix and found associated schema
         */
        private function fillCurrentSchemaDescription(content:String, schemaDescription:SchemaDescription):void {
            if (schemaDescription == null) {
                var index:String = DEFAULT_SCHEMA_INDEX;
                if (content != null && content.length > 0 && content.indexOf(":") > 0) {
                    index = content.slice(0, content.indexOf(":"));
                }
                m_currentSchemaDescription = m_schemaDescriptions[index];
            } else {
                m_currentSchemaDescription = schemaDescription;
            }
        }

        /**
         * get simpleType tags from schema
         * @param schema current schema
         * @param standardNameSpace
         * @return collection of simpleType tag
         */
        private static function getSchemaSimpleTypes(schema:XML, standardNameSpace:Namespace):Dictionary {
            var result:Dictionary = new Dictionary();
            var simpleTypes:XMLList = schema.standardNameSpace::simpleType;
            for each (var simpleType:XML in simpleTypes) {
                result[String(simpleType.attribute("name"))] = simpleType;
            }
            return result;
        }

        /**
         * get element tags from schema
         * @param schema current schema
         * @param standardNameSpace
         * @return collection of element tag
         */
        public static function getSchemaElements(schema:XML, standardNameSpace:Namespace):Dictionary {
            var result:Dictionary = new Dictionary();
            var elements:XMLList = schema.standardNameSpace::element;
            for each (var element:XML in elements) {
                result[String(element.attribute("name"))] = element;
            }
            return result;
        }

        /**
         * get complexType tags from schema
         * @param schema current schema
         * @param standardNameSpace
         * @return collection of complexType tag
         */
        public static function getSchemaComplexTypes(schema:XML, standardNameSpace:Namespace):Dictionary {
            var result:Dictionary = new Dictionary();
            var complexTypes:XMLList = schema.standardNameSpace::complexType;
            for each (var complexType:XML in complexTypes) {
                var name:String = complexType.attribute("name");
                result[name] = complexType;
            }
            return result;
        }

        /**
         * get complexType tags with abstract="true" attribute from schema
         * @param schema current schema
         * @param standardNameSpace
         * @return collection of complexType tag
         */
        public static function getAbstractComplexTypes(schema:XML, standardNameSpace:Namespace):Dictionary {
            var result:Dictionary = new Dictionary();
            var complexTypes:XMLList = schema.standardNameSpace::complexType;
            for each (var complexType:XML in complexTypes) {
                if ("@abstract" in complexType && parseBooleanAttribute(complexType, "abstract")) {
                    var name:String = complexType.attribute("name");
                    result[name] = complexType;
                }
            }
            return result;
        }

        //endregion

        //region Content retrieving

        /**
         * retrieve tag completion information (ex: "<tes" ctrl+space key pressed)
         * @param position current begin tag description
         * @param schemaDescription current schema
         * @return collection of possible tag
         */
        public function retrieveTagCompletionInformation(position:XmlBeginTagPosition, schemaDescription:SchemaDescription):ArrayCollection {
            var parentTagName:String = position.parentTagName;
            var presetChars:String = position.presetChars;
            fillCurrentSchemaDescription(presetChars, schemaDescription);
            if (m_currentSchemaDescription != null) {
                if (parentTagName != null && parentTagName != "" && isParentTagNameCorrespondToSearch(parentTagName)) {
                    if (m_currentSchemaDescription.prefix != DEFAULT_SCHEMA_INDEX) {
                        // find prefix on parent tag
                        if (parentTagName.indexOf(m_currentSchemaDescription.prefix) != -1) {
                            parentTagName = parentTagName.slice(parentTagName.indexOf(":") + 1, parentTagName.length);
                        } else {
                            parentTagName = "";
                        }
                        // reset schema prefix from preset chars
                        presetChars = presetChars.slice(m_currentSchemaDescription.prefix.length + 1, presetChars.length);
                    }
                    return findAvailableChildren(parentTagName, presetChars, PROCESS_TAG);
                } else {
                    return m_currentSchemaDescription.rootTagNames;
                }
            }
            return null;
        }

        /**
         * retrieve attribute completion information (ex: "<test attr" ctrl+space key pressed)
         * @param position current attribute description
         * @param filterFunction if need to filter attribute tag containing specific attribute(ex: attribute tag with use="required" attribute)
         * @return collection of possible attribute
         */
        public function retrieveAttributeCompletionInformation(position:XmlAttributePosition, filterFunction:Function = null):ArrayCollection /* of String */ {
            var availableChildren:ArrayCollection;
            fillCurrentSchemaDescription(position.currentTagName, null);
            if (m_currentSchemaDescription != null) {
                availableChildren = findAvailableChildren(position.currentTagName, position.presetChars, PROCESS_ATTRIBUTE, filterFunction);
                if (position.alreadyUsedAttributes != null && availableChildren != null) {
                    for each (var alreadyUsedAttribute:String in position.alreadyUsedAttributes) {
                        if (availableChildren.contains(alreadyUsedAttribute)) {
                            availableChildren.removeItemAt(availableChildren.getItemIndex(alreadyUsedAttribute));
                        }
                    }
                }
                return availableChildren;
            }
            return availableChildren;
        }

        /**
         * retrieve attribute edition completion information (ex: "<test attribute="t" ctrl+space key pressed)
         * @param position current attribute content description
         * @return collection of possible attribute content
         */
        public function retrieveAttributeEditionCompletionInformation(position:XmlAttributeEditionPosition):ArrayCollection /* of String */ {
            fillCurrentSchemaDescription(position.currentTagName, null);
            if (m_currentSchemaDescription != null) {
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
                                                                .(attribute("name") == position.currentTagName).attribute("type").toXMLString());
                    var complexTypeNameWithoutPrefix:String = complexTypeName.replace(m_currentSchemaDescription.schemaInformation.schemaNameSpace.prefix.toString()
                                                                                              + ":", "");
                    // TODO: match ALL...not only here...
                    var simpleTypeName:String = String(schema.standardNameSpace::complexType.
                                                               (attribute("name") == complexTypeNameWithoutPrefix)..*::attribute
                                                               .(attribute("name") == position.currentAttributeName).attribute("type").toXMLString());
                    var simpleTypeNameWithoutPrefix:String = simpleTypeName.replace(m_currentSchemaDescription.schemaInformation.standardNameSpace.prefix.toString()
                                                                                            + ":", "");
                    if (simpleTypeNameWithoutPrefix == "boolean") {
                        result = new ArrayCollection(["true", "false"]);
                    }
                }
            }
            return result;
        }

        //endregion

        //region Tag processing
        /**
         * find available children
         * @param parent parent tag
         * @param presetChars preset chars
         * @param type PROCESS_ATTRIBUTE or PROCESS_TAG
         * @param filterFunction if need to filter attribute tag containing specific attribute(ex: attribute tag with use="required" attribute)
         * @return available children collection
         */
        private function findAvailableChildren(parent:String, presetChars:String, type:String, filterFunction:Function = null):ArrayCollection {
            var complexType:XML = findComplexType(parent);
            if (complexType != null && complexType.length() > 0) {
                return processComplexType(complexType, presetChars, type, filterFunction);
            }
            return null;
        }

        /**
         * find complex types
         * @param parent parent tag
         * @return retrieved complex type
         */
        private function findComplexType(parent:String):XML {
            if (m_currentSchemaDescription != null) {
                var element:XML = m_currentSchemaDescription.elements[parent];
                var standardNameSpace:Namespace;
                if (element != null) {
                    var complexType:XML;
                    var type:String = element.attribute("type");
                    if (type != null && type != "") { // complex type description in other tag
                        var convertType:String = type.replace(m_currentSchemaDescription.schemaInformation.schemaNameSpace.prefix.toString() + ":", "");
                        complexType = m_currentSchemaDescription.complexTypes[convertType];
                        return complexType;
                    } else if (element.hasComplexContent()) { // complex type description in other tag
                        standardNameSpace = m_currentSchemaDescription.schemaInformation.standardNameSpace;
                        complexType = XML(element.standardNameSpace::complexType);
                        return complexType;
                    }
                } else {
                    // worst code ever...
                    var descendants:XMLList = m_currentSchemaDescription.schema.descendants().(attribute("name") == parent);
                    if (descendants != null) {
                        var descendant:XML = XML(descendants[0]);
                        standardNameSpace = m_currentSchemaDescription.schemaInformation.standardNameSpace;
                        var temp:XMLList = descendant.standardNameSpace::complexType;
                        if (temp != null && temp.length() > 0) {
                            return XML(temp);
                        }
                    }
                }
            }
            return null;
        }

        /**
         * process complex type tags
         * @param complexType complex type
         * @param presetChars  preset char
         * @param type PROCESS_ATTRIBUTE or PROCESS_TAG
         * @param filterFunction if need to filter attribute tag containing specific attribute(ex: attribute tag with use="required" attribute)
         * @return collection of elements(String)
         */
        private function processComplexType(complexType:XML, presetChars:String, type:String, filterFunction:Function):ArrayCollection {
            if (complexType != null && complexType.length() > 0) {
                var result:ArrayCollection = new ArrayCollection();
                for each (var complexTypeChild:XML in complexType.children()) {
                    processContent(result, complexTypeChild, presetChars, type, filterFunction);
                }
                return result;
            }
            return null;
        }

        /**
         * process content type tags
         * @param complexType complex type
         * @param presetChars  preset char
         * @param type PROCESS_ATTRIBUTE or PROCESS_TAG
         * @param filterFunction if need to filter attribute tag containing specific attribute(ex: attribute tag with use="required" attribute)
         * @return collection of elements(String)
         */
        private function processContent(result:ArrayCollection, complexType:XML, presetChars:String, type:String, filterFunction:Function):void {
            var complexTypeLocalName:String = complexType.localName();
            if (complexTypeLocalName == "complexContent") {
                append(result, processComplexContent(complexType, presetChars, type, filterFunction));
            } else if (complexTypeLocalName == "sequence") {
                append(result, processSequence(complexType, presetChars, type));
            } else if (complexTypeLocalName == "attribute" && type == PROCESS_ATTRIBUTE) {
                appendAttribute(complexType, result, presetChars, filterFunction);
            }
        }

        /**
         * process complexContent type tags
         * @param complexType complex type
         * @param presetChars  preset char
         * @param type PROCESS_ATTRIBUTE or PROCESS_TAG
         * @param filterFunction if need to filter attribute tag containing specific attribute(ex: attribute tag with use="required" attribute)
         * @return collection of elements(String)
         */
        private function processComplexContent(complexType:XML, presetChars:String, type:String, filterFunction:Function):ArrayCollection {
            var result:ArrayCollection = new ArrayCollection();
            var complexContents:XMLList = complexType.children();
            for each (var complexContent:XML in complexContents) {
                var complexContentName:String = complexContent.localName();
                if ("extension" == complexContentName) {
                    var base:String = complexContent.attribute("base");
                    var baseType:String = base.replace(m_currentSchemaDescription.schemaInformation.schemaNameSpace.prefix.toString() + ":", "");
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

        /**
         * process extension type tags
         * @param baseType complex type
         * @param presetChars  preset char
         * @param type PROCESS_ATTRIBUTE or PROCESS_TAG
         * @param filterFunction if need to filter attribute tag containing specific attribute(ex: attribute tag with use="required" attribute)
         * @return collection of elements(String)
         */
        private function processExtension(baseType:String, presetChars:String, type:String, filterFunction:Function):ArrayCollection {
            if (m_currentSchemaDescription != null) {
                var result:ArrayCollection = new ArrayCollection();
                var complexType:XML = m_currentSchemaDescription.abstractComplexTypes[baseType];
                if (complexType == null) {
                    complexType = m_currentSchemaDescription.complexTypes[baseType];
                }
                append(result, processComplexType(complexType, presetChars, type, filterFunction));
                return result;
            }
            return null;
        }

        /**
         * process sequence type tags
         * @param sequence sequence type tag
         * @param presetChars  preset char
         * @param type PROCESS_ATTRIBUTE or PROCESS_TAG
         * @return collection of elements(String)
         */
        private function processSequence(sequence:XML, presetChars:String, type:String):ArrayCollection {
            var result:ArrayCollection = new ArrayCollection();
            var sequenceChildren:XMLList = sequence.children();
            for each (var sequenceChild:XML in sequenceChildren) {
                var sequenceName:String = sequenceChild.localName();
                if ("element" == sequenceName && type == PROCESS_TAG) {
                    if (sequenceChild.hasOwnProperty("@ref")) {
                        var element:String = sequenceChild.attribute("ref");
                        var item:String = element.replace(m_currentSchemaDescription.schemaInformation.schemaNameSpace.prefix.toString() + ":", "");
                        appendItem(result, item, presetChars);
                    } else if (sequenceChild.hasOwnProperty("@name")) {
                        appendItem(result, String(sequenceChild.attribute("name")), presetChars);
                    }
                } else if ("choice" == sequenceName) {
                    append(result, processChoice(sequenceChild, presetChars, type));
                }
            }
            return result;
        }

        /**
         * process sequence type tags
         * @param choice choice type tag
         * @param presetChars  preset char
         * @param type PROCESS_ATTRIBUTE or PROCESS_TAG
         * @return collection of elements(String)
         */
        private function processChoice(choice:XML, presetChars:String, type:String):ArrayCollection {
            var result:ArrayCollection = new ArrayCollection();
            var choiceChildren:XMLList = choice.children();
            for each (var choiceChild:XML in choiceChildren) {
                var choiceName:String = choiceChild.localName();
                if ("element" == choiceName && type == PROCESS_TAG) {
                    var refAttribute:String = choiceChild.attribute("ref");
                    var typeAttribute:String = choiceChild.attribute("type");
                    var nameAttribute:String = choiceChild.attribute("name");
                    var item:String;
                    if (refAttribute != null && refAttribute != "") {
                        item = refAttribute.replace(m_currentSchemaDescription.schemaInformation.schemaNameSpace.prefix.toString() + ":", "");
                        appendItem(result, item, presetChars);
                    } else if (typeAttribute != null && typeAttribute != "" && nameAttribute != null && nameAttribute != "") {
                        appendItem(result, nameAttribute, presetChars);
                    }
                }
            }
            return result;
        }

        /**
         * determine if prefix is set
         * @param parentTagName parent tag name
         * @return boolean
         */
        private function isParentTagNameCorrespondToSearch(parentTagName:String):Boolean {
            return !(m_currentSchemaDescription.prefix != DEFAULT_SCHEMA_INDEX && parentTagName.indexOf(m_currentSchemaDescription.prefix) != 0);
        }

        //endregion

        //region Utils
        private static function appendAttribute(complexType:XML, result:ArrayCollection, presetChars:String, filterFunction:Function = null):void {
            if (filterFunction != null) {
                if (filterFunction(complexType)) {
                    appendItem(result, complexType.attribute("name"), presetChars);
                }
            } else {
                appendItem(result, complexType.attribute("name"), presetChars);
            }
        }

        private static function appendItem(result:ArrayCollection, item:String, presetChars:String):void {
            if (presetChars != null && presetChars != "" && item.indexOf(presetChars) != 0) {
                return;
            }
            result.addItem(item);
        }

        private function append(result:ArrayCollection, processComplexContent:ArrayCollection):void {
            for each (var tag:String in processComplexContent) {
                if (!result.contains(tag) && tag != "") {
                    if (m_currentSchemaDescription.prefix != DEFAULT_SCHEMA_INDEX) {
                        tag = m_currentSchemaDescription.prefix + ":" + tag;
                    }
                    result.addItem(tag);
                }
            }
        }

        private static function parseBooleanAttribute(complexType:XML, toParse:String):Boolean {
            return (complexType.@[toParse] == "true");
        }

        /**
         * extract item from source collection that are not include in target collection
         */
        private static function notIntersect(source:ArrayCollection, target:ArrayCollection):ArrayCollection {
            var result:ArrayCollection = new ArrayCollection();
            for each (var item:String in source) {
                if (!target.contains(item)) {
                    result.addItem(item);
                }
            }
            return result;
        }

        /**
         * No length property on dictinary...
         * @param dictionary
         * @return
         */
        public static function countDictionaryKeys(dictionary:Dictionary):int {
            var n:int = 0;
            for (var key:* in dictionary) {
                n++;
            }
            return n;
        }

        /**
         * Use to generate first tag with schema declarations
         * @param rootTagName
         * @return
         */
        public function generateHeaderForSchemaDescriptions(rootTagName:String):String {
            if (rootTagName != null && rootTagName.length > 0) {
                var result:String = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<" + rootTagName;
                for each (var schemaDescription:SchemaDescription in m_schemaDescriptions) {
                    result += " " + XML_NAMESPACE_DECLARATION;
                    if (schemaDescription.prefix != DEFAULT_SCHEMA_INDEX) {
                        result += ":" + schemaDescription.prefix;
                    }
                    result += "=\"" + schemaDescription.schemaInformation.targetNamespace + "\"";
                }
                result += ">\n" + "</" + rootTagName + ">";
                return result;
            }

            return null;

        }

        //endregion
    }
}
