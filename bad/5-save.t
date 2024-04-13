use Test;
use CSV::Table;

# this is the single "master" csv file with all possible comment placements:
my $csv  = 't/data/commented.csv';

# these are the expected files produced upon .save:
#   no comments, cell separation by a single space
my $csv1 = 't/data/expected/commented-raw.csv';
#   no comments, columns aligned by max field width
my $csv2 = 't/data/expected/commented-raw2.csv';

#   comments per original spacing, cell separation by a single space
my $csv3 = 't/data/expected/commented3.csv';
#   comments per original spacing, cells aligned by max field width 
my $csv4 = 't/data/expected/commented4.csv';
#   comments normalized, cells aligned by max field width 
my $csv5 = 't/data/expected/commented5.csv';

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

is $csv.IO.r, True;

my $t = CSV::Table.new: :$csv;
is $t.comment<-1>.trailing.head, "# a commented CSV file";

is $t.field.elems, 2, "field elems 2";
is $t.field[0], 'name', "field 0 'name'";
is $t.field[1], 'age', "field 1 'age'";

is $t.cell.elems, 1;

is $t.cell[0].elems, 2;
is $t.cell[0][0], 'Sally Jean';
is $t.cell[0][1], '21';

is $t.raw-csv, 't/data/commented-raw.csv', 'in same dir as src csv';
$t.save: :force;

my $s1 = slurp $csv;
my $s2 = slurp $csv2;

done-testing;

