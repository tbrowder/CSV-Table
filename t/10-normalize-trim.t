use Test;
use CSV::Table;

my $csv = "t/data/normalize-trim.csv";

=begin comment
 name , age , notes 
 Sally  Jean , 22 ,  # replace 'x' with '\n' or ' '
 Tom , 30 , rakuun # 
=end comment

is $csv.IO.r, True, "file '$csv' is readable";

my $line = " , , ";
my @c = $line.split(/','/);
is @c[0], ' ';
is @c[1], ' ';
is @c[2], ' ';
$line = $csv.IO.lines[2];
is $line, " Tom , 30 , rakuun # "; 

my $t;

# use the default settings
$t = CSV::Table.new: :$csv;

is $t.comment-char, "#", "test normalize default";
is $t.trim, True, "trim is True";
is $t.normalize, True, "normalize is True";
is $t.separator, ',', "separator is ','";
is $t.field.elems, 3;
is $t.field[0], 'name';
is $t.field[1], 'age';
is $t.field[2], 'notes';
is $t.fields, 3, "num fields 3";
is $t.rows, 2, "num rows 3";

is $t.cell[0][0], 'Sally Jean';
is $t.cell[0][1], '22';
is $t.cell[0][2], '', "blank";

is $t.cell[1][0], 'Tom';
is $t.cell[1][1], '30';
is $t.cell[1][2], 'rakuun';

# use normalize=False
$t = CSV::Table.new: :$csv, :normalize(False);

is $t.comment-char, "#", "test normalize=False";
is $t.trim, True, "trim is True";
is $t.normalize, False, "normalize is False";
is $t.separator, ',', "separator is ','";
is $t.field.elems, 3;
is $t.field[0], 'name';
is $t.field[1], 'age';
is $t.field[2], 'notes';
is $t.fields, 3, "num fields 3";
is $t.rows, 2, "num rows 3";

is $t.cell[0][0], 'Sally  Jean';
is $t.cell[0][1], '22';
is $t.cell[0][2], '', "blank";

is $t.cell[1][0], 'Tom';
is $t.cell[1][1], '30';
is $t.cell[1][2], 'rakuun';

# use trim=False
$t = CSV::Table.new: :$csv, :trim(False);

is $t.comment-char, "#", "test trim=False";
is $t.trim, False, "trim is False";
is $t.normalize, False, "normalize is False";
is $t.separator, ',', "separator is ','";
is $t.field.elems, 3;
is $t.field[0], ' name ';
is $t.field[1], ' age ';
is $t.field[2], ' notes ';
is $t.fields, 3, "num fields 3";
is $t.rows, 2, "num rows 3";

is $t.cell[0][0], ' Sally  Jean ';
is $t.cell[0][1], ' 22 ';
is $t.cell[0][2], '  ', "blank";

is $t.cell[1][0], ' Tom ';
is $t.cell[1][1], ' 30 ';
is $t.cell[1][2], ' rakuun ', "blank last char";

done-testing;
=finish

is $t.cell.elems, 1;
is $t.cell[0].elems, 3;
is $t.cell[0][0], "Sally Jean,21", "cell[0][0] is Sally Jean,21";
is $t.cell[0][1], 52;
is $t.cell[0][2], 103;
