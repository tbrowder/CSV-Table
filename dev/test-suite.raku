use Test;

use File::Temp;

use Text::Utils :ALL; #:strip-comment :normalize-string;

use lib ".";
use Utils;

my $debug = 1; # output files are placed in local dir "tmp"

# test saving in a temp dir
my $tdir = $debug ?? "tmp" !! tempdir;
mkdir $tdir;

# this is the way to most easily create an array of strings
#my @x = qqww{ "\n"  ; || , "\t" | '#' };

my @comment-chars = qqww{ '#'  ;    --   }; # with :first, semi can be a sep char

# the line-ending and sepchar strings cannot share a common character
my @line-endings  = qqww{ "\n"   ||      };
my @sepchars      = qqww{  ,   ; |  "\t" };
#                                |<== these are limited to one role in a file

# the test csv contents
# by line without a defined line ending
my @hdr  = [" name         ", " age ", " notes " ];
my @row1 = [" Sally x Jean ", " 22  ", "       " ]; # replace 'x' with '\n' or ' '
my @row2 = [" Tom          ", " 30  ", " rakuun "];
my $ncols = 3;

# Generate the test files
my $prefix = "csv";
my $idx  = 0;
my $pipe = 0;
my $semi = 0;
my ($LE, $SC, $CC);
constant \pipe   = "pipe";
constant \nl     = "nl";
constant \tab    = "tab";
constant \hash   = "hash";
constant \semi   = ";";
constant \dashes = "--";

# create a file that lists the test files
my $flist = "csv-test-input-files-list.txt";
my $ft = open $flist, :w;

LE: for @line-endings -> $le {
    # currently one of: \n || ;
    $LE = get-abbrev $le;

    note "DEBUG: line ending is \<$LE\>" if 0 and $debug;
    if $le ~~ /\n/ {
        note "DEBUG: line ending is a newline" if 0 and $debug;
    }

    # get the dir name
    my $odir = "$tdir/$LE";

    CC: for @comment-chars -> $cc {
        # currently one of: # ;  --
        $CC = get-abbrev $cc;

        SC: for @sepchars -> $sc {
            next SC if ?($le.comb (&) $sc.comb);

            # currently one of: , ; | \t
            $SC = get-abbrev $sc;

            # semicolons cannot appear in more than one role
            # pipes and double pipes can only appear in one role

            my $comment = "Using mark ('$CC'), sepchar ('$SC'), line ending ('$LE')";

            my $fnam = "csv-{$CC}-{$SC}.csv";
            $fnam = "$odir/$fnam";

            # write to the file name list
            $ft.say: $fnam;
        
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
            $fh.note();

            for @row2.kv -> $i, $v is copy {
                $fh.print: $v;
                $fh.print($sc) if $i < $ncols - 1;
            }
            $fh.note();
            #===========
            $fh.close;

            # Now run tests on the generated file
            note "DEBUG: testing file '$fnam'";
            $fh = open $fnam, :r, :nl-in($le); #, :!chomp;
            LINE: for $fh.lines.kv -> $i, $line is copy {
                note "  DEBUG line pre-strip : '$line'";
                $line = strip-comment $line, :first, :mark($cc);
                note "  DEBUG line post-strip: '$line'";
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
                for @cells.kv -> $i, $v is copy {
                    @tcells[$i] = normalize-string $v;
                }
                is @tcells.elems, 3;
                # i=1: @hdr  = [" name         ", " age ", " notes " ];
                # i=2: @row1 = [" Sally x Jean ", " 22  ", "       " ];
                #                 replace 'x' with '\n' or ' '
                # i=3: @row2 = [" Tom          ", " 30  ", " rakuun "];
                if $i == 1 {
                    is @tcells[0], "name";
                    is @tcells[1], "age";
                    is @tcells[2], "notes";
                }
                elsif $i == 2 {
                    if $le ~~ /\n/ {
                        is @tcells[0], "Sally Jean", "Sally with newline line ending";
                    }
                    else {
                        is @tcells[0], "Sally\nJean", "Sally WITHOUT newline line ending";
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
                note "DEBUG normalize tabs" if $debug;
                # normalize tabs
                for @cells.kv -> $i, $v is copy {
                    @tcells[$i] = normalize-string $v, :t<n>;
                }
                is @tcells.elems, 3;
                # i=1: @hdr  = [" name         ", " age ", " notes " ];
                # i=2: @row1 = [" Sally x Jean ", " 22  ", "       " ];
                #                 replace 'x' with '\n' or ' '
                # i=3: @row2 = [" Tom          ", " 30  ", " rakuun "];
                if $i == 1 {
                    is @tcells[0], "name";
                    is @tcells[1], "age";
                    is @tcells[2], "notes";
                }
                elsif $i == 2 {
                    if $le ~~ /\n/ {
                        is @tcells[0], "Sally Jean", "Sally with newline line ending";
                    }
                    else {
                        is @tcells[0], "Sally\nJean", "Sally WITHOUT newline line ending";
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
                # normalize newlines
                note "DEBUG normalize newlines" if $debug;
                for @cells.kv -> $i, $v is copy {
                    @tcells[$i] = normalize-string $v, :n<n>;
                }
                is @tcells.elems, 3;
                # i=1: @hdr  = [" name         ", " age ", " notes " ];
                # i=2: @row1 = [" Sally x Jean ", " 22  ", "       " ];
                #                 replace 'x' with '\n' or ' '
                # i=3: @row2 = [" Tom          ", " 30  ", " rakuun "];
                if $i == 1 {
                    is @tcells[0], "name";
                    is @tcells[1], "age";
                    is @tcells[2], "notes";
                }
                elsif $i == 2 {
                    if $le ~~ /\n/ {
                        is @tcells[0], "Sally Jean", "Sally with newline line ending";
                    }
                    else {
                        is @tcells[0], "Sally\nJean", "Sally WITHOUT newline line ending";
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
                # normalize tabs and newlines
                note "DEBUG normalize tabs and newlines" if $debug;
                for @cells.kv -> $i, $v is copy {
                    @tcells[$i] = normalize-string $v, :t<n>, :n<n>;
                }
                is @tcells.elems, 3;
                # i=1: @hdr  = [" name         ", " age ", " notes " ];
                # i=2: @row1 = [" Sally x Jean ", " 22  ", "       " ];
                #                 replace 'x' with '\n' or ' '
                # i=3: @row2 = [" Tom          ", " 30  ", " rakuun "];
                if $i == 1 {
                    is @tcells[0], "name";
                    is @tcells[1], "age";
                    is @tcells[2], "notes";
                }
                elsif $i == 2 {
                    if $le ~~ /\n/ {
                        is @tcells[0], "Sally Jean", "Sally with newline line ending";
                    }
                    else {
                        is @tcells[0], "Sally\nJean", "Sally WITHOUT newline line ending";
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
                # collapse to spaces
                note "DEBUG collapse to spaces" if $debug;
                for @cells.kv -> $i, $v is copy {
                    @tcells[$i] = normalize-string $v, :c<s>;
                }
                is @tcells.elems, 3;
                # i=1: @hdr  = [" name         ", " age ", " notes " ];
                # i=2: @row1 = [" Sally x Jean ", " 22  ", "       " ];
                #                 replace 'x' with '\n' or ' '
                # i=3: @row2 = [" Tom          ", " 30  ", " rakuun "];
                if $i == 1 {
                    is @tcells[0], "name";
                    is @tcells[1], "age";
                    is @tcells[2], "notes";
                }
                elsif $i == 2 {
                    if $le ~~ /\n/ {
                        is @tcells[0], "Sally Jean", "Sally with newline line ending";
                    }
                    else {
                        is @tcells[0], "Sally\nJean", "Sally WITHOUT newline line ending";
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
                # collapse to tabs
                note "DEBUG collapse to tabs" if $debug;
                for @cells.kv -> $i, $v is copy {
                    @tcells[$i] = normalize-string $v, :c<t>;
                }
                is @tcells.elems, 3;
                # i=1: @hdr  = [" name         ", " age ", " notes " ];
                # i=2: @row1 = [" Sally x Jean ", " 22  ", "       " ];
                #                 replace 'x' with '\n' or ' '
                # i=3: @row2 = [" Tom          ", " 30  ", " rakuun "];
                if $i == 1 {
                    is @tcells[0], "name";
                    is @tcells[1], "age";
                    is @tcells[2], "notes";
                }
                elsif $i == 2 {
                    if $le ~~ /\n/ {
                        is @tcells[0], "Sally Jean", "Sally with newline line ending";
                    }
                    else {
                        is @tcells[0], "Sally\nJean", "Sally WITHOUT newline line ending";
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
                # collapse to newlines
                note "DEBUG collapse to newlines" if $debug;
                for @cells.kv -> $i, $v is copy {
                    @tcells[$i] = normalize-string $v, :c<n>;
                }
                is @tcells.elems, 3;
                # i=1: @hdr  = [" name         ", " age ", " notes " ];
                # i=2: @row1 = [" Sally x Jean ", " 22  ", "       " ];
                #                 replace 'x' with '\n' or ' '
                # i=3: @row2 = [" Tom          ", " 30  ", " rakuun "];
                if $i == 1 {
                    is @tcells[0], "name";
                    is @tcells[1], "age";
                    is @tcells[2], "notes";
                }
                elsif $i == 2 {
                    if $le ~~ /\n/ {
                        is @tcells[0], "Sally Jean", "Sally with newline line ending";
                    }
                    else {
                        is @tcells[0], "Sally\nJean", "Sally WITHOUT newline line ending";
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
            }
            $fh.close;
        }
    }
}
note "Wrote $idx test files" if $debug;
done-testing;

exit;
=finish

my $f = "$tdir/conf-test.csv";
# write the test file
my $fh = open $f, :w, :nl-out("||");
for @csv {
    $fh.note: $_;
}
$fh.close;

#my ($of1, $of2, $f3, $f4, $f5, $f6);
#$of1 = "$tdir/config-csv-table.yml";
#$of2 = "$tdir/config-csv-table.json";

my $cy = "t/data/conf-rev.yml";
my $cj = "t/data/conf-rev.json";

my $t;

$t = CSV::Table.new: :csv($f), :config($cy);
is $t.has-header, True, "has header";
is $t.separator, '\t', "sep char is a tab";
is $t.comment-char, ";", "comment-char semicolon";
is $t.line-ending, '||', "line-ending '||'";
is $t.normalize, False, "normalize False";

# check values
is $t.rows, 2, "2 rows";
is $t.fields, 3, "3 fields";
is $t.field[0], "name", "field 0 is name";

is $tdir.IO.d, True, "making dir '$tdir'";
my $tstem = "$tdir/test-out";
my $tcsv = $tstem ~ ".csv";
my $traw = $tstem ~ $t.raw-ending ~ ".csv";
lives-ok { $t.save: $tstem, :force; }, "save and rename";

is $tcsv.IO.r, True, "commented written";
is $traw.IO.r, True, "commented -clean written";

done-testing;
=finish


$t = CSV::Table.new: :csv($f1), :config($cj);

# test the self-selected file names
lives-ok { CSV::Table.write-config: $f4, :force; }, "valid file name";
lives-ok { CSV::Table.write-config: $f5, :force; }, "valid file name";

# test all the combos
lives-ok { CSV::Table.write-config: :force, :type(yam); }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type(ya); }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type(y); }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type(yml); }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type(ym); }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type(jso); }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type(js); }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type(j); }, "valid input type";

done-testing;
