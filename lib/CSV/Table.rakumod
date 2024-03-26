unit class CSV::Table;

use Text::Utils :strip-comment, :normalize-text;
use File::Temp;

has $.csv is required;
# options
#   separator
has $.separator = 'auto'; # auto, comma, pipe, semicolon
#   normalize
has $.normalize = True;
#   comment-char
has $.comment-char = '#';

# data
# arrays
has @.fields-a;
has @.lines-a;

# hashes
has %.fields-h;
has %.lines-h;

submethod TWEAK() {
    my $debug = 0;

    die "FATAL: File '$!csv' not found" unless $!csv.IO.r;
    # read the csv file ignoring comments
    my $cchar = $!comment-char;
    my $schar = $!separator;

    # get the raw lines while collecting some info
    my $header;
    my @lines;

    LINE: for $!csv.IO.lines -> $line is copy {
        note "DEBUG: line = $line" if $debug;
        $line = strip-comment $line, :mark($cchar);
        next if $line !~~ /\S/; # skip blank lines

        if not $header.defined {
            $header = $line;
            if $!separator ~~ /:i auto/ {
                note "DEBUG: separator = $!separator" if $debug;
                my %c;
                # count currently known chars [,;|]
                CHAR: for $header.comb -> $c {
                    # $c must be a currently know sepchar
                    next unless $c ~~ /<[,;|]>/;
                    if %c{$c}:exists {
                        %c{$c} += 1;
                    }
                    else {
                        %c{$c} = 1;
                    }
                }
                # use the one most seen
                my ($C, $V) = "", 0;
                for %c.kv -> $c, $v {
                    if $v > $V {
                        $C = $c;
                    }
                }
                $!separator = $C;
                $schar = $C;
            }
            next LINE;
        }
        @lines.push: $line;
    }

    note "DEBUG: sepchar = $!separator" if $debug;
    # process the header and lines now that we know the separator
    my @arr = $header.split(/$schar/);
    for @arr {
        $_ = normalize-text $_;
        @!fields-a.push: $_;
    }
    for @lines -> $line {
        @arr = $line.split(/$schar/);
        for @arr {
            $_ = normalize-text $_;
        }
        @!lines-a.push: @arr;
    }
}
