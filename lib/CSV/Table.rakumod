unit class CSV::Table;

use Text::Utils :strip-comment, :normalize-text, :count-substrs;

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
has %.comment; # @lines index number => Comment

# other
has @.col-width; # max col width in number of characters (.chars)
                 # includes any header row

class Comment {
    has $.comment; # inline
    has @.trailing = []; # one or more comment-only lines
}

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

    my $fh = open $!csv, :r, :nl-in($!line-ending);
    LINE: for $fh.lines -> $line is copy {
        note "DEBUG: line = $line" if $debug;
        my $comment;
        ($line, $comment) = strip-comment $line, :save-comment;
        # Comment lines:
        # Save the line and retain its postion for reassembly.
        # We use the %!comment hash with a key as the index number
        # of the current last line in the @lines
        # array (or -1 if this is a beginning comment). Use an array as
        # value to enable handling multiple, contiguous comment lines.
        # The first array position is reserved for inline trailing
        # comments.
            
        # Note we could have a line with just one or more comment chars and
        # there also may be whitespace
        my ($c, $idx);

        if $line ~~ /\S/ {
            @lines.push: $line;
            # count sepchars
            my $ns = count-substrs @lines.tail, $!separator;
            @nseps.push: $ns;
        }

        if $comment ~~ /\S/ {
            $idx = @lines.elems ?? (@lines.elems - 1) !! -1;
            if %!comment{$idx}:exists {
                %!comment{$idx}.trailing.push: $comment;
            }
            else {
                %!comment{$idx} = Comment.new;
                %!comment{$idx}.trailing.push: $comment;
            }
        }

        if @lines.elems == 1 {
            # determine the separator
            if $!separator ~~ /:i auto / {
                my $line = @lines.head;
                $!separator = get-sepchar $line;
            }
            note "DEBUG: sepchar = $!separator" if 0 or $debug;
        }
    }
    $fh.close;

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

        # assign data to:
        #   %!col;     # field name => @rows
        #   %!colnum;  # field name => col number
        #   %!colname; # col number => field name
        for @!field.kv -> $i, $nam {
            %!col{$nam} = []; # array of colunm values
            %!colnum{$nam} = $i;
            %!colname{$i}  = $nam;
        }

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
        #   %!col;     # field name => @rows
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

            # don't forget the data hash
            my $nam = %!colname{$i};
            %!col{$nam}.push: $s;
        }
    }
}

method save {
    # The input file is $!csv; save its contents
    # without comments as "{$!csv.basename}-raw.csv"
    #   has $.raw-ending   = "-raw";
    my $raw-csv = "{$!csv.basename}";
    $raw-csv ~~ s/'.csv'//;
    $raw-csv = $raw-csv ~ $!raw-ending ~ '.csv';

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

method !process-header(
    # must pass $!attr values because this sub is called by TWEAK
    $header,
    #:$separator!,
    #:$normalize!,
    #:$trim!,
    :$debug,
    --> Line
    ) {
} # method !process-header

method !process-line(
    # uses $!attr values
    $line,
    #:$separator!,
    #:$has-header!, # is this needed here? YES
    #:$nfields!,
    #:$normalize!,
    #:$trim!,
    :$debug,
    #--> Line
    ) {
} # method !process-line

sub process-header(
    # must pass $!attr values because this sub is called by TWEAK
    $header,
    :$separator!,
    :$normalize!,
    :$trim!,
    :$debug,
    #--> Line
) {
    my @arr = $header.split(/$separator/);
    my $o = Line.new;

    # fields are cleaned
    # empty cells fire an exception
    # column widths are initialized
    # assign data to:
    #   @!field and @!col-width

    my %field; # name => index
    my %dups;  # name => [] # list of indices

    my @ei;  # indices of empty cells
    my @res; # results
    my @ri;  # indices of @res
    for @arr.kv -> $i, $v is copy {
        # track empty cells
        if $v !~~ /\S/ {
            @res.push: 'empty';
            @ei.push: $i;
            @ri.push: $i;
        }
        else {
            @res.push: 'ok';
            @ri.push: $i;
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
        if %field{$v}:exists {
            if %dups{$v}:exist {
                %dups{$v}.push: $i;
            }
            else {
                %dups{$v} = [];
                %dups{$v}.push: $i;
            }
        }
        else {
            %field{$v} = $i;
        }

        # save the value
        $o.arr.push: $v;
    }

    # now check for dups
    if %dups.elems {
        note "FATAL: Duplicate field names are illegal:";
        for %dups.keys -> $f {
            print "  name: $f; at indices:";
            my @a = @(%dups{$f});
            for @a.kv -> $i, $v {
                print "," if $i;
                print " $v";
            }
            note();
        }
        exit;
    }

    my $empty-cells = @ei.elems;
    my $num-cells   = @res.elems;

    # analyze the header for trailing empty cells
    my @c = @res.reverse;
    my @empty;
    my @name;
    for @c.kv -> $i, $v {
        # $v is "empty" or "ok"
        if $v ~~ /empty/ {
            @empty.push: $i;
            if @name.elems {
                note qq:to/HERE/;
                FATAL: field index $i is empty and precedes
                HERE
            }
        }
        else {
            @name.push: $i;
        }
    }

    # if we get here, any empty cells are trailing
    my $ne = @empty.elems;
    if $ne {
        note qq:to/HERE/;
        WARNING: The header row has $ne trailing empty cells.
                 They will be deleted and 
        HERE
    }

    # the Line object
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
    my @res; # results (empty or ok)
    for @arr.kv -> $i, $v is copy {
        # track empty cells
        if $v !~~ /\S/ {
            @res.push: 'empty';
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
    }
    my $empty-cells = @ei.elems;
    my $num-cells   = @res.elems;

    if $has-header {
        if $o.arr.elems > $nfields {
            # 
        }
        elsif $o.arr.elems < $nfields {
        }
    }
    else {
    }

    # the Line object
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
    # the most used sepchar
    $C
}
