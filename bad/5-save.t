use Test;
use CSV::Table;

my $csv = 't/data/commented.csv';
=begin comment
# a commented CSV file                 < line -1, trailing[0]
#                                      < line -1, trailing[1]
name, age                              < line  0
# Sally is my sister                   < line  0, trailing[0]
Sally   Jean,21 # she really is        < line  1, comment
  # another comment                    < line  1, trailing[0]
#                                      < line  1, trailing[1]
=end comment

is $csv.IO.r, True;

my $t = CSV::Table.new: :$csv;
#say dd $t.comment;
#exit;
is $t.comment<-1>.trailing.head, "# a commented CSV file";

is $t.field.elems, 2, "field elems 2";
is $t.field[0], 'name', "field 0 'name'";
is $t.field[1], 'age', "field 1 'age'";

is $t.cell.elems, 1;

is $t.cell[0].elems, 2;
is $t.cell[0][0], 'Sally Jean';
is $t.cell[0][1], '21';

is $t.raw-csv, 't/data/commented-raw.csv', 'in same dir as src csv';
#$t.save: :force;

done-testing;

