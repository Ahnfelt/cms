package kocms;

import kocms.Markup;
import kocms.MarkupParser;
import kocms.MarkupHtml;
import kocms.Pages;
import kocms.PagesHtml;
import kocms.Plugin;

class Main {
/*
    public static function main(): Void {
        var input = 
"Dette burde være en overskrift
===

1. A
2. B
3. C
4. D
5. E
6. F
";
        var markup = new MarkupParser().parse(input);
        trace(markup);
        trace(MarkupHtml.toHtml(markup));
    }
*/

/*
    public static function main(): Void {
        var pages = new Pages();
        pages.insert({
            path: "/faciliteter",
            title: "Faciliteter",
            markup: "Hello!"
        });
        pages.insert({
            path: "/faciliteter/tarmen",
            title: "Tarmen",
            markup: "- E-mail: foo@bar.baz"
        });
        trace(PagesHtml.toHtml("/faciliteter", pages));
    }
*/

    public static function main(): Void {
        var pluginHash = new Hash<Plugin>();
        pluginHash.set("body", new BodyPlugin());
        pluginHash.set("sidebar", new SidebarPlugin());
        var plugins = new Plugins(pluginHash);
        var template = haxe.Resource.getString("template");
        var html = TemplateHtml.toHtml(template, plugins.replacePlaceholders);
        trace(html);
    }
}

class BodyPlugin implements Plugin {
    public var listeners(default, null): Hash<Trigger -> Dynamic -> Dynamic>;
    public var placeholders(default, null): Hash<Trigger -> String>;
    
    public function new() {
        listeners = new Hash<Trigger -> Dynamic -> Dynamic>();
        placeholders = new Hash<Trigger -> String>();
        placeholders.set("", function(trigger) { 
            var callbacks = trigger("html");
            return Plugins.chain(callbacks, "Body");
        });
        placeholders.set("title", function(trigger) { 
            return "Title";
        });
    }
}

class SidebarPlugin implements Plugin {
    public var listeners(default, null): Hash<Trigger -> Dynamic -> Dynamic>;
    public var placeholders(default, null): Hash<Trigger -> String>;
    
    public function new() {
        listeners = new Hash<Trigger -> Dynamic -> Dynamic>();
        placeholders = new Hash<Trigger -> String>();
        listeners.set("body:html", function(trigger, input) { 
            return "<div>Sidebar</div><div>" + input + "</div>";
        });
    }
}

