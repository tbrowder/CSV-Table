use Test;
use CSV::Parser::Simple;

plan 1;

my $f = 't/data/commented.csv';
is $f.IO.r, True;

=finish

=begin comment
my $outcome = 1;

my $fn      = 't/data/commented.csv'.IO;
my $parser  = CSV::Parser.new( strip => True, file_name => $fn );
my %line    = %($parser.get_line());
 
$outcome    = 0 if %line{'0'} ne 'name'; 
$outcome    = 0 if %line{'1'} ne 'age'; 

%line       = %($parser.get_line());
$outcome    = 0 if %line{'0'} ne 'Sally'; 
$outcome    = 0 if %line{'1'} ne '21'; 

ok $outcome == 1;

$fn = 't/data/not-commented.csv'.IO;
$parser  = CSV::Parser.new( strip => False, file_name => $fn );

%line       = %($parser.get_line());
$outcome    = 0 if %line{'0'} ne 'name'; 
$outcome    = 0 if %line{'1'} ne 'age'; 

%line       = %($parser.get_line());
$outcome    = 0 if %line{'0'} ne 'Sally'; 
$outcome    = 0 if %line{'1'} ne '21'; 

ok $outcome == 1;
=end comment
