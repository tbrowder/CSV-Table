unit class CSV::Table;

use JSON::Fast;
use YAMLish;
use Text::Utils :strip-comment, :normalize-string, :count-substrs;

has $.csv; #is required;

# the default strings:
# YAML
constant $yaml = q:to/HERE/;
separator:        auto # auto, comma, pipe, semicolon, tab
trim:             true
normalize:        true
comment-char:     '#'
has-header:       true
line-ending:      '\n'
raw-ending:       -raw
empty-cell-value: ""
has-row-names:    false
HERE

# JSON
constant $json = q:to/HERE/;
{
"separator":        "auto",
"trim":             true,
"normalize":        true,
"comment-char":     '#',
"has-header":       true,
"line-ending":      '\n',
"raw-ending":       "-raw",
"empty-cell-value": "",
"has-row-names":    false
}
HERE

# 10 options
has      $.separator is rw  = 'auto'; # auto, comma, pipe, semicolon, tab
has Bool $.trim             = True;
has Bool $.normalize        = True;
has      $.comment-char     = '#';
has Bool $.has-header       = True;
has      $.line-ending      = "\n";
has      $.raw-ending is rw = "-raw";
has      $.empty-cell-value = "";
has Bool $.has-row-names    = False;
has      $.config; # JSON file name; empty unless using it;
                   # if used, contents take precedence over
                   # other entries
# end options

has $.ulname; # "corner" cell contents when header and row names are used
has $.raw-csv;

# data
# arrays
has @.field;   # array of field names (or 0..N-1 if no header)
has @.cell;    # array of arrays of row cells (aka "row"); data
has @.rowname; # array of row names, if $has-row-names

# hashes
has %.col;     # field name => slice of that col from @rows
has %.colnum;  # field name => col number
has %.coltag;  # col number => field name

has %.row;     # row name   => an element of @rows
has %.rownum;  # row name   => row number
has %.rowtag;  # row number => row name

has %.comment; # @lines index number (includes any header) => Comment

# other
has @.col-width;     # max col width in number of characters (.chars)
                     # includes any header row
has $.rowname-width; # max rowname width in number of characters (.chars)
                 # (if $!has-row-names)

class Comment {
    has $.inline   = 0;  # inline after the comment char
    has @.trailing = []; # one or more comment-only lines
}

class Line {
    # holds the data from processing a header or data line
    has $.rname is rw; # if $!has-row-names
    has $.rwid  is rw; # if $!has-row-names

    has @.arr is rw;       # does NOT include the row name cell
    has @.col-width is rw; # does NOT include row name cell
}

submethod TWEAK() {
    $!rowname-width = 0;
    my $debug = 0;

    # Read any config file
    if $!config.defined and $!config.IO.r {
        my $typ = get-config-ftype $!config;
        my $str = slurp $!config;
        my %h;
        if $typ ~~ /:i json/ {
            %h = from-json $str;
        }
        elsif $typ ~~ /:i yaml/ {
            %h = load-yaml $str;
        }
        else {
            die "FATAL: Unknown config file type.";
        }
        # fill in new values
        for %h.kv -> $k, $v {
            with $k {
                when /separator/          { $!separator        = $v }
                  #  = 'auto'; # auto, comma, pipe, semicolon, tab
                when /trim/               { $!trim             = $v } # = True;
                when /normalize/          { $!normalize        = $v } # = True;
                when /comment\-char/      { $!comment-char     = $v } # = '#';
                when /has\-header/        { $!has-header       = $v } # = True;
                when /line\-ending/       { $!line-ending      = $v } # = "\n";
                when /raw\-ending/        { $!raw-ending       = $v } # = "-raw";
                when /empty\-cell\-value/ { $!empty-cell-value = $v } # = "";
                when /has\-row\-names/    { $!has-row-names    = $v } # = "";
                # config not expected, but
                when /config/             { ; }
            }
        }
    }

    if not $!csv.defined {
        # allow the method write-config to be called without an object
        return;
    }

    # The input file is $!csv; save its contents
    # without comments as "{$!csv.basename}-raw.csv"
    #   has $.raw-ending   = "-raw";
    $!raw-csv = $!csv; # put in same dir.IO.basename;
    $!raw-csv ~~ s/:i '.csv'//;
    $!raw-csv = $!raw-csv ~ $!raw-ending ~ '.csv';

    # read the csv file and strip and collect comments
    # Get the raw lines while collecting some info

    my $header;
    my @lines;

    note "DEBUG: separator = $!separator" if $debug;

    my @nseps; # keep track of number of separators per line
    my $maxseps = 0;

    my $cchar = $!comment-char;

    my $fh = open $!csv, :r, :nl-in($!line-ending);
    LINE: for $fh.lines -> $line is copy {
        note "DEBUG: line = $line" if $debug;
        my $comment;

        # do NOT normalize in this step
        ($line, $comment) = strip-comment $line, :normalize(False), :mark($cchar),
                                                 :save-comment;
        # Comment lines:
        # Save the line and retain its postion for reassembly.
        # We use the %!comment hash with a key as the index number
        # of the current last line in the @lines
        # array (or -1 if this is a beginning comment). Use a Comment

        # object to save data.

        # Note we could have a line with just one or more comment chars and
        # there also may be whitespace
        my ($c, $idx);

        if $line ~~ /\S/ {
            @lines.push: $line;
            # count sepchars
            my $ns = count-substrs @lines.tail, $!separator;
            @nseps.push: $ns;
            $maxseps = $ns if $ns > $maxseps;
        }

        if $comment.defined and $comment ~~ /\S/ {
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
    } # end of file read loop
    $fh.close;

    # sanity check
    if @nseps.elems != @lines.elems {
        die "FATAL: \@nseps.elems ({@nseps.elems}) != \@lines.elems ({@lines.elems})";
    }
    if not @nseps.elems {
        die "FATAL: \@nseps.elems are zero";
    }
    if not @lines.elems {
        die "FATAL: \@lines.elems are zero";
    }

    # process any header and lines now that we know the separator

    # handle any leading comments occuring before the first data or header line
    if %!comment<-1>:exists {
        #die "tom, fix this";
    }

    my $nfields = 0;
    my $ncols   = 0;
    my $row; # holds a Line object

    # tweak some settings: trim and normalize
    if not $!trim {
        $!normalize = False;
    }

    if $!has-header {
        # TODO handle row names
        if not @lines.elems {
            die "FATAL: Unexpected empty \@lines array, file '$!csv'";
        }
        $header = @lines.shift;
        $row = process-header $header, :separator($!separator),
                              :has-row-names($!has-row-names),
                              :normalize($!normalize), :trim($!trim);
        if $!has-row-names {
            # assign row name data
            $!ulname = $row.rname;
            if $row.rwid > $!rowname-width {
                $!rowname-width = $row.rwid:
            }
        }

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
        #   %!coltag;  # col number => field name
        for @!field.kv -> $i, $nam {
            %!col{$nam} = []; # array of colunm values
            %!colnum{$nam} = $i;
            %!coltag{$i}   = $nam;
        }
    }
    else {
        $nfields = $maxseps + 1;
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
        $row = process-line $line, :separator($!separator), :$line-num,
                                   :has-row-names($!has-row-names),
                                   :has-header($!has-header), :$nfields,
                                   :empty-cell-value($!empty-cell-value),
                                   :normalize($!normalize), :trim($!trim);

        if $!has-row-names {
            # assign row name data
            if $row.rwid > $!rowname-width {
                $!rowname-width = $row.rwid:
            }
            @!rowname.push: $row.rname;

            # don't forget the cross-reference data
            #note "DEBUG: Tom, fix this";
            # has %.row;     # row name   => an element of @rows
            # has %.rownum;  # row name   => row number ($line-number)
            # has %.rowtag;  # row number => row name
            %!row{$row.rname}    = $line-num;
            %!rownum{$row.rname} = $line-num;
            %!rowtag{$line-num}  = $row.rname;
        }

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

            # don't forget the cross-reference data
            my $nam = %!coltag{$i};
            %!col{$nam}.push: $s;
        }
    }
}

method slice2d(Range $rows, Range $cols --> Array) {
    # thanks @librasteve
    self.slice: $rows, $cols
}
method view(Range $rows, Range $cols --> Array) {
    # thanks @librasteve
    self.slice: $rows, $cols
}
method slice(Range $rows, Range $cols --> Array) {
    my $upper-row = $rows.head;
    my $lower-row = $rows.tail;
    my $left-col  = $cols.head;
    my $right-col = $cols.tail;
    my $err = 0;
    # report out of bounds
    if $upper-row < 0 {
        ++$err;
    }
    elsif $left-col < 0 {
        ++$err;
    }
    elsif $lower-row > self.rows - 1 {
        ++$err;
    }
    elsif $right-col > self.cols - 1 {
        ++$err;
    }

    if $err {
        my $s = $err > 1 ?? "s" !! "";
        die "FATAL: Method .slice exceeded $err array bound$s."
    }

    my @arr;
    for $upper-row .. $lower-row -> $i {
        my @cells;
        for $left-col .. $right-col -> $j {
            @cells.push: @!cell[$i][$j];
        }
        @arr.push: @cells;
    }
    @arr
}

method save($stem? is copy, :$force) {
    # defining $stem is a file rename
    my ($csv, $raw);
    if $stem.defined {
        $stem ~~ s/:i '.' csv $//;
        $csv = $stem ~ '.csv';
        $raw = $stem ~ $.raw-ending ~ '.csv';
    }
    else {
        # default
        $csv  = $!csv;
        $raw  = $!raw-csv;
    }

    my $wraw = $force ?? True !! False;
    my $wcsv = $force ?? True !! False;

    if not $force and $raw.IO.e {
        say "File '$raw' exists.";
        my $res = prompt "Overwrite file '$raw'? (Y/n) ";
        if $res ~~ /:i y/ {
            $wraw = True;
            say "Overwriting file '$raw'...";
        }
        else {
            say "File '$raw' was not overwritten.";
        }
    }
    if not $force and $csv.IO.e {
        say "File '$csv' exists.";
        my $res = prompt "Overwrite file '$csv'? (Y/n) ";
        if $res ~~ /:i y/ {
            $wcsv = True;
            say "Overwriting file '$csv'...";
        }
        else {
            say "File '$csv' was not overwritten.";
        }
    }

    if $wraw {
        my $fh = open $raw, :w, :nl-out($!line-ending);
        # Use proper sepchar, respect max col width # with sprintf
        my $ne = @!col-width.elems;
        if $!has-header {
            for @!field.kv -> $i, $v {
                my $w = @!col-width[$i];
                my $s;
                if $w ~~ Numeric {
                    $s = sprintf "%-*.*s", $w, $w, $v;
                }
                else {
                    $s = sprintf "%s", $v;
                }
                $fh.print(" ") if $i;
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
            my $s;
            if $w ~~ Numeric {
                $s = sprintf "%-*.*s", $w, $w, $v;
            }
            else {
                $s = sprintf "%s", $v;
            }
            $fh.print(" ") if $i;
            if $i < $ne-1 {
                $fh.print: $s;
                $fh.print: $!separator;
            }
            else {
                $fh.say: $s;
            }
        }
        $fh.close;
    }

    =begin comment
    class Comment {
        has $.inline   = 0;  # inline after the comment char
        has @.trailing = []; # one or more comment-only lines
    }
    has %.comment; # @lines index number (includes any header) => Comment
    =end comment

    if $wcsv {
        # Add back the stripped comments
        my $fh = open $csv, :w, :nl-out($!line-ending);
        # Use proper sepchar, respect max col width # with sprintf
        my $ne = @!col-width.elems;

        my $lnum = -1;
        my $c = %!comment{$lnum}:exists ?? %!comment{$lnum} !! 0;
        # print any leading comments
        if $c {
            # sanity check: there should be NO inline comment
            die "FATAL: Unexpected error: please file an issue" if $c.inline;
            for $c.trailing {
                $fh.say: $_;
            }
        }

        if $!has-header {

            ++$lnum; # set to first line number
            my $c = %!comment{$lnum}:exists ?? %!comment{$lnum} !! 0;

            for @!field.kv -> $i, $v {
                my $w = @!col-width[$i];
                my $s = sprintf "%-*.*s", $w, $w, $v;
                $fh.print(" ") if $i;
                if $i < $ne-1 {
                    $fh.print: $s;
                    $fh.print: $!separator;
                }
                else {
                    # print the last field plus any inline comment
                    if $c and $c.inline {
                        $fh.print: $s;
                        $fh.say:   $c.inline;
                    }
                    else {
                        $fh.say: $s;
                    }
                }
            }
            # print any trailing comments
            if $c and $c.trailing.elems {
                for $c.trailing {
                    $fh.say: $_;
                }
            }
        }

        for @!cell.kv -> $i, $v is copy {
            #if $v.WHAT ~~ Array {
            if $v ~~ Array {
                $v = $v.head;
                #note "DEBUG2: \$v.head: '$v'";
            }
            #elsif $v.WHAT ~~ Str {
            elsif $v ~~ Str {
                #note "DEBUG2: \$v: '$v'";
            }
            else {
                die "FATAL: Unexpected type or value for \$v";
                #note "DEBUG: \$v.WHAT: ", $v.WHAT;
                #note "DEBUG: ", $v.gist;
            }

            ++$lnum;
            my $c = %!comment{$lnum}:exists ?? %!comment{$lnum} !! 0;

            my $w = @!col-width[$i];
            my $s;
            if $w ~~ Numeric {
                $s = sprintf "%-*.*s", $w, $w, $v;
            }
            else {
                $s = sprintf "%s", $v;
            }

            $fh.print(" ") if $i;
            if $i < $ne-1 {
                $fh.print: $s;
                $fh.print: $!separator;
            }
            else {
                # print the last field plus any inline comment
                if $c and $c.inline {
                    $fh.print: $s;
                    $fh.say:   $c.inline;
                }
                else {
                    $fh.say: $s;
                }
            }
            # print any trailing comments
            if $c and $c.trailing.elems {
                for $c.trailing {
                    $fh.say: $_;
                }
            }
        }
        $fh.close;
    }
}

method shape(:$show) {
    # shows: num rows, num cols
    if $show {
        return "{self.rows}x{self.cols}"
    }
    self.rows, self.cols
}

multi method rowcol(Int $r, Int $c) {
    @!cell[$r][$c];
}
multi method rowcol(Int $r, Int $c, $val) {
    @!cell[$r][$c] = $val;
}

multi method rowcol(Str $r, Str $c) {
    my $a = %!rownum{$r};
    my $b = %!colnum{$c};
    @!cell[$a][$b];
}
multi method rowcol(Str $r, Str $c, $val) {
    my $a = %!rownum{$r};
    my $b = %!colnum{$c};
    @!cell[$a][$b] = $val;
}

multi method rc(Int $r, Int $c) { self.rowcol($r, $c) }
multi method ij(Int $r, Int $c) { self.rowcol($r, $c) }

multi method colrow(Int $c, Int $r) { self.rowcol($r, $c) }
multi method cr(Int $c, Int $r) { self.rowcol($r, $c) }
multi method ji(Int $c, Int $r) { self.rowcol($r, $c) }

# convenience methods
method fields  { @!field.elems     }
method rows    { @!cell.elems      }
method cols    { @!cell.head.elems }
method columns { @!cell.head.elems }

sub get-config-ftype($config) is export(:get-config-ftype) {
    # current choice is yaml or json
    my $s = $config.IO.lines.head;

    if $s ~~ /^ \s* '{'/ {
        return "json";
    }

    for $config.IO.lines -> $line is copy {
        $line = strip-comment $line;
        next if $line !~~ /\S/;
        return "yamlyml" if $line ~~ /\s* <-[:]>+ ':' <-[:]>+ $/;
    }
    "unknown"
}

method !process-header(
    # don't need $!attr values because this is a method used by TWEAK
    $header,
    :$debug,
    --> Line
    ) {
} # method !process-header

method !process-line(
    # don't need $!attr values because this is a method used by TWEAK
    $line,
    :$debug,
    #--> Line
    ) {
} # method !process-line

sub process-header(
     # must pass $!attr values because this sub is called by TWEAK
     $header,
     :$separator!,
Bool :$normalize!,
Bool :$trim!,
     :$debug,
Bool :$has-row-names!,
     --> Line
) {
    my @arr = $header.split(/$separator/);
    my $o = Line.new;

    # fields are cleaned
    # empty cells fire an exception
    # column widths are initialized
    # assign data to:
    #   @!field and @!col-width

    if $has-row-names {
        my $v = @arr.shift;
        if $normalize {
            # includes trimming
            $v = normalize-string $v;
        }
        elsif $trim {
            # trim only
            $v .= trim;
        }
        else {
            ; # no-op, keep the original data
        }
        $o.rname = $v;
        $o.rwid  = $v.chars;
    }

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
            # includes trimming
            $v = normalize-string $v;
        }
        elsif $trim {
            # trim only
            $v .= trim;
        }
        else {
            ; # no-op, keep the original data
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
                 They will be deleted may affect data rows.
        HERE
        my @tmp = $o.arr;
        $o.arr = [];
        CELL: for @tmp -> $v {
            if $v ~~ /\S/ {
                $o.arr.push: $v;
            }
            else {
                last CELL;
            }
        }
    }

    # the Line object
    $o;

} # sub process-header

sub process-line(
     # must pass $!attr values because this sub is called by TWEAK
     $line,
     :$line-num!,
     :$separator!,
Bool :$has-header!, # is this needed here? YES
     :$nfields!,
Bool :$normalize!,
Bool :$has-row-names!,
     :$empty-cell-value!,
Bool :$trim!,
     :$debug,
     --> Line
) {
    my @arr = $line.split(/$separator/);
    my $o = Line.new;

    if $has-row-names {
        my $v = @arr.shift;
        if $normalize {
            # includes trimming
            $v = normalize-string $v;
        }
        elsif $trim {
            # trim only
            $v .= trim;
        }
        else {
            ; # no-op, keep the original data
        }
        $o.rname = $v;
        $o.rwid  = $v.chars;
    }

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
            # includes trimming
            $v = normalize-string $v;
        }
        elsif $trim {
            # trim only
            $v .= trim;
        }
        else {
            ; # no-op, keep the original data
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
            die qq:to/HERE/;
            FATAL: Data row with index $line-num has more cells ({$o.arr.elems}) than
                   the header row which has only $nfields.
            HERE
        }
        elsif $o.arr.elems < $nfields {
            while $o.arr.elems < $nfields {
                $o.arr.push: $empty-cell-value;
            }
        }
    }
    else {
        # pad to max ncols
        while $o.arr.elems < $nfields {
            $o.arr.push: $empty-cell-value;
        }
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
    # if $C is empty, assume sepchar is ',' (comma)
    $C = $C ~~ /\S/ ?? $C !! ',';;

} # sub get-sepchar

#enum CT is export(:CT) ( yaml=>0, yam=>1, ya=>2, y=>3, yml=>4, ym=>5, json=>6, jso=>7, js=>8, j=>9 );
subset CT of Any is export(:CT) where { $_ ~~ /^ :i [0|yaml|yam|ya|y|yml|ym|json|jso|js|j]  /};
method write-config(
    $f? is copy, # the suffix must be one of: .json, .yml, or .yaml
 CT :$type is copy = 0,
    :$force,
    :$quiet,
) {

    $type = Nil if $type eq "0";
    #note "DEBUG: type = '$type'" if $type.defined;

    # the default config file type is YAML
    my $ftype = "YAML";
    my $fsuff = ".yml";

    my $ostr  = $yaml;
    my ($wyaml, $wjson);

    with $type {
        # fatal if $f is defined
        if $f.defined {
            die q:to/HERE/;
            FATAL: Both \$f and \$type are defined!
            HERE
        }

        when $_ ~~ /^ :i [json|jso|js|j]/ {
            $wjson = $json;
            $fsuff = "json";
            $ftype = "JSON";
            $ostr  = $json;
        }
        when $_ ~~ /^ :i [yaml|yam|ya|y|yml|ym]/ {
            $wyaml = $yaml;
            $fsuff = "yml";
            $ftype = "YAML";
            $ostr  = $yaml;
        }
    }

    if $f.defined {
        if $f ~~ /'.' (\S+) $/ {
            my $suf = ~$0.lc;
            if $suf eq "yml" {
                $f = "config-csv-table.yml";
            }
            elsif $suf eq "yaml" {
                $f = "config-csv-table.yaml";
            }
            elsif $suf eq "json" {
                $f = "config-csv-table.json";
            }
            else {
                die qq:to/HERE/;
                FATAL: Input config file name is '$f' with unknown suffix of '.$suf'.
                       The suffix must be one of: .json, .yml, or .yaml";
                HERE
            }
        }
    }
    elsif $wjson.defined {
        $f = "config-csv-table.json";
    }
    elsif $wyaml.defined {
        $f = "config-csv-table.yml";
    }
    else {
        # default
        #die "FATAL: Unexpected failure. Please file an issue."
        $f = "config-csv-table.yml";
    }

    if $f.defined and $f.IO.e and $f.IO.r {
        if $force.defined {
            $f.IO.spurt: $ostr;
        }
        else {
            say "File $f exists. Use the 'force' option to over-write it.";
            exit; # return;
        }
    }
    else {
        $f.IO.spurt: $ostr;
    }
    say "See CSV::Table $ftype configuration file '$f'";
}
