use Test;

use CSV::Table :CT;

my ($f1, $f2, $f3, $f4, $f5, $f6, $f7);
$f1 = "config-csv-table.yml";
$f2 = "config-csv-table.json";
$f3 = "t.json";
$f4 = "t.yaml";
$f5 = "t.yml";
$f6 = "t.y";
$f7 = "config-csv-table.yaml";

sub D($f) { unlink($f) if $f and $f.IO.r; }
BEGIN {
    D $f1; D $f2; D $f3; D $f4; D $f5; D $f6; D $f7;
}
END {
    D $f1; D $f2; D $f3; D $f4; D $f5; D $f6; D $f7;
}

dies-ok { CSV::Table.write-config: $f3, :type<yaml>; },
    "invalid input: entered both file and type";

lives-ok {
    CSV::Table.write-config;
}, "valid, default type (yaml), lives";


lives-ok {
    CSV::Table.write-config: :type<json>;
}, "default .json";

# test the self-selected file names
lives-ok { CSV::Table.write-config: $f4, :force; }, "valid file name";
lives-ok { CSV::Table.write-config: $f5, :force; }, "valid file name";
dies-ok { CSV::Table.write-config: $f6, :force; }, "invalid file name";

# test all the combos
lives-ok { CSV::Table.write-config: :force, :type<yam>; }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type<ya>; }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type<y>; }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type<yml>; }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type<ym>; }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type<jso>; }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type<js>; }, "valid input type";
lives-ok { CSV::Table.write-config: :force, :type<j>; }, "valid input type";

done-testing;
