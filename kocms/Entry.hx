package kocms;

import kocms.Markup;
import kocms.Group;

enum Entry {
    External(name: String, url: String);
    Internal(name: String, markup: Array<Markup>, entries: Array<Entry>, view: Array<Group>, edit: Array<Group>);
}


