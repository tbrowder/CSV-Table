use Test;
use CSV::Parser::Simple;

plan 1;
my $f = 't/data/delimiters.csv';
is $f.IO.r, True;

done-testing;

=finish

my $parser  = CSV::Parser.new( file_handle => $fh , contains_header_row => False , field_separator => "||" , field_operator => "''" );
my $keys    = 0;
my %line    = %($parser.get_line());

$outcome = 0 if %line{'0'} ne 'i'; 
$outcome = 0 if %line{'1'} ne 'has'; 
$outcome = 0 if %line{'2'} ne 'headers'; 
$outcome = 0 if %line{'3'} ne 'with'; 
$outcome = 0 if %line{'4'} ne 'a line'; 

%line    = %($parser.get_line());
$outcome = 0 if %line{'0'} ne 'i'; 
$outcome = 0 if %line{'1'} ne 'has'; 
$outcome = 0 if %line{'2'} ne 'headers'; 
$outcome = 0 if %line{'3'} ne 'with'; 
$outcome = 0 if %line{'4'} ne '||'; 


$fh.close;
ok $outcome == 1;
