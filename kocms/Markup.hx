package kocms;

enum Markup {
    Paragraph(inside: Inline);
    Heading(inside: Inline);
    Subheading(inside: Inline);
    Code(code: String);
    Listing(listing: Listing);
    Command(name: String, arguments: String);
}

enum Listing {
    Bullets(content: Inline, children: Array<Listing>);
    Numbers(content: Inline, children: Array<Listing>);
}

enum Inline {
    Bold(inside: Inline);
    Italic(inside: Inline);
    Verbatim(verbatim: String);
    Link(inside: Inline, url: String);
    Text(text: String);
    Sequence(left: Inline, right: Inline);
}

