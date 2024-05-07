use Test;
use CSV::Table;

my $csv  = 't/data/row-names.csv';

=begin comment
row/col    ,    jan,    feb,    mar,    apr,    may,    jun 
water      ,    $20,  10.80,  18.32,  21.63,  15.72,  19.91
electricity, 120.31, 150.42, 143.20, 170.45, 190.82, 210.34
gas        ,  45.00,  44.18,  47.41,  32.87,  46.29,  39.56
=end comment

is $csv.IO.r, True;

my $t = CSV::Table.new: :$csv, :has-row-names;

is $t.field.elems, 6, "field elems 6";
is $t.field[0], 'jan', "field 0 'jan'";
is $t.field[5], 'jun', "field 5 'jun'";

is $t.ulname, "row/col";
is $t.rowname[0], "water";
is $t.rowname[1], "electricity";
is $t.rowname[2], "gas";
is $t.row-width, 11;

done-testing;
=finish

is $t.cell.elems, 1;

is $t.cell[0].elems, 2;
is $t.cell[0][0], 'Sally Jean';
is $t.cell[0][1], '21';

is $t.raw-csv, 't/data/commented-raw.csv', 'in same dir as src csv';
$t.save: :force;

my $s1 = slurp $csv;
my $s2 = slurp $csv2;

done-testing;

