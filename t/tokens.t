#!/usr/bin/perl
# tokens.t - repo lint: every layout's declared layout.json "tokens" block
# must match a fresh scan of its default theme's main.css (SM203). Run from
# anywhere: prove t/ or perl t/tokens.t.
use strict;
use warnings;
use Test::More tests => 1;
use FindBin ();

my $root = "$FindBin::Bin/..";
my $rc = system( $^X, "$root/tools/gen-tokens.pl", '--check', $root );
(is( $rc, 0, 'declared layout tokens match default-theme CSS' ));
