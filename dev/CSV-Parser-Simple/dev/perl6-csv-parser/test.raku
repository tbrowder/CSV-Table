#!/usr/bin/env raku

use lib <./lib>;
use CSV::Parser;

my $f = "test.csv";
my $fh = open $f, :rw;

my (%hdrs, %data);
my $p = CSV::Parser.new(
    file_handle         => $fh,
    contains_header_row => True,
    field_normalizer => 
        #-> $k, $v is copy, :$header = False { # don't modify header
        -> $k, $v is copy, :$header = True  { # DO modify header
            #$header ?? $v       # leave header as is
            $header ?? $v.=trim  # modify header
                    !! $v.=trim # modify data fields
    }
);

%data = $p.get_line;
%hdrs = $p.headers;
say %hdrs.raku;
say %data.raku;

