/**
 * Created with IntelliJ IDEA.
 * User: A.PAILHES
 * Date: 16/07/12
 * Time: 20:19
 *
 */
package autocompletion.model.position {
import mx.collections.ArrayCollection;

public class XmlAttributePosition extends XmlBasicPosition {
    public var currentTagName:String;
    public var alreadyUsedAttributes:ArrayCollection;

    public function XmlAttributePosition(currentTagName:String, presetChars:String,
                                         alreadyUsedAttributes:ArrayCollection = null) {
        this.currentTagName = currentTagName;
        this.alreadyUsedAttributes = alreadyUsedAttributes;
        super(presetChars);
    }

    public override function toString():String {
        return super.toString() + "{currentTagName=" + String(currentTagName)
                + ",alreadyUsedAttributes=" + String(alreadyUsedAttributes) + "}";
    }
}
}
