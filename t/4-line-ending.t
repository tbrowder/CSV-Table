use Test;
use CSV::Table;

my $csv = 't/data/line-enders.csv';
=begin comment
# content of $csv:
name, age , notes ||
 Sally   
Jean,22 ||
Tom, 30, male
=end comment

is $csv.IO.r, True;

my $line-ending = "||";
my $t = CSV::Table.new: :$csv, :$line-ending;

is $t.line-ending, '||';

is $t.field.elems, 3, "field elems 3";
is $t.field[0], 'name', "field 0 'name'";
is $t.field[1], 'age', "field 1 'age'";
is $t.field[2], 'notes', "field 2 'notes'";

is $t.cell.elems, 2;

is $t.cell[0].elems, 3, "input one missing cell";
is $t.cell[0][0], 'Sally Jean';
is $t.cell[0][1], '22';
is $t.cell[0][2], '', "this is the added empty cell";

is $t.cell[1].elems, 3;
is $t.cell[1][0], 'Tom';
is $t.cell[1][1], '30';
is $t.cell[1][2], 'male';

done-testing;

