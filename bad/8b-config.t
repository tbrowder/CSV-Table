use Test;

use YAMLish;
use JSON::Fast;
use File::Temp;

use CSV::Table :CT;

my $debug = 1; # output files are place in local dir "tmp"

# test saving in a temp dir
my $tdir = $debug ?? "tmp" !! tempdir;
mkdir $tdir;

# the test csv contents (4 lines)
# by line without the '||' line endings:
my @csv = [
"; tabs, '||' line endings ",
"name	 age 	 notes ",
" Sally   
Jean	22 ",
"Tom	 30	 rakuun"
];

# the test file
my $f = "$tdir/conf-test.csv";

# write the test file
my $fh = open $f, :w, :nl-out("||");
for @csv {
    $fh.say: $_;
}
$fh.close;

my ($of1, $of2, $f3, $f4, $f5, $f6);
$of1 = "$tdir/config-csv-table.yml";
$of2 = "$tdir/config-csv-table.json";

my $cy = "t/data/conf-rev.yml";
my $cj = "t/data/conf-rev.json";

my $t;

$t = CSV::Table.new: :csv($f), :config($cy);
is $t.has-header, True, "has header";
is $t.separator, '\t', "sep char is a tab";
is $t.comment-char, ";", "comment-char semicolon";
is $t.line-ending, '||', "line-ending '||'";

is $tdir.IO.d, True, "making dir '$tdir'";

my $tstem = "$tdir/test-out";
my $tcsv = $tstem ~ ".csv";
my $traw = $tstem ~ $t.raw-ending ~ ".csv";
lives-ok { $t.save: $tstem, :force; }, "save and rename";

is $tcsv.IO.r, True, "commented written";
is $traw.IO.r, True, "commented -clean written";

done-testing;
=finish


$t = CSV::Table.new: :csv($f1), :config($cj);

# test the self-selected file names
lives-ok { CSV::Table.write-config: $f4, :force; }, "valid file name";
lives-ok { CSV::Table.write-config: $f5, :force; }, "valid file name";

# test all the combos
lives-ok { CSV::Table.write-config: :force, :type(yam); }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type(ya); }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type(y); }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type(yml); }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type(ym); }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type(jso); }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type(js); }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type(j); }, "valid input type";

done-testing;

