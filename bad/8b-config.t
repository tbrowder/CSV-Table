use Test;

use YAMLish;
use JSON::Fast;
	
use CSV::Table :CT;

my $cy = "t/data/conf-rev.yml";
my $cj = "t/data/conf-rev.json";

my $f1 = "t/data/conf-test.csv";

=begin comment
my $s = slurp $cy;
my %h = load-yaml $s;
dd %h;
done-testing;
=finish
=end comment

my $t;

lives-ok {
    $t = CSV::Table.new: :csv($f1), :config($cy);
}, "conf.yml";

lives-ok {
    $t = CSV::Table.new: :csv($f1), :config($cj);
}, "conf.json";

lives-ok {
    CSV::Table.write-config: :type(json);
}, "default .json";

done-testing;
=finish

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

