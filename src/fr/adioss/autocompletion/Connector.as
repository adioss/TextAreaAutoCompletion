/* ---------------
 // Connector Class
 // ---------------
 //
 // AUTHOR:  Sammy Joe Osborne
 // DATE:    07/15/2007
 //
 // DESCRIPTION: Creates a connection between two display objects.  The first parameter is considered the parent.
 */

package fr.adioss.autocompletion {
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.Event;

    import mx.core.IUIComponent;
    import mx.managers.ISystemManager;

    public class Connector extends Sprite implements IUIComponent {

        private var line:Shape = new Shape;
        private var triangle:Shape = new Shape;
        private var _obj1:DisplayObject;
        private var _obj2:DisplayObject;
        private var _obj1X:Number;
        private var _obj2X:Number;
        private var _obj1Y:Number;
        private var _obj2Y:Number;
        private const ARROW_SPACE = 8;
        private var _lineColor:uint;
        private var _lineThickness:uint;
        private var _usePointer:Boolean;

        public function Connector(obj1:DisplayObject, obj2:DisplayObject):void {
            _obj1 = obj1;
            _obj2 = obj2;
            init();
        }

        private function init():void {
            _obj1X = _obj1.x;
            _obj1Y = _obj1.y;
            _obj2X = _obj2.x;
            _obj2Y = _obj2.y;
            _lineColor = 0x000000;
            _lineThickness = 2;
            _usePointer = true;
            addChild(line);
            addChild(triangle);
            drawConnector();
            drawTriangle();

            //constantly checking to see if either display objects have moved
            _obj1.addEventListener(Event.ENTER_FRAME, checkForMove);
            _obj2.addEventListener(Event.ENTER_FRAME, checkForMove);
        }

        private function checkForMove(event:Event):void {
            if ((_obj1X != _obj1.x) || (_obj1Y != _obj1.y) || (_obj2X != _obj2.x) || (_obj2Y != _obj2.y)) {
                drawConnector();
                _obj1X = _obj1.x;
                _obj1Y = _obj1.y;
                _obj2X = _obj2.x;
                _obj2Y = _obj2.y;
            }
        }

        private function drawConnector() {
            line.graphics.clear();
            line.graphics.lineStyle(_lineThickness, _lineColor, 1);

            if (isFullyLeftOf(_obj1, _obj2)) {
                if (isFullyAbove(_obj1, _obj2)) {
                    bottomToTop();
                } else if (isFullyBelow(_obj1, _obj2)) {
                    topToBottom();
                } else {
                    rightToLeft();
                }
            } else if (isFullyRightOf(_obj1, _obj2)) {
                if (isFullyAbove(_obj1, _obj2)) {
                    bottomToTop();
                } else if (isFullyBelow(_obj1, _obj2)) {
                    topToBottom();
                } else {
                    leftToRight();
                }
            } else if (isFullyAbove(_obj1, _obj2)) {
                bottomToTop();
            } else if (isFullyBelow(_obj1, _obj2)) {
                topToBottom();
            } else {
                centerToCenter();
            }
        }

        //this is the arrow on the end of the line
        private function drawTriangle():void {
            triangle.graphics.clear();
            triangle.graphics.beginFill(lineColor, 1);
            triangle.graphics.moveTo(lineThickness + 1.5, 0);
            triangle.graphics.lineTo(-(lineThickness + 1.5), 0);
            triangle.graphics.lineTo(0, ARROW_SPACE);
            triangle.graphics.lineTo(lineThickness + 1.5, 0);
            triangle.graphics.endFill();
        }

        public function reverse():void {
            var temp:DisplayObject = _obj1;
            _obj1 = _obj2;
            _obj2 = temp;
        }

        public function set lineThickness(value:uint):void {
            _lineThickness = value;
            drawTriangle();
            drawConnector();
        }

        public function get lineThickness():uint {
            return _lineThickness;
        }

        public function set lineColor(value:uint):void {
            _lineColor = value;
            drawTriangle();
            drawConnector();

        }

        public function get lineColor():uint {
            return _lineColor;
        }

        public function getParent():DisplayObject {
            return _obj1;
        }

        public function setParent(value:DisplayObject):void {
            _obj1 = value;
            drawTriangle();
            drawConnector();
        }

        public function getChild():DisplayObject {
            return _obj2;
        }

        public function setChild(value:DisplayObject):void {
            _obj2 = value;
            drawTriangle();
            drawConnector();
        }

        public function set usePointer(value:Boolean):void {
            _usePointer = value;
            drawTriangle();
            drawConnector();

        }

        public function get usePointer():Boolean {
            return _usePointer;
        }

        //from the right side of obj1 to the left side of obj2
        private function rightToLeft():void {
            line.graphics.moveTo(_obj1.x + _obj1.width, _obj1.y + (_obj1.height / 2));

            if (_usePointer) {
                line.graphics.lineTo((_obj1.x + _obj1.width) + .5 * (_obj2.x - (_obj1.x + _obj1.width)) - ARROW_SPACE, _obj1.y + (_obj1.height / 2));
                line.graphics.lineTo((_obj1.x + _obj1.width) + .5 * (_obj2.x - (_obj1.x + _obj1.width)) - ARROW_SPACE, _obj2.y + (_obj2.height / 2));
                line.graphics.lineTo(_obj2.x - ARROW_SPACE + 1, _obj2.y + (_obj2.height / 2));
                triangle.visible = true;
                triangle.x = _obj2.x - ARROW_SPACE;
                triangle.y = _obj2.y + (_obj2.height / 2);
                triangle.rotation = -90;
            } else {
                line.graphics.lineTo((_obj1.x + _obj1.width) + .5 * (_obj2.x - (_obj1.x + _obj1.width)), _obj1.y + (_obj1.height / 2));
                line.graphics.lineTo((_obj1.x + _obj1.width) + .5 * (_obj2.x - (_obj1.x + _obj1.width)), _obj2.y + (_obj2.height / 2));
                line.graphics.lineTo(_obj2.x, _obj2.y + (_obj2.height / 2));
                triangle.visible = false;
            }
        }

        //from the left side of obj1 to the right side of obj2
        private function leftToRight():void {
            line.graphics.moveTo(_obj1.x, _obj1.y + (_obj1.height / 2));

            if (_usePointer) {
                line.graphics.lineTo((_obj2.x + _obj2.width) + .5 * (_obj1.x - (_obj2.x + _obj2.width)) + ARROW_SPACE, _obj1.y + (_obj1.height / 2));
                line.graphics.lineTo((_obj2.x + _obj2.width) + .5 * (_obj1.x - (_obj2.x + _obj2.width)) + ARROW_SPACE, _obj2.y + (_obj2.height / 2));
                line.graphics.lineTo((_obj2.x + _obj2.width) + ARROW_SPACE - 1, _obj2.y + _obj2.height / 2);
                triangle.visible = true;
                triangle.x = (_obj2.x + _obj2.width) + ARROW_SPACE;
                triangle.y = _obj2.y + _obj2.height / 2;
                triangle.rotation = 90;
            } else {
                line.graphics.lineTo((_obj2.x + _obj2.width) + .5 * (_obj1.x - (_obj2.x + _obj2.width)), _obj1.y + (_obj1.height / 2));
                line.graphics.lineTo((_obj2.x + _obj2.width) + .5 * (_obj1.x - (_obj2.x + _obj2.width)), _obj2.y + (_obj2.height / 2));
                line.graphics.lineTo((_obj2.x + _obj2.width), _obj2.y + _obj2.height / 2);
                triangle.visible = false;
            }

        }

        //from the top of obj1 to the bottom of obj2
        private function topToBottom():void {
            line.graphics.moveTo(_obj1.x + (_obj1.width / 2), _obj1.y);
            if (_usePointer) {
                line.graphics.lineTo(_obj1.x + (_obj1.width / 2), _obj1.y + .5 * ((_obj2.y + _obj2.height) - _obj1.y));
                line.graphics.lineTo(_obj2.x + (_obj2.width / 2), _obj1.y + .5 * ((_obj2.y + _obj2.height) - _obj1.y));
                line.graphics.lineTo(_obj2.x + (_obj2.width / 2), (_obj2.y + _obj2.height) + ARROW_SPACE - 1);
                triangle.visible = true;
                triangle.x = _obj2.x + (_obj2.width / 2);
                triangle.y = (_obj2.y + _obj2.height) + ARROW_SPACE;
                triangle.rotation = 180;
            } else {
                line.graphics.lineTo(_obj1.x + (_obj1.width / 2), _obj1.y + .5 * ((_obj2.y + _obj2.height) - _obj1.y));
                line.graphics.lineTo(_obj2.x + (_obj2.width / 2), _obj1.y + .5 * ((_obj2.y + _obj2.height) - _obj1.y));
                line.graphics.lineTo(_obj2.x + (_obj2.width / 2), (_obj2.y + _obj2.height));
                triangle.visible = false;
            }

        }

        //from the bottom of obj1 to the top of obj2
        private function bottomToTop():void {
            line.graphics.moveTo(_obj1.x + (_obj1.width / 2), _obj1.y + _obj1.height);
            if (_usePointer) {
                line.graphics.lineTo(_obj1.x + (_obj1.width / 2), (_obj1.y + _obj1.height) + .5 * (_obj2.y - (_obj1.y + _obj1.height)));
                line.graphics.lineTo(_obj2.x + (_obj2.width / 2), (_obj1.y + _obj1.height) + .5 * (_obj2.y - (_obj1.y + _obj1.height)));
                line.graphics.lineTo(_obj2.x + (_obj2.width / 2), _obj2.y - ARROW_SPACE + 1);
                triangle.visible = true;
                triangle.x = (_obj2.x + (_obj2.width / 2));
                triangle.y = _obj2.y - ARROW_SPACE;
                triangle.rotation = 0;
            } else {
                line.graphics.lineTo(_obj1.x + (_obj1.width / 2), (_obj1.y + _obj1.height) + .5 * (_obj2.y - (_obj1.y + _obj1.height)));
                line.graphics.lineTo(_obj2.x + (_obj2.width / 2), (_obj1.y + _obj1.height) + .5 * (_obj2.y - (_obj1.y + _obj1.height)));
                line.graphics.lineTo(_obj2.x + (_obj2.width / 2), _obj2.y);
                triangle.visible = false;
            }

        }

        //from the center of _obj1 to the center of _obj2
        private function centerToCenter():void {
            line.graphics.moveTo(_obj1.x + (_obj1.width / 2), _obj1.y + (_obj1.height / 2));
            line.graphics.lineTo(_obj2.x + (_obj2.width / 2), _obj2.y + (_obj2.height / 2));
            triangle.visible = false;
        }

        //checks if obj1 is fully above obj2 (this includes the space for the arrow)
        private function isFullyAbove(obj1:DisplayObject, obj2:DisplayObject):Boolean {
            return (obj1.y + obj1.height + ARROW_SPACE) < obj2.y;
        }

        //checks if obj1 is fully below obj2 (this includes the space for the arrow)
        private function isFullyBelow(obj1:DisplayObject, obj2:DisplayObject):Boolean {
            return obj1.y > (obj2.y + obj2.height + ARROW_SPACE);
        }

        //checks if obj1 is fully to the left of obj2 (this includes the space for the arrow)
        private function isFullyLeftOf(obj1:DisplayObject, obj2:DisplayObject):Boolean {
            return (obj1.x + obj1.width + ARROW_SPACE) < obj2.x;
        }

        //checks if obj1 is fully to the right of obj2 (this includes the space for the arrow)
        private function isFullyRightOf(obj1:DisplayObject, obj2:DisplayObject):Boolean {
            return obj1.x > (obj2.x + obj2.width + ARROW_SPACE);
        }

        public function get baselinePosition():Number {
            return 0;
        }

        public function get document():Object {
            return null;
        }

        public function set document(value:Object):void {
        }

        public function get enabled():Boolean {
            return false;
        }

        public function set enabled(value:Boolean):void {
        }

        public function get explicitHeight():Number {
            return 0;
        }

        public function set explicitHeight(value:Number):void {
        }

        public function get explicitMaxHeight():Number {
            return 0;
        }

        public function get explicitMaxWidth():Number {
            return 0;
        }

        public function get explicitMinHeight():Number {
            return 0;
        }

        public function get explicitMinWidth():Number {
            return 0;
        }

        public function get explicitWidth():Number {
            return 0;
        }

        public function set explicitWidth(value:Number):void {
        }

        public function get focusPane():Sprite {
            return null;
        }

        public function set focusPane(value:Sprite):void {
        }

        public function get includeInLayout():Boolean {
            return false;
        }

        public function set includeInLayout(value:Boolean):void {
        }

        public function get isPopUp():Boolean {
            return false;
        }

        public function set isPopUp(value:Boolean):void {
        }

        public function get maxHeight():Number {
            return 0;
        }

        public function get maxWidth():Number {
            return 0;
        }

        public function get measuredMinHeight():Number {
            return 0;
        }

        public function set measuredMinHeight(value:Number):void {
        }

        public function get measuredMinWidth():Number {
            return 0;
        }

        public function set measuredMinWidth(value:Number):void {
        }

        public function get minHeight():Number {
            return 0;
        }

        public function get minWidth():Number {
            return 0;
        }

        public function get owner():DisplayObjectContainer {
            return null;
        }

        public function set owner(value:DisplayObjectContainer):void {
        }

        public function get percentHeight():Number {
            return 0;
        }

        public function set percentHeight(value:Number):void {
        }

        public function get percentWidth():Number {
            return 0;
        }

        public function set percentWidth(value:Number):void {
        }

        public function get systemManager():ISystemManager {
            return null;
        }

        public function set systemManager(value:ISystemManager):void {
        }

        public function get tweeningProperties():Array {
            return null;
        }

        public function set tweeningProperties(value:Array):void {
        }

        public function initialize():void {
        }

        public function parentChanged(p:DisplayObjectContainer):void {
        }

        public function getExplicitOrMeasuredWidth():Number {
            return 0;
        }

        public function getExplicitOrMeasuredHeight():Number {
            return 0;
        }

        public function setVisible(value:Boolean, noEvent:Boolean = false):void {
        }

        public function owns(displayObject:DisplayObject):Boolean {
            return false;
        }

        public function get measuredHeight():Number {
            return 0;
        }

        public function get measuredWidth():Number {
            return 0;
        }

        public function move(x:Number, y:Number):void {
        }

        public function setActualSize(newWidth:Number, newHeight:Number):void {
        }
    }
}
