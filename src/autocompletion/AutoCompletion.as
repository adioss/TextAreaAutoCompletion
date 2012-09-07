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

    private var m_textArea:TextArea;
    private var m_beginPosition:int = -1;
    private var m_endPosition:int = -1;

    // xml/xsd tools
    private var m_xmlPositionHelper:XmlPositionHelper;
    private var m_schemaParser:SchemaParser;
    private var m_currentXmlPosition:XmlPosition;
    private var m_generateSchemaHeader:Boolean;

    // textarea tools
    private var m_textAreaHelper:TextAreaHelper;
    // autocomplete selection with combobox
    private var m_autoCompleteList:List = new List();
    private var m_globalAutoCompleteListContent:Array = new Array();

    private var m_autoCompleteCanvas:Canvas = new Canvas();
    private var m_currentTypedWord:String;

    public function AutoCompletion(textArea:TextArea, schemas:ArrayCollection, generateSchemaHeader:Boolean) {
        m_textArea = textArea;
        m_generateSchemaHeader = generateSchemaHeader;
        m_xmlPositionHelper = new XmlPositionHelper(m_textArea);
        m_schemaParser = new SchemaParser(schemas);
        m_textAreaHelper = new TextAreaHelper();
        m_textArea.addEventListener(KeyboardEvent.KEY_DOWN, onTextAreaKeyDown);
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
        if (tagCompletions != null) {
            initializeAutoCompleteList(tagCompletions.source, presetChars);
            var currentPosition:Point = TextAreaHelper.getTextAreaCurrentGlobalCursorPosition(m_textArea,
                    havePreset ? presetChars.length : 0);
            var presetOffset:int = havePreset ? presetChars.length : 0;
            beginPosition = m_textArea.selectionBeginIndex - presetOffset;
            endPosition = m_textArea.selectionBeginIndex;
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
            if (currentTypedWord.length == 0) {
                removeAutoCompleteCanvas();
            } else {
                currentTypedWord = currentTypedWord.substring(0, currentTypedWord.length - 1);
                refreshListAndPosition(endPosition > 0 ? endPosition - 1 : endPosition);
            }
        } else if (isValidKeyCode(keyCode)) {
            var nextCharacter:String = String.fromCharCode(charCode);
            endPosition += 1;
            currentTypedWord += nextCharacter;
            appendCharToTextArea(nextCharacter); // update text area
            updateAutoCompleteList(); // update list
        }
    }

    private function isValidKeyCode(keyCode:uint):Boolean {
        return keyCode != Keyboard.CONTROL && keyCode != Keyboard.SHIFT;
    }

    private function refreshAfterHorizontalNavigation(keyCodeHorizontalNavigation:uint):void {
        if (currentTypedWord.length > 0) {
            if (keyCodeHorizontalNavigation == Keyboard.LEFT) {
                currentTypedWord = currentTypedWord.substr(0, currentTypedWord.length - 1);
            } else {
                currentTypedWord += m_textArea.text.substr(m_endPosition, 1);
            }
            refreshListAndPosition(endPosition > 0 ? endPosition - 1 : endPosition);
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
        var postText:String = "";
        var completionOffset:int = 0;
        if (m_currentXmlPosition is XmlBeginTagPosition) {
            var firstAttribute:String = retrieveFirstAttributeOfBeginTag(textToAppend);
            postText = "></" + textToAppend.substring(0, textToAppend.length) + ">";
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
        var textAreaContent:String = textToTransform.substring(0, beginPosition) +
                textToAppend + postText + textToTransform.substr(endPosition, textToTransform.length);
        endPosition += textToAppend.length - currentTypedWord.length + completionOffset;
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
        endPosition = centerPosition + textToAppend.length;
        var textAreaContent:String = content.substring(0, centerPosition) + (textToAppend)
                + (content.substring(endPosition - deltaToRetrieveEndPart, content.length));
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
        var result:String = textToTransform.substring(0, endPosition - 1) +
                charToAppend + textToTransform.substr(endPosition - 1, textToTransform.length);
        m_textArea.callLater(setTextAreaCallBack, new Array(result));
    }

    private function setTextAreaCallBack(selectedText:String):void {
        m_textArea.text = selectedText;
        setFocusToEndPosition();
    }

    private function setFocusToEndPosition():void {
        m_textArea.setSelection(endPosition, endPosition);
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
        currentTypedWord = havePreset ? presetChar : "";
        m_globalAutoCompleteListContent = wordList;
        if (havePreset) {
            wordList = filterWordListWithCurrentTypedWord();
        }
        m_autoCompleteList.dataProvider = wordList;
        m_autoCompleteList.rowCount = wordList.length > AUTOCOMPLETION_MAX_ROW_COUNT ? AUTOCOMPLETION_MAX_ROW_COUNT : wordList.length;
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
        beginPosition = -1;
        endPosition = -1;
        currentTypedWord = "";
    }

    private function updateAutoCompleteList():void {
        var newFilteredWordList:Array = filterWordListWithCurrentTypedWord();
        if (newFilteredWordList.length == 0) {
            m_textArea.callLater(removeAutoCompleteCanvas);
            m_textArea.callLater(m_textArea.setFocus);
            return;
        }
        m_autoCompleteList.dataProvider = newFilteredWordList;
        m_autoCompleteList.rowCount = newFilteredWordList.length > AUTOCOMPLETION_MAX_ROW_COUNT ? AUTOCOMPLETION_MAX_ROW_COUNT : newFilteredWordList.length;
        m_autoCompleteList.selectedIndex = 0;
    }

    private function filterWordListWithCurrentTypedWord():Array {
        var newFilteredWordList:Array = new Array();
        var lowerCaseItem:String;
        var typedWord:String = currentTypedWord.toLowerCase();
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
        endPosition = lastEndPosition;
        setFocusToEndPosition();
    }

    //endregion

    //region Getters/Setters
    private function set beginPosition(value:int):void {
        m_beginPosition = value;
    }

    private function get beginPosition():int {
        return m_beginPosition;
    }

    private function set endPosition(value:int):void {
        m_endPosition = value;
    }

    private function get endPosition():int {
        return m_endPosition
    }

    private function get currentTypedWord():String {
        return m_currentTypedWord;
    }

    private function set currentTypedWord(value:String):void {
        m_currentTypedWord = value;
    }

    //endregion
}
}
