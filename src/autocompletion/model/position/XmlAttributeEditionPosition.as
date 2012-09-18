/**
 * Created with IntelliJ IDEA.
 * User: A.PAILHES
 * Date: 16/07/12
 * Time: 20:19
 *
 */
package autocompletion.model.position {
public class XmlAttributeEditionPosition extends XmlAttributePosition {
    public var currentAttributeName:String;

    public function XmlAttributeEditionPosition(currentTagName:String, currentAttributeName:String,
                                                presetChars:String) {
        super(currentTagName, presetChars);
        this.currentAttributeName = currentAttributeName;
    }

    public override function toString():String {
        return super.toString() + "{currentAttributeName=" + String(currentAttributeName) + "}";
    }
}
}
