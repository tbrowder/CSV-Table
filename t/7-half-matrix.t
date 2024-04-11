use Test;

use CSV::Table;

my $csv = "t/data/half-matrix.csv";
my $t = CSV::Table.new: :$csv, :has-header(False);

isa-ok $t, CSV::Table;
is $t.shape, [5, 5];

my @arr;
@arr = $t.slice(0..0, 0..1);
is @arr[0][0], '00';
is @arr[0][1], '';

$t = CSV::Table.new: :$csv, :empty-cell-value(0), :has-header(False);
is $t.cell[0][0], '00';

is $t.cell[0][1], 0, "zero at row 0, col 1";
is $t.cell[1][2], 0, "zero at row 1, col 2";
is $t.cell[2][3], 0, "zero at row 2, col 3";
is $t.cell[3][4], 0, "zero at row 3, col 4";

done-testing;
