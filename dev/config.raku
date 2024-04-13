#!/usr/bin/env raku

#use lib "../lib";
#use CSV::Table;
#use YAMLish;
use JSON::Fast;

#my $f = "./expected.yml";
my $f = "./expected.json";
#my $t = CSV::Table.new: :$config;
#my $str = $t.config.IO.slurp;

my $str = slurp $f; #.IO.slurp;

for $str.lines -> $line is copy {
    say "line: |$line|";
}
#my %c = load-yaml $str;
my %c = from-json $str;
dd %c;


=finish
exit;

dd $str;
dd %conf;

