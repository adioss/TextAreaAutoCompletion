/**
 *
 * User: A.PAILHES
 * Date: 01/08/12
 * Time: 00:21
 */
package autocompletion {
import autocompletion.model.position.XmlAttributeEditionPosition;
import autocompletion.model.position.XmlAttributePosition;
import autocompletion.model.position.XmlBasicPosition;
import autocompletion.model.position.XmlBeginTagPosition;
import autocompletion.model.position.XmlEndTagPosition;
import autocompletion.model.position.XmlPosition;

import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.ui.Keyboard;

import mx.collections.ArrayCollection;
import mx.containers.Canvas;
import mx.controls.List;
import mx.controls.TextArea;
import mx.core.mx_internal;
import mx.managers.PopUpManager;

use namespace mx_internal;

/**
 * Manage autocompletion:
 * - show/position list over textarea
 * - manage key/mouse events
 */
public class AutoCompletion {
    private static const AUTOCOMPLETION_MAX_ROW_COUNT:int = 10;
    private static const AUTOCOMPLETION_SELECTION_COLOR:int = 0xA4D3EE;
    private static const AUTOCOMPLETION_ROLLOVER_COLOR:int = 0xA4D3EE;
    private static const AUTOCOMPLETION_LIST_WIDTH:int = 160;

    private static const SLASH_CHAR:String = "/";
    private static const GREATER_CHAR:String = ">";

    private var m_textArea:TextArea;
    private var m_beginPosition:int = -1;
    private var m_endPosition:int = -1;

    // xml/xsd tools
    private var m_xmlPositionHelper:XmlPositionHelper;
    private var m_schemaParser:SchemaParser;
    private var m_currentXmlPosition:XmlPosition;

    // autocomplete selection with combobox
    private var m_autoCompleteList:List = new List();
    private var m_globalAutoCompleteListContent:Array = new Array();

    private var m_autoCompleteCanvas:Canvas = new Canvas();
    private var m_currentTypedWord:String;

    public function AutoCompletion(textArea:TextArea, schemas:ArrayCollection) {
        if (schemas != null && schemas.length > 0) {
            m_textArea = textArea;
            m_xmlPositionHelper = new XmlPositionHelper(m_textArea);
            m_schemaParser = new SchemaParser(schemas);
            m_textArea.addEventListener(KeyboardEvent.KEY_DOWN, onTextAreaKeyDown);
        }
    }

    public function stopCompletion():void {
        if (m_textArea != null) {
            m_textArea.removeEventListener(KeyboardEvent.KEY_DOWN, onTextAreaKeyDown);
        }
    }

    //region Events
    private function onTextAreaKeyDown(event:KeyboardEvent):void {
        if (event.ctrlKey && event.keyCode == Keyboard.SPACE) {
            // get cursor position in xml
            m_currentXmlPosition = m_xmlPositionHelper.getCurrentXmlPosition();
            if (m_currentXmlPosition is XmlBeginTagPosition
                    || m_currentXmlPosition is XmlAttributePosition
                    || m_currentXmlPosition is XmlAttributeEditionPosition) {
                initializeCompletion();
            } else if (m_currentXmlPosition is XmlEndTagPosition) {
                completeEndTag();
            }
        } else if (String.fromCharCode(event.charCode) == SLASH_CHAR ||
                String.fromCharCode(event.charCode) == GREATER_CHAR) { // for "/" and ">"
            m_currentXmlPosition = m_xmlPositionHelper.getCurrentXmlPosition();
            if (m_currentXmlPosition is XmlAttributePosition) {
                clauseCurrentTag(String.fromCharCode(event.charCode),
                                 XmlAttributePosition(m_currentXmlPosition).currentTagName);
            } else if (m_currentXmlPosition is XmlBeginTagPosition) {
                var position:XmlBeginTagPosition = XmlBeginTagPosition(m_currentXmlPosition);
                var tags:ArrayCollection = m_schemaParser.retrieveTagCompletionInformation(position);
                if (tags != null && tags.length == 1 && tags.getItemAt(0) == position.presetChars) {
                    clauseCurrentTag(String.fromCharCode(event.charCode), position.presetChars);
                }
            }
        }
    }

    private function onKeyPressedWhenCanvasIsShown(event:KeyboardEvent):void {
        var charCode:uint = event.charCode;
        var keyCode:uint = event.keyCode;
        manageKeyPressedOnTextArea(charCode, keyCode);
    }

    private function onTextAreaClickWhenCanvasIsShown(event:MouseEvent):void {
        removeAutoCompleteCanvas();
    }

    private function onListClickWhenCanvasIsShown(event:MouseEvent):void {
        appendAutoCompletionItemSelection();
    }

    private function onKeyPressedWhenListIsSelected(event:KeyboardEvent):void {
        var charCode:uint = event.charCode;
        var keyCode:uint = event.keyCode;
        setFocusToEndPosition();
        manageKeyPressedOnTextArea(charCode, keyCode);
    }

    //endregion

    //region Completion
    private function initializeCompletion():void {
        var xmlPosition:XmlBasicPosition = XmlBasicPosition(m_currentXmlPosition);
        var presetChars:String = xmlPosition.presetChars;
        var havePreset:Boolean = presetChars != null && presetChars != "";
        var tagCompletions:ArrayCollection;
        if (m_currentXmlPosition is XmlBeginTagPosition) {
            tagCompletions = m_schemaParser.retrieveTagCompletionInformation(XmlBeginTagPosition(m_currentXmlPosition));
        } else if (m_currentXmlPosition is XmlAttributeEditionPosition) {
            tagCompletions = m_schemaParser.
                    retrieveAttributeEditionCompletionInformation(XmlAttributeEditionPosition(m_currentXmlPosition));
        } else if (m_currentXmlPosition is XmlAttributePosition) {
            tagCompletions = m_schemaParser.
                    retrieveAttributeCompletionInformation(XmlAttributePosition(m_currentXmlPosition));
        }
        if (tagCompletions != null && tagCompletions.length > 0) {
            initializeAutoCompleteList(tagCompletions.source, presetChars);
            var presetOffset:int = havePreset ? presetChars.length : 0;
            var currentPosition:Point = TextAreaHelper.getTextAreaCurrentGlobalCursorPosition(m_textArea, presetOffset);
            m_beginPosition = m_textArea.selectionBeginIndex - presetOffset;
            m_endPosition = m_textArea.selectionBeginIndex;
            showAutoCompleteCanvas(currentPosition);
            manageAutoCompleteCanvas();
        }
    }

    //endregion


    //region Manage TextArea
    private function manageKeyPressedOnTextArea(charCode:uint, keyCode:uint):void {
        if (charCode == Keyboard.ENTER) {
            appendAutoCompletionItemSelection();
        } else if (charCode == Keyboard.ESCAPE) {
            removeAutoCompleteCanvas();
        } else if (keyCode == Keyboard.UP || keyCode == Keyboard.DOWN) {
            refreshAfterVerticalNavigation(keyCode);
        } else if (keyCode == Keyboard.LEFT || keyCode == Keyboard.RIGHT) {
            refreshAfterHorizontalNavigation(keyCode);
        } else if (charCode == Keyboard.BACKSPACE) {
            if (m_currentTypedWord.length == 0) {
                removeAutoCompleteCanvas();
            } else {
                m_currentTypedWord = m_currentTypedWord.substring(0, m_currentTypedWord.length - 1);
                refreshListAndPosition(m_endPosition > 0 ? m_endPosition - 1 : m_endPosition);
            }
        } else if (isValidKeyCode(keyCode)) {
            var nextCharacter:String = String.fromCharCode(charCode);
            m_endPosition += 1;
            m_currentTypedWord += nextCharacter;
            appendCharToTextArea(nextCharacter); // update text area
            updateAutoCompleteList(); // update list
        }
    }

    private static function isValidKeyCode(keyCode:uint):Boolean {
        return keyCode != Keyboard.CONTROL && keyCode != Keyboard.SHIFT;
    }

    private function refreshAfterHorizontalNavigation(keyCodeHorizontalNavigation:uint):void {
        if (m_currentTypedWord.length > 0) {
            if (keyCodeHorizontalNavigation == Keyboard.LEFT) {
                m_currentTypedWord = m_currentTypedWord.substr(0, m_currentTypedWord.length - 1);
            } else {
                m_currentTypedWord += m_textArea.text.substr(m_endPosition, 1);
            }
            refreshListAndPosition(m_endPosition > 0 ? m_endPosition - 1 : m_endPosition);
        } else {
            removeAutoCompleteCanvas();
        }
    }

    private function refreshAfterVerticalNavigation(keyCode:uint):void {
        var offsetDirection:int;
        if (keyCode == Keyboard.UP) {
            offsetDirection = m_autoCompleteList.selectedIndex != 0 ? -1 : 0;
        } else {
            offsetDirection = 1;
        }
        m_autoCompleteList.selectedIndex += offsetDirection;
        m_autoCompleteList.scrollToIndex(m_autoCompleteList.selectedIndex);
        setFocusToEndPosition();
    }

    private function appendTextToTextArea(textToAppend:String):void {
        var textToTransform:String = m_textArea.text;
        var completionOffset:int = 0;
        if (m_currentXmlPosition is XmlBeginTagPosition) {
            var firstAttribute:String = retrieveFirstAttributeOfBeginTag(textToAppend);
            if (firstAttribute != null && firstAttribute.length > 0) {
                textToAppend += " ";
                textToAppend += firstAttribute + "=\"\"";
                completionOffset = -1;

            }
        } else if (m_currentXmlPosition is XmlAttributePosition
                && !(m_currentXmlPosition is XmlAttributeEditionPosition)) {
            textToAppend += "=\"\"";
            completionOffset = -1;
        }
        var textAreaContent:String = textToTransform.substring(0, m_beginPosition) +
                textToAppend + textToTransform.substr(m_endPosition, textToTransform.length);
        m_endPosition += textToAppend.length - m_currentTypedWord.length + completionOffset;
        m_textArea.callLater(setTextAreaCallBack, new Array(textAreaContent));
    }

    private function clauseCurrentTag(currentChar:String, tagCompletion:String):void {
        var content:String = m_textArea.text;
        var currentPosition:int = m_textArea.selectionBeginIndex;
        var textToAppend:String = "";
        if (currentChar == GREATER_CHAR) {
            m_endPosition = currentPosition + 1;
            textToAppend = ">" + "</" + tagCompletion + ">";
        } else if (currentChar == SLASH_CHAR) {
            textToAppend = "/>";
            m_endPosition = currentPosition + textToAppend.length;
        }
        var textAreaContent:String = content.substring(0, currentPosition) + (textToAppend)
                + (content.substring(currentPosition, content.length));
        m_textArea.callLater(setTextAreaCallBack, new Array(textAreaContent));
    }

    private function completeEndTag():void {
        var xmlEndTagPosition:XmlEndTagPosition = XmlEndTagPosition(m_currentXmlPosition);
        var content:String = m_textArea.text;
        var currentPosition:int = m_textArea.selectionBeginIndex;
        var centerPosition:int = xmlEndTagPosition.presetChars != null ?
                currentPosition - xmlEndTagPosition.presetChars.length : currentPosition;
        var textToAppend:String = xmlEndTagPosition.associatedTagName;
        var isClosedTag:Boolean = false;
        if (currentPosition < content.length) {
            if (content.charAt(currentPosition) != ">") {
                isClosedTag = true;
                textToAppend += (">");
            }
        } else {
            isClosedTag = true;
            textToAppend += (">");
        }
        var deltaToRetrieveEndPart:int = (xmlEndTagPosition.associatedTagName.length
                - (xmlEndTagPosition.presetChars != null ? xmlEndTagPosition.presetChars.length : 0))
                + (isClosedTag ? 1 : 0);
        m_endPosition = centerPosition + textToAppend.length;
        var textAreaContent:String = content.substring(0, centerPosition) + (textToAppend)
                + (content.substring(m_endPosition - deltaToRetrieveEndPart, content.length));
        m_textArea.callLater(setTextAreaCallBack, new Array(textAreaContent));
    }

    private function retrieveFirstAttributeOfBeginTag(beginTagName:String):String {
        var firstAttribute:String = null;
        if (beginTagName != null && beginTagName.length > 0) {
            var retrieveAttributeCompletionInformation:ArrayCollection = m_schemaParser.
                    retrieveAttributeCompletionInformation(new XmlAttributePosition(beginTagName,
                                                                                    null), filterByRequiredUse);
            if (retrieveAttributeCompletionInformation != null && retrieveAttributeCompletionInformation.length > 0) {
                firstAttribute = String(retrieveAttributeCompletionInformation.getItemAt(0));
            }
        }
        return firstAttribute;
    }

    private static function filterByRequiredUse(complexType:XML):Boolean {
        var used:String = String(complexType.attribute("use"));
        return used == "required";
    }

    private function appendCharToTextArea(charToAppend:String):void {
        var textToTransform:String = m_textArea.text;
        var result:String = textToTransform.substring(0, m_endPosition - 1) +
                charToAppend + textToTransform.substr(m_endPosition - 1, textToTransform.length);
        m_textArea.callLater(setTextAreaCallBack, new Array(result));
    }

    private function setTextAreaCallBack(selectedText:String):void {
        m_textArea.text = selectedText;
        setFocusToEndPosition();
    }

    private function setFocusToEndPosition():void {
        m_textArea.setSelection(m_endPosition, m_endPosition);
        m_textArea.setFocus();
    }

    //endregion

    //region Manage AutoCompletionList
    private function initializeAutoCompleteList(wordList:Array, presetChar:String):void {
        var havePreset:Boolean = presetChar != null && presetChar != "";
        m_autoCompleteList.setStyle("rollOverColor", AUTOCOMPLETION_ROLLOVER_COLOR);
        m_autoCompleteList.setStyle("m_selectionColor", AUTOCOMPLETION_SELECTION_COLOR);
        m_autoCompleteList.width = AUTOCOMPLETION_LIST_WIDTH;
        m_autoCompleteList.doubleClickEnabled = true;
        m_currentTypedWord = havePreset ? presetChar : "";
        m_globalAutoCompleteListContent = wordList;
        if (havePreset) {
            wordList = filterWordListWithCurrentTypedWord();
        }
        m_autoCompleteList.dataProvider = wordList;
        m_autoCompleteList.rowCount =
                wordList.length > AUTOCOMPLETION_MAX_ROW_COUNT ? AUTOCOMPLETION_MAX_ROW_COUNT : wordList.length;
    }

    private function showAutoCompleteCanvas(currentPosition:Point):void {
        var previousCharBounds:Rectangle = TextAreaHelper.getPreviousCharBounds(m_textArea);
        m_autoCompleteCanvas = new Canvas();
        m_autoCompleteCanvas.x = currentPosition.x - previousCharBounds.width;
        m_autoCompleteCanvas.y = currentPosition.y + previousCharBounds.height;
        m_autoCompleteList.selectedIndex = 0;
        m_autoCompleteCanvas.addChild(m_autoCompleteList);

        PopUpManager.addPopUp(m_autoCompleteCanvas, m_textArea, false);
    }

    private function manageAutoCompleteCanvas():void {
        m_textArea.removeEventListener(KeyboardEvent.KEY_DOWN, onTextAreaKeyDown);
        m_textArea.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPressedWhenCanvasIsShown);
        m_textArea.addEventListener(MouseEvent.CLICK, onTextAreaClickWhenCanvasIsShown);
        m_autoCompleteList.addEventListener(MouseEvent.DOUBLE_CLICK, onListClickWhenCanvasIsShown);
        m_autoCompleteList.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPressedWhenListIsSelected);
    }

    private function removeAutoCompleteCanvas():void {
        PopUpManager.removePopUp(m_autoCompleteCanvas);
        m_autoCompleteList.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPressedWhenListIsSelected);
        m_autoCompleteList.removeEventListener(MouseEvent.DOUBLE_CLICK, onListClickWhenCanvasIsShown);
        m_textArea.removeEventListener(MouseEvent.CLICK, onTextAreaClickWhenCanvasIsShown);
        m_textArea.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPressedWhenCanvasIsShown);
        m_textArea.addEventListener(KeyboardEvent.KEY_DOWN, onTextAreaKeyDown);
        m_autoCompleteCanvas = null;
        m_currentXmlPosition = null;
        m_beginPosition = -1;
        m_endPosition = -1;
        m_currentTypedWord = "";
    }

    private function updateAutoCompleteList():void {
        var newFilteredWordList:Array = filterWordListWithCurrentTypedWord();
        if (newFilteredWordList.length == 0) {
            m_textArea.callLater(removeAutoCompleteCanvas);
            m_textArea.callLater(m_textArea.setFocus);
            return;
        }
        m_autoCompleteList.dataProvider = newFilteredWordList;
        m_autoCompleteList.rowCount =
                newFilteredWordList.length > AUTOCOMPLETION_MAX_ROW_COUNT ? AUTOCOMPLETION_MAX_ROW_COUNT :
                        newFilteredWordList.length;
        m_autoCompleteList.selectedIndex = 0;
    }

    private function filterWordListWithCurrentTypedWord():Array {
        var newFilteredWordList:Array = new Array();
        var lowerCaseItem:String;
        var typedWord:String = m_currentTypedWord.toLowerCase();
        for each (var item:String in m_globalAutoCompleteListContent) {
            lowerCaseItem = item.toLocaleLowerCase();
            if (lowerCaseItem.substr(0, typedWord.length) == typedWord) {
                newFilteredWordList.push(item);
            }
        }
        return newFilteredWordList;
    }

    private function appendAutoCompletionItemSelection():void {
        var selectedText:String = String(m_autoCompleteList.selectedItem);
        appendTextToTextArea(selectedText);
        m_textArea.callLater(removeAutoCompleteCanvas);
    }

    private function refreshListAndPosition(lastEndPosition:int):void {
        updateAutoCompleteList();
        m_endPosition = lastEndPosition;
        setFocusToEndPosition();
    }

    //endregion

    //region Utils
    public function generateHeaderForSchemaDescriptions(rootTagName:String):String {
        if (m_schemaParser) {
            return m_schemaParser.generateHeaderForSchemaDescriptions(rootTagName);
        }
        return "";
    }

    //endregion
}
}
