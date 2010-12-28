package kocms;

import kocms.Markup;

/* Note: Not thread safe due to the static mutable ERegs (meh Haxe!) */
class MarkupParser {
    private static var headingPattern = ~/(([\n]|.)*[\n])[=]{3,}$/g;
    private static var subheadingPattern = ~/(([\n]|.)*[\n])[-]{3,}$/g;
    private static var listPattern = ~/^([ ]*)([-*]|[0-9]+[.])[ ]+/g;
    private static var commandPattern = ~/^[!]([^ \n]+)((.|[\n])*)/g;
    
    public static function parse(input: String): Array<Markup> {
        var paragraphs = splitParagraphs(input);
        var parsed = Lambda.array(Lambda.map(paragraphs, function(paragraph) { 
            var code = toCode(paragraph);
            if(code != null) {
                return Code(code);
            }
            if(commandPattern.match(paragraph)) {
                return Command(commandPattern.matched(1), commandPattern.matched(2));
            }
            if(listPattern.match(paragraph)) {
                return Listing(parseListing(paragraph));
            }
            if(headingPattern.match(paragraph)) {
                return Heading(parseInline(headingPattern.matched(1)));
            }
            if(subheadingPattern.match(paragraph)) {
                return Subheading(parseInline(subheadingPattern.matched(1)));
            }
            return Paragraph(parseInline(paragraph)); 
        }));
        var final = [];
        for(paragraph in parsed) {
            switch(paragraph) {
                case Code(right):
                    if(final.length > 0) {
                        switch(final[final.length - 1]) {
                            case Code(left):
                                final.pop();
                                final.push(Code(left + "\n" + right));
                            default:
                                final.push(paragraph);
                        }
                    } else {
                        final.push(paragraph);
                    }
                default:
                    final.push(paragraph);
            }
        }
        return final;
    }
    
    private static function splitParagraphs(input: String): Array<String> {
        var lines = StringTools.replace(StringTools.replace(input + "\n", "\r", ""), "\t", "    ").split("\n");
        var paragraphs = [];
        var paragraph = new StringBuf();
        for(line in lines) {
            if(StringTools.trim(line).length == 0) {
                var string = paragraph.toString();
                if(string.length > 0) {
                    paragraphs.push(string);
                }
                paragraph = new StringBuf();
            } else {
                paragraph.add(line);
                paragraph.add("\n");
            }
        }
        return paragraphs;
    }
    
    private static function toCode(input: String): String {
        var builder = new StringBuf();
        for(line in input.substr(0, input.length - 1).split("\n")) {
            if(line.length > 4 && line.substr(0, 4) == "    ") {
                builder.add(line.substr(4) + "\n");
            } else {
                return null;
            }
        }
        return builder.toString();
    }
    
    public static function parseListing(input: String): Listing {
        var elements = parseElements(input);
        elements.reverse();
        return parseItems(elements, "", -1);
    }

    public static function parseItems(elements: Array<{indentation: Int, bullet: Bool, body: String}>, body: String, indentation: Int): Listing {
        var inside = parseInline(body);
        var bullets = true;
        var items = [];
        while(elements.length > 0) {
            var top = elements.pop();
            if(top.indentation > indentation) {
                bullets = top.bullet;
                var item = parseItems(elements, top.body, top.indentation);
                items.push(item);
            } else {
                elements.push(top);
                break;
            }
        }
        return if(bullets) Bullets(inside, items) else Numbers(inside, items);
    }
    
    private static function parseElements(input: String) {
        var lines = input.split("\n");
        lines.pop();
        var elements = [];
        var element = null;
        for(line in lines) {
            if(listPattern.match(line)) {
                if(element != null) {
                    elements.push(element);
                }
                var length = listPattern.matched(0).length;
                var indentation = listPattern.matched(1).length;
                var bullet = listPattern.matched(2) == "*" || listPattern.matched(2) == "-";
                element = {indentation: indentation, bullet: bullet, body: line.substr(length) + "\n"};
            } else {
                element = {indentation: element.indentation, bullet: element.bullet, body: element.body + line + "\n"};
            }
        }
        if(element != null) {
            elements.push(element);
        }
        return elements;
    }
    
    private static var textPattern = ~/^[^[*`\\]+/g;
    private static var stylePattern = ~/^([*]{1,3})([^*]|$)/g;
    private static var italicPattern = ~/^[*]{1}([^*]|$)/g;
    private static var boldPattern = ~/^[*]{2}([^*]|$)/g;
    private static var italicBoldPattern = ~/^[*]{3}([^*]|$)/g;
    private static var linkPattern = ~/^[\[]([^\]]*)[\]][(]([^)]*)[)]/g;
    private static var longUrlPattern = ~/(^([.]?[.]?[\/#?]))|[:]/g;
    private static var verbatimPattern = ~/^[`]([^`]+)[`]/g;
    private static var escapePattern = ~/^[\\](.)/g;

    public static function parseInline(input: String) {
        return parseInside(input, null).inside;
    }

    public static function parseInside(input: String, stopPattern: EReg): {inside: Inline, remaining: String} {
        var inside = null; 
        var sequence = function(right: Inline): Inline {
            return if(inside == null) right else Sequence(inside, right);
        }
        while(input.length > 0) {
            if(stopPattern != null && stopPattern.match(input)) {
                return {inside: inside, remaining: input};
            } else if(textPattern.match(input)) {
                var match = textPattern.matched(0);
                inside = sequence(Text(match));
                input = input.substr(match.length);
            } else if(stylePattern.match(input)) {
                var length = stylePattern.matched(1).length;
                input = input.substr(length);
                var body = parseInside(input, 
                    if(length == 1) italicPattern 
                    else if(length == 2) boldPattern 
                    else italicBoldPattern);
                inside = sequence(
                    if(length == 1) Italic(body.inside)
                    else if(length == 2) Bold(body.inside)
                    else Italic(Bold(body.inside)));
                input = body.remaining.substr(length);
            } else if(linkPattern.match(input)) {
                var length = linkPattern.matched(0).length;
                var text = linkPattern.matched(1);
                var url = linkPattern.matched(2);
                if(!longUrlPattern.match(url)) url = "http://" + url;
                inside = sequence(Link(Text(text), url));
                input = input.substr(length);
            } else if(verbatimPattern.match(input)) {
                var length = verbatimPattern.matched(0).length;
                inside = sequence(Verbatim(verbatimPattern.matched(1)));
                input = input.substr(length);
            } else if(escapePattern.match(input)) {
                var length = escapePattern.matched(0).length;
                inside = sequence(Text(escapePattern.matched(1)));
                input = input.substr(length);
            } else {
                inside = sequence(Text(input.substr(0, 1)));
                input = input.substr(1);
            }
        }
        return {inside: if(inside == null) Text("") else inside, remaining: ""};
    }
}

