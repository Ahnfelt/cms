package kocms;

class Group {
    public var id(default, null): Int;
    public var name(default, null): String;
    public function new(id, name) {
        this.id = id;
        this.name = name;
    }
}


