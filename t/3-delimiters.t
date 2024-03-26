use Test;
use CSV::Table;

my $csv = 't/data/delimiters.csv';
is $csv.IO.r, True;

my $t = CSV::Table.new: :$csv;
is $t.separator, ';';

done-testing;
