/**
 *
 * User: A.PAILHES
 * Date: 02/09/12
 * Time: 21:55
 */
package fr.adioss.autocompletion.model.schema {
    import flash.utils.Dictionary;

    import mx.collections.ArrayCollection;

    public class SchemaDescription {
        public var schema:XML;
        public var schemaInformation:SchemaInformation = new SchemaInformation();
        public var simpleTypes:Dictionary = new Dictionary();
        public var elements:Dictionary = new Dictionary();
        public var complexTypes:Dictionary = new Dictionary();
        public var abstractComplexTypes:Dictionary = new Dictionary();
        public var prefix:String;
        public var rootTagNames:ArrayCollection;

        public function SchemaDescription(schema:XML) {
            this.schema = schema;
        }
    }
}
