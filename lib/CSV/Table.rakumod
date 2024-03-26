unit class CSV::Table;

use Text::Utils :strip-comment, :normalize-text;

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
    my $header = 0;
    my @lines;

    LINE: for $!csv.IO.lines -> $line is copy {
        note "DEBUG: line = $line" if $debug;
        $line = strip-comment $line, :mark($cchar);
        next LINE if $line !~~ /\S/; # skip blank lines

        if not ($header and $header.defined) {
            $header = $line;
            if $!separator ~~ /:i auto/ {
                note "DEBUG: separator = $!separator" if $debug;
                my %c;
                # count currently known chars [,;|]
                CHAR: for $header.comb -> $c {
                    # $c must be a currently know sepchar
                    next CHAR unless $c ~~ /<[,;|]>/;
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
        next LINE;
    }

    note "DEBUG: sepchar = $!separator" if 0 or $debug;
    # process the header and lines now that we know the separator
    my @arr = $header.split(/$schar/);
    for @arr.kv -> $i, $v is copy {
        $v = normalize-text $v;
        @!fields-a.push: $v;

        if %!fields-h{$v}:exists {
            die "FATAL: Duplicate field names are illegal: $v";
        }
        else {
            %!fields-h{$i} = $v;
        }
    }

    for @lines.kv -> $line-num, $line {
        @arr = $line.split(/$schar/);
        for @arr.kv -> $i, $v is copy {
            @arr[$i] = normalize-text $v;

            # how should %!lines-h be structured?
            # field name is %!field-h{$i}
            my $fnam = %!fields-h{$i};
            %!lines-h{$i}{$fnam} = $v;
        }
        @!lines-a.push: @arr;
    }
}
