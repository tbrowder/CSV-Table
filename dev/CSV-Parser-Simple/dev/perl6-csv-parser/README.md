NAME
====

`CSV::Parser` - parses binary CSV file and reads it line by line.

SYNOPSIS
========

This module is pretty powerful. It reads CSV files line by line and can handle individual lines so you can handle your own file reads or you can let it do the work for you. It handles binary files with relative ease so you can parse your binary 'Comma Separated Value' files like a pro.

```raku
use CSV::Parser;

my $file_handle = open 'some.csv', :r;
my $parser = CSV::Parser.new(
    :$file_handle,
    :contains_header_row,
);

# Option 1
until $file_handle.eof {
  my %data = %($parser.get_line());
  # do something here with your hashish data
}

$parser.reset;

# Option 2
my %data;
while %data = %($parser.get_line()) {
  # do something with data here
}

$file_handle.close; # don't forget to close
```

INSTALLATION
============

```console
$ zef install CSV::Parser
```

METHODS
=======

method new
----------

```raku
method new(
    IO::Handle :$file_handle,
    IO::Path   :$file_name,
    Bool       :$binary,
    Bool       :$contains_header_row,
               :$field_separator,
               :$line_separator,
               :$field_operator,
               :$escape_operator,
               :$strip,
    int        :$chunk_size,
)
```

Constructs a CSV parser and sets its attributes to the provided options.

### `file_handle`

File handle opened with [`read`](https://docs.raku.org/routine/read).

### `file_name`

File name to be opened with [`read`](https://docs.raku.org/routine/read).

Notes:

  * This value will be ignored if `file_handle` is entered.

  * This value **is required** if `strip` is `True`.

### `binary`

  * Default: `False`

  * Type: `Bool`

Indicates if file was opened in binary mode. If `True`, the file was opened as binary and all operator/separator options are **REQUIRED** to be passed as `Buf` objects (instead of `Str`).

### `contains_header_row`

  * Default: `False`

  * Type: `Bool`

Indicates if the first line should be interpreted as column names. If `False`, the first line won't be interpreted as column names but will be treated as a normal data line. 

If `True`, the first line will be interpreted as column names, and **each subsequent line** will be treated as a normal data line.

See method `get_line` for details.

### `field_normalizer`

  * Default: `-> $k, $v, :$header = False { $v }`.

  * Type: `Callable`

A `Callable` with signature `($key, $value, :$header = False)` to normalize the key-value pair for each CSV row (whether data only or both). The `$key` is the header value if available, otherwise the column index. The `$value` is the value of the column. The `$header` boolean flag indicates whether we want to modify any existing header. The return value is the column's final value, i.e., a `Str`. For example:

    my $p = CSV::Parser.new(
        file_handle         => $fh,
        contains_header_row => True,
        field_normalizer => 
            -> $k, $v, :$header = False { # don't modify header
                $header ?? $v       # leave header as is
                        !! $v.=trim # modify data fields
        }
    );

### `field_separator`

  * Default: `,`

  * Type: `Str` or `Buf`

Specifies a single-character string used as the the column separator for each row.

### `line_separator`

  * Default: `\n`

  * Type: `Str`

Specifies the separator between CSV rows. See `field_separator` - this will be included in a parsed value if found in an open `field_operator`.

### `field_operator`

  * Default: `"`

  * Type: `Str`

Specifies the character [sequence] used to escape a field (can handle `line_separator` encapsulation). See `field_separator`.

### `escape_operator`

  * Default: `\\`

  * Type: `Str`

Specifies the single-character string used to escape strings in a CSV row. See `field_separator`.

### `chunk_size`

  * Default: `1024`

  * Type: `Int`

Specifies how many bytes to read from the file handle. It can be increased to improve performance if you are parsing some huge lined binary file. 1024 should be sufficient.

### `strip`

With a `file_name` input, uses `Text::Utils.strip-comments` to remove comments and blank lines before processing the CSV lines.

method headers(:$list)
----------------------

This method is functional when `contains_header_row` is `True`.

The method will return parsed headers when they are available (after the first `get_line` call). It returns the parsed headers as a hash keyed by column numbers (0..X-1) and column (field) names as values. If `$list` is defined, the headers will be returned as a list of column names in order of appearance.

method get_line
---------------

```raku
method get_line()
```

Reads a line or chunk from a file and return the parsed line. If this is the first call to this function and `contains_header_row` is set, then this will parse the first two rows (lines) and use the first row's values as the column (field) names.

method parse
------------

```raku
method parse($line, :$header = False) returns Hash
```

Parses a `Str` or `Buf` in accordance with the options set in `new`. Set the `binary` flag in `new` if you are going to pass a `Buf`.

method reset
------------

```raku
method reset()
```

Closes and re-opens the file handle provided in `new`.

AUTHOR
======

tony-o [https://github.com/tony-o/](https://github.com/tony-o/)

COPYRIGHT AND LICENSE
=====================

Copyright 2023 tony-o

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

