use Test;
use CSV::Parser::Simple;

plan 1;

my $f = 't/data/not-commented.csv';
is $f.IO.r, True;

done-testing;

=finish

{
    my $outcome = 1;
    my $fn      = 't/data/not-commented.csv'.IO;
    my $parser  = CSV::Parser.new( contains_header_row => True, file_name => $fn );
    my %line    = %($parser.get_line());
    my %hdrs    = $parser.headers;
    my @hdrs    = $parser.headers: :list;

    $outcome    = 0 if %hdrs<0>    ne 'name'; 
    $outcome    = 0 if %hdrs<1>    ne 'age'; 
    $outcome    = 0 if @hdrs[0]    ne 'name'; 
    $outcome    = 0 if @hdrs[1]    ne 'age'; 
    $outcome    = 0 if %line<name> ne 'Sally';
    $outcome    = 0 if %line<age>  ne '21';

    ok $outcome == 1;
}

{
    my $outcome = 1;
    my $fn      = 't/data/not-commented.csv'.IO;
    my $parser  = CSV::Parser.new( contains_header_row => False, file_name => $fn );

    my %line    = %($parser.get_line());
    $outcome    = 0 if %line<0> ne 'name';
    $outcome    = 0 if %line<1> ne 'age';

    %line    = %($parser.get_line());
    $outcome    = 0 if %line<0> ne 'Sally';
    $outcome    = 0 if %line<1> ne '21';

    ok $outcome == 1;
}

{
    my $outcome = 1;
    my $fn      = 't/data/not-commented.csv'.IO;
    my $parser  = CSV::Parser.new( contains_header_row => False, file_name => $fn );

    my %line    = %($parser.get_line());
    my %hdrs    = $parser.headers;

    is %hdrs.elems, 0;
}

