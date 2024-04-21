use Test;
use CSV::Table;

use File::Temp;

my $debug = 1; # output files are place in local dir "tmp"

# this is the single "master" csv file with all possible comment placements:
my $csv  = 't/data/commented.csv';

# these are the expected files produced upon .save:
#   no comments, cell separation by a single space
my $csv1r = 't/data/expected/commented-raw.csv';
#   no comments, columns aligned by max field width
my $csv2r = 't/data/expected/commented-raw2.csv';
#   no comments, columns aligned by max field width, change sepchar to pipe
my $csv3r = 't/data/expected/commented-raw3.csv';

#   comments per original spacing, cell separation by a single space
my $csv1 = 't/data/expected/commented3.csv';
#   comments per original spacing, cells aligned by max field width 
my $csv2 = 't/data/expected/commented4.csv';

# for future use with normalized comments
#   comments normalized, cells aligned by max field width 
my $csv6 = 't/data/expected/commented5.csv';

#END { unlink $csvt }

=begin comment
# an example of terminology
# a commented CSV file                 < line -1, trailing[0]
#                                      < line -1, trailing[1]
name, age                              < line  0
# Sally is my sister                   < line  0, trailing[0]
Sally   Jean,21 # she really is        < line  1, inline
  # another comment                    < line  1, trailing[0]
#                                      < line  1, trailing[1]
=end comment

# actual contents of t/data/commented.csv
=begin comment
# a commen,age
      name,age
# Sally is my sister
Sally Jean,# she really is
# another comment
# 
=end comment

is $csv.IO.r, True;

my $t = CSV::Table.new: :$csv;
is $t.comment<-1>.trailing.head, "# a commen,age";

is $t.field.elems, 2, "field elems 2";
is $t.field[0], 'name', "field 0 'name'";
is $t.field[1], 'age', "field 1 'age'";

is $t.cell.elems, 1;

is $t.cell[0].elems, 2;
is $t.cell[0][0], 'Sally Jean';
is $t.cell[0][1], '';

is $t.raw-csv, 't/data/commented-raw.csv', 'in same dir as src csv';

# test saving in a temp dir
my $tdir = $debug ?? "tmp" !! tempdir;
mkdir $tdir;

my $tcsv  = "$tdir/saved.csv";
my $tcsv2 = "$tdir/saved-raw.csv";
$t.save: $tcsv, :force;
is $tcsv.IO.r, True, "saved new csv file ok";
is $tcsv2.IO.r, True, "saved new raw csv file ok";

# are the outputs the same as expected?
# the outputs:
my $s1 = slurp $tcsv;
my $s2 = slurp $tcsv2;
# the expected:
my $s1e = slurp $csv1;
my $s2e = slurp $tcsv2;

is $s1, $s1e;

# test all comment combos

done-testing;

