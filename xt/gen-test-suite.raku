#!/usr/bin/env raku

use File::Temp;

use lib "./t/data/lib";
use Utils;

if not @*ARGS {
    print qq:to/HERE/;
    Usage: ./xt/{$*PROGRAM.basename}

    Execute this file to generate test files in directory "xt".
    HERE
    exit;
}

my $debug = 0; # output files are placed in local dir "tmp"

# test saving in a temp dir
#my $tdir = $debug ?? "./xt/tmp" !! tempdir;
my $tdir = "./xt";

mkdir $tdir;
mkdir "$tdir/nl";
mkdir "$tdir/dpipe";

# this is the way to most easily create an array of strings
#my @x = qqww{ "\n"  ; || , "\t" | '#' };

my @comment-chars = qqww{ '#'  ;    --   }; # with :first, semi can be a sep char

# the line-ending and sepchar strings cannot share a common character
my @line-endings  = qqww{ "\n"   ||      };
my @sepchars      = qqww{  ,   ; |  "\t" };
#                                |<== these are limited to one role in a file

# the test csv contents
# by line without a defined line ending
my @hdr  = [" name "          , " age ", " notes " ];
my @row1 = [" Sally  x  Jean ", " 22 " , " "       ]; # replace 'x' with '\n' or ' '
my @row2 = [" Tom "           , " 30 " , " rakuun "];
my $ncols = 3;

# Generate the test files
my $prefix = "csv";
my $idx  = 0;
my $pipe = 0;
my $semi = 0;
my ($LE, $SC, $CC);

# create a file that lists the test files
#my $flist = "$tdir/csv-test-input-files-list.txt";
#my $ft    = open $flist, :w;

# create a file that runs the test files
#my $fe = open "xt/run-test-files.sh", :w;

LE: for @line-endings -> $le {
    # currently one of: \n || 
    $LE = get-abbrev $le;

    note "DEBUG: line ending is '$LE'" if 0 and $debug;
    if $le ~~ /\n/ {
        note "DEBUG: line ending is a newline" if 0 and $debug;
    }

    # get the dir name
    my $odir = "$tdir/$LE";

    CC: for @comment-chars -> $cc {
        # currently one of: # ;  --
        $CC = get-abbrev $cc;

        SC: for @sepchars -> $sc {
            # currently one of: , ; | \t
            next SC if ?($le.comb (&) $sc.comb);

            $SC = get-abbrev $sc;
            note "DEBUG: sepchar '$SC'" if 0 and $debug;
            next SC if $SC eq $CC;

            # semicolons cannot appear in more than one role
            # pipes and double pipes can only appear in one role

            my $comment = "Using mark ('$CC'), sepchar ('$SC'), line ending ('$LE')";

            my $fnam  = "csv-{$CC}-{$SC}.csv";
            my $fnamt = "csv-{$CC}-{$SC}.t";
            $fnam     = "$odir/$fnam";
            $fnamt    = "$odir/$fnamt";

            # write to the file name list
#            $ft.say: $fnam;
#            $ft.say: $fnamt;

            # write to the exe list
#            $fe.say: "raku -I. $fnamt";
        
            my $fh = open $fnam, :w, :nl-out($le); #, :!chomp;
            #===========
            $fh.say: "$cc $comment";
            for @hdr.kv -> $i, $v is copy {
                $fh.print: $v;
                $fh.print($sc) if $i < $ncols - 1;
            }
            $fh.say();

            for @row1.kv -> $i, $v is copy  {
                # special col 0
                if $i == 0 and $v.contains('x') {
                    note "DEBUG: \$v contains x" if 0 and $debug;
                    if $le ~~ /\n/ {
                        note "DEBUG: x with newline ending" if 0 and $debug;
                        $v ~~ s/x/ /;
                    }
                    else {
                        note "DEBUG: x with NO newline ending" if 0 and $debug;
                        $v ~~ s/x/\n/;
                    }
                }

                $fh.print: $v;
                $fh.print($sc) if $i < $ncols - 1;
            }
            $fh.say();

            for @row2.kv -> $i, $v is copy {
                $fh.print: $v;
                $fh.print($sc) if $i < $ncols - 1;
            }
            $fh.say();
            #===========
            $fh.close;

            # write the test file
            my $fht = open $fnamt, :w;

            #=begin comment
            $fht.print: q:to/HERE/;
            use Test;
            use Text::Utils :ALL;
            use CSV::Table;
            HERE

            $fht.print: qq:to/HERE/;
            \# var defs
            my \$fnam  = '{$fnam}';
            my \$fnamt = '{$fnamt}';
            my \$le    = '{$le}';
            my \$sc    = '{$sc}';
            my \$cc    = '{$cc}';
            my \$debug = '{$debug}';
            HERE

            $fht.print: q:to/HERE/;
            # Now run tests on the generated file
            note "=== DEBUG: testing file '$fnam'" if 0 and $debug;
            my $fh = open $fnam, :r, :nl-in($le); #, :!chomp;
            LINE: for $fh.lines.kv -> $i, $line is copy {
                note "    DEBUG line pre-strip : '$line'" if 0 and $debug;
                $line = strip-comment $line, :first, :mark($cc);
                note "    DEBUG line post-strip: '$line'" if 0 and $debug;
                if $i == 0 {
                    # the comment line
                    # line should be empty
                    is ($line !~~ /\S/).so, True;
                    next LINE;
                }
                # split on the sepchar
                # note that default normalizing counts \n and \t as whitespace
                my @cells = $line.split(/$sc/);

                # need to break down further to test different options here
                my @tcells = [];

                #===================
                # default
                note "    DEBUG default normalize" if 0 and $debug;
                for @cells.kv -> $i, $v is copy {
                    @tcells[$i] = normalize-string $v;
                }
                is @tcells.elems, 3;
                # i=1: @hdr  = [" name "          , " age ", " notes " ];
                # i=2: @row1 = [" Sally  x  Jean ", " 22 " , " "       ];
                #                 replace 'x' with '\n' or ' '
                # i=3: @row2 = [" Tom "           , " 30 " , " rakuun "];
                if $i == 1 {
                    is @tcells[0], "name";
                    is @tcells[1], "age";
                    is @tcells[2], "notes";
                }
                elsif $i == 2 {
                    if $le ~~ /\n/ {
                        is @tcells[0], "Sally Jean", "Sally with NL line ending";
                    }
                    else {
                        is @tcells[0], "Sally Jean", "Sally WITHOUT NL line ending";
                    }
                    is @tcells[1], "22";
                    is @tcells[2], "";
                }
                elsif $i == 3 {
                    is @tcells[0], "Tom";
                    is @tcells[1], "30";
                    is @tcells[2], "rakuun";
                }
                #===================

                #===================
                # normalize=False
                #  (but trim=True)
                note "    DEBUG normalize=False (but trim=True)" if 0 and $debug;
                for @cells.kv -> $i, $v is copy {
                    $v .= trim;
                    @tcells[$i] = $v;
                }
                is @tcells.elems, 3;
                # i=1: @hdr  = [" name "          , " age ", " notes " ];
                # i=2: @row1 = [" Sally  x  Jean ", " 22 " , " "       ];
                #                 replace 'x' with '\n' or ' '
                # i=3: @row2 = [" Tom "           , " 30 " , " rakuun "];
                if $i == 1 {
                    is @tcells[0], "name";
                    is @tcells[1], "age";
                    is @tcells[2], "notes";
                }
                elsif $i == 2 {
                    if $le ~~ /\n/ {
                        is @tcells[0], "Sally     Jean", "Sally with NL line ending";
                    }
                    else {
                        is @tcells[0], "Sally  \n  Jean", "Sally WITHOUT NL line ending";
                    }
                    is @tcells[1], "22";
                    is @tcells[2], "";
                }
                elsif $i == 3 {
                    is @tcells[0], "Tom";
                    is @tcells[1], "30";
                    is @tcells[2], "rakuun";
                }
                #===================

                #===================
                # trim=False (and normalize=False)
                note "    DEBUG trim=False (and normalize=False)" if 0 and $debug;
                for @cells.kv -> $i, $v is copy {
                    @tcells[$i] = $v;
                }
                is @tcells.elems, 3;
                # i=1: @hdr  = [" name "          , " age ", " notes " ];
                # i=2: @row1 = [" Sally  x  Jean ", " 22 " , " "       ];
                #                 replace 'x' with '\n' or ' '
                # i=3: @row2 = [" Tom "           , " 30 " , " rakuun "];
                if $i == 1 {
                    is @tcells[0], " name ";
                    is @tcells[1], " age ";
                    is @tcells[2], " notes ";
                }
                elsif $i == 2 {
                    if $le ~~ /\n/ {
                        is @tcells[0], " Sally     Jean ", "Sally with NL line ending";
                    }
                    else {
                        is @tcells[0], " Sally  \n  Jean ", "Sally WITHOUT NL line ending";
                    }
                    is @tcells[1], " 22 ";
                    is @tcells[2], " ";
                }
                elsif $i == 3 {
                    is @tcells[0], " Tom ";
                    is @tcells[1], " 30 ";
                    is @tcells[2], " rakuun ";
                }
                #===================
            }
            done-testing;
            $fh.close;
            HERE
            $fht.close;
            ++$idx;
            note "=== DEBUG: END testing file '$fnam'" if 0 and $debug;
            #=end comment
        }
    }
}
note "Wrote $idx test files" if 0 and $debug;


