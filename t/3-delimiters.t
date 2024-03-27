use Test;
use CSV::Table;

# name, age; height; weight
# Sally  Jean,21; 52; 103

my $csv = 't/data/delimiters.csv';
is $csv.IO.r, True;

my $t = CSV::Table.new: :$csv;

is $t.separator, ';';

is $t.fields-a.elems, 3;
is $t.fields-a[0], 'name, age';
is $t.fields-a[1], 'height';
is $t.fields-a[2], 'weight';

is $t.lines-a.elems, 1;
is $t.lines-a[0].elems, 3;
is $t.lines-a[0][0], 'Sally Jean,21';
is $t.lines-a[0][1], '52';
is $t.lines-a[0][2], '103';

done-testing;
