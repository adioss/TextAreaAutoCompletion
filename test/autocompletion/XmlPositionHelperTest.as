/**
 * Created with IntelliJ IDEA.
 * User: A.PAILHES
 * Date: 14/07/12
 * Time: 08:13
 *
 */
package autocompletion {
import autocompletion.model.position.XmlAttributeEditionPosition;
import autocompletion.model.position.XmlAttributePosition;
import autocompletion.model.position.XmlBeginTagPosition;
import autocompletion.model.position.XmlContentPosition;
import autocompletion.model.position.XmlEndTagPosition;
import autocompletion.model.position.XmlPosition;

import flexunit.framework.*;

import mx.collections.ArrayCollection;
import mx.controls.TextArea;

public class XmlPositionHelperTest {
    private var m_xmlPositionHelper:XmlPositionHelper;
    private var m_textArea:TextArea;

    public function XmlPositionHelperTest() {
        m_textArea = new TextArea();
        m_xmlPositionHelper = new XmlPositionHelper(m_textArea);
    }

    [Test]
    public function shouldRetrieveTagCompletionInformation():void {
        var currentPositionTested:XmlPosition;
        var currentPosition:XmlBeginTagPosition;

        m_textArea.text = "<FIRSTNAME></FIRSTNAME>";
        m_textArea.selectionBeginIndex = 7;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlBeginTagPosition);
        currentPosition = XmlBeginTagPosition(m_xmlPositionHelper.getCurrentXmlPosition());
        Assert.assertEquals(currentPosition.parentTagName, null);
        Assert.assertEquals(currentPosition.presetChars, "FIRSTN");

        m_textArea.text = "<" + "\r" + "FIRSTN";
        m_textArea.selectionBeginIndex = 5;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlBeginTagPosition);
        currentPosition = XmlBeginTagPosition(m_xmlPositionHelper.getCurrentXmlPosition());
        Assert.assertEquals(currentPosition.parentTagName, null);
        Assert.assertEquals(currentPosition.presetChars, "FIR");

        m_textArea.text = "<" + "\r" + "     FIRSTN";
        m_textArea.selectionBeginIndex = 10;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlBeginTagPosition);
        currentPosition = XmlBeginTagPosition(m_xmlPositionHelper.getCurrentXmlPosition());
        Assert.assertEquals(currentPosition.parentTagName, null);
        Assert.assertEquals(currentPosition.presetChars, "FIR");

        m_textArea.text = "<routes><r";
        m_textArea.selectionBeginIndex = 10;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlBeginTagPosition);
        currentPosition = XmlBeginTagPosition(m_xmlPositionHelper.getCurrentXmlPosition());
        Assert.assertEquals(currentPosition.parentTagName, "routes");
        Assert.assertEquals(currentPosition.presetChars, "r");

        m_textArea.text = "<routes><route><";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlBeginTagPosition);
        currentPosition = XmlBeginTagPosition(m_xmlPositionHelper.getCurrentXmlPosition());
        Assert.assertEquals(currentPosition.parentTagName, "route");
        Assert.assertEquals(currentPosition.presetChars, "");
    }

    [Test]
    public function shouldRetrieveAttributeCompletionInformation():void {
        var currentPosition:XmlAttributePosition;
        var currentPositionTested:XmlPosition;

        m_textArea.text = "<BOOK ISBN=\"9782212090819\" LAN";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlAttributePosition);
        currentPosition = XmlAttributePosition(currentPositionTested);
        Assert.assertEquals(currentPosition.currentTagName, "BOOK");
        Assert.assertEquals(currentPosition.presetChars, "LAN");
        Assert.assertNotNull(currentPosition.alreadyUsedAttributes);
        Assert.assertTrue(currentPosition.alreadyUsedAttributes.contains("ISBN"));

        m_textArea.text = "<BOOK ISBN=\"9782212090819\" LANG=\"fds\" OTHER";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlAttributePosition);
        currentPosition = XmlAttributePosition(currentPositionTested);
        Assert.assertEquals(currentPosition.currentTagName, "BOOK");
        Assert.assertEquals(currentPosition.presetChars, "OTHER");
        Assert.assertNotNull(currentPosition.alreadyUsedAttributes);
        Assert.assertTrue(currentPosition.alreadyUsedAttributes.contains("ISBN"));
        Assert.assertTrue(currentPosition.alreadyUsedAttributes.contains("LANG"));
        Assert.assertFalse(currentPosition.alreadyUsedAttributes.contains("OTHER"));

        m_textArea.text = "<" + "\r" + "     FIRSTN     test     ";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlAttributePosition);
        currentPosition = XmlAttributePosition(currentPositionTested);
        Assert.assertEquals(currentPosition.currentTagName, "FIRSTN");
        Assert.assertEquals(currentPosition.presetChars, "");
        Assert.assertNull(currentPosition.alreadyUsedAttributes);

        m_textArea.text = "<routes><route><log id=\"\" message=\"\" loggingLevel=\"\" ";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlAttributePosition);
        currentPosition = XmlAttributePosition(currentPositionTested);
        Assert.assertEquals(currentPosition.currentTagName, "log");
        Assert.assertEquals(currentPosition.presetChars, "");
        Assert.assertNotNull(currentPosition.alreadyUsedAttributes);
        Assert.assertTrue(currentPosition.alreadyUsedAttributes.contains("id"));
        Assert.assertTrue(currentPosition.alreadyUsedAttributes.contains("message"));
        Assert.assertTrue(currentPosition.alreadyUsedAttributes.contains("loggingLevel"));

        m_textArea.text = "<routes><route><log id=\"\" message=\"\" loggingLevel=\"DEBUG\" ";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlAttributePosition);
        currentPosition = XmlAttributePosition(currentPositionTested);
        Assert.assertEquals(currentPosition.currentTagName, "log");
        Assert.assertEquals(currentPosition.presetChars, "");
        Assert.assertNotNull(currentPosition.alreadyUsedAttributes);
        Assert.assertTrue(currentPosition.alreadyUsedAttributes.contains("id"));
        Assert.assertTrue(currentPosition.alreadyUsedAttributes.contains("message"));
        Assert.assertTrue(currentPosition.alreadyUsedAttributes.contains("loggingLevel"));

        m_textArea.text = "<routes><route><multicast i";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        currentPosition = XmlAttributePosition(currentPositionTested);
        Assert.assertEquals(currentPosition.currentTagName, "multicast");
        Assert.assertEquals(currentPosition.presetChars, "i");
    }

    [Test]
    public function shouldRetrieveContentCompletionInformation():void {
        var currentPositionTested:XmlPosition;

        m_textArea.text = ">    ld";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlContentPosition);

        m_textArea.text = ">      ";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlContentPosition);
    }

    [Test]
    public function shouldFindParentTagName():void {
        var parentTagName:String;
        var content:String;

        content = "<routes><";
        parentTagName = XmlPositionHelper.findParentTagName(TextAreaHelper.prepareContent(content));
        Assert.assertEquals(parentTagName, "routes");

        content = "<routes><route><";
        parentTagName = XmlPositionHelper.findParentTagName(TextAreaHelper.prepareContent(content));
        Assert.assertEquals(parentTagName, "route");

        content = "<routes><route><test";
        parentTagName = XmlPositionHelper.findParentTagName(TextAreaHelper.prepareContent(content));
        Assert.assertEquals(parentTagName, "route");

        content = "<routes><" + "\r" + "   route><test";
        parentTagName = XmlPositionHelper.findParentTagName(TextAreaHelper.prepareContent(content));
        Assert.assertEquals(parentTagName, "route");

        content = "<routes><" + "\r" + "   route><";
        parentTagName = XmlPositionHelper.findParentTagName(TextAreaHelper.prepareContent(content));
        Assert.assertEquals(parentTagName, "route");

        content = "<BOOK ISBN=\"9782212090819\" LANG=\"fr\" SUBJECT=\"applications\">" +
                "    <AUTHOR><FIRSTNAME untruc=\"dfsd\">Jean-Christophe</FIRSTNAME>     " +
                "    <LASTN";
        parentTagName = XmlPositionHelper.findParentTagName(TextAreaHelper.prepareContent(content));
        Assert.assertEquals(parentTagName, "AUTHOR");

        content = "<BOOK ISBN=\"9782212090819\" LANG=\"fr\" SUBJECT=\"applications\">" +
                "    <AUTHOR><FIRSTNAME untruc=\"dfsd\">Jean-Christophe</FIRSTNAME>     " +
                "    <LASTNAME>Bernadac</LASTNAME>  </AUTHOR>    <AUTHOR>         " +
                "<FIRSTNAME>François</FIRSTNAME>        <LASTNAME>Knab</LASTNAME>" +
                "<SIMPLETAG/>" +
                "                </AUTHOR>       " +
                " <TITLE>Construire une application XML</TITLE>" +
                "        <PUBLIS";
        parentTagName = XmlPositionHelper.findParentTagName(TextAreaHelper.prepareContent(content));
        Assert.assertEquals(parentTagName, "BOOK");
    }

    [Test]
    public function shouldFindAssociatedTagName():void {
        var associatedTagName:String;
        var content:String;
        content = "<BOOK ISBN=\"9782212090819\" LANG=\"fr\" SUBJECT=\"applications\">" +
                "    <AUTHOR><FIRSTNAME untruc=\"df\\sd\">adrien</FIRST";
        associatedTagName = XmlPositionHelper.findAssociatedTagName(content, "FIRST");
        Assert.assertEquals(associatedTagName, "FIRSTNAME");

        content = "< " + "\r" + "   FIRSTNAME untruc=\"fsdf\">adrien</FIRST";
        associatedTagName = XmlPositionHelper.findAssociatedTagName(content, "FIRST");
        Assert.assertEquals(associatedTagName, "FIRSTNAME");

        content = "<DATEPUB>1999</DATE";
        associatedTagName = XmlPositionHelper.findAssociatedTagName(content, "DATE");
        Assert.assertEquals(associatedTagName, "DATEPUB");

        content = "    <PUBLISHER>" + "\r" +
                "         <NAME>Eyrolles</NAME>" + "\r" +
                "         <PLACE>Paris</PLACE>  </PUBL";
        associatedTagName = XmlPositionHelper.findAssociatedTagName(content, "PUBL");
        Assert.assertEquals(associatedTagName, "PUBLISHER");
    }

    [Test]
    public function shouldNotFindAssociatedTagName():void {
        var associatedTagName:String;
        var content:String;
        content = "<BOOK ISBN=\"9782212090819\" LANG=\"fr\" SUBJECT=\"applications\">" +
                "    <AUTHOR><EROOR untruc=\"dfsd\">Jean-Christophe</FIRST";
        associatedTagName = XmlPositionHelper.findAssociatedTagName(content, "FIRST");
        Assert.assertNull(associatedTagName);
    }

    [Test]
    public function shouldRetrieveAttributeEditionCompletionInformation():void {
        var currentPosition:XmlAttributeEditionPosition;
        var currentPositionTested:XmlPosition;

        m_textArea.text = "<BOOK ISBN=\"97822120";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlAttributeEditionPosition);
        currentPosition = XmlAttributeEditionPosition(m_xmlPositionHelper.getCurrentXmlPosition());
        Assert.assertEquals(currentPosition.currentTagName, "BOOK");
        Assert.assertEquals(currentPosition.currentAttributeName, "ISBN");
        Assert.assertEquals(currentPosition.presetChars, "97822120");

        m_textArea.text = "<BOOK ISBN=\"9782212090819\" LANG=\"fds\" OTHER=\"kjfdsk";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlAttributeEditionPosition);
        currentPosition = XmlAttributeEditionPosition(m_xmlPositionHelper.getCurrentXmlPosition());
        Assert.assertEquals(currentPosition.currentTagName, "BOOK");
        Assert.assertEquals(currentPosition.currentAttributeName, "OTHER");
        Assert.assertEquals(currentPosition.presetChars, "kjfdsk");

        m_textArea.text = "<routes><route><log id=\"\" message=\"";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlAttributeEditionPosition);
        currentPosition = XmlAttributeEditionPosition(m_xmlPositionHelper.getCurrentXmlPosition());
        Assert.assertEquals(currentPosition.currentTagName, "log");
        Assert.assertEquals(currentPosition.currentAttributeName, "message");
        Assert.assertEquals(currentPosition.presetChars, "");
    }

    [Test]
    public function shouldCompleteWithNextUsedAttributes():void {
        var content:String;
        var xmlAttributePosition:XmlAttributePosition;
        var xmlAttributePositionTested:XmlAttributePosition;
        content = " message=\"me<s\" loggingLevel=\"loglevel\" ";
        xmlAttributePosition = new XmlAttributePosition("log", "", new ArrayCollection());
        xmlAttributePositionTested = XmlPositionHelper.completeWithNextUsedAttributes(content, 0, xmlAttributePosition);
        Assert.assertNotNull(xmlAttributePositionTested.alreadyUsedAttributes);
        Assert.assertTrue(xmlAttributePositionTested.alreadyUsedAttributes.contains("message"));
        Assert.assertTrue(xmlAttributePositionTested.alreadyUsedAttributes.contains("loggingLevel"));

        content = " message=\"mes\"><test loggingLevel=\"loglevel\" ";
        xmlAttributePosition = new XmlAttributePosition("log", "", new ArrayCollection());
        xmlAttributePositionTested = XmlPositionHelper.completeWithNextUsedAttributes(content, 0, xmlAttributePosition);
        Assert.assertNotNull(xmlAttributePositionTested.alreadyUsedAttributes);
        Assert.assertEquals(xmlAttributePositionTested.alreadyUsedAttributes.length, 1);
        Assert.assertTrue(xmlAttributePositionTested.alreadyUsedAttributes.contains("message"));

        content = "<routes><route><multicast streaming=\"true\" timeout=\"\"  id=\"oik\"  shareUnitOfWork=\"\"></multicast>";
        xmlAttributePosition = new XmlAttributePosition("multicast", "", new ArrayCollection());
        xmlAttributePositionTested = XmlPositionHelper.completeWithNextUsedAttributes(content, 54, xmlAttributePosition);
        Assert.assertNotNull(xmlAttributePositionTested.alreadyUsedAttributes);
        Assert.assertEquals(xmlAttributePositionTested.alreadyUsedAttributes.length, 2);
        Assert.assertTrue(xmlAttributePositionTested.alreadyUsedAttributes.contains("id"));
        Assert.assertTrue(xmlAttributePositionTested.alreadyUsedAttributes.contains("shareUnitOfWork"));
    }

    [Test]
    public function shouldCompleteEndTag():void {
        var currentPositionTested:XmlPosition;
        var currentPosition:XmlEndTagPosition;

        m_textArea.text = "<FIRSTNAME></FI";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlEndTagPosition);
        currentPosition = XmlEndTagPosition(currentPositionTested);
        Assert.assertEquals(currentPosition.associatedTagName, "FIRSTNAME");
        Assert.assertEquals(currentPosition.presetChars, "FI");

        m_textArea.text = "<FIRSTNAME></";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlEndTagPosition);
        currentPosition = XmlEndTagPosition(currentPositionTested);
        Assert.assertEquals(currentPosition.associatedTagName, "FIRSTNAME");
        Assert.assertNull(currentPosition.presetChars);

        m_textArea.text = "<FIRSTNAME id=\"te st\" other=\"other\" ></";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlEndTagPosition);
        currentPosition = XmlEndTagPosition(currentPositionTested);
        Assert.assertNull(currentPosition.presetChars);

        m_textArea.text = "<FIRSTNAME id=\"te st\" other=\"other\" ></OTH";
        m_textArea.selectionBeginIndex = m_textArea.text.length;
        currentPositionTested = m_xmlPositionHelper.getCurrentXmlPosition();
        Assert.assertTrue(currentPositionTested is XmlEndTagPosition);
        currentPosition = XmlEndTagPosition(currentPositionTested);
        Assert.assertNull(currentPosition.associatedTagName);
    }
}
}
