/**
 * Created with IntelliJ IDEA.
 * User: A.PAILHES
 * Date: 14/07/12
 * Time: 01:07
 *
 */
package autocompletion {
import autocompletion.model.position.XmlAttributeEditionPosition;
import autocompletion.model.position.XmlAttributePosition;
import autocompletion.model.position.XmlBeginTagPosition;
import autocompletion.model.position.XmlContentPosition;
import autocompletion.model.position.XmlEndTagPosition;
import autocompletion.model.position.XmlPosition;

import mx.collections.ArrayCollection;
import mx.controls.TextArea;

public class XmlPositionHelper {
    private var m_textArea:TextArea;

    public function XmlPositionHelper(textArea:TextArea) {
        m_textArea = textArea;
    }

    public function getCurrentXmlPosition():XmlPosition {
        var content:String = m_textArea.text;
        var currentPosition:int = m_textArea.selectionBeginIndex;
        return XmlPositionHelper.retrieveXmlPosition(content, currentPosition);
    }

    private static function retrieveXmlPosition(content:String, currentPosition:int):XmlPosition {
        var contentToBegin:String = TextAreaHelper.prepareContent(getTextToBegin(content, currentPosition));
        var processedChar:String = "";
        var collectedTagName:String = "";
        var collectedAttributeName:String = "";
        var attributeEditionContent:String = "";
        var isAttributeEditionPosition:Boolean = false;
        var attributeNameCollected:Boolean = false;
        var isSpaceFound:Boolean = false;
        var stopCollectAttribute:Boolean = false;
        var isQuoteFound:Boolean = false;
        var alreadyUsedAttributes:ArrayCollection = new ArrayCollection();

        if (contentToBegin.length > 2) {
            if (contentToBegin.charAt(contentToBegin.length - 1) == "\""
                    && contentToBegin.charAt(contentToBegin.length - 2) != "=") {
                return new XmlContentPosition();
            }
        }

        var contentLength:int = contentToBegin.length;
        while (contentLength-- > 0) {
            processedChar = contentToBegin.charAt(contentLength);
            switch (processedChar) {
                case  " ":
                    isSpaceFound = stopCollectAttribute = true;
                    if (attributeNameCollected) {
                        alreadyUsedAttributes.addItem(format(collectedTagName));
                    }
                    break;
                case "<":
                    if (isAttributeEditionPosition && attributeNameCollected) {
                        return new XmlAttributeEditionPosition(format(collectedTagName),
                                format(collectedAttributeName),
                                format(attributeEditionContent));
                    } else if (collectedTagName != "") {
                        var xmlAttributePosition:XmlAttributePosition = new XmlAttributePosition(
                                format(collectedTagName),
                                format(attributeEditionContent != null && attributeEditionContent != ""
                                        ? attributeEditionContent : collectedAttributeName),
                                alreadyUsedAttributes.length > 0 ? alreadyUsedAttributes : null);
                        return completeWithNextUsedAttributes(content, currentPosition, xmlAttributePosition);
                    } else {
                        return new XmlBeginTagPosition(findParentTagName(contentToBegin),
                                format(collectedAttributeName));
                    }
                case "/":
                    if (contentToBegin.charAt(contentLength - 1) == "<") {
                        return new XmlEndTagPosition(
                                findAssociatedTagName(contentToBegin, format(collectedAttributeName)), "");
                    }
                    break;
                case ">":
                    return new XmlContentPosition();
                case "\"":
                    collectedTagName = "";
                    if (!isSpaceFound && !isAttributeEditionPosition && !attributeNameCollected) {
                        isAttributeEditionPosition = true;
                    }
                    isQuoteFound = true;
                    break;
                case "=" :
                    if (!attributeNameCollected) {
                        attributeNameCollected = true;
                        attributeEditionContent = collectedAttributeName;
                        collectedAttributeName = "";
                    }
                    break;
                default :
                    if (!stopCollectAttribute && (!isQuoteFound || attributeNameCollected)) {
                        collectedAttributeName += processedChar;
                    }
                    if (isSpaceFound) {
                        if (isUsableChar(processedChar)) {
                            collectedTagName = "";
                        }
                        isSpaceFound = false;
                    }
                    if (stopCollectAttribute) {
                        collectedTagName += removeUnusableChar(processedChar);
                    }
            }
        }
        return null;
    }

    public static function findParentTagName(content:String):String {
        var contentLength:int = content.length;
        var processedChar:String;
        var processedTag:String = "";
        var processedBeginTags:ArrayCollection = new ArrayCollection();
        var processedEndTags:ArrayCollection = new ArrayCollection();
        var beginTagDetected:Boolean = false;
        var endTagDetected:Boolean = false;
        var collectTag:Boolean = true;
        var spaceDetected:Boolean = false;
        var processingAttribute:Boolean = false;
        var beginningQuoteParsing:Boolean = false;
        var simpleFormattedTag:Boolean = false;

        while (contentLength-- > 0) {
            processedChar = content.charAt(contentLength);
            switch (processedChar) {
                case  "<":
                    if (!simpleFormattedTag
                            && contentLength < content.length && content.charAt(contentLength + 1) == "/") {
                        if (processedTag != "" && !processedEndTags.contains(processedTag)) {
                            processedEndTags.addItem(processedTag);
                        }
                        processedTag = "";
                        beginTagDetected = collectTag = simpleFormattedTag = false;
                    } else {
                        if (!simpleFormattedTag
                                && processedEndTags.length > 0
                                && !processedEndTags.contains(processedTag)
                                && processedTag != "") {
                            return format(processedTag);
                        }
                        if (processedTag != "") {
                            if (!simpleFormattedTag
                                    && processedTag != ""
                                    && !processedBeginTags.contains(processedTag)) {
                                if (endTagDetected) {
                                    processedBeginTags.addItem(processedTag);
                                }
                                if (processedBeginTags.length > processedEndTags.length) {
                                    return format(processedTag);
                                } else if (endTagDetected && contentLength == 0) {
                                    return format(processedTag);
                                }
                            }
                        }
                        beginTagDetected = true;
                        collectTag = simpleFormattedTag = endTagDetected = false;
                        processedTag = "";
                    }
                    break;
                case  ">":
                    spaceDetected = beginTagDetected = false;
                    collectTag = endTagDetected = true;
                    break;
                case  "/":
                    if (contentLength < content.length && content.charAt(contentLength + 1) == ">") {
                        simpleFormattedTag = true;
                    }
                    break;
                case  "\"":
                    processingAttribute = true;
                    beginningQuoteParsing = !beginningQuoteParsing;
                    break;
                case  " ":
                    spaceDetected = true;
                    processedTag = "";
                    break;
                default :
                    if (collectTag) {
                        if (spaceDetected) {
                            spaceDetected = processingAttribute = false;
                            processedTag = "";
                        }
                        if (!beginningQuoteParsing && !processingAttribute) {
                            processedTag += processedChar;
                        }
                    }
            }
        }
        return null;
    }

    public static function findAssociatedTagName(content:String, prefix:String):String {
        var contentLength:int = content.length;
        var processedChar:String;
        var processedTag:String = "";
        var collectTag:Boolean = true;
        var beginningQuoteParsing:Boolean = false;
        var beginningAttributeParsing:Boolean = false;
        var spaceDetected:Boolean = false;
        var foundPrefix:Boolean = false;
        while (contentLength-- > 0) {
            processedChar = content.charAt(contentLength);
            if (processedChar == "<" && !beginningQuoteParsing) {
                if (contentLength < content.length) {
                    if (content.charAt(contentLength + 1) != "/") {
                        var formatted:String = format(processedTag);
                        if (formatted.search(prefix) != -1) {
                            return formatted;
                        }
                    }
                }
            } else if (processedChar == ">" && !beginningQuoteParsing) {
                collectTag = true;
            } else if (processedChar == " " || !isUsableChar(processedChar)) {
                if (beginningAttributeParsing) {
                    processedTag = "";
                }
                spaceDetected = true;
            } else if (processedChar == "\"") {
                beginningQuoteParsing = !beginningQuoteParsing;
                processedTag = "";
            } else if (processedChar == "/" && !beginningQuoteParsing) {
                if (!foundPrefix && format(processedTag) != prefix && processedTag.search(prefix) == -1) {
                    return null;
                } else {
                    foundPrefix = true
                }
                processedTag = "";
                collectTag = false;
            } else if (collectTag) {
                if (spaceDetected) {
                    spaceDetected = false;
                    processedTag = "";
                }
                processedTag += processedChar;
            }
        }
        return null;
    }

    public static function completeWithNextUsedAttributes(content:String, currentPosition:int, xmlAttributePosition:XmlAttributePosition):XmlAttributePosition {
        var contentToEnd:String = TextAreaHelper.prepareContent(getTextToEnd(content, currentPosition));
        var stopCollecting:Boolean = false;
        var processedChar:String;
        var currentCollectedChars:String = "";
        for (var contentLength:int = 0; contentLength < contentToEnd.length; contentLength++) {
            processedChar = content.charAt(contentLength);
            switch (processedChar) {
                case  " " || "\"":
                    currentCollectedChars = "";
                    break;
                case  ">" || "<":
                    stopCollecting = true;
                    break;
                case  "=":
                    xmlAttributePosition.alreadyUsedAttributes.addItem(currentCollectedChars);
                    currentCollectedChars = "";
                    break;
                default:
                {
                    currentCollectedChars += processedChar;
                }
            }
            if (stopCollecting) {
                break;
            }
            processedChar = contentToEnd.charAt(contentLength);
        }
        return xmlAttributePosition;
    }

    private static function format(toReverse:String):String {
        var reversed:String = toReverse.split("").reverse().join("");
        return removeUnusableChar(reversed);
    }

    private static function removeUnusableChar(toClean:String):String {
        var regExp:RegExp = /^\s*(.*?)\s*$/g;
        return toClean.replace(regExp, "$1");
    }

    private static function isUsableChar(toCheck:String):Boolean {
        var regExp:RegExp = /^\s*(.*?)\s*$/g;
        return toCheck.replace(regExp, "$1").length == toCheck.length;
    }

    private static function getTextToBegin(content:String, currentPosition:int):String {
        var result:String = content.substr(0, currentPosition);
        return result;
    }

    private static function getTextToEnd(content:String, currentPosition:int):String {
        var result:String = content.substr(currentPosition, content.length);
        return result;
    }
}
}
