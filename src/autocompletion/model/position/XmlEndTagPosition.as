/**
 * Created with IntelliJ IDEA.
 * User: adio
 * Date: 16/07/12
 * Time: 20:19
 *
 */
package autocompletion.model.position {
public class XmlEndTagPosition extends XmlBasicPosition {
    public var associatedTagName:String;

    public function XmlEndTagPosition(associatedTagName:String, presetChars:String) {
        this.associatedTagName = associatedTagName;
        super(presetChars);
    }

    public override function toString():String {
        return super.toString() + "{associatedTagName=" + String(associatedTagName) + "}";
    }
}
}
