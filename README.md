[![Actions Status](https://github.com/tbrowder/CSV-Table/actions/workflows/linux.yml/badge.svg)](https://github.com/tbrowder/CSV-Table/actions) [![Actions Status](https://github.com/tbrowder/CSV-Table/actions/workflows/macos.yml/badge.svg)](https://github.com/tbrowder/CSV-Table/actions) [![Actions Status](https://github.com/tbrowder/CSV-Table/actions/workflows/windows.yml/badge.svg)](https://github.com/tbrowder/CSV-Table/actions)

NAME
====

**CSV::Table** - Provides routines for querying a CSV file with a header row

SYNOPSIS
========

```raku
use CSV::Table;
my $t = CSV::Table.new: :csv($my-csv-file);
say $t.num-fields;
say $t.num-data-row;
```

DESCRIPTION
===========

**CSV::Table** is a class enabling access to a CSV table's contents. Currently it handles only tables with a header row with unique field names. 

By default, the contents of all unquoted text is 'normalized', that is, it is trimmed of leading and trailing whitespace and multiple contiguous interior whitespaces are collapsed into single ones.

Quote characters must be balanced, and quoted text may be normalzed if the user so desires. The following table shows the recognized quote pairs.

<table class="pod-table">
<thead><tr>
<th>Left quote</th> <th>Right quote</th>
</tr></thead>
<tbody>
<tr> <td>U+0022 (&#x0022;)</td> <td>U+0022 (&#x0022;)</td> </tr> <tr> <td>U+0027 (&#x0027;)</td> <td>U+0027 (&#x0027;)</td> </tr> <tr> <td>U+2018 (&#x2018;)</td> <td>U+2019 (&#x2019;)</td> </tr> <tr> <td>U+201C (&#x201C;)</td> <td>U+201D (&#x201D;)</td> </tr>
</tbody>
</table>

<table class="pod-table">
<thead><tr>
<th>Unicode hex code</th> <th>Unicode name</th>
</tr></thead>
<tbody>
<tr> <td>U+0022</td> <td>QUOTATION MARK</td> </tr> <tr> <td>U+0027</td> <td>APOSTROPHE</td> </tr> <tr> <td>U+2018</td> <td>LEFT SINGLE QUOTATION MARK</td> </tr> <tr> <td>U+2019</td> <td>RIGHT SINGLE QUOTATION MARK</td> </tr> <tr> <td>U+201C</td> <td>LEFT DOUBLE QUOTATION MARK</td> </tr> <tr> <td>U+201D</td> <td>RIGHT DOUBLE QUOTATION MARK</td> </tr>
</tbody>
</table>

NOTE: Newlines are **not** currently handled. 

It includes a very simple CSV file reader and parser. It is intended as a makeshift CSV file reader for use until other available modules can be made to test successfully with **Github workflows** as well as handle:

  * header lines with an ending empty field

  * data lines with trailing whitespace.

  * normalizing field names

This class **CAN** handle those successfully.

As simple as it is, it also has some features that are very useful:

  * Comment lines are allowed

    This feature, which is not usual in CSV parsers, is to ignore comment lines which may have leading whitespace, but it and data at or after a comment character are ignored so the line is treated as a blank line. The comment character is user-definable but must not conflict with the chosen field separator.

  * Text normalization

    Its results are to normalize text in a field, that is: leading and trailing whitespace is trimmed and interior whitespace is collapsed to one space between words. This is the default behavior but can be turned off if desired (`normalize=False`).

  * Automatic determination of separator character

    The header line is searched for the most-used separator character from this list: `|`, `;`, and `,`. Other non-space characters may be used but are probably not tested. File an issue if you want to use a separator not currently specified.

Limitations
-----------

It cannot currently handle:

  * files without a header line (results are untested)

  * special characters

  * backslashes

  * non-text data

  * named line endings

  * multi-line fields (i.e., embedded newlines)

  * duplicate field names

Constructor signature
---------------------

    CSV::Table.new: :$csv, :separator='auto', :trim=True, :normalize=True, :comment-char='#'

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

