[![Actions Status](https://github.com/tbrowder/CSV-Table/actions/workflows/linux.yml/badge.svg)](https://github.com/tbrowder/CSV-Table/actions) [![Actions Status](https://github.com/tbrowder/CSV-Table/actions/workflows/macos.yml/badge.svg)](https://github.com/tbrowder/CSV-Table/actions) [![Actions Status](https://github.com/tbrowder/CSV-Table/actions/workflows/windows.yml/badge.svg)](https://github.com/tbrowder/CSV-Table/actions)

NAME
====

**CSV::Table** - Provides routines for manipulating a CSV file with a header row

SYNOPSIS
========

```raku
use CSV::Table;
my $t = CSV::Table.new: $my-csv;
say $t.fields.elems;
say $t.lines.elems;
for $t.lines.kv -> $i, $line {
    for  $line.fields.kv -> $j, $v {
    };
}
```

DESCRIPTION
===========

**CSV::Table** is a class enabling access to a CSV table as a hash of hashes or an array of arrays.

It includes a very simple CSV file reader and parser. It is intended as a makeshift CSV file reader for use until other available modules can be made to test successfully with **Github workflows** as well as handle:

  * header lines with an ending empty field

  * data lines with trailing whitespace.

  * normalizing field names

As simple as it is, it does have some features that are very useful:

  * Comment lines are allowed

    This feature, which is not usual in CSV parsers, is to ignore comment lines which may have leading whitespace, but it and data at or after a comment character are ignored so the line is treated as a blank line. The comment character is user-definable but must not conflict with the chosen field separator.

  * Text normalization

    Its results are to normalize text in a field, that is: leading and trailing whitespace is trimmed and interior whitespace is collapsed to one space between words. This is the default behavior but can be turned off if desired (`normalize=False`).

  * Automatic determination of separator character

    The header line is searched for the most-used separator character from this list: `|`, `;`, `,`. Other non-space characters may be used but are probably not tested. File an issue if you want to use a separator not currently specified.

Limitations
-----------

It cannot handle:

  * files without a header line (results are untested)

  * special characters

  * backslashes

  * non-text data

  * quoted words

  * named line endings

  * multi-line fields

Constructor signature
---------------------

    CSV::Table.new: $csv-file-name, :separator='auto', :normalize=True, :comment-char='#')

Following are the allowable values for the named arguments. The user is cautioned that unspecified values are probably not tested. File an issue if your value of choice is not specified, and it can be added and tested for.

  * `:$separator`

    * auto [default]

    * comma (`,`)

    * pipe (`|`)

    * semicolon (`;`)

  * `:$normalize`

    * `True` [default]

    * `False`

  * `:$comment-char`

    * `#` [default]

    * others, including multiple characters, are possible

AUTHOR
======

Tom Browder <tbrowder@acm.org>

COPYRIGHT AND LICENSE
=====================

© 2024 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

