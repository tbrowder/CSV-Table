use Test;

use CSV::Table;

my $csv = "t/data/matrix.csv";
my $t = CSV::Table.new: :$csv, :has-header(False);

isa-ok $t, CSV::Table;

my @arr;
@arr = $t.slice(0..0, 0..0);
is @arr[0][0], '00';
# test calling aliases
@arr = $t.slice2d(0..0, 0..0);
is @arr[0][0], '00';
@arr = $t.view(0..0, 0..0);
is @arr[0][0], '00';

@arr = $t.slice(0..1, 0..1);
is @arr[0][0], '00';
is @arr[0][1], '01';
is @arr[1][0], '10';
is @arr[1][1], '11';

@arr = $t.slice(1..2, 1..2);
is @arr[0][0], '11';
is @arr[0][1], '12';
is @arr[1][0], '21';
is @arr[1][1], '22';

# exceed limits
dies-ok { @arr = $t.slice(-1..4, 4..4) }
dies-ok { @arr = $t.slice(4..4, -1..4) }
dies-ok { @arr = $t.slice(4..5, 4..4) }
dies-ok { @arr = $t.slice(4..4, 4..5) }

done-testing;
