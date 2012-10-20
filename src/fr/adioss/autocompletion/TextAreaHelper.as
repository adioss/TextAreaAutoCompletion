/**
 *
 * User: A.PAILHES
 * Date: 01/08/12
 * Time: 00:49
 */
package fr.adioss.autocompletion {
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextFormat;

    import mx.controls.TextArea;
    import mx.core.IUITextField;
    import mx.core.mx_internal;

    use namespace mx_internal;

    /**
     * Tools for textarea
     * - clean unusable chars
     * - find position of a cursor
     */
    public class TextAreaHelper {
        private static var HEIGHT_PADDING:int = 2;
        private static const DEFAULT_CHAR_BOUNDARIES_WIDTH:int = 0;
        private static const DEFAULT_CHAR_BOUNDARIES_HEIGHT:int = 12;

        public function TextAreaHelper() {
        }

        /**
         * Get text area current global cursor position
         * @param textArea text area component
         * @param caretOffset if preset char, subtract preset char length
         * @return current x/y positions
         */
        public static function getTextAreaCurrentGlobalCursorPosition(textArea:TextArea, caretOffset:int = 0):Point {
            return textArea.getTextField().localToGlobal(getTextAreaCurrentCursorPosition(textArea, caretOffset));
        }

        /**
         * Get text area current cursor position
         * @param textArea text area component
         * @param caretOffset if preset char, subtract preset char length
         * @return current x/y positions
         */
        private static function getTextAreaCurrentCursorPosition(textArea:TextArea, caretOffset:int):Point {
            var textField:IUITextField = textArea.getTextField();
            var text:String = textArea.text;

            var index:int = textField.caretIndex - caretOffset;
            var cursorPoint:Point = new Point();
            var numberOfNewlines:int;
            var previousCharFormat:TextFormat;
            var previousCharBounds:Rectangle;
            var previousCharIndex:int;
            var nextCharIndex:int;
            var nextCharBounds:Rectangle;
            if (index == 0) {
                cursorPoint.x = (textField.getTextFormat(0).indent as Number) + (textField.getTextFormat(0).leftMargin as Number);
            } else if (index == text.length) {
                previousCharIndex = getPreviousCharacterIndex(text, index);
                numberOfNewlines = index - (previousCharIndex + 1);
                if (previousCharIndex != -1) {
                    previousCharBounds = textField.getCharBoundaries(previousCharIndex);
                }
                if (previousCharIndex == index - 1) {
                    cursorPoint.x = previousCharBounds.x + previousCharBounds.width;
                    cursorPoint.y = previousCharBounds.y;
                } else if (previousCharIndex != -1) {
                    cursorPoint.x = (textField.getTextFormat(index - 1).indent as Number) + (textField.getTextFormat(index - 1).leftMargin as Number);
                    previousCharFormat = textField.getTextFormat(previousCharIndex);
                    cursorPoint.y = previousCharBounds.y + (previousCharBounds.height - HEIGHT_PADDING) + ((previousCharFormat.leading as Number)
                            * numberOfNewlines);
                } else {
                    cursorPoint.x = (textField.getTextFormat(0).indent as Number) + (textField.getTextFormat(0).leftMargin as Number);
                    cursorPoint.y = ((textField.getTextFormat(0).leading as Number) * numberOfNewlines);
                }
            } else {
                previousCharIndex = getPreviousCharacterIndex(text, index);
                nextCharIndex = getNextCharacterIndex(text, index);
                if (previousCharIndex != -1 && previousCharIndex == index - 1) {
                    previousCharBounds = textField.getCharBoundaries(previousCharIndex);
                    cursorPoint.x = previousCharBounds.x + previousCharBounds.width;
                    cursorPoint.y = previousCharBounds.y;
                } else if (nextCharIndex != -1 && nextCharIndex == index + 1) {
                    nextCharBounds = textField.getCharBoundaries(nextCharIndex);
                    cursorPoint.x = nextCharBounds.x - nextCharBounds.width;
                    cursorPoint.y = nextCharBounds.y;
                } else if (previousCharIndex != -1) {
                    previousCharBounds = textField.getCharBoundaries(previousCharIndex);
                    numberOfNewlines = index - (previousCharIndex);
                    cursorPoint.x = (textField.getTextFormat(previousCharIndex).indent as Number);
                    cursorPoint.y = previousCharBounds.y + (previousCharBounds.height - HEIGHT_PADDING) + ((textField.getTextFormat(previousCharIndex).leading
                            as Number) * numberOfNewlines);
                }
            }
            return cursorPoint;
        }

        private static function getPreviousCharacterIndex(text:String, startIndex:int):int {
            for (var i:int = startIndex - 1; i >= 0; i--) {
                if (text.charAt(i) != "\r") {
                    return i;
                }
            }
            return -1;
        }

        private static function getNextCharacterIndex(text:String, startIndex:int):int {
            for (var i:int = startIndex + 1; i < text.length; i++) {
                if (text.charAt(i) != "\r") {
                    return i;
                }
            }
            return -1;
        }

        public static function getPreviousCharBounds(textArea:TextArea):Rectangle {
            var charBoundaries:Rectangle = textArea.getTextField().getCharBoundaries(textArea.selectionBeginIndex - 1);
            return charBoundaries != null ? charBoundaries : new Rectangle(0, 0, DEFAULT_CHAR_BOUNDARIES_WIDTH, DEFAULT_CHAR_BOUNDARIES_HEIGHT);
        }

        public static function prepareContent(content:String):String {
            // delete newline etc...
            content = content.replace(/[\r\n\t]+/g, "");
            // delete useless spaces between < >
            content = content.replace(/(>)(\s+)(<)/gi, "$1$3");
            // delete useless spaces between words, like "e        i" => "e i"
            content = content.replace(/(\w)(\s+)(\w)/gi, "$1 $3");
            // delete useless spaces between words, fist one not a char, like "<        i" => "<i"
            content = content.replace(/(<)(\s+)(\w)/gi, "$1$3");
            // delete attribute content
            content = content.replace(/(=")(\s*\w*\s*)(")/gi, "$1$3");
            // delete space between " and >
            content = content.replace(/(")(\s+)(>)/gi, "$1$3");
            return content;
        }
    }
}
