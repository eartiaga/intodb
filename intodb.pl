#!/usr/bin/perl

use strict;
use warnings;

my $MAJOR   = 0;
my $MINOR   = 101;
my $RELEASE = 13;

my $VERSION = sprintf "%s.%s.%s", $MAJOR, $MINOR, $RELEASE;
my $VERSION_STRING = "IntoDB $VERSION";
my $DBVERSION = sprintf "%s.%s", $MAJOR, $MINOR;

=head1 NAME

intodb - benchmark-agnostic data storage and visualization

=head1 SYNOPSIS

intodb.pl [options] <command> <command_args> [-- <env_var_settings>]

=head1 DESCRIPTION

Intodb.pl provides a mechanism for storing benchmark results and
generating graphs from the data. Data is stored in a SQLite database
and, currently, graphs are generated using the jgraph tool
(http://www.cs.utk.edu/~plank/plank/jgraph/jgraph.html).

=head1 USAGE

=head2 Overview

The overall syntax consists of the name of the script (C<intodb.pl>), followed
by global options (if any), then a command, and possibly some command
arguments. Additionally, it is possible to overwrite settings for environment
variables after a double dash (C<-->) at the end of the command. So, the
following syntax:

  intodb.pl [options] <command args> -- VAR1=VALUE1 VAR2=VALUE2

is roughly equivalent to

  VAR1=VALUE1 VAR2=VALUE2 intodb.pl [options] <command args>

The following are the recognized global options (which must appear
before the command name:

=over

=item -rc=FILE

The name of the configuration file. Note that this file is loaded after the
default configuration file (C<$HOME/.intodbrc>), unless the C<-nostdrc> option
is used. Any settings in the default configuration file can be override in the
file specified with this option.
See the C<CONFIGURATION FILE> section below for more details.

=item -nostdrc

Do not load the default configuration file (C<$HOME/.intodbrc>).
See the C<CONFIGURATION FILE> section below for more details.

=item -db=FILE

The name of the database file (C<./BenchDB.db>, if not specified)).

=item -tmpdir=DIR

Name of the directory for temporary data. If not set, the value
of the C<TMPDIR> env variable is used. If this is not set, the default
settings for the system are used.

=item -sep=STR

A string to be used as separator for CSV files (colon C<:> by default).

=item -progress={dots|pct}

Default text-based progress indicator.

=item -chunk=INT

Size of transaction chunk to load csv lines into the database (1 by default).
Note that a larger chunk makes load faster, but the input file position
indicator may be less reliable in case of failure.

=item -v

Increases the verbosity level.

=back

You may use the command C<commands> to obtain a list of the available commands,
and the command C<help> to obtain a short description of each of them. A
slightly more detailed description appears in the
C<DETAILED COMMAND DESCRIPTION> in this documentation.

=head2 Creating the Database

The database is created using the command C<create>. The file name is
C<BenchDB.db> in the current directory (unless otherwise specified using
the C<-db> option). To remove the database, simply delete the file.

Note that C<intodb.pl> refuses to re-create an existing database: you have
to explicitly remove the old file before.

=head2 Configuring a Benchmark

Prior to introducing data, at least one benchmark must be defined (you
may have data from several benchmarks in the same database - even if
the utility of that is limited to very specific cases: a single benchmark
per database is the recommended way to use intodb).

A benchmark has a C<name>, possibly a C<description>, and a list of
C<fields>. Additionally, some of the C<fields> form an experiment C<key>:
i.e. their values form a unique key to distinguish experiment repetitions.

You may create a benchmark and set a description with the following commands:

 intodb.pl new IOR
 intodb.pl description IOR "Interleaved or Random I/O Benchmark"

Entering an empty string as C<description> ("") removes the description.
A benchmark can be renamed with C<rename>:

  intodb.pl rename OLD_NAME NEW_NAME

And deleted with C<remove>

  intodb.pl remove BENCH_NAME

(Note that to remove a benchmark, the database cannot contain any data
associated to it, and all the fields must have been removed).

Benchmark C<fields> can be either introduced manually or imported from a CSV
file. Field names are case insensitive, and can contain alphanumeric
characters and the underscore C<_> (any other character will be converted
to an underscore C<_>).

To manually use a new field use the C<new_field> command:

  intodb.pl new_field IOR SYSTEM

The field can be removed with

  intodb.pl remove_field IOR SYSTEM

All fields in a benchmark can be removed at once using:

  intodb.pl remove_all_fields IOR

As mentioned above, fields can also be imported from a CSV file. The file is
assumed to have the field names in the first line, and at least one
data line):

  intodb.pl load_fields IOR ./my_csv_file_with_ior_data.txt

There are two different types of fields: C<numeric> and C<text>. The type
affect how the values are ordered and the aggregation operations that can
be done on them (e.g. it may have little sense to compute an "average" of
text values). The default type when fields are created manually is
C<text>; when imported from a file, it is guessed from the first data line.
If the default value is wrong, it can be changed with the C<field_type>
command:

  intodb.pl field_type BENCH_NAME FIELD_NAME numeric

or

  intodb.pl field_type BENCH_NAME FIELD_NAME text

The last task to do is to identify the fields that form an experiment key.
Use the C<set_key> command for this:

  intodb.pl set_key IOR OPERATION true
  intodb.pl set_key IOR ITERATION true
  intodb.pl set_key IOR FS true
  ...

Of course, you may remove the C<key> status of a field passing a
C<false> parameter:

  intodb.pl set_key IOR BANDWIDTH false

If your data does not contain any unique identifier, intodb may generate
one for you. You only have to create an additional C<field>, and pass it
to the C<-autoid> option in the C<parse> command when importing data; then,
intodb will generate an unique id for each line in the input CSV file.

CAVEAT: it is not possible to change the benchmark definition (including
fields, their types and the key) once there is data in the database. The
only possible modification consists of adding a new non-key field with
a default value, using C<add_field>:

  intodb.pl add_field BENCHMARK_NAME FIELD_NAME {text|numeric} VALUE

The benchmark definition can be seen with the command C<details>:

  intodb.pl details ior

will show something like:

  IOR - Interleaved or Random I/O Benchmark
  Field list:
    (txt) ACCESS
    (num) AGGREGATE
    (txt) API
    (num) BANDWIDTH
    (num) BLOCK
    (num) BLOCKSIZE
    (num) CHUNK
    (num) CLOSE_TIME
    (num) DSIZE
    (txt) ENDDATE
    (txt) EXTRA
    (txt) FS
    (num) FSYNC
    (txt) ID
    (num) ITERATION
    (txt) MODE
    (num) NODES
    (num) NPROC
    (num) NSEGM
    (num) ODIRECT
    (num) OPEN_TIME
    (txt) OPERATION
    (txt) ORDERING
    (num) RANDOM
    (num) RDWR_TIME
    (num) REORDER
    (num) REPEAT
    (num) SSIZE
    (txt) STARTDATE
    (txt) SYSTEM
    (num) UNIQUE
    (txt) UNIT
    (num) XFERSIZE
  Experiment keys:
    EXTRA, FS, ID, ITERATION, OPERATION, SYSTEM
  Data rows:
    0

=head2 Importing Data

Intodb takes the input from a CSV file. The file is assumed to have a
header with the field names in the first line. The command to import data
is C<parse>:

  intodb.pl parse BENCHMARK_NAME ./file_with_data.txt

In order to generate a unique id for each line in the file, the
C<-autoid> option may be used:

  intodb.pl parse BENCHMARK_NAME ./file_with_data.txt -autoid=SOME_FIELD

Finally, if some fields are missing from the CSV file, they can be added
at the end using the following syntax:

  intodb.pl parse BENCHMARK_NAME ./file_with_data.txt FIELD=VALUE ...

It is possible to remove all data corresponding to a benchmark using:

  intodb.pl remove_all_data BENCHMARK_NAME

In order to remove some experiments only, the command C<remove_experiment>
can be used. It comes in two flavors:

  intodb.pl remove_experiment BENCHMARK_NAME id1 id2 ...

removes the experiments having the specified identifiers, while:

  intodb.pl remove_experiment BENCHMARK_NAME FIELDNAME=value ...

removes the experiments satisfying *all* the specified conditions, where
a C<condition> consists of a field name, an operator (which may be one of
C<E<lt>>, C<E<gt>>, C<E<lt>=>, C<E<gt>=>, C<=>, C<E<lt>E<gt>>,
C<~> (like) and C<!~> (not like)),
and a value. There must be no blank spaces around the operator (if the value
needs blanks, surround the expression in quotes - this is may also be
necessary for operators containing C<E<lt>>, C<E<gt>>, C<~> or C<!>).

=head2 Accessing the Data

Once imported into the database, data can be queried using SQL syntax. The
table name to use is the benchmark name followed by the suffix C<_VIEW>.
Columns are the field names with an underscore C<_> prepended to them.
Additionally, three columns are automatically added: C<EXP>, C<OUT>, C<BENCH>
(with no underscore prepended). C<EXP> is a unique identifier for the
experiment information, C<OUT> can be C<0> or C<1> and indicates if the
experiment has been marked as an outlier and, finally, C<BENCH> is an
internal identifier for the benchmark.

An outlier can be marked using the C<set_outlier> command:

  intodb.pl set_outlier BENCHMARK_NAME EXP_ID true

or

  intodb.pl set_outlier BENCHMARK_NAME EXP_ID false

(where EXP_ID is content of the C<EXP> column of the experiment).

The command for issuing an sql command is C<sql>. Note that only selects
are allowed on benchmark tables:

  intodb.pl sql select distinct _dsize from ior_view where out = 0

   _dsize
   ------------
   1048576
   262144
   4194304
   524288

For convenience (to avoid conflicts with shell expansions), the asterisk
C<*> used to represent all fields can be omitted. Therefore, the following
expressions are equivalent:

  intodb.pl sql select count from ior_view

  intodb.pl sql select count(\*) from ior_view

=head2 Plotting the Data

Intodb is able to generate a C<jgraph> script from the data in the database
using a graph description file (its syntax is described in the
C<GRAPH DESCRIPTION FILE> section below).

The command to generate the jgraph code is C<graph>:

  intodb.pl graph ./graph_description_file.gdt > plot.jgr

A postscript file can then be obtained by using the C<jgraph> tool

  jgraph plot.jgr > plot.eps

  jgraph -P plot.jgr > plot.ps

=head1 DETAILED COMMAND DESCRIPTION

=head2 Database and benchmark handling

=over

=item add_field

Syntax:

  intodb.pl add_field <bench> <field> {text|numeric} <val>

Adds a new field to a benchmark which (possibly) has data already loaded.
A default value must be provided to fill the new column for the already
existing database rows. C<bench> is the benchmark name, and C<field> is the
new field name. Field names must contain alphanumeric characters and
underscores (C<_>) only, and cannot start with a digit.

The new field cannot be used as an experiment key (unless all data from
benchmark is removed).

Note that this is not intended for regular use: benchmark structure should
be defined before loading data into them.

=item create

Syntax:

  intodb.pl create

Creates a new database file and initializes it with the proper schema.
Unless specified with C<--db>, the default name for the database is
C<BenchDB.db>.

Note that there is no command to destroy the database. If needed, you may
simply remove the file.

=item create_index

Syntax:

  intodb.pl create_index <bench> <field> ...

Creates an index in the database based on the given fields. This may be
useful to speed-up some data queries and graph generation for large data
sets. Creating indexes is not recommended unless you experience performance
problems (note that they increase the database file and do not guarantee
performance improvements).

=item description

Syntax:

  intodb.pl description <bench> "<benchmark description>"

Assigns an arbitrary description string to a benchmark name. Assigning an
empty string C<''> removes the previous description.

=item details

Syntax:

  intodb.pl details <bench>

Shows the description of the benchmark named C<bench>, including description,
the list of fields with their types, which fields form a key for an
experiment, and the number of experiment currently loaded on the database.

=item field_type

Syntax:

  intodb.pl field_type <bench> <field> {text|numeric}

Changes the type of a field into C<text> or C<numeric>. This essentially
affects how the values are encoded and sorted. The default type for a newly
created field is C<text>.

=item list

Syntax:

  intodb.pl list

Lists the benchmarks stored in the database.

=item load_fields

Syntax:

  intodb.pl load_fields <bench> <csv_file>

Determines the benchmark fields from the header of a csv file. C<bench> is
the benchmark name, and <csv_file> is a csv-like file where the first line
contain the field names. There must be at least a data line with values, so
that the types of the fields can be inferred from them (the types can be
changed later using the C<field_type> command).

=item remove

Syntax:

  intodb.pl remove <bench>

Removes a benchmark from the database. Note that all data and all fields
must have been manually removed before executing this command (see
C<remove_all_data> and C<remove_all_fields> commands).

=item remove_all_fields

Syntax:

  intodb.pl remove_all_fields <bench>

Removes all fields from the benchmark description. Note that data must have
been cleared with C<remove_all_data> before executing this command.

Removing all the fields implies removing all indexes associated to the
benchmark.

=item remove_index

Syntax:

  intodb.pl remove_index <index_name>

Removes the specified index. The indexes associated to a given
benchmark can be obtained with the C<details> command.

=item remove_field

Syntax:

  intodb.pl remove_field <bench> <field>

Removes the named field from the specified benchmark. Note that fields
cannot be removed if the benchmark contains experiment data.

Any index using this field will also be removed.

=item rename

Syntax:

  intodb.pl rename <bench> <new_bench_name>

Renames the specified benchmark to a new name.

=item dump_schema

Syntax:

  intodb.pl dump_schema [bench ...]

Dumps the benchmark and field descriptions in xml format. If C<bench> is
specified, only the information about the named benchmarks is produced.

=item restore

Syntax:

  intodb.pl restore <xml_file>

Retrieves benchmark and field descriptions, as well as experiment data,
from an xml file generated with the C<dump> command.

=item restore_schema

Syntax:

  intodb.pl restore_schema <xml_file>

Retrieves benchmark and field descriptions from an xml file generated with
the C<dump> or C<dump_schema> commands. Experiment data, if present,
are ignored.

=item set_key

Syntax:

  intodb.pl set_key <bench> <field> {true|false}

Sets or clears the C<key> flag for a benchmark field. An experiment should
be uniquely identified by the values of its C<key> fields. In other words,
IntoDB will skip data from an experiment with the same key as another one
already loaded in the database. This is useful for incremental loading, and
to recover from failures during data import.

In case no actual field combination can be considered a key, IntoDB allows
to specify an extra field which is automatically filled with a unique
identifier (see the C<parse> command and its C<--autoid> option).

=back

=head2 Data handling

=over

=item check_graph

Syntax:

  intodb.pl check_graph <graph_desc_file>

Checks the syntax of a graph description file. Note that the parser may
complain if the graph description file uses settings defined in a
external configuration file (using C<--rc=config_file.cfg> should
avoid this issue).

=item data

Syntax:

  intodb.pl data <graph_desc_file> [var1=val1 ...]

Process a graph description file and generate raw data from it. The
settings in C<var1=...> (if any) override the default values for
environment variables used in the graph description file (see the
C<GRAPH DESCRIPTION FILE> section for further information).

The output format is designed to facilitate its parsing by external
post-processing and plotting tools. It is composed of several columns
separated by colons (:) (though this can be changed via the global option
C<--sep>).  The columns are:

=over

=item the curve identifier

with format C<gXXcYY>, where C<XX> is the graph index, and C<YY> is the
curve index within that graph. If the option C<descriptive_data> is set, the
format is C<TT_LL> where C<TT> is the graph title and C<LL> is the curve
label.

=item the x value

the value for the x axis, as extracted from the database values. Note that
this may not be available depending on the aggregation function. If not
available, the value for the corresponding x coordinate is given instead.

=item the y value

the value for the y axis, as extracted from the database values. Note that
this may not be available depending on the aggregation function. If not
available, the value for the corresponding y coordinate is given instead.

=item the x coordinate

the x coordinate computed for the data point, after the corresponding values
have been processed by the aggregation functions.

=item the y coordinate

the y coordinate computed for the data point, after the corresponding values
have been processed by the aggregation functions.

=item low error

the y coordinate for the low error value (usually the bottom limit for the
confidence interval, depending on the aggregation function).
This is not present if the C<no_error> option is used in the graph.

=item high error

the y coordinate for the high error value (usually the top limit for the
confidence interval, depending on the aggregation function).
This is not present if the C<no_error> option is used in the graph.

=back

Note that even if all options in the graph description files are allowed
for the C<data> command, some of them may pollute the output and mask the
real data (e.g. C<xoffset>, C<yoffset> or C<stack>).

=item dump

Syntax

  intodb.pl dump [bench ...]

Dumps the benchmark description and the associated experiment data in xml
format. If C<bench> is given, only information about the named benchmarks
is produced.

=item export

Syntax:

  intodb.pl export <bench>

Dumps the data corresponding to the specified benchmark using a csv-like
format. The output contains the fields defined for the benchmarks, preceded
by an underscore (C<_>) and two additional fields: C<EXP> (the internal
experiment identifier) and C<OUT> (the outlier mark for the experiment).

The default separator is the colon (C<:>), but it can be changed using
the C<--sep> global option.

=item graph

Syntax:

  intodb.pl data <graph_desc_file> [var1=val1 ...]

Process a graph description file and generate a jgraph script from it. The
settings in C<var1=...> (if any) override the default values for
environment variables used in the graph description file (see the
C<GRAPH DESCRIPTION FILE> section for further information).

The output of this command can be fed to the C<jgraph> command to generate
a postscript (.ps) or encapsulated postscript (.eps) file.

=item parse

Syntax:

  intodb.pl parse <bench> <csv_file> [--autoid=field0] [field1=val1 ...]

Parses and imports data corresponding to the specified benchmark from a
csv-like file. This file must contain the field names in its first line.

If specified, the field in the C<--autoid> option will be filled in with
a unique id for each line of the csv file (note that, in this case,
multiple imports of the same file will generate different identifiers and
be considered different experiments). If the C<--autoid> field is also
present in the csv file, the value in the file is ignored.

Additionally, several C<field=value> expressions can be given to supply
fixed values for missing fields in the csv file, or to override values
in the file (if they are present).

Note that for large data sets, the global option C<--chunk> may be used
to speed-up data loading.

=item remove_all_data

Syntax:

  intodb.pl remove_all_data <bench>

Removes all experiment data associated to the given benchmark. The
benchmark description remains in the database.

=item remove_experiment

Syntax:

  intodb.pl remove_experiment <bench> <exp_id> ...
  intodb.pl remove_experiment <bench> <field><op><value> ...

Removes a set of experiments from the specified benchmark. The experiments
can be specified either by their internal identifiers (the C<EXP> column
in the benchmark data view) or via conditions (C<op> may be one of
E<lt>=, E<gt>=, E<lt>, E<gt>, =, !=, ~, !~; all the conditions are AND'ed
to select the experiments to remove).

=item set_outlier

Syntax: 

  intodb.pl set_outlier <bench> <exp_id> {true|false}

Marks a specific experiment as an outlier. By default, outliers are not
shown in graphs.

=item xmlplot

Syntax:

  intodb.pl xmlplot <graph_desc_file> [var1=val1 ...]

Process a graph description file and generate xml data from it. The
settings in C<var1=...> (if any) override the default values for
environment variables used in the graph description file (see the
C<GRAPH DESCRIPTION FILE> section for further information).

The root xml element is called C<intodbplot>. This contains a series of
one or more C<graphset> elements (representing graphs that should be
plotted in the same page.) A graph set then contains a series of
individual C<graph> elements.

Attributes in the C<graph> element indicate its sequence number (C<id>),
and also show the C<newpage> and C<stack> attributes. A graph may contain
a C<title>, the C<xaxis> description, the C<yaxis> description and a
series of C<curve> elements.

Each C<curve> element may contain a C<label> and a series of C<point>
elements. Each point contain information on the C<x> and C<y> coordinates:
the C<coord> attribute indicates the physical coordinate of the point to
be plot, and C<emin> and C<emax>, if present, indicate the lower and higher
bounds for error bars in that dimension. The text content of the C<x> or
C<y> elements contain the symbolic values for x and y (assuming they are
available).

=back

=head2 Sql interface

=over

=item admsql

Syntax:

  intodb.pl admsql "some sql statement"

Allows the execution of C<any> sql command on the internal database (including
dangerous ones). This is intended for maintenance, testing and power-tweaking.
Do not use it unless you really know what you are doing. It may corrupt the
database.

=item sql

Syntax:

  intodb.pl sql "some sql select statement"

allows the execution of sql queries on the internal database. There is
also restricted support for data modification (update and delete), but
despite the restrictions, improper use could end up with data corruption.
So, the recommended use is for select statements, only.

=back

=head2 Miscellaneous

=over

=item commands

Syntax:

  intodb.pl commands

Shows a terse list of available commands

=item gui

Syntax:

  intodb.pl gui

Starts the graphical user interface. Most (but not all) operations from
command line are available from the gui. It is mainly conceived for easily
browsing and exploring the experiments in the database. Despite not being
documented, it should be intuitive enough for brave users.

=item help

Syntax:

  intodb.pl help

Shows basic usage information, including the command list, its arguments
and aliases.

=item license

Syntax:

  intodb.pl license

Shows the license terms.

=item show_config

Syntax:

  intodb.pl show_config

Shows the active configuration. Useful to see the available options for
graph generation, and to verify that non-standard configuration
files are producing the desired effects.

=item version

Syntax:

  intodb.pl version

Shows the version string.

=back

=head1 GRAPH DESCRIPTION FILE

A Graph description file contains different sections with information
to describe draw a graph.

A line ending with a blank space followed by a backslash C<\> as the last
character of the line, is concatenated with the next line, suppressing the
both the blank space and the ending backslash.

A line starting by a hash symbol (C<#>) in the first column of the line,
immediately followed by the INCLUDE word (without any blank spaces between
C<INCLUDE> and the hash symbol C<#>), followed by some spaces and a path
surrounded by double quotes C<">, is an C<include directive>, meaning that
the program will open the specified file and treat it as if it was literally
included in the current file. The path may be absolute, or relative to the
location of the current file. Examples of valid include directives are:

 #INCLUDE "/an/absolute/path/to/a/file"

 #INCLUDE "a/relative/path/to/a/file"

 #INCLUDE "a_file_in_the_same_directory"

Other lines starting by a hash symbol C<#> (or by blank spaces followed by a
hash symbol) are considered as comments and ignored. Emtpy lines or lines
consisting only of blank spaces are also ignored.

A Graph Description File is composed of sections. Each section has a section
C<header> formed by a single line with the section name surrounded by
C<[> and C<]> characters, followed by C<item> lines. The section names are
not case sensitive.

An C<item> line consists of a C<keyword>, followed by a colon C<:>, followed
by some value (with a free or restricted format, depending on the keyword).
Keyword names are not case sensitive, but values may be.
Example:

 title: some nice graph

There are five types of section:

=over

=item [global]

global settings

=item [graph]

parameters affecting a whole graph

=item [bench]

data selection parameters

=item [curve]

curve-specific parameters

=item [end]

marks the end of the processing (it is implicit at the end of file)

=back

Some of the item values may contain environment variables, which
are expanded when the graph is generated. The syntax for such expressions
is:

  @VARNAME

or

  @{VARNAME}

For convenience, intodb.pl allows for locally specifying values for such
variables, declaring them at the end of the command line, following a "--".
For example:

  intodb.pl graph ./file.gdt -- OPERATION=read > plot.jgr

Note that not all items admit environment variables. Next subsections
specify where they can be used.

Additionally, some items may also have C<field> variables. These are
expanded to a specific field contents. The syntax is

 $FIELDNAME

or

 ${FIELDNAME}

Again, only some of the items admit such variables. Next subsections
specify where they can be used.

=head2 The [global] section

A C<Global> section may appear anywhere in the file. If several of them
appear in a file, only the last one has effect. Currently, it is only used
to set default values for environment variables.

The following are the accepted keywords for the C<item> lines:

=over

=item env

A default value for an C<environment> variable. The syntax is:

 env: VARNAME = VALUE

Several C<env> items may appear in a C<global> section.

=item eval

A calculated value for an C<environment> variable. The syntax is:

 eval: VARNAME = EXPRESSION

Variables to be computed from other values are preceded by
a C<&> symbol, instead of an C<@>. The expression can only be set
on the C<global> section and it the expression is evaluated when the
variable is expanded. The C<EXPRESSION> may contain C<environment>
variables defined with C<env> or passed via command line, but cannot
contain other C<calculated> variables.

For example, the definitions

 env: RANGE = 10
 eval: XCATLIST = join(", ",(map {$_ * @RANGE} (0..int(500/@RANGE))))

will generate a comma separated list from 0 to 500 in steps of 10 whenever
the expression &XCATLIST is expanded. This can be used, for example, to
generate automatic labels for a category axis: 

  xtype: category
  xcat: &XCATLIST
  xskip: 9

(will generate labels at 0, 100, 200, 300, 400 and 500, with 9 minor hash
marks between them.)

Several C<eval> items may appear in a C<global> section.

=item func

The body of a perl function to be used in the C<xval>/C<yval> items in the
C<CURVE> section (see below).

The syntax is:

 func: FUNCNAME = FUNCTION_CODE

The function is invoked by using the C<FUNCNAME> preceded by a percent (C<%>)
symbol. Arguments can be passed on invocation by providing a comma-separated
list of arguments enclosed in parenthesis.

No substitution is performed on the C<FUNCTION_CODE>, but expressions composed
of C<environment> variables, C<calculated> variables and/or C<column> variables
can be passed as parameters on invocation.

There is a way to call other functions defined in IntoDB. The global hash
C<%INTODBFUNC> contains pointers to the defined functions, and can be used
to invoke them from within a different definition (recursive calls should
work, but are not supported). For example, a function C<CALL_F1> using function
C<F1> could be written as:

  func: CALL_F1 = \
    my $arg = shift; \
    return &{$INTODBFUNC{"F1"}}($arg);

The C<FUNCTION_CODE> can be multiline, if each line is ended by a blank space
followed by a backslash (C<\>).

For example, a function can be defined to compute the elapsed time in
seconds between two time strings with the format:

 Fri Mar 19 05_29_47 CET 2010

The following definition does the job (assuming the time zone is CET or CEST):

 func: ETIME = \
   my $s = shift; \
   my $e = shift; \
   my %m = (Jan => 0, Feb => 1, Mar => 2, Apr => 3, \
            May => 4, Jun => 5, Jul => 6, Aug => 7, \
            Sep => 8, Oct => 9, Nov => 10, Dec => 11); \
   my %tz = (CET => 2, CEST => 1); \
   my ($ss, $es) = (0, 0); \
   if ($s =~ \
    /^\s*\w+\s+(\w+)\s+(\d+)\s+(\d+)_(\d+)_(\d+)\s+(\w+)\s+(\d+)/) \
   { \
     $ss = Time::Local::timegm($5, $4, $3, $2, $m{$1}, $7 - 1900); \
     $ss += $tz{$6} * 3600; \
   } \
   if ($e =~ \
    /^\s*\w+\s+(\w+)\s+(\d+)\s+(\d+)_(\d+)_(\d+)\s+(\w+)\s+(\d+)/) \
   { \
     $es = Time::Local::timegm($5, $4, $3, $2, $m{$1}, $7 - 1900); \
     $es += $tz{$6} * 3600; \
   } \
   return ($es > $ss)? $es - $ss: 0;

Then, if time values are stored in columns C<STARTDATE> and C<ENDDATE>, the
elapsed time in minutes can be fed to the C<y> value by using:

 yval: "%.2f", (%ETIME(${STARTDATE}, ${ENDDATE})) / 60

The functions should be self-contained (i.e. it is not possible to call a
defined function from a different function).

Several C<func> items may appear in a C<global> section.

=back

=head2 The [graph] section

A C<Graph> section may appear anywhere in the file and it is composed by
the corresponding header C<[graph]>, followed by several C<item> lines.

The following are the accepted keywords for the C<item> lines:

=over

=item Global Settings

=over

=item jgraph

Arbitrary jgraph commands to be applied to the whole graph (free format).

=item size

Default size for the x and y axis. Can be overridden by the C<xsize> and
C<ysize> keywords. If not specified, jgraph defaults are used. Should
be a number (units are inches).

=item font

Default font for the title, axis labels, legend and hash labels. Can
be overridden by more specific keywords (C<title_font>, C<legend_font>,
C<label_font>, C<hash_font>). If not specified, jgraph defaults are used.
Should be a string.

=item fontsize

Default font size for the title, axis labels, legend and hash labels. Can
be overridden by more specific keywords (C<title_fontsize>, C<legend_fontsize>,
C<label_fontsize>, C<hash_fontsize>). If not specified, jgraph defaults are
used. Should be an integer.

=item title

Graph title (an arbitrary string), possibly containing C<environment>
variables.

=item title_font

Font to use for the title. Should be a string.

=item title_fontsize

Font size to use for the title. Should be an integer.

=item legend

Position of the curve legend. It may be either C<none> (no legend is printed)
or one of C<top>, C<bottom>, C<left>, C<right>, C<top_left>, C<top_right>,
C<bottom_left>, C<bottom_right>. Default is C<none>.

=item legend_font

Font to use for the legend. Should be a string.

=item legend_fontsize

Font size to use for the legend. Should be an integer.

=item legend_x

X position in the graph to place the curve legend.

=item legend_y

Y position in the graph to place the curve legend.

=item label_font

Font to use for the axis labels. Should be a string.

=item label_fontsize

Font size to use for the axis labels. Should be an integer.

=item hash_font

Font to use for the hash labels. Should be a string.

=item hash_fontsize

Font size to use for the hash labels. Should be an integer.

=back

=item X Axis Settings

=over

=item xjgraph

Arbitrary jgraph commands to be applied to the X axis (free format).

=item xlabel

X axis title. It is an arbitrary string, possibly containing C<environment>
variables.

=item xtype

X axis type. One of C<category>, C<numeric>, C<log2>, C<log10>.

=item xcat

Comma-separated list of category values to appear in the X axis, in the
same order as they are mean to appear. If necessary, it can be split
into several C<xcat> item lines (the values are concatenated).
First and last occurences of | in the values are used as begin/end 
of string and therefore removed.

The special value C<_> can be used to add extra separation between value
labels.

If not specified, and the axis type is C<category>, an alphabetically
sorted list with all X values is automatically generated.

=item xskip

An integer indicating how many hash labels to skip in a category axis
(a hash label is printed and then C<xskip> labels are skipped).

=item xsize

Size for the X axis. If not specified, jgraph defaults are used. Should
be a number (units are inches).

=item xmin

Minimum value for the X axis. Default is 0. Should be a number.

=item xmax

Maximum value for the X axis. Default is automatically determined.
Should be a number.

=item xbase

Position where the Y axis should be plotted. Defaults to C<xmin>.

=back

=item Y Axis Settings

=over

=item yjgraph

Arbitrary jgraph commands to be applied to the Y axis (free format).

=item ylabel

Y axis title. It is an arbitrary string, possibly containing C<environment>
variables.

=item ytype

Y axis type. One of C<category>, C<numeric>, C<log2>, C<log10>.

=item ycat

Comma-separated list of category values to appear in the Y axis, in the
same order as they are mean to appear. If necessary, it can be split
into several C<ycat> item lines (the values are concatenated).
First and last occurences of | in the values are used as begin/end 
of string and therefore removed.

The special value C<_> can be used to add extra separation between value
labels.

If not specified, and the axis type is C<category>, an alphabetically
sorted list with all Y values is automatically generated.

=item yskip

An integer indicating how many hash labels to skip in a category axis
(a hash label is printed and then C<yskip> labels are skipped).

=item ysize

Size for the Y axis. If not specified, jgraph defaults are used. Should
be a number (units are inches).

=item ymin

Minimum value for the Y axis. Default is 0. Should be a number.

=item ymax

Maximum value for the Y axis. Default is automatically determined.
Should be a number.

=item ybase

Position where the X axis should be plotted. Defaults to C<ymin>.

=item aggr

Aggregation function to be used when there are several Y values
for the same X value in a single curve. If the line type is C<ybar>,
then it is applied to the X values corresponding to the same Y value
in a single curve. Currently supported functions include:

=over

=item none

No grouping (for scatter plots)

=item count

Number of values

=item sum

Sum of all values

=item max

Maximum value

=item min

Minimum value

=item rng

Difference between the maximum and the minimum value

=item avg

Average value

=item median

Value corresponding to the median

=item stdev

Standard deviation

=item cv

Coefficient of variation

=item ci

Average with confidence intervals

=item ci_max

Upper limit of the confidence intervals

=item ci_min

Lower limit of the confidence intervals

=item delta

Delta for confidence interval

=back

=back

=item Other Settings

=over

=item linecycle

Number of curves to repeat a specific line pattern. The count includes curves
not plotted because no data is present, and also those with a forced line type.
This is used to control the automatically generated line patterns
for different curves.

=item markcycle

Number of curves to repeat a specific mark pattern. The count includes curves
not plotted because no data is present, and also those with a forced mark type.
This is used to control the automatically generated mark patterns
for different curves.

=item colorcycle

Number of curves to repeat a specific color or gray level. The count
includes curves not plotted because no data is present, and also those with
a forced color or gray level.
This is used to control the automatically generated colors
for different curves.

=item markscalecycle

There is an obscure feature to automatically change the mark sizes
for each curve. This setting indicates the number of curves to repeat
a specific mark size.

=item options

Switches for specific features. There may be several C<options> item lines
(and their values are grouped). Available options for graph sections include:

=over

=item skip

Do not plot this graph at all.

=item include_outliers

Include data points from experiments marked as outliers (such points are
not plotted by default).

=item stack

Stack curves (i.e. add their values, instead of overlapping them). The
first curve is plotted at the bottom, then the second one is added, and
so on...

=item newpage

Plot this graph in a new page (by default, it is overlapped with the previous
graph)

=item grayscale

Use gray scale instead of colors for plotting the curves.

=item top_axis

Plot the X axis on the top, instead of the bottom (useful when overlapping
graphs with different X scales).

=item right_axis

Plot the Y axis on the right, instead of the left (useful when overlapping
graphs with different Y scales).

=item no_error

Do not draw error intervals.

=item no_xhash

Do not draw hash marks for X axis (useful to avoid some ugly effects when
overlapping graphs).

=item no_xhash_labels

Do not draw hash mark labels for X axis (useful to avoid some ugly effects when
overlapping graphs).

=item no_yhash

Do not draw hash marks for Y axis (useful to avoid some ugly effects when
overlapping graphs).

=item no_yhash_labels

Do not draw hash mark labels for X axis (useful to avoid some ugly effects when
overlapping graphs).

=item xno_min

Do not set automatic minimum axis value for x.

=item yno_min

Do not set automatic minimum axis value for y.

=item xrotate_labels

Rotate 90 degrees the x axis labels

=item yrotate_labels

Rotate 90 degrees the y axis labels

=item xoffset

When drawing vertical bars, shift their x position for different curves,
so that they do not overlap.

=item yoffset

When drawing horizontal bars, shift their y position for different curves,
so that they do not overlap.

=item normalize

Normalize the curve values taking as normalization base the values from the
first curve with the option C<base>. Behavior is not well defined if
no curve has such option, or it misses some values (or the value is 0); so,
be careful.

=item descriptive_data

Use human readable labels for data dumps (see C<data> command). If set, graph
title and curve labels are used; otherwise numeric indexes are used.

=back

=back

=back

=head2 The [bench] section

The C<bench> section defines the benchmark to use to obtain the data points
for the following C<curve> sections, and specifies some conditions on the
selection. It completely substitutes any previous C<bench> section.

A C<bench> section may appear immediately after a C<graph> section, after
another C<bench> section (though this may have little sense) or after a
C<curve> section.

The keywords for a C<bench> section are:

=over

=item name

the name of the benchmark to use.

=item select

An SQL condition to select interesting data points. Fields are expressed
using the C<field variable> syntax (i.e. preceded by a dollar sign C<$>
and possibly surrounded by braces C<{}>).

It is possible to specify several select conditions using different
C<item lines>. They may also contain C<environment> variables.

Note that SQL syntax must be abode; in particular, strings should be
surrounded by single quotes C<'>. For example:

 select: $OPERATION = '@OPERATION'
 select: $ORDERING  = '@{ACCESS}_offsets'
 select: $ACCESS    = '@MODE'
 select: $API       = 'POSIX'
 select: $DSIZE     <> (512 * 1024)
 select: $FS        not like 'ext3'

=back

=head2 The [curve] section

The C<curve> section specifies how to draw the data points using one or more
C<curves>.

A C<curve> section may only appear after a C<bench> section or another
C<curve> section.

The following keywords are recognized:

=over

=item jgraph

Arbitrary string containing jgraph commands for the curve. It may
contain C<environment> variables.

=item label

An arbitrary string to appear in the curve legend. It may contain
both C<environment> variables and C<field> variables.

=item filter

Additional SQL conditions to select data points. It has the same format
as the C<select> keyword in the C<bench> section (in fact, the C<filter>
conditions are added to ones in the C<bench> section for the current curve).

There may be several C<filter> lines.

=item xval

Format of the X value. It is a comma-separated list where the first component
is a control string in the C<printf> style, and the rest are valid perl
expressions possibly containing C<environment> and C<field> variables.

For example:

  xval: "%d MB", (${DSIZE} / 1024)

This is a compulsory item for C<curve> sections.

Note that it is possible to use predefined expressions to clusterize values.
All functors derived from the C<Fn> class (see the methods documentation below)
can be used. For example, to clusterize the C<BANDWIDTH> field in ranges of 10
units, the following keywords can be used in the curve definition:

  xval: "%d", FnCluster0->new(10)->calc(${BANDWIDTH})
  yval: "%f", ${BANDWIDTH}
  aggr: count
  line: xbar

The following functors are available:

=over

=item FnConst->new($value)->($arg);

Always returns C<$value>.

=item FnMap->new($default, {x1 => y1, ...})->calc($arg);

Return C<yi> when C<$arg> is C<xi>; if C<$arg> is not equal to any C<xi>,
then C<$default> is returned.

=item FnEnum->new($first, [x1, ...])->calc($arg);

Return C<$first + i - 1> when C<$arg> is equal to C<xi>.

=item FnEnum0->new([x1, ...])->calc($arg);

Return C<i - 1> when C<$arg> is equal to C<xi>.

=item FnEnum1->new([x1, ...])->calc($arg);

Return C<i> when C<$arg> is equal to C<xi>.

=item FnList->new($first, [x1, ...])->calc($arg);

Return C<xi> when C<$arg> is equal to C<$first + i - 1>.

=item FnList0->new([x1, ...])->calc($arg);

Return C<xi> when C<$arg> is equal to C<i - 1>.

=item FnList1->new([x1, ...])->calc($arg);

Return C<xi> when C<$arg> is equal to C<i>.

=item FnCluster->new($start, $width)->calc($arg);

Return C<i> when C<$arg> is in the range
C<[$start + i * $width, $start + (i + 1) * $width)>.

=item FnCluster0->new($width)->calc($arg);

Return C<i> when C<$arg> is in the range C<[i * $width, (i + 1) * $width)>.

=back

=item yval

Format of the Y value. It is a comma-separated list where the first component
is a control string in the C<printf> style, and the rest are valid perl
expressions possibly containing C<environment> and C<field> variables.

For example:

  yval: "%f", ${BANDWIDTH}

This is a compulsory item for C<curve> sections.

=item aggr

Aggregation function for this curve. It overrides the value in the
C<graph> section.

=item line

Line type for the current curve. If not specified, a default one based on
the C<linecycle> is chosen.

Possible values are: C<none>, C<xbar>, C<xbarval>, C<ybarval>, C<ytext>, 
C<solid>, C<dotted>, C<dashed>, <longdash>, C<dotdash>, C<dotdotdash>, 
C<dotdotdashdash>.

=item mark

Mark type for the current curve. If not specified, a default one based on
the C<markcycle> is chosen.

Possible values are: C<auto>, C<none>,
C<circle>, C<box>, C<diamond>, C<triangle>, C<x>, <cross>, C<ellipse>.

It is possible to set an arbitrary text using the syntax:

  mark: text="some text"

(The text admits C<field> variables).

=item color

Color for the current curve. If not specified, a default one based on
C<colorcycle> is chosen.

Colors can be specified by name, or using the format

  rXXXgYYYbZZZ

where C<XXX>, C<YYY> and C<ZZZ> are values between 0 and 255 indicating the
RGB components of the color. Values can be also expressed in hex notation
using the format:

  rxXXgxYYbxZZ

=item gray

Gray level for the current curve. If not specified, a default one based on
C<colorcycle> is chosen.

The gray level can also be expressed using the format:

  gXXX

where C<XXX> is the white/black component (0 is black, and 255 is white).

=item markscale

Scale factor for the curve marks. Pre-defined values range from 100%
of a C<point> size to 10% of a curve C<point>. If the mark is a text,
then the font size varies from 10pt to 1pt.

Pre-defined values are: C<s100>, C<s90>, ..., C<s10> (representing values
from 100% to 10%). Specific values can be specified using the syntax
C<#size=XXX> (where XXX is the percentage with respect to the curve
default C<point> size. The format C<#size=XXX/YYY> can be used to specify
different percentages for the C<x> and C<y> dimensions).

For textual marks, the definition syntax is C<#size=XX>, where XX is the
desired font size.

Alternatively, names for specific formats can be defined in the
C<CONFIGURATION FILE> using the format C<SSS#size=XXX/YYY> or C<SSS#size=XXX>,
where C<SSS> is an id name for the mark size.

=item iterate

Reuse the same specifications for several curves. The value is a
comma-separated list of C<field> variables. All the value combinations
are computed and a different curve is generated for each of them. Note
that the order of fields affect the order in which curves are generated
(and how color and line cycles affect them).

For example, the following line:

  iterate: $DSIZE, $FS

is roughly equivalent to something like

  for each size in $DSIZE
    for each filesystem in $FS
      draw curve(size, filesystem)
    done
  done

=item options

Switches for specific features. There may be several C<options> item lines
(and their values are grouped). Available options for curve sections include:

=over

=item skip

Skip this curve.

=item no_stack

Do not stack this curve, even if the graph has the C<stack> option set.

=item accum

Accumulate C<y> values across the C<x> axis. Note that results are undefined
when there is more than a single C<y> value (after aggregation) per C<x>
value. Error range printing is also disabled.

This option has no effect for category-type C<y> values, or for curves using
C<ybar> lines.

=item include_outliers

Include data points from experiments marked as outliers (such points are
not plotted by default).

=item exclude_outliers

Do not include data points from experiments marked as outliers. This
overrides the C<include_outliers> option in the C<graph> section.

=item grayscale

Use gray levels for drawing the current curve.

=item color

Force the use of color, overriding the C<grayscale> option in the C<graph>
section.

=item no_error

Do not draw error intervals.

=item error

Draw error intervals, overriding the C<no_error> option in the C<graph>
section.

=item fill

Fill the surface between the curve and the axis with a solid color.

=item base

Use the current curve as a normalization base.

Note that this option may produce unexpected results if the
keyword C<iterate> is set for the same curve, as the data for
the first combination of parameters is taken (even if it
corresponds to an empty data set - leading to wrong normalization.).
So, do not use in C<iterate> curves (you have been warned ;-)

=item markscale

Activates an obscure feature to apply round-robin mark scale modifications
to the current curve.

=back

=back

=head2 The [end] section

The C<end> section finishes the parsing of the graph description file,
even if the end of the file has not been reached.

=head2 Example

The following is an example for a graph description file. Additional
graphs could be specified at the end.


  #
  # Bandwidth vs. processors and nodes
  #
  # Environment variables:
  #   OPERATION {read|write}
  #   ACCESS {sequential|random}
  #   MODE {file_per_process|single_shared_file}
  #

  [global]
  # provide default values for environment variables
  env: OPERATION = read
  env: ACCESS = sequential
  env: MODE = file_per_process

  #############
  # graph
  #############
  [graph]

  title: @ACCESS @OPERATION (@MODE)
  legend: top

  xlabel: nodes and processors
  xtype: category
  xcat: 1-1, 1-2, 4-4, 4-8, 8-8, 8-16, 16-16, 16-32

  ylabel: bandwidth (MB/s)
  ytype: numeric
  ymin: 0
  aggr: ci

  linecycle : 3
  options: newpage
  options: xoffset
  options: grayscale

  #######################
  # curve specification
  #######################
  [bench]
  name: ior
  select: $OPERATION = '@OPERATION'
  select: $ORDERING  = '@{ACCESS}_offsets'
  select: $ACCESS    = '@MODE'
  select: $API       = 'POSIX'
  select: $DSIZE     <> (512 * 1024)
  select: $FS        not like 'ext3'

  [curve]
  label: data size = ${DSIZE}KB, block size = ${XFERSIZE}KB ($FS)
  xval : "%d-%d", $NODES, $NPROC
  yval : "%f", $BANDWIDTH
  iterate: $DSIZE, $FS

  filter: $BLOCKSIZE = 4
  filter: $XFERSIZE  = $BLOCKSIZE


=head1 CONFIGURATION FILE

The configuration file allows redefining and selecting automatic values
for graph drawing. The syntax is based in sections (as in the C<GRAPH
DESCRIPTION FILE>). Available sections are:

=head2 Section [params]

Allows setting default values for some command line parameters

=over

=item chunk

Size of transaction chunk to load csv lines into the database (1 by default).
Note that a larger chunk makes load faster, but the input file position
indicator may be less reliable in case of failure.

The value must be a non-negative integer

=item progress

Default text-based progress indicator for parsing csv files. Possible
values are: C<dotprogress>, C<pctprogress>.

=item separator

A string to be used as separator for CSV files (colon C<:> by default).

=item tmpdir

Name of the directory for temporary data. If not set, the value
of the C<TMPDIR> env variable is used. If this is not set, the default
settings for the system are used.

=back

=head2 Section [helpers]

Allows setting the path for external application helpers. Recognized keywords
in this section include:

=over

=item jgraph

Path to the C<jgraph> application. It is possible to specify several
settings, either separated by comma or in multiple C<jgraph> items in
different lines (the first one found is used).

=item texteditor

Programs (possibly including paths) to be used as text editors. It is
possible to specify several settings, either separated by comma or in
multiple C<texteditor> items in different lines
(the first one found is used).

=item psviewer

Programs (possibly including paths) to be used as postscript viewers.
It is possible to specify several settings, either separated by comma or in
multiple C<texteditor> items in different lines
(the first one found is used).

=back

=head2 Section [progress]

I<Note:> this section is deprecated. Use the C<progress> keyword in the
C<params> section instead.

Allows changing the progress indicators. Recognized keywords are:

=over

=item default

I<Note:> this keyword is deprecated. Use the C<progress> item in the
C<params> section instead.

Default text-based progress indicator for parsing csv files. Possible
values are: C<dotprogress>, C<pctprogress>.

=back

=head2 Section [mark]

Allows changing the automatic mark types for the curve points. Recognized
keywords in this section include:

=over

=item autolist

An ordered, comma-separated list of mark types to use.

=back

=head2 Section [markscale]

Allows defining and changing the scale factor for mark types. Recognized
keywords are:

=over

=item define

A markscale value with the syntax

  SSS#size=XXX

or

  SSS#size=XXX/YYY

where SSS is the name to use, and XXX and YYY are percentage values, as
indicated in the C<GRAPH DESCRIPTION FILE> documentation.

=item autolist

An ordered, comma-separated list of markscale sizes to use.

Note that if the autolist includes names declared via C<define>, they should
also be declared in the C<textmarkscale> section; otherwise, the behavior of
automatic cyclic scaling (C<markscalecycle>) when mixing textual and
non-textual marks is undefined (and not supported). 

=back

=head2 Section [textmarkscale]

Allows defining and changing the scale factor for mark types. Recognized
keywords are:

=over

=item define

A textmarkscale value with the syntax

  SSS#size=XX

where SSS is the name to use and XX is the desired font size for the
text mark, as indicated in the C<GRAPH DESCRIPTION FILE> documentation.

=item autolist

An ordered, comma-separated list of markscale sizes to use.

Note that if the autolist includes names declared via C<define>, they should
also be declared in the C<markscale> section; otherwise, the behavior of
automatic cyclic scaling (C<markscalecycle>) when mixing textual and
non-textual marks is undefined (and not supported). 

=back

=head2 Section [line]

Allows changing the automatic line types for the curves. Recognized
keywords in this section include:

=over

=item autolist

An ordered, comma-separated list of line types to use.

=back

=head2 Section [color]

Allows defining and changing the automatic colors for the curves. Recognized
keywords are:

=over

=item define

A color name (the Graphics::ColorNames module may be required for extra
colors).

=item autolist

An ordered, comma-separated list of colors to use, or an RGB specification
using the format

 rXXXgYYYbZZZ

where the values are between 0 and 255. Alternatively, the hex format can
be used:

 rxXXgxYYbxZZ

=back

=head2 Section [gray]

Allows defining and changing the automatic gray levels for the curves.
Recognized keywords are:

=over

=item define

A gray level name with the syntax:

 gXXX

where XXX is a number between 0 and 255 (0 being black, and 255 being white).

=item autolist

An ordered, comma-separated list of gray levels to use. Pre-defined values
include C<gray0> (black), C<gray1>, ..., C<gray4>. The names C<black>
and C<white> are also allowed.

=back

=head1 BUGS

This script does not do what you want it to do: it simply does what you
tell it to do; some may consider this a bug.

Occasionally, this script may not even do what you tell it to do.
More people would agree on this being a bug.

There are probably several of the latter, so be warned :-)

=head1 AUTHOR

Ernest Artiaga, 2009, 2010

=head1 LICENSE

Copyright (C) 2009-2014  Ernest Artiaga

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

You may also access the full text of the LICENSE at the following URL:

 https://www.gnu.org/licenses/gpl-2.0.html

=cut

my $LICENSE =<<EOT;
Copyright (C) 2009-2014  Ernest Artiaga

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

You may also access the full text of the LICENSE at the following URL:

 https://www.gnu.org/licenses/gpl-2.0.html

EOT

#################################################
#################################################
# MODULES
#################################################
#################################################

=head1 REQUIREMENTS

=over

=cut

use FindBin qw($Bin $Script);

=item use Math::NumberCruncher;

=cut

#use Math::NumberCruncher;
our $HAS_NUMBERCRUNCHER;
BEGIN {eval
  {require Math::NumberCruncher; import Math::NumberCruncher;};
  our $HAS_NUMBERCRUNCHER = $@? 0: 1;
};

=item use Statistics::PointEstimation

  (provided by Statistics-Distributions-1.02.tar.gz and
   Statistics-TTest-1.1.0.tar.gz from CPAN)

=cut

#use Statistics::PointEstimation;
our $HAS_POINTESTIMATION;
BEGIN {eval
  {require Statistics::PointEstimation; import Statistics::PointEstimation;};
  our $HAS_POINTESTIMATION = $@? 0: 1;
};

=item use Graphics::ColorNames

 (only required for increased color support for graphs)

=cut

#use Graphics::ColorNames;
our $HAS_COLORNAMES;
BEGIN {eval
  {require Graphics::ColorNames; import Graphics::ColorNames;};
  our $HAS_COLORNAMES = $@? 0: 1;
};


=item use Gtk2; use Glib;

 (only required for the graphic interface)

=item use Time::Local

 (optional, to define time format conversion functions)

=cut

#use Time::Local
our $HAS_TIMELOCAL;
BEGIN {eval
  {require Time::Local;};
  our $HAS_TIMELOCAL = $@? 0: 1;
};

#use Gtk2 -init;
#use Glib qw(TRUE FALSE);
our $HAS_GTK2;
our ($GTK_TRUE, $GTK_FALSE) = (1, !1);
BEGIN {eval
  {
    require Gtk2;
    require Glib; import GLib qw(TRUE FALSE);
  };
  our $HAS_GTK2 = $@? 0: 1;
};

=item use XML::LibXML;

 (only required for xml dump and dump_schema commands)

=cut

our $HAS_XML;
BEGIN {eval
  {require XML::LibXML;};
  our $HAS_XML = $@? 0: 1;
};

=item use XML::Parser::Expat;

 (only required for restore and restore_schema commands)

=cut

our $HAS_EXPAT;
BEGIN {eval
  {require XML::Parser::Expat;};
  our $HAS_EXPAT = $@? 0: 1;
};

=item use DBI

 (requires SQLite DBD driver)

=cut

use DBI;

=back

=cut


#################################################
#################################################
# ARGUMENTS
#################################################
#################################################
my $STDRCFILE = $ENV{HOME} . "/.intodbrc";

my %DEFOPTS = (
  database  => "BenchDB.db",
  separator => ":",
  tmp       => undef,
  progress  => "dots",
  chunk     => 1,
);

my %OPTS = (
  verbose   => 0,
  database  => "BenchDB.db",
  rcfile    => undef,
  nostdrc   => 0,
  tmp       => undef,
  separator => undef,
  progress  => undef,
  chunk     => undef,
  help      => 0,
);

while ($ARGV[0] && $ARGV[0] =~ /^\-/) {
  if ($ARGV[0] =~ /^\-\-?h(elp)?$/) {
    $OPTS{help} += 1;
    shift(@ARGV);
    next;
  }
  if ($ARGV[0] =~ /^\-\-?progress=pct$/) {
    $OPTS{progress} = "pct";
    shift(@ARGV);
    next;
  }
  if ($ARGV[0] =~ /^\-\-?progress=dots$/) {
    $OPTS{progress} = "dots";
    shift(@ARGV);
    next;
  }
  if ($ARGV[0] =~ /^\-\-?v(erbose)?$/) {
    $OPTS{verbose} += 1;
    shift(@ARGV);
    next;
  }
  if ($ARGV[0] =~ /^\-\-?no(std)?rc(file)?$/) {
    $OPTS{nostdrc} = 1;
    shift(@ARGV);
    next;
  }
  if ($ARGV[0] =~ /^\-\-?d(ata)?b(ase)?=([\~\w\_\.\/]+)$/) {
    my @globed = glob $3;
    die "multiple files specified for database\n" if ($#globed > 0);
    die "no file specified for database\n" if ($#globed < 0);
    $OPTS{database} = shift(@globed);
    shift(@ARGV);
    next;
  }
  if ($ARGV[0] =~ /^\-\-?rc(file)?=([\~\w\_\.\/]+)$/) {
    my @globed = glob $2;
    die "multiple files specified for rcfile\n" if ($#globed > 0);
    die "no file specified for rcfile\n" if ($#globed < 0);
    $OPTS{rcfile} = shift(@globed);
    shift(@ARGV);
    next;
  }
  if ($ARGV[0] =~ /^\-\-?tmp(dir)?=([\~\w\_\.\/]+)$/) {
    my @globed = glob $2;
    die "multiple entries specified for tmpdir\n" if ($#globed > 0);
    die "no entry specified for tmpdircfile\n" if ($#globed < 0);
    $OPTS{tmp} = shift(@globed);
    shift(@ARGV);
    next;
  }
  if ($ARGV[0] =~ /^\-\-?sep(arator)?=(.+)$/) {
    $OPTS{separator} = $2;
    shift(@ARGV);
    next;
  }
  if ($ARGV[0] =~ /^\-\-?chunk=(\d+)$/) {
    $OPTS{chunk} = $1;
    shift(@ARGV);
    next;
  }
  die "unrecognized option: $ARGV[0]\n";
}

if (grep {$_ eq "--"} @ARGV) {
  my $arg = pop(@ARGV);
  while ($arg ne "--") {
    if ($arg =~ /^([\w_]+)=(.*)$/) {
      my $var = $1;
      my $val = $2; $val = "" if (!defined $val);
      $ENV{$var} = $val;
      $arg = pop(@ARGV);
      next;
    }
    die "wrong syntax for environment settings: $arg\n";
  }
}

unshift(@ARGV, "help") if ($OPTS{help});

#################################################
#################################################
# MODULE INITIALIZATIONS
#################################################
#################################################

my $TRUE = 1;
my $FALSE = 0;

my %TMPFILE;

my $SCRIPT = $Script;
my %LOCALENV;
my %LOCALEVAL;
my %LOCALFUNC;
my %LOCALFUNCPTR;
my %INTODBFUNC;
my %GLOBALENV;
my $NC= ($HAS_NUMBERCRUNCHER)? Math::NumberCruncher->new(): undef;
my $COLORTABLE= ($HAS_COLORNAMES)? Graphics::ColorNames->new("X","HTML"): undef;
my $DBH = undef;
END {$DBH->disconnect() if (defined $DBH)};
END {foreach my $f (keys %TMPFILE) {unlink $f if (-e $f);}};

# non-configurable options
my $DBFILE = $OPTS{database};
my $RCFILE = $OPTS{rcfile};
my $VERBOSE = $OPTS{verbose};
my $NOSTDRC = $OPTS{nostdrc};

# configurable options (set in IntoDB::loadConfig)
my $CHUNK = undef;
my $PROGRESS = undef;
my $SEPARATOR = undef;
my $TMPDIR = undef;

#################################################
#################################################

=head1 INTERNAL INTERFACE

=cut

#################################################
#################################################

#################################################
#################################################
# UTILITIES
#################################################
#################################################

=head2 UTILITIES

=head3 Class IndexVector

=over

=cut

package IndexVector;
our @ISA = qw();

=item $IndexVector = IndexVector->new($arity);

=item $IndexVector = IndexVector->new([@int_list]);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);
  my $arg = shift;
  if (ref($arg) eq "ARRAY") {
    $obj->{vector} = [(@$arg)];
  } else {
    $obj->{vector} = [(0) x $arg];
  }
  return $obj;
}

=item $int = $IndexVector->cmp($IndexVector2);

=cut

sub cmp {
  my $obj = shift;
  my $arg = shift;
  my $i = 0;
  while ($i <= $#{$obj->{vector}}) {
    return 1 if ($obj->{vector}->[$i] > $arg->{vector}->[$i]);
    return -1 if ($obj->{vector}->[$i] < $arg->{vector}->[$i]);
    $i += 1;
  }
  return 0;
}


=item $IndexVector = $IndexVector->next($max_Vector);

=cut

sub next {
  my $obj = shift;
  my $max = shift;
  return undef if ($obj->cmp($max) >= 0);
  my $i = $#{$obj->{vector}};
  while ($i >= 0) {
    if ($obj->{vector}->[$i] < $max->{vector}->[$i]) {
      $obj->{vector}->[$i] += 1;
      return $obj;
    }
    $obj->{vector}->[$i] = 0;
    $i -= 1;
  }
  return $obj;
}

=item [$val1, ...] = $IndexVector->get([ [...], ...  ]);

=cut

sub get {
  my $obj = shift;
  my $arg = shift;
  my @array = ();
  my $i = 0;
  while ($i <= $#{$obj->{vector}}) {
    push(@array, $arg->[$i]->[$obj->{vector}->[$i]]);
    $i += 1;
  }
  return [@array];
}

=back

=head3 Class Fn

=over

=cut

package Fn;
our @ISA = qw();

=item $Fn = Fn->new();

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);
  return $obj;
}

=item $data = $Fn->calc(@args);

=cut

sub calc {
  my $obj = shift;
  my $class = ref($obj) || $obj;
  die "\"calc\" method not implemented for Fn \"$class\"\n";
}

=back

=head3 Class FnConst: Fn

=over

=cut

package FnConst;
our @ISA = qw(Fn);

=item $FnConst = FnConst->new($val);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);
  my $val = shift;

  $obj->{val} = $val;
  return $val;
}

=item $val = $FnConst->calc();

=cut

sub calc {
  my $obj = shift;
  return $obj->{val};
}

=back

=head3 Class FnMap: Fn

=over

=cut

package FnMap;
our @ISA = qw(Fn);

=item $FnMap = FnMap->new($default, {x1 => y1, x2 => y2, ...});

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);
  my $def = shift;
  my $hash = shift;
  $obj->{default} = $def;
  $obj->{hash} = $hash;
  return $obj;
}

=item $val = $FnMap->calc($arg);

=cut

sub calc {
  my $obj = shift;
  my $arg = shift;
  return $obj->{hash}->{$arg} if (exists $obj->{hash}->{$arg});
  return $obj->{default};
}

=back

=head3 Class FnEnum: FnMap

=over

=cut

package FnEnum;
our @ISA = qw(FnMap);

=item $FnEnum = FnEnum->new($first_int, [x1, x2, ...]);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $first = shift;
  my $xlist = shift;
  my $def = $first - 1;
  my $hash = {};
  foreach my $x (@$xlist) {
    $hash->{$x} = $first;
    $first += 1;
  }
  my $obj = $class->SUPER::new($def, $hash);
  bless($obj, $class);
  return $obj;
}

=back

=head3 Class FnEnum0: FnEnum

=over

=cut

package FnEnum0;
our @ISA = qw(FnEnum);

=item $FnEnum0 = FnEnum0->new([x1, x2, ...]);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $xlist = shift;
  my $obj = $class->SUPER::new(0, $xlist);
  bless($obj, $class);
  return $obj;
}

=back

=head3 Class FnEnum1: FnEnum

=over

=cut

package FnEnum1;
our @ISA = qw(FnEnum);

=item $FnEnum1 = FnEnum1->new([x1, x2, ...]);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $xlist = shift;
  my $obj = $class->SUPER::new(1, $xlist);
  bless($obj, $class);
  return $obj;
}

=back

=head3 Class FnList: FnMap

=over

=cut

package FnList;
our @ISA = qw(FnMap);

=item $FnList = FnList->new($first_int, [x1, x2, ...]);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $first = shift;
  my $xlist = shift;
  my $def = undef;
  my $hash = {};
  foreach my $x (@$xlist) {
    $hash->{$first} = $x;
    $first += 1;
  }
  my $obj = $class->SUPER::new($def, $hash);
  bless($obj, $class);
  return $obj;
}

=back

=head3 Class FnList0: FnList

=over

=cut

package FnList0;
our @ISA = qw(FnList);

=item $FnList0 = FnList0->new([x1, x2, ...]);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $xlist = shift;
  my $obj = $class->SUPER::new(0, $xlist);
  bless($obj, $class);
  return $obj;
}

=back

=head3 Class FnList1: FnList

=over

=cut

package FnList1;
our @ISA = qw(FnList);

=item $FnList1 = FnList1->new([x1, x2, ...]);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $xlist = shift;
  my $obj = $class->SUPER::new(1, $xlist);
  bless($obj, $class);
  return $obj;
}

=back

=head3 Class FnCluster: Fn

=over

=cut

package FnCluster;
our @ISA = qw(Fn);

=item $FnCluster = FnCluster->new($start, $width);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);
  my $start = shift;
  my $width = shift;
  $obj->{start} = $start;
  $obj->{width} = $width;
  return $obj;
}

=item $val = $FnCluster->calc($arg);

=cut

sub calc {
  my $obj = shift;
  my $arg = shift;
  my $ref = $arg - $obj->{start};
  if ($ref >= 0) {
    return int($ref / $obj->{width});
  } else {
    return -1 * int(-1 * $ref / $obj->{width}) - 1;
  }
}

=back

=head3 Class FnCluster0: FnCluster

=over

=cut

package FnCluster0;
our @ISA = qw(FnCluster);

=item $FnCluster0 = FnCluster0->new($width);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $width = shift;
  my $obj = $class->SUPER::new(0, $width);
  bless($obj, $class);
  return $obj;
}

=back

=head3 Class Helper

=over

=cut

package Helper;
our @ISA = qw();

=item $string = Helper::findPath($program);

=cut

sub findPath {
  my $program = shift;
  my @path = split(/:/, $ENV{PATH});
  return undef if (!defined($program) || $program !~ /\S/);
  if ($program =~ /\//) {
    my $cwd = `pwd`; chomp($cwd); chomp($cwd);
    $program = $cwd . "/" . $program if ($program !~ /^\//);
    return undef if (!-f $program || !-x $program);
    return $program;
  }
  foreach my $d (@path) {
    next if ($d !~ /\S/);
    my $path = sprintf "%s/%s", $d, $program;
    return $path if (-f $path && -x $path);
  }
  return undef;
}

=item Helper->parseRc($rcConfig);

=cut

sub parseRc {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $rcConfig = shift;

  my $sname = "helpers";
  my $iname = lc($class);

  return if (!defined $rcConfig);
  my $str = join(",", $rcConfig->getValues($sname, $iname, -1));
  my $list = undef; eval {$list = Check::isList($str, [undef, undef])};
  die "rc parse error in section [$sname]: \"$iname\": $@\n" if ($@);
  if (defined $list && $#$list >= 0) {
    no strict "refs";
    my $ListVar = $class . "::List";
    @$ListVar = @$list;
  }
}

=item ($Helper, ...) = Helper->list();

=cut

sub list {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $ListVar = $class . "::List";
  no strict "refs";
  my @list = map {Helper->new($_)} @$ListVar;
  return @list;
}

=item $Helper = Helper->selected();

=cut

sub selected {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  foreach my $h ($class->list()) {
    return $h if (defined $h->path());
  }
  return undef;
}

=item $Helper = Helper->new($program);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);
  my $program = shift;

  $obj->{program} = $program;
  $obj->{path} = Helper::findPath($program);

  return $obj;
}

=item $string = $Helper->name();

=cut

sub name {
  my $obj = shift;
  my $name = $obj->{program};
  $name =~ s/.*\///;
  return $name;
}

=item $string = $Helper->path();

=cut

sub path {
  my $obj = shift;
  return $obj->{path};
}

=item $pid = $Helper->launch(@helper_args);

=cut

sub launch {
  my $obj = shift;
  my @args = @_;

  return undef if (!defined $obj->{path});

  my $launcher = fork();
  return undef if (!defined $launcher);
  if ($launcher) {
    my $rc = waitpid($launcher, 0);
    return $launcher;
  }

  # we are in the launcher: cleanup tmpfile list
  undef %TMPFILE;
  
  # we use double fork, so the child can be auto-reaped without
  # secondary effect in the main application
  $SIG{CHLD} = 'IGNORE';

  my $pid = fork();
  exit 1 if (!defined $pid);
  exit 0 if ($pid);

  exec ($obj->{path}, @args);
  exit 1;
}

=item $pid = $Helper->launchMonitored(\&atexit_func, $atexit_arg, @helper_args);

=cut

# note: atexit_func recives params: pid, exit_code, atexit_arg, @helper_args 
# note: atexit_func will be executed in a different process!!!

sub launchMonitored {
  my $obj = shift;
  my $func = shift;
  my $param = shift;
  my @args = @_;

  return undef if (!defined $obj->{path});

  my $launcher = fork();
  return undef if (!defined $launcher);
  if ($launcher) {
    my $rc = waitpid($launcher, 0);
    return $launcher;
  }

  # we are in the launcher: cleanup tmpfile list
  undef %TMPFILE;
  
  # we use double fork, so the child can be auto-reaped without
  # secondary effect in the main application
  $SIG{CHLD} = 'IGNORE';

  my $monitor = fork();
  exit 1 if (!defined $monitor);
  exit 0 if ($monitor);

  # now we are in the monitor code
  # restore SIG_CHLD, so we can wait
  $SIG{CHLD} = 'DEFAULT';

  my $child = fork();
  if (!defined $child) {
    &{$func}(undef, undef, $param, @args);
    exit 1;
  }
  if ($child) {
    my $rc = waitpid($child, 0);
    my $exit_code = $?;
    &{$func}($child, $exit_code, $param, @args);
    exit $exit_code >> 8;
  }

  exec ($obj->{path}, @args);
  exit 1;
}

=back

=head3 Class Jgraph: Helper

=over

=cut

package Jgraph;
our @ISA = qw(Helper);

our @List = qw(jgraph);

=item $Jgraph = Jgraph->new($program);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $program = shift;
  my $obj = $class->SUPER::new($program);
  bless($obj, $class);
  return $obj;
}

=back

=head3 Class TextEditor: Helper

=over

=cut

package TextEditor;
our @ISA = qw(Helper);

our @List = qw(
  gvim
  nedit
  gedit
  kedit
  xedit
);

=item $TextEditor = TextEditor->new($program);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $program = shift;
  my $obj = $class->SUPER::new($program);
  bless($obj, $class);
  return $obj;
}

=back

=head3 Class PsViewer: Helper

=over

=cut

package PsViewer;
our @ISA = qw(Helper);

our @List = qw(
  evince
  gv
);

=item $PsViewer = PsViewer->new($program);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $program = shift;
  my $obj = $class->SUPER::new($program);
  bless($obj, $class);
  return $obj;
}

=back

=head3 Class Progress

=over

=cut

package Progress;
our @ISA = qw();

=item $Progress = Progress->new();

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);
  $obj->{name}     = $class;
  $obj->{success}  = 0;
  $obj->{skipped}  = 0;
  $obj->{failed}   = 0;
  $obj->{total}    = undef;
  $obj->{canceled} = 0;
  $obj->{ended}    = 0;
  $obj->{hook_success} = undef;
  $obj->{hook_skipped} = undef;
  $obj->{hook_failed} = undef;
  $obj->{hook_ended} = undef;
  $obj->{hook_canceled} = undef;
  return $obj;
}

=item $string = $Progress->name();

=cut

sub name {
  my $obj = shift;
  return $obj->{name};
}

=item $Progress = $Progress->setName($string);

=cut

sub setName {
  my $obj = shift;
  my $str = shift;
  $obj->{name} = $str;
  return $obj;
}

=item $Progress = $Progress->setTotal($value);

=cut

sub setTotal {
  my $obj = shift;
  my $total = shift;
  $obj->{total} = $total;
  return $obj;
}

=item $Progress = $Progress->addSuccess();

=item $Progress = $Progress->addSuccess($value);

=cut

sub addSuccess {
  my $obj = shift;
  my $val = shift; $val = 1 if (!defined $val);
  $obj->{success} += $val;
  my $hook = $obj->{hook_success};
  if (defined $hook) {
    &{$hook}($obj, $val, $obj->{arg_hook_success});
  }
  return $obj;
}

=item $Progress = $Progress->addSkipped();

=item $Progress = $Progress->addSkipped($value);

=cut

sub addSkipped {
  my $obj = shift;
  my $val = shift; $val = 1 if (!defined $val);
  $obj->{skipped} += $val;
  my $hook = $obj->{hook_skipped};
  if (defined $hook) {
    &{$hook}($obj, $val, $obj->{arg_hook_skipped});
  }
  return $obj;
}

=item $Progress = $Progress->addFailed();

=item $Progress = $Progress->addFailed($value);

=cut

sub addFailed {
  my $obj = shift;
  my $val = shift; $val = 1 if (!defined $val);
  $obj->{failed} += $val;
  my $hook = $obj->{hook_failed};
  if (defined $hook) {
    &{$hook}($obj, $val, $obj->{arg_hook_failed});
  }
  return $obj;
}

=item $val = $Progress->getSuccess();

=cut

sub getSuccess {
  my $obj = shift;
  return $obj->{success};
}

=item $val = $Progress->getSkipped();

=cut

sub getSkipped {
  my $obj = shift;
  return $obj->{skipped};
}

=item $val = $Progress->getFailed();

=cut

sub getFailed {
  my $obj = shift;
  return $obj->{failed};
}

=item $val = $Progress->getSuccessRatio();

=cut

sub getSuccessRatio {
  my $obj = shift;
  return 0 if (!$obj->{total});
  return $obj->{success} / $obj->{total};
}

=item $val = $Progress->getSkippedRatio();

=cut

sub getSkippedRatio {
  my $obj = shift;
  return 0 if (!$obj->{total});
  return $obj->{skipped} / $obj->{total};
}

=item $val = $Progress->getFailedRatio();

=cut

sub getFailedRatio {
  my $obj = shift;
  return 0 if (!$obj->{total});
  return $obj->{failed} / $obj->{total};
}

=item $Progress = $Progress->setCancel();

=cut

sub setCancel {
  my $obj = shift;
  $obj->{canceled} = 1;
  my $hook = $obj->{hook_canceled};
  if (defined $hook) {
    &{$hook}($obj, $obj->{arg_hook_canceled});
  }
  return $obj;
}

=item $bool = $Progress->getCancel();

=cut

sub getCancel {
  my $obj = shift;
  return $obj->{canceled};
}

=item $Progress = $Progress->setEnd();

=cut

sub setEnd {
  my $obj = shift;
  $obj->{ended} = 1;
  my $hook = $obj->{hook_ended};
  if (defined $hook) {
    &{$hook}($obj, $obj->{arg_hook_ended});
  }
  return $obj;
}

=item $bool = $Progress->getEnd();

=cut

sub getEnd {
  my $obj = shift;
  return $obj->{ended};
}

=item $Progress = $Progress->setHook($event, \&func, $arg);

=cut

sub setHook {
  my $obj = shift;
  my $event = shift;
  my $func = shift;
  my $arg = shift;
  my $hook = "hook_" . $event;
  if (exists $obj->{$hook}) {
    $obj->{$hook} = $func;
    $obj->{"arg_" . $hook} = $arg;
  }
  return $obj;
}

=back

=head3 Class DotProgress: Progress

=over

=cut

package DotProgress;
our @ISA = qw(Progress);

=item $DotProgress = DotProgress->new();

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);
  return $obj;
}

=item $DotProgress = $DotProgress->addSuccess();

=cut

sub addSuccess {
  my $obj = shift;
  $obj->SUPER::addSuccess();
  local $| = 1;
  print ".";
  return $obj;
}

=item $DotProgress = $DotProgress->addSkipped();

=cut

sub addSkipped {
  my $obj = shift;
  $obj->SUPER::addSkipped();
  local $| = 1;
  print "+";
  return $obj;
}

=item $DotProgress = $DotProgress->addFailed();

=cut

sub addFailed {
  my $obj = shift;
  $obj->SUPER::addFailed();
  local $| = 1;
  print "!";
  return $obj;
}

=item $DotProgress = $DotProgress->setCancel();

=cut

sub setCancel {
  my $obj = shift;
  $obj->SUPER::setCancel();
  local $| = 1;
  print "\n";
  return $obj;
}

=item $DotProgress = $DotProgress->setEnd();

=cut

sub setEnd {
  my $obj = shift;
  $obj->SUPER::setEnd();
  local $| = 1;
  print "\n";
  return $obj;
}

=back

=head3 Class PctProgress: Progress

=over

=cut

package PctProgress;
our @ISA = qw(Progress);

=item $PctProgress = PctProgress->new();

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);
  return $obj;
}

=item $PctProgress = $PctProgress->addSuccess();

=cut

sub addSuccess {
  my $obj = shift;
  $obj->SUPER::addSuccess(@_);
  local $| = 1;
  my $success = $obj->getSuccessRatio();
  my $skipped = $obj->getSkippedRatio();
  my $failed  = $obj->getFailedRatio();
  my $overall = $success + $skipped + $failed;
  printf "\rsucceded:" .
         " %6.2f%%,  skipped: %6.2f%%,  failed: %6.2f%%,  total: %6.2f%%",
         $success * 100,
         $skipped * 100,
         $failed  * 100,
         $overall * 100;
  return $obj;
}

=item $PctProgress = $PctProgress->addSuccess();

=cut

sub addSkipped {
  my $obj = shift;
  $obj->SUPER::addSkipped(@_);
  local $| = 1;
  my $success = $obj->getSuccessRatio();
  my $skipped = $obj->getSkippedRatio();
  my $failed  = $obj->getFailedRatio();
  my $overall = $success + $skipped + $failed;
  printf "\rsucceded:" .
         " %6.2f%%,  skipped: %6.2f%%,  failed: %6.2f%%,  total: %6.2f%%",
         $success * 100,
         $skipped * 100,
         $failed  * 100,
         $overall * 100;
  return $obj;
}

=item $PctProgress = $PctProgress->addFailed();

=cut

sub addFailed {
  my $obj = shift;
  $obj->SUPER::addFailed(@_);
  local $| = 1;
  my $success = $obj->getSuccessRatio();
  my $skipped = $obj->getSkippedRatio();
  my $failed  = $obj->getFailedRatio();
  my $overall = $success + $skipped + $failed;
  printf "\rsucceded:" .
         " %6.2f%%,  skipped: %6.2f%%,  failed: %6.2f%%,  total: %6.2f%%",
         $success * 100,
         $skipped * 100,
         $failed  * 100,
         $overall * 100;
  return $obj;
}

=item $PctProgress = $PctProgress->setCancel();

=cut

sub setCancel {
  my $obj = shift;
  $obj->SUPER::setCancel();
  local $| = 1;
  print "\n";
  return $obj;
}

=item $PctProgress = $PctProgress->setEnd();

=cut

sub setEnd {
  my $obj = shift;
  $obj->SUPER::setEnd();
  local $| = 1;
  print "\n";
  return $obj;
}

=back

=cut

#################################################
#################################################
# DATABASE
#################################################
#################################################

=head2 DATABASE TABLES

=head3 Class DBTable

=over

=cut

package DBTable;
our @ISA = qw();

=item $DBTable = DBTable->new($Db, $table_name);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $dbh = shift;
  my $table = uc(shift(@_));
  my $obj = {};
  bless($obj, $class);
  die "null table name\n" if (!defined $table);
  $table = uc($table);
  $table =~ s/[^\w_]/_/g;
  die "invalid table name\n" if ($table eq "");
  $obj->{table} = $table;
  $obj->{dbh} = $dbh;
  return $obj;
}

=item $string = $DBTable->table();

=cut

sub table {
  my $obj = shift;
  return $obj->{table};
}

=item $int = $DBTable->rows();

=cut

sub rows {
  my $obj = shift;
  my $sqlstr = sprintf "SELECT COUNT(*) FROM %s\n", $obj->{table};
  my $sth = $obj->{dbh}->do($sqlstr);
  my ($row) = $sth->fetchrow_array();
  return $row;
}

=item $Db = $DBTable->database();

=cut

sub database {
  my $obj = shift;
  return $obj->{dbh};
}

=back

=head3 Class DBInfo: DBTable

=over

=cut

package DBInfo;
our @ISA = qw(DBTable);

=item $Dbinfo = DBInfo->create($Db);

=cut

sub create {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $dbh = shift;
  my $obj = $class->SUPER::new($dbh, "DBINFO");
  bless($obj, $class);
  $obj->{dummy} = 0;

  my $sqlstr = "CREATE TABLE " .
               "DBINFO ( " .
               "  ITEM TEXT NOT NULL PRIMARY KEY, " .
               "  DATUM TEXT " .
               ")";
  $dbh->do($sqlstr);

  $sqlstr = "INSERT INTO DBINFO (ITEM, DATUM) VALUES (?, ?)";
  my $sth = $dbh->prepare($sqlstr);
  $dbh->execute($sth, "MAJOR", $MAJOR);
  $dbh->execute($sth, "MINOR", $MINOR);
  $dbh->execute($sth, "RELEASE", $RELEASE);

  return $obj;
}

=item $Dbinfo = DBInfo->new($Db);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $dbh = shift;
  my $obj = $class->SUPER::new($dbh, "DBINFO");
  bless($obj, $class);
  $obj->{dummy} = ($dbh->checkTable("DBINFO"))? 0: 1;
  return $obj;
}
  
=item ($str, ...) = $Dbinfo->listKeys();

=cut

sub listKeys {
  my $obj = shift;
  return () if ($obj->{dummy});
  my $sqlstr = "SELECT ITEM FROM DBINFO ORDER BY ITEM";
  my $sth = $obj->{dbh}->do($sqlstr);
  my @list = ();
  my $row = $sth->fetchrow_hashref();
  while (defined $row) {
    push(@list, $row->{ITEM});
    $row = $sth->fetchrow_hashref();
  }
  return @list;
}

=item $str = $Dbinfo->getItem($key);

=cut

sub getItem {
  my $obj = shift;
  my $key   = uc(shift(@_));
  return undef if ($obj->{dummy});

  my $sqlstr = "SELECT DATUM FROM DBINFO WHERE ITEM = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $key);
  my $row = $sth->fetchrow_hashref();
  return undef if (!defined $row);
  return $row->{DATUM};
}

=item ($major, $minor) = $Dbinfo->getVersion();

=item $str = $Dbinfo->getVersion();

=cut

sub getVersion {
  my $obj = shift;
  if ($obj->{dummy}) {
    return (wantarray)? (0, 99): "0.99";
  }
  my $major = $obj->getItem("MAJOR"); $major = 0 if (!defined $major);
  my $minor = $obj->getItem("MINOR"); $minor = 0 if (!defined $minor);
  return (wantarray)? ($major, $minor): sprintf("%s.%s", $major, $minor);
}

=back

=head3 Class Benchmark: DBTable

=over

=cut

package Benchmark;
our @ISA = qw(DBTable);

=item Benchmark->create($Db);

=cut

sub create {
  my $proto = shift;
  my $dbh = shift;
  my $sqlstr = "CREATE TABLE IF NOT EXISTS " .
               "BENCHMARK ( " .
               "  ID INTEGER NOT NULL PRIMARY KEY ASC AUTOINCREMENT, " .
               "  NAME TEXT NOT NULL UNIQUE, " .
               "  DESC TEXT " .
               ")";
  $dbh->do($sqlstr);
}

=item ($str, ...) = Benchmark->listNames($Db);

=cut

sub listNames {
  my $proto = shift;
  my $dbh = shift;

  my $sqlstr = "SELECT NAME FROM BENCHMARK ORDER BY NAME";
  my $sth = $dbh->do($sqlstr);

  my @list = ();
  my $row = $sth->fetchrow_hashref();
  while (defined $row) {
    push(@list, $row->{NAME});
    $row = $sth->fetchrow_hashref();
  }
  return @list;
}

=item ($Benchmark, ...) = Benchmark->list($Db);

=cut

sub list {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $dbh = shift;
  my @list = (map {$class->new($dbh, $_)} ($class->listNames($dbh)));
  return @list;
}

=item $Benchmark = Benchmark->new($Db, $name);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $dbh = shift;
  my $obj = $class->SUPER::new($dbh, "BENCHMARK");
  bless($obj, $class);
  my $name = shift;
  die "null benchmark name\n" if (!defined $name);
  $name = uc($name);
  $name =~ s/[^\w_]/_/g;
  die "invalid benchmark name\n" if ($name eq "");
  die "invalid benchmark name\n" if ($name =~ /_VIEW$/);
  die "invalid benchmark name\n" if ($name =~ /^_/);

  $obj->{name} = $name;
  $obj->{desc} = undef;

  my $sqlstr = "SELECT * FROM BENCHMARK WHERE NAME = ?";
  my $sth = $dbh->do($sqlstr, $name);
  my $row = $sth->fetchrow_hashref();
  if (!defined $row) {
    $sqlstr = "INSERT INTO BENCHMARK (NAME, DESC) VALUES (?, ?)";
    $dbh->do($sqlstr, $name, undef);
    $sqlstr = "SELECT * FROM BENCHMARK WHERE NAME = ?";
    $sth = $dbh->do($sqlstr, $name);
    $row = $sth->fetchrow_hashref();
    if (!defined $row) {
      print STDERR "$sqlstr\n";
      die "sql select failed\n";
    }
  }
  $obj->{name} = $row->{NAME};
  $obj->{desc} = $row->{DESC};
  $obj->{id}   = $row->{ID};

  return $obj;
}

=item $Benchmark = Benchmark->get($Db, $name);

=cut

sub get {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $dbh = shift;
  my $obj = $class->SUPER::new($dbh, "BENCHMARK");
  bless($obj, $class);
  my $name = shift;
  die "null benchmark name\n" if (!defined $name);
  $name = uc($name);
  $name =~ s/[^\w_]/_/g;
  die "invalid benchmark name\n" if ($name eq "");

  $obj->{name} = $name;
  $obj->{desc} = undef;

  my $sqlstr = "SELECT * FROM BENCHMARK WHERE NAME = ?";
  my $sth = $dbh->do($sqlstr, $name);
  my $row = $sth->fetchrow_hashref();
  if (!defined $row) {
    die "unknown benchmark \"$name\"\n";
  }
  $obj->{name} = $row->{NAME};
  $obj->{desc} = $row->{DESC};
  $obj->{id}   = $row->{ID};

  return $obj;
}

=item $Benchmark = Benchmark->getById($Db, $name);

=cut

sub getById {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $dbh = shift;
  my $obj = $class->SUPER::new($dbh, "BENCHMARK");
  bless($obj, $class);
  my $id = shift;
  die "null benchmark name\n" if (!defined $id);
  die "invalid benchmark id\n" if ($id !~ /^\s*\d+\s*$/);

  $obj->{id} = $id + 0;
  $obj->{desc} = undef;

  my $sqlstr = "SELECT * FROM BENCHMARK WHERE ID = ?";
  my $sth = $dbh->do($sqlstr, $id);
  my $row = $sth->fetchrow_hashref();
  if (!defined $row) {
    die "unknown benchmark \"$id\"\n";
  }
  $obj->{name} = $row->{NAME};
  $obj->{desc} = $row->{DESC};
  $obj->{id}   = $row->{ID};

  return $obj;
}

=item $Benchmark->remove();

=cut

sub remove {
  my $obj = shift;
  my @fields = $obj->getFieldNames();
  if (@fields) {
    die "cannot remove benchmark: fields still exist\n";
  }
  my $sqlstr = "DELETE FROM BENCHMARK WHERE ID = ?";
  $obj->{dbh}->do($sqlstr, $obj->{id});
  $obj->{id} = undef;
  $obj->{name} = undef;
  $obj->{desc} = undef;
  return $obj;
}

=item $int = $Benchmark->id();

=cut

sub id {
  my $obj = shift;
  return $obj->{id};
}

=item $string = $Benchmark->name();

=cut

sub name {
  my $obj = shift;
  return $obj->{name};
}

=item $string = $Benchmark->getName();

=cut

sub getName {
  my $obj = shift;
  my $sqlstr = "SELECT NAME FROM BENCHMARK WHERE ID = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $obj->{id});
  my $row = $sth->fetchrow_hashref();
  if (!defined $row) {
    print STDERR "$sqlstr\n";
    die "sql select failed\n";
  }
  $obj->{name} = $row->{NAME};
  return $obj->{name};
}

=item $Benchmark = $Benchmark->setName($name);

=cut

sub setName {
  my $obj = shift;
  my $name = shift;
  die "null benchmark name\n" if (!defined $name);
  $name = uc($name);
  $name =~ s/[^\w_]/_/g;
  die "invalid benchmark name\n" if ($name eq "");
  return $obj if ($obj->{name} eq $name);

  my $oldname = $obj->{name};
  my $oldview = $oldname . "_VIEW";
  my $newview = $name . "_VIEW";
  $obj->{dbh}->begin_work();
  eval {
    my $sqlstr = "UPDATE BENCHMARK SET NAME = ? WHERE ID = ?";
    $obj->{dbh}->do($sqlstr, $name, $obj->{id});
    if ($obj->{dbh}->checkTable($oldview)) {
      $sqlstr = "ALTER TABLE $oldview RENAME TO $newview";
      $obj->{dbh}->do($sqlstr);
    }
    $obj->{dbh}->commit();
  };
  if ($@) {
    my $errstr = $@;
    $obj->{dbh}->rollback();
    die "$errstr\n";
  }
  $obj->{name} = $name;
  
  return $obj;
}

=item $string = $Benchmark->viewName();

=cut

sub viewName {
  my $obj = shift;
  return $obj->{name} . "_VIEW";
}

=item $string = $Benchmark->getViewName();

=cut

sub getViewName {
  my $obj = shift;
  return $obj->getName() . "_VIEW";
}

=item $DataView = $Benchmark->view();

=cut

sub view {
  my $obj = shift;
  return DataView->new($obj);
}

=item $string = $Benchmark->getDesc();

=cut

sub getDesc {
  my $obj = shift;
  my $sqlstr = "SELECT DESC FROM BENCHMARK WHERE ID = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $obj->{id});
  my $row = $sth->fetchrow_hashref();
  if (!defined $row) {
    print STDERR "$sqlstr\n";
    die "sql select failed\n";
  }
  $obj->{desc} = $row->{DESC};
  return $obj->{desc};
}

=item $Benchmark = $Benchmark->setDesc($description);

=cut

sub setDesc {
  my $obj = shift;
  my $desc = shift;
  $desc = undef if (defined $desc && $desc =~ /^\s*$/);
  my $sqlstr = "UPDATE BENCHMARK SET DESC = ? WHERE ID = ?";
  $obj->{dbh}->do($sqlstr, $desc, $obj->{id});
  $obj->{desc} = $desc;
  return $obj;
}

=item $int = $Benchmark->getExpCount();

=cut

sub getExpCount {
  my $obj = shift;
  my $sqlstr = "SELECT COUNT(*) FROM EXPERIMENT WHERE BENCH = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $obj->{id});
  my ($row) = $sth->fetchrow_array();
  if (!defined $row) {
    print STDERR "$sqlstr\n";
    die "sql select failed\n";
  }
  return $row;
}

=item ($str, ...) = $Benchmark->getFieldNames();

=cut

sub getFieldNames {
  my $obj = shift;
  my $sqlstr = "SELECT NAME FROM FIELD WHERE BENCH = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $obj->{id});
  my @list = ();
  my $row = $sth->fetchrow_hashref();
  while (defined $row) {
    push(@list, $row->{NAME});
    $row = $sth->fetchrow_hashref();
  }
  return (sort {$a cmp $b} @list);
}

=item ($Field, ...) = $Benchmark->getFields();

=cut

sub getFields {
  my $obj = shift;
  return (map {Field->new($obj, $_)} $obj->getFieldNames());
}

=item ($str, ...) = $Benchmark->getKeyFieldNames();

=cut

sub getKeyFieldNames {
  my $obj = shift;
  my $sqlstr = "SELECT NAME FROM EXPKEY WHERE BENCH = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $obj->{id});
  my @list = ();
  my $row = $sth->fetchrow_hashref();
  while (defined $row) {
    push(@list, $row->{NAME});
    $row = $sth->fetchrow_hashref();
  }
  return (sort {$a cmp $b} @list);
}

=item ($Field, ...) = $Benchmark->getKeyFields();

=cut

sub getKeyFields {
  my $obj = shift;
  return (map {Field->new($obj, $_)} $obj->getKeyFieldNames());
}

=item $Benchmark = $Benchmark->removeAllFields();

=cut

sub removeAllFields {
  my $obj = shift;
  my $sqlstr;
  my $sth;

  my $n = $obj->getExpCount();
  die "cannot remove fields while data is present\n" if ($n > 0);

  my @indexes = ExpIdx->list($obj);
  foreach my $idx (@indexes) {
    $idx->remove();
  }

  $obj->view()->destroy();
  $obj->{dbh}->begin_work();
  eval {
    $sqlstr = "DELETE FROM EXPKEY WHERE BENCH = ?";
    $sth = $obj->{dbh}->do($sqlstr, $obj->{id});
  
    $sqlstr = "DELETE FROM FIELD WHERE BENCH = ?";
    $sth = $obj->{dbh}->do($sqlstr, $obj->{id});

    $obj->{dbh}->commit();
  };
  if ($@) {
    my $errstr = $@;
    $obj->{dbh}->rollback();
    die "$errstr\n";
  }
  
  return $obj;
}

=item $Benchmark = $Benchmark->removeAllExperiments();

=cut

sub removeAllExperiments {
  my $obj = shift;
  my $sqlstr;
  my $sth;

  $obj->{dbh}->begin_work();
  eval {
    $obj->view()->removeAll();
    my $sqlstr = "DELETE FROM EXPERIMENT WHERE BENCH = ?";
    $obj->{dbh}->do($sqlstr, $obj->{id});
    $obj->{dbh}->commit();
  };
  if ($@) {
    my $errstr = $@;
    $obj->{dbh}->rollback();
    die "$errstr\n";
  }

  return $obj;
}

=back

=head3 Class Field: DBTable

=over

=cut

package Field;
our @ISA = qw(DBTable);

=item Field->create($Db);

=cut

sub create {
  my $proto = shift;
  my $dbh = shift;
  my $sqlstr = "CREATE TABLE IF NOT EXISTS " .
               "FIELD ( " .
               "  BENCH INTEGER NOT NULL REFERENCES BENCHMARK (ID) " .
               "                         ON DELETE RESTRICT, " .
               "  NAME TEXT NOT NULL, " .
               "  ISNUM INTEGER, " .
               "  PRIMARY KEY (BENCH, NAME)" .
               ")";
  $dbh->do($sqlstr);
  $dbh->enforceForeignKey("FIELD", ["BENCH"], "BENCHMARK", ["ID"]);
}

=item $Field = Field->new($Bench, $name);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $bench = shift;
  my $obj = $class->SUPER::new($bench->database(), "FIELD");
  bless ($obj, $class);
  my $name = shift;
  die "null field name\n" if (!defined $name);
  $name = uc($name);
  $name =~ s/[^\w_]/_/g;
  die "invalid field name\n" if ($name eq "");

  $obj->{bench} = $bench;
  $obj->{name} = $name;
  $obj->{num} = 0;

  my $sqlstr = "SELECT * FROM FIELD WHERE BENCH = ? AND NAME = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $bench->id(), $name);
  my $row = $sth->fetchrow_hashref();
  if (!defined $row) {
    if ($bench->getExpCount() > 0) {
      die "cannot change benchmark specification (data exists)\n"
    }
    $bench->view()->destroy();
    $sqlstr = "INSERT INTO FIELD (BENCH, NAME, ISNUM) VALUES (?, ?, ?)";
    $obj->{dbh}->do($sqlstr, $bench->id(), $name, 0);
  } else {
    $obj->{num} = $row->{ISNUM};
  }

  return $obj;
}

=item $Field = Field->get($Bench, $name);

=cut

sub get {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $bench = shift;
  my $obj = $class->SUPER::new($bench->database(), "FIELD");
  bless ($obj, $class);
  my $name = shift;
  die "null field name\n" if (!defined $name);
  $name = uc($name);
  $name =~ s/[^\w_]/_/g;
  die "invalid field name\n" if ($name eq "");

  $obj->{bench} = $bench;
  $obj->{name} = $name;
  $obj->{num} = 0;

  my $sqlstr = "SELECT * FROM FIELD WHERE BENCH = ? AND NAME = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $bench->id(), $name);
  my $row = $sth->fetchrow_hashref();
  if (!defined $row) {
    die "unknown field \"$name\"\n";
  } else {
    $obj->{num} = $row->{ISNUM};
  }

  return $obj;
}

=item $Field = Field->add($Bench, $name, $numeric_bool, $default_value);

=cut

sub add {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $bench = shift;
  my $obj = $class->SUPER::new($bench->database(), "FIELD");
  bless ($obj, $class);
  my $name = shift;
  my $numeric = shift;
  my $default = shift;
  die "null field name\n" if (!defined $name);
  $name = uc($name);
  $name =~ s/[^\w_]/_/g;
  die "invalid field name\n" if ($name eq "");
  die "null default value\n" if (!defined $default);
  if ($numeric) {
    die "invalid default value\n" if (!Check::IsNum($default));
  }

  $obj->{bench} = $bench;
  $obj->{name} = $name;
  $obj->{num} = ($numeric)? 1: 0;

  my $sqlstr = "SELECT * FROM FIELD WHERE BENCH = ? AND NAME = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $bench->id(), $name);
  my $row = $sth->fetchrow_hashref();
  if (defined $row) {
    die "field already exists: $name\n";
  }

  $obj->{dbh}->begin_work();
  eval {
    $sqlstr = "INSERT INTO FIELD (BENCH, NAME, ISNUM) VALUES (?, ?, ?)";
    $obj->{dbh}->do($sqlstr, $bench->id(), $name, $obj->{num});
    my $view = $bench->view();
    if ($view->check()) {
      $sqlstr = "ALTER TABLE " . $view->table() . " ADD COLUMN _$name";
      if ($obj->{num}) {
        $sqlstr .= " NUMERIC NOT NULL DEFAULT " . $default;
      } else {
        $sqlstr .= " TEXT NOT NULL DEFAULT " . $obj->{dbh}->quote($default);
      }
      $obj->{dbh}->do($sqlstr);
    }
    $obj->{dbh}->commit();
  };
  if ($@) {
    my $errstr = $@;
    $obj->{dbh}->rollback();
    die "$errstr\n";
  }

  return $obj;
}

=item $Field->remove();

=cut

sub remove {
  my $obj = shift;
  if ($obj->bench()->getExpCount() > 0) {
    die "cannot change benchmark specification (data exists)\n"
  }
  if ($obj->getKey()) {
    die "cannot remove a key field (remove key status first)\n";
  }
  my @indexes = ExpIdx->list($obj);
  foreach my $idx (@indexes) {
    $idx->remove();
  }
  $obj->{bench}->view()->destroy();
  my $sqlstr = "DELETE FROM FIELD WHERE BENCH = ? AND NAME = ?";
  $obj->{dbh}->do($sqlstr, $obj->{bench}->id(), $obj->{name});
  $obj->{bench} = undef;
  $obj->{name} = undef;
  $obj->{num} = undef;
  return $obj;
}

=item $Benchmark = $Field->bench();

=cut

sub bench {
  my $obj = shift;
  return $obj->{bench};
}

=item $string = $Field->name();

=cut

sub name {
  my $obj = shift;
  return $obj->{name};
}

=item $bool = $Field->numeric();

=cut

sub numeric {
  my $obj = shift;
  return $obj->{num};
}

=item $bool = $Field->getNumeric();

=cut

sub getNumeric {
  my $obj = shift;
  my $sqlstr = "SELECT ISNUM FROM FIELD WHERE BENCH = ? AND NAME = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $obj->{bench}->id(), $obj->{name});
  my $row = $sth->fetchrow_hashref();
  if (!defined $row) {
    print STDERR "$sqlstr\n";
    die "sql select failed\n";
  }
  $obj->{num} = $row->{ISNUM};
  return $obj->{num};
}

=item $Field = $Field->setNumeric($bool);

=cut

sub setNumeric {
  my $obj = shift;
  my $bool = shift;

  if ($obj->{bench}->getExpCount() > 0) {
    die "cannot change benchmark field specification (data exists)\n"
  }

  $bool = ($bool)? 1: 0;
  my $sqlstr = "UPDATE FIELD SET ISNUM = ? WHERE BENCH = ? AND NAME = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $bool, $obj->{bench}->id(), $obj->{name});
  $obj->{num} = $bool;
  return $obj;
}

=item $bool = $Field->getKey();

=cut

sub getKey {
  my $obj = shift;
  my $sqlstr = "SELECT COUNT(*) FROM EXPKEY WHERE BENCH = ? AND NAME = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $obj->{bench}->id(), $obj->{name});
  my ($row) = $sth->fetchrow_array();
  if (!defined $row) {
    print STDERR "$sqlstr\n";
    die "sql select failed\n";
  }
  return $row;
}

=item $Field = $Field->setKey($bool);

=cut

sub setKey {
  my $obj = shift;
  my $bool = shift;

  if ($obj->{bench}->getExpCount() > 0) {
    die "cannot change benchmark field specification (data exists)\n"
  }

  my $iskey = $obj->getKey();
  if (($iskey && $bool) || (!$iskey && !$bool)) {
    return $obj;
  }

  my $sqlstr;
  if ($bool) {
    $sqlstr = "INSERT INTO EXPKEY (BENCH, NAME) VALUES (?, ?)";
  } else {
    $sqlstr = "DELETE FROM EXPKEY WHERE BENCH = ? AND NAME = ?";
  }
  $obj->{dbh}->do($sqlstr, $obj->{bench}->id(), $obj->{name});
  return $obj;
}

=back

=head3 Class ExpKey: DBTable

=over

=cut

package ExpKey;
our @ISA = qw(DBTable);

=item ExpKey->create($Db);

=cut

sub create {
  my $proto = shift;
  my $dbh = shift;
  my $sqlstr = "CREATE TABLE IF NOT EXISTS " .
               "EXPKEY ( " .
               "  BENCH INTEGER NOT NULL REFERENCES BENCHMARK (ID) " .
               "                         ON DELETE RESTRICT, " .
               "  NAME TEXT NOT NULL, " .
               "  PRIMARY KEY (BENCH, NAME), " .
               "  FOREIGN KEY (BENCH, NAME) REFERENCES FIELD (BENCH, NAME) " .
               "          ON DELETE RESTRICT" .
               ")";
  $dbh->do($sqlstr);
  $dbh->enforceForeignKey("EXPKEY", ["BENCH"], "BENCHMARK", ["ID"]);
  $dbh->enforceForeignKey("EXPKEY", ["BENCH", "NAME"],
                          "FIELD", ["BENCH", "NAME"]);
}

=back

=head3 Class ExpIdx: DBTable

=over

=cut

package ExpIdx;
our @ISA = qw(DBTable);

=item ExpIdx->create($Db);

=cut

sub create {
  my $proto = shift;
  my $dbh = shift;
  my $sqlstr = "CREATE TABLE IF NOT EXISTS " .
               "EXPIDX ( " .
               "  ID INTEGER NOT NULL PRIMARY KEY ASC AUTOINCREMENT, " .
               "  BENCH INTEGER NOT NULL REFERENCES BENCHMARK (ID) " .
               "                         ON DELETE RESTRICT, " .
               "  NAME TEXT NOT NULL, " .
               "  FIELDS TEXT NOT NULL, " .
               "  UNIQUE (NAME), " .
               "  UNIQUE (BENCH, FIELDS)" .
               ")";
  $dbh->do($sqlstr);
  $dbh->enforceForeignKey("EXPIDX", ["BENCH"], "BENCHMARK", ["ID"]);
}

=item ($ExpIdx, ...) = ExpIdx->list($Benchmark);

=item ($ExpIdx, ...) = ExpIdx->list($Field);

=cut

sub list {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $item = shift;

  my ($dbh, $bench, $field);
  if (UNIVERSAL::isa($item, "Benchmark")) {
    $field = undef;
    $bench = $item;
    $dbh = $bench->database();
  } elsif (UNIVERSAL::isa($item, "Field")) {
    $field = $item;
    $bench = $field->bench();
    $dbh = $bench->database();
  } else {
    die "invalid argument for ExpIdx::list\n";
  }

  my $sqlstr = "SELECT NAME FROM EXPIDX WHERE BENCH = ?";
     $sqlstr .=  " AND FIELDS LIKE ?" if (defined $field);
  my @args = ($bench->id());
  push(@args, "%:" . $field->name() . ":%") if (defined $field);
  my $sth = $dbh->do($sqlstr, @args);
  my @names = ();
  my $row = $sth->fetchrow_hashref();
  while (defined $row) {
    push(@names, $row->{NAME});
    $row = $sth->fetchrow_hashref();
  }
  return (map {ExpIdx->getByName($dbh, $_)} @names);
}

=item $ExpIdx = ExpIdx->new($Benchmark, @field_names)

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $bench = shift;
  my $obj = $class->SUPER::new($bench->database(), "EXPIDX");
  bless($obj, $class);
  my @field_names = @_;
  die "no fields specified to create an index\n" if (!@field_names);

  $obj->{id} = undef;
  $obj->{bench} = $bench;
  $obj->{name} = undef;
  $obj->{fields} = undef;

  my @bfields = $bench->getFieldNames();
  my @flist = ();
  foreach my $f (@field_names) {
    if (!grep {uc($f) eq $_} @bfields) {
      die "unknown index field $f\n";
    }
    push(@flist, uc($f));
  }

  my $idxstr = ":" . join(":", @flist) . ":";
  my $sqlstr = "SELECT * FROM EXPIDX WHERE BENCH = ? AND FIELDS = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $bench->id(), $idxstr);
  my $row = $sth->fetchrow_hashref();
  if (!defined $row) {
    $obj->{dbh}->begin_work();
    eval {
      $sqlstr = "INSERT INTO EXPIDX (BENCH, NAME, FIELDS) VALUES (?, ?, ?)";
      $obj->{dbh}->do($sqlstr, $bench->id(), "", $idxstr);
      $sqlstr = "SELECT * FROM EXPIDX WHERE BENCH = ? AND FIELDS = ?";
      $sth = $obj->{dbh}->do($sqlstr, $bench->id(), $idxstr);
      $row = $sth->fetchrow_hashref();
      die "sql select failed: $sqlstr\n" if (!defined $row);
      my $name = sprintf "INTODB_IDX_%d_%d", $bench->id(), $row->{ID};
      $sqlstr = "UPDATE EXPIDX SET NAME = ? WHERE BENCH = ? AND ID = ?";
      $obj->{dbh}->do($sqlstr, $name, $bench->id(), $row->{ID});
      $sqlstr = "SELECT * FROM EXPIDX WHERE BENCH = ? AND FIELDS = ?";
      $sth = $obj->{dbh}->do($sqlstr, $bench->id(), $idxstr);
      $row = $sth->fetchrow_hashref();
      die "sql select failed: $sqlstr\n" if (!defined $row);

      $obj->{id} = $row->{ID};
      $obj->{name} = $row->{NAME};
      $obj->{fields} = $row->{FIELDS};

      $obj->make();

      $obj->{dbh}->commit();
    };
    if ($@) {
      my $errstr = $@;
      $obj->{dbh}->rollback();
      die "$errstr\n";
    }
  } else {
    $obj->{id} = $row->{ID};
    $obj->{name} = $row->{NAME};
    $obj->{fields} = $row->{FIELDS};
  }
  
  return $obj;
}

=item $ExpIdx = ExpIdx->getByName($Db, $name);

=cut

sub getByName {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $dbh = shift;
  my $obj = $class->SUPER::new($dbh, "EXPIDX");
  bless($obj, $class);
  my $name = shift;
  die "null index name\n" if (!defined $name);
  $name = uc($name);

  my $sqlstr = "SELECT * FROM EXPIDX WHERE NAME = ?";
  my $sth = $dbh->do($sqlstr, $name);
  my $row = $sth->fetchrow_hashref();
  die "experiment index not found: \"$name\"\n" if (!defined $row);

  $obj->{id} = $row->{ID};
  $obj->{name} = $row->{NAME};
  $obj->{fields} = $row->{FIELDS};
  $obj->{bench} = Benchmark->getById($dbh, $row->{BENCH});
  
  return $obj;
}

=item $int = $ExpIdx->id();

=cut

sub id {
  my $obj = shift;
  return $obj->{id};
}

=item $string = $ExpIdx->name();

=cut

sub name {
  my $obj = shift;
  return $obj->{name};
}

=item $Benchmark = $ExpIdx->bench();

=cut

sub bench {
  my $obj = shift;
  return $obj->{bench};
}

=item ($str1, ...) = $ExpIdx->getFieldNames();

=cut

sub getFieldNames {
  my $obj = shift;
  my $idxstr = $obj->{fields};
  $idxstr =~ s/^://;
  $idxstr =~ s/:$//;
  my @list = split(/:/, $idxstr);
  return @list;
}

=item $bool = $ExpIdx->check();

=cut

sub check {
  my $obj = shift;
  if ($obj->{dbh}->checkIndex($obj->name())) {
    return $TRUE;
  }
  return $FALSE;
}

=item $ExpIdx = $ExpIdx->make();

=cut

sub make {
  my $obj = shift;
  if (!$obj->check()) {
    my $view = $obj->{bench}->view();
    if ($view->check()) {
      my $sqlstr = sprintf "CREATE INDEX %s ON %s (%s)",
                           $obj->{name}, $view->table(),
                           join(", ", (map {"_$_"} ($obj->getFieldNames())));
      $obj->{dbh}->do($sqlstr);
    }
  }
  return $obj;
}

=item $ExpIdx = $ExpIdx->destroy();

=cut

sub destroy {
  my $obj = shift;
  if ($obj->check()) {
    my $sqlstr = sprintf "DROP INDEX %s", $obj->{name};
    $obj->{dbh}->do($sqlstr);
  }
  return $obj;
}

=item $ExpIdx->remove();

=cut

sub remove {
  my $obj = shift;
  my $sqlstr = "DELETE FROM EXPIDX WHERE ID = ?";
  $obj->{dbh}->begin_work();
  eval {
    $obj->{dbh}->do($sqlstr, $obj->{id});
    $obj->destroy();
    $obj->{dbh}->commit();
  };
  if ($@) {
    my $errstr = $@;
    $obj->rollback();
    die "$errstr\n";
  }
  $obj->{id} = undef;
  $obj->{bench} = undef;
  $obj->{name} = undef;
  $obj->{bench} = undef;
  $obj->{dbh} = undef;
  return $obj;
}

=back

=head3 Class Experiment: DBTable

=over

=cut

package Experiment;
our @ISA = qw(DBTable);

=item Experiment->create($Db);

=cut

sub create {
  my $proto = shift;
  my $dbh = shift;
  my $sqlstr = "CREATE TABLE IF NOT EXISTS " .
               "EXPERIMENT ( " .
               "  ID INTEGER NOT NULL PRIMARY KEY ASC AUTOINCREMENT, " .
               "  BENCH INTEGER NOT NULL REFERENCES BENCHMARK (ID) " .
               "                         ON DELETE RESTRICT, " .
               "  STR TEXT NOT NULL, " .
               "  OUT INTEGER NOT NULL, " .
               "  UNIQUE (BENCH, STR) " .
               ")";

  $dbh->do($sqlstr);
}

=item $Experiment = Experiment->new($Benchmark, $data_hash);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $bench = shift;
  my $obj = $class->SUPER::new($bench->database(), "FIELD");
  bless($obj, $class);
  my $data = shift;

  my @Fields = $bench->getFieldNames();
  my @Keys = $bench->getKeyFieldNames();

  foreach my $k (@Keys) {
    if (!defined $data->{$k}) {
      die "missing key field \"$k\" in experiment data\n";
    }
  }
  foreach my $k (@Fields) {
    if (!defined $data->{$k}) {
      die "missing field \"$k\" in experiment data\n";
    }
  }
  foreach my $k (keys %$data) {
    if (!grep {$_ eq $k} @Fields) {
      die "unknown field \"$k\" in experiment data\n";
    }
  }

  my @keystr = ();
  foreach my $k (@{$data}{@Keys}) {
     my $str = $k;
     $str =~ s/([^\w_])/sprintf("&%d;",ord($1))/ge;
     push(@keystr, $str);
  }
  my $idstr = join("::", @keystr);

  $obj->{id} = undef;
  $obj->{bench} = $bench;
  $obj->{idstr} = $idstr;
  $obj->{outlier} = 0;
  $obj->{discarded} = 0;

  my $sqlstr = "SELECT * FROM EXPERIMENT WHERE BENCH = ? AND STR = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $bench->id(), $idstr);
  my $row = $sth->fetchrow_hashref();
  if (defined $row) {
    $obj->{id} = $row->{ID};
    $obj->{outlier} = $row->{OUT};
    $obj->{discarded} = 1;
  } else {
    $sqlstr = "INSERT INTO EXPERIMENT (BENCH, STR, OUT) VALUES (?, ?, ?)";
    $obj->{dbh}->do($sqlstr, $bench->id(), $idstr, 0);
    $sqlstr = "SELECT * FROM EXPERIMENT WHERE BENCH = ? AND STR = ?";
    $sth = $obj->{dbh}->do($sqlstr, $bench->id(), $idstr);
    $row = $sth->fetchrow_hashref();
    if (!defined $row) {
      print STDERR "$sqlstr\n";
      die "sql select failed\n";
    }
    $obj->{id} = $row->{ID};
  }

  return $obj;
}

=item $Experiment = Experiment->get($Benchmark, $id);

=cut

sub get {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $bench = shift;
  my $obj = $class->SUPER::new($bench->database(), "FIELD");
  bless($obj, $class);
  my $id = shift;


  $obj->{id} = undef;
  $obj->{bench} = $bench;
  $obj->{idstr} = undef;
  $obj->{outlier} = undef;
  $obj->{discarded} = 1;

  my $sqlstr = "SELECT * FROM EXPERIMENT WHERE BENCH = ? AND ID = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $bench->id(), $id);
  my $row = $sth->fetchrow_hashref();
  if (!defined $row) {
    die "unknown experiment id: \"$id\"\n";
  }
  $obj->{id} = $row->{ID};
  $obj->{idstr} = $row->{STR};
  $obj->{outlier} = $row->{OUT};
  $obj->{discarded} = 1;

  return $obj;
}

=item $Experiment->remove();

=cut

sub remove {
  my $obj = shift;

  my $view = $obj->{bench}->view();
  $obj->{dbh}->begin_work();
  eval {
    $view->remove($obj);
    my $sqlstr = "DELETE FROM EXPERIMENT WHERE BENCH = ? AND ID = ?";
    $obj->{dbh}->do($sqlstr, $obj->{bench}->id(), $obj->{id});
    $obj->{dbh}->commit();
  };
  if ($@) {
    my $errstr = $@;
    $obj->{dbh}->rollback();
    die "$errstr\n";
  }
  
  $obj->{id} = undef;
  $obj->{bench} = undef;
  $obj->{idstr} = undef;
  $obj->{outlier} = undef;
  $obj->{discarded} = undef;
  return $obj;
}

=item Experiment->removeId($Benchmark, $id1, ..., $idn)

=cut

sub removeId {
  my $proto = shift;
  my $bench = shift;
  my @idlist = @_;
  die "no experiment id specified\n" if (!@idlist);
  my %id_hash;
  foreach my $i (@idlist) {
    if ($i =~ /^\d+$/) {
      $id_hash{$i} = 1;
    } else {
      die "invalid experiment id: $i\n";
    }
  }
  foreach my $id (keys %id_hash) {
    eval {Experiment->get($bench, $id)->remove()};
    warn "removal failed for id ${id}: $@\n" if ($@);
  }
}

=item Experiment->removeSelection($Benchmark, "<column><op><value", ...);

=cut

sub removeSelection {
  my $proto = shift;
  my $bench = shift;
  my $dbh = $bench->database();
  my $view = $bench->view();
  my @fields = $bench->getFields();
  my @cfields = ("BENCH", "EXP", "OUT", (map {"_" . $_->name()} @fields));
  my @conditions = @_;
  die "no condition specified\n" if (!@conditions);
  my %select;
  foreach my $c (@conditions) {
    my ($col, $val, $op);
    if ($c =~ /^([\w_]+)<>(\S.*)$/) {
      $col = uc($1); $val = $2; $op = "<>";
    } elsif ($c =~ /^([\w_]+)<=(\S.*)$/) {
      $col = uc($1); $val = $2; $op = "<=";
    } elsif ($c =~ /^([\w_]+)>=(\S.*)$/) {
      $col = uc($1); $val = $2; $op = ">=";
    } elsif ($c =~ /^([\w_]+)<(\S.*)$/) {
      $col = uc($1); $val = $2; $op = "<";
    } elsif ($c =~ /^([\w_]+)>(\S.*)$/) {
      $col = uc($1); $val = $2; $op = ">";
    } elsif ($c =~ /^([\w_]+)==(\S.*)$/) {
      $col = uc($1); $val = $2; $op = "=";
    } elsif ($c =~ /^([\w_]+)=(\S.*)$/) {
      $col = uc($1); $val = $2; $op = "=";
    } elsif ($c =~ /^([\w_]+)\!=(\S.*)$/) {
      $col = uc($1); $val = $2; $op = "<>";
    } elsif ($c =~ /^([\w_]+)\~(\S.*)$/) {
      $col = uc($1); $val = $2; $op = "like";
    } elsif ($c =~ /^([\w_]+)\!\~(\S.*)$/) {
      $col = uc($1); $val = $2; $op = "not like";
    } else {
      die "unrecognized condition: $c\n";
    }
    my ($field) = (grep {$col eq $_->name()} @fields);
    if (!defined $field && !grep {$col eq $_} @cfields) {
      die "invalid column name: \"$col\"\n";
    }
    if (!defined $field) {
      if ($col eq "OUT") {
        die "invalid value: \"$val\"\n"
          if (!defined(Check::isInteger($val,[0, 1])));
      } else {
        die "invalid value: \"$val\"\n"
          if (!defined(Check::isInteger($val,[0, undef])));
      }
      $select{$col} = [] if (!exists $select{$col});
      push(@{$select{$col}}, [$op, $val]);
    } elsif ($field->numeric()) {
      die "invalid value: \"$val\"\n" if (!defined(Check::isInteger($val,[])));
      $select{$col} = [] if (!exists $select{$col});
      push(@{$select{$col}}, [$op, $val]);
    } else {
      $select{$col} = [] if (!exists $select{$col});
      push(@{$select{$col}}, [$op, $val]);
    }
  }

  if ($view->check()) {
    my @condlist = ();
    my @args = ();
    foreach my $c (keys %select) {
      foreach my $i (@{$select{$c}}) {
        push(@condlist, join(" ", $c, $i->[0], "?"));
        push(@args, $i->[1]);
      }
    }
    my $sqlstr = "SELECT DISTINCT EXP FROM " . $view->table() .
                 " WHERE BENCH = ? AND " . join(" AND ", @condlist);
    my $sth = $dbh->do($sqlstr, $bench->id(), @args);
    my @explist = ();
    my $row = $sth->fetchrow_hashref();
    while (defined $row) {
      push(@explist, $row->{ID});
      $row = $sth->fetchrow_hashref();
    }
    while (@explist) {
      my @sublist = ();
      if ($#explist >= 512) {
        @sublist = @explist[0 .. 511];
        @explist = @explist[512 .. $#explist];
      } else {
        @sublist = @explist;
        @explist = ();
      }
      $sqlstr = sprintf "DELETE FROM %s WHERE BENCH = ? AND EXP IN (%s)",
                $view->table(), join(", ", @sublist);
      $sth = $dbh->do($sqlstr, $bench->id());
      $sqlstr = sprintf "DELETE FROM EXPERIMENT WHERE BENCH = ? AND ID IN (%s)",
                join(", ", @sublist);
      $sth = $dbh->do($sqlstr, $bench->id());
    }
  }
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item $int = $Experiment->id();

=cut

sub id {
  my $obj = shift;
  return $obj->{id};
}

=item $Benchmark = $Experiment->bench();

=cut

sub bench {
  my $obj = shift;
  return $obj->{bench};
}

=item $bool = $Experiment->existed();

=cut

sub existed {
  my $obj = shift;
  return ($obj->{discarded})? 1: 0;
}

=item $bool = $Experiment->outlier();

=cut

sub outlier {
  my $obj = shift;
  return $obj->{outlier};
}

=item $bool = $Experiment->getOutlier();

=cut

sub getOutlier {
  my $obj = shift;
  my $sqlstr = "SELECT OUT FROM EXPERIMENT WHERE ID = ?";
  my $sth = $obj->{dbh}->do($sqlstr, $obj->{id});
  my $row = $sth->fetchrow_hashref();
  if (!defined $row) {
    print STDERR "$sqlstr\n";
    die "sql select failed\n";
  }
  $obj->{outlier} = $row->{OUT};
  return $obj->{outlier};
}

=item $Experiment = $Experiment->setOutlier($bool);

=cut

sub setOutlier {
  my $obj = shift;
  my $bool = shift;
  $bool = ($bool)? 1: 0;
  my $orig = $obj->{outlier};
  my $sqlstr = "UPDATE EXPERIMENT SET OUT = ? WHERE ID = ?";
  $obj->{dbh}->begin_work();
  eval {
    $obj->{dbh}->do($sqlstr, $bool, $obj->{id});
    $obj->{outlier} = $bool;
    $obj->{bench}->view()->updateOutlier($obj);
    $obj->{dbh}->commit();
  };
  if ($@) {
    my $errstr = $@;
    $obj->{dbh}->rollback();
    $obj->{outlier} = $orig;
    die "$errstr\n";
  }
    
  return $obj;
}

=back

=head3 Class DataView: DBTable

=over

=cut

package DataView;
our @ISA = qw(DBTable);

=item $DataView = DataView->new($Benchmark);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $bench = shift;
  my $obj = $class->SUPER::new($bench->database(), $bench->getViewName());
  bless($obj, $class);
  $obj->{bench} = $bench;
  $obj->{insert} = undef;
  return $obj;
}

=item $bool = $DataView->check();

=cut

sub check {
  my $obj = shift;
  if ($obj->{dbh}->checkTable($obj->table())) {
    return $TRUE;
  }
  return $FALSE;
}

=item $Dataview = $DataView->create();

=cut

sub create {
  my $obj = shift;
  if (!$obj->check()) {
    my $bench = $obj->{bench};
    my $dbh = $obj->database();
    my $sqlstr = "CREATE TABLE " . $obj->table() . " (" .
               "  BENCH INTEGER NOT NULL REFERENCES BENCHMARK (ID) " .
               "                         ON DELETE RESTRICT, " .
               "  EXP INTEGER NOT NULL REFERENCES EXPERIMENT (ID) " .
               "                         ON DELETE RESTRICT, " .
               "  OUT INTEGER NOT NULL";
    my @fnames = $bench->getFieldNames();
    die "no fields defined for benchmark\n" if (!@fnames);
    foreach my $field ($bench->getFields()) {
      if ($field->numeric()) {
        $sqlstr .= ", _" . $field->name() . " NUMERIC NOT NULL";
      } else {
        $sqlstr .= ", _" . $field->name() . " TEXT NOT NULL";
      }
    }
    $sqlstr .= ", PRIMARY KEY (EXP, BENCH)";
    $sqlstr .= ")";
    $dbh->do($sqlstr);
    # should create indexes here...
    my @indexes = ExpIdx->list($bench);
    foreach my $idx (@indexes) {
      $idx->make();
    }
  }
  return $obj;
}

=item $DataView = $DataView->destroy();

=cut

sub destroy {
  my $obj = shift;
  if ($obj->check()) {
    # should remove indexes first...
    my @indexes = ExpIdx->list($obj->{bench});
    foreach my $idx (@indexes) {
      $idx->destroy();
    }
    my $sqlstr = "DROP TABLE " . $obj->table();
    $obj->{dbh}->do($sqlstr);
  }
  return $obj;
}

=item $DataView = $DataView->insert($Experiment, $data_hash);

=cut

sub insert {
  my $obj = shift;
  my $exp = shift;
  my $data = shift;

  my @fnames = $obj->{bench}->getFieldNames();
  if (!$obj->{insert}) {
    $obj->create() if (!$obj->check());
    my $sqlstr = "INSERT INTO " . $obj->table() .
                 " (BENCH, EXP, OUT, _" .join(", _", @fnames). ") " .
                 " VALUES (?, ?, ?, " .join(", ", ("?") x ($#fnames + 1)). ")";
    $obj->{insert} = $obj->{dbh}->prepare($sqlstr);
  }
  my @values = map {$data->{$_}} @fnames;
  $obj->{dbh}->execute($obj->{insert},
                       $exp->bench()->id(), $exp->id(), $exp->outlier(),
                       @values);
  return $obj;
}

=item $DataView = $DataView->remove($Experiment);

=cut

sub remove {
  my $obj = shift;
  my $exp = shift;
  my $sqlstr = "DELETE FROM " . $obj->table() . " WHERE BENCH = ? AND EXP = ?";
  $obj->{dbh}->do($sqlstr, $exp->bench()->id(), $exp->id());
  return $obj;
}

=item $DataView = $DataView->removeAll();

=cut

sub removeAll {
  my $obj = shift;
  if ($obj->check()) {
    my $sqlstr = "DELETE FROM " . $obj->table();
    $obj->{dbh}->do($sqlstr);
  }
  return $obj;
}

=item $DataView = $DataView->updateOulier($Experiment);

=cut

sub updateOutlier {
  my $obj = shift;
  my $exp = shift;
  my $sqlstr = "UPDATE " . $obj->table() .
                 " SET OUT = ? WHERE BENCH = ? AND EXP = ?";
  $obj->{dbh}->do($sqlstr, $exp->outlier(), $exp->bench()->id(), $exp->id());
  return $obj;
}

=back

=head3 Class DB

=over

=cut

package DB;
our @ISA = qw();

=item $Db = DB->new($file [,$bool_create]);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $file = shift;
  my $create = shift;

  my $obj = {};
  if (ref($proto)) {
    $obj = $proto;
    $file = $obj->{file};
  }
  bless($obj, $class);

  die "null database file\n" if (!defined $file);
  die "database \"$file\" is already connected\n" if (defined $obj->{dbh});
  die "database \"$file\" already exists\n" if (-e $file && $create);
  die "invalid database file \"$file\"\n" if (! -f $file && !$create);

  my $newdb = DBI->connect("dbi:SQLite:dbname=$file", "", "");
  die "cannot create database \"$file\"\n" if (!defined $newdb && $create);
  die "cannot connect to database \"$file\"\n" if (!defined $newdb);

  $newdb->{FetchHashKeyName} = 'NAME_uc';
  $obj->{file} = $file;
  $obj->{dbh} = $newdb;
  $obj->{info} = undef;

  my ($sqlstr, $sth);
  $sqlstr = "PRAGMA cache_size = 200000";
  $sth = $newdb->prepare($sqlstr);
  warn "cannot prepare db pragma \"$sqlstr\"\n" if (!defined($sth));
  $sth->execute() if (defined($sth));
  $sth->finish() if (defined($sth));
  $sth = undef;

  if (defined $TMPDIR) {
    $sqlstr = "PRAGMA temp_store_directory = '${TMPDIR}'";
    $sth = $newdb->prepare($sqlstr);
    warn "cannot prepare db pragma \"$sqlstr\"\n" if (!defined($sth));
    $sth->execute() if (defined($sth));
    $sth->finish() if (defined($sth));
    $sth = undef;
  }

  if ($create) {
    eval {
      $obj->{info} = DBInfo->create($obj);
      Benchmark->create($obj);
      Field->create($obj);
      ExpKey->create($obj);
      ExpIdx->create($obj);
      Experiment->create($obj);
    };
    if ($@) {
      my $errstr = $@;
      $obj->disconnect();
      unlink $file;
      die "$errstr\n";
    }
  } else {
    $obj->{info} = DBInfo->new($obj);
  }

  my $dbv = $obj->{info}->getVersion();
  if ($dbv ne $DBVERSION) {
    $obj->disconnect();
    die "incompatible db format in \"$file\": $dbv != $DBVERSION\n";
  }

  return $obj;
}

=item $Db->DESTROY()

=cut

sub DESTROY {
  my $obj = shift;
  $obj->{dbh}->disconnect() if (defined $obj->{dbh});
  $obj->{dbh} = undef;
  return $obj;
}

=item $Db = $Db->connect();

=cut

sub connect {
  my $obj = shift;
  return $obj->new(undef, undef);
}

=item $Db = $Db->disconnect();

=cut

sub disconnect {
  my $obj = shift;
  $obj->{dbh}->disconnect() if (defined $obj->{dbh});
  $obj->{dbh} = undef;
  return $obj;
}

=item $sth = $Db->prepare($sql_string);

=cut

sub prepare {
  my $obj = shift;
  my $str = shift;
  my $file = $obj->{file};
  die "database \"$file\" is not connected\n" if (!defined $obj->{dbh});
  my $sth = $obj->{dbh}->prepare($str);
  if (!$sth) {
    my $errstr = $obj->{dbh}->errstr();
    die "sql prepare on database \"$file\" failed ($errstr): $str\n";
  }
  #$sth->{private_intodb_sqlstr} = $str;
  return $sth;
}

=item $sth = DB->execute($sth, @args);

=cut

sub execute {
  my $proto = shift;
  my $sth = shift;
  my @args = @_;
  die "null sql statement\n" if (!defined $sth);
  my $sqlstr = $sth->{Statement};
  #my $sqlstr = $sth->{private_intodb_sqlstr};
  my $rc = $sth->execute(@args);
  if (!$rc) {
    my $errstr = $sth->errstr();
    die "sql execution failed ($errstr): $sqlstr\n";
  }
  return $sth;
}

=item $sth = $Db->do($sql_string, @args);

=cut

sub do {
  my $obj = shift;
  my $str = shift;
  my @args = @_;
  return $obj->execute($obj->prepare($str), @args);
}

=item $Db = $Db->begin_work();

=cut

sub begin_work {
  my $obj = shift;
  $obj->{dbh}->begin_work();
  return $obj;
}

sub begin {
  my $obj = shift;
  return $obj->begin_work();
}

=item $Db = $Db->commit();

=cut

sub commit {
  my $obj = shift;
  local $obj->{dbh}->{RaiseError} = 1;
  $obj->{dbh}->commit();
  return $obj;
}

=item $Db = $Db->rollback();

=cut

sub rollback {
  my $obj = shift;
  $obj->{dbh}->rollback();
  return $obj;
}

=item $string = $Db->quote($literal);

=cut

sub quote {
  my $obj = shift;
  my $str = shift;
  return $obj->{dbh}->quote($str);
}

=item $dbh = $Db->handle();

=cut 

sub handle {
  my $obj = shift;
  return $obj->{dbh};
}

=item $bool = $Db->checkTable($table_name);

=cut

sub checkTable {
  my $obj = shift;
  my $name = shift;
  my $sqlstr = "SELECT TBL_NAME FROM SQLITE_MASTER WHERE TYPE = ? AND NAME = ?";
  my $sth = $obj->do($sqlstr, "table", $name);
  my $row = $sth->fetchrow_hashref();
  return undef if (!defined $row);
  return $TRUE;
}

=item $bool = $Db->checkIndex($index_name[, $table_name]);

=cut

sub checkIndex {
  my $obj = shift;
  my $name = shift;
  my $tname = shift;

  my $sqlstr = "SELECT TBL_NAME FROM SQLITE_MASTER WHERE TYPE = ? AND NAME = ?";
     $sqlstr .= " AND TBL_NAME = ?" if (defined $tname);
  my @args = ("index", $name);
     push(@args, $tname) if (defined $tname);
  my $sth = $obj->do($sqlstr, @args);
  my $row = $sth->fetchrow_hashref();
  return undef if (!defined $row);
  return $TRUE;
}

=item $Db = $Db->enforceForeignKey($table,[$fld_names],$frgn_tab,[frgn_fields]);

=cut

sub enforceForeignKey {
  my $obj = shift;
  my $table = shift;
  my $fields = shift;
  my $f_table = shift;
  my $f_fields = shift;

  my $sqlstr;
  my $sth;

  my $tname = "T_${table}_${f_table}";
  my @new_f = (); my @old_f = ();
  my @for_f = (); my @loc_f = ();
  my @cond  = (); my @dcond = ();
  for (my $i = 0; $i <= $#$fields; $i ++) {
    push(@new_f, "NEW." . $fields->[$i]);
    push(@old_f, "OLD." . $f_fields->[$i]);
    push(@loc_f, "${table}." . $fields->[$i]);
    #push(@loc_f, $fields->[$i]);
    push(@for_f, "${f_table}." . $f_fields->[$i]);
    #push(@for_f, $f_fields->[$i]);
    push(@cond, $for_f[$i] . " = " . $new_f[$i]);
    push(@dcond, $loc_f[$i] . " = " . $old_f[$i]);
  }

  $sqlstr = "CREATE TRIGGER I${tname} " .
            "  BEFORE INSERT ON ${table} " .
            "  FOR EACH ROW BEGIN " .
            "    SELECT CASE ".
            #"    WHEN ((SELECT DISTINCT " . join(", ", @for_f) .
            "    WHEN ((SELECT COUNT(*) " .
            "             FROM ${f_table} " .
            #"            WHERE " . join(" AND ", @cond) . ") IS NULL) " .
            "            WHERE " . join(" AND ", @cond) . ") = 0) " .
            "    THEN RAISE(ABORT, " .
            "'insert on ${table} violates foreign key constraint I${tname}') " .
            "    END; " .
            "  END;";
  $obj->do($sqlstr);

  $sqlstr = "CREATE TRIGGER U${tname} " .
            #"  BEFORE UPDATE OF " . join(", ", @loc_f) . " ON ${table} " .
            "  BEFORE UPDATE ON ${table} " .
            "  FOR EACH ROW BEGIN " .
            "    SELECT CASE ".
            #"    WHEN ((SELECT DISTINCT " . join(", ", @for_f) .
            "    WHEN ((SELECT COUNT(*) " .
            "             FROM ${f_table} " .
            #"            WHERE " . join(" AND ", @cond) . ") IS NULL) " .
            "            WHERE " . join(" AND ", @cond) . ") = 0) " .
            "    THEN RAISE(ABORT, " .
            "'update of ${table} violates foreign key constraint U${tname}') " .
            "    END; " .
            "  END;";
  $obj->do($sqlstr);

  $sqlstr = "CREATE TRIGGER D${tname} " .
            "  BEFORE DELETE ON ${f_table} " .
            "  FOR EACH ROW BEGIN " .
            "    SELECT CASE ".
            #"    WHEN ((SELECT DISTINCT " . join(", ", @loc_f) .
            "    WHEN ((SELECT COUNT(*) " .
            "             FROM ${table} " .
            #"            WHERE " . join(" AND ", @dcond) . ") IS NOT NULL) " .
            "            WHERE " . join(" AND ", @dcond) . ") <> 0) " .
            "    THEN RAISE(ABORT, " .
        "'delete from ${f_table} violates foreign key constraint D${tname}') " .
            "    END; " .
            "  END;";
  $obj->do($sqlstr);

  return $obj;
}

=item $Dbinfo = $Db->info();

=cut

sub info {
  my $obj = shift;
  return $obj->{info};
}

=back

=cut

#################################################
#################################################
# CURVE FUNCTIONS
#################################################
#################################################

=head2 CURVE FUNCTIONS

=head3 Class CurveParam

=over

=cut

package CurveParam;
our @ISA = qw();

=item CurveParam->parseRc($rcConfig, [$key1, ...]);

=cut

sub parseRc {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $rcConfig = shift;
  my $AutoListVar = $class . "::AutoList";
  my $ListVar = $class . "::List";
  my $HashVar = $class . "::Hash";

  my $keylist = shift;
  my $name = lc($class);

  return if (!defined $rcConfig);

  if (grep {$_ eq "define"} @$keylist) {
    my $has_defined = 0;
    foreach my $v ($rcConfig->getValues($class, "define", -1)) {
      eval {$class->register($v)};
      die "rc parse error in section [$class]: \"$v\": $@\n" if ($@);
      $has_defined = 1;
    }
    if ($has_defined) {
      no strict "refs";
      @$ListVar = sort keys %$HashVar;
    }
  }

  if (grep {$_ eq "autolist"} @$keylist) {
    my $str = join(",", $rcConfig->getValues($class, "autolist", -1));
    if ($str =~ /\S/) {
       no strict "refs";
       my $list = undef; eval {
       $list = Check::isList($str, [\&Check::isWord, [undef,  [@$ListVar]]])};
       die "rc parse error in section [$class]: \"autolist\": $@\n" if ($@);
       @$AutoListVar = @$list if (defined $list && $#$list >= 0);
    }
  }
}

=item ($name1, ...) = CurveParam->list();

=cut

sub list {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $ListVar = $class . "::List";
  no strict "refs";
  return @$ListVar;
}

=item $bool = CurveParam->exists($name);

=cut

sub exists {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = lc(shift(@_));
  my $HashVar = $class . "::Hash";
  no strict "refs";
  return 1 if (exists $HashVar->{$name});
  return 0;
}

=item $name = CurveParam->check($name);

=cut

sub check {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = lc(shift(@_));
  my $HashVar = $class . "::Hash";
  no strict "refs";
  return $name if (exists $HashVar->{$name});
  return undef;
}

=item $CurveParam = CurveParam->new($name, $hash, $auto, $list);

=item $CurveParam = CurveParam->new($idx, $hash, $auto, $list);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);

  my $name = shift;
  my $hash = shift;
  my $list = shift;
  my $auto = shift;

  $obj->{hash} = $hash;
  $obj->{list} = $list;
  $obj->{auto} = $auto;

  my $idname = lc($class);
  die "null $idname\n" if (!defined $name);
  my $idx = Check::isInteger($name, [0, undef]);
  if (defined $idx) {
    $idx = $idx % ($#$auto + 1);
    $name = $auto->[$idx];
  }
  die "invalid $idname \"$name\"\n" if (!exists $hash->{$name});

  $obj->{name}   = $name;
  $obj->{desc}   = $hash->{$name}->[1];
  $obj->{jgraph} = $hash->{$name}->[2];

  return $obj;
}

=item $string = $CurveParam->name();

=cut

sub name {
  my $obj = shift;
  return $obj->{name};
}

=item $string = $CurveParam->desc();

=cut

sub desc {
  my $obj = shift;
  return $obj->{desc};
}

=item $string = $CurveParam->jgraph();

=cut

sub jgraph {
  my $obj = shift;
  return $obj->{jgraph};
}

=back

=head3 Class Justification: CurveParam

=over

=cut

package Justification;
our @ISA = qw(CurveParam);

# format: [$auto, $description, $jgraph_code]
our %Hash = (
  none         => [0, "none",         ""],
  top          => [1, "top",          "hjl vjb"],
  bottom       => [0, "bottom",       "hjl vjt"],
  left         => [0, "left",         "hjr vjc"],
  right        => [0, "right",        "hjl vjc"],
  top_left     => [0, "top left",     "hjl vjb"],
  top_right    => [0, "top right",    "hjr vjb"],
  bottom_left  => [0, "bottom left",  "hjl vjt"],
  bottom_right => [0, "bottom right", "hjr vjt"],
);

our @List = qw(none
               top bottom left right
               top_left top_right bottom_left bottom_right);
our @AutoList = grep {$Justification::Hash{$_}->[0]} @List;

=item $Justification = Justification->new($name);

=item $Justification = Justification->new($idx);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = shift;
  my $obj = $class->SUPER::new($name,
                               \%Justification::Hash,
                               \@Justification::List,
                               \@Justification::AutoList);
  bless($obj, $class);
  return $obj;
}

=back

=head3 Class AxisType: CurveParam

=over

=cut

package AxisType;
our @ISA = qw(CurveParam);

# format: [$auto, $description, $jgraph_code]
our %Hash = (
  numeric   => [1, "numeric",              ""],
  log2      => [0, "logarithmic, base 2",  "log log_base 2"],
  log10     => [0, "logarithmic, base 10", "log log_base 10"],
  category  => [0, "category",             ""],
);

our @List = qw(numeric log2 log10 category);
our @AutoList = grep {$AxisType::Hash{$_}->[0]} @List;

=item $AxisType = AxisType->new($name);

=item $AxisType = AxisType->new($idx);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = shift;
  my $obj = $class->SUPER::new($name,
                               \%AxisType::Hash,
                               \@AxisType::List,
                               \@AxisType::AutoList);
  bless($obj, $class);
  return $obj;
}

=back

=head3 Class Mark: CurveParam

=over

=cut

package Mark;
our @ISA = qw(CurveParam);

# format: [$auto, $description, $jgraph_code]
our %Hash = (
  auto           => [0, "auto",                   ""],
  none           => [0, "no mark",                "marktype none"],
  circle         => [1, "circle",                 "marktype cycle"],
  box            => [1, "box",                    "marktype box"],
  diamond        => [1, "diamond",                "marktype diamond"],
  triangle       => [1, "triangle",               "marktype triangle"],
  x              => [1, "x",                      "marktype x"],
  cross          => [1, "cross",                  "marktype cross"],
  ellipse        => [1, "ellipse",                "marktype ellipse"],
);

our @List = qw(auto none
               circle box diamond triangle x cross ellipse);
our @AutoList = grep {$Mark::Hash{$_}->[0]} @List;

=item $Mark = Mark->new($name);

=item $Mark = Mark->new($idx);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = shift;
  $name =~ s/^text=/text=/i;
  $class->register($name);
  my $obj = $class->SUPER::new($name,
                               \%Mark::Hash, \@Mark::List, \@Mark::AutoList);
  bless($obj, $class);
  return $obj;
}

=item Mark->register($name);

=cut

sub register {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = shift(@_);
  return if (defined(Check::isInteger($name, [0, undef])));
  if ($name =~ /^text=(.+)/i) {
    my $text = $1;
    my $key = "text=$text";
    $Mark::Hash{$key} = [0, "text: $text", "marktype text : $text"];
  }
}

=item $bool = Mark->exists($name)

=cut

sub exists {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = shift;
  $name =~ s/^text=/text=/i;
  $class->register($name);
  return $class->SUPER::exists($name);
}

=back

=head3 Class MarkScale: CurveParam

=over

=cut

package MarkScale;
our @ISA = qw(CurveParam);

# format: [$auto, $description, $jgraph_code]
our %Hash = (
  auto           => [0, "auto",                ""],
  s100           => [1, "100%",                "marksize 1 1"],
   s90           => [1, "90%",                 "marksize 0.9 0.9"],
   s80           => [1, "80%",                 "marksize 0.8 0.8"],
   s70           => [1, "70%",                 "marksize 0.7 0.7"],
   s60           => [1, "60%",                 "marksize 0.6 0.6"],
   s50           => [1, "50%",                 "marksize 0.5 0.5"],
   s40           => [1, "40%",                 "marksize 0.4 0.4"],
   s30           => [1, "30%",                 "marksize 0.3 0.3"],
   s20           => [1, "20%",                 "marksize 0.2 0.2"],
   s19           => [1, "19%",                 "marksize 0.19 0.19"],
   s18           => [1, "18%",                 "marksize 0.18 0.18"],
   s17           => [1, "17%",                 "marksize 0.17 0.17"],
   s16           => [1, "16%",                 "marksize 0.16 0.16"],
   s15           => [1, "15%",                 "marksize 0.15 0.15"],
   s14           => [1, "14%",                 "marksize 0.14 0.14"],
   s13           => [1, "13%",                 "marksize 0.13 0.13"],
   s12           => [1, "12%",                 "marksize 0.12 0.12"],
   s11           => [1, "11%",                 "marksize 0.11 0.11"],
   s10           => [1, "10%",                 "marksize 0.10 0.10"],
   s09           => [1, "9%",                  "marksize 0.09 0.09"],
   s08           => [1, "8%",                  "marksize 0.08 0.08"],
   s07           => [1, "7%",                  "marksize 0.07 0.07"],
   s06           => [1, "6%",                  "marksize 0.06 0.06"],
   s05           => [1, "5%",                  "marksize 0.05 0.05"],
   s04           => [1, "4%",                  "marksize 0.04 0.04"],
   s03           => [1, "3%",                  "marksize 0.03 0.03"],
   s02           => [1, "2%",                  "marksize 0.02 0.02"],
   s01           => [1, "1%",                  "marksize 0.01 0.01"],
);

our @List = qw(auto s100 s90 s80 s70 s60 s50 s40 s30 s20 s19 s18 s17 s16 
  s15 s14 s13 s12 s11 s10 s09 s08 s07 s06 s05 s04 s03 s02 s01);

our @AutoList = grep {$MarkScale::Hash{$_}->[0]} @List;

sub internalName {
  my $proto = shift;
  my $name = shift;
  return undef if (!defined $name);
  my $idx = Check::isInteger($name, [0, undef]);
  return $idx if (defined $idx);
  return $name if (exists $MarkScale::Hash{$name});
  if ($name =~ /^(\w+)#size=(\d+(\.\d+)?)(\/(\d+(\.\d+)?))?/i) {
    return lc($1);
  }
  if ($name =~ /^#size=(\d+(\.\d+)?)(\/(\d+(\.\d+)?))?/i) {
    return lc($name);
  }
  return undef;
}

=item MarkScale->register($name);

=cut

sub register {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = shift(@_);

  return if (defined(Check::isInteger($name, [0, undef])));
  return if (exists $MarkScale::Hash{$name});
  if ($name =~ /^(\w+)#size=(\d+(\.\d+)?)(\/(\d+(\.\d+)?))?/i) {
    my $key = $1;
    my $pct1 = $2;
    my $pct2 = $4? $5: $2;
    my $siz1 = $pct1 / 100.0;
    my $siz2 = $pct2 / 100.0;
    $MarkScale::Hash{$key} = [0,
       $4? "$key (size: ${pct1}/${pct2}%)": "$key (size: ${pct1}%)",
       "marksize $siz1 $siz2"];
  }
  if ($name =~ /^#size=(\d+(\.\d+)?)(\/(\d+(\.\d+)?))?/i) {
    my $key = lc($name);
    my $pct1 = $1;
    my $pct2 = $3? $4: $1;
    my $siz1 = $pct1 / 100.0;
    my $siz2 = $pct2 / 100.0;
    $MarkScale::Hash{$key} = [0,
       $4? "$key (size: ${pct1}/${pct2}%)": "$key (size: ${pct1}%)",
       "marksize $siz1 $siz2"];
  }
}

=item $MarkScale = MarkScale->new($name);

=item $MarkScale = MarkScale->new($idx);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = shift(@_);
  $class->register($name);
  my $realname = MarkScale->internalName($name);
  my $obj = $class->SUPER::new($name,
             \%MarkScale::Hash, \@MarkScale::List, \@MarkScale::AutoList);
  bless($obj, $class);
  return $obj;
}

=item $bool = MarkScale->exists($name)

=item $bool = MarkScale::exists($name)

=cut

sub exists {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $classcheck = eval {$class->isa("MarkScale")};
  my $name;
  if ($classcheck) {
    $name = shift;
  } else {
    $class = "MarkScale";
    $name = $proto;
  }
  $class->register($name);
  my $realname = MarkScale->internalName($name);
  return $class->SUPER::exists($realname);
}

=item $bool = MarkScale->check($name)

=item $bool = MarkScale::check($name)

=cut

sub check {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $classcheck = eval {$class->isa("MarkScale")};
  my $name;
  if ($classcheck) {
    $name = shift;
  } else {
    $class = "MarkScale";
    $name = $proto;
  }
  $class->register($name);
  my $realname = MarkScale->internalName($name);
  return $realname if $class->SUPER::exists($realname);
  return undef;
}

=back

=head3 Class TextMarkScale: CurveParam

=over

=cut

package TextMarkScale;
our @ISA = qw(CurveParam);

# format: [$auto, $description, $jgraph_code]
our %Hash = (
  auto           => [0, "auto",                ""],
   s19           => [1, "19pt",                "fontsize 19"],
   s18           => [1, "18pt",                "fontsize 18"],
   s17           => [1, "17pt",                "fontsize 17"],
   s16           => [1, "16pt",                "fontsize 16"],
   s15           => [1, "15pt",                "fontsize 15"],
   s14           => [1, "14pt",                "fontsize 14"],
   s13           => [1, "13pt",                "fontsize 13"],
   s12           => [1, "12pt",                "fontsize 12"],
   s11           => [1, "11pt",                "fontsize 11"],
   s10           => [1, "10pt",                "fontsize 10"],
   s9            => [1, "9pt",                 "fontsize 9"],
   s8            => [1, "8pt",                 "fontsize 8"],
   s7            => [1, "7pt",                 "fontsize 7"],
   s6            => [1, "6pt",                 "fontsize 6"],
   s5            => [1, "5pt",                 "fontsize 5"],
   s4            => [1, "4pt",                 "fontsize 4"],
   s3            => [1, "3pt",                 "fontsize 3"],
   s2            => [1, "2pt",                 "fontsize 2"],
   s1            => [1, "1pt",                 "fontsize 1"],
);

our @List = qw(auto s19 s18 s17 s16 s16 s14 s13 s12 s11 s10
  s9 s8 s7 s6 s5 s4 s3 s2 1);
our @AutoList = grep {$TextMarkScale::Hash{$_}->[0]} @List;

sub internalName {
  my $proto = shift;
  my $name = shift;
  return undef if (!defined $name);
  my $idx = Check::isInteger($name, [0, undef]);
  return $idx if (defined $idx);
  return $name if (exists $TextMarkScale::Hash{$name});
  if ($name =~ /^(\w+)#size=(\d+)/i) {
    return lc($1);
  }
  if ($name =~ /^#size=(\d+)/i) {
    return lc($name);
  }
  return undef;
}

=item TextMarkScale->register($name);

=cut

sub register {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = shift(@_);

  return if (defined(Check::isInteger($name, [0, undef])));
  return if (exists $TextMarkScale::Hash{$name});
  if ($name =~ /^(\w+)#size=(\d+)/i) {
    my $key = $1;
    my $pts = $2;
    $TextMarkScale::Hash{$key} = [0, "$key (size: ${pts}pt)", "fontsize $pts"];
  }
  if ($name =~ /^#size=(\d+)/i) {
    my $key = lc($name);
    my $pts = $1;
    $TextMarkScale::Hash{$key} = [0, "$key (size: ${pts}pt)", "fontsize $pts"];
  }
}


=item $TextMarkScale = TextMarkScale->new($name);

=item $TextMarkScale = TextMarkScale->new($idx);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = shift;
  $class->register($name);
  my $realname = TextMarkScale->internalName($name);
  my $obj = $class->SUPER::new($name,
     \%TextMarkScale::Hash, \@TextMarkScale::List, \@TextMarkScale::AutoList);
  bless($obj, $class);
  return $obj;
}

=item $bool = TextMarkScale->exists($name)

=item $bool = TextMarkScale::exists($name)

=cut

sub exists {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $classcheck = eval {$class->isa("TextMarkScale")};
  my $name;
  if ($classcheck) {
    $name = shift;
  } else {
    $class = "TextMarkScale";
    $name = $proto;
  }
  $class->register($name);
  my $realname = MarkScale->internalName($name);
  return $class->SUPER::exists($realname);
}

=item $bool = TextMarkScale->check($name)

=item $bool = TextMarkScale::check($name)

=cut

sub check {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $classcheck = eval {$class->isa("TextMarkScale")};
  my $name;
  if ($classcheck) {
    $name = shift;
  } else {
    $class = "TextMarkScale";
    $name = $proto;
  }
  $class->register($name);
  my $realname = MarkScale->internalName($name);
  return $realname if $class->SUPER::exists($realname);
  return undef
}

=back

=head3 Class Line: CurveParam

=over

=cut

package Line;
our @ISA = qw(CurveParam);

# format: [$auto, $description, $jgraph_code]
our %Hash = (
  none           => [0, "no line",                "linetype none"],
  solid          => [1, "solid line",             "linetype solid"],
  dotted         => [1, "dotted line",            "linetype dotted"],
  dashed         => [1, "dashed line",            "linetype dashed"],
  longdash       => [1, "long dashed line",       "linetype longdash"],
  dotdash        => [1, "dot-dash line",          "linetype dotdash"],
  dotdotdash     => [1, "dot-dot-dash line",      "linetype dotdotdash"],
  dotdotdashdash => [1, "dot-dot-dash-dash line", "linetype dotdotdashdash"],
  xbar           => [0, "vertical bar",           "marktype xbar"],
  xbarval        => [0, "vertical bar value",     "marktype text :"],
  ybar           => [0, "horizontal bar",         "marktype ybar"],
  ybarval        => [0, "horizontal bar value",   "marktype text :"],
);

our @List = qw(none
               solid dotted dashed longdash
               dotdash dotdotdash dotdotdashdash
               xbar xbarval ybar ybarval);
our @AutoList = grep {$Line::Hash{$_}->[0]} @List;

=item $Line = Line->new($name);

=item $Line = Line->new($idx);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = shift;
  my $obj = $class->SUPER::new($name,
                               \%Line::Hash, \@Line::List, \@Line::AutoList);
  bless($obj, $class);
  return $obj;
}

=back

=head3 Class Color: CurveParam

=over

=cut

package Color;
our @ISA = qw(CurveParam);

our %RGB = (
  black   => [0x00, 0x00, 0x00],
  red     => [0xFF, 0x00, 0x00],
  lime    => [0x00, 0xFF, 0x00],
  blue    => [0x00, 0x00, 0xFF],
  gray    => [0x80, 0x80, 0x80],
  purple  => [0x80, 0x00, 0x80],
  green   => [0x00, 0x80, 0x00],
  aqua    => [0x00, 0xFF, 0xFF],
  silver  => [0xC0, 0xC0, 0xC0],
  maroon  => [0x80, 0x00, 0x00],
  olive   => [0x80, 0x80, 0x00],
  teal    => [0x00, 0x80, 0x80],

  white   => [0xFF, 0xFF, 0xFF],
  fuchsia => [0xFF, 0x00, 0xFF],
  yellow  => [0xFF, 0xFF, 0x00],
  navy    => [0x00, 0x00, 0x80],
);

our @AutoList = qw(black red lime blue
                   gray purple green aqua
                   silver maroon olive teal);

our @List = (@AutoList, "white", "fuchsia", "yellow", "navy");

# format: [$auto, $description, $jgraph_code]
our %Hash;
foreach my $c (@Color::List) {
  $Color::Hash{$c} = [
    (scalar grep {$c eq $_} @Color::AutoList)? 1: 0,
    $c,
    sprintf("color %f %f %f", (map {$_ / 255.0} @{$Color::RGB{$c}}))
  ];
}

=item Color->register($name);

=cut

sub register {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = lc(shift(@_));
  return if (defined(Check::isInteger($name, [0, undef])));
  return if (exists $Color::Hash{$name});
  if ($name =~ /^r(\d+)g(\d+)b(\d+)$/) {
    my ($r, $g, $b) = ($1, $2, $3);
    $Color::RGB{$name} = [$r, $g, $b];
    $Color::Hash{$name} = [0, $name,
      sprintf("color %f %f %f", (map {$_ / 255.0} @{$Color::RGB{$name}}))];
    return;
  }
  if ($name =~ /^rx([\da-f]+)gx([\da-f]+)bx([\da-f]+)$/) {
    my ($r, $g, $b) = (hex("0x$1"), hex("0x$2"), hex("0x$3"));
    $Color::RGB{$name} = [$r, $g, $b];
    $Color::Hash{$name} = [0, $name,
      sprintf("color %f %f %f", (map {$_ / 255.0} @{$Color::RGB{$name}}))];
    return;
  }
  if ($HAS_COLORNAMES) {
    my $hex = $COLORTABLE->hex($name, "");
    if (defined $hex) {
      my ($r, $g, $b) = $COLORTABLE->rgb($name);
      $Color::RGB{$name} = [$r, $g, $b];
      $Color::Hash{$name} = [0, $name,
        sprintf("color %f %f %f", (map {$_ / 255.0} @{$Color::RGB{$name}}))];
    }
    return;
  }
}

=item $Color = Color->new($name);

=item $Color = Color->new($idx);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = shift;
  $class->register($name);
  my $obj = $class->SUPER::new($name,
                               \%Color::Hash, \@Color::List, \@Color::AutoList);
  bless($obj, $class);
  return $obj;
}

=item $bool = Color->exists($name)

=item $bool = Color::exists($name)

=item $name = Color->check($name)

=item $name = Color::check($name)

=cut

sub exists {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $classcheck = eval {$class->isa("Color")};
  my $name;
  if ($classcheck) {
    $name = shift;
  } else {
    $class = "Color";
    $name = $proto;
  }
  $class->register($name);
  return $class->SUPER::exists($name);
}

sub check {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $classcheck = eval {$class->isa("Color")};
  my $name;
  if ($classcheck) {
    $name = shift;
  } else {
    $class = "Color";
    $name = $proto;
  }
  $class->register($name);
  return lc($name) if $class->SUPER::exists($name);
  return undef;
}

=back

=head3 Class Gray: CurveParam

=over

=cut

package Gray;
our @ISA = qw(CurveParam);

our %RGB = (
  black   => [0],
  gray0   => [0],
  gray1   => [80],
  gray2   => [140],
  gray3   => [160],
  gray4   => [170],
  white   => [255],
);

our @AutoList = qw(black gray1 gray2 gray3 gray4);

our @List = (@AutoList, "black", "white");

# format: [$auto, $description, $jgraph_code]
our %Hash;
foreach my $g (@Gray::List) {
  $Gray::Hash{$g} = [
    (scalar grep {$g eq $_} @Gray::AutoList)? 1: 0,
    $g,
    sprintf("gray %f", (map {$_ / 255.0} @{$Gray::RGB{$g}}))
  ];
}

=item Gray->register($name);

=cut

sub register {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = lc(shift(@_));
  return if (defined(Check::isInteger($name, [0, undef])));
  if ($name =~ /^g(\d{1,3})$/) {
    my $lvl = $1;
    if ($lvl >= 0 && $lvl <= 255) {
      $Gray::RGB{$name} = [$lvl];
      $Gray::Hash{$name} = [0, $name,
        sprintf("gray %f", (map {$_ / 255.0} @{$Gray::RGB{$name}}))];
    }
  }
}

=item $Gray = Gray->new($name);

=item $Gray = Gray->new($idx);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name = shift;
  $class->register($name);
  my $obj = $class->SUPER::new($name,
                               \%Gray::Hash, \@Gray::List, \@Gray::AutoList);
  bless($obj, $class);
  return $obj;
}

=item $bool = Gray->exists($name)

=item $bool = Gray::exists($name)

=item $name = Gray->check($name)

=item $name = Gray::check($name)

=cut

sub exists {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $classcheck = eval {$class->isa("Gray")};
  my $name;
  if ($classcheck) {
    $name = shift;
  } else {
    $class = "Gray";
    $name = $proto;
  }
  $class->register($name);
  return $class->SUPER::exists($name);
}

sub check {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $classcheck = eval {$class->isa("Gray")};
  my $name;
  if ($classcheck) {
    $name = shift;
  } else {
    $class = "Gray";
    $name = $proto;
  }
  $class->register($name);
  return lc($name) if $class->SUPER::exists($name);
  return undef;
}

=back

=cut

#################################################
#################################################
# AGGREGATION FUNCTIONS
#################################################
#################################################

=head2 AGGREGATION FUNCTIONS

=head3 Class Aggregation

=over

=cut

package Aggregation;
our @ISA = qw();

our %Functions = (
  none   => ["no aggregation",           \&Aggregation::none],
  count  => ["count values",             \&Aggregation::count],
  sum    => ["sum values",               \&Aggregation::sum],
  max    => ["maximum value",            \&Aggregation::max],
  min    => ["minimum value",            \&Aggregation::min],
  rng    => ["range of values",          \&Aggregation::rng],
  avg    => ["average value",            \&Aggregation::avg],
  median => ["median value",             \&Aggregation::median],
  stdev  => ["standard deviation",       \&Aggregation::stdev],
  cv     => ["coefficient of variation", \&Aggregation::cv],
  ci     => ["confidence interval",      \&Aggregation::ci],
  ci_max => ["upper limit of c.i.",      \&Aggregation::ci_max],
  ci_min => ["lower limit of c.i.",      \&Aggregation::ci_min],
  delta  => ["delta for conf. interval", \&Aggregation::delta],
);
our @FunctionList = ("none", (sort (grep {$_ ne "none"} keys %Functions)));

sub none {
  my $list = shift;
  my @out = map {[$_, $_, $_]} @$list;
  return @out;
}

sub count {
  my $list = shift;
  my $val = $#$list + 1;
  return ([$val, $val, $val]);
}

sub sum {
  my $list = shift;
  my $val = 0;
  my @checklist = grep {defined(Check::isNum($_, [undef,undef]))} @$list;
  if ($#checklist == $#$list) {
    map {$val += $_} @$list;
  }
  return ([$val, $val, $val]);
}

sub max {
  my $list = shift;
  my $val = undef;
  my @checklist = grep {defined(Check::isNum($_, [undef,undef]))} @$list;
  if ($#checklist == $#$list) {
    map {$val = $_ if (!defined($val) || $val < $_)} @$list;
  } else {
    map {$val = $_ if (!defined($val) || $val lt $_)} @$list;
  }
  return () if (!defined $val);
  return ([$val, $val, $val]);
}

sub min {
  my $list = shift;
  my $val = undef;
  my @checklist = grep {defined(Check::isNum($_, [undef,undef]))} @$list;
  if ($#checklist == $#$list) {
    map {$val = $_ if (!defined($val) || $val > $_)} @$list;
  } else {
    map {$val = $_ if (!defined($val) || $val gt $_)} @$list;
  }
  return () if (!defined $val);
  return ([$val, $val, $val]);
}

sub avg {
  my $list = shift;
  my $val = $NC->Mean($list);
  return () if (!defined $val);
  return ([$val, $val, $val]);
}

sub median {
  my $list = shift;
  my $val = $NC->Median($list);
  return () if (!defined $val);
  return ([$val, $val, $val]);
}

sub stdev {
  my $list = shift;
  return () if ($#$list < 0);
  return ([0.0, 0.0, 0.0]) if ($#$list == 0);
  my $val = $NC->StandardDeviation($list);
  return ([$val, $val, $val]);
}

sub cv {
  my $list = shift;
  return () if ($#$list < 0);
  return ([0.0, 0.0, 0.0]) if ($#$list == 0);
  my $val = $NC->StandardDeviation($list);
  my $avg = $NC->Mean($list);
  $val = $val / $avg if ($avg != 0);
  return ([$val, $val, $val]);
}

sub ci {
  my $list = shift;
  my $stats = Statistics::PointEstimation->new();
  $stats->add_data(@$list);
  my $avg = $stats->mean();
  my $dlt = $stats->delta();
  $dlt = 0.0 if (!defined $dlt);
  return ([$avg, $avg - $dlt, $avg + $dlt]);
}

sub ci_max {
  my $list = shift;
  my $stats = Statistics::PointEstimation->new();
  $stats->add_data(@$list);
  my $avg = $stats->mean();
  my $dlt = $stats->delta();
  $dlt = 0.0 if (!defined $dlt);
  return ([$avg + $dlt, $avg + $dlt, $avg + $dlt]);
}

sub ci_min {
  my $list = shift;
  my $stats = Statistics::PointEstimation->new();
  $stats->add_data(@$list);
  my $avg = $stats->mean();
  my $dlt = $stats->delta();
  $dlt = 0.0 if (!defined $dlt);
  return ([$avg - $dlt, $avg - $dlt, $avg - $dlt]);
}

sub delta {
  my $list = shift;
  my $stats = Statistics::PointEstimation->new();
  $stats->add_data(@$list);
  my $avg = $stats->mean();
  my $dlt = $stats->delta();
  $dlt = 0.0 if (!defined $dlt);
  return ([$dlt, $dlt, $dlt]);
}

=item ($name1, ...) = Aggregation->list();

=cut

sub list {
  my $proto = shift;
  my @names = @Aggregation::FunctionList;
  return @names;
}

=item $Aggregation = Aggregation->new($name);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);
  my $name = lc(shift(@_));
  if (!exists $Aggregation::Functions{$name}) {
    die "invalid aggregation function \"$name\"\n";
  }
  $obj->{name} = $name;
  $obj->{desc} = $Aggregation::Functions{$name}->[0];
  $obj->{func} = $Aggregation::Functions{$name}->[1];
  return $obj;
}

=item ([$val, $low, $high], ...) = $Aggregation->do($listref);

=cut

sub do {
  my $obj = shift;
  my $in = shift;
  return () if (!defined $in);
  my $f = $obj->{func};
  my @out = &{$f}($in);
  return @out;
}

=item $string = $Aggregation->name();

=cut

sub name {
  my $obj = shift;
  return $obj->{name};
}

=item $string = $Aggregation->desc();

=cut

sub desc {
  my $obj = shift;
  return $obj->{desc};
}

=back

=cut

#################################################
#################################################
# CURVE DATA
#################################################
#################################################

=head2 CURVE DATA

=head3 Class CurveData

=over

=cut

package CurveData;
our @ISA = qw();

=item $CurveData = CurveData->new();

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);
  $obj->{label} = "";
  $obj->{mark} = "auto";
  $obj->{pts} = [];
  $obj->{xpts} = {};
  $obj->{ypts} = {};

  return $obj;
}

=item $string = $CurveData->getLabel();

=cut

sub getLabel {
  my $obj = shift;
  return $obj->{label};
}

=item $string = $CurveData->getMark();

=cut

sub getMark {
  my $obj = shift;
  return $obj->{mark};
}

=item $CurveData = $CurveData->setLabel();

=cut

sub setLabel {
  my $obj = shift;
  my $str = shift; $str = "" if (!defined $str);
  $obj->{label} = $str;
  return $obj;
}

=item $CurveData = $CurveData->setMark();

=cut

sub setMark {
  my $obj = shift;
  my $str = shift; $str = "" if (!defined $str);
  $obj->{mark} = $str;
  return $obj;
}

=item $int = $CurveData->xCount();

=cut

sub xCount {
  my $obj = shift;
  my @x = keys %{$obj->{xpts}};
  return $#x + 1;
}

=item $int = $CurveData->yCount();

=cut

sub yCount {
  my $obj = shift;
  my @y = keys %{$obj->{ypts}};
  return $#y + 1;
}

=item $int = $CurveData->pCount();

=cut

sub pCount {
  my $obj = shift;
  return $#{$obj->{pts}} + 1;
}

=item $CurveData = $CurveData->addPoint([$x, $y]);

=cut

sub addPoint {
  my $obj = shift;
  my $point = shift;
  my ($x, $y) = @$point;
  push(@{$obj->{pts}}, $point);
  $obj->{xpts}->{$x} = [] if (!exists $obj->{xpts}->{$x});
  push(@{$obj->{xpts}->{$x}}, $y);
  $obj->{ypts}->{$y} = [] if (!exists $obj->{ypts}->{$y});
  push(@{$obj->{ypts}->{$y}}, $x);
  return $obj;
}

=item [$xval1, ...] = $CurveData->xValues();

=cut

sub xValues {
  my $obj = shift;
  return [ (keys %{$obj->{xpts}}) ];
}

=item [$xval1, ...] = $CurveData->getX($y);

=cut

sub getX {
  my $obj = shift;
  my $y = shift;
  return undef if (!exists $obj->{ypts}->{$y});
  return [ @{$obj->{ypts}->{$y}} ];
}

sub yValues {
  my $obj = shift;
  return [ (keys %{$obj->{ypts}}) ];
}

=item [$yval1, ...] = $CurveData->getY($x);

=cut

sub getY {
  my $obj = shift;
  my $x = shift;
  return undef if (!exists $obj->{xpts}->{$x});
  return [ @{$obj->{xpts}->{$x}} ];
}

=back

=cut

#################################################
#################################################
# FILES
#################################################
#################################################

=head2 FILES

=head3 Class Input

=over

=cut

package Input;
our @ISA = qw();

=item $Input = Input->new();

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);

  $obj->{buff} = [];
  $obj->{fpos} = 0;
  return $obj;
}

=item $int = $Input->getPosition();

=cut

sub getPosition {
  my $obj = shift;
  return $obj->{fpos};
}

=item $string = $Input->getLine();

=cut

sub getBuffLine {
  my $obj = shift;
  my $line;
  if ($#{$obj->{buff}} >= 0) {
    $line = shift(@{$obj->{buff}});
    return $line;
  }
  return undef;
}

=item $Input = $Input->pushBuffLine($string);

=cut

sub pushBuffLine {
  my $obj = shift;
  my $str = shift;
  return $obj if (!defined $str);
  chomp($str);
  return $obj if ($str =~ /^\s*$/);
  return $obj if ($str =~ /^\s*#/);
  unshift(@{$obj->{buff}}, $str);
  return $obj;
}

=item $Input = $Input->appendBuffLine($string);

=cut

sub appendBuffLine {
  my $obj = shift;
  my $str = shift;
  return $obj if (!defined $str);
  chomp($str);
  return $obj if ($str =~ /^\s*$/);
  return $obj if ($str =~ /^\s*#/);
  push(@{$obj->{buff}}, $str);
  return $obj;
}

=back

=head3 Class MemFile: Input

=over

=cut

package MemFile;
our @ISA = qw(Input);

=item $MemFile = MemFile->new($line, ...);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();;
  bless($obj, $class);
  my @lines = @_;
  $obj->{data} = [@lines];
  return $obj;
}

=item $string = $MemFile->getLine();

=cut

sub getLine {
  my $obj = shift;
  my $line = $obj->getBuffLine();
  return $line if (defined $line);
  while (defined($line = shift(@{$obj->{data}}))) {
    $obj->{fpos} += 1;
    chomp($line);
    next if ($line =~ /^\s*$/);
    next if ($line =~ /^\s*#/);
    return $line;
  }
  return $line;
}

=item $MemFile = $MemFile->pushLine($string);

=cut

sub pushLine {
  my $obj = shift;
  my $str = shift;
  $obj->pushBuffLine($str);
  return $obj;
}

=item $MemFile = $MemFile->appendData($str1, ...);

=cut

sub appendData {
  my $obj = shift;
  my @lines = @_;
  push(@{$obj->{data}}, @lines);
  return $obj;
}

=back

=head3 Class File: Input

=over

=cut

package File;
our @ISA = qw(Input);

=item $File = File->new($path);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);
  my $path = shift;
  die "null file path\n" if (!defined $path);
  die "no such file \"$path\"\n" if (! -f $path);

  my $FH;
  die "cannot open file \"$path\"\n" if (!open($FH, $path));
  my @statdata = stat $FH;

  $obj->{path} = $path;
  $obj->{bytesize} = $statdata[7];
  $obj->{bytepos} = 0;
  $obj->{fh} = $FH;
  return $obj;
}

sub DESTROY {
  my $obj = shift;
  my $fh = $obj->{fh};
  close($fh) if (defined($fh));
  $obj->{path} = undef;
  $obj->{fh} = undef;
}

=item $string = $File->path();

=cut

sub path {
  my $obj = shift;
  return $obj->{path};
}

=item $string = $File->getLine();

=cut

sub getLine {
  my $obj = shift;
  my $fh = $obj->{fh};
  my $dataline = $obj->getBuffLine();
  return $dataline if (defined $dataline);
  $dataline = "";
  my $cont = 0;
  my $line;
  while ($line = <$fh>) {
    $obj->{fpos} += 1;
    $obj->{bytepos} += length($line);
    chomp($line);
    next if ($cont == 0 && $line =~ /^\s*$/);
    next if ($cont == 0 && $line =~ /^\s*#/);
    if ($cont != 0) {
      $line =~ s/#.*// if ($line =~ /^\s*#/)
    }
    $dataline .= $line;
    if ($dataline =~ /\s\\$/) {
      $dataline =~ s/\s\\$//;
      $cont ++;
    } else {
      $cont = 0;
      return $dataline;
    }
  }
  return ($cont == 0)? undef: $dataline;
}

=item $File = $File->pushLine($string);

=cut

sub pushLine {
  my $obj = shift;
  my $str = shift;
  $obj->pushBuffLine($str);
  return $obj;
}

=item $int = $File->getByteSize();

=cut

sub getByteSize {
  my $obj = shift;
  return $obj->{bytesize};
}

=item $int = $file->getBytePosition();

=cut

sub getBytePosition {
  my $obj = shift;
  return $obj->{bytepos};
}

=back

=cut

=head3 Class IncludeFile: File

=over

=cut

package IncludeFile;
our @ISA = qw(Input);

=item $IncludeFile = IncludeFile->new($path);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);

  my $path = shift;
  my $file = File->new($path);
  $obj->{filestack} = [$file];

  return $obj;
}

sub DESTROY {
  my $obj = shift;
  my $file = pop(@{$obj->{filestack}});
  while (defined $file) {
    $file = undef;
    $file = pop(@{$obj->{filestack}});
  }
}

=item $File = $IncludeFile->getCurFile();

=cut

sub getCurFile {
  my $obj = shift;
  my $file = $obj->{filestack}->[$#{$obj->{filestack}}];
  return $file;
}

=item $string = $File->path();

=cut

sub path {
  my $obj = shift;
  return $obj->getCurFile()->path();
}

=item $string = $File->gpath();

=cut

sub gpath {
  my $obj = shift;
  return $obj->{filestack}->[0]->path();
}

=item $string = $IncludeFile->getLine();

=cut

sub getLine {
  my $obj = shift;

  my $dataline = $obj->getBuffLine();
  return $dataline if (defined $dataline);
  $dataline = "";

  my $file = $obj->getCurFile();
  my $fh = $file->{fh};

  my $cont = 0;
  my $line;
backfile:
  while ($line = <$fh>) {
    $file->{fpos} += 1;
    $file->{bytepos} += length($line);
    chomp($line);

    if ($cont == 0 && $line =~ /^#INCLUDE\s+\"([^\"]+)\"\s*$/) {
      my $include = $1;
      $include =~ s/^\"//;
      $include =~ s/\"$//;
      if ($include !~ /^\//) {
        my $base = $file->path();
        if ($base =~ /\//) {
          $base =~ s/\/[^\/]*$//;
          $include = sprintf "%s/%s", $base, $include;
        }
      }
      if (! -f $include || ! -r $include) {
        warn "invalid file include path: \"$include\"\n";
        next;
      }
      my $newfile = File->new($include);
      push(@{$obj->{filestack}}, $newfile);
      $file = $newfile;
      $fh = $file->{fh};
      next;
    }

    next if ($cont == 0 && $line =~ /^\s*$/);
    next if ($cont == 0 && $line =~ /^\s*#/);
    if ($cont != 0) {
      $line =~ s/#.*// if ($line =~ /^\s*#/)
    }
    $dataline .= $line;
    if ($dataline =~ /\s\\$/) {
      $dataline =~ s/\s\\$//;
      $cont ++;
    } else {
      $cont = 0;
      return $dataline;
    }
  }

  return $dataline if ($cont != 0);
  return undef if ($#{$obj->{filestack}} == 0);

  pop(@{$obj->{filestack}});
  $file = $obj->getCurFile();
  $fh = $file->{fh};
  goto backfile;

}

=item $IncludeFile = $IncludeFile->pushLine($string);

=cut

sub pushLine {
  my $obj = shift;
  my $str = shift;
  $obj->pushBuffLine($str);
  return $obj;
}

=item $int = $IncludeFile->getPosition();

=cut

sub getPosition {
  my $obj = shift;
  my $file = $obj->getCurFile();
  return $file->getPosition();
}

=item $int = $IncludeFile->getByteSize();

=cut

sub getByteSize {
  my $obj = shift;
  my $file = $obj->getCurFile();
  return $file->getByteSize();
}

=item $int = $IncludeFile->getBytePosition();

=cut

sub getBytePosition {
  my $obj = shift;
  my $file = $obj->getCurFile();
  return $file->getBytePosition();
}

=back

=cut

=head3 Class ParamFile

=over

=cut

package ParamFile;
our @ISA = qw();

=item $ParamFile = ParamFile->new($Input);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);
  my $input = shift;

  $obj->{input} = $input;
  return $obj;
}

=item [$varname, $value] = $ParamFile->getData();

=cut

sub getData {
  my $obj = shift;
  my $input = $obj->{input};
  my $line = $input->getLine();
  while (defined $line) {
    if ($line =~ /^\s*([\w_]+)\s*=\s*(.*)/) {
      my $var = $1;
      my $val = $2; $val = "" if (!defined $val); $val =~ s/\s+$//;
      return [$var, $val];
    }
    my $pos = $input->getPosition();
    warn "malformed data line in param file (input line ${pos}: ${line})\n";
    $line = $input->getLine();
  }
  return undef;
}

=back

=cut

=head3 Class CsvFile

=over

=cut

package CsvFile;
our @ISA = qw();

=item $CsvFile = CsvFile->new($Input);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);
  my $input = shift;

  $obj->{input} = $input;
  $obj->{fnum} = {};
  $obj->{flist} = [];
  $obj->{fcount} = 0;

  my $fhash = {};
  my $header = $input->getLine();
  die "not a valid csv file\n" if (!defined $header);
  my @fields = split(/${SEPARATOR}/, $header, -1);
  my $idx = 0;
  foreach my $f (@fields) {
    my $norm = uc($f); $norm =~ s/[^\w_]/_/g;
    if (exists $fhash->{$norm}) {
      die "repeated field name \"$f\" (${norm}) in csv file\n";
    }
    $fhash->{$norm} = $idx;
    push(@{$obj->{flist}}, $norm);
    $idx ++;
  }
  $obj->{fcount} = $idx;

  my $line = $input->getLine();
  die "no data in csv file\n" if (!defined $line);
  my @items = split(/${SEPARATOR}/, $line, -1);
  if ($obj->{fcount} != ($#items + 1)) {
    die "malformed data line in csv file\n";
  }
  $idx = 0;
  foreach my $i (@items) {
    my $k = $obj->{flist}->[$idx];
    if ($i =~ /^(\+|\-)?\d+(\.\d+([eE](\+|\-)?\d+)?)?$/) {
      $obj->{fnum}->{$k} = 1;
    } else {
      $obj->{fnum}->{$k} = 0;
    }
    $idx ++;
  }
  $input->pushLine($line);

  return $obj;
}

=item ($str, ...) = $CsvFile->getFieldNames();

=cut

sub getFieldNames {
  my $obj = shift;
  return (sort {$a cmp $b} @{$obj->{flist}});
}

=item $bool = $CsvFile->getNumeric($field_name);

=cut

sub getNumeric {
  my $obj = shift;
  my $name = shift;
  $name = uc($name);
  $name =~ s/[^\w_]/_/g;
  return $obj->{fnum}->{$name};
}

=item $hash = $CsvFile->getData();

=cut

sub getData {
  my $obj = shift;
  my $input = $obj->{input};
  my $line = $input->getLine();
  return $line if (!defined $line);
  my @items = split(/${SEPARATOR}/, $line, -1);
  if ($obj->{fcount} != ($#items + 1)) {
    my $line = $obj->{input}->getPosition();
    die "malformed data line in csv file (input line ${line})\n";
  }
  my $data = {};
  my $idx = 0;
  while ($idx < $obj->{fcount}) {
    $data->{$obj->{flist}->[$idx]} = $items[$idx];
    $idx ++;
  }
  return $data;
}

=back

=head3 Class GFToken

=over

=cut

package GFToken;
our @ISA = qw();

=item $GFToken->new($string);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);
  my $str = shift;
  die "null token in graph file\n" if (!defined $str);
  $obj->{pos} = -1;
  $obj->{str} = $str;

  return $obj;
}

=item $string = $GFToken->string();

=cut

sub string {
  my $obj = shift;
  return $obj->{str};
}

=item @list = $GFToken->stringList();

=cut

sub stringList {
  my $obj = shift;
  return ($obj->{str});
}

=item $int = $GFToken->getPosition();

=cut

sub getPosition {
  my $obj = shift;
  return $obj->{pos};
}

=item $GFToken = $GFToken->setPosition($int);

=cut

sub setPosition {
  my $obj = shift;
  my $pos = shift;
  $obj->{pos} = int($pos);
  return $obj;
}

=back

=cut

=head3 Class GFHeader: GFToken

=over

=cut

package GFHeader;
our @ISA = qw(GFToken);

=item $string = GFHeader->match($str);

=cut

sub match {
  my $proto = shift;
  my $str = shift;
  return undef if (!defined $str);
  if ($str =~ /^\s*\[\s*([\w_]+)\s*\]\s*/) {
    return lc($1);
  }
  return undef;
}

=item $GFHeader = GFHeader->new($str);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $str = $class->match(shift(@_));
  die "invalid header in graph file\n" if (!defined $str);
  my $obj = $class->SUPER::new("[${str}]");
  bless($obj, $class);
  $obj->{name} = $str;

  return $obj;
}

=item $string = $GFHeader->name();

=cut

sub name {
  my $obj = shift;
  return $obj->{name};
}

=back

=head3 Class GFItem: GFToken

=over

=cut

package GFItem;
our @ISA = qw(GFToken);

=item ($item, $data) = GFItem->match($string);

=cut

sub match {
  my $proto = shift;
  my $str = shift;
  return undef if (!defined $str);
  if ($str =~ /^\s*([\w_]+)\s*:\s*(\S.*)$/) {
    my $key = lc($1);
    my $data = $2; $data =~ s/\s+$//;
    return (wantarray)? ($key, $data): $key;
#  } elsif ($str =~ /^\s*([\w_]+)\s*:\s*$/) {
#    my $key = lc($1);
#    my $data = "";
#    return (wantarray)? ($key, $data): $key;
  }
  return undef;
}

=item $GFItem = GFItem->new($string);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my ($item, $data) = $class->match(shift(@_));
  die "invalid item specification in graph file\n" if (!defined $item);
  my $obj = $class->SUPER::new($item . ": " . $data);
  $obj->{name} = $item;
  $obj->{data} = $data;

  return $obj;
}

=item $string = $GFItem->name();

=cut

sub name {
  my $obj = shift;
  return $obj->{name};
}

=item $string = $GFItem->data();

=cut

sub data {
  my $obj = shift;
  return $obj->{data}
}

=item $string = $GFItem->expanded();

=cut

sub expandEnvVar ($$$;$) {
  my $pfx = shift;
  my $brc = shift;
  my $var = shift;
  my $Override = shift;
  if (defined $Override && exists $Override->{$var}) {
    return (defined $pfx)? $pfx . $Override->{$var}: $Override->{$var};
  } elsif (exists $GLOBALENV{$var}) {
    return (defined $pfx)? $pfx . $GLOBALENV{$var}: $GLOBALENV{$var};
  } elsif (exists $ENV{$var}) {
    return (defined $pfx)? $pfx . $ENV{$var}: $ENV{$var};
  } elsif (exists $LOCALENV{$var}) {
    return (defined $pfx)? $pfx . $LOCALENV{$var}: $LOCALENV{$var};
  }
  if ($brc) {
    return (defined $pfx)? $pfx . "\@{" . $var . "}": "\@{" . $var . "}";
  } else {
    return (defined $pfx)? $pfx . "\@" . $var: "\@" . $var;
  }
}

sub expandEvalVar ($$$;$) {
  my $pfx = shift;
  my $brc = shift;
  my $var = shift;
  my $Override = shift;
  if (exists $LOCALEVAL{$var}) {
    my $str = $LOCALEVAL{$var};
    $str =~ s/(^|[^\\])\@\{([\w_]+)\}/expandEnvVar($1, 1, $2, $Override)/ge;
    $str =~ s/(^|[^\\])\@([\w_]+)(\b|$)/expandEnvVar($1, 0, $2, $Override)/ge;
    my $value = eval $str;
    $value = "" if (!defined $value);
    return (defined $pfx)? $pfx . $value: $value;
  }
  if ($brc) {
    return (defined $pfx)? $pfx . "\&{" . $var . "}": "\&{" . $var . "}";
  } else {
    return (defined $pfx)? $pfx . "\&" . $var: "\&" . $var;
  }
}

sub expanded {
  my $obj = shift;
  my $Override = shift;
  my $exp = $obj->{data};
  $exp =~ s/(^|[^\\])\@\{([\w_]+)\}/expandEnvVar($1, 1, $2, $Override)/ge;
  $exp =~ s/(^|[^\\])\@([\w_]+)(\b|$)/expandEnvVar($1, 0, $2, $Override)/ge;
  $exp =~ s/(^|[^\\])\&\{([\w_]+)\}/expandEvalVar($1, 1, $2, $Override)/ge;
  $exp =~ s/(^|[^\\])\&([\w_]+)(\b|$)/expandEvalVar($1, 0, $2, $Override)/ge;
  #$exp =~ s/(^|[^\\])\%\{([\w_]+)\}/expandFuncVar($1, 1, $2, $Override)/ge;
  #$exp =~ s/(^|[^\\])\%([\w_]+)(\b|$)/expandFuncVar($1, 0, $2, $Override)/ge;
  return $exp;
}

=back

=head3 Class GFSection

=over

=cut

package GFSection;
our @ISA = qw();

our $SectionId = 1;

=item $GFSection = GFSection->new($GFHeader);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);
  my $header = shift;
  $obj->{counter} = \$GFSection::SectionId;
  $obj->{id} = ${$obj->{counter}};
  $obj->{header} = $header;
  $obj->{itemlist} = [];
  $obj->{current} = undef;
  $obj->{items} = undef;

  ${$obj->{counter}} += 1;
  return $obj;
}

=item $int = $GFsection->id();

=cut

sub id {
  my $obj = shift;
  return $obj->{id};
}

=item $GFHeader = $GFSection->header();

=cut

sub header {
  my $obj = shift;
  return $obj->{header};
}

=item $GFSection = $GFSection->addItem($GFItem);

=cut

sub addItem {
  my $obj = shift;
  my $item = shift;
  my $name = $item->name();
  my $valid = $obj->{allowed};
  if (defined $valid && !exists $valid->{$name}) {
    my $pos = $item->getPosition();
    die "invalid item \"$name\" (input line: $pos)\n";
  }
  if (defined $valid && defined $valid->{$name}) {
    my $pos = $item->getPosition();
    my $multi = $valid->{$name}->[0];
    if (!$multi && defined($obj->getItem($name))) {
      die "duplicated item \"$name\" (input line: $pos)\n";
    }
    my $f = $valid->{$name}->[1];
    if (defined $f) {
      my $args = $valid->{$name}->[2];
      my $checked = &{$f}($item->data(), $args);
      if (!defined($checked)) {
        die "syntax error for \"$name\" (input line: $pos)\n";
      }
    }
  }
  push(@{$obj->{itemlist}}, $item);
  $obj->{current} = undef;
  return $obj;
}

=item $GFSection = $GFSection->replaceItem($GFItem);

=cut

sub replaceItem {
  my $obj = shift;
  my $item = shift;
  my @newitems = grep {$_->name() ne $item->name()} @{$obj->{itemlist}};
  push(@newitems, $item);
  $obj->{itemlist} = [ @newitems ];
  $obj->addItem($item);
  return $obj;
}

=item $GFSection = $GFSection->removeItem($name);

=cut

sub removeItem {
  my $obj = shift;
  my $name = lc(shift(@_));
  my @newitems = grep {$_->name() ne $name} @{$obj->{itemlist}};
  $obj->{itemlist} = [ @newitems ];
  $obj->{current} = undef;
  return $obj;
}

=item $GFItem = $GFSection->getFirstItem();

=cut

sub getFirstItem {
  my $obj = shift;
  if ($#{$obj->{itemlist}} < 0) {
    $obj->{current} = undef;
    return undef;
  }
  $obj->{current} = 0;
  return $obj->{itemlist}->[0];
}

=item $GFItem = $GFSection->getNextItem();

=cut

sub getNextItem {
  my $obj = shift;
  return undef if (!defined $obj->{current});
  if ($obj->{current} == $#{$obj->{itemlist}}) {
    $obj->{current} = undef;
    return undef;
  }
  $obj->{current} += 1;
  return $obj->{itemlist}->[$obj->{current}];
}

=item $bool = $GFSection->hasItem($name);

=cut

sub hasItem {
  my $obj = shift;
  my $name = lc(shift(@_));
  if (grep {$name eq $_->name()} @{$obj->{itemlist}}) {
    return 1;
  }
  return 0;
}

=item ($GFItem, ...) = $GFSection->getItem($name);

=cut

sub getItem {
  my $obj = shift;
  my $name = lc(shift(@_));
  my @list = grep {$name eq $_->name()} @{$obj->{itemlist}};
  return (wantarray)? @list: $list[0];
}

=item ($data, ...) = $GFSection->getItemData($name);

=cut

sub getItemData {
  my $obj = shift;
  my $name = lc(shift(@_));
  my @list = grep {$name eq $_->name()} @{$obj->{itemlist}};
  my $func = $obj->{allowed}->{$name}->[1];
  my @data;
  if (!defined $func) {
    foreach my $i (@list) {
      my $d = $i->data();
      if (ref($d) eq "ARRAY") {
        push(@data, @$d);
      } else {
        push(@data, $d);
      }
    }
  } else {
    my $args = $obj->{allowed}->{$name}->[2];
    foreach my $i (@list) {
      my $d = &{$func}($i->data(), $args);
      if (ref($d) eq "ARRAY") {
        push(@data, @$d);
      } else {
        push(@data, $d);
      }
    }
  }
  return (wantarray)? @data: $data[0];
}

=item ($data, ...) = $GFSection->getItemExpandedData($name [, $hash]);

=cut

sub getItemExpandedData {
  my $obj = shift;
  my $name = lc(shift(@_));
  my $Override = shift;
  my @list = grep {$name eq $_->name()} @{$obj->{itemlist}};
  my $func = $obj->{allowed}->{$name}->[1];
  my @data;
  if (!defined $func) {
    foreach my $i (@list) {
      my $d = $i->expanded($Override);
      push(@data, $d);
    }
  } else {
    my $args = $obj->{allowed}->{$name}->[2];
    foreach my $i (@list) {
      my $d = &{$func}($i->expanded($Override), $args);
      if (ref($d) eq "ARRAY") {
        push(@data, @$d);
      } else {
        push(@data, $d);
      }
    }
  }
  return (wantarray)? @data: $data[0];
}

=item $string = $GFSection->string();

=cut

sub string {
  my $obj = shift;
  return join("\n", ($obj->stringList()));
}

=item @list = $GFSection->stringList();

=cut

sub stringList {
  my $obj = shift;
  my @str = ($obj->{header}->stringList());
  foreach my $i (@{$obj->{itemlist}}) {
    push(@str, $i->stringList());
  }
  return (@str, "");
}

=back

=head3 Class SectionFile

=over

=cut

package SectionFile;
our @ISA = qw();

=item $SectionFile = SectionFile->new($Input);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);
  my $input = shift;
  $obj->{input} = $input;

  return $obj;
}

=item $GFHeader = $SectionFile->getHeader();

=cut

sub getHeader {
  my $obj = shift;
  my $input = $obj->{input};
  my $line = $input->getLine();
  return undef if (!defined $line);
  if (!defined GFHeader->match($line)) {
    $input->pushLine($line);
    return undef;
  }
  my $header = GFHeader->new($line);
  $header->setPosition($input->getPosition());
  return $header;
}

=item $GFItem = $SectionFile->getItem();

=cut

sub getItem {
  my $obj = shift;
  my $input = $obj->{input};
  my $line = $input->getLine();
  return undef if (!defined $line);
  if (!defined GFItem->match($line)) {
    $input->pushLine($line);
    return undef;
  }
  my $item = GFItem->new($line);
  $item->setPosition($input->getPosition());
  return $item;
}

=item $bool = $SectionFile->getEndSection();

=cut

sub getEndSection {
  my $obj = shift;
  my $input = $obj->{input};
  my $header = $obj->getHeader();
  return undef if (!defined $header);
  if ($header->name() ne "end") {
    $input->pushLine("[" . $header->name() . "]");
    return undef;
  }
  $input->pushLine("[end]");
  return 1;
}

=back

=head3 Class GlobalSection: GFSection

=over

=cut

package GlobalSection;
our @ISA = qw(GFSection);

our %Options = (
);

# format: key -> [$multi_value, \&check_function, [check_args,...]]
our %Items = (
  env          => [1, undef, undef],
  eval         => [1, undef, undef],
  func         => [1, undef, undef],
);

=item $GlobalSection = GlobalSection->new($GFHeader);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $header = shift;
  die "invalid header for global section\n" if ($header->name() ne "global");
  my $obj = $class->SUPER::new($header);
  $obj->{allowed} = \%GlobalSection::Items;
  return $obj;
}

=back

=head3 Class GraphSection: GFSection

=over

=cut

package GraphSection;
our @ISA = qw(GFSection);

our %Options = (
  skip             => "skip graph",
  include_outliers => "include outliers",
  stack            => "stack curves",
  newpage          => "print graph in new page",
  grayscale        => "print using gray scale",
  top_axis         => "print x axis on top",
  right_axis       => "print y axis on the right",
  no_xhash         => "do not print marks on x axis",
  no_xhash_labels  => "do not print mark labels on x axis",
  no_yhash         => "do not print marks on y axis",
  no_yhash_labels  => "do not print mark labels on y axis",
  xno_min          => "do not set minimum axis value for x",
  yno_min          => "do not set minimum axis value for y",
  no_error         => "do not print error marks",
  xoffset          => "shift vertical bars",
  yoffset          => "shift horizontal bars",
  xrotate_labels   => "rotate x labels",
  yrotate_labels   => "rotate y labels",
  normalize        => "normalize to a base curve",
  descriptive_data => "use human readable labels for data dumps",
);

# format: key -> [$multi_value, \&check_function, [check_args,...]]
our %Items = (
  jgraph          => [1, undef, undef],
  size            => [0, \&Check::isNum, [1, undef]],
  font            => [0, \&Check::isWord, [undef, undef]],
  fontsize        => [0, \&Check::isInteger, [1, undef]],

  title           => [0, undef, undef],
  title_font      => [0, \&Check::isWord, [undef, undef]],
  title_fontsize  => [0, \&Check::isInteger, [1, undef]],

  legend          => [0, \&Check::isWord, ["l", [(Justification->list())]]],
  legend_font     => [0, \&Check::isWord, [undef, undef]],
  legend_fontsize => [0, \&Check::isInteger, [1, undef]],
  legend_x        => [0, undef, undef],
  legend_y        => [0, undef, undef],

  label_font      => [0, \&Check::isWord, [undef, undef]],
  label_fontsize  => [0, \&Check::isInteger, [1, undef]],

  hash_font       => [0, \&Check::isWord, [undef, undef]],
  hash_fontsize   => [0, \&Check::isInteger, [1, undef]],

  xjgraph         => [1, undef, undef],
  xlabel          => [0, undef, undef],
  xtype           => [0, \&Check::isWord, ["l", [(AxisType->list())]]],
  xcat            => [1, \&Check::isList, [undef, undef]],
  xskip           => [0, \&Check::isInteger, [0, undef]],
  xsize           => [0, \&Check::isNum, [1, undef]],
  xmin            => [0, \&Check::isNum, [undef, undef]],
  xmax            => [0, \&Check::isNum, [undef, undef]],
  xbase           => [0, \&Check::isNum, [undef, undef]],

  yjgraph         => [1, undef, undef],
  ylabel          => [0, undef, undef],
  ytype           => [0, \&Check::isWord, ["l", [(AxisType->list())]]],
  ycat            => [1, \&Check::isList, [undef, undef]],
  yskip           => [0, \&Check::isInteger, [0, undef]],
  ysize           => [0, \&Check::isNum, [1, undef]],
  ymin            => [0, \&Check::isNum, [undef, undef]],
  ymax            => [0, \&Check::isNum, [undef, undef]],
  ybase           => [0, \&Check::isNum, [undef, undef]],
  aggr            => [0, \&Check::isWord, ["l", [Aggregation->list()]]],

  linecycle       => [0, \&Check::isInteger, [0, undef]],
  markcycle       => [0, \&Check::isInteger, [0, undef]],
  colorcycle      => [0, \&Check::isInteger, [0, undef]],
  markscalecycle  => [0, \&Check::isInteger, [0, undef]],
  options         => [1, \&Check::isList, [\&Check::isWord, ["l",
                                          [(keys %GraphSection::Options)]]]],
);

=item $GraphSection = GraphSection->new($GFHeader);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $header = shift;
  die "invalid header for graph section\n" if ($header->name() ne "graph");
  my $obj = $class->SUPER::new($header);
  $obj->{allowed} = \%GraphSection::Items;
  return $obj;
}

=back

=head3 Class BenchSection: GFSection

=over

=cut

package BenchSection;
our @ISA = qw(GFSection);

our %Options = (
);

# format: key -> [$multi_value, \&check_function, [check_args,...]]
our %Items = (
  name            => [0, \&Check::isWord, ["u", undef]],
  select          => [1, undef, undef],
);

=item $BenchSection = BenchSection->new($GFHeader);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $header = shift;
  die "invalid header for bench section\n" if ($header->name() ne "bench");
  my $obj = $class->SUPER::new($header);
  $obj->{allowed} = \%BenchSection::Items;
  return $obj;
}

=back

=head3 Class CurveSection: GFSection

=over

=cut

package CurveSection;
our @ISA = qw(GFSection);

our %Options = (
  skip             => "skip curve",
  include_outliers => "include outliers",
  exclude_outliers => "exclude outliers",
  grayscale        => "force gray scale",
  color            => "force color",
  no_error         => "do not print error marks",
  no_stack         => "skip curve stacking",
  accum            => "accumulate y values from previous x",
  error            => "force printing error marks",
  fill             => "fill curve line",
  base             => "use as normalization base",
  markscale        => "cycle through mark sizes",
);

# format: key -> [$multi_value, \&check_function, [check_args,...]]
our %Items = (
  label           => [0, undef, undef],
  filter          => [1, undef, undef],
  xval            => [0, \&Check::isList, [undef, undef]],
  yval            => [0, \&Check::isList, [undef, undef]],
  aggr            => [0, \&Check::isWord, ["l", [Aggregation->list()]]],
  line            => [0, \&Check::isWord, ["l", [Line->list()]]],
  mark            => [0, undef, undef],
  markscale       => [0, \&Check::isValid, ["l", [\&MarkScale::check, []]]],
  jgraph          => [1, undef, undef],
  color           => [0, \&Check::isValid, ["l", [\&Color::check, []]]],
  gray            => [0, \&Check::isValid, ["l", [\&Gray::check, []]]],
  iterate         => [1, \&Check::isList, [\&Check::isColVar, [undef]]],
  options         => [1, \&Check::isList, [\&Check::isWord, ["l",
                                          [(keys %CurveSection::Options)]]]],
);

=item $CurveSection = CurveSection->new($GFHeader);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $header = shift;
  die "invalid header for curve section\n" if ($header->name() ne "curve");
  my $obj = $class->SUPER::new($header);
  $obj->{allowed} = \%CurveSection::Items;
  return $obj;
}

=back

=head3 Class Desc

=over

=cut

package Desc;
our @ISA = qw();

=item $Desc = Desc->new($GFSection);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);
  my $sect = shift;
  $obj->{sect} = $sect;
  $obj->{parent} = undef;
  $obj->{children} = [];
  $obj->{current} = undef;

  return $obj;
}

=item $int = $Desc->id();

=cut

sub id {
  my $obj = shift;
  return $obj->{sect}->id();
}

=item $GFSection = $Desc->section();

=cut

sub section {
  my $obj = shift;
  return $obj->{sect};
}

=item $GFSection = $Desc->parent();

=cut

sub parent {
  my $obj = shift;
  return $obj->{parent};
}

=item $Desc = $Desc->addChild($child_Desc);

=cut

sub addChild {
  my $obj = shift;
  my $desc = shift;
  $obj->{current} = undef;
  return $obj if (grep {$_->id() == $desc->id()} @{$obj->{children}});
  push(@{$obj->{children}}, $desc);
  $desc->{parent} = $obj;
  return $obj;
}

=item $Desc = $Desc->insertChild($child_Desc, $int);

=cut

sub insertChild {
  my $obj = shift;
  my $desc = shift;
  my $pos = shift;
  $obj->{current} = undef;
  $obj->addChild($desc);
  $obj->setChildPos($desc, $pos);
  return $obj;
}

=item $Desc = $Desc->removeChild($child_Desc);

=item $Desc = $Desc->removeChild($child_id);

=cut

sub removeChild {
  my $obj = shift;
  my $desc = shift;
  $obj->{current} = undef;
  $desc = $desc->id() if (ref($desc));
  my @newchildren = grep {$_->id() != $desc} @{$obj->{children}};
  $obj->{children} = [ @newchildren ];
  return $obj;
}

=item $int = $Desc->getChildCount();

=cut

sub getChildCount {
  my $obj = shift;
  return $#{$obj->{children}} + 1;
}

=item $int = $Desc->getChildPos($child_Desc);

=item $int = $Desc->getChildPos($child_id);

=cut

sub getChildPos {
  my $obj = shift;
  my $child = shift;
  $child = $child->id() if (ref($child));
  my $pos = 0;
  while ($pos <= $#{$obj->{children}}) {
    return $pos if ($obj->{children}->[$pos]->id() == $child);
    $pos += 1;
  }
  return undef;
}

=item $Desc = $Desc->setChildPos($child_Desc, $int);

=item $Desc = $Desc->setChildPos($child_id, $int);

=cut

sub setChildPos {
  my $obj = shift;
  my $child = shift;
  my $pos = shift;
  $obj->{current} = undef;
  $pos = $#{$obj->{children}} +1 + $pos if ($pos < 0);
  $pos = 0 if ($pos < 0);
  $pos = $#{$obj->{children}} if ($pos > $#{$obj->{children}});
  my $child_id = (ref($child))? $child->id(): $child;
  my ($item) = grep {$_->id() == $child_id} @{$obj->{children}};
  if (defined $item) {
    $obj->removeChild($item);
    my @pre = $obj->{children}->[0 .. ($pos - 1)];
    my @post = $obj->{children}->[$pos .. $#{$obj->{children}}];
    $obj->{children} = [ @pre, $item, @post ];
  }
  return $obj;
}

=item $child_Desc = $Desc->getFirstChild();

=cut

sub getFirstChild {
  my $obj = shift;
  $obj->{current} = undef;
  return undef if ($#{$obj->{children}} < 0);
  $obj->{current} = 0;
  return $obj->{children}->[0];
}

=item $child_Desc = $Desc->getNextChild();

=cut

sub getNextChild {
  my $obj = shift;
  return undef if (!defined $obj->{current});
  $obj->{current} += 1;
  return $obj->{children}->[$obj->{current}]
         if ($obj->{current} <= $#{$obj->{children}});
  $obj->{current} = undef;
  return undef;
}

=item $child_Desc = $Desc->getChildByPos($int);

=cut

sub getChildByPos {
  my $obj = shift;
  my $pos = shift;
  $pos = $#{$obj->{children}} +1 + $pos if ($pos < 0);
  return undef if ($pos < 0 || $pos > $#{$obj->{children}});
  return $obj->{chidlren}->[$pos];
}

=item $string = $Desc->string();

=cut

sub string {
  my $obj = shift;
  return join("\n", ($obj->stringList()));
}

=item @list = $Desc->stringList();

=cut

sub stringList {
  my $obj = shift;
  my @str = ($obj->{sect}->stringList(), "");
  foreach my $c (@{$obj->{children}}) {
    push(@str, $c->stringList(), "");
  }
  return @str;
}

=back

=head3 Class CurveDesc: Desc

=over

=cut

package CurveDesc;
our @ISA = qw(Desc);

=item $CurveDesc = CurveDesc->new($CurveSection);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $sect = shift;
  my $obj = $class->SUPER::new($sect);
  bless($obj, $class);

  $obj->{data} = {};
  $obj->{data}->{filter} = [];
  $obj->{data}->{curves} = [];
  $obj->{data}->{current} = undef;

  return $obj;
}

=item $hash = $CurveDesc->getOptions()

=cut

sub getOptions {
  my $obj = shift;
  my @options = $obj->section()->getItemData("options");
  my $hash = {};
  foreach my $o (@options) {
    $hash->{$o} = 1;
  }
  return $hash;
}

=item $CurveDesc = $CurveDesc->verify();

=cut

sub verify {
  my $obj = shift;
  my $sect = $obj->section();
  my $header = $sect->header();
  my $options = $obj->getOptions();
  my $linenum = $header->getPosition();

  return $obj if ($options->{skip});
  if (!$sect->hasItem("xval")) {
    die "missing \"xval\" in curve section (input line $linenum)\n";
  }
  if (!$sect->hasItem("yval")) {
    die "missing \"yval\" in curve section (input line $linenum)\n";
  }

  return $obj;
}

=item $CurveDesc = $CurveDesc->calculate();

=cut

sub calculate {
  my $obj = shift;
  my $Override = shift;
  my $sect = $obj->section();
  my $sqlstr;
  my $sth;
  my $row;

  $obj->verify();

  my $bench = $obj->parent()->bench();
  my $view = $bench->view()->create();
  my @fields = $bench->getFields();
  my @fieldnames = $bench->getFieldNames();
  my %field;
  foreach my $f (@fields) {
    $field{$f->name()} = $f;
  }

  my $graph_options = $obj->parent()->parent()->getOptions();
  my $curve_options = $obj->getOptions();

  my $include_outliers = $curve_options->{include_outliers} ||
    ($graph_options->{include_outliers} && !$curve_options->{exclude_outliers});

  $obj->{data}->{filter} = [];
  $obj->{data}->{curves} = [];
  $obj->{data}->{current} = undef;

  # curve filter
  if ($sect->hasItem("filter")) {
    my @list = $sect->getItemExpandedData("filter", $Override);
    $obj->{data}->{filter} = [ @list ];
  }
  my $selection = join (" AND ", @{$obj->{data}->{filter}});
  my $curve_cond = Check::expandColVar($selection, [[@fieldnames]]);
  die "unknown columns in curve filter\n" if (!defined $curve_cond);

  # benchmark filter
  my $bench_cond = Check::expandColVar($obj->parent()->selection(),
                                       [[@fieldnames]]);
  die "unknown columns in benchmark selection\n" if (!defined $bench_cond);

  # iteration filter
  my @iter_cond = ();
  if (!$sect->hasItem("iterate")) {
    @iter_cond = ("");
  } else {
    my @iterate = $sect->getItemExpandedData("iterate", $Override);
    my @iter_cols = ();
    my %iter_values;
    foreach my $c (@iterate) {
      my $col = Check::isColVar("\$" . $c, [[@fieldnames]]);
      die "unknown column in curve iteration\n" if (!defined $col);
      push(@iter_cols, $col);
      $iter_values{$col} = [];
    }
    foreach my $col (keys %iter_values) {
      $sqlstr = sprintf "SELECT DISTINCT _%s FROM %s WHERE BENCH = ?",
                        $col, $view->table();
      $sqlstr .= sprintf " AND (%s)", $bench_cond if ($bench_cond);
      $sth = $view->database()->do($sqlstr, $bench->id());
      my @values = ();
      ($row) = $sth->fetchrow_array();
      while (defined $row) {
        push(@values, $row);
        ($row) = $sth->fetchrow_array();
      }
      if ($field{$col}->numeric()) {
        $iter_values{$col} = [(sort {$a <=> $b} @values)];
      } else {
        $iter_values{$col} = [(sort {$a cmp $b} @values)];
      }
    }
    my $iter_sizes = [];
    my $iter_data = [];
    foreach my $col (@iter_cols) {
      push(@$iter_sizes, $#{$iter_values{$col}});
      push(@$iter_data, $iter_values{$col});
    }
    my $indexes = IndexVector->new($#iter_cols + 1);
    my $indexes_max = IndexVector->new($iter_sizes);
    my $next = $indexes;
    while (defined($next)) {
      my @values = @{$indexes->get($iter_data)};
      my @cond = ();
      my $i = 0;
      while ($i <= $#iter_cols) {
        if (!defined($values[$i])) {
          push(@cond, sprintf("_%s IS NULL", $iter_cols[$i]));
        } elsif ($field{$iter_cols[$i]}->numeric()) {
          push(@cond, sprintf("_%s = %s", $iter_cols[$i], $values[$i]));
        } else {
          push(@cond, sprintf("_%s = '%s'", $iter_cols[$i], $values[$i]));
        }
        $i += 1;
      }
      push(@iter_cond, join(" AND ", @cond));
      $next = $indexes->next($indexes_max);
    }
  }

  # retrieve data

  foreach my $iter_cond (@iter_cond) {
    my $label = "";
    my $mark = "auto";
    my $xval = join(", ", $sect->getItemExpandedData("xval", $Override));
       $xval = "sprintf " . Check::expandColCode($xval, [[@fieldnames]]);
    my $yval = join(", ", $sect->getItemExpandedData("yval", $Override));
       $yval = "sprintf " . Check::expandColCode($yval, [[@fieldnames]]);
    my @pts = ();
    $sqlstr = sprintf "SELECT * FROM %s WHERE BENCH = ?", $view->table();
    $sqlstr .= " AND OUT = 0" if (!$include_outliers);
    $sqlstr .= sprintf " AND (%s)", $bench_cond if ($bench_cond);
    $sqlstr .= sprintf " AND (%s)", $curve_cond if ($curve_cond);
    $sqlstr .= sprintf " AND (%s)", $iter_cond if ($iter_cond);
    $sth = $view->database()->do($sqlstr, $bench->id());
    $row = $sth->fetchrow_hashref();
    if (defined $row) {
    my @iterate = $sect->getItemExpandedData("iterate", $Override);
      # evaluate label
      my $labstr = $sect->getItemExpandedData("label", $Override);
      $labstr = "" if (!defined $labstr);
      $label = Check::expandColValue($labstr, [$row]);
      $label = "" if (!defined $label);
      # evaluate mark
      if ($sect->hasItem("mark")) {
        my $markstr = $sect->getItemExpandedData("mark", $Override);
        $markstr = "auto" if (!defined $markstr);
        $mark = Check::expandColValue($markstr, [$row]);
        $mark = "auto" if (!defined $mark);
      }
    }
    while (defined $row) {
      # get x/y 
      my $x = eval $xval;
      my $y = eval $yval;
      push(@pts, [$x, $y]);
      $row = $sth->fetchrow_hashref();
    }

    my $curve = CurveData->new();
    $curve->setLabel($label);
    $curve->setMark($mark);
    foreach my $p (@pts) {
      $curve->addPoint($p);
    }
    push(@{$obj->{data}->{curves}}, $curve);
  }

  return $obj;
}

=item $int = $CurveDesc->getCurveCount();

=cut

sub getCurveCount {
  my $obj = shift;
  return $#{$obj->{data}->{curves}} + 1;
}

=item $int = $CurveDesc->getFirstCurve();

=cut

sub getFirstCurve {
  my $obj = shift;
  $obj->{data}->{current} = undef;
  return undef if ($obj->getCurveCount() == 0);
  $obj->{data}->{current} = 0;
  return $obj->{data}->{curves}->[0];
}

=item $int = $CurveDesc->getNextCurve();

=cut

sub getNextCurve {
  my $obj = shift;
  return undef if (!defined $obj->{data}->{current});
  $obj->{data}->{current} += 1;
  return $obj->{data}->{curves}->[$obj->{data}->{current}]
    if ($obj->{data}->{current} < $obj->getCurveCount());
  $obj->{data}->{current} = undef;
  return undef;
}

=item $Line = $CurveDesc->line($curve_idx);

=cut

sub line {
  my $obj = shift;
  my $idx = shift; $idx = 0 if (!defined $idx);
  my $sect = $obj->section();
  my $options = $obj->getOptions();

  my $gdesc = $obj->parent()->parent();
  my $gsect = $gdesc->section();

  my $cycle = 0;
  if ($gsect->hasItem("linecycle")) {
    $cycle = scalar $gsect->getItemData("linecycle");
  }
  $idx = $idx % $cycle if ($cycle);

  my $line = Line->new($idx);
     $line = Line->new($sect->getItemData("line")) if ($sect->hasItem("line"));
     $line = Line->new("xbar") if ($options->{xbar});
     $line = Line->new("xbarval") if ($options->{xbarval});
     $line = Line->new("ybar") if ($options->{ybar});
     $line = Line->new("ybarval") if ($options->{ybarval});

  return $line;
}

=item $Mark = $CurveDesc->mark($curve_idx [,$CurveData]);

=cut

sub mark {
  my $obj = shift;
  my $idx = shift; $idx = 0 if (!defined $idx);
  my $curve = shift;
  my $Override = shift;
  my $sect = $obj->section();
  my $options = $obj->getOptions();
  my $line = $obj->line();

  return Mark->new("auto")
    if ($line->name() eq "xbar" || $line->name() eq "ybar" || 
    $line->name() eq "xbarval" || $line->name() eq "ybarval");

  my $gdesc = $obj->parent()->parent();
  my $gsect = $gdesc->section();

  return Mark->new("auto")
    if (!$gsect->hasItem("markcycle") && !$sect->hasItem("mark"));

  my $cycle = 0;
  if ($gsect->hasItem("markcycle")) {
    $cycle = scalar $gsect->getItemData("markcycle");
  }
  $idx = $idx % $cycle if ($cycle);

  my $mark = Mark->new($idx);
  if ($sect->hasItem("mark")) {
    if (defined $curve) {
      $mark = Mark->new($curve->getMark());
    } else {
      $mark = Mark->new($sect->getItemExpandedData("mark", $Override));
    }
  }
  return $mark;
}

=item $MarkScale = $CurveDesc->markscale($curve_idx);

=cut

sub markscale {
  my $obj = shift;
  my $idx = shift; $idx = 0 if (!defined $idx);
  my $sect = $obj->section();
  my $options = $obj->getOptions();

  my $gdesc = $obj->parent()->parent();
  my $gsect = $gdesc->section();
  my $g_options = $gdesc->getOptions();

  if ($sect->hasItem("markscale")) {
    return MarkScale->new($sect->getItemData("markscale"));
  }
  return MarkScale->new("auto") if (!$options->{markscale});

  my $cycle = 0;
  if ($gsect->hasItem("markscalecycle")) {
    $cycle = scalar $gsect->getItemData("markscalecycle");
  }
  $idx = $idx % $cycle if ($cycle);
  return MarkScale->new($idx);
}

=item $TextMarkScale = $CurveDesc->textmarkscale($curve_idx);

=cut

sub textmarkscale {
  my $obj = shift;
  my $idx = shift; $idx = 0 if (!defined $idx);
  my $sect = $obj->section();
  my $options = $obj->getOptions();

  my $gdesc = $obj->parent()->parent();
  my $gsect = $gdesc->section();
  my $g_options = $gdesc->getOptions();

  if ($sect->hasItem("markscale")) {
    return TextMarkScale->new($sect->getItemData("markscale"));
  }
  return TextMarkScale->new("auto") if (!$options->{markscale});

  my $cycle = 0;
  if ($gsect->hasItem("markscalecycle")) {
    $cycle = scalar $gsect->getItemData("markscalecycle");
  }
  $idx = $idx % $cycle if ($cycle);
  return TextMarkScale->new($idx);
}

=item $Color | $Gray = $CurveDesc->color($curve_idx);

=cut

sub color {
  my $obj = shift;
  my $idx = shift; $idx = 0 if (!defined $idx);
  my $sect = $obj->section();
  my $options = $obj->getOptions();

  my $gdesc = $obj->parent()->parent();
  my $gsect = $gdesc->section();
  my $g_options = $gdesc->getOptions();

  my $cycle = 0;
  my $color;
  if ($options->{grayscale} ||
     ($g_options->{grayscale} && !$options->{color}) ||
     ($sect->hasItem("gray") && !$sect->hasItem("color"))) {
    if ($gsect->hasItem("colorcycle")) {
      $cycle = scalar $gsect->getItemData("colorcycle");
    }
    $idx = $idx % $cycle if ($cycle);
    $color = Gray->new($idx);
    $color = Gray->new($sect->getItemData("gray")) if ($sect->hasItem("gray"));
  } else {
    if ($gsect->hasItem("colorcycle")) {
      $cycle = scalar $gsect->getItemData("colorcycle");
    }
    $idx = $idx % $cycle if ($cycle);
    $color = Color->new($idx);
    $color = Color->new($sect->getItemData("color"))
             if ($sect->hasItem("color"));
  }
  return $color;
}

=item $Aggregation = $CurveDesc->aggregation();

=cut

sub aggregation {
  my $obj = shift;
  my $sect = $obj->section();
  my $options = $obj->getOptions();

  my $gdesc = $obj->parent()->parent();
  my $gsect = $gdesc->section();

  my $aggr = Aggregation->new("none");
     $aggr = Aggregation->new($gsect->getItemData("aggr"))
             if ($gsect->hasItem("aggr"));
     $aggr = Aggregation->new($sect->getItemData("aggr"))
             if ($sect->hasItem("aggr"));
  return $aggr;
}

=item $int = $CurveDesc->xBar();

=cut

sub xBar {
  my $obj = shift;
  my $line = $obj->line();
  if ($line->name() eq "xbar" || $line->name() eq "xbarval") {
    return $obj->getCurveCount() || 1;
  }
  return 0;
}

=item $int = $CurveDesc->yBar();

=cut

sub yBar {
  my $obj = shift;
  my $line = $obj->line();
  if ($line->name() eq "ybar" || $line->name() eq "ybarval") {
    return $obj->getCurveCount() || 1;
  }
  return 0;
}

=item [$xval1, ...] = $CurveDesc->xValues();

=cut

sub xValues {
  my $obj = shift;
  my %val;
  my $c = $obj->getFirstCurve();
  while (defined $c) {
    foreach my $p (@{$c->xValues()}) {
      $val{$p} = 1;
    }
    $c = $obj->getNextCurve();
  }
  return [ (keys %val) ];
}

=item [$yval1, ...] = $CurveDesc->yValues();

=cut

sub yValues {
  my $obj = shift;
  my %val;
  my $c = $obj->getFirstCurve();
  while (defined $c) {
    foreach my $p (@{$c->yValues()}) {
      $val{$p} = 1;
    }
    $c = $obj->getNextCurve();
  }
  return [ (keys %val) ];
}

=back

=head3 Class BenchDesc: Desc

=over

=cut

package BenchDesc;
our @ISA = qw(Desc);

=item $BenchDesc = BenchDesc->new($BenchSection);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $sect = shift;
  my $obj = $class->SUPER::new($sect);
  bless($obj, $class),

  $obj->{data} = {};
  $obj->{data}->{bench} = undef;
  $obj->{data}->{filter} = undef;

  return $obj;
}

=item $BenchDesc = $BenchDesc->verify();

=cut

sub verify {
  my $obj = shift;
  my $sect = $obj->section();
  my $header = $sect->header();
  my $linenum = $header->getPosition();

  if (!$sect->hasItem("name")) {
    die "missing \"name\" in bench section (input line $linenum)\n";
  }

  foreach my $c (@{$obj->{children}}) {
    $c->verify();
  }

  return $obj;
}

=item $BenchDesc = $BenchDesc->calculate();

=cut

sub calculate {
  my $obj = shift;
  my $Override = shift;
  my $sect = $obj->section();

  $obj->verify();

  my ($bname) = $sect->getItemExpandedData("name", $Override);
  $obj->{data}->{bench} = Benchmark->get($DBH, $bname);
  $obj->{data}->{filter} = [];

  if ($sect->hasItem("select")) {
    my @list = $sect->getItemExpandedData("select", $Override);
    $obj->{data}->{filter} = [ @list ];
  }

  foreach my $c (@{$obj->{children}}) {
    $c->calculate($Override);
  }

  return $obj;
}

=item $Benchmark = $BenchDesc->bench();

=cut

sub bench {
  my $obj = shift;
  return $obj->{data}->{bench};
}

=item $string = $BenchDesc->selection();

=cut

sub selection {
  my $obj = shift;
  return join(" AND ", @{$obj->{data}->{filter}});
}

=item $int = $BenchDesc->xBar();

=cut

sub xBar {
  my $obj = shift;
  my $xbar = 0;
  foreach my $c (@{$obj->{children}}) {
    $xbar += $c->xBar();
  }
  return $xbar;
}

=item $int = $BenchDesc->yBar();

=cut

sub yBar {
  my $obj = shift;
  my $ybar = 0;
  foreach my $c (@{$obj->{children}}) {
    $ybar += $c->yBar();
  }
  return $ybar;
}

=item $CurveDesc = $BenchDesc->normalizationBase();

=cut

sub normalizationBase {
  my $obj = shift;
  foreach my $c (@{$obj->{children}}) {
    my $c_options = $c->getOptions();
    return $c if ($c_options->{base});
  }
  return undef;
}

=item [$xval1, ...] = $BenchDesc->xValues();

=cut

sub xValues {
  my $obj = shift;
  my %val;
  foreach my $c (@{$obj->{children}}) {
    foreach my $p (@{$c->xValues()}) {
      $val{$p} = 1;
    }
  }
  return [ (keys %val) ];
}

=item [$yval1, ...] = $BenchDesc->yValues();

=cut

sub yValues {
  my $obj = shift;
  my %val;
  foreach my $c (@{$obj->{children}}) {
    foreach my $p (@{$c->yValues()}) {
      $val{$p} = 1;
    }
  }
  return [ (keys %val) ];
}

=back

=head3 Class GraphDesc: Desc

=over

=cut

package GraphDesc;
our @ISA = qw(Desc);

=item $GraphDesc = GraphDesc->new($GraphSection);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $sect = shift;
  my $obj = $class->SUPER::new($sect);
  bless($obj, $class);

  return $obj;
}

=item $hash = $GraphDesc->getOptions();

=cut

sub getOptions {
  my $obj = shift;
  my @options = $obj->section()->getItemData("options");
  my $hash = {};
  foreach my $o (@options) {
    $hash->{$o} = 1;
  }
  return $hash;
}

=item $bool = $GraphDesc->skipped();

=cut

sub skipped {
  my $obj = shift;
  return $obj->getOptions()->{skip};
}

=item $AxisType = $GraphDesc->getXType();

=cut

sub getXType {
  my $obj = shift;
  my $sect = $obj->section();
  my $type = AxisType->new("category");
  $type = AxisType->new($sect->getItemData("xtype"))
          if ($sect->hasItem("xtype"));
  return $type;
}

=item $AxisType = $GraphDesc->getYType();

=cut

sub getYType {
  my $obj = shift;
  my $sect = $obj->section();
  my $type = AxisType->new("category");
  $type = AxisType->new($sect->getItemData("ytype"))
          if ($sect->hasItem("ytype"));
  return $type;
}

=item [$xval1, ...] = $GraphDesc->getXCat($Override);

=cut

sub getXCat {
  my $obj = shift;
  my $Override = shift;
  my $sect = $obj->section();
  my $catlist = [];
  if ($sect->hasItem("xcat")) {
    $catlist = [($sect->getItemExpandedData("xcat", $Override))];
  }
  return $catlist;
}

=item $int = $GraphDesc->getXSkip();

=cut

sub getXSkip {
  my $obj = shift;
  my $sect = $obj->section();
  my $skip = 0;
  if ($sect->hasItem("xskip")) {
    $skip = $sect->getItemData("xskip");
  }
  return $skip;
}

=item [$yval1, ...] = $GraphDesc->getYCat($Override);

=cut

sub getYCat {
  my $obj = shift;
  my $Override = shift;
  my $sect = $obj->section();
  my $catlist = [];
  if ($sect->hasItem("ycat")) {
    $catlist = [($sect->getItemExpandedData("ycat", $Override))];
  }
  return $catlist;
}

=item $int = $GraphDesc->getYSkip();

=cut

sub getYSkip {
  my $obj = shift;
  my $sect = $obj->section();
  my $skip = 0;
  if ($sect->hasItem("yskip")) {
    $skip = $sect->getItemData("yskip");
  }
  return $skip;
}

=item $num = $GraphDesc->getXBase();

=cut

sub getXBase {
  my $obj = shift;
  my $sect = $obj->section();
  my $xtype = $obj->getXType();
  return scalar $sect->getItemData("xbase") if ($sect->hasItem("xbase"));
  return scalar $sect->getItemData("xmin") if ($sect->hasItem("xmin"));
  return 1 if ($xtype->name() eq "log2");
  return 1 if ($xtype->name() eq "log10");
  return 0;
}

=item $num = $GraphDesc->getYBase();

=cut

sub getYBase {
  my $obj = shift;
  my $sect = $obj->section();
  my $ytype = $obj->getYType();
  return scalar $sect->getItemData("ybase") if ($sect->hasItem("ybase"));
  return scalar $sect->getItemData("ymin") if ($sect->hasItem("ymin"));
  return 1 if ($ytype->name() eq "log2");
  return 1 if ($ytype->name() eq "log10");
  return 0;
}

=item $GraphDesc = $GraphDesc->verify();

=cut

sub verify {
  my $obj = shift;
  my $sect = $obj->section();
  my $header = $sect->header();
  my $options = $obj->getOptions();
  my $linenum = $header->getPosition();

  return $obj if ($options->{skip});
  if (!$sect->hasItem("xtype")) {
    die "missing \"xtype\" in graph section (input line $linenum)\n";
  }
  if (!$sect->hasItem("ytype")) {
    die "missing \"ytype\" in graph section (input line $linenum)\n";
  }

  foreach my $b (@{$obj->{children}}) {
    $b->verify();
  }

  return $obj;
}

=item $GraphDesc = $GraphDesc->calculate();

=cut

sub calculate {
  my $obj = shift;
  my $Override = shift;
  $obj->verify();
  foreach my $b (@{$obj->{children}}) {
    $b->calculate($Override);
  }
}

=item $CurveDesc = $GraphDesc->normalizationBase();

=cut

sub normalizationBase {
  my $obj = shift;
  foreach my $b (@{$obj->{children}}) {
    my $curve = $b->normalizationBase();
    return $curve if (defined $curve);
  }
  return undef;
}

=item $int = $GraphDesc->xBar();

=cut

sub xBar {
  my $obj = shift; my $xbar = 0;
  foreach my $c (@{$obj->{children}}) {
    $xbar += $c->xBar();
  }
  return $xbar;
}

=item $int = $GraphDesc->yBar();

=cut

sub yBar {
  my $obj = shift;
  my $ybar = 0;
  foreach my $c (@{$obj->{children}}) {
    $ybar += $c->yBar();
  }
  return $ybar;
}

=item {1|0|-1} = $GraphDesc->xCmp($a, $b, $Override);

=cut

sub xCmp {
  my $obj = shift;
  my $a = shift;
  my $b = shift;
  my $Override = shift;
  my $type = $obj->getXType();
  return $a <=> $b if ($type->name() ne "category");
  my $cat = $obj->getXCat($Override);
  return $a cmp $b if ($#$cat < 0);
  my %pos; my $i = 0;
  while ($i <= $#$cat) {
    $pos{$cat->[$i]} = $i;
    $i += 1;
  }
  return $pos{$a} <=> $pos{$b} if (exists $pos{$a} && exists $pos{$b});
  return -1 if (exists $pos{$a});
  return 1 if (exists $pos{$b});
  return $a cmp $b;
}

=item {1|0|-1} = $GraphDesc->yCmp($a, $b, $Override);

=cut

sub yCmp {
  my $obj = shift;
  my $a = shift;
  my $b = shift;
  my $Override = shift;
  my $type = $obj->getYType();
  return $a <=> $b if ($type->name() ne "category");
  my $cat = $obj->getYCat($Override);
  return $a cmp $b if ($#$cat < 0);
  my %pos; my $i = 0;
  while ($i <= $#$cat) {
    $pos{$cat->[$i]} = $i;
    $i += 1;
  }
  return $pos{$a} <=> $pos{$b} if (exists $pos{$a} && exists $pos{$b});
  return -1 if (exists $pos{$a});
  return 1 if (exists $pos{$b});
  return $a cmp $b;
}

=item [$xval1, ...] = $GraphDesc->xValues();

=cut


sub xValues {
  my $obj = shift;
  my %val;
  foreach my $c (@{$obj->{children}}) {
    foreach my $p (@{$c->xValues()}) {
      $val{$p} = 1;
    }
  }
  return [ (sort {$obj->xCmp($a, $b)} keys %val) ];
}

=item [$yval1, ...] = $GraphDesc->yValues();

=cut

sub yValues {
  my $obj = shift;
  my %val;
  my $Override = shift;
  foreach my $c (@{$obj->{children}}) {
    foreach my $p (@{$c->yValues()}) {
      $val{$p} = 1;
    }
  }
  return [ (sort {$obj->yCmp($a, $b, $Override)} keys %val) ];
}

=item @list = $GraphDesc->dataList($graph_idx);

=cut

sub dataList {
  my $obj = shift;
  my $idx = shift; $idx = 0 if (!$idx);
  my $Override = shift;
  my $sect = $obj->section();
  my @str = ();

  my $options = $obj->getOptions();

  return () if ($options->{skip});

  # get basic x information

  my $xoff = 0;
  my $xgrp = 1;
  my $xpos = {};
  my $xtype = $obj->getXType();
  my $xcat = $obj->getXCat($Override);
  if ($xtype->name() eq "category") {
    my $xval = $obj->xValues($Override);
    if (!@$xcat) {
      my $i = 0; while ($i <= $#$xval) {
        $xpos->{$xval->[$i]} = $i + 1;
        push(@$xcat, $xval->[$i]);
        $i += 1;
      }
    } else {
      my $i = 0; while ($i <= $#$xcat) {
        $xpos->{$xcat->[$i]} = $i + 1;
        $i += 1;
      }
      my $max = $i;
      $i = 0;
      while ($i <= $#$xval) {
        $xpos->{$xval->[$i]} = $max + 1 if (!exists $xpos->{$xval->[$i]});
        $i += 1;
      }
    }
    if ($options->{xoffset}) {
      my $barcount = $obj->xBar();
      $xgrp = $barcount + 4;
      $xoff = int($barcount / 2);
    }
  }

#  elsif ($xtype->name() eq "numeric") {
#    if ($options->{xoffset}) {
#      my $barcount = $obj->xBar();
#      if ($barcount > 1) {
#        $xgrp = $barcount + 4;
#        $xoff = int($barcount / 2);
#      }
#    }
#  }

  # get basic y information

  my $yoff = 0;
  my $ygrp = 1;
  my $ypos = {};
  my $ytype = $obj->getYType();
  my $ycat = $obj->getYCat($Override);
  if ($ytype->name() eq "category") {
    my $yval = $obj->yValues();
    if (!@$ycat) {
      my $i = 0; while ($i <= $#$yval) {
        $ypos->{$yval->[$i]} = $i + 1;
        push(@$ycat, $yval->[$i]);
        $i += 1;
      }
    } else {
      my $i = 0; while ($i <= $#$ycat) {
        $ypos->{$ycat->[$i]} = $i + 1;
        $i += 1;
      }
      my $max = $i;
      $i = 0;
      while ($i <= $#$yval) {
        $ypos->{$yval->[$i]} = $max + 1 if (!exists $ypos->{$yval->[$i]});
        $i += 1;
      }
    }
    if ($options->{yoffset}) {
      my $barcount = $obj->yBar();
      $ygrp = $barcount + 4;
      $yoff = int($barcount / 2);
    }
  }

#  elsif ($ytype->name() eq "numeric") {
#    if ($options->{yoffset}) {
#      my $barcount = $obj->yBar();
#      if ($barcount > 1) {
#        $ygrp = $barcount + 4;
#        $yoff = int($barcount / 2);
#      }
#    }
#  }

  # curves

  my $curve_idx = 0;
  my $xbar_idx = 0;
  my $ybar_idx = 0;
  my $xaccum = {};
  my $yaccum = {};

  my $base_x = {};
  my $base_y = {};
  if ($options->{normalize}) {
    my $base_curve = $obj->normalizationBase();
    my $base_data  = $base_curve->getFirstCurve() if (defined $base_curve);
    if (defined($base_curve) && defined($base_data)) {
      my $base_aggr = $base_curve->aggregation();
      my $base_options = $base_curve->getOptions();
      my $do_accum = $base_options->{accum} && ($ytype->name() ne "category");
      my $base_accum = 0;
      foreach my $p (@{$base_curve->xValues()}) {
        my $p_array = $base_data->getY($p);
        if (defined $p_array) {
          my @y = sort {$obj->yCmp($a, $b, $Override)} @$p_array;
          my @set = $base_aggr->do([@y]);
          $base_y->{$p} = $set[0]->[0];
          if ($do_accum) {
            $base_y->{$p} += $base_accum;
            $base_accum = $base_y->{$p};
          }
        }
      }
      foreach my $p (@{$base_curve->yValues()}) {
        my $p_array = $base_data->getX($p);
        if (defined $p_array) {
          my @x = sort {$obj->xCmp($a, $b, $Override)} @$p_array;
          my @set = $base_aggr->do([@x]);
          $base_x->{$p} = $set[0]->[0];
        }
      }
    }
  }

  my $xbase = $obj->getXBase();
  my $ybase = $obj->getYBase();
  my $bdesc = $obj->getFirstChild();
  while (defined $bdesc) {
    my $cdesc = $bdesc->getFirstChild();
    while (defined $cdesc) {
      my $c_options = $cdesc->getOptions();
      my $curve = $cdesc->getFirstCurve();
      my $csect = $cdesc->section();
      my $do_accum = $c_options->{accum} && ($ytype->name() ne "category");
      while (defined $curve) {
        my $base_accum = 0;
        if (! $c_options->{skip} && $curve->pCount() != 0) {
          my $no_error = ($options->{no_error} && !$c_options->{error}) ||
                          $c_options->{no_error} ||
                          $c_options->{accum};

          my $curveID = sprintf "g%dc%d", $idx, $curve_idx;
          if ($options->{descriptive_data}) {
            my $gr = sprintf "g%d", $idx;
            if ($sect->hasItem("title")) {
              $gr = sprintf "%s",$sect->getItem("title")->expanded($Override);
            }
            my $cr = $curve->getLabel();
            if ($cr =~ /^\s*$/) {
              $cr = sprintf "c%d", $curve_idx;
            }
            $curveID = sprintf "%s_%s", $gr, $cr;
            my $replacement = ($SEPARATOR eq " ")? "_": " ";
            while ($curveID =~ /${SEPARATOR}/) {
              $curveID =~ s/${SEPARATOR}/${replacement}/g;
            }
          }

          if ($cdesc->line()->name() eq "ybar"|| 
              $cdesc->line()->name() eq "ybarval") {
            ###### Y-BASED ######
            my @yvalues = sort {$obj->yCmp($a, $b, $Override)}
                               @{$curve->yValues()};
            foreach my $yp (@yvalues) {
              my $y = $yp;
              if ($ytype->name() eq "category") {
                my $offset = ($cdesc->yBar())? $ybar_idx: $yoff;
                $y = $ypos->{$y} * $ygrp + $offset;
              }
#              if ($ytype->name() eq "numeric") {
#                my $offset = ($cdesc->yBar())? $ybar_idx: $yoff;
#                $y = ($y * $ygrp + $offset) / $ygrp;
#              }
              my @xvalues = sort {$obj->xCmp($a, $b, $Override)}
                                 @{$curve->getX($yp)};
              my $aggr = $cdesc->aggregation();
              foreach my $xset ($aggr->do([@xvalues])) {
                my ($xp, $low, $high) = @$xset;
                my $x = $xp;
                if ($xtype->name() eq "category") {
                  $x = $xpos->{$x} * $xgrp + $xoff;
                  $low = $x;
                  $high = $x;
                }
                if ($options->{normalize}) {
                  if (exists $base_x->{$yp} && $base_x->{$yp} != 0) {
                    my $base_x = $base_x->{$yp};
                    if ($xtype->name() eq "category") {
                      $base_x = $xpos->{$base_x} * $xgrp + $xoff;
                    }
                    $x = $x / $base_x;
                    $low = $low / $base_x;
                    $high = $high / $base_x;
                  } elsif (!exists $base_x->{$yp}) {
                    $x = $xbase;
                    $low = $xbase;
                    $high = $xbase;
                  }
                }
                if ($options->{stack} && !$c_options->{no_stack}) {
                  $xaccum->{$yp} = 0 if (!exists $xaccum->{$yp});
                  $x += $xaccum->{$yp};
                  $low += $xaccum->{$yp};
                  $high += $xaccum->{$yp};
                  $xaccum->{$yp} = $x;
                }
                if ($no_error) {
                  push(@str, sprintf("%s%s%s%s%s%s%s%s%s", $curveID,
                             $SEPARATOR, $xp,
                             $SEPARATOR, $yp,
                             $SEPARATOR, $x,
                             $SEPARATOR, $y));
                } else {
                  push(@str, sprintf("%s%s%s%s%s%s%s%s%s%s%s%s%s", $curveID,
                             $SEPARATOR, $xp,
                             $SEPARATOR, $yp,
                             $SEPARATOR, $x,
                             $SEPARATOR, $y,
                             $SEPARATOR, $low,
                             $SEPARATOR, $high));
                }
              }
            }
          } else {
            ###### X-BASED ######
            my @xvalues = sort {$obj->xCmp($a, $b, $Override)}
                               @{$curve->xValues()};
            foreach my $xp (@xvalues) {
              my $x = $xp;
              if ($xtype->name() eq "category") {
                my $offset = ($cdesc->xBar())? $xbar_idx: $xoff;
                $x = $xpos->{$x} * $xgrp + $offset;
              }
#              if ($xtype->name() eq "numeric") {
#                my $offset = ($cdesc->xBar())? $xbar_idx: $xoff;
#                $x = ($x * $xgrp + $offset) / $xgrp;
#              }
              my @yvalues = sort {$obj->yCmp($a, $b, $Override)}
                                 @{$curve->getY($xp)};
              my $aggr = $cdesc->aggregation();
              foreach my $yset ($aggr->do([@yvalues])) {
                my ($yp, $low, $high) = @$yset;
                my $y = $yp;
                if ($ytype->name() eq "category") {
                  $y = $ypos->{$y} * $ygrp + $yoff;
                  $low = $y;
                  $high = $y;
                }
                if ($do_accum) {
                  $y += $base_accum;
                  $base_accum = $y;
                }
                if ($options->{normalize}) {
                  if (exists $base_y->{$xp} && $base_y->{$xp} != 0) {
                    my $base_y = $base_y->{$xp};
                    if ($ytype->name() eq "category") {
                      $base_y = $ypos->{$base_y} * $ygrp + $yoff;
                    }
                    $y = $y / $base_y;
                    $low = $low / $base_y;
                    $high = $high / $base_y;
                  } elsif (!exists $base_y->{$xp}) {
                    $y = $ybase;
                    $low = $ybase;
                    $high = $ybase;
                  }
                }
                if ($options->{stack} && !$c_options->{no_stack}) {
                  $yaccum->{$xp} = 0 if (!exists $yaccum->{$xp});
                  $y += $yaccum->{$xp};
                  $low += $yaccum->{$xp};
                  $high += $yaccum->{$xp};
                  $yaccum->{$xp} = $y;
                }
                if ($no_error) {
                  push(@str, sprintf("%s%s%s%s%s%s%s%s%s", $curveID,
                             $SEPARATOR, $xp,
                             $SEPARATOR, $yp,
                             $SEPARATOR, $x,
                             $SEPARATOR, $y));
                } else {
                  push(@str, sprintf("%s%s%s%s%s%s%s%s%s%s%s%s%s", $curveID,
                             $SEPARATOR, $xp,
                             $SEPARATOR, $yp,
                             $SEPARATOR, $x,
                             $SEPARATOR, $y,
                             $SEPARATOR, $low,
                             $SEPARATOR, $high));
                }
              }
            }
          }
          push(@str, "");
        }
        $curve_idx += 1 if (!$c_options->{skip});
        $xbar_idx += 1
          if (!$c_options->{skip} && $cdesc->xBar() && $options->{xoffset});
        $ybar_idx += 1
          if (!$c_options->{skip} && $cdesc->yBar() && $options->{yoffset});
        $curve = $cdesc->getNextCurve();
      }
      $cdesc = $bdesc->getNextChild();
    }
    $bdesc = $obj->getNextChild();
  }

  push(@str, "");
  return @str;
}

=item string = $GraphDesc->data($graph_idx);

=cut

sub data {
  my $obj = shift;
  return join("\n", ($obj->dataList(@_)), "");
}


=item $xml = $GraphDesc->xml($graph_idx);

=cut

sub xml {
  my $obj = shift;
  my $idx = shift; $idx = 0 if (!$idx);
  my $Override = shift;
  my $sect = $obj->section();
  my $xml = XML::LibXML::Element->new("graph");
  my $xml_xaxis = XML::LibXML::Element->new("xaxis");
  my $xml_yaxis = XML::LibXML::Element->new("yaxis");

  my $options = $obj->getOptions();

  return undef if ($options->{skip});
  $xml->setAttribute("id", $idx);
  $xml->setAttribute("newpage", $options->{newpage}? "true": "false");
  $xml->setAttribute("stack", $options->{stack}? "true": "false");

  # get basic x information

  my $org = ($options->{stack})? 256: 0;

  my $xoff = 0;
  my $xgrp = 1;
  my $xpos = {};
  my $xtype = $obj->getXType();
  my $xcat = $obj->getXCat($Override);
  $xml_xaxis->setAttribute("type", $xtype->name());

  if ($xtype->name() eq "category") {
    my $xval = $obj->xValues($Override);
    if (!@$xcat) {
      my $i = 0; while ($i <= $#$xval) {
        $xpos->{$xval->[$i]} = $i + 1;
        push(@$xcat, $xval->[$i]);
        $i += 1;
      }
    } else {
      my $i = 0; while ($i <= $#$xcat) {
        $xpos->{$xcat->[$i]} = $i + 1;
        $i += 1;
      }
      my $max = $i;
      $i = 0;
      while ($i <= $#$xval) {
        $xpos->{$xval->[$i]} = $max + 1 if (!exists $xpos->{$xval->[$i]});
        $i += 1;
      }
    }
    if ($options->{xoffset}) {
      my $barcount = $obj->xBar();
      $xgrp = $barcount + 4;
      $xoff = int($barcount / 2);
    }
  }
#  elsif ($xtype->name() eq "numeric") {
#    if ($options->{xoffset}) {
#      my $barcount = $obj->xBar();
#      if ($barcount > 1) {
#        $xgrp = $barcount + 4;
#        $xoff = int($barcount / 2);
#      }
#    }
#  }

  # get basic y information

  my $yoff = 0;
  my $ygrp = 1;
  my $ypos = {};
  my $ytype = $obj->getYType();
  my $ycat = $obj->getYCat($Override);
  $xml_yaxis->setAttribute("type", $ytype->name());

  if ($ytype->name() eq "category") {
    my $yval = $obj->yValues();
    if (!@$ycat) {
      my $i = 0; while ($i <= $#$yval) {
        $ypos->{$yval->[$i]} = $i + 1;
        push(@$ycat, $yval->[$i]);
        $i += 1;
      }
    } else {
      my $i = 0; while ($i <= $#$ycat) {
        $ypos->{$ycat->[$i]} = $i + 1;
        $i += 1;
      }
      my $max = $i;
      $i = 0;
      while ($i <= $#$yval) {
        $ypos->{$yval->[$i]} = $max + 1 if (!exists $ypos->{$yval->[$i]});
        $i += 1;
      }
    }
    if ($options->{yoffset}) {
      my $barcount = $obj->yBar();
      $ygrp = $barcount + 4;
      $yoff = int($barcount / 2);
    }
  }
#  elsif ($ytype->name() eq "numeric") {
#    if ($options->{yoffset}) {
#      my $barcount = $obj->yBar();
#      if ($barcount > 1) {
#        $ygrp = $barcount + 4;
#        $yoff = int($barcount / 2);
#      }
#    }
#  }

  # title
  if ($sect->hasItem("title")) {
    my $title = $sect->getItem("title");
    $xml->appendTextChild("title", $title->expanded($Override));
  }

  # xaxis
  $xml->appendChild($xml_xaxis);

  if ($sect->hasItem("xlabel")) {
    my $label = $sect->getItem("xlabel");
    $xml_xaxis->appendTextChild("label", $label->expanded($Override));
  }


  # yaxis
  $xml->appendChild($xml_yaxis);

  if ($sect->hasItem("ylabel")) {
    my $label = $sect->getItem("ylabel");
    $xml_yaxis->appendTextChild("label", $label->expanded($Override));
  }

  # curves

  my $curve_idx = 0;
  my $xbar_idx = 0;
  my $ybar_idx = 0;
  my $xaccum = {};
  my $yaccum = {};

  my $base_x = {};
  my $base_y = {};
  if ($options->{normalize}) {
    my $base_curve = $obj->normalizationBase();
    my $base_data  = $base_curve->getFirstCurve() if (defined $base_curve);
    if (defined($base_curve) && defined($base_data)) {
      my $base_aggr = $base_curve->aggregation();
      my $base_options = $base_curve->getOptions();
      my $do_accum = $base_options->{accum} && ($ytype->name() ne "category");
      my $base_accum = 0;
      foreach my $p (@{$base_curve->xValues()}) {
        my $p_array = $base_data->getY($p);
        if (defined $p_array) {
          my @y = sort {$obj->yCmp($a, $b, $Override)} @$p_array;
          my @set = $base_aggr->do([@y]);
          $base_y->{$p} = $set[0]->[0];
          if ($do_accum) {
            $base_y->{$p} += $base_accum;
            $base_accum = $base_y->{$p};
          }
        }
      }
      foreach my $p (@{$base_curve->yValues()}) {
        my $p_array = $base_data->getX($p);
        if (defined $p_array) {
          my @x = sort {$obj->xCmp($a, $b, $Override)} @$p_array;
          my @set = $base_aggr->do([@x]);
          $base_x->{$p} = $set[0]->[0];
        }
      }
    }
  }

  my $xbase = $obj->getXBase();
  my $ybase = $obj->getYBase();
  my $bdesc = $obj->getFirstChild();
  while (defined $bdesc) {
    my $cdesc = $bdesc->getFirstChild();
    while (defined $cdesc) {
      my $c_options = $cdesc->getOptions();
      my $curve = $cdesc->getFirstCurve();
      my $csect = $cdesc->section();
      my $do_accum = $c_options->{accum} && ($ytype->name() ne "category");
      while (defined $curve) {
        my $base_accum = 0;
        if (! $c_options->{skip} && $curve->pCount() != 0) {
          my $no_error = ($options->{no_error} && !$c_options->{error}) ||
                          $c_options->{no_error} ||
                          $c_options->{accum};
          
          my $xml_curve = XML::LibXML::Element->new("curve");
          $xml->appendChild($xml_curve);
          $xml_curve->setAttribute("id", $curve_idx);
          $xml_curve->setAttribute("seq", $org);
          $xml_curve->setAttribute("no_stack", 1) if ($c_options->{no_stack});
          if ($options->{stack}) {
            $xml->setAttribute("stack", $c_options->{no_stack}?"false":"true");
          }

          $org += ($options->{stack})? -1: 1;

          $xml_curve->appendTextChild("label", $curve->getLabel())
             if ($curve->getLabel() =~ /\S/);

          if ($cdesc->line()->name() eq "ybar" || 
            $cdesc->line()->name() eq "ybarval") {
            ###### Y-BASED ######
            my @yvalues = sort {$obj->yCmp($a, $b, $Override)}
                               @{$curve->yValues()};
            foreach my $yp (@yvalues) {
              my $y = $yp;
              if ($ytype->name() eq "category") {
                my $offset = ($cdesc->yBar())? $ybar_idx: $yoff;
                $y = $ypos->{$y} * $ygrp + $offset;
              }
#              if ($ytype->name() eq "numeric") {
#                my $offset = ($cdesc->yBar())? $ybar_idx: $yoff;
#                $y = ($y * $ygrp + $offset) / $ygrp;
#              }
              my @xvalues = sort {$obj->xCmp($a, $b, $Override)}
                                 @{$curve->getX($yp)};
              my $aggr = $cdesc->aggregation();
              my $xidx = 0;
              foreach my $xset ($aggr->do([@xvalues])) {
                my ($xp, $low, $high) = @$xset;
                my $x = $xp;
                if ($xtype->name() eq "category") {
                  $x = $xpos->{$x} * $xgrp + $xoff;
                  $low = $x;
                  $high = $x;
                }
                if ($options->{normalize}) {
                  if (exists $base_x->{$yp} && $base_x->{$yp} != 0) {
                    my $base_x = $base_x->{$yp};
                    if ($xtype->name() eq "category") {
                      $base_x = $xpos->{$base_x} * $xgrp + $xoff;
                    }
                    $x = $x / $base_x;
                    $low = $low / $base_x;
                    $high = $high / $base_x;
                  } elsif (!exists $base_x->{$yp}) {
                    $x = $xbase;
                    $low = $xbase;
                    $high = $xbase;
                  }
                }
                if ($options->{stack} && !$c_options->{no_stack}) {
                  $xaccum->{$yp} = 0 if (!exists $xaccum->{$yp});
                  $x += $xaccum->{$yp};
                  $low += $xaccum->{$yp};
                  $high += $xaccum->{$yp};
                  $xaccum->{$yp} = $x;
                }

                my $xml_pt->XML::LibXML::Element->new("point");
                $xml_curve->appendChild($xml_pt);
                my $xml_x->XML::LibXML::Element->new("x");
                $xml_pt->appendChild($xml_x);
                $xml_x->setAttribute("coord", $x);
                if (!$no_error) {
                  $xml_x->setAttribute("emin", $low);
                  $xml_x->setAttribute("emax", $high);
                }
                $xml_x->appendText($xp);
                my $xml_y = XML::LibXML::Element->new("y");
                $xml_pt->appendChild($xml_y);
                $xml_y->setAttribute("coord", $y);
                $xml_y->appendText($yp);
              }
            }
          } else {
            ###### X-BASED ######
            my @xvalues = sort {$obj->xCmp($a, $b, $Override)}
                               @{$curve->xValues()};
            foreach my $xp (@xvalues) {
              my $x = $xp;
              if ($xtype->name() eq "category") {
                my $offset = ($cdesc->xBar())? $xbar_idx: $xoff;
                $x = $xpos->{$x} * $xgrp + $offset;
              }
#              if ($xtype->name() eq "numeric") {
#                my $offset = ($cdesc->xBar())? $xbar_idx: $xoff;
#                $x = ($x * $xgrp + $offset) / $xgrp;
#              }
              my @yvalues = sort {$obj->yCmp($a, $b, $Override)}
                                 @{$curve->getY($xp)};
              my $aggr = $cdesc->aggregation();
              foreach my $yset ($aggr->do([@yvalues])) {
                my ($yp, $low, $high) = @$yset;
                my $y = $yp;
                if ($ytype->name() eq "category") {
                  $y = $ypos->{$y} * $ygrp + $yoff;
                  $low = $y;
                  $high = $y;
                }
                if ($do_accum) {
                  $y += $base_accum;
                  $base_accum = $y;
                }
                if ($options->{normalize}) {
                  if (exists $base_y->{$xp} && $base_y->{$xp} != 0) {
                    my $base_y = $base_y->{$xp};
                    if ($ytype->name() eq "category") {
                      $base_y = $ypos->{$base_y} * $ygrp + $yoff;
                    }
                    $y = $y / $base_y;
                    $low = $low / $base_y;
                    $high = $high / $base_y;
                  } elsif (!exists $base_y->{$xp}) {
                    $y = $ybase;
                    $low = $ybase;
                    $high = $ybase;
                  }
                }
                if ($options->{stack} && !$c_options->{no_stack}) {
                  $yaccum->{$xp} = 0 if (!exists $yaccum->{$xp});
                  $y += $yaccum->{$xp};
                  $low += $yaccum->{$xp};
                  $high += $yaccum->{$xp};
                  $yaccum->{$xp} = $y;
                }
                my $xml_pt = XML::LibXML::Element->new("point");
                $xml_curve->appendChild($xml_pt);
                my $xml_x = XML::LibXML::Element->new("x");
                $xml_pt->appendChild($xml_x);
                $xml_x->setAttribute("coord", $x);
                $xml_x->appendText($xp);
                my $xml_y = XML::LibXML::Element->new("y");
                $xml_pt->appendChild($xml_y);
                $xml_y->setAttribute("coord", $y);
                if (!$no_error) {
                  $xml_y->setAttribute("emin", $low);
                  $xml_y->setAttribute("emax", $high);
                }
                $xml_y->appendText($yp);
              }
            }
          }
        }
        $curve_idx += 1 if (!$c_options->{skip});
        $xbar_idx += 1
          if (!$c_options->{skip} && $cdesc->xBar() && $options->{xoffset});
        $ybar_idx += 1
          if (!$c_options->{skip} && $cdesc->yBar() && $options->{yoffset});
        $curve = $cdesc->getNextCurve();
      }
      $cdesc = $bdesc->getNextChild();
    }
    $bdesc = $obj->getNextChild();
  }

  return $xml;
}

=item @list = $GraphDesc->jgraphList($graph_idx);

=cut

sub jgraphList {
  my $obj = shift;
  my $idx = shift; $idx = 0 if (!$idx);
  my $Override = shift;
  my $sect = $obj->section();
  my @str = ();

  my $options = $obj->getOptions();

  return () if ($options->{skip});
  push(@str, "newpage") if ($options->{newpage} && $idx > 0);

  my $font = undef;
  my $fontsize = undef;
  my $size = undef
  $font = $sect->getItemData("font") if ($sect->hasItem("font"));
  $fontsize = $sect->getItemData("fontsize") if ($sect->hasItem("fontsize"));
  $size = $sect->getItemData("size") if ($sect->hasItem("size"));

  # get basic x information

  my $org = ($options->{stack})? 256: 0;

  my $xoff = 0;
  my $xgrp = 1;
  my $xpos = {};
  my $xtype = $obj->getXType();
  my $xcat = $obj->getXCat($Override);
  my $xskip = $obj->getXSkip();
  if ($xtype->name() eq "category") {
    my $xval = $obj->xValues($Override);
    if (!@$xcat) {
      my $i = 0; while ($i <= $#$xval) {
        $xpos->{$xval->[$i]} = $i + 1;
        push(@$xcat, $xval->[$i]);
        $i += 1;
      }
    } else {
      my $i = 0; while ($i <= $#$xcat) {
        $xpos->{$xcat->[$i]} = $i + 1;
        $i += 1;
      }
      my $max = $i;
      $i = 0;
      while ($i <= $#$xval) {
        $xpos->{$xval->[$i]} = $max + 1 if (!exists $xpos->{$xval->[$i]});
        $i += 1;
      }
    }
    if ($options->{xoffset}) {
      my $barcount = $obj->xBar();
      $xgrp = $barcount + 4;
      $xoff = int($barcount / 2);
    }
  }
#  elsif ($xtype->name() eq "numeric") {
#    if ($options->{xoffset}) {
#      my $barcount = $obj->xBar();
#      if ($barcount > 1) {
#        $xgrp = $barcount + 4;
#        $xoff = int($barcount / 2);
#      }
#    }
#  }

  # get basic y information

  my $yoff = 0;
  my $ygrp = 1;
  my $ypos = {};
  my $ytype = $obj->getYType();
  my $ycat = $obj->getYCat($Override);
  my $yskip = $obj->getYSkip();
  if ($ytype->name() eq "category") {
    my $yval = $obj->yValues();
    if (!@$ycat) {
      my $i = 0; while ($i <= $#$yval) {
        $ypos->{$yval->[$i]} = $i + 1;
        push(@$ycat, $yval->[$i]);
        $i += 1;
      }
    } else {
      my $i = 0; while ($i <= $#$ycat) {
        $ypos->{$ycat->[$i]} = $i + 1;
        $i += 1;
      }
      my $max = $i;
      $i = 0;
      while ($i <= $#$yval) {
        $ypos->{$yval->[$i]} = $max + 1 if (!exists $ypos->{$yval->[$i]});
        $i += 1;
      }
    }
    if ($options->{yoffset}) {
      my $barcount = $obj->yBar();
      $ygrp = $barcount + 4;
      $yoff = int($barcount / 2);
    }
  }
#  elsif ($ytype->name() eq "numeric") {
#    if ($options->{yoffset}) {
#      my $barcount = $obj->yBar();
#      if ($barcount > 1) {
#        $ygrp = $barcount + 4;
#        $yoff = int($barcount / 2);
#      }
#    }
#  }

  # header
  push(@str, "newgraph");
  push(@str, "clip");

  # title
  if ($sect->hasItem("title")) {
    if ($sect->hasItem("title_font")) {
      push(@str, sprintf("title font \"%s\"",
                 $sect->getItemData("title_font")));
    } elsif (defined $font) {
      push(@str, sprintf("title font \"%s\"", $font));
    }
    if ($sect->hasItem("title_fontsize")) {
      push(@str, sprintf("title fontsize %d",
                 $sect->getItemData("title_fontsize")));
    } elsif (defined $fontsize) {
      push(@str, sprintf("title fontsize %d", $fontsize));
    }
    my $title = $sect->getItem("title");
    push(@str, sprintf("title : %s", $title->expanded($Override)));
  }

  # legend
  if ($sect->hasItem("legend")) {
    my $just = $sect->getItemData("legend");
    if ($just eq "none") {
      push(@str, "legend off");
    } else {
      push(@str, "legend on");
      if ($sect->hasItem("legend_font")) {
        push(@str, sprintf("legend defaults font \"%s\"",
                   $sect->getItemData("legend_font")));
      } elsif (defined $font) {
        push(@str, sprintf("legend defaults font \"%s\"", $font));
      }
      if ($sect->hasItem("legend_fontsize")) {
        push(@str, sprintf("legend defaults fontsize %d",
                   $sect->getItemData("legend_fontsize")));
      } elsif (defined $fontsize) {
        push(@str, sprintf("legend defaults fontsize %s", $fontsize));
      }
      if ($sect->hasItem("legend_x")) {
        push(@str, sprintf("legend defaults x %s",
             $sect->getItemExpandedData("legend_x", $Override)));
      }
      if ($sect->hasItem("legend_y")) {
        push(@str, sprintf("legend defaults y %s",
             $sect->getItemExpandedData("legend_y", $Override)));
      }
      my $j = Justification->new($just);
      push(@str, sprintf("legend defaults %s", $j->jgraph()));
    }
  } else {
    push(@str, "legend off");
  }

  # global jgraph commands
  if ($sect->hasItem("jgraph")) {
    push(@str, ($sect->getItemExpandedData("jgraph", $Override)));
  }

  push(@str, "");

  # xaxis
  push(@str, "xaxis");

  push(@str, sprintf("draw_at %s", $obj->getYBase()))
    if (!$options->{top_axis});
  if ($sect->hasItem("xsize")) {
    push(@str, sprintf("size %s\n", $sect->getItemData("xsize")));
  } elsif (defined $size) {
    push(@str, sprintf("size %s\n", $size));
  }
  if ($sect->hasItem("xtype")) {
    my $t = AxisType->new($sect->getItemData("xtype"));
    push(@str, $t->jgraph()) if ($t->jgraph() ne "");
  }
  if ($sect->hasItem("xlabel")) {
    if ($sect->hasItem("label_font")) {
      push(@str, sprintf("label font \"%s\"",
                 $sect->getItemData("label_font")));
    } elsif (defined $font) {
      push(@str, sprintf("label font \"%s\"", $font));
    };
    if ($sect->hasItem("label_fontsize")) {
      push(@str, sprintf("label fontsize %d",
                 $sect->getItemData("label_fontsize")));
    } elsif (defined $fontsize) {
      push(@str, sprintf("label fontsize %d", $fontsize));
    }
    my $label = $sect->getItem("xlabel");
    push(@str, sprintf("label : %s", $label->expanded($Override)));
  }

  # xaxis hashes
  if ($options->{top_axis}) {
    push(@str, "hash_scale +1.0");
  }
  if ($sect->hasItem("hash_font")) {
    push(@str, sprintf("hash_labels font \"%s\"",
               $sect->getItemData("hash_font")));
  } elsif (defined $font) {
    push(@str, sprintf("hash_labels font \"%s\"", $font));
  }
  if ($sect->hasItem("hash_fontsize")) {
    push(@str, sprintf("hash_labels fontsize %d",
               $sect->getItemData("hash_fontsize")));
  } elsif (defined $fontsize) {
    push(@str, sprintf("hash_labels fontsize %d", $fontsize));
  }
  if ($options->{xrotate_labels}) {
    push(@str, sprintf("hash_labels vjc hjr rotate 90"));
  }
  if ($options->{no_xhash}) {
    push(@str, "no_auto_hash_labels");
    push(@str, "no_auto_hash_marks");
  } elsif ($options->{no_xhash_labels}) {
    push(@str, "no_auto_hash_labels");
  }
  if ($xtype->name() eq "category") {
    push(@str, "min 0");
    push(@str, sprintf("max %d", ($#$xcat + 2) * $xgrp + $xoff));
    if (!$options->{no_xhash}) {
      push(@str, "no_auto_hash_labels");
      push(@str, "no_auto_hash_marks");
      my $skiphash = 0;
      foreach my $v (@$xcat) {
        if (!$skiphash && $v ne "_") {
          push(@str, sprintf("hash_at %f", $xpos->{$v} * $xgrp + $xoff));
          if (!$options->{no_xhash_labels}) {
              
              # Strip leading and trailing white spaces 
              # and first/last occurrence  of |

              my $hash_label = $v;

              # $hash_label =~ s/^(\s*\|)?|(\|\s*)?$//g;
              $hash_label =~ s/^(\s*\|)?|(\|\s*)?$//g;

              push(@str, sprintf("hash_label at %f : %s",
                               $xpos->{$v} * $xgrp + $xoff, $hash_label));
          }
        } elsif ($v ne "_") {
          push(@str, sprintf("mhash_at %f", $xpos->{$v} * $xgrp + $xoff));
        }
        $skiphash = ($skiphash + 1) % ($xskip + 1);
      }
    }
  } else {
    if ($sect->hasItem("xmin")) {
      push(@str, sprintf("min %s", scalar $sect->getItemData("xmin")));
    } else {
      if ($xtype->name() eq "numeric") {
        push(@str, "min 0") if (!$options->{xno_min});
      } else {
        push(@str, "min 1");
      }
    }
    if ($sect->hasItem("xmax")) {
      push(@str, sprintf("max %s", scalar $sect->getItemData("xmax")));
    }
  }

  # xaxis jgraph commands
  if ($sect->hasItem("xjgraph")) {
    push(@str, ($sect->getItemExpandedData("xjgraph", $Override)));
  }

  push(@str, "");


  # yaxis
  push(@str, "yaxis");

  push(@str, sprintf("draw_at %s", $obj->getXBase()))
    if (!$options->{right_axis});
  if ($sect->hasItem("ysize")) {
    push(@str, sprintf("size %s\n", $sect->getItemData("ysize")));
  } elsif (defined $size) {
    push(@str, sprintf("size %s\n", $size));
  }
  if ($sect->hasItem("ytype")) {
    my $t = AxisType->new($sect->getItemData("ytype"));
    push(@str, $t->jgraph()) if ($t->jgraph() ne "");
  }
  if ($sect->hasItem("ylabel")) {
    if ($sect->hasItem("label_font")) {
      push(@str, sprintf("label font \"%s\"",
                 $sect->getItemData("label_font")));
    } elsif (defined $font) {
      push(@str, sprintf("label font \"%s\"", $font));
    }
    if ($sect->hasItem("label_fontsize")) {
      push(@str, sprintf("label fontsize %d",
                 $sect->getItemData("label_fontsize")));
    } elsif (defined $fontsize) {
      push(@str, sprintf("label fontsize %d", $fontsize));
    }
    my $label = $sect->getItem("ylabel");
    push(@str, sprintf("label : %s", $label->expanded($Override)));
  }

  # yaxis hashes
  if ($options->{right_axis}) {
    push(@str, "hash_scale +1.0");
  }
  if ($sect->hasItem("hash_font")) {
    push(@str, sprintf("hash_labels font \"%s\"",
               $sect->getItemData("hash_font")));
  } elsif (defined $font) {
    push(@str, sprintf("hash_labels font \"%s\"", $font));
  }
  if ($sect->hasItem("hash_fontsize")) {
    push(@str, sprintf("hash_labels fontsize %d",
               $sect->getItemData("hash_fontsize")));
  } elsif (defined $fontsize) {
    push(@str, sprintf("hash_labels fontsize %d", $fontsize));
  }
  if ($options->{yrotate_labels}) {
    push(@str, sprintf("hash_labels vjc hjc rotate 90"));
  }
  if ($options->{no_yhash}) {
    push(@str, "no_auto_hash_labels");
    push(@str, "no_auto_hash_marks");
  } elsif ($options->{no_yhash_labels}) {
    push(@str, "no_auto_hash_labels");
  }
  if ($ytype->name() eq "category") {
    push(@str, "min 0");
    push(@str, sprintf("max %d", ($#$ycat + 2) * $ygrp + $yoff));
    if (!$options->{no_yhash}) {
      push(@str, "no_auto_hash_labels");
      push(@str, "no_auto_hash_marks");
      my $skiphash = 0;
      foreach my $v (@$ycat) {
        if (!$skiphash && $v ne "_") {
          push(@str, sprintf("hash_at %f", $ypos->{$v} * $ygrp + $yoff));
          if (!$options->{no_yhash_labels}) {
              
              # Strip leading and trailing white spaces 
              # and first/last occurrence  of |

              my $hash_label = $v;
              $hash_label =~ s/^(\s*\|)?|(\|\s*)?$//g;

              push(@str, sprintf("hash_label at %f : %s",
                               $ypos->{$v} * $ygrp + $yoff, $hash_label));
          }
        } elsif ($v ne "_") {
          push(@str, sprintf("mhash_at %f", $ypos->{$v} * $ygrp + $yoff));
        }
        $skiphash = ($skiphash + 1) % ($yskip + 1);
      }
    }
  } else {
    if ($sect->hasItem("ymin")) {
      push(@str, sprintf("min %s", scalar $sect->getItemData("ymin")));
    } else {
      if ($ytype->name() eq "numeric") {
        push(@str, "min 0") if (!$options->{yno_min});
      } else {
        push(@str, "min 1");
      }
    }
    if ($sect->hasItem("ymax")) {
      push(@str, sprintf("max %s", scalar $sect->getItemData("ymax")));
    }
  }

  # yaxis jgraph commands
  if ($sect->hasItem("yjgraph")) {
    push(@str, ($sect->getItemExpandedData("yjgraph", $Override)));
  }

  push(@str, "");

  # curves

  my $curve_idx = 0;
  my $xbar_idx = 0;
  my $ybar_idx = 0;
  my $xaccum = {};
  my $yaccum = {};

  my $base_x = {};
  my $base_y = {};
  if ($options->{normalize}) {
    my $base_curve = $obj->normalizationBase();
    my $base_data  = $base_curve->getFirstCurve() if (defined $base_curve);
    if (defined($base_curve) && defined($base_data)) {
      my $base_aggr = $base_curve->aggregation();
      my $base_options = $base_curve->getOptions();
      my $do_accum = $base_options->{accum} && ($ytype->name() ne "category");
      my $base_accum = 0;
      foreach my $p (@{$base_curve->xValues()}) {
        my $p_array = $base_data->getY($p);
        if (defined $p_array) {
          my @y = sort {$obj->yCmp($a, $b, $Override)} @$p_array;
          my @set = $base_aggr->do([@y]);
          $base_y->{$p} = $set[0]->[0];
          if ($do_accum) {
            $base_y->{$p} += $base_accum;
            $base_accum = $base_y->{$p};
          }
        }
      }
      foreach my $p (@{$base_curve->yValues()}) {
        my $p_array = $base_data->getX($p);
        if (defined $p_array) {
          my @x = sort {$obj->xCmp($a, $b, $Override)} @$p_array;
          my @set = $base_aggr->do([@x]);
          $base_x->{$p} = $set[0]->[0];
        }
      }
    }
  }

  my $xbase = $obj->getXBase();
  my $ybase = $obj->getYBase();
  my $bdesc = $obj->getFirstChild();
  while (defined $bdesc) {
    my $cdesc = $bdesc->getFirstChild();
    while (defined $cdesc) {
      my $c_options = $cdesc->getOptions();
      my $curve = $cdesc->getFirstCurve();
      my $csect = $cdesc->section();
      my $do_accum = ($c_options->{accum} && ($ytype->name() ne "category"));
      while (defined $curve) {
        my $base_accum = 0;
        if (! $c_options->{skip} && $curve->pCount() != 0) {
          my $no_error = ($options->{no_error} && !$c_options->{error}) ||
                          $c_options->{no_error} ||
                          $c_options->{accum};
          push(@str, "(* curve sequence number: $curve_idx *)");
          push(@str, "newcurve");
          push(@str, sprintf("curve %d", $org));
               $org += ($options->{stack})? -1: 1;
          push(@str, "poly") if ($c_options->{fill});

          my $markscale = $cdesc->markscale($curve_idx)->jgraph();
          my $markspec = $cdesc->mark($curve_idx, $curve, $Override)->jgraph();
              
          if ($cdesc->line()->name() eq "xbar" || 
              $cdesc->line()->name() eq "ybar" || 
              $cdesc->line()->name() eq "xbarval" ||
              $cdesc->line()->name() eq "ybarval") {

              $markspec = $cdesc->line($curve_idx)->jgraph();
          }
          else {
              push(@str, $cdesc->line($curve_idx)->jgraph());
          }
            
          # Disable marks for bar values as they
          # appear in the middle of the value as noise
            
          if ($cdesc->line()->name() eq "xbarval" ||
              $cdesc->line()->name() eq "ybarval") {
              $markscale = "marksize 0.00 0.00"
          } 

          # begin of ugly hack to allow text mark scaling
          if ($markspec =~ /^marktype text/) {
            my $tmscalespec = $cdesc->textmarkscale($curve_idx)->jgraph();
            $markspec =~ s/^marktype text//;
            $markspec = "marktype text " . $tmscalespec . $markspec;
            $markscale = "marksize 0.00 0.00"
          }
          # end of ugly hack to allow text mark scaling
          push(@str, $cdesc->mark($curve_idx, $curve, $Override)->jgraph());
          push(@str, $markspec);
          push(@str, $cdesc->color($curve_idx)->jgraph());
          push(@str, $cdesc->markscale($curve_idx)->jgraph());
          push(@str, sprintf("label : %s", $curve->getLabel()))
               if ($curve->getLabel() =~ /\S/);
          if ($csect->hasItem("jgraph")) {
            push(@str, ($csect->getItemExpandedData("jgraph", $Override)));
          }

          if ($cdesc->line()->name() eq "ybar" || 
               $cdesc->line()->name() eq "ybarval") {
            ###### Y-BASED ######
            my @yvalues = sort {$obj->yCmp($a, $b, $Override)}
                               @{$curve->yValues()};
            if ($c_options->{fill}) {
              my $first_y = $yvalues[0];
              if ($ytype->name() eq "category") {
                my $offset = ($cdesc->yBar())? $ybar_idx: $yoff;
                $first_y = $ypos->{$first_y} * $ygrp + $offset;
              }
#              if ($ytype->name() eq "numeric") {
#                my $offset = ($cdesc->yBar())? $ybar_idx: $yoff;
#                $first_y = ($first_y * $ygrp + $offset) / $ygrp;
#              }
              if ($no_error) {
                push(@str, sprintf("pts %s %s", $first_y, $xbase));
              } else {
                push(@str, sprintf("x_epts %s %s %s %s", $first_y,
                                         $xbase, $xbase, $xbase));
              }
            }
            foreach my $yp (@yvalues) {
              my $y = $yp;
              if ($ytype->name() eq "category") {
                my $offset = ($cdesc->yBar())? $ybar_idx: $yoff;
                $y = $ypos->{$y} * $ygrp + $offset;
              }
#              if ($ytype->name() eq "numeric") {
#                my $offset = ($cdesc->yBar())? $ybar_idx: $yoff;
#                $y = ($y * $ygrp + $offset) / $ygrp;
#              }
              my @xvalues = sort {$obj->xCmp($a, $b, $Override)}
                                 @{$curve->getX($yp)};
              my $aggr = $cdesc->aggregation();
              foreach my $xset ($aggr->do([@xvalues])) {
                my ($x, $low, $high) = @$xset;
                if ($xtype->name() eq "category") {
                  $x = $xpos->{$x} * $xgrp + $xoff;
                  $low = $x;
                  $high = $x;
                }
                if ($options->{normalize}) {
                  if (exists $base_x->{$yp} && $base_x->{$yp} != 0) {
                    my $base_x = $base_x->{$yp};
                    if ($xtype->name() eq "category") {
                      $base_x = $xpos->{$base_x} * $xgrp + $xoff;
                    }
                    $x = $x / $base_x;
                    $low = $low / $base_x;
                    $high = $high / $base_x;
                  } elsif (!exists $base_x->{$yp}) {
                    $x = $xbase;
                    $low = $xbase;
                    $high = $xbase;
                  }
                }
                if ($options->{stack} && !$c_options->{no_stack}) {
                  $xaccum->{$yp} = 0 if (!exists $xaccum->{$yp});
                  $x += $xaccum->{$yp};
                  $low += $xaccum->{$yp};
                  $high += $xaccum->{$yp};
                  $xaccum->{$yp} = $x;
                }
                if ( $cdesc->line()->name() eq "ybarval") {
                  $markspec = "$markspec " . $x;

                  # TODO: Make support for negative $xbase and $x

                  if ($xtype->name() eq "numeric") {
                    $x = $xbase+(($x-$xbase)/2.0);
                  } elsif ($xtype->name() eq "log2" || $xtype->name() eq "log10") {
                    # Find the geometric mean
                    $x = sqrt($xbase*$x);
                  }
                  push(@str,sprintf("pts %s %s", $x, $y));
                } else {
                  if ($no_error) {
                    push(@str,sprintf("pts %s %s", $x, $y));
                  } else {
                    push(@str,sprintf("x_epts %s %s %s %s", $x, $y, $low, $high));
                  }
                }
              }
            }
            if ($c_options->{fill}) {
              my $last_y = $yvalues[$#yvalues];
              if ($ytype->name() eq "category") {
                my $offset = ($cdesc->yBar())? $ybar_idx: $yoff;
                $last_y = $ypos->{$last_y} * $ygrp + $offset;
              }
#              if ($ytype->name() eq "numeric") {
#                my $offset = ($cdesc->yBar())? $ybar_idx: $yoff;
#                $last_y = ($last_y * $ygrp + $offset) / $ygrp;
#              }
              if ( $cdesc->line()->name() eq "ybarval") {
                $markspec = "$markspec " . $xbase;
              }
              if ($no_error) {
                push(@str, sprintf("pts %s %s", $last_y, $xbase));
              } else {
                push(@str, sprintf("x_epts %s %s %s %s", $last_y,
                                         $xbase, $xbase, $xbase));
              }
            }
          } else {
            ###### X-BASED ######
            my @xvalues = sort {$obj->xCmp($a, $b, $Override)}
                               @{$curve->xValues()};

            if ($c_options->{fill}) {
              my $first_x = $xvalues[0];
              if ($xtype->name() eq "category") {
                my $offset = ($cdesc->xBar())? $xbar_idx: $xoff;
                $first_x = $xpos->{$first_x} * $xgrp + $offset;
              }
#              if ($xtype->name() eq "numeric") {
#                my $offset = ($cdesc->xBar())? $xbar_idx: $xoff;
#                $first_x = ($first_x * $xgrp + $offset) / $xgrp;
#              }
              if ($no_error) {
                push(@str, sprintf("pts %s %s", $first_x, $ybase));
              } else {
                push(@str, sprintf("y_epts %s %s %s %s", $first_x,
                                         $ybase, $ybase, $ybase));
              }
            }
            foreach my $xp (@xvalues) {
              my $x = $xp;
              if ($xtype->name() eq "category") {
                my $offset = ($cdesc->xBar())? $xbar_idx: $xoff;
                $x = $xpos->{$x} * $xgrp + $offset;
              }
#              if ($xtype->name() eq "numeric") {
#                my $offset = ($cdesc->xBar())? $xbar_idx: $xoff;
#                $x = ($x * $xgrp + $offset) / $xgrp;
#              }
              my @yvalues = sort {$obj->yCmp($a, $b, $Override)}
                                 @{$curve->getY($xp)};
              my $aggr = $cdesc->aggregation();
              foreach my $yset ($aggr->do([@yvalues])) {
                my ($y, $low, $high) = @$yset;
                if ($ytype->name() eq "category") {
                  $y = $ypos->{$y} * $ygrp + $yoff;
                  $low = $y;
                  $high = $y;
                }
                if ($do_accum) {
                  $y += $base_accum;
                  $base_accum = $y;
                }
                if ($options->{normalize}) {
                  if (exists $base_y->{$xp} && $base_y->{$xp} != 0) {
                    my $base_y = $base_y->{$xp};
                    if ($ytype->name() eq "category") {
                      $base_y = $ypos->{$base_y} * $ygrp + $yoff;
                    }
                    $y = $y / $base_y;
                    $low = $low / $base_y;
                    $high = $high / $base_y;
                  } elsif (!exists $base_y->{$xp}) {
                    $y = $ybase;
                    $low = $ybase;
                    $high = $ybase;
                  }
                }
                if ($options->{stack} && !$c_options->{no_stack}) {
                  $yaccum->{$xp} = 0 if (!exists $yaccum->{$xp});
                  $y += $yaccum->{$xp};
                  $low += $yaccum->{$xp};
                  $high += $yaccum->{$xp};
                  $yaccum->{$xp} = $y;
                }
                if ( $cdesc->line()->name() eq "xbarval") {
                    $markspec = "$markspec " . $y;
                    
                    # TODO: Make support for negative $ybase and $y
                    
                    if ($ytype->name() eq "numeric") {
                      $y = $ybase+(($y-$ybase)/2.0);
                    } elsif ($ytype->name() eq "log2" || $ytype->name() eq "log10") {

                      # Find the geometric mean

                      $y = sqrt($ybase*$y);
                    }
                    push(@str,sprintf("pts %s %s", $x, $y));
                } else {
                    if ($no_error) {
                      push(@str,sprintf("pts %s %s", $x, $y));
                    } else {
                      push(@str,sprintf("y_epts %s %s %s %s", $x, $y, $low, $high));
                    }
                }
              }
            }
            if ($c_options->{fill}) {
              my $last_x = $xvalues[$#xvalues];
              if ($xtype->name() eq "category") {
                my $offset = ($cdesc->xBar())? $xbar_idx: $xoff;
                $last_x = $xpos->{$last_x} * $xgrp + $offset;
              }
#              if ($xtype->name() eq "numeric") {
#                my $offset = ($cdesc->xBar())? $xbar_idx: $xoff;
#                $last_x = ($last_x * $xgrp + $offset) / $xgrp;
#              }
              if ($no_error) {
                push(@str, sprintf("pts %s %s", $last_x, $ybase));
              } else {
                push(@str, sprintf("y_epts %s %s %s %s", $last_x,
                                         $ybase, $ybase, $ybase));
              }
            }
          }
          push(@str, $markspec);
          push(@str, $markscale);
          push(@str, "");
        }
        $curve_idx += 1 if (!$c_options->{skip});
        $xbar_idx += 1
          if (!$c_options->{skip} && $cdesc->xBar() && $options->{xoffset});
        $ybar_idx += 1
          if (!$c_options->{skip} && $cdesc->yBar() && $options->{yoffset});
        $curve = $cdesc->getNextCurve();
      }
      $cdesc = $bdesc->getNextChild();
    }
    $bdesc = $obj->getNextChild();
  }

  push(@str, "");
  return @str;
}

=item string = $GraphDesc->jgraph($graph_idx);

=cut

sub jgraph {
  my $obj = shift;
  return join("\n", ($obj->jgraphList(@_)), "");
}

=back

=head3 Class GraphFile: SectionFile

=over

=cut

package GraphFile;
our @ISA = qw(SectionFile);

=item $GraphFile = GraphFile->new($Input);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $input = shift;
  my $obj = $class->SUPER::new($input);
  bless($obj, $class);

  return $obj;
}

=item $GraphSection = $GraphFile->getGraphSection();

=cut

sub getGraphSection {
  my $obj = shift;
  while (defined $obj->getGlobalSection()) {};
  my $header = $obj->getHeader();
  return undef if (!defined $header);
  if ($header->name() ne "graph") {
    $obj->{input}->pushLine("[" . $header->name() . "]");
    return undef;
  }
  return undef if (!defined $header || $header->name() ne "graph");
  my $s = GraphSection->new($header);
  my $item = $obj->getItem();
  while (defined $item) {
    $s->addItem($item);
    $item = $obj->getItem();
  }
  return $s;
}

=item $BenchSection = $GraphFile->getBenchSection();

=cut

sub getBenchSection {
  my $obj = shift;
  while (defined $obj->getGlobalSection()) {};
  my $header = $obj->getHeader();
  return undef if (!defined $header);
  if ($header->name() ne "bench") {
    $obj->{input}->pushLine("[" . $header->name() . "]");
    return undef;
  }
  my $s = BenchSection->new($header);
  my $item = $obj->getItem();
  while (defined $item) {
    $s->addItem($item);
    $item = $obj->getItem();
  }
  return $s;
}

=item $CurveSection = $GraphFile->getCurveSection();

=cut

sub getCurveSection {
  my $obj = shift;
  while (defined $obj->getGlobalSection()) {};
  my $header = $obj->getHeader();
  return undef if (!defined $header);
  if ($header->name() ne "curve") {
    $obj->{input}->pushLine("[" . $header->name() . "]");
    return undef;
  }
  my $s = CurveSection->new($header);
  my $item = $obj->getItem();
  while (defined $item) {
    $s->addItem($item);
    $item = $obj->getItem();
  }
  return $s;
}

=item $bool = $GraphFile->getGlobalSection();

=cut

sub getGlobalSection {
  my $obj = shift;
  my $header = $obj->getHeader();
  return undef if (!defined $header);
  if ($header->name() ne "global") {
    $obj->{input}->pushLine("[" . $header->name() . "]");
    return undef;
  }
  my $s = GlobalSection->new($header);
  undef %LOCALENV;
  undef %LOCALEVAL;
  undef %LOCALFUNC;
  undef %LOCALFUNCPTR;
  undef %INTODBFUNC;
  my $item = $obj->getItem();
  while (defined $item) {
    if ($item->name() eq "env") {
      my $str = $item->data();
      $str =~ s/^\s+//;
      $str =~ s/\s+$//;
      if ($str =~ /^([\w_]+)\s*=\s*(\S.*)$/) {
        my $var = $1;
        my $val = $2;
        $LOCALENV{$var} = $val;
      }
    }
    if ($item->name() eq "eval") {
      my $str = $item->data();
      $str =~ s/^\s+//;
      $str =~ s/\s+$//;
      if ($str =~ /^([\w_]+)\s*=\s*(\S.*)$/) {
        my $var = $1;
        my $val = $2;
        $LOCALEVAL{$var} = $val;
      }
    }
    if ($item->name() eq "func") {
      my $str = $item->data();
      $str =~ s/^\s+//;
      $str =~ s/\s+$//;
      if ($str =~ /^([\w_]+)\s*=\s*(\S.*)$/) {
        my $var = $1;
        my $val = $2;
        $LOCALFUNC{$var} = $val;
        $LOCALFUNCPTR{$var} = eval "sub { $val }";
        $INTODBFUNC{$var} = $LOCALFUNCPTR{$var};
      }
    }
    $s->addItem($item);
    $item = $obj->getItem();
  }
  return $s;
}

=item $GraphDesc = $GraphFile->getGraph();

=cut

sub getGraph {
  my $obj = shift;
  my $input = $obj->{input};
  return undef if ($obj->getEndSection());
  while (defined $obj->getGlobalSection()) {};
  my $gsect = $obj->getGraphSection();
  if (!defined $gsect) {
    my $line = $input->getLine();
    return undef if (!defined $line);
    $input->pushLine($line);
    my $pos = $input->getPosition();
    die "syntax error parsing graph description (input line $pos)\n";
  }
  my $graph = GraphDesc->new($gsect);
  my $bsect = $obj->getBenchSection();
  while (defined $bsect) {
    my $bench = BenchDesc->new($bsect);
    $graph->addChild($bench);
    my $csect = $obj->getCurveSection();
    while (defined $csect) {
      my $curve = CurveDesc->new($csect);
      $bench->addChild($curve);
      $csect = $obj->getCurveSection();
    }
    $bsect = $obj->getBenchSection();
  }
  return $graph;
}

=item ($GraphDesc, ...) = $GraphFile->parse();

=cut

sub parse {
  my $obj = shift;
  my @glist = ();
  undef %LOCALENV;
  undef %LOCALEVAL;
  undef %LOCALFUNC;
  undef %LOCALFUNCPTR;
  undef %INTODBFUNC;
  my $graph = $obj->getGraph();
  while (defined $graph) {
    push(@glist, $graph);
    $graph = $obj->getGraph();
  }
  return @glist;
}

=back

=head3 Class RcFile: SectionFile

=over

=cut

package RcFile;
our @ISA = qw(SectionFile);

=item $RcFile = RcFile->new($Input);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $input = shift;
  my $obj = $class->SUPER::new($input);
  bless($obj, $class);
  $obj->{sectionlist} = [];

  return $obj;
}

=item $GFSection = $RcFile->getSection();

=cut

sub getSection {
  my $obj = shift;
  return undef if ($obj->getEndSection());
  my $header = $obj->getHeader();
  return undef if (!defined $header);
  my $sect = GFSection->new($header);
  my $item = $obj->getItem();
  while (defined $item) {
    $sect->addItem($item);
    $item = $obj->getItem();
  }
  return $sect;
}

=item $RcFile = $RcFile->parse();

=cut

sub parse {
  my $obj = shift;
  my @slist = ();
  my $sect = $obj->getSection();
  while (defined $sect) {
    push(@slist, $sect);
    $sect = $obj->getSection();
  }
  $obj->{sectionlist} = [ @slist ];
  return $obj;
}

=item ($GFSection, ...) = $RcFile->getAllSections();

=cut

sub getAllSections {
  my $obj = shift;
  return @{$obj->{sectionlist}};
}

=item ($value1, ...) = $RcFile->getValues($section_name, $item_name [, $mode]);

  $mode: -1 (last), 0 (all), 1 (first)

=cut

sub getValues {
  my $obj = shift;
  my $sname = shift;
  my $iname = shift;
  my $mode = shift;
  return () if (!defined($sname) || !defined($iname));
  $sname = lc($sname);
  $iname = lc($iname);
  my @val = ();
  my @sections = grep {$_->header()->name() eq $sname} @{$obj->{sectionlist}};
  @sections = reverse @sections if (defined $mode && $mode < 0);
  foreach my $s (@sections) {
    if ($s->hasItem($iname)) {
      push(@val, $s->getItemData($iname));
    }
    last if ($mode);
  }
  return @val;
}

=back

=cut

#################################################
#################################################
# CHECKS
#################################################
#################################################

=head2 CHECKS

=head3 Class Check

=over

=cut

package Check;
our @ISA = qw();

=item $int = Check::sorter($a, $b);

=cut

sub sorter ($$) {
  my $a = shift;
  my $b = shift;

  my $na = isNum($a, [undef, undef]);
  my $nb = isNum($b, [undef, undef]);

  return $na <=> $nb if (defined($na) && defined($nb));
  return $a cmp $b if (!defined($na) && !defined($nb));
  return -1 if (defined($na));
  return 1;
}

=item $int = Check::isInteger($val, [$min, $max]);

=cut

sub isInteger ($$) {
  my $val = shift;
  my $args = shift;
  my ($min, $max) = @$args;
  return undef if (!defined $val);
  if ($val =~ /^\s*((\+\-)?\d+)\s*$/) {
    $val = $1;
  } elsif ($val =~ /^\s*0x([\dA-Fa-f]+)\s*$/) {
    $val = hex($1);
  } else {
    return undef;
  }
  return undef if (defined($min) && $min > $val);
  return undef if (defined($max) && $max < $val);
  return $val;
}

=item $num = Check::isNum($val, [$min, $max]);

=cut

sub isNum ($$) {
  my $val = shift;
  my $args = shift;
  my ($min, $max) = @$args;
  return undef if (!defined $val);
  if ($val =~ /^\s*((\+|\-)?\d+(\.\d+([eE](\+|\-)?\d+)?)?)\s*$/) {
    $val = $1;
  } elsif ($val =~ /^\s*0x([\dA-Fa-f]+)\s*$/) {
    $val = hex($1);
  } else {
    return undef;
  }
  return undef if (defined($min) && $min > $val);
  return undef if (defined($max) && $max < $val);
  return $val;
}

=item $string = Check::isWord($val, [("l"|"u"|undef), ["word1", ...]]);

=cut

sub isWord {
  my $val = shift;
  my $args = shift;
  my ($case, $list) = @$args;
  $val = lc($val) if (defined($case) && $case eq "l");
  $val = uc($val) if (defined($case) && $case eq "u");
  if ($val =~ /^\s*(\S+)\s*$/) {
    $val = $1;
  } else {
    return undef;
  }
  return undef if (defined($list) && !grep {$_ eq $val} @$list);
  return $val;
}

=item $string = Check::isValid($val, [("l"|"u"|undef), [&chk_func,[args...]]]);

=cut

sub isValid {
  my $val = shift;
  my $args = shift;
  my ($case, $list) = @$args;
  my ($f, $fargs) = @$list;
  $val = lc($val) if (defined($case) && $case eq "l");
  $val = uc($val) if (defined($case) && $case eq "u");
  if ($val =~ /^\s*(\S+)\s*$/) {
    $val = $1;
  } else {
    return undef;
  }
  if (defined $f) {
    $val = &{$f}($val, $fargs);
    return undef if (!defined $val);
  }
  return $val;
}

=item $string = Check::isEnvVar($val, [["var1", ...]]);

=cut

sub isEnvVar {
  my $val = shift;
  my $args = shift;
  my ($list) = @$args;
  my $var;
  if ($val =~ /^\@\{([\w_]+)\}$/) {
    $var = $1;
  } elsif ($val =~ /^\@([\w_]+)$/) {
    $var = $1;
  } else {
    return undef;
  }
  return undef if (defined($list) && !grep {$_ eq $var} @$list);
  return $var;
}

=item $string = Check::isEvalVar($val, [["var1", ...]]);

=cut

sub isEvalVar {
  my $val = shift;
  my $args = shift;
  my ($list) = @$args;
  my $var;
  if ($val =~ /^\&\{([\w_]+)\}$/) {
    $var = $1;
  } elsif ($val =~ /^\&([\w_]+)$/) {
    $var = $1;
  } else {
    return undef;
  }
  return undef if (defined($list) && !grep {$_ eq $var} @$list);
  return $var;
}

=item $string = Check::isFuncVar($val, [["var1", ...]]);

=cut

sub isFuncVar {
  my $val = shift;
  my $args = shift;
  my ($list) = @$args;
  my $var;
  if ($val =~ /^\%\{([\w_]+)\}$/) {
    $var = $1;
  } elsif ($val =~ /^\%([\w_]+)$/) {
    $var = $1;
  } else {
    return undef;
  }
  return undef if (defined($list) && !grep {$_ eq $var} @$list);
  return $var;
}

=item $string = Check::expandFuncVar($val, [["var1", ...]]);

=cut

sub expandFuncBrcCodeFunc {
  my $prefix = shift;
  my $varname = shift;
  my $args = shift;
  my $name = "%{" . $varname . "}";
  my $var = Check::isFuncVar($name, $args);
  my $expr = $name;
  #if (defined($var) && exists $LOCALFUNC{$var}) {
  #  $expr = "&{sub {" . $LOCALFUNC{$var} . "}}";
  #}
  if (defined($var) && defined($LOCALFUNCPTR{$var})) {
    $expr = sprintf '&{$LOCALFUNCPTR{"%s"}}', $var;
    #$expr = "&{sub {" . $LOCALFUNC{$var} . "}}";
  }
  return $prefix . $expr;
}

sub expandFuncNoBrcCodeFunc {
  my $prefix = shift;
  my $varname = shift;
  my $args = shift;
  my $name = "%" . $varname;
  my $var = Check::isFuncVar($name, $args);
  my $expr = $name;
  #if (defined($var) && exists $LOCALFUNC{$var}) {
  #  $expr = "&{sub {" . $LOCALFUNC{$var} . "}}";
  #}
  if (defined($var) && defined($LOCALFUNCPTR{$var})) {
    $expr = sprintf '&{$LOCALFUNCPTR{"%s"}}', $var;
    #$expr = "&{sub {" . $LOCALFUNC{$var} . "}}";
  }
  return $prefix . $expr;
}

sub expandFuncCode {
  my $val = shift;
  my $args = shift;
  my ($list) = @$args;
  $val =~ s/(^|[^\\])\%([\w_]+)(\b|$)/expandFuncBrcCodeFunc($1, $2, $args)/ge;
  $val =~ s/(^|[^\\])\%\{([\w_]+)\}/expandFuncNoBrcCodeFunc($1, $2, $args)/ge;
  return $val;
}

=item $string = Check::isColVar($val, [["var1", ...]]);

=cut

sub isColVar {
  my $val = shift;
  my $args = shift;
  my ($list) = @$args;
  my $var;
  if ($val =~ /^\$\{([\w_]+)\}$/) {
    $var = uc($1);
  } elsif ($val =~ /^\$([\w_]+)$/) {
    $var = uc($1);
  } else {
    return undef;
  }
  return undef if (defined($list) && !grep {$_ eq $var} @$list);
  return $var;
}

=item $string = Check::expandColVar($val, [["var1", ...]]);

=cut

sub expandColVar {
  my $val = shift;
  my $args = shift;
  my ($list) = @$args;
  while ($val =~ /(^|[^\\])\$([\w_]+)(\b|$)/) {
    my $name = "\$" . $2;
    my $col = Check::isColVar($name, $args);
    return undef if (!defined($col));
    $val =~ s/(^|[^\\])\$([\w_]+)(\b|$)/$1_${col}$3/;
  }
  while ($val =~ /(^|[^\\])\$\{([\w_]+)\}/) {
    my $name = "\$" . $2;
    my $col = Check::isColVar($name, $args);
    return undef if (!defined($col));
    $val =~ s/(^|[^\\])\$\{([\w_]+)\}/$1_${col}/;
  }
  return $val;
}

=item $string = Check::expandColCode($val, [["var1", ...]]);

=cut

sub expandColCodeFunc {
  my $prefix = shift;
  my $varname = shift;
  my $args = shift;
  my $name = "\$" . $varname;
  my $col = Check::isColVar($name, $args);
  die "invalid column name \"$name\"\n" if (!defined $col);
  my $expr = "\$row->{_$col}";
  #my $expr = (defined $col)? "\$row->{_$col}": "undef";
  return $prefix . $expr;
}

sub expandColCode {
  my $val = shift;
  my $args = shift;
  my ($list) = @$args;
  $val =~ s/(^|[^\\])\$([\w_]+)(\b|$)/expandColCodeFunc($1, $2, $args)/ge;
  $val =~ s/(^|[^\\])\$\{([\w_]+)\}/expandColCodeFunc($1, $2, $args)/ge;
  $val = Check::expandFuncCode($val, []);
  return $val;
}

=item $string = Check::expandColValue($val, [$value_hash]);

=cut

sub expandColValue {
  my $val = shift;
  my $args = shift;
  my ($hash) = @$args;
  while ($val =~ /(^|[^\\])\$([\w_]+)(\b|$)/) {
    my $name = "\$_" . $2;
    my $col = Check::isColVar($name, [[keys %$hash]]);
    $col = "" if (!defined($col));
    my $data = $hash->{$col}; $data = "null" if (!defined $data);
    $val =~ s/(^|[^\\])\$([\w_]+)(\b|$)/$1${data}$3/;
  }
  while ($val =~ /(^|[^\\])\$\{([\w_]+)\}/) {
    my $name = "\$_" . $2;
    my $col = Check::isColVar($name, [[keys %$hash]]);
    $col = "" if (!defined($col));
    my $data = $hash->{$col}; $data = "null" if (!defined $data);
    $val =~ s/(^|[^\\])\$\{([\w_]+)\}/$1${data}/;
  }
  return $val;
}

=item $arrayref = Checkk::isList($val, [&check_function, [check_args...]]);

=cut

sub isList {
  my $val = shift;
  my $args = shift;
  my ($f, $fargs) = @$args;
  return undef if (!defined $val);
  my $listval = [];
  my $str = "";
  my $quoted = 0;
  $val =~ s/^\s+//;
  while ($val ne "") {
    if (!$quoted && $val =~ /^\"/) {
      $quoted = 1;
      $val =~ s/^\"//;
      $str = "";
      $str = "\"";
    } elsif ($quoted && $val =~ /^\"/) {
      $str .= "\"";
      push(@$listval, $str);
      $val =~ s/^\"//;
      $quoted = 0;
    } elsif ($quoted && $val =~ /^\\\\/) {
      $str .= "\\";
      $val =~ s/^\\\\//;
    } elsif ($quoted && $val =~ /^\\\"/) {
      $str .= "\"";
      $val =~ s/^\\\"//;
    } elsif ($quoted && $val =~ /^\\/) {
      $str .= "\\";
      $val =~ s/^\\//;
    } elsif ($quoted && $val =~ /^([^\\\"]+)/) {
      $str .= $1;
      $val =~ s/^[^\\\"]+//;
    } elsif (!$quoted && $val =~ /^\,/){
      $val =~ s/^\,//;
    } elsif (!$quoted && $val =~ /^([^\,]+)/){
      $str = $1;
      $str =~ s/^\s+//;
      $str =~ s/\s+$//;
      push(@$listval, $str);
      $val =~ s/^[^\,]+//;
    } else {
      die "error parsing list \"$val\"\n";
    }
    $val =~ s/^\s+//;
  }
  return undef if ($quoted);
  if (defined $f) {
    my $newlist = [];
    foreach my $i (@$listval) {
      my $v = &{$f}($i, $fargs);
      return undef if (!defined $v);
      push(@$newlist, $v);
    }
    return $newlist;
  }
  return $listval;
}

=back

=cut

#################################################
#################################################
# GUI
#################################################
#################################################

=head2 GUI

=head3 Class Callback

=over

=cut

package Callback;
our @ISA = qw();

our $IdCount = 1;

=item $Callback = Callback->new(\&func, @data);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);

  my $func = shift;
  my $args = [];
  my $i = 0; while ($i <= $#_) {
    push(@$args, $_[$i]);
    $i += 1;
  }

  $obj->{id} = $Callback::IdCount ++;
  $obj->{func} = $func;
  $obj->{args} = $args;

  return $obj;
}

=item $Callback->run(@args)

=cut

sub run {
  my $obj = shift;
  my @args = @_;

  my $f = $obj->{func};
  my @data = @{$obj->{args}};
  &{$f}(@data, @args);
  return $obj;
}

=item $int = $Callback->id();

=cut

sub id {
  my $obj = shift;
  return $obj->{id};
}

=back

=head3 Class IntoDBWidget

=over

=cut

package IntoDBWidget;
our @ISA = qw();

our $IdCount = 1;

=item $IntoDBWidget = IntoDBWidget->new();

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = {};
  bless($obj, $class);
  $obj->{widget} = undef;
  $obj->{data} = undef;
  $obj->{id} = $IntoDBWidget::IdCount ++;
  $obj->{callback} = {};

  return $obj;
}

=item $IntoDBWidget = IntoDBWidget->setCallback($event, $Callback);

=cut

sub setCallback {
  my $obj = shift;
  my $event = shift;
  my $callback = shift;
  $obj->{callback}->{$event} = {} if (!exists $obj->{callback}->{$event});
  $obj->{callback}->{$event}->{$callback->id()} = $callback;
  return $obj;
}

=item $IntoDBWidget = IntoDBWidget->removeCallback($event [, $callback_id]);

=cut

sub removeCallback {
  my $obj = shift;
  my $event = shift;
  my $id = shift;
  if (exists $obj->{callback}->{$event}) {
    if (defined $id) {
      delete $obj->{callback}->{$event}->{$id}
             if (exists $obj->{callback}->{$event}->{$id});
    } else {
      delete $obj->{callback}->{$event};
    }
  }
  return $obj;
}

=item $IntoDBWidget = IntoDBWidget->signalEvent($event, @extra_args);

=cut

sub signalEvent {
  my $obj = shift;
  my $event = shift;
  my @extra_args = @_;
  return $obj if (!defined $event);
  if (exists $obj->{callback}->{$event}) {
    foreach my $cb (values %{$obj->{callback}->{$event}}) {
      $cb->run($obj, @extra_args);
    }
  }
}

=item $int = $IntoDBWidget->id();

=cut

sub id {
  my $obj = shift;
  return $obj->{id};
}

=item $widget = $IntoDBWidget->widget();

=cut

sub widget {
  my $obj = shift;
  return $obj->{widget};
}

=item $data = $IntoDBWidget->getData();

=cut

sub getData {
  my $obj = shift;
  return $obj->{data};
}

=item $IntoDBWidget = $IntoDBWidget->setData($data);

=cut

sub setData {
  my $obj = shift;
  $obj->{data} = shift;
  return $obj;
}

=item $IntoDBwidget = $IntoDBWidget->destroyData($data);

=cut

sub destroyData {
  my $obj = shift;
  $obj->{data} = undef;
  return $obj;
}

=back

=head3 Class Window: IntoDBWidget

=over

=cut

package Window;
our @ISA = qw(IntoDBWidget);

=item $Window = Window->new($title [, $parent_Window]);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  my $title = shift;
  my $parent = shift;
  bless($obj, $class);
  $obj->{parent} = $parent;
  $obj->{children} = {};

  my $close = Gtk2::Button->new("close");
  $close->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    $obj->destroy();
  }, $obj);

  my $button_box = Gtk2::HBox->new();
  $button_box->pack_end($close, $GTK_FALSE, $GTK_FALSE, 0);

  my $content_box = Gtk2::VBox->new();

  my $main_box = Gtk2::VBox->new();
  $main_box->add($content_box);
  $main_box->pack_end($button_box, $GTK_FALSE, $GTK_FALSE, 0);

  my $frame = Gtk2::Frame->new($title);
  $frame->set_shadow_type('out');
  $frame->add($main_box);

  my $win = Gtk2::Window->new('toplevel');
  $win->set_title($title);
  $win->add($frame);
  $win->signal_connect('destroy' => sub {
    my $widget = shift;
    my $obj = shift;
    $obj->destroy();
  }, $obj);
  $win->signal_connect('delete_event' => sub {
    my $widget = shift;
    my $event = shift;
    my $obj = shift;
    $obj->destroy();
  }, $obj);

  $obj->{content} = $content_box;
  $obj->{buttons} = $button_box;
  $obj->{close} = $close;
  $obj->{widget} = $win;

  if (defined $parent) {
    $parent->{children}->{$obj->id()} = $obj;
  }

  return $obj;
}

=item $Win = $Window->parent();

=cut

sub parent {
  my $obj = shift;
  return $obj->{parent};
}

=item ($Window1, ...) = $Window->children();

=cut

sub children {
  my $obj = shift;
  return (values %{$obj->{children}});
}

=item $Window->destroy();

=cut

sub destroy {
  my $obj = shift;
  my @children = keys %{$obj->{children}};
  foreach my $id (@children) {
    $obj->{children}->{$id}->destroy();
  }
  $obj->destroyData();
  $obj->{widget}->destroy();
  if (defined($obj->{parent})) {
    delete $obj->{parent}->{children}->{$obj->id()};
  }
  return $obj;
}

=item $Window = $Window->show();

=cut

sub show {
  my $obj = shift;
  $obj->{widget}->show_all();
  return $obj;
}

=item $Window = $Window->addButton($GtkButton);

=cut

sub addButton {
  my $obj = shift;
  my $button = shift;
  $obj->{buttons}->pack_start($button, $GTK_FALSE, $GTK_FALSE, 0);
  return $obj;
}

=item $Window = $Window->addContent($GtkWidget);

=cut

sub addContent {
  my $obj = shift;
  my $widget = shift;
  $obj->{content}->add($widget);
  return $obj;
}

=item $Window = $Window->setCloseLabel($text);

=cut

sub setCloseLabel {
  my $obj = shift;
  my $text = shift;
  $obj->{close}->set_label($text);
  return $obj;
}

=back

=head3 Class MainWindow: Window

=over

=cut

package MainWindow;
our @ISA = qw(Window);

=item $MainWindow = MainWindow->new($title);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $title = shift;
  my $obj = $proto->SUPER::new($title);
  bless($obj, $class);
  return $obj;
}

=item $MainWindow->destroy();

=cut

sub destroy {
  my $obj = shift;
  $obj->SUPER::destroy();
  Gtk2->main_quit();
}

=back

=head3 Class MessageWindow: IntoDBWidget

=over

=cut

package MessageWindow;
our @ISA = qw(IntoDBWidget);

=item $MessageWindow = MessageWindow->new($title);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);
  my $title = shift;

  my $text = Gtk2::Label->new();
  $text->set_line_wrap($GTK_TRUE);
  $text->set_selectable($GTK_TRUE);
  $obj->{text} = $text;

  my $win = Gtk2::Dialog->new($title, undef, ['modal']);
  $win->set_has_separator($GTK_TRUE);
  $win->vbox()->add($text);

  $obj->{text} = $text;
  $obj->{widget} = $win;

  return $obj;
}

=item $MessageWindow = $MessageWindow->setText($text);

=cut

sub setText {
  my $obj = shift;
  my $text = shift;
  $obj->{text}->set_text($text);
  return $obj;
}

=item $MessageWindow = $MessageWindow->addResponse($text, $response_id);

=cut

sub addResponse {
  my $obj = shift;
  my $text = shift;
  my $resp = shift;
  $obj->{widget}->add_button($text, $resp);
  return $obj;
}

=item $resp = $MessageWindow->run();

=cut

sub run {
  my $obj = shift;
  my $resp = undef;
  $obj->{widget}->show_all();
  $resp = $obj->{widget}->run();
  $obj->{widget}->destroy();
  return $resp;
}

=back

=head3 Class ErrorWindow: MessageWindow

=over

=cut

package ErrorWindow;
our @ISA = qw(MessageWindow);

=item $ErrorWindow = ErrorWindow->new($message);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new("Error");
  bless($obj, $class);
  my $message = shift;
  $obj->setText($message);
  $obj->addResponse("ok", "ok");
  return $obj;
}

=back

=head3 Class ConfirmWindow: MessageWindow

=over

=cut

package ConfirmWindow;
our @ISA = qw(MessageWindow);

=item $ConfirmWindow = ConfirmWindow->new($message);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new("Confirm");
  bless($obj, $class);
  my $message = shift;
  $obj->setText($message);
  $obj->addResponse("ok", "ok");
  $obj->addResponse("cancel", "cancel");
  return $obj;
}

=back

=head3 Class FileWindow: IntoDBWidget

=over

=cut

package FileWindow;
our @ISA = qw(IntoDBWidget);

our $LASTDIR = ".";

=item $FileWindow = FileWindow->new($title [,dir]);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $title = shift;
  my $dir = shift;
  my $obj = $class->SUPER::new();
  bless($obj, $class);

  my $win = Gtk2::FileChooserDialog->new($title, undef, "open");
  $win->set_modal($GTK_TRUE);
  $win->set_show_hidden($GTK_FALSE);
  $win->set_select_multiple($GTK_FALSE);
  #$win->set_current_folder($dir) if (defined $dir);
  if (defined $dir) {
    $win->set_current_folder($dir);
  } else {
    $win->set_current_folder($FileWindow::LASTDIR);
  }
  eval {
    $win->add_shortcut_folder(".");
  };
  $win->add_button("cancel", "cancel");
  $win->add_button("ok", "ok");

  $obj->{widget} = $win;
  $obj->{lastdir} = \$FileWindow::LASTDIR;
  return $obj;
}

=item $FileWindow = $FileWindow->setAction($action);

=item $FileWindow = $FileWindow->setActionOpen();

=item $FileWindow = $FileWindow->setActionSave();

=cut

sub setAction {
  my $obj = shift;
  my $action = shift;
  $obj->{widget}->set_action($action);
  return $obj;
}

sub setActionOpen {
  my $obj = shift;
  return $obj->setAction("open");
}

sub setActionSave {
  my $obj = shift;
  return $obj->setAction("save");
}

=item $FileWindow = $FileWindow->setFilename($filename);

=cut

sub setFilename {
  my $obj = shift;
  my $filename = shift;
  #$obj->{widget}->set_filename($filename);
  $obj->{widget}->set_current_name($filename);
  return $obj;
}

=item $filename = $FileWindow->run();

=cut

sub run {
  my $obj = shift;
  my $file = undef;
  $obj->{widget}->show_all();
  my $resp = $obj->{widget}->run();
  if ($resp eq "ok") {
    $file = $obj->{widget}->get_filename();
    my $folder = $obj->{widget}->get_current_folder();
    ${$obj->{lastdir}} = $folder if (defined $folder);
  }
  $obj->{widget}->destroy();
  return $file;
}

=back

=head3 Class Choice: IntoDBWidget

=over

=cut

package Choice;
our @ISA = qw(IntoDBWidget);

=item $Choice = Choice->new();

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);
  my $combo = Gtk2::ComboBox->new_text();

  $obj->{data} = [];
  $obj->{widget} = $combo;

  return $obj;
}

=item $Choice = $Choice->add([$text, $data1, ..., $datan]);

=item $Choice = $Choice->add([$text, $data1, ..., $datan], $pos);

=item $Choice = $Choice->append([$text, $data1, ..., $datan]);

=cut

sub add {
  my $obj = shift;
  my $data = shift;
  my $pos = shift;
  if (!defined $pos) {
    $pos = $obj->{widget}->get_active();
    return $obj if (!defined $pos);
  } elsif ($pos < 0) {
    $pos = $#{$obj->{data}} + 1;
  }
  $obj->{widget}->insert_text($pos, $data->[0]);
  my @pre = @{$obj->{data}}[0 .. $pos - 1];
  my @post = @{$obj->{data}}[$pos .. $#{$obj->{data}}];
  $obj->{data} = [@pre, $data, @post];
  return $obj;
}

sub append {
  my $obj = shift;
  my $data = shift;
  return $obj->add($data, -1);
}

=item $Choice = $Choice->remove();

=item $Choice = $Choice->removeAt($pos);

=cut

sub remove {
  my $obj = shift;
  my $pos = shift;
  if (!defined $pos) {
    $pos = $obj->{widget}->get_active();
    return $obj if (!defined $pos);
  } elsif ($pos < 0) {
    $pos = $#{$obj->{data}};
  } elsif ($pos > $#{$obj->{data}}) {
    return $obj;
  }
  my @pre = @{$obj->{data}}[0 .. $pos - 1];
  my @post = @{$obj->{data}}[$pos + 1.. $#{$obj->{data}}];
  $obj->{widget}->remove_text($pos);
  $obj->{data} = [@pre, @post];
  return $obj;
}

sub removeAt {
  my $obj = shift;
  my $pos = shift;
  return $obj->remove($pos);
}

=item $Choice = $Choice->removeAll();

=cut

sub removeAll {
  my $obj = shift;
  while ($#{$obj->{data}} >= 0) {
    $obj->remove(0);
  }
  return $obj;
}

=item [$text, $data1, ..., $datan] = $Choice->get();

=cut

sub get {
  my $obj = shift;
  my $idx = $obj->getPosition();
  return undef if (!defined $idx);
  return $obj->{data}->[$idx];
}

=item $int = $Choice->getPosition();

=cut

sub getPosition {
  my $obj = shift;
  return $obj->{widget}->get_active();
}

=item $Choice = $Choice->setByPosition($pos);

=cut

sub setByPosition {
  my $obj = shift;
  my $pos = shift;
  return $obj if (!defined $pos);
  $pos = $#{$obj->{data}} if ($pos < 0 || $pos > $#{$obj->{data}});
  $obj->{widget}->set_active($pos);
  return $obj;
}

=item $Choice = $Choice->setByText($text);

=cut

sub setByText {
  my $obj = shift;
  my $text = shift;
  return $obj if (!defined $text);
  my $pos = 0;
  foreach my $d (@{$obj->{data}}) {
    return $obj->setByPosition($pos) if ($text eq $d->[0]);
    $pos += 1;
  }
  return $obj;
}

=item $Choice = $Choice->setWrap($ncols);

=cut

sub setWrap {
  my $obj = shift;
  my $ncols = shift;
  $obj->{widget}->set_wrap_width($ncols);
  return $obj;
}

=back

=head3 Class List: IntoDBWidget

=over

=cut

package List;
our @ISA = qw(IntoDBWidget);

=item $List = List->new($ncolumns);

events: C<row-activated($path)>, C<rows-reordered>

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);
  my $ncols = shift; $ncols = 1 if (!defined($ncols) || $ncols < 1);

  my @typelist = ('Glib::String') x ($ncols);
  my $store = Gtk2::ListStore->new(@typelist);
  my $view = Gtk2::TreeView->new($store);
  $view->set_headers_visible($GTK_FALSE);
  $view->set_reorderable($GTK_FALSE);
  $view->set_headers_visible($GTK_FALSE);

  for (my $i = 0; $i < $ncols; $i ++) {
    my $txt = Gtk2::CellRendererText->new();
    my $col = Gtk2::TreeViewColumn->new();
    $col->pack_start($txt, $GTK_FALSE);
    $col->add_attribute($txt, 'text' => $i);
    $view->append_column($col);
  }

  my $selection = $view->get_selection();
  $selection->set_mode('single');

  my $scroll = Gtk2::ScrolledWindow->new();
  $scroll->set_shadow_type('etched-out');
  $scroll->set_policy('automatic', 'automatic');
  $scroll->add($view);

  $view->signal_connect('row-activated' => sub {
    my $widget = shift;
    my $path = shift;
    my $col = shift;
    my $obj = shift;
    my $iter = $obj->{store}->get_iter($path);
    if (defined $iter) {
      my @indexes = (0 .. ($obj->{ncols} - 1));
      my $row = [($obj->{store}->get($iter, @indexes))];
      $obj->signalEvent('row-activated', $row, $path, $col);
    }
  }, $obj);
  $store->signal_connect('rows-reordered' => sub{
    my $widget = shift;
    my $path = shift;
    my $iter = shift;
    my $ptr = shift;
    my $obj = shift;
    $obj->signalEvent('rows-reordered')
  }, $obj);

  $obj->{ncols} = $ncols;
  $obj->{store} = $store;
  $obj->{view} = $view;
  $obj->{selection} = $selection;
  $obj->{path} = undef;
  $obj->{widget} = $scroll;

  return $obj;
}

=item $int = $List->getNColumns();

=cut

sub getNColumns {
  my $obj = shift;
  return $obj->{ncols};
}

=item $List = $List->setReorderable($bool);

=cut

sub setReorderable {
  my $obj = shift;
  my $bool = $_[0]? $GTK_TRUE: $GTK_FALSE;
  $obj->{view}->set_reorderable($bool);
  return $obj;
}

=item $List = $List->setColumnReorderable($pos, $bool);

=cut

sub setColumnReorderable {
  my $obj = shift;
  my $pos = shift;
  my $bool = ($_[0])? $GTK_TRUE: $GTK_FALSE;
  $obj->{view}->get_column($pos)->set_reorderable($bool);
  return $obj;
}

=item $List = $List->setHeader($pos, $title);

=cut

sub setHeader {
  my $obj = shift;
  my $pos = shift;
  my $title = shift; $title = "" if (!defined $title);
  $obj->{view}->get_column($pos)->set_title($title);
  return $obj;
}

=item $List = $List->setHeadersVisible($bool);

=cut

sub setHeadersVisible {
  my $obj = shift;
  my $bool = $_[0]? $GTK_TRUE: $GTK_FALSE;
  $obj->{view}->set_headers_visible($bool);
  return $obj;
}

=item $List = $List->setColumnVisible($pos, $bool);

=cut

sub setColumnVisible {
  my $obj = shift;
  my $pos = shift;
  my $bool = $_[0]? $GTK_TRUE: $GTK_FALSE;
  $obj->{view}->get_column($pos)->set_visible($bool);
  return $obj;
}

=item $List = $List->add([$text1, ..., $textn]);

=item $List = $List->add([$text1, ..., $textn], $pos);

=item $List = $List->append([$text1, ..., $textn]);

=cut

sub add {
  my $obj = shift;
  my $row = shift;
  my $pos = shift;
  my $iter = undef;
  if (!defined $pos) {
    $iter = $obj->{selection}->get_selected();
  } elsif ($pos >= 0) {
    my $path = Gtk2::TreePath->new_from_string("0");
    while ($pos > 0) {
      $path->next();
      $pos -= 1;
    }
    $iter = $obj->{store}->get_iter($path);
  }
  my $new = (defined $iter)? $obj->{store}->insert_before($iter):
                             $obj->{store}->append();
  my @data = (); for (my $c = 0; $c < $obj->{ncols}; $c ++) {
    push(@data, $c => $row->[$c]);
  }
  $obj->{store}->set($new, @data);
  if (defined $obj->{path}) {
    if ($obj->{path}->compare($obj->{store}->get_path($new)) >= 0) {
      $obj->{path}->next();
    }
  }
  return $obj;
}

sub append {
  my $obj = shift;
  my $row = shift;
  return $obj->add($row, -1);
}

=item $List = $List->replace([$text1, ..., $textn]);

=cut

sub replace {
  my $obj = shift;
  my $row = shift;
  my $pos = shift;
  my $iter = undef;
  if (!defined $pos) {
    $iter = $obj->{selection}->get_selected();
  } elsif ($pos < 0) {
    my $path = Gtk2::TreePath->new_from_string("0");
    my $new_iter = $obj->{store}->get_iter($path);
    while (defined $new_iter) {
      $iter = $new_iter;
      $path->next();
      $new_iter = $obj->{store}->get_iter($path);
    }
  } else {
    my $path = Gtk2::TreePath->new_from_string("0");
    while ($pos > 0) {
      $path->next();
      $pos -= 1;
    }
    $iter = $obj->{store}->get_iter($path);
  }
  return $obj if (!defined $iter);
  my @data = (); for (my $c = 0; $c < $obj->{ncols}; $c ++) {
    push(@data, $c => $row->[$c]);
  }
  $obj->{store}->set($iter, @data);
  return $obj;
}

=item [$text1, ..., $textn] = $List->get();

=cut

sub get {
  my $obj = shift;
  my $iter = $obj->{selection}->get_selected();
  return undef if (!defined $iter);
  my @indexes = (0 .. ($obj->{ncols} - 1));
  return [($obj->{store}->get($iter, @indexes))];
}

=item [$text1, ..., $textn] = $List->getFirstRow();

=cut

sub getFirstRow {
  my $obj = shift;
  $obj->{path} = undef;
  my $path = Gtk2::TreePath->new_from_string("0");
  my $iter = $obj->{store}->get_iter($path);
  return undef if (!defined $iter);
  $obj->{path} = $path;
  my @indexes = (0 .. ($obj->{ncols} - 1));
  return [($obj->{store}->get($iter, @indexes))];
}

=item [$text1, ..., $textn] = $List->getNextRow();

=cut

sub getNextRow {
  my $obj = shift;
  return undef if (!defined $obj->{path});
  $obj->{path}->next();
  my $iter = $obj->{store}->get_iter($obj->{path});
  if (!defined $iter) {
    $obj->{path} = undef;
    return undef;
  }
  my @indexes = (0 .. ($obj->{ncols} - 1));
  return [($obj->{store}->get($iter, @indexes))];
}

=item [$text1, ..., $textn] = $List->getRowAt($pos);

=cut

sub getRowAt {
  my $obj = shift;
  my $pos = shift;
  my $path = Gtk2::TreePath->new_from_string("0");
  $pos = ($obj->{store}->iter_n_children() - 1) if ($pos < 0);
  while ($pos > 0) {
    $path->next();
    $pos -= 1;
  }
  my $iter = $obj->{store}->get_iter($path);
  return undef if (!defined $iter);
  my @indexes = (0 .. ($obj->{ncols} - 1));
  return [($obj->{store}->get($iter, @indexes))];
}

=item ([$text1, ..., $textn], ...) = $List->getAllRows();

=cut

sub getAllRows {
  my $obj = shift;
  my @list = ();
  my @indexes = (0 .. ($obj->{ncols} - 1));
  my $path = Gtk2::TreePath->new_from_string("0");
  my $iter = $obj->{store}->get_iter($path);
  while (defined $iter) {
    push(@list, [($obj->{store}->get($iter, @indexes))]);
    $path->next();
    $iter = $obj->{store}->get_iter($path);
  }
  return @list;
}

=item ([$text1, ..., $textn], ...) = $List->getAllSettings();

=cut

sub getAllSettings {
  my $obj = shift;
  my @list = ();
  my @indexes = (0 .. ($obj->{ncols} - 1));
  my $path = Gtk2::TreePath->new_from_string("0");
  my $iter = $obj->{store}->get_iter($path);
  while (defined $iter) {
    push(@list, [($obj->{store}->get($iter, @indexes))]);
    $path->next();
    $iter = $obj->{store}->get_iter($path);
  }
  return @list;
}

=item $List = $List->remove();

=cut

sub remove {
  my $obj = shift;
  my $iter = $obj->{selection}->get_selected();
  return $obj if (!defined $iter);
  my $path = $obj->{store}->get_path($iter);
  if (defined $obj->{path}) {
    if ($obj->{path}->compare($path) >= 0) {
      $obj->{path}->prev();
    }
  }
  $obj->{store}->remove($iter);
  $obj->{selection}->select_path($path);
  return $obj;
}

=item $List = $List->removeAt($pos);

=cut

sub removeAt {
  my $obj = shift;
  my $pos = shift;
  my $path = Gtk2::TreePath->new_from_string("0");
  $pos = ($obj->{store}->iter_n_children() - 1) if ($pos < 0);
  while ($pos > 0) {
    $path->next();
    $pos -= 1;
  }
  my $iter = $obj->{store}->get_iter($path);
  return $obj if (!defined $iter);
  if (defined $obj->{path}) {
    if ($obj->{path}->compare($obj->{store}->get_path($iter)) >= 0) {
      $obj->{path}->prev();
    }
  }
  $obj->{store}->remove($iter);
  return $obj;
}

=item $List = $List->removeAll();

=cut

sub removeAll {
  my $obj = shift;
  $obj->{store}->clear();
  $obj->{selection}->unselect_all();
  $obj->{path} = undef;
  return $obj;
}

=back

=head3 Class ChoiceList: IntoDBWidget

=over

=cut

package ChoiceList;
our @ISA = qw(IntoDBWidget);

=item $ChoiceList = ChoiceList->new();

events: C<row-activated($path)>, C<rows-reordered>

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);
  my $ncols = 2;

  #my @typelist = ('Glib::String', 'Gtk2::ComboBox');
  #my @typelist = ('Glib::String', 'Glib::String');
  my @typelist = ('Glib::String', 'Glib::String', 'Gtk2::ListStore');
  my $store = Gtk2::ListStore->new(@typelist);
  my $view = Gtk2::TreeView->new($store);
  $view->set_headers_visible($GTK_FALSE);
  $view->set_reorderable($GTK_FALSE);
  $view->set_headers_visible($GTK_FALSE);

  my $stxt = Gtk2::CellRendererText->new();
  my $scol = Gtk2::TreeViewColumn->new();
  $scol->pack_start($stxt, $GTK_FALSE);
  $scol->add_attribute($stxt, 'text' => "0");
  $scol->set_reorderable($GTK_FALSE);
  $view->append_column($scol);

  my $ctxt = Gtk2::CellRendererCombo->new();
  $ctxt->set('has_entry' => $GTK_FALSE);
  $ctxt->set('text_column' => 0);
  $ctxt->set('editable' => $GTK_TRUE);
  $ctxt->signal_connect ('edited' => sub {
    my $cell = shift;
    my $path = shift;
    my $ntxt = shift;
    my $obj = shift;
    my $iter = $obj->{store}->get_iter_from_string($path);
    $obj->{store}->set($iter, 1, $ntxt);
  }, $obj);
  my $ccol = Gtk2::TreeViewColumn->new();
  $ccol->pack_start($ctxt, $GTK_FALSE);
  $ccol->add_attribute($ctxt, 'text' => "1");
  $ccol->add_attribute($ctxt, 'model' => "2");
  $ccol->set_reorderable($GTK_FALSE);
  $view->append_column($ccol);

  my $selection = $view->get_selection();
  $selection->set_mode('single');

  my $scroll = Gtk2::ScrolledWindow->new();
  $scroll->set_shadow_type('etched-out');
  $scroll->set_policy('automatic', 'automatic');
  $scroll->add($view);

  $view->signal_connect('row-activated' => sub {
    my $widget = shift;
    my $path = shift;
    my $col = shift;
    my $obj = shift;
    my $iter = $obj->{store}->get_iter($path);
    if (defined $iter) {
      my @indexes = (0 .. ($obj->{ncols}));
      my $row = [($obj->{store}->get($iter, @indexes))];
      $obj->signalEvent('row-activated', $row, $path, $col);
    }
  }, $obj);
  $store->signal_connect('rows-reordered' => sub{
    my $widget = shift;
    my $path = shift;
    my $iter = shift;
    my $ptr = shift;
    my $obj = shift;
    $obj->signalEvent('rows-reordered')
  }, $obj);

  $obj->{ncols} = $ncols;
  $obj->{store} = $store;
  $obj->{view} = $view;
  $obj->{selection} = $selection;
  $obj->{path} = undef;
  $obj->{cpath} = undef;
  $obj->{widget} = $scroll;

  return $obj;
}

=item $int = $ChoiceList->getNColumns();

=cut

sub getNColumns {
  my $obj = shift;
  return $obj->{ncols};
}

=item $ChoiceList = $ChoiceList->setReorderable($bool);

=cut

sub setReorderable {
  my $obj = shift;
  my $bool = $_[0]? $GTK_TRUE: $GTK_FALSE;
  $obj->{view}->set_reorderable($bool);
  return $obj;
}

=item $ChoiceList = $ChoiceList->setColumnReorderable($pos, $bool);

=cut

sub setColumnReorderable {
  my $obj = shift;
  my $pos = shift;
  my $bool = ($_[0])? $GTK_TRUE: $GTK_FALSE;
  #$obj->{view}->get_column($pos)->set_reorderable($bool);
  return $obj;
}

=item $ChoiceList = $ChoiceList->setHeader($pos, $title);

=cut

sub setHeader {
  my $obj = shift;
  my $pos = shift;
  my $title = shift; $title = "" if (!defined $title);
  $obj->{view}->get_column($pos)->set_title($title);
  return $obj;
}

=item $ChoiceList = $ChoiceList->setHeadersVisible($bool);

=cut

sub setHeadersVisible {
  my $obj = shift;
  my $bool = $_[0]? $GTK_TRUE: $GTK_FALSE;
  $obj->{view}->set_headers_visible($bool);
  return $obj;
}

=item $ChoiceList = $ChoiceList->setColumnVisible($pos, $bool);

=cut

sub setColumnVisible {
  my $obj = shift;
  my $pos = shift;
  my $bool = $_[0]? $GTK_TRUE: $GTK_FALSE;
  $obj->{view}->get_column($pos)->set_visible($bool);
  return $obj;
}

=item $ChoiceList = $ChoiceList->add([$key, $option]);

=item $ChoiceList = $ChoiceList->append([$key, $option]);

=cut

sub add {
  my $obj = shift;
  my $row = shift;
  my ($key, $option) = @$row;
  my $cmb_model = undef;

  my $lst_path = Gtk2::TreePath->new_from_string("0");
  my $lst_iter = $obj->{store}->get_iter($lst_path);
  my $lst_txt = undef;
  while (defined($lst_iter)) {
    ($lst_txt) = $obj->{store}->get($lst_iter, 0);
    last if (Check::sorter($lst_txt, $key) >= 0);
    $lst_txt = undef;
    $lst_path->next();
    $lst_iter = $obj->{store}->get_iter($lst_path);
  }
  if (!defined($lst_iter)) {
    $lst_iter = $obj->{store}->append();
    $cmb_model = Gtk2::ListStore->new('Glib::String');
  } elsif (Check::sorter($lst_txt, $key) > 0) {
    $lst_iter = $obj->{store}->insert_before($lst_iter);
    $cmb_model = Gtk2::ListStore->new('Glib::String');
  } else {
    # already set
    ($cmb_model) = $obj->{store}->get($lst_iter, 2);
  }

  # Add option to combo
  
  $option = "" if (!defined($option));
  #my $cmb_model = $combo->get_model();
  my $cmb_path = Gtk2::TreePath->new_from_string("0");
  my $cmb_iter = $cmb_model->get_iter($cmb_path);
  my $cmb_txt = undef;
  while (defined($cmb_iter)) {
    ($cmb_txt) = $cmb_model->get($cmb_iter, 0);
    last if (Check::sorter($cmb_txt, $option) >= 0);
    $cmb_txt = undef;
    $cmb_path->next();
    $cmb_iter = $cmb_model->get_iter($cmb_path);
  }
  if (!defined($cmb_iter)) {
    $cmb_iter = $cmb_model->append();
    $cmb_model->set($cmb_iter, 0 => $option);
  } elsif (Check::sorter($cmb_txt, $option) > 0) {
    $cmb_iter = $cmb_model->insert_before($cmb_iter);
    $cmb_model->set($cmb_iter, 0 => $option);
  } else {
    # already set
  }

  # set active things
  $obj->{store}->set($lst_iter, 0 => $key, 1 => $option, 2 => $cmb_model);
  $obj->{selection}->select_iter($lst_iter);

  # cleanup paths
  $obj->{path} = undef;
  $obj->{cpath} = undef;

  # return object
  return $obj;
}

sub append {
  my $obj = shift;
  my $row = shift;
  return $obj->add($row);
}

=item [$key, $option] = $ChoiceList->get();

=cut

sub get {
  my $obj = shift;
  my $iter = $obj->{selection}->get_selected();
  return undef if (!defined $iter);
  my ($key) = $obj->{store}->get($iter, 0);
  my ($val) = $obj->{store}->get($iter, 1);
  return [$key, $val];
}

=item [$key, $option] = $ChoiceList->getByKey($key);

=cut

sub getByKey {
  my $obj = shift;
  my $key = shift;
  my $lst_path = Gtk2::TreePath->new_from_string("0");
  my $lst_iter = $obj->{store}->get_iter($lst_path);
  my $lst_txt = undef;
  while (defined($lst_iter)) {
    ($lst_txt) = $obj->{store}->get($lst_txt, 0);
    last if (Check::sorter($lst_txt, $key) >= 0);
    $lst_txt = undef;
    $lst_path->next();
    $lst_iter = $obj->{store}->get_iter($lst_path);
  }
  return undef if (!defined($lst_iter) || Check::sorter($lst_txt, $key) != 0);
  my ($val) = $obj->{store}->get($lst_iter, 1);
  return [$key, $val];
}

=item [$key, $option] = $ChoiceList->getFirstRow();

=cut

sub getFirstRow {
  my $obj = shift;
  $obj->{path} = undef;
  $obj->{cpath} = undef;

  my $path = Gtk2::TreePath->new_from_string("0");
  my $iter = $obj->{store}->get_iter($path);
  return undef if (!defined $iter);

  my ($dat) = $obj->{store}->get($iter, 2);
  my $cpath = Gtk2::TreePath->new_from_string("0");
  my $citer = $dat->get_iter($path);
  return undef if (!defined $citer);

  $obj->{path} = $path;
  $obj->{cpath} = $cpath;
  return [$obj->{store}->get($iter, 0), $dat->get($citer, 0)];
}

=item [$key, $option] = $ChoiceList->getNextRow();

=cut

sub getNextRow {
  my $obj = shift;
  return undef if (!defined $obj->{path} || !defined $obj->{cpath});
  my $iter = $obj->{store}->get_iter($obj->{path});
  my ($dat) = $obj->{store}->get($iter, 2);
  $obj->{cpath}->next();
  my $citer = $dat->get_iter($obj->{cpath});

  if (defined($citer)) {
    return [$obj->{store}->get($iter, 0), $dat->get($citer, 0)];
  }
  
  $obj->{path}->next();
  $iter = $obj->{store}->get_iter($obj->{path});

  if (!defined($iter)) {
    $obj->{path} = undef;
    $obj->{cpath} = undef;
    return undef;
  }
 
  my $cpath = Gtk2::TreePath->new_from_string("0");
  $citer = $dat->get_iter($cpath);
  if (!defined($citer)) {
    $obj->{path} = undef;
    $obj->{cpath} = undef;
    return undef;
  }

  $obj->{cpath} = $cpath;
  return [$obj->{store}->get($iter, 0), $dat->get($citer, 0)];
}

=item [$key, $option] = $ChoiceList->getFirstSetting();

=cut

sub getFirstSetting {
  my $obj = shift;
  $obj->{path} = undef;
  $obj->{cpath} = undef;

  my $path = Gtk2::TreePath->new_from_string("0");
  my $iter = $obj->{store}->get_iter($path);
  return undef if (!defined $iter);

  my ($val) = $obj->{store}->get($iter, 1);
  $obj->{path} = $path;
  return [$obj->{store}->get($iter, 0), $val];
}

=item [$key, $option] = $ChoiceList->getNextSetting();

=cut

sub getNextSetting {
  my $obj = shift;
  return undef if (!defined $obj->{path});

  $obj->{path}->next();
  my $iter = $obj->{store}->get_iter($obj->{path});
  if (!defined($iter)) {
    $obj->{path} = undef;
    $obj->{cpath} = undef;
    return undef;
  }
  my ($val) = $obj->{store}->get($iter, 1);
  $obj->{cpath} = undef;
  return [$obj->{store}->get($iter, 0), $val];
}

=item ([$key, $option], ...) = $ChoiceList->getAllRows();

=cut

sub getAllRows {
  my $obj = shift;
  my @list = ();

  my $path = Gtk2::TreePath->new_from_string("0");
  my $iter = $obj->{store}->get_iter($path);
  while (defined($iter)) {
    my ($dat) = $obj->{store}->get($iter, 2);
    my ($active) = $obj->{store}->get($iter, 1);
    my $cpath = Gtk2::TreePath->new_from_string("0");
    my $citer = $dat->get_iter($cpath);
    while (defined($citer)) {
      my ($value) = $dat->get($citer, 0);
      if (!defined($active) || $active ne $value) {
        push(@list, [$obj->{store}->get($iter, 0), $dat->get($citer, 0)]);
      }
      $cpath->next();
      $citer = $dat->get_iter($cpath);
    }
    if (defined($active)) {
      push(@list, [$obj->{store}->get($iter, 0), $active]);
    }
    $path->next();
    $iter = $obj->{store}->get_iter($path);
  }
  return @list;
}

=item ([$key, $option], ...) = $ChoiceList->getAllSettings();

=cut

sub getAllSettings {
  my $obj = shift;
  my @list = ();

  my $path = Gtk2::TreePath->new_from_string("0");
  my $iter = $obj->{store}->get_iter($path);
  while (defined($iter)) {
    my ($val) = $obj->{store}->get($iter, 1);
    push(@list, [$obj->{store}->get($iter, 0), $val]);
    $path->next();
    $iter = $obj->{store}->get_iter($path);
  }
  return @list;
}

=item $List = $List->remove();

=cut

sub remove {
  my $obj = shift;
  my $iter = $obj->{selection}->get_selected();
  return $obj if (!defined $iter);

  my ($dat) = $obj->{store}->get($iter, 2);
  my ($active) = $obj->{store}->get($iter, 1);
  my $cpath = Gtk2::TreePath->new_from_string("0");
  my $citer = $dat->get_iter($cpath);
  while (defined($citer)) {
    my ($value) = $dat->get($citer, 0);
    last if (Check::sorter($value, $active) == 0);
    $cpath->next();
    $citer = $dat->get_iter($cpath);
  }
  return $obj if (!defined $citer);

  # remove setting
  $dat->remove($citer);
  $cpath = Gtk2::TreePath->new_from_string("0");
  $citer = $dat->get_iter($cpath);

  # no need to remove the entire row if there are more values
  if (defined $citer) {
    my ($value) = $dat->get($citer, 0);
    $obj->{store}->set($iter, 1 => $value); 
    return $obj;
  }

  # no more settings: delete row
  my $path = $obj->{store}->get_path($iter);
  if (defined $obj->{path}) {
    if ($obj->{path}->compare($path) >= 0) {
      $obj->{path}->prev();
    }
  }
  $obj->{store}->remove($iter);
  $obj->{selection}->select_path($path);
  return $obj;
}

=item $List = $List->removeSetting();

=cut

sub removeSetting {
  my $obj = shift;
  my $iter = $obj->{selection}->get_selected();
  return $obj if (!defined $iter);
  my $path = $obj->{store}->get_path($iter);
  if (defined $obj->{path}) {
    if ($obj->{path}->compare($path) >= 0) {
      $obj->{path}->prev();
    }
  }
  $obj->{store}->remove($iter);
  $obj->{selection}->select_path($path);
  return $obj;
}

=item $List = $List->removeAll();

=cut

sub removeAll {
  my $obj = shift;
  $obj->{store}->clear();
  $obj->{selection}->unselect_all();
  $obj->{path} = undef;
  $obj->{cpath} = undef;
  return $obj;
}

=back

=head3 Class DBConnector: IntoDBWidget

=over

=cut

package DBConnector;
our @ISA = qw(IntoDBWidget);

=item $DBConnector = DBConnector->new();

events: C<changed>

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);

  my $label1 = Gtk2::Label->new("file:");
  my $entry = Gtk2::Entry->new();
  $entry->set_editable($GTK_TRUE);
  $entry->signal_connect('changed' => sub {
    my $widget = shift;
    my $obj = shift;
    my $text = $widget->get_text();
    my $style = $widget->get_default_style();
    if (-f $text) {
      $widget->modify_text('normal', $style->fg('normal'));
    } else {
      $widget->modify_text('normal', Gtk2::Gdk::Color->parse("red"));
    }
  }, $obj);
  my $browse = Gtk2::Button->new("browse");
  $browse->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $filechooser = FileWindow->new("IntoDB - Select Database File");
    my $file = $filechooser->run();
    if (defined $file) {
      $entry = $obj->{entry};
      $entry->set_text($file);
    }
  }, $obj);
  my $current = Gtk2::Button->new("current");
  $current->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    $obj->refresh();
  }, $obj);

  my $label2 = Gtk2::Label->new("status:");
  my $info = Gtk2::Label->new();
  my $connect = Gtk2::Button->new("connect");
  $connect->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $file = $obj->{entry}->get_text();
    eval {
      my $newdb = DB->new($file, $FALSE);
      $DBH->disconnect() if ($DBH);
      $DBH = $newdb;
      $DBFILE = $file;
    };
    ErrorWindow->new($@)->run() if ($@);
    $obj->refresh();
    $obj->signalEvent('changed');
  }, $obj);
  my $disconnect = Gtk2::Button->new("disconnect");
  $disconnect->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    eval {$DBH->disconnect(); $DBH = undef};
    ErrorWindow->new($@)->run() if ($@);
    $obj->refresh();
    $obj->signalEvent('changed');
  }, $obj);
  my $create = Gtk2::Button->new("create");
  $create->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $file = $obj->{entry}->get_text();
    eval {
      my $newdb = DB->new($file, $TRUE);
      $DBH->disconnect() if (defined $DBH);
      $DBH = $newdb;
      $DBFILE = $file;
    };
    if ($@) {
      ErrorWindow->new($@)->run();
    }
    $obj->refresh();
    $obj->signalEvent('changed');
  }, $obj);

  my $box1 = Gtk2::HBox->new();
  $box1->pack_start($label1, $GTK_FALSE, $GTK_FALSE, 1);
  $box1->pack_start($entry, $GTK_TRUE, $GTK_TRUE, 1);
  $box1->pack_end($current, $GTK_FALSE, $GTK_FALSE, 1);
  $box1->pack_end($browse, $GTK_FALSE, $GTK_FALSE, 1);

  my $box2 = Gtk2::HBox->new();
  $box2->pack_start($label2, $GTK_FALSE, $GTK_FALSE, 1);
  $box2->pack_start($info, $GTK_FALSE, $GTK_FALSE, 1);
  $box2->pack_start($connect, $GTK_FALSE, $GTK_FALSE, 1);
  $box2->pack_start($disconnect, $GTK_FALSE, $GTK_FALSE, 1);
  $box2->pack_start($create, $GTK_FALSE, $GTK_FALSE, 1);

  my $box = Gtk2::VBox->new();
  $box->pack_start($box1, $GTK_TRUE, $GTK_TRUE, 0);
  $box->pack_start($box2, $GTK_FALSE, $GTK_FALSE, 0);

  my $frame = Gtk2::Frame->new("Database Connection");
  $frame->set_shadow_type('etched-out');
  $frame->add($box);

  $obj->{b_connect} = $connect;
  $obj->{b_disconnect} = $disconnect;
  $obj->{b_create} = $create;
  $obj->{entry} = $entry;
  $obj->{info} = $info;
  $obj->{widget} = $frame;

  $obj->refresh();

  return $obj;
}

=item $DBConnector = $DBConnector->refresh();

=cut

sub refresh {
  my $obj = shift;
  my $dbfile = $DBFILE;
  $dbfile = "" if (!defined $dbfile);
  $obj->{entry}->set_text($dbfile);
  if (-f $dbfile) {
    my $style = $obj->{entry}->get_default_style();
    $obj->{entry}->modify_text('normal', $style->fg('normal'));
  } else {
    $obj->{entry}->modify_text('normal', Gtk2::Gdk::Color->parse("red"));
  }
  if (defined $DBH) {
    my $style = $obj->{info}->get_default_style();
    $obj->{info}->set_text("connected");
    $obj->{b_connect}->set_sensitive($GTK_FALSE);
    $obj->{b_disconnect}->set_sensitive($GTK_TRUE);
    $obj->{b_create}->set_sensitive($GTK_FALSE);
  } else {
    $obj->{info}->set_text("disconnected");
    $obj->{b_connect}->set_sensitive($GTK_TRUE);
    $obj->{b_disconnect}->set_sensitive($GTK_FALSE);
    $obj->{b_create}->set_sensitive($GTK_TRUE);
  }
  return $obj;
}

=back

=head3 Class BenchmarkList: IntoDBWidget

=over

=cut

package BenchmarkList;
our @ISA = qw(IntoDBWidget);

=item $BenchmarkList = BenchmarkList->new();

events: C<edit($Benchmark)>, C<remove($bench_id)>

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);

  my $list = List->new(3);
  $list->setHeadersVisible($TRUE);
  $list->setHeader(0, "id");
  $list->setHeader(1, "name");
  $list->setHeader(2, "description");
  $list->setColumnVisible(0, $FALSE);
  $list->setCallback('row-activated', Callback->new(sub {
    my $obj = shift;
    my $wdg = shift;
    my $row = shift;
    my $p = shift;
    my $c = shift;
    eval {
      my $bench = Benchmark->get($DBH, $row->[1]);
      $obj->signalEvent('edit', $bench);
    };
    ErrorWindow->new($@)->run() if ($@);
  }, $obj));

  my $name = Gtk2::Entry->new();
  $name->signal_connect('changed' => sub {
    my $widget = shift;
    my $obj = shift;
    my $text = $widget->get_text();
    if ($text =~ /^[\w_]+$/) {
      my $style = $widget->get_default_style();
      $widget->modify_text('normal', $style->fg('normal'));
    } else {
      $widget->modify_text('normal', Gtk2::Gdk::Color->parse("red"));
    }
  }, $obj);

  my $new = Gtk2::Button->new("new");
  $new->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $text = $obj->{name}->get_text();
    if ($text =~ /^\s*$/) {
      ErrorWindow->new("null name for new benchmark")->run();
    } elsif ($text !~ /^[\w_]+$/) {
      ErrorWindow->new("invalid name for new benchmark: \"$text\"")->run();
    } else {
      eval {
        Benchmark->new($DBH, $text);
        $obj->refresh();
      };
      ErrorWindow->new($@)->run() if ($@);
    }
  }, $obj);

  my $edit = Gtk2::Button->new("edit");
  $edit->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $item = $obj->{list}->get();
    if (defined $item) {
      my $bench = undef;
      eval {
        $bench = Benchmark->get($DBH, $item->[1]);
        $obj->signalEvent('edit', $bench);
      };
      ErrorWindow->new($@)->run() if ($@);
    }
  }, $obj);

  my $remove = Gtk2::Button->new("remove");
  $remove->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $item = $obj->{list}->get();
    if (defined $item) {
      eval {
        my $b = Benchmark->get($DBH, $item->[1]);
        $b->remove();
        $obj->{list}->remove();
        $obj->signalEvent('remove', $item->[0]);
      };
      ErrorWindow->new($@)->run() if ($@);
    }
  }, $obj);

  my $option = Gtk2::CheckButton->new_with_label("show description");
  $option->set_active($GTK_TRUE);
  $option->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    if ($widget->get_active()) {
      $obj->{list}->setColumnVisible(2, $GTK_TRUE);
    } else {
      $obj->{list}->setColumnVisible(2, $GTK_FALSE);
    }
  }, $obj);

  my $box1 = Gtk2::HBox->new();
  $box1->pack_start($option, $GTK_FALSE, $GTK_FALSE, 1);

  my $box2 = Gtk2::HBox->new();
  $box2->pack_start($name, $GTK_TRUE, $GTK_TRUE, 0);
  $box2->pack_end($new, $GTK_FALSE, $GTK_FALSE, 0);

  my $box3 = Gtk2::VBox->new();
  $box3->pack_start($list->widget(), $GTK_TRUE, $GTK_TRUE, 0);
  $box3->pack_end($box2, $GTK_FALSE, $GTK_FALSE, 0);

  my $box4 = Gtk2::VBox->new();
  $box4->pack_start($edit, $GTK_FALSE, $GTK_FALSE, 0);
  $box4->pack_start($remove, $GTK_FALSE, $GTK_FALSE, 0);

  my $box5 = Gtk2::HBox->new();
  $box5->pack_start($box3, $GTK_TRUE, $GTK_TRUE, 0);
  $box5->pack_start($box4, $GTK_FALSE, $GTK_FALSE, 0);

  my $box = Gtk2::VBox->new();
  $box->pack_start($box5, $GTK_TRUE, $GTK_TRUE, 0);
  $box->pack_end($box1, $GTK_FALSE, $GTK_FALSE, 0);

  my $frame = Gtk2::Frame->new("Benchmarks");
  $frame->set_shadow_type('etched-out');
  $frame->add($box);

  $obj->{b_new} = $new;
  $obj->{b_edit} = $edit;
  $obj->{b_remove} = $remove;
  $obj->{list} = $list;
  $obj->{name} = $name;
  $obj->{option} = $option;
  $obj->{widget} = $frame;

  $obj->refresh();

  return $obj;
}

=item $BenchmarkList = $BenchmarkList->refresh();

=cut

sub refresh {
  my $obj = shift;
  $obj->{list}->removeAll();
  if (defined $DBH) {
    my @benchmarks = Benchmark->list($DBH);
    foreach my $b (@benchmarks) {
      my $desc = $b->getDesc(); $desc = "" if (!defined $desc);
      $obj->{list}->append([$b->id(), $b->getName(), $desc]);
    }
    $obj->{b_new}->set_sensitive($GTK_TRUE);
    $obj->{b_edit}->set_sensitive($GTK_TRUE);
    $obj->{b_remove}->set_sensitive($GTK_TRUE);
    $obj->{name}->set_sensitive($GTK_TRUE);
  } else {
    $obj->{b_new}->set_sensitive($GTK_FALSE);
    $obj->{b_edit}->set_sensitive($GTK_FALSE);
    $obj->{b_remove}->set_sensitive($GTK_FALSE);
    $obj->{name}->set_text("");
    $obj->{name}->set_sensitive($GTK_FALSE);
  }
  return $obj;
}

=back

=head3 Class FieldList: IntoDBWidget

=over

=cut

package FieldList;
our @ISA = qw(IntoDBWidget);

=item $FieldList = FieldList->new($Benchmark);

events: C<changed>, C<remove($field_name)>

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);
  my $bench = shift;

  my $list = List->new(3);
  $list->setHeadersVisible($TRUE);
  $list->setHeader(0, "name");
  $list->setHeader(1, "type");
  $list->setHeader(2, "key");

  my $name = Gtk2::Entry->new();
  $name->signal_connect('changed' => sub {
    my $widget = shift;
    my $obj = shift;
    my $text = $widget->get_text();
    if ($text =~ /^[\w_]+$/) {
      my $style = $widget->get_default_style();
      $widget->modify_text('normal', $style->fg('normal'));
    } else {
      $widget->modify_text('normal', Gtk2::Gdk::Color->parse("red"));
    }
  }, $obj);

  my $new = Gtk2::Button->new("new");
  $new->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $text = $obj->{name}->get_text();
    if ($text =~ /^\s*$/) {
      ErrorWindow->new("null name for new field")->run();
    } elsif ($text !~ /^[\w_]+$/) {
      ErrorWindow->new("invalid name for new field: \"$text\"")->run();
    } else {
      eval {
        Field->new($obj->{bench}, $text);
        $obj->refresh();
      };
      ErrorWindow->new($@)->run() if ($@);
      $obj->signalEvent('changed');
    }
  }, $obj);

  my $type = Gtk2::Button->new("change type");
  $type->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $item = $obj->{list}->get();
    if (defined $item) {
      eval {
        my $field = Field->get($obj->{bench}, $item->[0]);
        $field->setNumeric(!$field->getNumeric());
        $obj->{list}->replace(
            [$field->name(), 
            ($field->numeric())? "numeric": "text",
            ($field->getKey())? "true": ""]);
      };
      ErrorWindow->new($@)->run() if ($@);
    }
  }, $obj);

  my $key = Gtk2::Button->new("toggle key");
  $key->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $item = $obj->{list}->get();
    if (defined $item) {
      eval {
        my $field = Field->get($obj->{bench}, $item->[0]);
        $field->setKey(!$field->getKey());
        $obj->{list}->replace(
            [$field->name(), 
            ($field->numeric())? "numeric": "text",
            ($field->getKey())? "true": ""]);
      };
      ErrorWindow->new($@)->run() if ($@);
    }
  }, $obj);

  my $remove = Gtk2::Button->new("remove");
  $remove->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $item = $obj->{list}->get();
    if (defined $item) {
      eval {
        my $field = Field->get($obj->{bench}, $item->[0]);
        $field->remove();
        $obj->{list}->remove();
        $obj->signalEvent('remove', $item->[0]);
        $obj->signalEvent('changed');
      };
      ErrorWindow->new($@)->run() if ($@);
      $obj->signalEvent('changed');
    }
  }, $obj);

  my $remove_all = Gtk2::Button->new("remove all");
  $remove_all->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $confirm = ConfirmWindow->new("are you sure?")->run();
    if ($confirm eq "ok") {
      my $bench = $obj->{bench};
      eval {$bench->removeAllFields()};
      my $item = $obj->{list}->get();
      if ($@) {
        ErrorWindow->new($@)->run();
      } else {
        $obj->refresh();
      }
      $obj->signalEvent('changed');
    }
  }, $obj);

  my $load = Gtk2::Button->new("load from file");
  $load->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $filechooser = FileWindow->new("IntoDB - Load Benchmark Fields");
    my $file = $filechooser->run();
    if (defined $file) {
      my $input = IncludeFile->new($file);
      eval {
        my $csv = CsvFile->new($input);
        my @flist = $csv->getFieldNames();
        foreach my $f (@flist) {
          eval {
            my $field = Field->new($obj->{bench}, $f);
            $field->setNumeric($csv->getNumeric($f));
          };
          if ($@) {
            ErrorWindow->new($@)->run();
          }
        }
      };
      if ($@) {
        ErrorWindow->new($@)->run();
      }
      $obj->signalEvent('changed');
      $obj->refresh();
    }
  }, $obj);

  my $box0 = Gtk2::HBox->new();
  $box0->pack_start($load, $GTK_FALSE, $GTK_FALSE, 0);

  my $box1 = Gtk2::HBox->new();
  $box1->pack_start($name, $GTK_TRUE, $GTK_TRUE, 0);
  $box1->pack_end($new, $GTK_FALSE, $GTK_FALSE, 0);

  my $box2 = Gtk2::VBox->new();
  $box2->pack_start($list->widget(), $GTK_TRUE, $GTK_TRUE, 0);
  $box2->pack_end($box1, $GTK_FALSE, $GTK_FALSE, 0);

  my $box3 = Gtk2::VBox->new();
  $box3->pack_start($type, $GTK_FALSE, $GTK_FALSE, 0);
  $box3->pack_start($key, $GTK_FALSE, $GTK_FALSE, 0);
  $box3->pack_start($remove, $GTK_FALSE, $GTK_FALSE, 0);
  $box3->pack_start($remove_all, $GTK_FALSE, $GTK_FALSE, 0);

  my $box4 = Gtk2::HBox->new();
  $box4->pack_start($box2, $GTK_TRUE, $GTK_TRUE, 0);
  $box4->pack_start($box3, $GTK_FALSE, $GTK_FALSE, 0);

  my $box = Gtk2::VBox->new();
  $box->pack_start($box4, $GTK_TRUE, $GTK_TRUE, 0);
  $box->pack_end($box0, $GTK_FALSE, $GTK_FALSE, 0);

  my $frame = Gtk2::Frame->new("Fields");
  $frame->set_shadow_type('etched-out');
  $frame->add($box);

  $obj->{bench} = $bench;
  $obj->{b_new} = $new;
  $obj->{b_type} = $type;
  $obj->{b_key} = $key;
  $obj->{b_remove} = $remove;
  $obj->{b_remove_all} = $remove_all;
  $obj->{b_load} = $load;
  $obj->{list} = $list;
  $obj->{name} = $name;
  $obj->{widget} = $frame;

  $obj->refresh();

  return $obj;
}

=item $BenchmarkList = $BenchmarkList->refresh();

=cut

sub refresh {
  my $obj = shift;
  $obj->{list}->removeAll();
  my @fields = $obj->{bench}->getFields();
  foreach my $f (@fields) {
    $obj->{list}->append(
          [$f->name(), 
          ($f->numeric())? "numeric": "text",
          ($f->getKey())? "true": ""]);
  }
  my $count = $obj->{bench}->getExpCount();
  if ($count > 0) {
    $obj->{b_new}->set_sensitive($GTK_FALSE);
    $obj->{b_type}->set_sensitive($GTK_FALSE);
    $obj->{b_key}->set_sensitive($GTK_FALSE);
    $obj->{b_remove}->set_sensitive($GTK_FALSE);
    $obj->{b_remove_all}->set_sensitive($GTK_FALSE);
    $obj->{b_load}->set_sensitive($GTK_FALSE);
  } else {
    $obj->{b_new}->set_sensitive($GTK_TRUE);
    $obj->{b_type}->set_sensitive($GTK_TRUE);
    $obj->{b_key}->set_sensitive($GTK_TRUE);
    $obj->{b_remove}->set_sensitive($GTK_TRUE);
    $obj->{b_remove_all}->set_sensitive($GTK_TRUE);
    $obj->{b_load}->set_sensitive($GTK_TRUE);
  }
  return $obj;
}

=back

=head3 Class BenchmarkParser: IntoDBWidget

=over

=cut

package BenchmarkParser;
our @ISA = qw(IntoDBWidget);

=item $BenchmarkParser = BenchmarkParser->new($Benchmark);

events: C<changed>, C<parse-begin>, C<parse-end>

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);
  my $bench = shift;

  my $list = List->new(3);
  $list->setHeadersVisible($TRUE);
  $list->setHeader(0, "field");
  $list->setHeader(1, "value");
  $list->setHeader(2, "auto-id");

  my $label0 = Gtk2::Label->new("experiment count:");
  my $counter = Gtk2::Label->new();
  $counter->set_text("0");
  my $docount = Gtk2::Button->new("count");
  $docount->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    $obj->{counter}->set_text($bench->getExpCount());
  }, $obj);

  my $label1 = Gtk2::Label->new("field:");
  my $field = Choice->new();

  my $label2 = Gtk2::Label->new("value:");
  my $auto = Gtk2::CheckButton->new_with_label("auto id");
  $auto->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    if ($widget->get_active()) {
      $obj->{value}->set_text("");
      $obj->{value}->set_sensitive($GTK_FALSE);
    } else {
      $obj->{value}->set_sensitive($GTK_TRUE);
    }
  }, $obj);
  my $value = Gtk2::Entry->new();

  my $new = Gtk2::Button->new("add");
  $new->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $field = $obj->{field}->get();
    if (defined $field) {
      my $val = [$field->[0], $obj->{value}->get_text(),
                 $obj->{auto}->get_active()? "true": ""];
      $obj->{list}->append($val);
    }
  }, $obj);

  my $copy = Gtk2::Button->new("copy");
  $copy->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $field = $obj->{list}->get();
    if (defined $field) {
      $obj->{field}->setByText($field->[0]);
      $obj->{value}->set_text($field->[1]);
      if ($field->[2] eq "true") {
        $obj->{auto}->set_active($GTK_TRUE);
      } else {
        $obj->{auto}->set_active($GTK_FALSE);
      }
    }
  }, $obj);

  my $remove = Gtk2::Button->new("remove");
  $remove->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    if (defined ($obj->{list}->get())) {
      $obj->{list}->remove();
    }
  }, $obj);

  my $label3 = Gtk2::Label->new("inserted:");
  my $inserted = Gtk2::Label->new("0");
  my $label4 = Gtk2::Label->new("skipped:");
  my $skipped = Gtk2::Label->new("0");
  my $cancel = Gtk2::Button->new("stop");
  $cancel->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    $obj->{progress}->setCancel() if (defined $obj->{progress});
  }, $obj);
  $cancel->set_sensitive($GTK_FALSE);
  my $parse = Gtk2::Button->new("import data file");
  $parse->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    $obj->{inserted}->set_text("0");
    $obj->{skipped}->set_text("0");
    my $file = FileWindow->new("IntoDB - Import CSV File")->run();
    if (defined $file) {
      $obj->{parse}->set_sensitive($GTK_FALSE);

      $obj->{progress} = Progress->new();
      $obj->{progress}->setHook("success", sub {
        my $prg = shift; my $val = shift; my $obj = shift;
        $obj->{inserted}->set_text($obj->{inserted}->get_text() + 1);
        $obj->{counter}->set_text($obj->{counter}->get_text() + 1);
        Gtk2->main_iteration() while (Gtk2->events_pending());
      }, $obj);
      $obj->{progress}->setHook("skipped", sub {
        my $prg = shift; my $val = shift; my $obj = shift;
        $obj->{skipped}->set_text($obj->{skipped}->get_text() + 1);
        Gtk2->main_iteration() while (Gtk2->events_pending());
      }, $obj);

      my @extra = ();
      foreach my $v ($obj->{list}->getAllRows()) {
        if ($v->[2] eq "true") {
          push(@extra, "--autoid=" . $v->[0]);
        } else {
          push(@extra, $v->[0] . "=" . $v->[1]);
        }
      }

      Gtk2->main_iteration() while (Gtk2->events_pending());
      $obj->signalEvent("parse-begin");
      $obj->{cancel}->set_sensitive($GTK_TRUE);
      my $old_progress = $PROGRESS;
      $PROGRESS = $obj->{progress};
      eval {
        IntoDB::run_parse($obj->{bench}->getName(), $file, @extra);
      };
      ErrorWindow->new($@)->run() if ($@);
      $obj->signalEvent("parse-end");

      $obj->{cancel}->set_sensitive($GTK_FALSE);
      $obj->{parse}->set_sensitive($GTK_TRUE);
      $obj->{progress} = undef;
      $PROGRESS = $old_progress;

      $obj->signalEvent('changed');
    }
  }, $obj);

  my $box0 = Gtk2::HBox->new();
  $box0->pack_start($label0, $GTK_FALSE, $GTK_FALSE, 1);
  $box0->pack_start($counter, $GTK_FALSE, $GTK_FALSE, 1);
  $box0->pack_start($docount, $GTK_FALSE, $GTK_FALSE, 1);

  my $box1 = Gtk2::HBox->new();
  $box1->pack_start($label1, $GTK_FALSE, $GTK_FALSE, 1);
  $box1->pack_start($field->widget(), $GTK_FALSE, $GTK_FALSE, 1);

  my $box2 = Gtk2::HBox->new();
  $box2->pack_start($label2, $GTK_FALSE, $GTK_FALSE, 1);
  $box2->pack_start($value, $GTK_TRUE, $GTK_TRUE, 1);
  $box2->pack_start($auto, $GTK_FALSE, $GTK_FALSE, 1);

  my $box3 = Gtk2::VBox->new();
  $box3->pack_start($box1, $GTK_FALSE, $GTK_FALSE, 0);
  $box3->pack_start($box2, $GTK_TRUE, $GTK_TRUE, 0);

  my $box4 = Gtk2::HBox->new();
  $box4->pack_start($box3, $GTK_TRUE, $GTK_TRUE, 0);
  $box4->pack_start($new, $GTK_FALSE, $GTK_FALSE, 0);

  my $box5 = Gtk2::VBox->new();
  $box5->pack_start($copy, $GTK_FALSE, $GTK_FALSE, 0);
  $box5->pack_start($remove, $GTK_FALSE, $GTK_FALSE, 0);

  my $box6 = Gtk2::VBox->new();
  $box6->pack_start($list->widget(), $GTK_TRUE, $GTK_TRUE, 0);
  $box6->pack_end($box4, $GTK_FALSE, $GTK_FALSE, 0);

  my $box7 = Gtk2::HBox->new();
  $box7->pack_start($box6, $GTK_TRUE, $GTK_TRUE, 0);
  $box7->pack_end($box5, $GTK_FALSE, $GTK_FALSE, 0);

  my $extra = Gtk2::Frame->new("Extra Values");
  $extra->set_shadow_type('none');
  $extra->add($box7);

  my $box8 = Gtk2::HBox->new();
  $box8->pack_start($label3, $GTK_FALSE, $GTK_FALSE, 2);
  $box8->pack_start($inserted, $GTK_FALSE, $GTK_FALSE, 2);
  $box8->pack_start($label4, $GTK_FALSE, $GTK_FALSE, 2);
  $box8->pack_start($skipped, $GTK_FALSE, $GTK_FALSE, 2);
  $box8->pack_start($cancel, $GTK_FALSE, $GTK_FALSE, 2);

  my $box9 = Gtk2::VBox->new();
  $box9->pack_start($box0, $GTK_FALSE, $GTK_FALSE, 0);
  $box9->pack_start($extra, $GTK_TRUE, $GTK_TRUE, 0);
  $box9->pack_end($box8, $GTK_FALSE, $GTK_FALSE, 0);
  $box9->pack_end($parse, $GTK_FALSE, $GTK_FALSE, 0);

  my $frame = Gtk2::Frame->new("Experiments");
  $frame->set_shadow_type('etched-out');
  $frame->add($box9);

  $obj->{bench} = $bench;
  $obj->{counter} = $counter;
  $obj->{inserted} = $inserted;
  $obj->{skipped} = $skipped;
  $obj->{cancel} = $cancel;
  $obj->{list} = $list;
  $obj->{field} = $field;
  $obj->{auto} = $auto;
  $obj->{value} = $value;
  $obj->{parse} = $parse;
  $obj->{widget} = $frame;

  $obj->refresh();

  return $obj;
}

=item $BenchmarkParser = $BenchmarkParser->refresh();

=cut

sub refresh {
  my $obj = shift;
  my $bench = $obj->{bench};
  #$obj->{counter}->set_text($bench->getExpCount());
  $obj->{field}->removeAll();
  my @fields = $bench->getFields();
  foreach my $f (@fields) {
    $obj->{field}->append([$f->name()]);
  }
  $obj->{field}->setByPosition(0);
  my $wrap = int(($#fields + 1)/20); $wrap = 1 if ($wrap < 1);
  $obj->{field}->setWrap($wrap);
  if ($obj->{auto}->get_active()) {
    $obj->{value}->set_text("");
    $obj->{value}->set_sensitive($GTK_FALSE);
  } else {
    $obj->{value}->set_sensitive($GTK_TRUE);
  }
  return $obj;
}

=item $BenchmarkParser = $BenchmarkParser->cancel();

=cut

sub cancel {
  my $obj = shift;
  my $progress = $obj->{progress};
  $progress->setCancel() if (defined $progress);
  return $obj;
}

=back

=head3 Class BenchmarkWindow: Window

=over

=cut

package BenchmarkWindow;
our @ISA = qw(Window);

=item $BenchmarkWindow = BenchmarkWindow->new($Benchmark, $parent);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $bench = shift;
  my $parent = shift;
  my $obj = $class->SUPER::new("IntoDB - Benchmark Manager", $parent);
  bless($obj, $class);

  my $idlabel = Gtk2::Label->new("benchmark id: " . $bench->id());

  my $label1 = Gtk2::Label->new("name:");
  $label1->set_alignment(1.0, 0.5);
  $label1->set_width_chars(12);

  my $name = Gtk2::Entry->new();
  $name->signal_connect('changed' => sub {
    my $widget = shift;
    my $obj = shift;
    my $text = $widget->get_text();
    if ($text =~ /^[\w_]+$/) {
      my $style = $widget->get_default_style();
      $widget->modify_text('normal', $style->fg('normal'));
    } else {
      $widget->modify_text('normal', Gtk2::Gdk::Color->parse("red"));
    }
  }, $obj);

  my $rename = Gtk2::Button->new("rename");
  $rename->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $text = $obj->{name}->get_text();
    if ($text =~ /^\s*$/) {
      ErrorWindow->new("null name for benchmark")->run();
    } elsif ($text !~ /^[\w_]+$/) {
      ErrorWindow->new("invalid name for benchmark: \"$text\"")->run();
    } else {
      eval {
        $obj->{bench}->setName($text);
        $obj->parent()->{benchlist}->refresh();
      };
      ErrorWindow->new($@)->run() if ($@);
    }
  }, $obj);

  my $reset1 = Gtk2::Button->new("reset");
  $reset1->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    $obj->{name}->set_text($obj->{bench}->getName());
  }, $obj);

  my $label2 = Gtk2::Label->new("description:");
  $label2->set_alignment(1.0, 0.5);
  $label2->set_width_chars(12);

  my $desc = Gtk2::Entry->new();
  my $update = Gtk2::Button->new("update");
  $update->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $text = $obj->{desc}->get_text();
    eval {
      $obj->{bench}->setDesc($text);
      $obj->parent()->{benchlist}->refresh();
    };
    ErrorWindow->new($@)->run() if ($@);
  }, $obj);
  my $reset2 = Gtk2::Button->new("reset");
  $reset2->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $desc = $obj->{bench}->getDesc(); $desc = "" if (!defined $desc);
    $obj->{desc}->set_text($desc);
  }, $obj);

  my $flist = FieldList->new($bench);
  $flist->setCallback("changed", Callback->new(sub {
    my $obj = shift;
    my $wdg = shift;
    $obj->{parser}->refresh();
  }, $obj));

  my $parser = BenchmarkParser->new($bench);
  $flist->setCallback("changed", Callback->new(sub {
    my $obj = shift;
    my $wdg = shift;
    $obj->{flist}->refresh();
  }, $obj));

  my $box0 = Gtk2::HBox->new();
  $box0->pack_start($idlabel, $GTK_FALSE, $GTK_FALSE, 1);

  my $box1 = Gtk2::HBox->new();
  $box1->pack_start($label1, $GTK_FALSE, $GTK_FALSE, 0);
  $box1->pack_start($name, $GTK_TRUE, $GTK_TRUE, 0);
  $box1->pack_end($reset1, $GTK_FALSE, $GTK_FALSE, 0);
  $box1->pack_end($rename, $GTK_FALSE, $GTK_FALSE, 0);

  my $box2 = Gtk2::HBox->new();
  $box2->pack_start($label2, $GTK_FALSE, $GTK_FALSE, 0);
  $box2->pack_start($desc, $GTK_TRUE, $GTK_TRUE, 0);
  $box2->pack_end($reset2, $GTK_FALSE, $GTK_FALSE, 0);
  $box2->pack_end($update, $GTK_FALSE, $GTK_FALSE, 0);

  my $box3 = Gtk2::VBox->new();
  $box3->pack_start($box0, $GTK_FALSE, $GTK_FALSE, 0);
  $box3->pack_start($box1, $GTK_TRUE, $GTK_FALSE, 0);
  $box3->pack_start($box2, $GTK_TRUE, $GTK_FALSE, 0);

  my $box4 = Gtk2::HBox->new();
  $box4->pack_start($parser->widget(), $GTK_TRUE, $GTK_TRUE, 2);
  $box4->pack_end($flist->widget(), $GTK_TRUE, $GTK_TRUE, 2);

  my $main_box = Gtk2::VBox->new();
  $main_box->pack_start($box3, $GTK_FALSE, $GTK_FALSE, 0);
  $main_box->pack_start($box4, $GTK_TRUE, $GTK_TRUE, 0);

  $obj->addContent($main_box);

  $obj->{bench} = $bench;
  $obj->{name} = $name;
  $obj->{desc} = $desc;
  $obj->{flist} = $flist;
  $obj->{parser} = $parser;

  $obj->refresh();

  return $obj;
}

=item $BenchmarkWindow->destroy();

=cut

sub destroy {
  my $obj = shift;
  my $main = $obj->parent();
  my $id = $obj->{bench}->id();
  delete $main->{benchwin}->{$id} if (exists $main->{benchwin}->{$id});
  $obj->{parser}->cancel();
  $obj->SUPER::destroy();
  return $obj;
}

=item $BenchmarkWindow = $BenchmarkWindow->refresh();

=cut

sub refresh {
  my $obj = shift;
  my $bench = $obj->{bench};
  my $desc = $bench->getDesc(); $desc = "" if (!defined $desc);
  $obj->{name}->set_text($bench->getName());
  $obj->{desc}->set_text($desc);
  return $obj;
}

=back

=head3 Class DataViewer: IntoDBWidget

=over

=cut

package DataViewer;
our @ISA = qw(IntoDBWidget);

=item $DataViewer = DataViewer->new([header1, ..., $headern];

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);
  my $headers = shift;

  my $can_toggle = 1;
  $can_toggle = 0 if (!grep {$_ eq "BENCH"} @$headers);
  $can_toggle = 0 if (!grep {$_ eq "EXP"} @$headers);

  my $hidden = {};
  my $hash = {};
  my $list = List->new($#$headers + 1);
  $list->setHeadersVisible($TRUE);
  for (my $i = 0; $i <= $#$headers; $i += 1) {
    my $title = $headers->[$i]; $title =~ s/_/__/g;
    $hash->{$headers->[$i]} = $i;
    $list->setHeader($i, $title);
    $list->setColumnReorderable($i, $TRUE);
  }
  $list->setCallback("row-activated", Callback->new(sub {
    my $obj = shift;
    my $wdg = shift;
    my $row = shift;
    my $path = shift;
    my $col = shift;
    if ($obj->{hide}->get_active()) {
      my $title = $col->get_title(); $title =~ s/__/_/g;
      $obj->{hidden}->{$obj->{hash}->{$title}} = 1;
      $obj->{show}->set_sensitive($GTK_TRUE);
      $col->set_visible($GTK_FALSE);
    }
  }, $obj));

  my $click_to_hide = Gtk2::CheckButton->new("double-click hides column");

  my $show = Gtk2::Button->new("show all columns");
  $show->set_sensitive($GTK_FALSE);
  $show->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my @cols = keys %{$obj->{hidden}};
    foreach my $c (@cols) {
      $obj->{list}->setColumnVisible($c, $TRUE);
      delete $obj->{hidden}->{$c};
    }
    $widget->set_sensitive($GTK_FALSE);
  }, $obj);

  my $toggle = undef;
  if ($can_toggle) {
    $toggle = Gtk2::Button->new("toggle outlier");
    $toggle->signal_connect('clicked' => sub {
      my $widget = shift;
      my $obj = shift;
      my $row = $obj->{list}->get();
      if (defined $row) {
        eval {
          my $bench = Benchmark->getById($DBH, $row->[$obj->{hash}->{"BENCH"}]);
          my $exp = Experiment->get($bench, $row->[$obj->{hash}->{"EXP"}]);
          if ($exp->getOutlier()) {
            $exp->setOutlier($FALSE);
            if (exists $obj->{hash}->{"OUT"}) {
              $row->[$obj->{hash}->{"OUT"}] = 0;
              $obj->{list}->replace($row);
            }
          } else {
            $exp->setOutlier($TRUE);
            if (exists $obj->{hash}->{"OUT"}) {
              $row->[$obj->{hash}->{"OUT"}] = 1;
              $obj->{list}->replace($row);
            }
          }
        };
        ErrorWindow->new($@)->run() if ($@);
      }
    }, $obj);
  }

  my $control = Gtk2::HBox->new();
  $control->pack_start($show, $GTK_FALSE, $GTK_FALSE, 1);
  $control->pack_start($click_to_hide, $GTK_FALSE, $GTK_FALSE, 1);
  $control->pack_end($toggle, $GTK_FALSE, $GTK_FALSE, 1) if ($can_toggle);;

  my $box = Gtk2::VBox->new();
  $box->pack_start($list->widget(), $GTK_TRUE, $GTK_TRUE, 0);
  $box->pack_end($control, $GTK_FALSE, $GTK_FALSE, 0);

  $obj->{ncols} = $#$headers + 1;
  $obj->{headers} = $headers;
  $obj->{hidden} = $hidden;
  $obj->{hash} = $hash;
  $obj->{list} = $list;
  $obj->{hide} = $click_to_hide;
  $obj->{show} = $show;
  $obj->{widget} = $box;

  return $obj;
}

=item $DataViewer = $DataViewer->append($row);

=cut

sub append {
  my $obj = shift;
  my $row = shift;
  $obj->{list}->append($row);
  return $obj;
}

=back

=head3 Class QueryWindow: Window

=over

=cut

package QueryWindow;
our @ISA = qw(Window);

=item $QueryWindow = QueryWindow->new($parent);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $parent = shift;
  my $obj = $class->SUPER::new("IntoDB - Database Queries", $parent);
  bless($obj, $class);

  my $label1 = Gtk2::Label->new("SELECT");
  $label1->set_alignment(1.0, 0.5);
  $label1->set_width_chars(8);
  my $entry1 = Gtk2::Entry->new();
  $entry1->set_width_chars(60);
  $entry1->signal_connect('activate' => sub {
    my $widget = shift;
    my $obj = shift;
    $obj->{execute}->clicked();
  }, $obj);
  my $line1 = Gtk2::HBox->new();
  $line1->pack_start($label1, $GTK_FALSE, $GTK_FALSE, 1);
  $line1->pack_start($entry1, $GTK_TRUE, $GTK_TRUE, 1);

  my $label2 = Gtk2::Label->new("FROM");
  $label2->set_alignment(1.0, 0.5);
  $label2->set_width_chars(8);
  my $entry2 = Gtk2::Entry->new();
  $entry2->set_width_chars(60);
  $entry2->signal_connect('activate' => sub {
    my $widget = shift;
    my $obj = shift;
    $obj->{execute}->clicked();
  }, $obj);
  my $line2 = Gtk2::HBox->new();
  $line2->pack_start($label2, $GTK_FALSE, $GTK_FALSE, 1);
  $line2->pack_start($entry2, $GTK_TRUE, $GTK_TRUE, 1);

  my $label3 = Gtk2::Label->new("WHERE");
  $label3->set_alignment(1.0, 0.5);
  $label3->set_width_chars(8);
  my $entry3 = Gtk2::Entry->new();
  $entry3->set_width_chars(60);
  $entry3->signal_connect('activate' => sub {
    my $widget = shift;
    my $obj = shift;
    $obj->{execute}->clicked();
  }, $obj);
  my $line3 = Gtk2::HBox->new();
  $line3->pack_start($label3, $GTK_FALSE, $GTK_FALSE, 1);
  $line3->pack_start($entry3, $GTK_TRUE, $GTK_TRUE, 1);

  my $label4 = Gtk2::Label->new("");
  $label4->set_alignment(1.0, 0.5);
  $label4->set_width_chars(8);
  my $entry4 = Gtk2::Entry->new();
  $entry4->set_width_chars(60);
  $entry4->signal_connect('activate' => sub {
    my $widget = shift;
    my $obj = shift;
    $obj->{execute}->clicked();
  }, $obj);
  my $line4 = Gtk2::HBox->new();
  $line4->pack_start($label4, $GTK_FALSE, $GTK_FALSE, 1);
  $line4->pack_start($entry4, $GTK_TRUE, $GTK_TRUE, 1);

  my $label5 = Gtk2::Label->new("");
  $label5->set_alignment(1.0, 0.5);
  $label5->set_width_chars(8);
  my $entry5 = Gtk2::Entry->new();
  $entry5->set_width_chars(60);
  $entry5->signal_connect('activate' => sub {
    my $widget = shift;
    my $obj = shift;
    $obj->{execute}->clicked();
  }, $obj);
  my $line5 = Gtk2::HBox->new();
  $line5->pack_start($label5, $GTK_FALSE, $GTK_FALSE, 1);
  $line5->pack_start($entry5, $GTK_TRUE, $GTK_TRUE, 1);

  my $label6 = Gtk2::Label->new("");
  $label6->set_alignment(1.0, 0.5);
  $label6->set_width_chars(8);
  my $entry6 = Gtk2::Entry->new();
  $entry6->set_width_chars(60);
  $entry6->signal_connect('activate' => sub {
    my $widget = shift;
    my $obj = shift;
    $obj->{execute}->clicked();
  }, $obj);
  my $line6 = Gtk2::HBox->new();
  $line6->pack_start($label6, $GTK_FALSE, $GTK_FALSE, 1);
  $line6->pack_start($entry6, $GTK_TRUE, $GTK_TRUE, 1);

  my $execute = Gtk2::Button->new("execute");
  $execute->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    
    $widget->set_sensitive($GTK_FALSE);
    Gtk2->main_iteration() while (Gtk2->events_pending());

    my $cols = $obj->{entry1}->get_text();
    $cols = "*" if ($cols =~ /^\s*$/);
    $cols = "DISTINCT *" if ($cols =~ /^\s*DISTINCT\s*$/i);
    $cols = "ALL *" if ($cols =~ /^\s*ALL\s*$/i);
    $cols = "COUNT(*)" if ($cols =~ /^\s*COUNT\s*$/i);
    $cols = "DISTINCT COUNT(*)" if ($cols =~ /^\s*DISTINCT\s+COUNT\s*$/i);
    $cols = "DISTINCT COUNT(*)" if ($cols =~ /^\s*COUNT\s+DISTINCT\s*$/i);
    my $tables = $obj->{entry2}->get_text();
    my $where = $obj->{entry3}->get_text();
    my $sqlstr = join(" ", "SELECT", $cols, "FROM", $tables);
    $sqlstr .= " WHERE $where" if ($where =~ /\S/);
    $sqlstr .= sprintf " %s", $obj->{entry4}->get_text();
    $sqlstr .= sprintf " %s", $obj->{entry5}->get_text();
    $sqlstr .= sprintf " %s", $obj->{entry6}->get_text();

    my %vhash;
    my @views = ($sqlstr =~ /\b\w[\w_]*_VIEW\b/ig);
    eval {
      foreach my $v (@views) {
        my $b = uc($v); $b =~ s/_VIEW$//;
        if (!exists $vhash{$b}) {
          my $bench = Benchmark->get($DBH, $b);
          $vhash{$b} = $bench->view->create();
        }
      }
    };
    if ($@) {
      ErrorWindow->new($@)->run();
      $widget->set_sensitive($GTK_TRUE);
      return;
    }

    my $data = undef;
    eval {
      my $sth = $DBH->do($sqlstr);
      my $row = $sth->fetchrow_hashref();
      if (!defined $row) {
        $data = Gtk2::Label->new("no data selected");
      } else {
        my @keys = sort keys %$row;
        my $viewer = DataViewer->new(["#", @keys]);

        my $num = 1;
        while (defined $row) {
          my @data = ();
          for (my $i = 0; $i <= $#keys; $i += 1) {
            push(@data, $row->{$keys[$i]});
          }
          $viewer->append([$num, @data]);
          $num += 1;
          $row = $sth->fetchrow_hashref();
        }
        $data = $viewer->widget();
      }
    };
    $widget->set_sensitive($GTK_TRUE);
    if ($@) {
      ErrorWindow->new($@)->run();
    } else {
      if (defined $data) {
        $obj->{results}->remove($obj->{data}) if (defined($obj->{data}));
        $obj->{results}->add($data);
        $obj->{data} = $data;
        $obj->show();
      }
    }
  }, $obj);

  my $results = Gtk2::Frame->new("Results");
  $results->set_shadow_type('etched-out');

  my $box = Gtk2::VBox->new();
  $box->pack_start($line1, $GTK_FALSE, $GTK_FALSE, 0);
  $box->pack_start($line2, $GTK_FALSE, $GTK_FALSE, 0);
  $box->pack_start($line3, $GTK_FALSE, $GTK_FALSE, 0);
  $box->pack_start($line4, $GTK_FALSE, $GTK_FALSE, 0);
  $box->pack_start($line5, $GTK_FALSE, $GTK_FALSE, 0);
  $box->pack_start($line6, $GTK_FALSE, $GTK_FALSE, 0);
  $box->pack_start($execute, $GTK_FALSE, $GTK_FALSE, 0);
  $box->pack_start($results, $GTK_TRUE, $GTK_TRUE, 0);

  $obj->{entry1} = $entry1;
  $obj->{entry2} = $entry2;
  $obj->{entry3} = $entry3;
  $obj->{entry4} = $entry4;
  $obj->{entry5} = $entry5;
  $obj->{entry6} = $entry6;
  $obj->{execute} = $execute;
  $obj->{results} = $results;
  $obj->{data} = undef;

  $obj->addContent($box);

  $obj->refresh();

  return $obj;
}

=item $QueryWindow->destroy();

=cut

sub destroy {
  my $obj = shift;
  my $id = $obj->id();
  my $main = $obj->parent();
  delete $main->{querywin}->{$id} if (exists $main->{querywin}->{$id});
  $obj->SUPER::destroy();
  return $obj;
}

=item $QueryWindow = $QueryWindow->refresh();

=cut

sub refresh {
  my $obj = shift;
  if (!defined $DBH) {
    $obj->{execute}->set_sensitive($GTK_FALSE);
  } else {
    $obj->{execute}->set_sensitive($GTK_TRUE);
  }
  return $obj;
}

=back

=head3 Class GraphHandler: IntoDBWidget

=over

=cut

package GraphHandler;
our @ISA = qw(IntoDBWidget);

=item $GraphHandler = GraphHandler->new();

events: C<changed>

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new();
  bless($obj, $class);

  my $label1 = Gtk2::Label->new("file:");
  my $entry = Gtk2::Entry->new();
  $entry->set_editable($GTK_TRUE);
  $entry->signal_connect('changed' => sub {
    my $widget = shift;
    my $obj = shift;
    my $text = $widget->get_text();
    my $style = $widget->get_default_style();
    my $editor = TextEditor->selected();
    if (-f $text) {
      $widget->modify_text('normal', $style->fg('normal'));
      $obj->{b_edit}->set_sensitive((defined $editor)? $GTK_TRUE:
                                                       $GTK_FALSE);
      $obj->{b_create}->set_sensitive($GTK_FALSE);
    } else {
      $widget->modify_text('normal', Gtk2::Gdk::Color->parse("red"));
      $obj->{b_edit}->set_sensitive($GTK_FALSE);
      if ($text =~ /\S/ && !-e $text) {
        $obj->{b_create}->set_sensitive($GTK_TRUE);
      } else {
        $obj->{b_create}->set_sensitive($GTK_FALSE);
      }
    }
    $obj->signalEvent('changed');
  }, $obj);
  my $browse = Gtk2::Button->new("browse");
  $browse->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $filechooser = FileWindow->new("IntoDB - Select Graph Description File");
    my $file = $filechooser->run();
    if (defined $file) {
      $entry = $obj->{entry};
      $entry->set_text($file);
    }
  }, $obj);
  my $edit = Gtk2::Button->new("edit");
  $edit->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $editor = TextEditor->selected();
    my $filename = $obj->{entry}->get_text();
    if (defined $editor && -f $filename) {
      if (!defined ($editor->launch($filename))) {
        ErrorWindow->new("could not launch editor for \"$filename\"")->run();
      }
    }
  }, $obj);
  my $create = Gtk2::Button->new("create");
  $create->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $filename = $obj->{entry}->get_text();
    my $style = $obj->{entry}->get_default_style();
    if (!-e $filename) {
      my $FH;
      if (!open($FH, ">$filename")) {
        ErrorWindow->new("could not create \"$filename\"")->run();
      } else {
        close($FH);
      }
      my $editor = TextEditor->selected();
      if (-f $filename) {
        $obj->{entry}->modify_text('normal', $style->fg('normal'));
        $obj->{b_edit}->set_sensitive((defined $editor)? $GTK_TRUE:
                                                         $GTK_FALSE);
        $obj->{b_create}->set_sensitive($GTK_FALSE);
      } else {
        $obj->{entry}->modify_text('normal', Gtk2::Gdk::Color->parse("red"));
        $obj->{b_edit}->set_sensitive($GTK_FALSE);
        if ($filename =~ /\S/ && !-e $filename) {
          $obj->{b_create}->set_sensitive($GTK_TRUE);
        } else {
          $obj->{b_create}->set_sensitive($GTK_FALSE);
        }
      }
    }
    $obj->signalEvent('changed');
  }, $obj);


  my $box1 = Gtk2::HBox->new();
  $box1->pack_start($label1, $GTK_FALSE, $GTK_FALSE, 1);
  $box1->pack_start($entry, $GTK_TRUE, $GTK_TRUE, 1);
  $box1->pack_end($create, $GTK_FALSE, $GTK_FALSE, 1);
  $box1->pack_end($edit, $GTK_FALSE, $GTK_FALSE, 1);
  $box1->pack_end($browse, $GTK_FALSE, $GTK_FALSE, 1);

  my $box2 = Gtk2::HBox->new();

  my $box = Gtk2::VBox->new();
  $box->pack_start($box1, $GTK_TRUE, $GTK_TRUE, 0);
  $box->pack_start($box2, $GTK_FALSE, $GTK_FALSE, 0);

  my $frame = Gtk2::Frame->new("Graph Description File");
  $frame->set_shadow_type('etched-out');
  $frame->add($box);

  $obj->{entry} = $entry;
  $obj->{widget} = $frame;
  $obj->{b_edit} = $edit;
  $obj->{b_create} = $create;

  $obj->refresh();

  return $obj;
}

=item $string = GraphHandler->getFilename();

=cut

sub getFilename {
  my $obj = shift;
  my $filename = $obj->{entry}->get_text();
  return undef if (! -f $filename);
  return $filename;
}

=item $GraphHandler = $GraphHandler->refresh();

=cut

sub refresh {
  my $obj = shift;
  my $filename = $obj->{entry}->get_text();
  if (-f $filename) {
    my $editor = TextEditor->selected();
    my $style = $obj->{entry}->get_default_style();
    $obj->{entry}->modify_text('normal', $style->fg('normal'));
    $obj->{b_edit}->set_sensitive((defined $editor)?$GTK_TRUE:$GTK_FALSE);
    $obj->{b_create}->set_sensitive($GTK_FALSE);
  } else {
    $obj->{entry}->modify_text('normal', Gtk2::Gdk::Color->parse("red"));
    $obj->{b_edit}->set_sensitive($GTK_FALSE);
    if ($filename =~ /\S/ && !-e $filename) {
      $obj->{b_create}->set_sensitive($GTK_TRUE);
    } else {
      $obj->{b_create}->set_sensitive($GTK_FALSE);
    }
  }
  return $obj;
}

=back

=head3 Class GraphWindow: Window

=over

=cut

package GraphWindow;
our @ISA = qw(Window);

=item $GraphWindow = GraphWindow->new($parent);

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $parent = shift;
  my $obj = $class->SUPER::new("IntoDB - Graph Generation", $parent);
  bless($obj, $class);

  my $handler = GraphHandler->new();
  $handler->setCallback('changed', Callback->new(sub {
    my $obj = shift;
    my $wdg = shift;
    if (defined($obj->{graphhandler}->getFilename())) {
      $obj->{b_save_jgr}->set_sensitive($GTK_TRUE);
      my $jgraph = Jgraph->selected();
      my $psviewer = PsViewer->selected();
      my $editor = TextEditor->selected();
      if (defined $editor) {
        $obj->{b_view_jgr}->set_sensitive($GTK_TRUE);
      } else {
        $obj->{b_view_jgr}->set_sensitive($GTK_FALSE);
      }
      if (defined $jgraph) {
        $obj->{b_save_ps}->set_sensitive($GTK_TRUE);
        $obj->{b_save_eps}->set_sensitive($GTK_TRUE);
        if (defined $psviewer) {
          $obj->{b_view_ps}->set_sensitive($GTK_TRUE);
          $obj->{b_view_eps}->set_sensitive($GTK_TRUE);
        } else {
          $obj->{b_view_ps}->set_sensitive($GTK_FALSE);
          $obj->{b_view_eps}->set_sensitive($GTK_FALSE);
        }
      } else {
        $obj->{b_save_ps}->set_sensitive($GTK_FALSE);
        $obj->{b_save_eps}->set_sensitive($GTK_FALSE);
        $obj->{b_view_ps}->set_sensitive($GTK_FALSE);
        $obj->{b_view_eps}->set_sensitive($GTK_FALSE);
      }
    } else {
      $obj->{b_save_jgr}->set_sensitive($GTK_FALSE);
      $obj->{b_save_ps}->set_sensitive($GTK_FALSE);
      $obj->{b_save_eps}->set_sensitive($GTK_FALSE);
      $obj->{b_view_ps}->set_sensitive($GTK_FALSE);
      $obj->{b_view_eps}->set_sensitive($GTK_FALSE);
      $obj->{b_view_jgr}->set_sensitive($GTK_FALSE);
    }
  }, $obj));

  my $clist = ChoiceList->new();
  $clist->setReorderable($TRUE);
  $clist->setHeadersVisible($TRUE);
  $clist->setHeader(0, "variable");
  $clist->setHeader(1, "value");

  my $nlist = List->new(2);
  $nlist->setReorderable($TRUE);
  $nlist->setHeadersVisible($TRUE);
  $nlist->setHeader(0, "variable");
  $nlist->setHeader(1, "value");

  my $use_choicelist = 1;
  my $list = ($use_choicelist)? $clist: $nlist;
  my $listbox = Gtk2::HBox->new();
  $listbox->pack_start($list->widget(), $GTK_TRUE, $GTK_TRUE, 0);

  my $label1 = Gtk2::Label->new("variable:");
  $label1->set_alignment(1.0, 0.5);
  $label1->set_width_chars(10);
  my $variable = Gtk2::Entry->new();
  $variable->signal_connect('changed' => sub {
    my $widget = shift;
    my $obj = shift;
    my $text = $widget->get_text();
    my $style = $widget->get_default_style();
    if ($text =~ /^\s*[\w_]+\s*$/) {
      $widget->modify_text('normal', $style->fg('normal'));
      $obj->{b_new}->set_sensitive($GTK_TRUE);
    } else {
      $widget->modify_text('normal', Gtk2::Gdk::Color->parse("red"));
      $obj->{b_new}->set_sensitive($GTK_FALSE);
    }
  }, $obj);
  $variable->signal_connect('activate' => sub {
    my $widget = shift;
    my $obj = shift;
    my $var = $obj->{variable}->get_text();
    $var =~ s/^\s+//;
    $var =~ s/\s+$//;
    if ($var =~ /^[\w_]+$/) {
      my $val = $obj->{value}->get_text();
      $val =~ s/^\s+//;
      $val =~ s/\s+$//;
      my $entry = [$var, $val];
      $obj->{list}->append($entry);
    }
  }, $obj);

  my $label2 = Gtk2::Label->new("value:");
  $label2->set_alignment(1.0, 0.5);
  $label2->set_width_chars(10);
  my $value = Gtk2::Entry->new();
  $value->signal_connect('activate' => sub {
    my $widget = shift;
    my $obj = shift;
    my $var = $obj->{variable}->get_text();
    $var =~ s/^\s+//;
    $var =~ s/\s+$//;
    if ($var =~ /^[\w_]+$/) {
      my $val = $obj->{value}->get_text();
      $val =~ s/^\s+//;
      $val =~ s/\s+$//;
      my $entry = [$var, $val];
      $obj->{list}->append($entry);
    }
  }, $obj);

  my $new = Gtk2::Button->new("add");
  $new->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $var = $obj->{variable}->get_text();
    $var =~ s/^\s+//;
    $var =~ s/\s+$//;
    if ($var =~ /^[\w_]+$/) {
      my $val = $obj->{value}->get_text();
      $val =~ s/^\s+//;
      $val =~ s/\s+$//;
      my $entry = [$var, $val];
      $obj->{list}->append($entry);
    }
  }, $obj);

  my $copy = Gtk2::Button->new("copy");
  $copy->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $field = $obj->{list}->get();
    if (defined $field) {
      $obj->{variable}->set_text($field->[0]);
      $obj->{value}->set_text($field->[1]);
    }
  }, $obj);

  my $remove = Gtk2::Button->new("remove");
  $remove->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    if (defined ($obj->{list}->get())) {
      $obj->{list}->remove();
    }
  }, $obj);

  my $remove_all = Gtk2::Button->new("remove all");
  $remove_all->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    $obj->{list}->removeAll();
  }, $obj);

  my $save_param = Gtk2::Button->new("save to file");
  $save_param->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $filename = $obj->{graphhandler}->getFilename();
    my $suggest = $filename;
       $suggest = "parameters.cfg" if (!defined $suggest);
       $suggest =~ s/.*\///;
       $suggest =~ s/\.[^\.]*//; $suggest .= ".cfg";
    my $win = FileWindow->new("IntoDB - Save Parameter Configuration File");
       $win->setActionSave();
       $win->setFilename($suggest);
    my $save = $win->run();
    if (defined $save) {
      my $doit = "ok";
      if (-e $save) {
        $doit = ConfirmWindow->new("overwrite \"$save\"?")->run();
      }
      if ($doit eq "ok") {
        eval {
          open(CFG, ">$save") || die "cannot write to \"$save\"\n";
          foreach my $v ($obj->{list}->getAllRows()) {
            printf CFG "%s = %s\n", $v->[0], $v->[1];
          }
          close(CFG);
        };
        if ($@) {
          ErrorWindow->new($@)->run();
        }
      }
    }
  }, $obj);

  my $load_param = Gtk2::Button->new("load from file");
  $load_param->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $win = FileWindow->new("IntoDB - Load Parameter Configuration File");
    my $load = $win->run();
    if (defined $load) {
      eval {
        my $input = IncludeFile->new($load);
        my $params = ParamFile->new($input);
        $obj->{list}->removeAll();
        my $p = $params->getData();
        while (defined $p) {
          $obj->{list}->append($p);
          $p = $params->getData();
        }
      };
      if ($@) {
        ErrorWindow->new($@)->run();
      }
    }
  }, $obj);

  my $append_param = Gtk2::Button->new("append from file");
  $append_param->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $win = FileWindow->new("IntoDB - Append Parameter Configuration File");
    my $load = $win->run();
    if (defined $load) {
      eval {
        my $input = IncludeFile->new($load);
        my $params = ParamFile->new($input);
        my $p = $params->getData();
        while (defined $p) {
          $obj->{list}->append($p);
          $p = $params->getData();
        }
      };
      if ($@) {
        ErrorWindow->new($@)->run();
      }
    }
  }, $obj);

  my $expand_param = Gtk2::CheckButton->new_with_label("expand values");
  $expand_param->set_active($GTK_FALSE);
  $expand_param->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;

    my @list = $obj->{list}->getAllRows();
    $obj->{list}->removeAll();
    $obj->{listbox}->remove($obj->{list}->widget());

    if ($widget->get_active()) {
      $obj->{use_choicelist} = 0;
      $obj->{list} = $obj->{nlist};
    } else {
      $obj->{use_choicelist} = 1;
      $obj->{list} = $obj->{clist};
    }

    $obj->{listbox}->pack_start($obj->{list}->widget(), $GTK_TRUE,$GTK_TRUE,0);
    foreach my $d (@list) {
      $obj->{list}->append($d);
    }
    $obj->{listbox}->show_all();
  }, $obj);

  my $view_jgr = Gtk2::Button->new("view jgr");
  $view_jgr->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $editor = TextEditor->selected();
    my $filename = $obj->{graphhandler}->getFilename();
    if (defined($filename) && defined($editor)) {
      my $jgrfile = IntoDB::getTmpFile("jgr");
      my $Override = {};
      foreach my $v ($obj->{list}->getAllSettings()) {
        $Override->{$v->[0]} = $v->[1];
      }
      eval {
        if (!open(JGR, ">$jgrfile")) {
          die "cannot create \"$jgrfile\"\n";
        }
        my $input = IncludeFile->new($filename);
        my $gfile = GraphFile->new($input);
        my @glist = $gfile->parse();
        my $idx = 0;
        foreach my $g (@glist) {
          $g->verify();
          $g->calculate($Override);
          print JGR $g->jgraph($idx, $Override);
          $idx += 1 unless $g->skipped();
        }
        close(JGR);
      };
      if ($@) {
        ErrorWindow->new($@)->run();
        unlink $jgrfile;
      } else {
        #my $child = $psviewer->launchMonitored(sub {
        #  my ($pid, $exit, $param, $file) = @_; sleep 10; unlink $file;
        #}, undef, $psfile);
        #if (!defined $child) {
        #  ErrorWindow->new("could not launch ps viewer for \"$psfile\"");
        #}
        $TMPFILE{$jgrfile} = 1;
        if (!defined($editor->launch($jgrfile))) {
          ErrorWindow->new("could not launch editor for \"$jgrfile\"");
          unlink $jgrfile;
          delete $TMPFILE{$jgrfile};
        } else {
          #sleep 2; unlink $psfile; # ugly... 
        }
      }
    }
  }, $obj);

  my $view_ps = Gtk2::Button->new("view ps");
  $view_ps->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $jgraph = Jgraph->selected();
    my $psviewer = PsViewer->selected();
    my $filename = $obj->{graphhandler}->getFilename();
    if (defined($filename) && defined($jgraph) && defined($psviewer)) {
      my $psfile = IntoDB::getTmpFile("ps");
      my $Override = {};
      foreach my $v ($obj->{list}->getAllSettings()) {
        $Override->{$v->[0]} = $v->[1];
      }
      eval {
        my $cmd = sprintf "%s -P > %s", $jgraph->path(), $psfile;
        if (!open(JGR, "|$cmd")) {
          die "cannot execute \"$cmd\"\n";
        }
        my $input = IncludeFile->new($filename);
        my $gfile = GraphFile->new($input);
        my @glist = $gfile->parse();
        my $idx = 0;
        foreach my $g (@glist) {
          $g->verify();
          $g->calculate($Override);
          print JGR $g->jgraph($idx, $Override);
          $idx += 1 unless $g->skipped();
        }
        close(JGR);
      };
      if ($@) {
        ErrorWindow->new($@)->run();
        unlink $psfile;
      } else {
        #my $child = $psviewer->launchMonitored(sub {
        #  my ($pid, $exit, $param, $file) = @_; sleep 10; unlink $file;
        #}, undef, $psfile);
        #if (!defined $child) {
        #  ErrorWindow->new("could not launch ps viewer for \"$psfile\"");
        #}
        $TMPFILE{$psfile} = 1;
        if (!defined($psviewer->launch($psfile))) {
          ErrorWindow->new("could not launch ps viewer for \"$psfile\"");
          unlink $psfile;
          delete $TMPFILE{$psfile};
        } else {
          #sleep 2; unlink $psfile; # ugly... 
        }
      }
    }
  }, $obj);

  my $view_eps = Gtk2::Button->new("view eps");
  $view_eps->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $jgraph = Jgraph->selected();
    my $psviewer = PsViewer->selected();
    my $filename = $obj->{graphhandler}->getFilename();
    if (defined($filename) && defined($jgraph) && defined($psviewer)) {
      my $psfile = IntoDB::getTmpFile("ps");
      my $Override = {};
      foreach my $v ($obj->{list}->getAllSettings()) {
        $Override->{$v->[0]} = $v->[1];
      }
      eval {
        my $cmd = sprintf "%s > %s", $jgraph->path(), $psfile;
        if (!open(JGR, "|$cmd")) {
          die "cannot execute \"$cmd\"\n";
        }
        my $input = IncludeFile->new($filename);
        my $gfile = GraphFile->new($input);
        my @glist = $gfile->parse();
        my $idx = 0;
        foreach my $g (@glist) {
          $g->verify();
          $g->calculate($Override);
          print JGR $g->jgraph($idx, $Override);
          $idx += 1 unless $g->skipped();
        }
        close(JGR);
      };
      if ($@) {
        ErrorWindow->new($@)->run();
        unlink $psfile;
      } else {
        #my $child = $psviewer->launchMonitored(sub {
        #  my ($pid, $exit, $param, $file) = @_; sleep 10; unlink $file;
        #}, undef, $psfile);
        #if (!defined $child) {
        #  ErrorWindow->new("could not launch ps viewer for \"$psfile\"");
        #}
        $TMPFILE{$psfile} = 1;
        if (!defined($psviewer->launch($psfile))) {
          ErrorWindow->new("could not launch ps viewer for \"$psfile\"");
          unlink $psfile;
          delete $TMPFILE{$psfile};
        } else {
          #sleep 2; unlink $psfile; # ugly... 
        }
      }
    }
  }, $obj);

  my $save_ps = Gtk2::Button->new("save ps");
  $save_ps->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $jgraph = Jgraph->selected();
    my $filename = $obj->{graphhandler}->getFilename();
    if (defined($filename) && defined($jgraph)) {
      my $suggest = $filename;
         $suggest =~ s/.*\///;
         $suggest =~ s/\.[^\.]*//; $suggest .= ".ps";
      my $win = FileWindow->new("IntoDB - Save Postscript File");
         $win->setActionSave();
         $win->setFilename($suggest);
      my $save = $win->run();
      if (defined $save) {
        my $doit = "ok";
        if (-e $save) {
          $doit = ConfirmWindow->new("overwrite \"$save\"?")->run();
        }
        if ($doit eq "ok") {
          my $Override = {};
          foreach my $v ($obj->{list}->getAllSettings()) {
            $Override->{$v->[0]} = $v->[1];
          }
          eval {
            my $cmd = sprintf "%s -P > %s", $jgraph->path(), $save;
            if (!open(JGR, "| $cmd")) {
              die "cannot execute  \"$cmd\"\n";
            }
            my $input = IncludeFile->new($filename);
            my $gfile = GraphFile->new($input);
            my @glist = $gfile->parse();
            my $idx = 0;
            foreach my $g (@glist) {
              $g->verify();
              $g->calculate($Override);
              print JGR $g->jgraph($idx, $Override);
              $idx += 1 unless $g->skipped();
            }
            close(JGR);
          };
          if ($@) {
            ErrorWindow->new($@)->run();
          }
        }
      }
    }
  }, $obj);

  my $save_eps = Gtk2::Button->new("save eps");
  $save_eps->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $jgraph = Jgraph->selected();
    my $filename = $obj->{graphhandler}->getFilename();
    if (defined($filename) && defined($jgraph)) {
      my $suggest = $filename;
         $suggest =~ s/.*\///;
         $suggest =~ s/\.[^\.]*//; $suggest .= ".eps";
      my $win = FileWindow->new("IntoDB - Save Encapsulated Postscript File");
         $win->setActionSave();
         $win->setFilename($suggest);
      my $save = $win->run();
      if (defined $save) {
        my $doit = "ok";
        if (-e $save) {
          $doit = ConfirmWindow->new("overwrite \"$save\"?")->run();
        }
        if ($doit eq "ok") {
          my $Override = {};
          foreach my $v ($obj->{list}->getAllSettings()) {
            $Override->{$v->[0]} = $v->[1];
          }
          eval {
            my $cmd = sprintf "%s > %s", $jgraph->path(), $save;
            if (!open(JGR, "| $cmd")) {
              die "cannot execute  \"$cmd\"\n";
            }
            my $input = IncludeFile->new($filename);
            my $gfile = GraphFile->new($input);
            my @glist = $gfile->parse();
            my $idx = 0;
            foreach my $g (@glist) {
              $g->verify();
              $g->calculate($Override);
              print JGR $g->jgraph($idx, $Override);
              $idx += 1 unless $g->skipped();
            }
            close(JGR);
          };
          if ($@) {
            ErrorWindow->new($@)->run();
          }
        }
      }
    }
  }, $obj);

  my $save_jgr = Gtk2::Button->new("save jgr");
  $save_jgr->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $filename = $obj->{graphhandler}->getFilename();
    if (defined($filename)) {
      my $suggest = $filename;
         $suggest =~ s/.*\///;
         $suggest =~ s/\.[^\.]*//; $suggest .= ".jgr";
      my $win = FileWindow->new("IntoDB - Save Jgraph File");
         $win->setActionSave();
         $win->setFilename($suggest);
      my $save = $win->run();
      if (defined $save) {
        my $doit = "ok";
        if (-e $save) {
          $doit = ConfirmWindow->new("overwrite \"$save\"?")->run();
        }
        if ($doit eq "ok") {
          my $Override = {};
          foreach my $v ($obj->{list}->getAllSettings()) {
            $Override->{$v->[0]} = $v->[1];
          }
          eval {
            if (!open(JGR, ">$save")) {
              die "cannot open \"$save\"\n";
            }
            my $input = IncludeFile->new($filename);
            my $gfile = GraphFile->new($input);
            my @glist = $gfile->parse();
            my $idx = 0;
            foreach my $g (@glist) {
              $g->verify();
              $g->calculate($Override);
              print JGR $g->jgraph($idx, $Override);
              $idx += 1 unless $g->skipped();
            }
            close(JGR);
          };
          if ($@) {
            ErrorWindow->new($@)->run();
          }
        }
      }
    }
  }, $obj);

  my $box1 = Gtk2::HBox->new();
  $box1->pack_start($label1, $GTK_FALSE, $GTK_FALSE, 1);
  $box1->pack_start($variable, $GTK_TRUE, $GTK_TRUE, 1);

  my $box2 = Gtk2::HBox->new();
  $box2->pack_start($label2, $GTK_FALSE, $GTK_FALSE, 1);
  $box2->pack_start($value, $GTK_TRUE, $GTK_TRUE, 1);

  my $box3 = Gtk2::VBox->new();
  $box3->pack_start($box1, $GTK_TRUE, $GTK_TRUE, 0);
  $box3->pack_start($box2, $GTK_TRUE, $GTK_TRUE, 0);

  my $box4 = Gtk2::HBox->new();
  $box4->pack_start($box3, $GTK_TRUE, $GTK_TRUE, 0);
  $box4->pack_start($new, $GTK_FALSE, $GTK_FALSE, 0);

  my $box5 = Gtk2::VBox->new();
  $box5->pack_start($copy, $GTK_FALSE, $GTK_FALSE, 0);
  $box5->pack_start($remove, $GTK_FALSE, $GTK_FALSE, 0);
  $box5->pack_start($remove_all, $GTK_FALSE, $GTK_FALSE, 0);
  $box5->pack_start($save_param, $GTK_FALSE, $GTK_FALSE, 0);
  $box5->pack_start($load_param, $GTK_FALSE, $GTK_FALSE, 0);
  $box5->pack_start($append_param, $GTK_FALSE, $GTK_FALSE, 0);
  $box5->pack_start($expand_param, $GTK_FALSE, $GTK_FALSE, 0);

  my $box6 = Gtk2::VBox->new();
  #$box6->pack_start($list->widget(), $GTK_TRUE, $GTK_TRUE, 0);
  $box6->pack_start($listbox, $GTK_TRUE, $GTK_TRUE, 0);
  $box6->pack_start($box4, $GTK_FALSE, $GTK_FALSE, 0);

  my $box7 = Gtk2::HBox->new();
  $box7->pack_start($box6, $GTK_TRUE, $GTK_TRUE, 0);
  $box7->pack_start($box5, $GTK_FALSE, $GTK_FALSE, 0);

  my $params = Gtk2::Frame->new("Variables");
  $params->set_shadow_type('etched-out');
  $params->add($box7);

  my $view_buttons = Gtk2::HBox->new();
  $view_buttons->add($view_ps);
  $view_buttons->add($view_eps);
  $view_buttons->add($view_jgr);

  my $save_buttons = Gtk2::HBox->new();
  $save_buttons->add($save_ps);
  $save_buttons->add($save_eps);
  $save_buttons->add($save_jgr);

  my $box = Gtk2::VBox->new();
  $box->pack_start($handler->widget(), $GTK_FALSE, $GTK_FALSE, 0);
  $box->pack_start($params, $GTK_TRUE, $GTK_TRUE, 0);
  $box->pack_start($view_buttons, $GTK_FALSE, $GTK_FALSE, 0);
  $box->pack_start($save_buttons, $GTK_FALSE, $GTK_FALSE, 0);

  $obj->{use_choicelist} = $use_choicelist;
  $obj->{data} = undef;
  $obj->{graphhandler} = $handler;
  $obj->{variable} = $variable;
  $obj->{value} = $value;
  $obj->{list} = $list;
  $obj->{clist} = $clist;
  $obj->{nlist} = $nlist;
  $obj->{listbox} = $listbox;
  $obj->{b_new} = $new;
  $obj->{b_view_ps} = $view_ps;
  $obj->{b_view_eps} = $view_eps;
  $obj->{b_view_jgr} = $view_jgr;
  $obj->{b_save_ps} = $save_ps;
  $obj->{b_save_eps} = $save_eps;
  $obj->{b_save_jgr} = $save_jgr;

  $obj->addContent($box);

  $obj->refresh();

  return $obj;
}

=item $QueryWindow->destroy();

=cut

sub destroy {
  my $obj = shift;
  my $id = $obj->id();
  my $main = $obj->parent();
  delete $main->{graphwin}->{$id} if (exists $main->{graphwin}->{$id});
  $obj->SUPER::destroy();
  return $obj;
}

=item $QueryWindow = $QueryWindow->refresh();

=cut

sub refresh {
  my $obj = shift;
  my $filename = $obj->{graphhandler}->getFilename();
  if (defined $filename) {
    $obj->{b_save_jgr}->set_sensitive($GTK_TRUE);
    if (defined TextEditor->selected()) {
      $obj->{b_view_jgr}->set_sensitive($GTK_TRUE);
    } else {
      $obj->{b_view_jgr}->set_sensitive($GTK_FALSE);
    }
    if (defined Jgraph->selected()) {
      $obj->{b_save_ps}->set_sensitive($GTK_TRUE);
      $obj->{b_save_eps}->set_sensitive($GTK_TRUE);
      if (defined PsViewer->selected()) {
        $obj->{b_view_ps}->set_sensitive($GTK_TRUE);
        $obj->{b_view_eps}->set_sensitive($GTK_TRUE);
      } else {
        $obj->{b_view_ps}->set_sensitive($GTK_FALSE);
        $obj->{b_view_eps}->set_sensitive($GTK_FALSE);
      }
    } else {
      $obj->{b_save_ps}->set_sensitive($GTK_FALSE);
      $obj->{b_save_eps}->set_sensitive($GTK_FALSE);
      $obj->{b_view_ps}->set_sensitive($GTK_FALSE);
      $obj->{b_view_eps}->set_sensitive($GTK_FALSE);
    }
  } else {
    $obj->{b_save_jgr}->set_sensitive($GTK_FALSE);
    $obj->{b_save_ps}->set_sensitive($GTK_FALSE);
    $obj->{b_save_eps}->set_sensitive($GTK_FALSE);
    $obj->{b_view_ps}->set_sensitive($GTK_FALSE);
    $obj->{b_view_eps}->set_sensitive($GTK_FALSE);
    $obj->{b_view_jgr}->set_sensitive($GTK_FALSE);
  }
  my $var = $obj->{variable}->get_text();
  $var =~ s/^\s+//;
  $var =~ s/\s+$//;
  if ($var =~ /^[\w_]+$/) {
    $obj->{b_new}->set_sensitive($GTK_TRUE);
  } else {
    $obj->{b_new}->set_sensitive($GTK_FALSE);
  }
  return $obj;
}

=back

=head3 Class IntoDBGui: MainWindow

=over

=cut

package IntoDBGui;
our @ISA = qw(MainWindow);

=item $IntoDBGui = IntoDBGui->new();

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $obj = $class->SUPER::new("IntoDB");
  bless($obj, $class);

  my $connector = DBConnector->new();
  $connector->setCallback('changed', Callback->new(sub {
    my $obj = shift;
    my $wdg = shift;
    my @bwins = keys %{$obj->{benchwin}};
    foreach my $k (@bwins) {
      $obj->{benchwin}->{$k}->destroy();
      delete $obj->{benchwin}->{$k};
    }
    my @qwins = keys %{$obj->{querywin}};
    foreach my $k (@qwins) {
      $obj->{querywin}->{$k}->refresh();
    }
    $obj->{benchlist}->refresh();
  }, $obj));

  my $benchlist = BenchmarkList->new();
  $benchlist->setCallback('remove', Callback->new(sub {
    my $obj = shift;
    my $wdg = shift;
    my $id = shift;
    if (exists $obj->{benchwin}->{$id}) {
      $obj->{benchwin}->{$id}->destroy();
      delete $obj->{benchwin}->{$id};
    }
  }, $obj));
  $benchlist->setCallback('edit', Callback->new(sub {
    my $obj = shift;
    my $wdg = shift;
    my $bench = shift;
    my $id = $bench->id();
    if (exists $obj->{benchwin}->{$id}) {
      $obj->{benchwin}->{$id}->show();
    } else {
      $obj->{benchwin}->{$id} = BenchmarkWindow->new($bench, $obj);
      $obj->{benchwin}->{$id}->show();
    }
  }, $obj));

  my $query = Gtk2::Button->new("query database");
  $query->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $win = QueryWindow->new($obj);
    $obj->{querywin}->{$win->id()} = $win;
    $win->show();
  }, $obj);

  my $graph = Gtk2::Button->new("generate graphs");
  $graph->signal_connect('clicked' => sub {
    my $widget = shift;
    my $obj = shift;
    my $win = GraphWindow->new($obj);
    $obj->{graphwin}->{$win->id()} = $win;
    $win->show();
  }, $obj);

  my $main_box = Gtk2::VBox->new();
  $main_box->pack_start($connector->widget(), $GTK_FALSE, $GTK_FALSE, 0);
  $main_box->pack_start($benchlist->widget(), $GTK_TRUE, $GTK_TRUE, 0);

  $obj->addContent($main_box);
  $obj->addButton($query);
  $obj->addButton($graph);

  $obj->{graphwin} = {};
  $obj->{querywin} = {};
  $obj->{benchwin} = {};
  $obj->{connector} = $connector;
  $obj->{benchlist} = $benchlist;

  return $obj;
}

=item $IntoDBGui = $IntoDBGui->run();

=cut

sub run {
  my $obj = shift;
  $obj->show();
  Gtk2->main();
  return $obj;
}

=back

=cut

#################################################
#################################################
# MAIN
#################################################
#################################################

=head2 MAIN

=head3 Class IntoDB

=over

=cut

package IntoDB;
our @ISA = qw();

my %CMDHASH = (
  create => \&run_create,
  list => \&run_list,
  details => \&run_details,
  new => \&run_new,
  rename => \&run_rename,
  description => \&run_description,
  desc => \&run_description,
  create_index => \&run_create_index,
  create_idx => \&run_create_index,
  remove_index => \&run_remove_index,
  remove_idx => \&run_remove_index,
  rm_index => \&run_remove_index,
  rm_idx => \&run_remove_index,
  delete_index => \&run_remove_index,
  delete_idx => \&run_remove_index,
  del_index => \&run_remove_index,
  del_idx => \&run_remove_index,
  remove => \&run_remove,
  rm => \&run_remove,
  delete => \&run_remove,
  del => \&run_remove,
  load_fields => \&run_load_fields,
  new_field => \&run_new_field,
  add_field => \&run_add_field,
  remove_field => \&run_remove_field,
  rm_field => \&run_remove_field,
  delete_field => \&run_remove_field,
  del_field => \&run_remove_field,
  remove_all_fields => \&run_remove_all_fields,
  remove_all_data => \&run_remove_all_data,
  remove_experiment => \&run_remove_experiment,
  remove_exp => \&run_remove_experiment,
  rm_experiment => \&run_remove_experiment,
  rm_exp => \&run_remove_experiment,
  delete_experiment => \&run_remove_experiment,
  delete_exp => \&run_remove_experiment,
  del_experiment => \&run_remove_experiment,
  del_exp => \&run_remove_experiment,
  field_type => \&run_field_type,
  set_key => \&run_set_key,
  set_outlier => \&run_set_outlier,
  sql => \&run_sql,
  admsql => \&run_admsql,
  parse => \&run_parse,
  import => \&run_parse,
  export => \&run_export,
  dump => \&run_dump,
  dump_schema => \&run_dump_schema,
  restore_schema => \&run_restore_schema,
  restore => \&run_restore,
  check_graph => \&run_check_graph,
  graph => \&run_graph,
  xmlplot => \&run_xmlplot,
  data => \&run_data,
  gui => \&run_gui,
  show_config => \&run_show_config,
  commands => \&run_commands,
  man => \&run_man,
  help => \&run_help,
  version => \&run_version,
  license => \&run_license,
);

my %INFOHASH = (
  show_config => 1,
  commands => 1,
  man => 1,
  help => 1,
  version => 1,
  license => 1,
);

my %CMDHLP = (
  create       => "create and format database file\n",
  list         => "list registered benchmarks\n",
  details      => "show benchmark details\n" .
    "                 args: <benchmark_name>\n",
  new          => "register a new benchmark\n" .
    "                 args: <benchmark_name>\n",
  rename       => "rename a benchmark\n" .
    "                 args: <old_name> <new_name>\n",
  description  => "set benchmark description (\"\" clears the description)\n" .
    "                 args: <benchmark_name> <description>\n" .
    "                 alias: desc\n",
  remove       => "unregister a benchmark\n" .
    "                 args: <benchmark_name>\n" .
    "                 alias: rm, delete, del\n",
  create_index => "create index on a set of fields\n" .
    "                 args: <benchmark_name> <field_name ...>\n" .
    "                 alias: create_idx\n",
  remove_index => "removes an index\n" .
    "                 args: <index_name>\n" .
    "                 alias: remove_idx, rm_index, rm_idx\n" .
    "                 delete_index, delete_idx, del_index, del_idx\n",
  load_fields  => "register benchmark fields from a csv file\n" .
    "                 args: <benchmark_name> <csv_file>\n",
  new_field    => "register a benchmark field name\n" .
    "                 args: <benchmark_name> <field_name>\n",
  add_field    => "add a field to a benchmark with data\n" .
  "                 args: <benchmark_name> <field_name> {text|numeric} <val>\n",
  remove_field => "unregister a benchmark field\n" .
    "                 args: <benchmark_name> <field_name>\n" .
    "                 alias: rm_field, delete_field, del_field\n",
  remove_all_fields => "unregister all benchmark fields\n" .
    "                 args: <benchmark_name>\n",
  remove_experiment => "remove selected experiments from a benchmark\n" .
    "                 args: <benchmark_name> <exp_id1> ...\n" .
    "                 args: <benchmark_name> <field_name><op><value> ...\n" .
    "                 where op may be: <=, >=, <, >, =, !=, ~, !~\n" .
    "                 alias: remove_exp, rm_experiment, rm_exp,\n" .
    "                 delete_experiment, delete_exp, del_experiment, del_exp\n",
  remove_all_data => "remove all experiments from a benchmark\n" .
    "                 args: <benchmark_name>\n",
  field_type   => "set the field type (text or numeric)\n" .
    "                 args: <benchmark_name> <field_name> {text|numeric}\n",
  set_key      => "mark a field as key for experiment identifier\n" .
    "                 args: <benchmark_name> <field_name> {true|false}\n",
  set_outlier  => "mark an experiment as an outlier\n" .
    "                 args: <benchmark_name> <exp_id> {true|false}\n",
  sql          => "execute an sql command (select/insert/update/delete)\n" .
    "                 args: <sql_command> <sql_args>\n",
  parse        => "populate the database from a csv file\n" .
    "                 args: <benchmark_name> <csv_file> [extra_data]\n" .
    "                 where extra_data may be:\n" .
    "                   -autoid=<field_name>\n" .
    "                   <field_name>=<value>\n" .
    "                 alias: import\n",
  export       => "export benchmark data as csv\n" .
    "                 args: <benchmark_name>\n",
  dump_schema  => "export the benchmark structure in xml format\n" .
    "                 args: <benchmark_name> (optional)\n",
  restore_schema => "retrieve the benchmark structure from an xml dump\n" .
    "                 args: <file_name>\n",
  dump         => "export the benchmark structure and experiment data in\n" .
    "                 xml format\n" .
    "                 args: <benchmark_name> (optional)\n",
  restore      => "retrieve the benchmark structure and experiment data from\n".
    "                 an xml dump\n" .
    "                 args: <file_name>\n",
  check_graph  => "check syntax of a graph description file\n" .
    "                 args: <graph_file>\n",
  graph        => "process a graph description file and generate jgraph code\n".
    "                 args: <graph_file>\n",
  data         => "process a graph description file and generate raw data\n".
    "                 args: <graph_file>\n",
  xmlplot      => "process a graph description file and generate xml data\n".
    "                 args: <graph_file>\n",
  field_type   => "set the field type (text or numeric)\n" .
    "                 args: <benchmark_name> <field_name> {text|numeric}\n",
  set_key      => "mark a field as key for experiment identifier\n" .
    "                 args: <benchmark_name> <field_name> {true|false}\n",
  set_outlier  => "mark an experiment as an outlier\n" .
    "                 args: <benchmark_name> <exp_id> {true|false}\n",
  sql          => "execute an sql command (select/insert/update/delete)\n" .
    "                 args: <sql_command> <sql_args>\n",
  gui          => "graphic user interface (beta)\n",
  show_config  => "show configuration values\n",
  commands     => "terse list of intodb commands\n",
  man          => "show the man page\n",
  help         => "show usage information\n",
  version      => "show version information\n",
  license      => "show license information\n",
);

=item IntoDB::getTS();

=cut

sub getTS {
  my @time = gmtime(time());
  return sprintf "%04d%02d%02d%02d%02d%02d",
                 $time[5] + 1900, $time[4] + 1, $time[3],
                 $time[2], $time[1], $time[0];
}

=item IntoDB::getID();

=cut

sub getID {
  return sprintf "%s_%05d_%d", getTS(), int(rand(16536)), $$;
}

=item IntoDB::getTmpFile($extension);

=cut

our $TMP_COUNTER = 1;
sub getTmpFile {
  my $ext = shift;
  my $tmp = (exists $ENV{TMPDIR} && -d $ENV{TMPDIR})? $ENV{TMPDIR}: "/tmp";
  my $fn = sprintf "%s/%s_%s", $tmp, IntoDB::getID(), $TMP_COUNTER ++;
  $fn .= ".$ext" if (defined $ext);
  return $fn;
}

sub takeOverNuclearSilos {
  # not implemented ... yet.
}

=item IntoDB::parseRc($rcConfig);

=cut

sub parseRc {
  my $rcConfig = shift;

  # chunk
  if (defined $rcConfig) {
    my $sname = "params";
    my $iname = "chunk";
    my ($chunkstr) = ($rcConfig->getValues($sname, $iname, -1));
    if (defined $chunkstr) {
      $CHUNK = Check::isInteger($chunkstr, [1,undef]);
    }
  }
  $CHUNK = $OPTS{chunk} if (defined $OPTS{chunk});
  $CHUNK = $DEFOPTS{chunk} if (!defined $CHUNK && defined $DEFOPTS{chunk});
  $CHUNK = $DEFOPTS{chunk} if ($CHUNK < 0 && defined $DEFOPTS{chunk});

  # progress indicator
  if (defined $rcConfig) {
    my $sname = "params";
    my $iname = "progress";
    my ($prgstr) = ($rcConfig->getValues($sname, $iname, -1));
    if (defined $prgstr) {
      if ($prgstr eq "dotprogress" || $prgstr eq "dots") {
        $PROGRESS = DotProgress->new();
      } elsif ($prgstr eq "pctprogress" || $prgstr eq "pct") {
        $PROGRESS = PctProgress->new();
      } else {
        die "rc parse error in section [$sname]: \"$iname\": $prgstr\n";
      }
    }
    ($prgstr) = ($rcConfig->getValues("progress", "default", -1));
    if (defined $prgstr) {
      if ($prgstr eq "dotprogress" || $prgstr eq "dots") {
        $PROGRESS = DotProgress->new();
      } elsif ($prgstr eq "pctprogress" || $prgstr eq "pct") {
        $PROGRESS = PctProgress->new();
      } else {
        die "rc parse error in section [$sname]: \"$iname\": $prgstr\n";
      }
    }
  }
  if (defined $OPTS{progress}) {
    my $prgstr = $OPTS{progress};
    if ($prgstr eq "dotprogress" || $prgstr eq "dots") {
      $PROGRESS = DotProgress->new();
    } elsif ($prgstr eq "pctprogress" || $prgstr eq "pct") {
      $PROGRESS = PctProgress->new();
    } else {
      die "invalid value for argument \"progress\": \"$prgstr\"\n";
    }
  }
  if (!defined $PROGRESS && defined $DEFOPTS{progress}) {
    my $prgstr = $DEFOPTS{progress};
    if ($prgstr eq "dotprogress" || $prgstr eq "dots") {
      $PROGRESS = DotProgress->new();
    } elsif ($prgstr eq "pctprogress" || $prgstr eq "pct") {
      $PROGRESS = PctProgress->new();
    }
  }
  $PROGRESS = DotProgress->new() if (!defined $PROGRESS);

  # separator
  if (defined $rcConfig) {
    my $sname = "params";
    my $iname = "separator";
    my ($sepstr) = ($rcConfig->getValues($sname, $iname, -1));
    $SEPARATOR = $sepstr if (defined $sepstr);
  }
  $SEPARATOR = $OPTS{separator} if (defined $OPTS{separator});
  $SEPARATOR = $DEFOPTS{separator}
               if (!defined $SEPARATOR && defined $DEFOPTS{separator});
  $SEPARATOR = $DEFOPTS{separator}
               if ($SEPARATOR !~ /\S/ && defined $DEFOPTS{separator});

  # tmpdir
  if (defined $rcConfig) {
    my $sname = "params";
    my $iname = "tmpdir";
    my ($tmpstr) = ($rcConfig->getValues($sname, $iname, -1));
    if (defined $tmpstr) {
      my @globed = glob $tmpstr;
      die "multiple entries specified for tmpdir\n" if ($#globed > 0);
      die "no entry specified for tmpdircfile\n" if ($#globed < 0);
      $tmpstr = shift(@globed);
    }
    $TMPDIR = $tmpstr if (defined $tmpstr);
  }
  $TMPDIR = $ENV{TMPDIR} if (!defined $TMPDIR && exists $ENV{TMPDIR});
  $TMPDIR = $OPTS{tmpdir} if (defined $OPTS{tmpdir});
  $TMPDIR = $DEFOPTS{tmpdir}
            if (!defined $TMPDIR && defined $DEFOPTS{tmpdir});
  die "invalid tmp directory \"$TMPDIR\"\n"
            if (defined $TMPDIR && ! -d $TMPDIR);
}

=item IntoDB::loadConfig();

=cut

sub loadConfig {
  my $stdConfig = undef;
  my $rcConfig = undef;

  if (-f $STDRCFILE && -r $STDRCFILE && !$NOSTDRC) {
    my $rc_input = IncludeFile->new($STDRCFILE);
    $stdConfig = RcFile->new($rc_input)->parse();
  }
  if (defined $RCFILE && -f $RCFILE && -r $RCFILE) {
    my $rc_input = IncludeFile->new($RCFILE);
    $rcConfig = RcFile->new($rc_input)->parse();
  }

  # this needs to be first
  IntoDB::parseRc($stdConfig);
  IntoDB::parseRc($rcConfig);

  foreach my $rc ($stdConfig, $rcConfig) {
    next if (!defined $rc);

    # curve param configuration
    Mark->parseRc($rc, ["autolist"]);
    MarkScale->parseRc($rc, ["define", "autolist"]);
    TextMarkScale->parseRc($rc, ["define", "autolist"]);
    Line->parseRc($rc, ["autolist"]);
    Color->parseRc($rc, ["define", "autolist"]);
    Gray->parseRc($rc, ["define", "autolist"]);

    # helper configuration
    Jgraph->parseRc($rc);
    TextEditor->parseRc($rc);
    PsViewer->parseRc($rc);
  }
}

=item IntoDB::run_create();

=cut

sub run_create {
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  $DBH = DB->new($DBFILE, $TRUE);
}

=item IntoDB::run_show_config();

=cut

sub run_show_config {
  my $jgraph = Jgraph->selected();
  my $editor = TextEditor->selected();
  my $psviewer = PsViewer->selected();
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  print  "$VERSION_STRING\n";
  print  "db file  : $DBFILE\n";
  print  "no stdrc : $NOSTDRC\n";
  printf "rc file  : %s\n", (defined $RCFILE)? $RCFILE: "(undef)";
  printf "tmp dir  : %s\n", (defined $TMPDIR)? $TMPDIR: "(undef)";
  print  "verbose  : $VERBOSE\n";
  print  "separator: \"$SEPARATOR\"\n";
  print  "chunk    : $CHUNK\n";
  printf "progress : %s\n", (defined $PROGRESS)? $PROGRESS->name(): "(undef)";
  print "\n";

  printf "gui support: %d\n", $HAS_GTK2;
  printf "color names module: %d\n", $HAS_COLORNAMES;
  printf "numbercruncher module: %d\n", $HAS_NUMBERCRUNCHER;
  printf "point estimation  module: %d\n", $HAS_POINTESTIMATION;
  print "\n";
  
  printf "jgraph: %s\n", (defined $jgraph)? $jgraph->path():
                             "(not available)";
  printf "text editor: %s\n", (defined $editor)? $editor->path():
                             "(not available)";
  printf "ps viewer: %s\n", (defined $psviewer)? $psviewer->path():
                             "(not available)";
  print "\n";

  print "legend justification values:";
  print join("\n- ", "", Justification->list()), "\n";
  printf "auto: %s\n", join(",", @Justification::AutoList);
  print "\n";
  print "axis values:";
  print join("\n- ", "", AxisType->list()), "\n";
  printf "auto: %s\n", join(",", @AxisType::AutoList);
  print "\n";
  print "mark values:";
  print join("\n- ", "", Mark->list()), "\n";
  printf "auto: %s\n", join(",", @Mark::AutoList);
  print "\n";
  print "mark scale values:";
  print join("\n- ", "", MarkScale->list()), "\n";
  printf "auto: %s\n", join(",", @MarkScale::AutoList);
  print "\n";
  print "text mark scale values:";
  print join("\n- ", "", TextMarkScale->list()), "\n";
  printf "auto: %s\n", join(",", @TextMarkScale::AutoList);
  print "\n";
  print "line values:";
  print join("\n- ", "", Line->list()), "\n";
  printf "auto: %s\n", join(",", @Line::AutoList);
  print "\n";
  print "color values:";
  print join("\n- ", "", Color->list()), "\n";
  printf "auto: %s\n", join(",", @Color::AutoList);
  print "\n";
  print "gray values:";
  print join("\n- ", "", Gray->list()), "\n";
  printf "auto: %s\n", join(",", @Gray::AutoList);
  print "\n";
  print "aggregation functions:\n";
  foreach my $n (Aggregation->list()) {
    printf "- %s (%s)\n", $n, Aggregation->new($n)->desc();
  }
  print "\n";
}

=item IntoDB::run_list();

=cut

sub run_list {
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  die "no database\n" if (!defined $DBH);
  foreach my $b (Benchmark->list($DBH)) {
    my $desc = $b->getDesc();
    printf "%-20s", $b->name();
    printf " %s", $desc if (defined $desc);
    print "\n";
  }
}

=item IntoDB::run_details($bench_name);

=cut

sub run_details {
  my $str = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  my $bench = Benchmark->get($DBH, $str);
  my $desc = $bench->getDesc();
  printf "%s", $bench->name();
  printf " - %s", $desc if (defined $desc);
  print "\n";
  print "Field list:\n";
  my @fields = $bench->getFields();
  foreach my $f (@fields) {
    printf "  (%s) %s\n", ($f->numeric())? "num": "txt", $f->name();
  }
  print "Experiment keys:\n";
  my @keys = $bench->getKeyFieldNames();
  if (@keys) {
    printf "  %s\n", join(", ", @keys);
  }
  print "Indexes:\n";
  foreach my $idx (ExpIdx->list($bench)) {
    printf "  %-20s (%s)\n", $idx->name(), join(", ", $idx->getFieldNames());
  }
  print "Data rows:\n";
  printf "  %d\n", $bench->getExpCount();
}

=item IntoDB::run_new($bench_name);

=cut

sub run_new {
  my $bname = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  my $bench = Benchmark->new($DBH, $bname);
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_remove($bench_name);

=cut

sub run_remove {
  my $bname = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  my $bench = Benchmark->new($DBH, $bname);
  $bench->remove();
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_rename($bench_name, $new_name);

=cut

sub run_rename {
  my $old = shift;
  my $new = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  my $bench = Benchmark->get($DBH, $old);
  $bench->setName($new);
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_description($bench_name, $description);

=cut

sub run_description {
  my $bname = shift;
  my $desc = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  if (!defined $desc) {
    die "null description: use an empty string (\"\") to remove description\n";
  }
  my $bench = Benchmark->get($DBH, $bname);
  $bench->setDesc($desc);
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_create_index($bench_name, @field_list);

=cut

sub run_create_index {
  my $bname = shift;
  my @fields = @_;
  my $bench = Benchmark->get($DBH, $bname);
  ExpIdx->new($bench, @fields);
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_remove_index($index_name);

=cut

sub run_remove_index {
  my $name = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  ExpIdx->getByName($DBH, $name)->remove();
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_load_fields($bench_name, $csv_file);

=cut

sub run_load_fields {
  my $bname = shift;
  my $file = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  my $bench = Benchmark->get($DBH, $bname);
  my $input = IncludeFile->new($file);
  my $csv = CsvFile->new($input);
  my @flist = $csv->getFieldNames();
  my $failed = 0;
  foreach my $f (@flist) {
    eval {
      my $field = Field->new($bench, $f);
      $field->setNumeric($csv->getNumeric($f));
    };
    if ($@) {
      $failed ++;
      print STDERR "cannot add field \"$f\": $@\n";
    }
  }
  printf "added %d fields out of %d\n", ($#flist + 1 - $failed), $#flist + 1;
}

=item IntoDB::run_new_field($bench_name, $field_name);

=cut

sub run_new_field {
  my $bname = shift;
  my $fname = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  my $bench = Benchmark->get($DBH, $bname);
  my $field = Field->new($bench, $fname);
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_add_field($bench_name, $field_name, $field_type, $default);

=cut

sub run_add_field {
  my $bname = shift;
  my $fname = shift;
  my $type = shift;
  my $value = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  my $numeric;
  die "null field type: use \"text\" or \"numeric\"\n" if (!defined $type);
  $type = lc($type);
  if ($type =~ /^t(e)?xt$/) {
    $numeric = $FALSE;
  } elsif ($type =~ /^num(eric)?$/) {
    $numeric = $TRUE;
  } else {
    die "invalid field type: use \"text\" or \"numeric\"\n";
  }
  my $bench = Benchmark->get($DBH, $bname);
  my $field = Field->add($bench, $fname, $numeric, $value);
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_remove_field($bench_name, $field_name);

=cut

sub run_remove_field {
  my $bname = shift;
  my $fname = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  my $bench = Benchmark->get($DBH, $bname);
  my $field = Field->get($bench, $fname);
  $field->remove();
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_remove_all_fields($bench_name);

=cut

sub run_remove_all_fields {
  my $bname = shift;
  my $fname = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  Benchmark->get($DBH, $bname)->removeAllFields();
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_remove_all_data($bench_name);

=cut

sub run_remove_all_data {
  my $bname = shift;
  my $fname = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  Benchmark->get($DBH, $bname)->removeAllExperiments();
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_remove_experiment($bench_name, $condition, ...)

=item IntoDB::run_remove_experiment($bench_name, $id1, ...)

=cut

sub run_remove_experiment {
  my $bname = shift;
  my $bench = Benchmark->get($DBH, $bname);
  my @conditions = @_;
  die "no condition specified\n" if (!@conditions);
  if ($conditions[0] =~ /^\d+$/) {
    Experiment->removeId($bench, @conditions);
  } else {
    Experiment->removeSelection($bench, @conditions);
  }
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_field_type($bench_name, $field_name, $field_type);

=cut

sub run_field_type {
  my $bname = shift;
  my $fname = shift;
  my $type = shift;

  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  die "null field type: use \"text\" or \"numeric\"\n" if (!defined $type);
  my $bench = Benchmark->get($DBH, $bname);
  my $field = Field->get($bench, $fname);
  $type = lc($type);
  if ($type =~ /^t(e)?xt$/) {
    $field->setNumeric($FALSE);
  } elsif ($type =~ /^num(eric)?$/) {
    $field->setNumeric($TRUE);
  } else {
    die "invalid field type: use \"text\" or \"numeric\"\n";
  }
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_set_key($bench_name, $field_name, $bool);

=cut

sub run_set_key {
  my $bname = shift;
  my $fname = shift;
  my $bool = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  die "null boolean: use \"true\" or \"false\"\n" if (!defined $bool);
  my $bench = Benchmark->get($DBH, $bname);
  my $field = Field->get($bench, $fname);
  $bool = lc($bool);
  if ($bool =~ /^yes$/) {
    $field->setKey($TRUE);
  } elsif ($bool =~ /^true$/) {
    $field->setKey($TRUE);
  } elsif ($bool =~ /^1$/) {
    $field->setKey($TRUE);
  } elsif ($bool =~ /^no$/) {
    $field->setKey($FALSE);
  } elsif ($bool =~ /^false$/) {
    $field->setKey($FALSE);
  } elsif ($bool =~ /^0$/) {
    $field->setKey($FALSE);
  } else {
    die "invalid boolean: use \"true\" or \"false\"\n";
  }
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_set_outlier($bench_name, $exp_id, $bool);

=cut

sub run_set_outlier {
  my $bname = shift;
  my $expid = shift;
  my $bool = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  die "null boolean: use \"true\" or \"false\"\n" if (!defined $bool);
  my $bench = Benchmark->get($DBH, $bname);
  my $exp = Experiment->get($bench, $expid);
  $bool = lc($bool);
  if ($bool =~ /^yes$/) {
    $exp->setOutlier($TRUE);
  } elsif ($bool =~ /^true$/) {
    $exp->setOutlier($TRUE);
  } elsif ($bool =~ /^1$/) {
    $exp->setOutlier($TRUE);
  } elsif ($bool =~ /^no$/) {
    $exp->setOutlier($FALSE);
  } elsif ($bool =~ /^false$/) {
    $exp->setOutlier($FALSE);
  } elsif ($bool =~ /^0$/) {
    $exp->setOutlier($FALSE);
  } else {
    die "invalid boolean: use \"true\" or \"false\"\n";
  }
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_parse($bench_name, $csv_file);

=cut

sub run_parse {
  my $bname = shift;
  my $file = shift;
  my @extra = @_;

  my $bench = Benchmark->get($DBH, $bname);
  my $view = $bench->view()->create();
  my $input = IncludeFile->new($file);
  my $csv = CsvFile->new($input);
  my $field = {};
  foreach my $f ($bench->getFields()) {
    $field->{$f->name()} = $f;
  }

  my $extra = {};
  my $auto = {};
  foreach my $x (@extra) {
    if ($x =~ /^([\w_]+)=(.*)$/) {
      my $k = uc($1);
      my $v = $2; $v = "" if (!defined $v);
      if (exists $extra->{$k} || exists $auto->{$k}) {
        die "multiple values for field \"$k\"\n";
      }
      $extra->{$k} = $v;
    } elsif ($x =~ /^\-\-?autoid=([\w_]+)$/) {
      my $k = uc($1);
      if (exists $extra->{$k} || exists $auto->{$k}) {
        die "multiple values for field \"$k\"\n";
      }
      $auto->{$k} = 1;
    } else {
      die "invalid extra field specification: \"$x\"\n";
    }
  }

  my $last_progress = 0;
  $PROGRESS->setTotal($input->getByteSize());

  my $exp;
  my $count = 0;
  my $skipped = 0;
  my $baseid = getID();
  my $data = $csv->getData();
  my $bunch = 0;
  while (defined $data) {
    if ($PROGRESS->getCancel()) {
      if ($bunch > 0) {
        $DBH->rollback();
        $bunch = 0;
      }
      die "parsing cancelled\n";
    }
    my $new_progress = $input->getBytePosition() - $last_progress;
    $last_progress += $new_progress;
    my $id = $baseid . "_" . $input->getPosition();
    foreach my $k (keys %$extra) {
      $data->{$k} = $extra->{$k};
    }
    foreach my $k (keys %$auto) {
      $data->{$k} = $id;
    }
    $exp = undef;
    if ($bunch == 0) {
      $DBH->begin_work();
    }
    $bunch += 1;
    eval {
      $exp = Experiment->new($bench, $data);
      if (!$exp->existed()) {
        $view->insert($exp, $data);
      }
      if ($bunch >= $CHUNK) {
        $DBH->commit();
        $bunch = 0;
      }
    };
    if ($@) {
      my $errstr = $@;
      $DBH->rollback();
      $PROGRESS->addFailed($new_progress);
      my $linenum = $input->getPosition() + 1 - $bunch;
      $PROGRESS->setEnd();
      $bunch = 0;
      die "parsing aborted about line ${linenum}: $errstr\n";
    }
    $count ++;
    if ($exp->existed()) {
      $PROGRESS->addSkipped($new_progress);
      $skipped ++;
    } else {
      $PROGRESS->addSuccess($new_progress);
    }
    $data = $csv->getData();
  }
  if ($bunch > 0) {
    eval {
      $DBH->commit();
      $bunch = 0;
    };
    if ($@) {
      my $errstr = $@;
      $DBH->rollback();
      $PROGRESS->addFailed(0);
      #$exp->remove() if (defined $exp);
      my $linenum = $input->getPosition() +1 - $bunch;
      $PROGRESS->setEnd();
      $bunch = 0;
      die "parsing aborted about line ${linenum}: $errstr\n";
    }
  }
  $PROGRESS->setEnd();
  printf "parsed %d experiments out of %d\n", $count - $skipped, $count;
}

=item IntoDB::run_export($bench_name);

=cut

sub run_export {
  my $bname = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  my $bench = Benchmark->get($DBH, $bname);
  my $view = $bench->view()->create();
  my @fields = $bench->getFieldNames();
  my @extra = ("EXP", "OUT");
  my $sqlstr = sprintf "SELECT * FROM %s\n", $view->table();
  my $sth = $DBH->do($sqlstr);
  print join($SEPARATOR, (map {"_$_"} @extra), @fields), "\n";
  my $row = $sth->fetchrow_hashref();
  while (defined $row) {
    print join($SEPARATOR, @{$row}{@extra},@{$row}{(map {"_$_"} @fields)}),"\n";
    $row = $sth->fetchrow_hashref();
  }
}

=item IntoDB::run_dump_schema([$bench_name]);

=item IntoDB::run_dump([$bench_name]);

=cut

sub run_dump_schema {
  my @bnames = @_;
  IntoDB::run_dump_internal(*STDOUT, $FALSE, @bnames);
}

sub run_dump {
  my @bnames = @_;
  IntoDB::run_dump_internal(*STDOUT, $TRUE, @bnames);
}

sub run_dump_internal {
  my $outh = shift;
  my $dump_data = shift;
  my @bnames = @_;
  die "no database\n" if (!defined $DBH);
  die "XML::LibXML module is required for xml dump commands\n" if (!$HAS_XML);
  
  my @blist = ();
  if (@bnames) {
    @blist = map {Benchmark->get($DBH, $_)} @bnames;
  } else {
    @blist = Benchmark->list($DBH);
  }
  
  my $schema = XML::LibXML::Element->new("schema");
     $schema->setAttribute("version", $DBVERSION);
  foreach my $b (@blist) {
    my $desc = $b->getDesc(); $desc = "" if (!defined $desc);
    my $bench = XML::LibXML::Element->new("benchmark");
       $bench->setAttribute("name", $b->name());
       $bench->setAttribute("id", $b->id());
       $bench->appendTextChild("description", $desc);
    foreach my $f ($b->getFields()) {
       my $field = XML::LibXML::Element->new("field");
          $field->setAttribute("type", $f->numeric()? "num": "txt");
          $field->setAttribute("key", $f->getKey()? "true": "false");
          $field->appendText($f->name());
       $bench->appendChild($field);
    }
    $schema->appendChild($bench);
  }

  print  $outh "<?xml version=\"1.0\"?>\n";
  printf $outh "<intodb version=\"%s\">\n", $VERSION;

  print  $outh $schema->toString(1), "\n";

  if ($dump_data) {
    print $outh "<data>\n";
    foreach my $b (@blist) {
      my @fields = $b->getFields();
      printf $outh "<benchmark name=\"%s\" id=\"%d\">\n", $b->name(), $b->id();
      my $view = $b->view();
      if ($view->check()) {
        my $sqlstr = sprintf "SELECT * FROM %s", $view->table();
        my $sth = $DBH->do($sqlstr);
        my $row = $sth->fetchrow_hashref();
        while (defined $row) {
          my $exp = XML::LibXML::Element->new("experiment");
             $exp->setAttribute("id", $row->{EXP});
             $exp->setAttribute("out", $row->{OUT});
          foreach my $f (@fields) {
            my $fname = $f->name();
            my $item = XML::LibXML::Element->new("value");
               $item->setAttribute("name", $fname);
               $item->setAttribute("type", $f->numeric()? "num": "txt");
               $item->appendText($row->{"_$fname"});
            $exp->appendChild($item);
          }
          print $outh $exp->toString(1), "\n";
          $row = $sth->fetchrow_hashref();
        }
      }
      print $outh "</benchmark>\n";
    }
    print $outh "</data>\n";
  }
  print $outh "</intodb>\n";
}

=item IntoDB::run_restore_schema($filename);

=item IntoDB::run_restore($filename);

=cut

my $XMLPARSE = undef;
sub xml_retrieve_element {
  my $item = shift;
  my $element = undef;
  foreach my $i (@{$XMLPARSE->{_Stack}}) {
    $element = $i if ($i->{name} eq $item);
  }
  return $element;
}

my %XMLSTART = (
  'intodb' => sub {
      my ($p, $item, %attr) = @_;
      return {name => $item, version => $attr{version}};
  },
  'schema' => sub {
      my ($p, $item, %attr) = @_;
      return {name => $item, version => $attr{version}};
  },
  'benchmark' => sub {
      my ($p, $item, %attr) = @_;
      my $bench = Benchmark->new($DBH, $attr{name});
      my $view = $bench->view();
      $view->create() if ($p->within_element("data"));
      return {name => $item, bench => $bench, view => $view};
  },
  'description' => sub {
      my ($p, $item, %attr) = @_;
      if (!$p->in_element("benchmark")) {
        $p->finish();
        die "description not in benchmark context\n";
      }
      if (!$p->within_element("schema")) {
        $p->finish();
        die "benchmark description outside schema\n";
      }
      my $bdata = xml_retrieve_element("benchmark");
      return {name => $item, bdata => $bdata};
  },
  'field' => sub {
      my ($p, $item, %attr) = @_;
      if (!$p->in_element("benchmark")) {
        $p->finish();
        die "field description not in benchmark context\n";
      }
      if (!$p->within_element("schema")) {
        $p->finish();
        die "field description outside schema\n";
      }
      my $numeric = $FALSE;
      if ($attr{type} && $attr{type} =~ /^num(eric)?$/i) {
        $numeric = $TRUE;
      } elsif ($attr{type} && $attr{type} !~ /^te?xt$/i) {
        $p->finish();
        die "invalid field type\n";
      }
      my $key = $FALSE;
      if ($attr{key} && grep {lc($attr{key}) eq $_} qw(true yes on 1)) {
        $key = $TRUE;
      } elsif ($attr{key} && !grep {lc($attr{key}) eq $_} qw(false no off 0)) {
        $p->finish();
        die "invalid field key specification\n";
      }
      my $bdata = xml_retrieve_element("benchmark");
      return {name => $item, bdata => $bdata, num => $numeric, key => $key};
  },
  'data' => sub {
      my ($p, $item, %attr) = @_;
      return {name => $item} if (!$XMLPARSE->{_RestoreData});
      $PROGRESS->setTotal($XMLPARSE->{_Size} - $p->current_byte());
      my $prg = {
        last_progress => $p->current_byte(),
        bunch => 0,
      };
      return {name => $item, prg => $prg};
  },
  'experiment' => sub {
      my ($p, $item, %attr) = @_;
      return {name => $item} if (!$XMLPARSE->{_RestoreData});
      if (!$p->in_element("benchmark")) {
        $p->finish();
        die "experiment not in benchmark context\n";
      }
      if (!$p->within_element("data")) {
        $p->finish();
        die "experiment outside data context\n";
      }
      my $out = $FALSE;
      if ($attr{out} && grep {lc($attr{out}) eq $_} qw(true yes on 1)) {
        $out = $TRUE;
      } elsif ($attr{out} && !grep {lc($attr{out}) eq $_} qw(false no off 0)) {
        $p->finish();
        die "invalid experiment outlier specification\n";
      }
      my $bdata = xml_retrieve_element("benchmark");
      return {name => $item, bdata => $bdata, out => $out, items => {}};
  },
  'value' => sub {
      my ($p, $item, %attr) = @_;
      return {name => $item} if (!$XMLPARSE->{_RestoreData});
      if (!$p->in_element("experiment")) {
        $p->finish();
        die "value outside experiment context\n";
      }
      my $field = $attr{name};
      return {name => $item, field => $field};
  },
);
my %XMLEND = (
  'description' => sub {
      my ($p, $item) = @_;
      my $bdata = xml_retrieve_element("benchmark");
      $bdata->{bench}->setDesc($XMLPARSE->{_String});
  },
  'field' => sub {
      my ($p, $item) = @_;
      my $fdata = xml_retrieve_element("field");
      my $fname = $XMLPARSE->{_String};
      my $field = Field->new($fdata->{bdata}->{bench}, $fname);
      $field->setNumeric($fdata->{num});
      $field->setKey($fdata->{key});
  },
  'data' => sub {
      my ($p, $item) = @_;
      return if (!$XMLPARSE->{_RestoreData});
      my $data = xml_retrieve_element("data");
      my $prg = $data->{prg};
      my $end_progress = $XMLPARSE->{_Size} - $prg->{last_progress};
      if ($prg->{bunch} > 0) {
        eval {
          $DBH->commit();
          $PROGRESS->addSuccess($end_progress);
          $prg->{bunch} = 0;
        };
        if ($@) {
          my $errstr = $@;
          $DBH->rollback();
          $PROGRESS->addFailed(0);
          $PROGRESS->setEnd(0);
          my $linenum = $p->current_line() - $prg->{bunch};
          $prg->{bunch} = 0;
          $p-> finish();
          die "parsing aborted about line ${linenum}: $errstr\n";
        }
      } elsif ($end_progress) {
        $PROGRESS->addSuccess($end_progress);
      }
      $PROGRESS->setEnd(0);
  },
  'value' => sub {
      my ($p, $item) = @_;
      return if (!$XMLPARSE->{_RestoreData});
      my $edata = xml_retrieve_element("experiment");
      my $vdata = xml_retrieve_element("value");
      $edata->{items}->{$vdata->{field}} = $XMLPARSE->{_String};
  },
  'experiment' => sub {
      my ($p, $item) = @_;
      return if (!$XMLPARSE->{_RestoreData});
      my $edata = xml_retrieve_element("experiment");
      my $data = xml_retrieve_element("data");
      my $bdata = $edata->{bdata};
      my $items = $edata->{items};
      my $prg = $data->{prg};
      if ($PROGRESS->getCancel()) {
        if ($prg->{bunch} > 0) {
          $DBH->rollback();
          $prg->{bunch} = 0;
        }
        $p->finish();
        die "parsing canceled\n";
      }
      my $new_progress = $p->current_byte() - $prg->{last_progress};
      $prg->{last_progress} += $new_progress;
      if ($prg->{bunch} == 0) {
        $DBH->begin_work();
      }
      $prg->{bunch} += 1;
      my $exp = undef;
      eval {
        $exp = Experiment->new($bdata->{bench}, $items);
        if (!$exp->existed()) {
          $bdata->{view}->insert($exp, $items);
          $exp->setOutlier($edata->{out});
        }
        if ($prg->{bunch} >= $CHUNK) {
          $DBH->commit();
          $prg->{bunch} = 0;
        }
      };
      if ($@) {
        my $errstr = $@;
        $DBH->rollback();
        $PROGRESS->addFailed($new_progress);
        $PROGRESS->setEnd(0);
        my $linenum = $p->current_line() + 1 - $prg->{bunch};
        $prg->{bunch} = 0;
        $p->finish();
        die "parsing aborted about line ${linenum}: $errstr\n";
      }
      if ($exp->existed()) {
        $PROGRESS->addSkipped($new_progress);
      } else {
        $PROGRESS->addSuccess($new_progress);
      }
  },
);

sub xml_parse {
  my $fh = shift;
  my $parser = shift;
  my $restore_data = shift;
  my @statdata = stat $fh;
  $XMLPARSE = {};
  $XMLPARSE->{_Stack} = [];
  $XMLPARSE->{_String} = "";
  $XMLPARSE->{_Size} = $statdata[7];
  $XMLPARSE->{_RestoreData} = $restore_data;

  eval {$parser->parse($fh)};
  my $errstr = $@;
  $parser->release();
  $XMLPARSE = undef;
  die "$errstr\n" if ($errstr);
}

sub run_restore_schema {
  my $file = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  IntoDB::run_restore_internal($file, $FALSE);
}

sub run_restore {
  my $file = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  IntoDB::run_restore_internal($file, $TRUE);
}

sub run_restore_internal {
  my $file = shift;
  my $restore_data = shift;
  die "no database\n" if (!defined $DBH);
  die "XML::Parser::Expat module required for xml_restore\n" if (!$HAS_EXPAT);
  die "missing file name\n" if (!defined $file);
  die "invalid file name \"$file\"\n" if (!-f $file);
  
  my $parser = XML::Parser::Expat->new();
  $parser->setHandlers(
    'Start' => sub {
        my ($parser, $item, %attr) = @_;
        if (!exists $XMLSTART{$item}) {
          $parser->finish();
          die "unrecognized xml element \"$item\"\n";
        }
        my $func = $XMLSTART{$item};
        my $element = &{$func}($parser, $item, %attr);
        push(@{$XMLPARSE->{_Stack}}, $element);
        $XMLPARSE->{_String} = "";
    },
    'End' => sub {
        my ($parser, $item) = @_;
        my $func = $XMLEND{$item};
        &{$func}($parser, $item) if (defined $func);
        pop(@{$XMLPARSE->{_Stack}});
        $XMLPARSE->{_String} = "";
    },
    'Char' => sub {
        my ($parser, $str) = @_;
        $XMLPARSE->{_String} .= $str;
    },
  );

  open(FH, $file) || die "cannot open file \"$file\"\n";
  eval {IntoDB::xml_parse(*FH, $parser, $restore_data)};
  my $errstr = $@;
  close(FH);
  die "$errstr\n" if ($errstr);
  print STDERR "done\n" if ($VERBOSE > 0);
}

=item IntoDB::run_sql_select($query_string);

=cut

sub run_sql_select {
  my $sqlstr = shift;
  $sqlstr =~ s/^SELECT\s+FROM\b/SELECT * FROM/i;
  $sqlstr =~ s/^SELECT\s+DISTINCT\s+FROM\b/SELECT DISTINCT * FROM/i;
  $sqlstr =~ s/^SELECT\s+ALL\s+FROM\b/SELECT ALL * FROM/i;
  $sqlstr =~ s/^SELECT\s+COUNT\s+FROM\b/SELECT COUNT(*) FROM/i;
  $sqlstr =~ s/^SELECT\s+DISTINCT\s*COUNT\s+FROM\b/SELECT DISTINCT COUNT(*) FROM/i;
  $sqlstr =~ s/^SELECT\s+COUNT\s*DISTINCT\s+FROM\b/SELECT DISTINCT COUNT(*) FROM/i;
  my %flen;
  my %vhash;
  my @views = ($sqlstr =~ /\b\w[\w_]*_VIEW\b/ig);
  foreach my $v (@views) {
    my $b = uc($v); $b =~ s/_VIEW$//;
    if (!exists $vhash{$b}) {
      my $bench = Benchmark->get($DBH, $b);
      $bench->view()->create();
      $vhash{$b} = $bench->view()->create();
    }
  }
  my $sth = $DBH->do($sqlstr);
  my $row = $sth->fetchrow_hashref();
  if (!defined $row) {
    print STDERR "no data selected\n";
  } else {
    my @head = sort keys %$row;
    foreach my $hd (@head) {
      my $klen = 12;
      my $val = $row->{$hd}; $val = "" if (!defined $val);
      if ($val !~ /^(\+|\-)?\d+(\.\d+([eE](\+|\-)?\d+)?)?$/) {
        $klen = 24;
      }
      if (length($hd) > $klen) {
        $klen = length($hd) + 2;
      }
      if (length($val) > $klen) {
        $klen = length($val) + 2;
      }
      $flen{$hd} = $klen;
      printf " %-${klen}s", $hd;
    }
    print "\n";
    foreach my $hd (@head) {
      my $klen = $flen{$hd};
      printf " %-${klen}s", "-" x $klen;
    }
    print "\n";
    while (defined $row) {
      foreach my $hd (@head) {
        my $klen = $flen{$hd};
        if (defined $row->{$hd}) {
          printf " %-${klen}s", $row->{$hd};
        } else {
          printf " %-${klen}s", "";
        }
      }
      print "\n";
      $row = $sth->fetchrow_hashref();
    }
  }
}

=item IntoDB::run_sql_modify($sql_string);

=cut

sub run_sql_modify {
  my $sqlstr = shift;
  my %vhash;
  my @views = ($sqlstr =~ /\b\w[\w_]*_VIEW\b/ig);
  foreach my $v (@views) {
    my $b = uc($v); $b =~ s/_VIEW$//;
    if (!exists $vhash{$b}) {
      my $bench = Benchmark->get($DBH, $b);
      $bench->view()->create();
      $vhash{$b} = $bench->view()->create();
    }
  }
  my $sth = $DBH->do($sqlstr);
  printf "modified %d row(s)\n", $sth->rows();
}

=item IntoDB::run_sql_any($sql_string);

=cut

sub run_sql_any {
  my $sqlstr = shift;
  my $sth = $DBH->do($sqlstr);
  printf "modified %d row(s)\n", $sth->rows();
}

=item IntoDB::run_sql($sql_string);

=cut

sub run_sql {
  my $sqlstr = join(" ", @ARGV);
  if ($sqlstr =~ /^\s*select\b/i) {
    run_sql_select($sqlstr);
  } elsif ($sqlstr =~ /^\s*update\b/i) {
    run_sql_modify($sqlstr);
  } elsif ($sqlstr =~ /^\s*delete\b/i) {
    run_sql_modify($sqlstr);
  } elsif ($sqlstr =~ /^\s*insert\b/i) {
    run_sql_modify($sqlstr);
  } else {
    die "invalid sql operation\n";
  }
}

=item IntoDB::run_admsql($sql_string);

=cut

sub run_admsql {
  my $sqlstr = join(" ", @ARGV);
  if ($sqlstr =~ /^\s*select\b/i) {
    run_sql_select($sqlstr);
  } else {
    run_sql_any($sqlstr);
  }
}

=item IntoDB::run_check_graph($graph_file);

=cut

sub run_check_graph {
  my $file = shift;
  warn "extra tokens in command line (ignored)\n" if ($#_ >= 0);
  my $input = IncludeFile->new($file);
  my $GraphFile = GraphFile->new($input);
  my @glist = $GraphFile->parse();
  foreach my $g (@glist) {
    $g->verify();
  }
  if ($VERBOSE > 0) {
    foreach my $g (@glist) {
      print STDERR $g->string();
    }
  }
  printf "parsed %d graph description(s)\n", $#glist + 1;
}

=item IntoDB::run_graph($graph_file);

=cut

sub run_graph {
  my $file = shift;
  my $Override = {};
  my $extra_tokens = 0;
  foreach my $tk (@_) {
    if ($tk =~ /^([\w_]+)=(.*)$/) {
      my $var = $1;
      my $val = $2; $val = "" if (!defined $val);
      $Override->{$var} = $val;
    } else {
      $extra_tokens ++;
    }
  }
  warn "extra tokens in command line (ignored)\n" if ($extra_tokens);
  my $input = IncludeFile->new($file);
  my $GraphFile = GraphFile->new($input);
  my @glist = $GraphFile->parse();
  print STDERR "no graph description found\n" if (!@glist);
  my $idx = 0;
  foreach my $g (@glist) {
    $g->verify();
    $g->calculate($Override);
    print $g->jgraph($idx, $Override);
    $idx += 1 unless $g->skipped();
  }
}

=item IntoDB::run_data($graph_file);

=cut

sub run_data {
  my $file = shift;
  my $Override = {};
  my $extra_tokens = 0;
  foreach my $tk (@_) {
    if ($tk =~ /^([\w_]+)=(.*)$/) {
      my $var = $1;
      my $val = $2; $val = "" if (!defined $val);
      $Override->{$var} = $val;
    } else {
      $extra_tokens ++;
    }
  }
  warn "extra tokens in command line (ignored)\n" if ($extra_tokens);
  my $input = IncludeFile->new($file);
  my $GraphFile = GraphFile->new($input);
  my @glist = $GraphFile->parse();
  print STDERR "no graph description found\n" if (!@glist);
  my $idx = 0;
  foreach my $g (@glist) {
    $g->verify();
    $g->calculate($Override);
    print $g->data($idx, $Override);
    $idx += 1 unless $g->skipped();
  }
}

=item IntoDB::run_xmlplot($graph_file);

=cut

sub run_xmlplot {
  my $file = shift;
  my $Override = {};
  my $extra_tokens = 0;
  foreach my $tk (@_) {
    if ($tk =~ /^([\w_]+)=(.*)$/) {
      my $var = $1;
      my $val = $2; $val = "" if (!defined $val);
      $Override->{$var} = $val;
    } else {
      $extra_tokens ++;
    }
  }
  warn "extra tokens in command line (ignored)\n" if ($extra_tokens);
  my $input = IncludeFile->new($file);
  my $GraphFile = GraphFile->new($input);
  my @glist = $GraphFile->parse();
  print STDERR "no graph description found\n" if (!@glist);
  IntoDB::run_xmlplot_internal(*STDOUT, $Override, @glist);
}

sub run_xmlplot_internal {
  my $outh = shift;
  my $Override = shift;
  my @glist = @_;
  print $outh "<?xml version=\"1.0\"?>\n";
  printf $outh "<intodbplot version=\"%s\">\n", $VERSION;

  my $idx = 0;
  my $inset = 0;
  foreach my $g (@glist) {
    $g->verify();
    $g->calculate($Override);
    my $xml = $g->xml($idx, $Override);
    if (defined $xml) {
      if (!$inset || $xml->getAttribute("newpage") eq "true") {
        print $outh "</graphset>\n" if ($inset);
        print $outh "<graphset>\n";
        $inset = 1;
      }
      print $outh $xml->toString(1), "\n";
      $idx+=1;
    }
  }
  print $outh "</graphset>\n" if ($inset);
  print $outh "</intodbplot>\n";
}

=item IntoDB::run_commands();

=cut

sub run_commands {
  foreach my $cmd (sort keys %CMDHASH) {
    printf "%s\n", $cmd;
  }
}

=item IntoDB::run_man();

=cut

sub run_man {
  exec "perldoc", $0;
  die "cannot execute \"perldoc\"\n";
}

=item IntoDB::run_help();

=cut

sub run_help {
  print "$VERSION_STRING\n";
  print "usage: $0 [options] <command> <command_arguments>\n";
  print "\navailable options:\n";
  print "  -rc=FILE             name of additional config file\n";
  print "  -nostdrc             do not load base config file (~/.intodbrc)\n";
  print "  -db=DATABASE         specify database file (default: BenchDB.db)\n";
  print "  -tmpdir=DIR          directory for temporary files\n";
  print "  -sep=STRING          separator for csv files (default: \":\")\n";
  print "  -progress={dots|pct} progress indicator\n";
  print "  -chunk=INT           experiments per transaction when parsing\n";
  print "  -v             increase verbosity (multiple -v are allowed)\n";
  print "\navailable commands:\n";
  foreach my $cmd (sort keys %CMDHLP) {
    printf "\n  %-12s - %s", $cmd, $CMDHLP{$cmd};
  }
}

=item IntoDB::run_version();

=cut

sub run_version {
  print "$VERSION_STRING\n";
}

=item IntoDB::run_license();

=cut

sub run_license {
  print "$0\n";
  print "version: $VERSION_STRING\n\n";
  print "$LICENSE\n";
}

#=item IntoDB::run_gui();
#
#=cut

sub run_gui {
  die "Glib and Gtk2 perl modules are required for \"gui\"\n" if (!$HAS_GTK2);
  Gtk2->init();
  IntoDBGui->new()->run();
}

=item IntoDB->run();

=cut

sub run {
  my $proto = shift;
  my $cmd = shift(@ARGV);

  if ($VERBOSE > 5) {
    print STDERR
          "this is not apt-get, so no super-cow powers are available, sorry\n";
    print STDERR
          "...but you could try some magic instead...\n\n";
  }

  IntoDB::loadConfig();

  if (!defined $cmd) {
    die "nothing to do\n\n" .
      "(use \"$SCRIPT help\" for help, \"$SCRIPT man\" for the whole\n" .
      "manual page, and \"$SCRIPT license\" to see the license terms)\n";
  }
  $cmd = lc($cmd);
  die "insufficient mana\n" if ($cmd eq "magic");
  die "unknown command \"$cmd\"\n" if (!exists $CMDHASH{$cmd});

  if (-f $DBFILE && !exists $INFOHASH{$cmd}) {
    $DBH = DB->new($DBFILE, $FALSE);
  }

  &{$CMDHASH{$cmd}}(@ARGV);
  exit 0;
}

=back

=cut

IntoDB->run();

__END__

=head1 CHANGE LOG

=head2 v0.99

=over

=item June 1st, 2009

first release tag: 0.99.0

=item June 2nd, 2009 (v. 0.99.1)

Added command: remove_experiment

=item June 3rd, 2009 (v. 0.99.2)

Fixed file name suggestion when saving files from gui.

Improved graph parameter interface.

=item June 4th, 2009 (v. 0.99.3)

Minor change in parsing progress indicator.

=item June 16th, 2009 (v. 0.99.4)

Added new aggregation functions: ci_max, ci_min, delta

Minor changes in documentation

=item June 17th, 2009 (v. 0.99.5)

Delay removing temporary postscript files, so that some faulty
evince versions do not experiment problems when zooming...

=item June 17th, 2009 (v. 0.99.6)

Gui: Added options to save and load graph configuration parameters to
and from a file (thanks to Alberto Miranda for the patch).

=item June 18th, 2009 (v. 0.99.7)

Minor fix to force uppercase printing of column names from the database.

Added separate license file.

=item June 19th, 2009 (v. 0.99.8)

Correctly reap helper zombies.

=item June 22nd, 2009 (v. 0.99.9)

Allow large chunks to speed-up database loading.

=item June 22nd, 2009 (v. 0.99.10)

Fixed bug in code for bar stacks

=item June 23nd, 2009 (v. 0.99.11)

Use temporary tables instead of views. This dramatically speeds-up
data drawing in gui for very large data sets (though it should have 
no effect for command-line use). Initial table generation still takes
a loooong time for data sets above 50,000 entries.

Added "-tmpdir" option to specify the location of temporary tables.

=back

=head2 v0.100

WARNNG: The schema of the internal database has changed and it is not
compatible with the v0.99 series. Old databases should be re-created and
re-loaded for this version of the script. Changes from version 0.99 are
mostly internal and should not affect the IntoDB usage.

It is possible to migrate from old database format to the new one by
using the C<dump> and C<restore> commands from versions 0.99 and 0.100
respectively.

=over

=item June 25th, 2009 (v. 0.100.0)

Major re-factoring of the internal database. The new schema should be faster
to load and to query. These changes were required in order to deal with
large data sets.

Added internal support for arbitrary data indexing (not active yet).

Added detailed documentation for command line options.

Major efforts to keep the external interface untouched.

NOTE: this version is the first release in the v0.100 series; should be
considered alpha.

=item June 26th, 2009 (v. 0.100.1)

Activated index support.

New commands: create_index, remove_index.

=item June 30th, 2009 (v. 0.100.2)

Added xml dump/restore (commands: dump_schema, dump, restore_schema, restore).
These commands allow restoring a database created with version 0.99, by
C<dumping> the old database with an old version of intodb and C<restoring>
the resulting file with a current version of intodb.

=item July 1st, 2009 (v. 0.100.3)

Bug fix: restore outlier information when importing from xml.

=item July 7th, 2009 (v. 0.100.4)

Added feature: dump graph data in xml format (so it can be parsed and feeded
to other plotting/post-processing tools). See new command: xmlplot.

=item July 30th, 2009 (v. 0.100.5)

In the gui, do not count the experiments in the benchmark manager unless
required.

Default configuration file can now be partially overriden by specific
configuration file (C<-rc>, C<-nostdrc>).

Progress section in configuration file is deprecated. New section C<params>
allow specifying chunk, progress indicator, tmp file and separator.

Minor additions to documentation

Also, fixed some minor bugs.

=item July 30th, 2009 (v. 0.100.6)

Fixed a bug in experiment deletion (thanks to Juanjo Costa for the patch).

=item August 4th, 2009 (v. 0.100.7-pre1)

Automatically add the star C<*> as argument for count when no columns are
specified.

=item August 17th, 2009 (v. 0.100.7-pre2)

Added new options to help info.

Added functors to use with C<xval> and C<yval> (in particular, added support
for clusterization.)

=item August 31st, 2009 (v. 0.100.7-pre3)

Tried Make xoffset/yoffset work with clusterization functions (in general,
with numeric class values - but not logarithmic.) The code was discarded,
as it is not obvious how to make the things right (and doing them badly is
not a good idea.) The problem is that having a continuous range of values and
adding arbitrary offsets to certain curve values can easily lead to confusing
graphs, overlapping bars that should not be together; so, offsets are
restricted to category values only. Note that it is always possible to manually
add a different constant value per curve to the result of the clusterization
function.

=item August 31st, 2009 (v. 0.100.7-pre4)

Added C<eval> key to C<global> section, allowing variables to be assigned
expressions to evaluate during execution.

Added C<xskip> and C<yskip> to avoid printing all hash labels for category
variables (hash marks are still printed.)

=item September 1st, 2009 (v. 0.100.7)

Print minor hash marks for skipped labels in category variables, instead
of full hash marks.

=item September 28th, 2009 (v. 0.100.8-pre1)

Added the possibility of extra spaces between xcat/ycat category labels
with C<_>.

=item November 26th, 2009 (v. 0.100.8-pre2)

Minor fix in notification window for malformed csv files.

Fixed bug in csv split for empty fields.

=item November 30th, 2009 (v. 0.100.8-pre3)

Added graph options: xrotate_labels and yrotate_labels.

Fixed bug in number checking (was not accepting negative values).

Added graph options: xno_min, yno_min.

=item March 2nd, 2010 (v. 0.100.8-pre4)

Added C<descriptive_data> option to generate human readable data dumps (based
on Juanjo Costa's patch).

Added graph items: C<legend_x> and C<legend_y> (Thanks to Martin Rehr for the
patch).

Fixed a bug (variables in the C<xcat>, C<ycat> can now be overriden by
environment variables).

=item March 5th, 2010 (v. 0.100.8-pre5)

Minor bugs in previous patches

=item March 15th, 2010 (v. 0.100.8)

Tagged as v0.100.8

=item March 31st, 2010 (v. 0.100.9-pre1)

Added the possibility to span items and keywords across several lines in a
file by terminating the lines in a blank space followed by a backslash.

Added the C<func> keyword to the C<global> section in the Graph Description
File to define arbitrary perl functions to be used to compute C<x> and C<y>
values for the graphs.

=item April 6th, 2010 (v. 0.100.9)

Tagged as v0.100.9

=item April 14th, 2010 (v. 0.100.10-pre1)

Allow #INCLUDE "filepath" directives in intodb files.

Some improvement in function hanling (generate the code once, use
several times).

Allow calling defined functions from inside other defined functions.

=item April 15th, 2010 (v. 0.100.10-pre2)

Make file dialogs remember the last folder visited (and add the initial
directory as a C<bookmark>).

Tag as v0.100.10

=item April 29, 2010 (v. 0.100.11-pre1)

Corrected some internal function documentation

Prevent warnings when applying numerical aggregation functions to
non-numerical values, specially anoying on automatic computations for
normalized graphs (on the other hand, there will be no warning for
erroneous aggregation functions... so, not sure if that was a bug or
a feature...)

=item June 23, 2010 (v. 0.100.11-pre2)

Added compact view for variable values in graph generation gui.

Added "view jgr" command to graph generation gui.

Added "no_stack" option to curves (to skip stacking for a particular curve).

Allow direct RGB and gray level color specification in the curve sections.

Tag as v0.100.11

=item June 24, 2010 (v. 0.100.12)

Fixed a bug preventing the specification of per-curve markscale and
textmarkscale (Thanks to Martin Rehr for the report and patch).

Fixed case confusions in the global configuration file, affecting
color, gray, textmarkscale and markscale settings.

Allow direct and anonymous specifications of markscale/textmarkscale.

Tag as v0.100.12

=item July 13, 2010 (v. 0.100.13-pre1)

Added the "accum" option for curves to accumulate y-values across the x axis

=back

=cut

