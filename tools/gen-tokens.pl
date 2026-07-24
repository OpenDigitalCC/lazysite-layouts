#!/usr/bin/perl
# gen-tokens.pl - declare each layout's consumed theme-token vocabulary (SM203).
#
# For every layouts/<L>/ (a dir with layout.tt + layout.json) it scans the
# layout's DEFAULT theme CSS - layouts/<L>/themes/<default_theme>/assets/main.css
# - for `var(--theme-<group>-<key>)` references and writes the result into that
# layout's layout.json as an optional "tokens" block, grouped as the theme
# config is:
#
#   "tokens": {
#     "colours": ["accent", "border", "text-muted", ...],
#     "fonts":   ["body", "display"]
#   }
#
# The block is DECLARATIVE documentation-as-data: the engine reads it to warn
# (never reject) when an activated theme does not supply the full vocabulary.
# Only the identity groups (colours, fonts) are declared - lazysite keeps
# rhythm/scale in CSS, so spacing/type-scale tokens are deliberately excluded
# even where legacy CSS consumes them; anything skipped is reported on stderr.
#
# Modes:
#   perl tools/gen-tokens.pl [ROOT]           rewrite layout.json tokens blocks
#   perl tools/gen-tokens.pl --check [ROOT]   verify committed blocks match a
#                                             fresh scan; exit 1 on any drift
#
# Both modes share the one extraction path, so the lint cannot drift from the
# generator. Edits are text-level and touch only the "tokens" span - the rest
# of layout.json is preserved byte-for-byte.
use strict;
use warnings;
use JSON::PP ();

my @DECLARED_GROUPS = qw(colours fonts);

my $check = 0;
my @args;
for (@ARGV) {
    if ( $_ eq '--check' ) { $check = 1 }
    else                   { push @args, $_ }
}
my $root = $args[0] || '.';
my $ldir = "$root/layouts";
die "no layouts dir under $root\n" unless -d $ldir;

sub slurp {
    my ($path) = @_;
    open my $fh, '<:utf8', $path or die "read $path: $!\n";
    my $raw = do { local $/; <$fh> };
    close $fh;
    return $raw;
}

# Scan a CSS file for var(--theme-<group>-<key>) references. Keys may span
# several hyphenated segments (text-muted, accent-2) - capture the whole tail,
# then split off the leading group segment.
sub scan_css {
    my ($css_path, $layout) = @_;
    my $css = slurp($css_path);
    my ( %vocab, %skipped );
    while ( $css =~ /var\(\s*--theme-([a-z0-9]+(?:-[a-z0-9]+)*)/g ) {
        my $tail = $1;
        my ( $group, $key ) = $tail =~ /^([a-z0-9]+)-([a-z0-9-]+)$/;
        unless ( defined $key ) {
            warn "$layout: skipping single-segment token --theme-$tail\n";
            next;
        }
        if ( grep { $_ eq $group } @DECLARED_GROUPS ) {
            $vocab{$group}{$key} = 1;
        }
        else {
            $skipped{"$group-$key"} = 1;
        }
    }
    warn "$layout: not declaring non-identity token(s): "
        . join( ', ', sort keys %skipped ) . "\n"
        if %skipped;
    return { map { $_ => [ sort keys %{ $vocab{$_} } ] } keys %vocab };
}

# Render the tokens block in the repo's 2-space layout.json style.
sub render_block {
    my ($vocab) = @_;
    my @groups = sort keys %$vocab;
    my $out    = qq("tokens": {\n);
    for my $i ( 0 .. $#groups ) {
        my $g    = $groups[$i];
        my $keys = join ', ', map { qq{"$_"} } @{ $vocab->{$g} };
        $out .= qq{    "$g": [$keys]};
        $out .= ',' if $i < $#groups;
        $out .= "\n";
    }
    $out .= '  }';
    return $out;
}

my $json     = JSON::PP->new->canonical(1);
my $failures = 0;
my $written  = 0;

opendir my $dh, $ldir or die "read $ldir: $!\n";
for my $L ( sort grep { !/^\./ } readdir $dh ) {
    my $lpath = "$ldir/$L";
    next unless -f "$lpath/layout.tt" && -f "$lpath/layout.json";

    my $raw = slurp("$lpath/layout.json");
    my $lj  = eval { $json->decode($raw) };
    die "$L: layout.json does not parse: $@" unless $lj;

    my $dt = $lj->{default_theme};
    die "$L: no default_theme in layout.json\n"
        unless defined $dt && length $dt;
    my $css = "$lpath/themes/$dt/assets/main.css";
    die "$L: default theme CSS missing: $css\n" unless -f $css;

    my $vocab = scan_css( $css, $L );

    if ($check) {
        my $got = $lj->{tokens};
        unless ( ref $got eq 'HASH' ) {
            warn "$L: FAIL - no tokens block declared\n";
            $failures++;
            next;
        }
        my $want_c = $json->encode($vocab);
        my $got_c  = $json->encode($got);
        if ( $want_c ne $got_c ) {
            warn "$L: FAIL - declared tokens drift from $dt CSS\n";
            warn "$L:   declared: $got_c\n";
            warn "$L:   scanned:  $want_c\n";
            $failures++;
        }
        next;
    }

    my $block = render_block($vocab);
    my $new   = $raw;
    if ( $new =~ /"tokens"\s*:\s*\{[^{}]*\}/s ) {
        $new =~ s/"tokens"\s*:\s*\{[^{}]*\}/$block/s;
    }
    else {
        $new =~ s/\n\}\s*\z/,\n  $block\n}\n/
            or die "$L: could not find closing brace to insert tokens\n";
    }

    my $reparsed = eval { $json->decode($new) };
    die "$L: edited layout.json no longer parses: $@" unless $reparsed;

    if ( $new ne $raw ) {
        open my $out, '>:utf8', "$lpath/layout.json"
            or die "write $lpath/layout.json: $!\n";
        print {$out} $new;
        close $out;
        $written++;
        my $summary = join ', ',
            map { $_ . '=' . scalar @{ $vocab->{$_} } } sort keys %$vocab;
        print "$L: tokens written ($summary)\n";
    }
    else {
        print "$L: unchanged\n";
    }
}
closedir $dh;

if ($check) {
    if ($failures) {
        warn "check-tokens: $failures layout(s) drifted - rerun tools/gen-tokens.pl\n";
        exit 1;
    }
    print "check-tokens: all layouts match their default theme CSS\n";
    exit 0;
}
print STDERR "gen-tokens: $written layout.json file(s) updated\n";
