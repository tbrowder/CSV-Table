#!/usr/bin/env raku

use lib ".";
use AutoSave;

my $autosave = True;

my $f = "/tmp/t.file";
spurt $f, "name";

my $a = AutoSave.new: :file($f), :$autosave;

my @lines;
for $f.IO.lines.kv -> $i, $line {
    say "$i: $line";
    @lines.push;
}

