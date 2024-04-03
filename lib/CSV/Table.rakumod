unit class CSV::Table;

use Text::Utils :strip-comment, :normalize-text;

has $.csv is required;

# options
has $.separator    = 'auto'; # auto, comma, pipe, semicolon, tab
has $.trim         = True;
has $.normalize    = True;
has $.comment-char = '#';
has $.has-header   = True;
has $.line-ending  = "\n";

# data
# arrays
has @.field; # array of field names (or 0..N-1 if no header)
has @.cell;  # array of arrays of row cells

# hashes
has %.col;     # field name => @rows
has %.colnum;  # field name => col number
has %.colname; # col number => field name

# other
has @.col-width; # max col width in number of characters (.chars)
                 # includes any header row

class Line {
    # holds the data from processing a line
    has $.is-header = False; 
    has $.line is required;
    has @.arr is rw;
    has @.col-width is rw;
}

submethod TWEAK() {

    my $debug = 0;

    die "FATAL: File '$!csv' not found" unless $!csv.IO.r;
    # read the csv file ignoring comments

    # Get the raw lines while collecting some info

    my $header;
    my @lines;

    # convenience
    my $cchar = $!comment-char;
    my $schar = $!separator;
    note "DEBUG: separator = $!separator" if $debug;

    LINE: for $!csv.IO.lines -> $line is copy {
        note "DEBUG: line = $line" if $debug;
        $line = strip-comment $line, :mark($cchar);
        next LINE if $line !~~ /\S/; # skip blank lines
        @lines.push: $line;
    }

    # determine the separator
    if $!separator ~~ /:i auto / {
        my $line = @lines.head;
        $!separator = get-sepchar $line;
    }

    note "DEBUG: sepchar = $!separator" if 0 or $debug;

    # process any header and lines now that we know the separator
    my $nfields = 0; 
    my $ncols   = 0;
    my @arr;
    if $!has-header {
        $header = @lines.shift;
        @arr = process-header $header, :separator($!separator);
        $nfields = @arr.elems;
        $ncols   = $nfields;
        # fields are cleaned, trailing empty cells are removed
        #   (but reported) and column widths are initialized
        # assign data to:
        #   @!fields and @!col-width
    }

    # The $nfields number controls the rest of the data handling depending
    # on whether we have a header or not. It will be adjusted to omit
    # any trailing empty cells if it is a header.

    # With header:
    #   It is a fatal error if a line has more columns that the header.
    #   Any contiguous empty cells at the end of a header are reported but ignored.
    #   Lines with fewer columns are filled with empty cells.

    # Without header
    #   All lines are adjusted to have the max number of columns found.
    #   @!fields and associated data are undefined, empty, or zero.

    =begin comment
    my @ei;  # indices of empty cells
    my @res; # results
    for @arr.kv -> $i, $v is copy {
        # track empty cells
        if $v !~~ /\S/ {
            @res.push: $i;
            @ei.push: $i;
        }
        else {
            @res.push: 'ok';
        }

        if $!normalize {
            $v = normalize-text $v;
        }
        elsif $!trim {
            $v .= trim;
        }

        # track the max column width
        my $w = $v.chars;
        # the first entry
        @!col-width[$i] = $w;

        # save the value
        @!field.push: $v;

        if $!has-header and %!col{$v}:exists {
            die "FATAL: Duplicate field names are illegal: $v";
        }
        else {
            %!col{$v}     = [];
            %!colnum{$v}  = $i;
            %!colname{$i} = $v;
        }
    }

    # analyze the header for trailing empty cells
    if $!has-header {
        my @c = @ei.reverse;
        my @empty;
        for @c -> $i, $v {
        }

        =begin comment
        # fix this
        if $ne {
            note qq:to/HERE/;
            WARNING: The header row has $ne empty cells.
            HERE
        }
        =end comment
    }
    =end comment

    # the rest of the data lines
    for @lines.kv -> $line-num, $line {
        @arr = $line.split(/$schar/);
        my $ne = @arr.elems;

        for @arr.kv -> $i, $v is copy {
            if $!normalize {
                $v = normalize-text $v;
            }
            elsif $!trim {
                $v .= trim;
            }
            else {
                ; # ok
            }
            $v = "" if $v !~~ /\S/;
            @arr[$i] = $v;

            my $w  = $v.comb.elems;
            my $cw = @!col-width[$i] // 0;
            @!col-width[$i] = $w if $w > $cw;

            next if not $!has-header;

            =begin comment
            # hashes
            has %.col;     # field name => @rows
            has %.colnum;  # field name => col number
            has %.colname; # col number => field name
            =end comment
            # how should %!col be structured?
            # field name is %!colname{$i}
            my $fnam = %!colname{$i} // "";
            my $fidx = %!colnum{$i} // -1;
            if %!col{$fnam}:exists {
                %!col{$fnam}.push: $v;
            }
            else {
                %!col{$fnam} = [];
                %!col{$fnam}.push: $v;
            }
        }
        @!cell.push: @arr;
    }

    # correct the table if no header row
    if not $!has-header {
        # Move all header data to the first data row (cell) and empty the field
        # data.
    }
}

method save {
    # The input file is $!csv; save its contents
    # without comments as "{$!csv.basename}-raw.csv"
    my $raw-csv = "{$!csv.basename}-raw.csv";
    my $res;
    if $raw-csv.IO.e {
        say "File '$raw-csv' exists.";
        $res = prompt "Overwrite file '$raw-csv'? (Y/n) ";
        if $res ~~ /:i y/ {
            say "Overwriting file '$raw-csv'...";
        }
        else {
            say "File '$!csv' was not overwritten.";
        }
    }
    else {
        say "Saving file '$raw-csv'...";
        # Use proper sepchar, respect max col width
        # with sprintf
        say "File '$!csv' was not overwritten.";
    }
}

# convenience methods
method fields  { @!field.elems     }
method rows    { @!cell.elems      }
method cols    { @!cell.head.elems }
method columns { @!cell.head.elems }

sub process-header(
    # must pass $!attr values because this sub is called by TWEAK
    $header,
    :$separator!,
    :$debug,
    --> Array
) {
    my @arr = $header.split(/$separator/);
    @arr
}

sub get-sepchar($header, :$debug) {

    my %c;
    # count currently known chars [,;|\t]
    CHAR: for $header.comb -> $c {
        # $c must be a currently known sepchar
        next CHAR unless $c ~~ /<[,;|\t]>/;
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
    $C
}
