/**
 * Created with IntelliJ IDEA.
 * User: A.PAILHES
 * Date: 14/07/12
 * Time: 03:34
 *
 */
package fr.adioss.autocompletion.model.position {
public class XmlBasicPosition extends XmlPosition {
    public var presetChars:String;

    public function XmlBasicPosition(presetChars:String) {
        this.presetChars = presetChars;
    }


    override public function toString():String {
        return "XmlBasicPosition{presetChars=" + String(presetChars) + "}";
    }
}
}
