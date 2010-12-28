package kocms;

import kocms.Markup;
import kocms.MarkupParser;
import kocms.MarkupHtml;

class Main {
    public static function main(): Void {
        var input = "

This is **the
*first* paragraph**.
================

This is the
[second](google.com?x=0&bI=1) paragraph.
-----------------

This is the
>>third<< paragraph.

    This is some
    code that I
    wrote once

!billede \"test.png\"

- A has
  some text
- B
  1. C
  2. D
    * E
    * F
  3. G
- H
  - I
        
Blah.
        ";
        var markup = MarkupParser.parse(input);
        trace(markup);
        trace(MarkupHtml.toHtml(markup));
    }
}

