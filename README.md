TextAreaAutoCompletion
======================

# What is it?
AS3 textarea component autocompletion with schema parsing.
Features:
* completion for tag, attribute and attribute content declaration,
* auto close tag with "/" or ">"
* schema parsing: any simple schema should work, if got a targetNamespace(All schema specification not implemented).
* multiple schema parsing

## Demo
You can see a running version at [TextAreaAutoCompletion.swf](http://adioss.fr/wp-content/uploads/2012/10/TextAreaAutoCompletion.swf)

## Usage

    (...)
    // declare text area
    <mx:TextArea id="textArea"/>
    (...)
    // declare autocompletion component with text area reference and schema collection
    var m_autoCompletion:AutoCompletion = new AutoCompletion(textArea, schemas);
    // auto create xml schema declaration if needed
    textArea.text = m_autoCompletion.generateHeaderForSchemaDescriptions(rootTagName.text);

## Requirements
1.  flex_sdk_4.6
2.  flexunit-4.0.0 for unit test

## Contributing
With Idea:
1.  create new flash module from scratch call TextAreaAutoCompletion,
2.  checkout into this repository sources and override files,
3.  launch TextAreaAutoCompletion app.

## Running Tests
Use flexunit.
