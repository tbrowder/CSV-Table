use Test;
use CSV::Table;


my $csv = 't/data/delimiters.csv';
=begin comment
name, age; height; weight
Sally  Jean,21; 52; 103
=end comment

is $csv.IO.r, True;

my $t = CSV::Table.new: :$csv;
#note dd $t; exit;

is $t.trim, True;
is $t.normalize, True;
is $t.separator, ';';
is $t.rows, 1, "num rows 1";
is $t.fields, 3, "num fields 3";

done-testing;
=finish
is $t.cell[0][0], "Sally Jean,21";
is $t.cell[0][1], "52";
is $t.cell[0][2], "103";

is $t.field.elems, 3;
is $t.field[0], 'name, age';
is $t.field[1], 'height';
is $t.field[2], 'weight';



is $t.row.elems, 1;
is $t.cell.elems, 1;
is $t.cell[0].elems, 3;
is $t.cell[0][0], 'Sally Jean,21';
is $t.cell[0][1], '52';
is $t.cell[0][2], '103';

done-testing;
