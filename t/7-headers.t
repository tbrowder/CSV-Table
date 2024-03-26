use Test;
use CSV::Table;

my $csv = 't/data/not-commented.csv';
is $csv.IO.r, True;

my $t = CSV::Table.new: :$csv;

is $t.separator, ',';
is $t.fields-a.elems, 2;
is $t.fields-a[0], 'name';
is $t.fields-a[1], 'age';
is $t.lines-a.elems, 1;
is $t.lines-a[0][0], 'Sally Jean';
is $t.lines-a[0][1], '21';
is $t.lines-a[0].elems, 2;

done-testing;
