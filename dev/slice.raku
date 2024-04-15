#!/usr/bin/env raku
use lib ".";

class F {
    has @.arr;
    method slice(Range $a; Range $b) {
        # break the ranges down
        my $a0 = $a.head;
        my $aL = $a.tail;
        my $b0 = $b.head;
        my $bL = $b.tail;
        $a0, $aL, $b0, $bL;

        #@!arr[$a][$b]
    }

}

my @a = [[1, 2],[3,4]];
my $s = :(Range $a, Range $b);
dd $s;

my $o = F.new: :arr(@a);
dd $o;
say $o.slice(0..1, ^1);
