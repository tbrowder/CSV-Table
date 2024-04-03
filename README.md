[![Actions Status](https://github.com/tbrowder/CSV-Table/actions/workflows/linux.yml/badge.svg)](https://github.com/tbrowder/CSV-Table/actions) [![Actions Status](https://github.com/tbrowder/CSV-Table/actions/workflows/macos.yml/badge.svg)](https://github.com/tbrowder/CSV-Table/actions) [![Actions Status](https://github.com/tbrowder/CSV-Table/actions/workflows/windows.yml/badge.svg)](https://github.com/tbrowder/CSV-Table/actions)

NAME
====

**CSV::Table** - Provides routines for querying a CSV file with or without a header row

SYNOPSIS
========

```raku
use CSV::Table;
# Using a 6x4 row/column matrix for data plus a header row
# with indexing from zero
my $t = CSV::Table.new: :csv($my-csv-file);
say $t.fields;       # OUTPUT: 4 # zero if no header row
say $t.rows;         # OUTPUT: 6 # not counting any header row
say $t.cols;         # OUTPUT: 4
say $t.field[0]      # OUTPUT: name # Any if no header row
say $t.cell[0][0]    # OUTPUT: John
say $t.cell[1][0]    # OUTPUT: Sally
```

DESCRIPTION
===========

**CSV::Table** is a class enabling access to a CSV table's contents. Tables with a header row must have unique field names. 

By default, text is 'normalized', that is, it is trimmed of leading and trailing whitespace and multiple contiguous interior whitespaces are collapsed into single ones.

Input files are read immediately, so very large files may overwhelm system resources. 

It can handle the following which other CSV readers may not:

  * with a header line

    * normalizing field names

    * header lines with an ending empty field (reported but otherwise ignored)

    * data lines with fewer fields than a header (missing values assumed to be "")

    * data lines with more fields than its header (fatal, but reported)

  * without a header line

    * data lines are padded with empty fields to the maximum number of fields found in the file

  * either with or without a header line

    * lines with trailing whitespace

As simple as it is, it also has some uncommon features that are very useful:

  * Comment lines are allowed

    This feature, which is not usual in CSV parsers, is to ignore comment lines (which may have leading whitespace), but it and data at or after a comment character are ignored so the line is treated as a blank line. The comment character is user-definable but must not conflict with the chosen field separator.

    There is a `save` method which enables saving a "raw" CSV file without the comments so the file can be used with conventional CSV handlers such as LibreOffice or Excel.

  * Text normalization

    Its results are to normalize text in a field, that is: leading and trailing whitespace is trimmed and interior whitespace is collapsed to one space between words. This is the default behavior but can be turned off if desired (`normalize=False`). In that event, data in all fields are still trimmed of leading and trailing whitespace (unless `trim=False`).

  * Automatic determination of separator character

    Unless the field separator is selected otherwise, the first line is searched for the most-used separator character from this list: `|`, `;`, `,` and `\t`. Other non-space characters may be used but are probably not tested. File an issue if you want to add a separator not currently specified.

Limitations
-----------

It cannot currently handle:

  * special characters

  * backslashes

  * binary data

  * duplicate field names in a header line

Constructor with default options
--------------------------------

    my $t = CSV::Table.new: :$csv, 
                            :has-header=True,
                            :separator='auto', 
                            :normalize=True, 
                            :trim=True, 
                            :comment-char='#', 
                            :line-ending="\n"
                            ;

Following are the allowable values for the named arguments. The user is cautioned that unspecified values are probably not tested. File an issue if your value of choice is not specified and it can be added and tested for.

  * `:$separator`

    * auto [default]

    * comma (`,`)

    * pipe (`|`)

    * semicolon (`;`)

    * tab (`\t`)

  * `:$normalize`

    * `True` [default]

    * `False`

  * `:$trim`

    * `True` [default]

    * `False`

  * `:$comment-char`

    * `#` [default]

    * others, including multiple characters, are possible

  * `:$has-header`

    * `True` [default]

    * `False`

  * `:$line-ending`

    * `"\n"` [default]

    * `String`

Accessing the table
-------------------

The following table shows how to access each cell in a table `$t` with a header row plus `R` rows and `C` columns of data. (In matrix terminology it is an `M x N` rectangular matrix with `M` rows and `N` columns.)

<table class="pod-table">
<tbody>
<tr> <td>$t.field[0]</td> <td>...</td> <td>$t.field[C-1]</td> </tr> <tr> <td>$t.cell[0][0]</td> <td>...</td> <td>$t.cell[0][C-1]</td> </tr> <tr> <td>...</td> <td>...</td> <td>...</td> </tr> <tr> <td>$t.cell[R-1][0]</td> <td>...</td> <td>$t.cell[R-1][C-1]</td> </tr>
</tbody>
</table>

The table's data cells can also be accessed by field name and row number:

    $t.col{$field-name}{$row-number}

AUTHOR
======

Tom Browder <tbrowder@acm.org>

COPYRIGHT AND LICENSE
=====================

© 2024 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

