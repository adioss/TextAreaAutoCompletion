/**
 * User: A.PAILHES
 * Date: 17/07/12
 * Time: 00:38
 *
 */
package fr.adioss.autocompletion {
    import flexunit.framework.Assert;

    import fr.adioss.autocompletion.model.position.XmlAttributeEditionPosition;
    import fr.adioss.autocompletion.model.position.XmlAttributePosition;
    import fr.adioss.autocompletion.model.position.XmlBeginTagPosition;

    import mx.collections.ArrayCollection;

    public class SchemaParserTest {
        [Embed(source="/fr/adioss/autocompletion/assets/camel-spring-2.9.1.xml")]
        private var CAMEL_SPRING_XSD:Class;

        [Embed(source="/fr/adioss/autocompletion/assets/simple.xml")]
        private var SIMPLE_XSD:Class;

        private var m_schemaParser:SchemaParser;

        public function SchemaParserTest() {
            var schemas:ArrayCollection = new ArrayCollection([(CAMEL_SPRING_XSD.data as XML), (SIMPLE_XSD.data as XML)]);
            m_schemaParser = new SchemaParser(schemas);
        }

        [Test]
        public function shouldRetrieveTagCompletionInformation():void {
            var position:XmlBeginTagPosition = new XmlBeginTagPosition("routes", null);
            var result:ArrayCollection = m_schemaParser.retrieveTagCompletionInformation(position, null);
            Assert.assertNotNull(result);
            Assert.assertTrue(result.contains("route"));
            Assert.assertTrue(result.contains("description"));

            position = new XmlBeginTagPosition("routes", "rou");
            result = m_schemaParser.retrieveTagCompletionInformation(position, null);
            Assert.assertNotNull(result);
            Assert.assertTrue(result.contains("route"));

            position = new XmlBeginTagPosition("route", null);
            result = m_schemaParser.retrieveTagCompletionInformation(position, null);
            Assert.assertNotNull(result);
            Assert.assertEquals(result.length, 60);

            position = new XmlBeginTagPosition("route", "l");
            result = m_schemaParser.retrieveTagCompletionInformation(position, null);
            Assert.assertNotNull(result);
            Assert.assertEquals(result.length, 3);
            Assert.assertTrue(result.contains("loadBalance"));
            Assert.assertTrue(result.contains("log"));
            Assert.assertTrue(result.contains("loop"));
        }

        [Test]
        public function shouldRetrieveAttributeCompletionInformation():void {
            var position:XmlAttributePosition = new XmlAttributePosition("route", null);
            var result:ArrayCollection = m_schemaParser.retrieveAttributeCompletionInformation(position);
            Assert.assertNotNull(result);
            Assert.assertEquals(result.length, 13);

            position = new XmlAttributePosition("route", "s");
            result = m_schemaParser.retrieveAttributeCompletionInformation(position);
            Assert.assertNotNull(result);
            Assert.assertEquals(result.length, 4);

            position = new XmlAttributePosition("log", null);
            result = m_schemaParser.retrieveAttributeCompletionInformation(position);
            Assert.assertNotNull(result);
            Assert.assertEquals(result.length, 6);

            position = new XmlAttributePosition("route", "s", new ArrayCollection(["shutdownRoute"]));
            result = m_schemaParser.retrieveAttributeCompletionInformation(position);
            Assert.assertNotNull(result);
            Assert.assertEquals(result.length, 3);
            Assert.assertFalse(result.contains("shutdownRoute"));
        }

        [Test]
        public function shouldRetrieveAttributeEditionCompletionInformation():void {
            var position:XmlAttributeEditionPosition = new XmlAttributeEditionPosition("log", "loggingLevel", "");
            var result:ArrayCollection = m_schemaParser.retrieveAttributeEditionCompletionInformation(position);
            Assert.assertNotNull(result);
            Assert.assertEquals(result.length, 6);
        }

        [Test]
        public function shouldRetrieveAttributeEditionCompletionBooleanInformation():void {
            var position:XmlAttributeEditionPosition = new XmlAttributeEditionPosition("multicast", "streaming", "");
            var result:ArrayCollection = m_schemaParser.retrieveAttributeEditionCompletionInformation(position);
            Assert.assertNotNull(result);
            Assert.assertEquals(result.length, 2);
            Assert.assertTrue(result.contains("false"));
            Assert.assertTrue(result.contains("true"));
        }

        [Test]
        public function shouldRetrieveInDifferentSchema():void {
            var position:XmlBeginTagPosition = new XmlBeginTagPosition("xs1:shiporder", "xs1:");
            var result:ArrayCollection = m_schemaParser.retrieveTagCompletionInformation(position, null);
            Assert.assertNotNull(result);
            Assert.assertEquals(result.length, 3);
            Assert.assertTrue(result.contains("xs1:orderperson"));
            Assert.assertTrue(result.contains("xs1:shipto"));
            Assert.assertTrue(result.contains("xs1:item"));
        }

        [Test]
        public function shouldRetrieveFirstElementWithoutParent():void {
            var position:XmlBeginTagPosition = new XmlBeginTagPosition("", "xs1:");
            var result:ArrayCollection = m_schemaParser.retrieveTagCompletionInformation(position, null);
            Assert.assertNotNull(result);
            Assert.assertTrue(result.contains("xs1:shiporder"));
        }
    }
}
