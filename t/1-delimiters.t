use Test;
use CSV::Table;

my $csv = 't/data/delimiters.csv';
=begin comment
name, age; height; weight
Sally  Jean,21; 52; 103
=end comment

is $csv.IO.r, True, "file '$csv' is readable";

my $t = CSV::Table.new: :$csv;

is $t.comment-char, "#";
is $t.trim, True, "trim is True";
is $t.normalize, True, "normalize is True";
is $t.separator, ';', "separator is ';'";
is $t.field.elems, 3;
is $t.field[0], 'name, age';
is $t.field[1], 'height';
is $t.field[2], 'weight';
is $t.fields, 3, "num fields 3";
is $t.rows, 1, "num rows 1";
is $t.cell.elems, 1;
is $t.cell[0].elems, 3;
is $t.cell[0][0], "Sally Jean,21", "cell[0][0] is Sally Jean,21";
is $t.cell[0][1], 52;
is $t.cell[0][2], 103;

is $t.rowcol(0, 2), 103;
is $t.rc(0, 2), 103;
is $t.ij(0, 2), 103;
is $t.colrow(1, 0), 52;
is $t.cr(1, 0), 52;
is $t.ji(1, 0), 52;

# try changing a value
$t.cell[0][1] = 48;
is $t.cell[0][1], 48;
$t.rowcol(0, 1, 50);
is $t.cell[0][1], 50;

# test the hashes
is $t.col<weight>[0], 103;

# possible
$t.field[0] = "Name";
is $t.field[0], "Name";

# but that change HAS NOT changed the hash keys
# TODO make suitable test
isnt $t.col<Name>[0], 103;

done-testing;

