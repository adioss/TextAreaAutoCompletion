/**
 * Created with IntelliJ IDEA.
 * User: A.PAILHES
 * Date: 16/07/12
 * Time: 20:19
 *
 */
package autocompletion.model.position {
public class XmlBeginTagPosition extends XmlBasicPosition {
    public var parentTagName:String;

    public function XmlBeginTagPosition(parentTagName:String, presetChars:String) {
        this.parentTagName = parentTagName;
        super(presetChars);
    }

    public override function toString():String {
        return super.toString() + "{parentTagName=" + String(parentTagName) + "}";
    }
}
}
