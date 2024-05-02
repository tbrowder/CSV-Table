unit module Utils;

sub get-abbrev($v) {
    # plain words for special chars
    my $abbrev = $v;
    $abbrev = "pipe"   if $v eq "|";
    $abbrev = "dpipe"  if $v eq "||";
    $abbrev = "nl"     if $v ~~ /\n/;
    $abbrev = "tab"    if $v ~~ /\t/;
    $abbrev = "hash"   if $v ~~ /'#'/;
    $abbrev = "semi"   if $v eq ';';
    $abbrev = "dashes" if $v eq '--';
    $abbrev
}
