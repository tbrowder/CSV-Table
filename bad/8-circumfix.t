use Test;
use CSV::Table;

sub circumfix:<[ ]>(Positional $a) {
}

my @b = 0, 1;
is @b[0], 0;

=finish

my $csv = 't/data/not-commented.csv';
is $csv.IO.r, True;

my $t = CSV::Table.new: :$csv;

is $t.separator, ',';
is $t.field.elems, 2;
is $t.field[0], 'name';
is $t.field[1], 'age';

is $t.cell.elems, 1;
is $t.cell[0].elems, 2;
is $t.cell[0][0], 'Sally Jean';
is $t.cell[0][1], '21';

done-testing;
