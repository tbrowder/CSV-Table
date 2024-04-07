unit class CSV::Table;

use Text::Utils :normalize-text, :count-substrs;

has $.csv is required;

# options
has $.separator    = 'auto'; # auto, comma, pipe, semicolon, tab
has $.trim         = True;
has $.normalize    = True;
has $.comment-char = '#';
has $.has-header   = True;
has $.line-ending  = "\n";
has $.raw-ending   = "-raw";

# data
# arrays
has @.field; # array of field names (or 0..N-1 if no header)
has @.cell;  # array of arrays of row cells (aka "row")

# hashes
has %.col;     # field name => @rows
has %.colnum;  # field name => col number
has %.colname; # col number => field name
has %.comment; # @lines index number 
has $.changed = False;

# other
has @.col-width; # max col width in number of characters (.chars)
                 # includes any header row

class Line {
    # holds the data from processing a header or data line
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

    note "DEBUG: separator = $!separator" if $debug;

    my @nseps; # keep track of number of separators per line
    my $cchar = $!comment-char;

    LINE: for $!csv.IO.lines -> $line is copy {
        note "DEBUG: line = $line" if $debug;
        if $line ~~ /^ \h* $cchar / {
            # Save the line and retain its postion for reassembly.
            # We use the %!comment hash with a key as the index number 
            # of the current last line in the @lines
            # array (or -1 if this is a beginning comment). Use an array as
            # value to enable handling multiple, contiguous comment lines.
            my $idx = @lines.elems ?? (@lines.elems - 1) !! -1;
            if %!comment{$idx}:exists {
                %!comment{$idx}.push: $line;
            }
            else {
                %!comment{$idx} = [];
                %!comment{$idx}.push: $line;
            }
            next LINE;
        }
        @lines.push: $line;
        if @lines.elems == 1 {
            # determine the separator
            if $!separator ~~ /:i auto / {
                my $line = @lines.head;
                $!separator = get-sepchar $line;
            }
            note "DEBUG: sepchar = $!separator" if 0 or $debug;
        }
        # count sepchars
        my $ns = count-substrs @lines.tail, $!separator;
        @nseps.push: $ns;
    }
    # sanity check
    if @nseps.elems != @lines.elems {
        die "FATAL: \@nseps.elems ({@nseps.elems}) != \@lines.elems ({@lines.elems})";
    }

    # process any header and lines now that we know the separator
    my $nfields = 0;
    my $ncols   = 0;
    my $row; # holds a Line object
    if $!has-header {
        $header = @lines.shift;
        $row = process-header $header, :separator($!separator),
                              :normalize($!normalize), :trim($!trim);
        # fields are cleaned, trailing empty cells are removed
        #   (but reported) and column widths are initialized
        # assign data to:
        #   @!field and @!col-width
        @!field      = $row.arr;
        @!col-width  = $row.col-width;

        $nfields     = $row.arr.elems;
        $ncols       = $nfields;
    }

    # The $nfields number controls the rest of the data handling depending
    # on whether we have a header or not. It will be adjusted to omit
    # any trailing empty cells if it is a header.

    # With header:
    #   Any contiguous empty cells at the end of a header are reported but ignored.
    #   Lines with fewer columns are filled with empty cells.
    #   It is a fatal error if a line has more columns that the header.

    # Without header
    #   All lines are adjusted to have the max number of columns found.
    #   @!fields and associated data are undefined, empty, or zero.

    # the rest of the data lines
    for @lines.kv -> $line-num, $line {
        $row = process-line $line, :separator($!separator),
                                   :has-header($!has-header), :$nfields,
                                   :normalize($!normalize), :trim($!trim);

        # assign data to:
        #   @!cell and @!col-width
        @!cell.push: $row.arr;
        for @!col-width.kv -> $i, $w {
            my $s = $row.arr[$i] // "";
	    my $rw = 0;
	    if $s ~~ /\S/ {
	        $rw = $s.chars;
	    }
            if $rw > $w {
                @!col-width[$i] = $rw;
            }
        }

        =begin comment
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
        =end comment
    }

    =begin comment
    # correct the table if no header row
    if not $!has-header {
        # Move all header data to the first data row (cell) and empty the field
        # data.
    }
    =end comment
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
        # TODO check effects for regular and non-standard line-ending
        say "Saving file '$raw-csv'...";
        my $fh = open $raw-csv, :w, :nl-out($!line-ending);
        # Use proper sepchar, respect max col width # with sprintf
        my $ne = @!col-width.elems;
        if $!has-header {
            for @!field.kv -> $i, $v {
                my $w = @!col-width[$i];
                my $s = sprintf "%*.*s", $w, $w, $v;
                if $i < $ne-1 {
                    $fh.print: $s;
                    $fh.print: $!separator;
                }
                else {
                    $fh.say: $s;
                }
            }
        }
        for @!cell.kv -> $i, $v {
            my $w = @!col-width[$i];
            my $s = sprintf "%*.*s", $w, $w, $v;
            if $i < $ne-1 {
                $fh.print: $s;
                $fh.print: $!separator;
            }
            else {
                $fh.say: $s;
            }
        }
    }
}

multi method rowcol($r, $c) { 
    @!cell[$r][$c];
}
multi method rowcol($r, $c, $val) { 
    @!cell[$r][$c] = $val;
}

method rc($r, $c) { self.rowcol($r, $c) }
method ij($r, $c) { self.rowcol($r, $c) }

method colrow($c, $r) { self.rowcol($r, $c) }
method cr($c, $r) { self.rowcol($r, $c) }
method ji($c, $r) { self.rowcol($r, $c) }

# convenience methods
method fields  { @!field.elems     }
method rows    { @!cell.elems      }
method cols    { @!cell.head.elems }
method columns { @!cell.head.elems }

sub process-header(
    # must pass $!attr values because this sub is called by TWEAK
    $header,
    :$separator!,
    :$normalize!,
    :$trim!,
    :$debug,
    --> Line
) {
    my @arr = $header.split(/$separator/);
    my $o = Line.new;

    # fields are cleaned, trailing empty cells are removed
    #   (but reported) and column widths are initialized
    # assign data to:
    #   @!field and @!col-width

    my %dups;

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

        if $normalize {
            $v = normalize-text $v;
        }
        elsif $trim {
            $v .= trim;
        }

        # track the max column width
        my $w = $v.chars;
        # the first entry
        $o.col-width[$i] = $w;

        # check no dups
        if %dups{$v}:exists {
            die "FATAL: Duplicate field names are illegal: $v";
        }

        # save the value
        $o.arr.push: $v;

            #%!col{$v}     = [];
            #%!colnum{$v}  = $i;
            #%!colname{$i} = $v;
    }

    =begin comment
       # analyze the header for trailing empty cells
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
    =end comment
    $o;

} # sub process-header

sub process-line(
    # must pass $!attr values because this sub is called by TWEAK
    $line,
    :$separator!,
    :$has-header!, # is this needed here? YES
    :$nfields!,
    :$normalize!,
    :$trim!,
    :$debug,
    --> Line
) {
    my @arr = $line.split(/$separator/);
    my $o = Line.new;
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

        if $normalize {
            $v = normalize-text $v;
        }
        elsif $trim {
            $v .= trim;
        }

        # track the max column width
        my $w = $v.chars;
        # the first entry
        $o.col-width[$i] = $w;

        # save the value
        $o.arr.push: $v;

            #%!col{$v}     = [];
            #%!colnum{$v}  = $i;
            #%!colname{$i} = $v;
    }

    $o;

} # sub process-line

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
