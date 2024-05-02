unit module Utils;

sub write-csv() is export {
}

sub write-test() is export {
}

sub get-abbrev($v) is export {
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
