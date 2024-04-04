#!/usr/bin/env raku

#my $csv = "../t/data/line-enders.csv";
my $csv = "line-enders.csv"; # a local copy of the above
my $line-ending = '||';

my $chomp = True;
my $fh = open $csv, :nl-in($line-ending);
for $fh.lines -> $line is copy {
   #$line ~~ s:g/\s**2/ /;
   #$line .= trim;
   # specifically remove newlines at the beginning and end
   $line ~~ s/\n+$//;
   $line ~~ s/^\n+//;
   say "'$line'";
}
$fh.close;

# try to duplicate the csv file in this directory
my $f = "dup-line-enders.csv";
my $fh2 = open $f, :w, :nl-out($line-ending);

$fh = open $csv, :nl-in($line-ending);
for $fh.lines -> $line is copy {
   # specifically remove newlines at the beginning and end
   $line ~~ s/\n+$//;
   $line ~~ s/^\n+//;
   #say "'$line'";
   $fh2.say: $line;
}
say "See file '$f' (copy of file '$csv')";


