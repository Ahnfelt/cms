package kocms;

import kocms.Markup;

class MarkupParser {
    private var headingPattern: EReg;
    private var subheadingPattern: EReg;
    private var listPattern: EReg;
    private var tablePattern: EReg;
    private var alignmentPattern: EReg;
    private var commandPattern: EReg;
    private var textPattern: EReg;
    private var stylePattern: EReg;
    private var italicPattern: EReg;
    private var boldPattern: EReg;
    private var italicBoldPattern: EReg;
    private var linkPattern: EReg;
    private var longUrlPattern: EReg;
    private var verbatimPattern: EReg;
    private var escapePattern: EReg;
    
    public function new() {
        headingPattern = new EReg("(([\\n]|.)*[\\n])[=]{3,}[\\n]?$", "g");
        subheadingPattern = new EReg("(([\\n]|.)*[\\n])[-]{3,}[\\n]?$", "g");
        listPattern = new EReg("^([ ]*)([-]|[0-9]+[.])[ ]+", "g");
        tablePattern = new EReg("^[|]([^\n]*)([\n]|$)", "");
        alignmentPattern = new EReg("^[ ]*([:]?)[-]+([:]?)[ ]*$", "");
        commandPattern = new EReg("^[!]([^ \\n]+)((.|[\\n])*)", "g");
        textPattern = new EReg("^[^\\[*`\\\\]+", "g");
        stylePattern = new EReg("^([*]{1,3})([^*]|$)", "g");
        italicPattern = new EReg("^[*]{1}([^*]|$)", "g");
        boldPattern = new EReg("^[*]{2}([^*]|$)", "g");
        italicBoldPattern = new EReg("^[*]{3}([^*]|$)", "g");
        linkPattern = new EReg("^[\\[]([^\\]]*)[\\]][(]([^)]*)[)]", "g");
        longUrlPattern = new EReg("(^[.\\/#?])|.*[:]", "g");
        verbatimPattern = new EReg("^[`](([^\\\\`]|[\\\\].)+)[`]", "g");
        escapePattern = new EReg("[\\\\](.)", "g");
    }
    
    public function parse(input: String): Array<Markup> {
        var self = this; 
        var paragraphs = splitParagraphs(input);
        var parsed = Lambda.array(Lambda.map(paragraphs, function(paragraph) { 
            var code = self.toCode(paragraph);
            if(code != null) {
                return Code(code);
            }
            if(self.commandPattern.match(paragraph)) {
                return Command(self.commandPattern.matched(1), self.commandPattern.matched(2));
            }
            if(self.listPattern.match(paragraph)) {
                return Listing(self.parseListing(paragraph));
            }
            if(self.tablePattern.match(paragraph)) {
                return self.parseTable(paragraph);
            }
            if(self.headingPattern.match(paragraph)) {
                return Heading(self.parseInline(self.headingPattern.matched(1)));
            }
            if(self.subheadingPattern.match(paragraph)) {
                return Subheading(self.parseInline(self.subheadingPattern.matched(1)));
            }
            return Paragraph(self.parseInline(paragraph)); 
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
    
    private function splitParagraphs(input: String): Array<String> {
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
    
    private function toCode(input: String): String {
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

    public function parseTable(input: String): Markup {
        var self = this;
        var lines = input.split("\n");
        var headers = Lambda.array(Lambda.map(parseRow(lines[0]), self.parseInline));
        var hasHeaders = lines.length > 2;
        var alignment = Lambda.array(Lambda.map(parseRow(lines[1]), function(cell) {
            if(self.alignmentPattern.match(cell)) {
                return {left: self.alignmentPattern.matched(1) != "", right: self.alignmentPattern.matched(2) != ""};
            } else {
                hasHeaders = false;
                return {left: false, right: false};
            }
        }));
        hasHeaders = hasHeaders && alignment.length > 0;
        lines.pop();
        if(hasHeaders) {
            lines = lines.slice(2);
        } else {
            headers = [];
        }
        var rows = [];
        for(line in lines) {
            var row = parseRow(line);
            rows.push(Lambda.array(Lambda.map(row, self.parseInline)));
        }
        return Table(headers, alignment, rows);
    }
    
    public function parseRow(input: String): Array<String> {
        if(tablePattern.match(input)) {
            // The following hack for handling escape codes relies on the
            // assumption that lines can't contain \r or \n.
            var cells = StringTools.replace(StringTools.replace(tablePattern.matched(1), "\\\\", "\r"), "\\|", "\n").split("|");
            if(cells.length > 0 && StringTools.trim(cells[cells.length - 1]) == "") {
                cells.pop();
            }
            return Lambda.array(Lambda.map(cells, function(cell) { 
                return StringTools.replace(StringTools.replace(cell, "\r", "\\\\"), "\n", "\\|");
            }));
        } else {
            return [];
        }
    }
    
    public function parseListing(input: String): Listing {
        var elements = parseElements(input);
        elements.reverse();
        return parseItems(elements, "", -1);
    }

    public function parseItems(elements: Array<{indentation: Int, bullet: Bool, body: String}>, body: String, indentation: Int): Listing {
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
    
    private function parseElements(input: String) {
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
                var bullet = listPattern.matched(2) == "-";
                element = {indentation: indentation, bullet: bullet, body: line.substr(length) + "\n"};
            } else if(element != null) {
                element = {indentation: element.indentation, bullet: element.bullet, body: element.body + line + "\n"};
            }
        }
        if(element != null) {
            elements.push(element);
        }
        return elements;
    }

    public function parseInline(input: String) {
        return parseInside(input, null).inside;
    }

    public function parseInside(input: String, stopPattern: EReg): {inside: Inline, remaining: String} {
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
                var verbatim = escapePattern.replace(verbatimPattern.matched(1), "$1");
                inside = sequence(Verbatim(verbatim));
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

