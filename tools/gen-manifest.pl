#!/usr/bin/perl
# gen-manifest.pl - write manifest.json at the repo root from what is on disk.
#
# Enumerates every layout (a layouts/<L>/ dir with layout.tt + layout.json) and,
# for each, the themes it declares (layout.json.themes[], falling back to a walk
# of layouts/<L>/themes/*/). Emits repo-relative package paths matching what
# package-themes.sh / the layout-packaging step produce:
#
#   layout package: releases/layouts/<L>.zip
#   theme  package: releases/<L>/<T>.zip
#
# Output is canonical (sorted keys) so re-runs don't churn the file. Run from
# the repo root, or pass the root as $ARGV[0]; writes ./manifest.json.
use strict;
use warnings;
use JSON::PP ();
use POSIX qw(strftime);

my $root = $ARGV[0] || '.';
my $ldir = "$root/layouts";
die "no layouts dir under $root\n" unless -d $ldir;

sub read_json {
    my ($path) = @_;
    open my $fh, '<:utf8', $path or return undef;
    my $raw = do { local $/; <$fh> };
    close $fh;
    return eval { JSON::PP->new->decode($raw) };
}

my @layouts;
opendir my $dh, $ldir or die "read $ldir: $!";
for my $L ( sort readdir $dh ) {
    next if $L =~ /^\./;
    my $ldir_l = "$ldir/$L";
    next unless -f "$ldir_l/layout.tt" && -f "$ldir_l/layout.json";

    my $lj = read_json("$ldir_l/layout.json") || {};
    my $name = ( defined $lj->{name} && length $lj->{name} ) ? $lj->{name} : $L;

    # Theme names: prefer the declared forward index; else walk themes/.
    my @theme_names;
    if ( ref $lj->{themes} eq 'ARRAY' && @{ $lj->{themes} } ) {
        @theme_names = @{ $lj->{themes} };
    }
    elsif ( -d "$ldir_l/themes" ) {
        opendir my $td, "$ldir_l/themes" or next;
        @theme_names = sort grep { !/^\./ && -f "$ldir_l/themes/$_/theme.json" }
            readdir $td;
        closedir $td;
    }

    my @themes;
    for my $T (@theme_names) {
        my $tj_path = "$ldir_l/themes/$T/theme.json";
        next unless -f $tj_path;    # only list themes that actually exist
        my $tj = read_json($tj_path) || {};
        push @themes, {
            name    => ( defined $tj->{name} && length $tj->{name} ) ? $tj->{name} : $T,
            version => $tj->{version} // '0.0.0',
            package => "releases/$L/$T.zip",
        };
    }

    push @layouts, {
        name          => $name,
        version       => $lj->{version} // '0.0.0',
        package       => "releases/layouts/$L.zip",
        default_theme => $lj->{default_theme}
            // ( @theme_names ? $theme_names[0] : '' ),
        themes        => \@themes,
    };
}
closedir $dh;

my $manifest = {
    schema    => 1,
    generated => strftime( '%Y-%m-%d', gmtime ),
    layouts   => \@layouts,
};

my $json = JSON::PP->new->canonical(1)->pretty->utf8->encode($manifest);
open my $out, '>:raw', "$root/manifest.json" or die "write manifest: $!";
print {$out} $json;
close $out;
print STDERR "wrote manifest.json: " . scalar(@layouts) . " layouts\n";
