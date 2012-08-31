/**
 *
 * User: adio
 * Date: 10/08/12
 * Time: 01:24
 */
package autocompletion {
import flexunit.framework.Assert;

public class TextAreaHelperTest {
    public function TextAreaHelperTest() {
    }

    [Test]
    public function shouldPrepareContent():void {
        var stringToPrepare:String;
        var stringPrepared:String;

        stringToPrepare = "<route> \n<";
        stringPrepared = TextAreaHelper.prepareContent(stringToPrepare);
        Assert.assertEquals(stringPrepared, "<route><");

        stringToPrepare = "<route> \r<";
        stringPrepared = TextAreaHelper.prepareContent(stringToPrepare);
        Assert.assertEquals(stringPrepared, "<route><");

        stringToPrepare = "<routes> \r  <\r route";
        stringPrepared = TextAreaHelper.prepareContent(stringToPrepare);
        Assert.assertEquals(stringPrepared, "<routes><route");

        stringToPrepare = "<routes>\r<   route  id=\"test\r  \" other=\" \" andOther=\"\"  >";
        stringPrepared = TextAreaHelper.prepareContent(stringToPrepare);
        Assert.assertEquals(stringPrepared, "<routes><route id=\"\" other=\"\" andOther=\"\">");

        stringToPrepare = "<routes><route><log id=\"\" message=\"\" loggingLevel=\"DEBUG\" ></log>";
        stringPrepared = TextAreaHelper.prepareContent(stringToPrepare);
        Assert.assertEquals(stringPrepared, "<routes><route><log id=\"\" message=\"\" loggingLevel=\"\"></log>");
    }
}
}
