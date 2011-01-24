package kocms;

import kocms.Markup;
import kocms.Html;

class MarkupHtml {
    public static function toHtml(markup: Array<Markup>, ?command: String -> String -> String): String {
        var builder = new StringBuf();
        writeHtml(markup, builder.add, command);
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
                output(Html.escape(code));
                output("</pre>\n");
            case Listing(listing):
                writeListing(listing, output, command);
            case Table(headings, alignment, rows):
                var align = function(i: Int) {
                    if(i < alignment.length) {
                        var aligned = alignment[i];
                        return if(aligned.left && aligned.right) " align=\"center\""
                            else if(aligned.left) " align=\"left\""
                            else if(aligned.right) " align=\"right\""
                            else "";
                    } else {
                        return "";
                    }
                }
                output("<table>\n");
                if(headings.length > 0) {
                    output("<thead>\n");
                    output("<tr>\n");
                    var i = 0;
                    for(cell in headings) {
                        output("<td" + align(i) + ">\n");
                        writeInline(cell, output, command);
                        output("</td>\n");
                        i += 1;
                    }
                    output("</tr>\n");
                    output("</thead>\n");
                }
                output("<tbody>\n");
                for(row in rows) {
                    output("<tr>\n");
                    var j = 0;
                    for(cell in row) {
                        output("<td" + align(j) + ">\n");
                        writeInline(cell, output, command);
                        output("</td>\n");
                        j += 1;
                    }
                    output("</tr>\n");
                }
                output("</tbody>\n");
                output("</table>\n");
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
                output(Html.escape(verbatim));
                output("</code>");
            case Link(inside, url):
                output("<a href=\"" + Html.escape(url) + "\">");
                writeInline(inside, output, command);
                output("</a>");
            case Text(text):
                output(Html.escape(text));
            case Sequence(left, right):
                writeInline(left, output, command);
                writeInline(right, output, command);
        }
    }
}

