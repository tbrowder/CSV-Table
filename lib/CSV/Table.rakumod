unit class CSV::Table;

use Text::Utils :strip-comment, :normalize-text;

has $.csv is required;
# options
#   separator
has $.separator    = 'auto'; # auto, comma, pipe, semicolon
#   normalize
has $.normalize    = True;
#   comment-char
has $.comment-char = '#';

# data
# arrays
has @.field; # array of field names
has @.cell;  # array of arrays of row cells

# hashes
has %.col;     # field name => @rows
has %.colnum;  # field name => col number
has %.colname; # col number => field name

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
        next LINE if $line !~~ /\S/; # skip blank lines
        @lines.push: $line;
    }

    # determine the separator
    $header = @lines.shift;

    if $!separator ~~ /:i auto / {
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
                $V = $v;
            }
        }
        $!separator = $C;
        $schar = $C;
    }

    note "DEBUG: sepchar = $!separator" if 0 or $debug;
    # process the header and lines now that we know the separator
    my @arr = $header.split(/$schar/);
    my $nfields = @arr.elems; 
    # $nfields number controls the rest of the data handling.
    # it is a fatal error if a line has more columns. lines
    # with fewer columns are filled with empty cells.
                      
    # for now we always normalize headers
    for @arr.kv -> $i, $v is copy {
        $v = normalize-text $v;
        @!field.push: $v;

        if %!col{$v}:exists {
            die "FATAL: Duplicate field names are illegal: $v";
        }
        else {
            %!col{$v}     = [];
            %!colnum{$v}  = $i;
            %!colname{$i} = $v;
        }
    }

    for @lines.kv -> $line-num, $line {
        @arr = $line.split(/$schar/);
        my $ne = @arr.elems;

        for @arr.kv -> $i, $v is copy {
            if $!normalize {
                @arr[$i] = normalize-text $v;
            }

            # how should %!cell be structured?
            # field name is %!colname{$i}
            my $fnam = %!colname{$i};
            #:%!col{$i}{$fnam} = $v;
            # TODO push the col vals to the correct $!col
        }
        @!cell.push: @arr;
    }
}

=begin comment
method save(:$force) {
    # the file is at $!csv
    my $res = prompt "Save file '$!csv'? (Y/n) ";
    if $res ~~ /:i y/ {
        say "File '$!csv' was saved.";
    }
    else {
        say "File '$!csv' was not overwritten.";
    }
}
=end comment

