package kocms;

import kocms.Html;
import kocms.Pages;

class PagesHtml {
    public static function toHtml(pagePath: String, pages: Pages, path = ""): String {
        var builder = new StringBuf();
        writeHtml(pagePath, pages, builder.add, path);
        return builder.toString();
    }

    public static function writeHtml(pagePath: String, pages: Pages, output: String -> Void, path = ""): Void {
        var page = pages.get(pagePath);
        output("<div class=\"menu-internal\">");
        output("<a href=\"" + Html.escape(path + pagePath) + "\">");
        output(Html.escape(page.title));
        output("</a>");
        var children = pages.getChildren(pagePath);
        if(children.hasNext()) {
            output("<ul>");
            for(childPath in children) {
                output("<li>");
                writeHtml(childPath, pages, output, path);
                output("</li>");
            }
            output("</ul>");
        }
        output("</div>");
    }
}

