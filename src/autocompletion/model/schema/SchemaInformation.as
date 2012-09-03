/**
 *
 * User: A.PAILHES
 * Date: 31/08/12
 * Time: 01:17
 */
package autocompletion.model.schema {
public class SchemaInformation {
    public static const STANDARD_URI:String = "http://www.w3.org/2001/XMLSchema";
    public var standardPrefix:String;
    public var standardNameSpace:Namespace;
    public var schemaPrefix:String;
    public var schemaUri:String;
    public var schemaNameSpace:Namespace;

    public function SchemaInformation() {
    }
}
}
