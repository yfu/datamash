#!/usr/bin/perl

use strict;
use warnings;

# Until a better way comes along to auto-use Coreutils Perl modules
# as in the coreutils' autotools system.
use Coreutils;
use CuSkip;
use CuTmpdir qw(calc);

(my $program_name = $0) =~ s|.*/||;
my $prog = 'calc';

# TODO: add localization tests with "grouping"
# Turn off localization of executable's output.
@ENV{qw(LANGUAGE LANG LC_ALL)} = ('C') x 3;

# note: '5' appears twice
my $in1 = join("\n", qw/1 2 3 4 5 6 7 5 8 9 10/) . "\n";

# Mix of whitespace and tabs
my $in2 = "1  2\t  3\n" .
          "4\t5 6\n";
my $in_minmax = join("\n", qw/5 90 -7e2 3 200 0.1e-3 42/) . "\n";

# Input with three groups, separated by empty lines
# (as if from 'uniq --group')
my $in_g1 = join("\n", 10 .. 20) . "\n" .
            "\n" .
            join("\n", 1 .. 13) . "\n" .
            "\n" .
            join("\n", 66 .. 99) . "\n" ;

my @Tests =
(
  # Basic tests, single field, single group, default everything
  ['b1', 'count 1' ,    {IN_PIPE=>$in1},  {OUT => "11\n"}],
  ['b2', 'sum 1',       {IN_PIPE=>$in1},  {OUT => "60\n"}],
  ['b3', 'min 1',       {IN_PIPE=>$in1},  {OUT => "1\n"}],
  ['b4', 'max 1',       {IN_PIPE=>$in1},  {OUT => "10\n"}],
  ['b5', 'absmin 1',    {IN_PIPE=>$in1},  {OUT => "1\n"}],
  ['b6', 'absmax 1',    {IN_PIPE=>$in1},  {OUT => "10\n"}],
  ['b8', 'median 1',    {IN_PIPE=>$in1},  {OUT => "5\n"}],
  ['b9', 'mode 1',      {IN_PIPE=>$in1},  {OUT => "5\n"}],
  ['b10', 'antimode 1', {IN_PIPE=>$in1},  {OUT => "1\n"}],
  ['b11', 'unique 1',   {IN_PIPE=>$in1},  {OUT => "1,10,2,3,4,5,6,7,8,9\n"}],
  ['b12', 'uniquenc 1', {IN_PIPE=>$in1},  {OUT => "1,10,2,3,4,5,6,7,8,9\n"}],
  ['b13', 'collapse 1', {IN_PIPE=>$in1},  {OUT => "1,2,3,4,5,6,7,5,8,9,10\n"}],

  # on a different architecture, would printf(%Lg) print something else?
  # Use OUT_SUBST to trim output to 1.3 digits
  ['b14', 'mean 1',     {IN_PIPE=>$in1},  {OUT => "5.454\n"},
	  {OUT_SUBST=>'s/^(\d\.\d{3}).*/\1/'}],
  ['b15', 'pstdev 1',   {IN_PIPE=>$in1},  {OUT => "2.742\n"},
	  {OUT_SUBST=>'s/^(\d\.\d{3}).*/\1/'}],
  ['b16', 'sstdev 1',   {IN_PIPE=>$in1},  {OUT => "2.876\n"},
	  {OUT_SUBST=>'s/^(\d\.\d{3}).*/\1/'}],
  ['b17', 'pvar 1',     {IN_PIPE=>$in1},  {OUT => "7.520\n"},
	  {OUT_SUBST=>'s/^(\d\.\d{3}).*/\1/'}],
  ['b18', 'svar 1',     {IN_PIPE=>$in1},  {OUT => "8.272\n"},
	  {OUT_SUBST=>'s/^(\d\.\d{3}).*/\1/'}],


  ## Some error checkings
  ['e1',  'sum',  {IN_PIPE=>""}, {EXIT=>1},
	  {ERR=>"$prog: missing field number after operation 'sum'\n"}],
  ['e2',  'foobar',  {IN_PIPE=>""}, {EXIT=>1},
	  {ERR=>"$prog: invalid operation 'foobar'\n"}],
  ['e3',  '',  {IN_PIPE=>""}, {EXIT=>1},
	  {ERR=>"$prog: missing operations specifiers\n"}],
  ['e4',  'sum 1' ,  {IN_PIPE=>"a\n"}, {EXIT=>1},
	  {ERR=>"$prog: invalid numeric input in line 1 field 1: 'a'\n"}],

  # No newline at the end of the lines
  ['nl1', 'sum 1', {IN_PIPE=>"99"}, {OUT=>"99\n"}],
  ['nl2', 'sum 1', {IN_PIPE=>"1\n99"}, {OUT=>"100\n"}],

  # empty input = empty output
  [ 'emp1', 'count 1', {IN_PIPE=>""}, {OUT=>""}],
  [ 'emp2', 'count 1', {IN_PIPE=>"\n"}, {OUT=>""}],
  [ 'emp3', 'count 1', {IN_PIPE=>"\n\n"}, {OUT=>""}],

  ## Field extraction
  ['f1', 'sum 1', {IN_PIPE=>$in2}, {OUT=>"5\n"}],
  ['f2', 'sum 2', {IN_PIPE=>$in2}, {OUT=>"7\n"}],
  ['f3', 'sum 3', {IN_PIPE=>$in2}, {OUT=>"9\n"}],
  ['f4', 'sum 3 sum 1', {IN_PIPE=>$in2}, {OUT=>"9 5\n"}],
  ['f5', '-t: sum 4', {IN_PIPE=>"11:12::13:14"}, {OUT=>"13\n"}],

  # Test Absolute min/max
  ['mm1', 'min 1', {IN_PIPE=>$in_minmax}, {OUT=>"-700\n"}],
  ['mm2', 'max 1', {IN_PIPE=>$in_minmax}, {OUT=>"200\n"}],
  ['mm3', 'absmin 1', {IN_PIPE=>$in_minmax}, {OUT=>"0.0001\n"}],
  ['mm4', 'absmax 1', {IN_PIPE=>$in_minmax}, {OUT=>"-700\n"}],

  # Test Groups
  ['g1', 'count 1' ,    {IN_PIPE=>$in_g1},  {OUT => "11\n13\n34\n"}],
  ['g2', 'sum 1',       {IN_PIPE=>$in_g1},  {OUT => "165\n91\n2805\n"}],
  ['g3', 'min 1',       {IN_PIPE=>$in_g1},  {OUT => "10\n1\n66\n"}],
  ['g4', 'max 1',       {IN_PIPE=>$in_g1},  {OUT => "20\n13\n99\n"}],
  ['g5', 'absmin 1',    {IN_PIPE=>$in_g1},  {OUT => "10\n1\n66\n"}],
  ['g6', 'absmax 1',    {IN_PIPE=>$in_g1},  {OUT => "20\n13\n99\n"}],
  ['g8', 'median 1',    {IN_PIPE=>$in_g1},  {OUT => "15\n7\n82.5\n"}],
  ['g9', 'mode 1',      {IN_PIPE=>$in_g1},  {OUT => "10\n1\n66\n"}],
  ['g10', 'antimode 1', {IN_PIPE=>$in_g1},  {OUT => "10\n1\n66\n"}],
  ['g11', 'unique 1',   {IN_PIPE=>$in_g1},
	  {OUT => join(',',10..20) . "\n" .
		  "1,10,11,12,13,2,3,4,5,6,7,8,9\n" . #not yet natural-order
		  join(',',66..99) . "\n" }],
  ['g12', 'uniquenc 1',   {IN_PIPE=>$in_g1},
	  {OUT => join(',',10..20) . "\n" .
		  "1,10,11,12,13,2,3,4,5,6,7,8,9\n" . #not yet natural-order
		  join(',',66..99) . "\n" }],
  ['g13', 'collapse 1',   {IN_PIPE=>$in_g1},
	  {OUT => join(',',10..20) . "\n" .
		  join(',',1..13) . "\n" .
		  join(',',66..99) . "\n" }],
  # on a different architecture, would printf(%Lg) print something else?
  # Use OUT_SUBST to trim output to 1.3 digits
  ['g14', 'mean 1',     {IN_PIPE=>$in_g1},  {OUT => "15\n7\n82.5\n"},
	  {OUT_SUBST=>'s/^(\d+\.\d{3}).*/\1/'}],
  ['g15', 'pstdev 1',   {IN_PIPE=>$in_g1},  {OUT => "3.162\n3.741\n9.810\n"},
	  {OUT_SUBST=>'s/^(\d+\.\d{3}).*/\1/'}],
  ['g16', 'sstdev 1',   {IN_PIPE=>$in_g1},  {OUT => "3.316\n3.894\n9.958\n"},
	  {OUT_SUBST=>'s/^(\d+\.\d{3}).*/\1/'}],
  ['g17', 'pvar 1',     {IN_PIPE=>$in_g1},  {OUT => "10\n14\n96.25\n"},
	  {OUT_SUBST=>'s/^(\d+\.\d{3}).*/\1/'}],
  ['g18', 'svar 1',     {IN_PIPE=>$in_g1},  {OUT => "11\n15.166\n99.166\n"},
	  {OUT_SUBST=>'s/^(\d+\.\d{3}).*/\1/'}],


);

my $save_temps = $ENV{SAVE_TEMPS};
my $verbose = $ENV{VERBOSE};

my $fail = run_tests ($program_name, $prog, \@Tests, $save_temps, $verbose);
exit $fail;
