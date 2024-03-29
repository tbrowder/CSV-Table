use Test;
use CSV::Table;

# name, age; height; weight
# Sally  Jean,21; 52; 103

my $csv = 't/data/delimiters.csv';
is $csv.IO.r, True;

my $t = CSV::Table.new: :$csv;

is $t.separator, ';';

is $t.field.elems, 3;
is $t.field[0], 'name, age';
is $t.field[1], 'height';
is $t.field[2], 'weight';

is $t.cell.elems, 1;
is $t.cell[0].elems, 3;
is $t.cell[0][0], 'Sally Jean,21';
is $t.cell[0][1], '52';
is $t.cell[0][2], '103';

done-testing;
