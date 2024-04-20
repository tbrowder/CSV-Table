use Test;

use YAMLish;
use JSON::Fast;
	
use CSV::Table :CT;

# the test csv contents (5 lines:
=begin comment
; tabs, '||' line endings ||
name	 age 	 notes ||
 Sally   
Jean	22 ||
Tom	 30	 male
=end comment


my ($of1, $of2, $f3, $f4, $f5, $f6);
$of1 = "config-csv-table.yml";
$of2 = "config-csv-table.json";
sub D($f) { unlink($f) if $f and $f.IO.r; }
=begin comment
BEGIN { 
    D $of1; D $of2;# D $f3; D $f4; D $f5; D $f6; 
}
END { 
    D $of1; D $of2;# D $f3; D $f4; D $f5; D $f6; 
}
=end comment

my $cy = "t/data/conf-rev.yml";
my $cj = "t/data/conf-rev.json";

my $f1 = "t/data/conf-test.csv";

my $t;

$t = CSV::Table.new: :csv($f1), :config($cy);
is $t.has-header, True;
is $t.separator, '\t';
is $t.comment-char, ";";
is $t.line-ending, '||';
$t.save: "test-out";

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

