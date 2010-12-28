package kocms;

import kocms.Markup;

class MarkupHtml {
    private static function htmlEscape(string: String): String {
        // Note that StringTools.htmlEscape is broken (doesn't escape " and '), hence the following fix
        return StringTools.replace(StringTools.replace(StringTools.htmlEscape(string), "\"", "&#34;"), "'", "&#39;");
    }

    public static function toHtml(markup: Array<Markup>, ?command: String -> String -> String): String {
        var builder = new StringBuf();
        var output = function(string) { builder.add(string); };
        writeHtml(markup, output, command);
        return builder.toString();
    }

    public static function writeHtml(markup: Array<Markup>, output: String -> Void, ?command: String -> String -> String): Void {
        for(element in markup) {
            writeMarkup(element, output, command);
        }
    }

    private static function writeMarkup(markup: Markup, output: String -> Void, ?command: String -> String -> String): Void {
        switch(markup) {
            case Paragraph(inside):
                output("<p>\n");
                writeInline(inside, output, command);
                output("</p>\n");
            case Heading(inside):
                output("<h1>\n");
                writeInline(inside, output, command);
                output("</h1>\n");
            case Subheading(inside):
                output("<h2>\n");
                writeInline(inside, output, command);
                output("</h2>\n");
            case Code(code):
                output("<pre>\n");
                output(htmlEscape(code));
                output("</pre>\n");
            case Listing(listing):
                writeListing(listing, output, command);
            case Command(name, arguments):
                if(command != null) output(command(name, arguments));
        }
    }
    
    private static function writeListing(listing: Listing, output: String -> Void, ?command: String -> String -> String): Void {
        switch(listing) {
            case Bullets(content, children):
                writeListingContent(content, output, command);
                if(children.length > 0) {
                    output("<ul>\n");
                    for(child in children) {
                        output("<li>\n");
                        writeListing(child, output, command);
                        output("</li>\n");
                    }
                    output("</ul>\n");
                }
            case Numbers(content, children):
                writeListingContent(content, output, command);
                if(children.length > 0) {
                    output("<ol>\n");
                    for(child in children) {
                        output("<li>\n");
                        writeListing(child, output, command);
                        output("</li>\n");
                    }
                    output("</ol>\n");
                }
        }
    }    

    private static function writeListingContent(content: Inline, output: String -> Void, ?command: String -> String -> String): Void {
        writeInline(content, output, command);
    }
    
    private static function writeInline(content: Inline, output: String -> Void, ?command: String -> String -> String): Void {
        switch(content) {
            case Bold(inside):
                output("<strong>");
                writeInline(inside, output, command);
                output("</strong>");
            case Italic(inside):
                output("<em>");
                writeInline(inside, output, command);
                output("</em>");
            case Verbatim(verbatim):
                output("<code>");
                output(htmlEscape(verbatim));
                output("</code>");
            case Link(inside, url):
                output("<a href=\"" + htmlEscape(url) + "\">");
                writeInline(inside, output, command);
                output("</a>");
            case Text(text):
                output(htmlEscape(text));
            case Sequence(left, right):
                writeInline(left, output, command);
                writeInline(right, output, command);
        }
    }
}

