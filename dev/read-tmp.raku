#!/usr/bin/env raku

my $f = "../tmp/saved.csv";
for $f.IO.lines {
    say $_;
}

