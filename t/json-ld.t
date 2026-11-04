#!/usr/bin/perl
# json-ld.t - the bio family emits a schema.org Person block from bio-hero.
#
# Renders layouts/<bio-*>/layout.tt with Template Toolkit against a stash that
# carries a bio-hero section whose values hold a double quote, an apostrophe,
# an ampersand, a newline and a closing script tag; extracts the
# application/ld+json block, parses it with JSON::PP and checks each field.
# A render with no bio-hero section must emit no block, and a hero with only a
# name must emit a name and nothing empty.
use strict;
use warnings;
use Test::More;
use FindBin  ();
use JSON::PP ();
use Template ();

my $ldir = "$FindBin::Bin/../layouts";

# The engine's filters (lazysite-processor/include.pm): _json_filter (SM824,
# 0.15.2) and _url_safe_filter (SM970, 0.15.3), reproduced here.
sub json_filter {
    my ($text) = @_;
    return '""' unless defined $text;
    return '""' if ref $text;
    my $s = "$text";
    $s =~ s/\\/\\\\/g;
    $s =~ s/"/\\"/g;
    $s =~ s/\x08/\\b/g;
    $s =~ s/\f/\\f/g;
    $s =~ s/\n/\\n/g;
    $s =~ s/\r/\\r/g;
    $s =~ s/\t/\\t/g;
    $s =~ s/([\x00-\x1f])/sprintf '\\u%04x', ord $1/ge;
    $s =~ s/</\\u003c/g;
    $s =~ s/>/\\u003e/g;
    $s =~ s/&/\\u0026/g;
    return '"' . $s . '"';
}

sub url_safe_filter {
    my ($v) = @_;
    return $v unless $v =~ m{^\s*[a-z][a-z0-9+.-]*:}i;
    return $v if $v =~ m{^\s*(?:https?|mailto|tel):}i;
    return '#';
}

my $NAME    = qq{Ann "Q" O'Neil & Co\n</script><img src=x onerror=alert(1)>};
my $ROLE    = q{Head of R&D, "Ops"};
my $TAGLINE = qq{Line one\nLine two: it's </script> & more};
my $ORG     = q{Smith & Sons "Ltd"};

my %base = (
    site_name         => 'Fixture Site',
    site_url          => 'https://fixture.example',
    request_uri       => '/',
    nav               => [],
    page_title        => 'Fixture',
    page_subtitle     => '',
    page_meta_title   => 'Fixture',
    page_meta_desc    => '',
    content           => '',
    page_modified     => '',
    page_modified_iso => '',
    theme_css         => '',
    theme_assets      => '/lazysite-assets/f/f',
    theme_version     => 'v1',
    page_url          => 'https://fixture.example/a&amp;b/',
    odoo_signin_banner => '',
    auth_control      => '',
    year              => '2026',
);

my @hero_sections = (
    {   'bio-hero' => {
            name    => $NAME,
            role    => $ROLE,
            tagline => $TAGLINE,
            avatar  => 'AO',
            links   => [ { label => 'Employer', href => 'https://emp.example/' } ],
            worksFor => { name => $ORG, url => 'https://org.example/' },
            sameAs   => [
                'https://profile.example/ann?x=1&y=2',
                'javascript:alert(1)',
                'https://other.example/ann',
            ],
        }
    },
    { 'bio-work' => { heading => 'Work', items => [] } },
);

sub render {
    my ( $layout, $sections ) = @_;
    my $tt = Template->new(
        {   INCLUDE_PATH => "$ldir/$layout",
            FILTERS      => {
                json     => sub { json_filter( $_[0] ) },
                url_safe => sub { url_safe_filter( $_[0] ) },
            },
        }
    );
    my $out = '';
    $tt->process( 'layout.tt', { %base, sections => $sections }, \$out )
        or die $tt->error;
    return $out;
}

sub blocks {
    my ($html) = @_;
    return $html =~ m{<script type="application/ld\+json">(.*?)</script>}gs;
}

for my $L (qw(bio-modest bio-balanced bio-bold)) {
    subtest $L => sub {
        my $out = render( $L, \@hero_sections );
        my @b = blocks($out);
        is( scalar @b, 1, 'exactly one ld+json block' ) or return;
        unlike( $b[0], qr{</?script|<img}i, 'no markup survives inside the block' );
        my $d = eval { JSON::PP->new->decode( $b[0] ) };
        ok( $d, 'block parses as JSON' ) or diag($@), return;
        is( $d->{'@context'}, 'https://schema.org', '@context' );
        is( $d->{'@type'},    'Person',             '@type' );
        is( $d->{name},       $NAME,                'name round-trips exactly' );
        is( $d->{jobTitle},   $ROLE,                'jobTitle from role' );
        is( $d->{description}, $TAGLINE,            'description from tagline' );
        is( $d->{url}, 'https://fixture.example/a&b/', 'url is page_url, decoded once' );
        is_deeply(
            $d->{worksFor},
            { '@type' => 'Organization', name => $ORG, url => 'https://org.example/' },
            'worksFor organisation'
        );
        is_deeply(
            $d->{sameAs},
            [ 'https://profile.example/ann?x=1&y=2', 'https://other.example/ann' ],
            'sameAs keeps http(s) addresses only'
        );
        ok( !exists $d->{image} && !exists $d->{email}, 'nothing invented' );

        # Only the first hero is read.
        my @two = ( @hero_sections, { 'bio-hero' => { name => 'Second' } } );
        is( scalar( () = blocks( render( $L, \@two ) ) ), 1, 'two heroes still emit one block' );

        # Name only: no empty fields.
        my $min = render( $L, [ { 'bio-hero' => { name => 'Solo', role => '  ', tagline => '', links => [] } } ] );
        my ($mb) = blocks($min);
        my $md = JSON::PP->new->decode($mb);
        is_deeply(
            [ sort keys %$md ],
            [ sort ( '@context', '@type', 'name', 'url' ) ],
            'empty and blank fields are omitted'
        );

        # worksFor without a name, sameAs given as one string.
        my $odd = render( $L, [ { 'bio-hero' => { name => 'Odd', worksFor => { url => 'https://x.example/' }, sameAs => 'https://one.example/' } } ] );
        my $od = JSON::PP->new->decode( ( blocks($odd) )[0] );
        ok( !exists $od->{worksFor}, 'worksFor without a name is omitted' );
        is_deeply( $od->{sameAs}, ['https://one.example/'], 'a single sameAs string is a list of one' );

        # No site address: no url.
        my $nu = JSON::PP->new->decode(
            ( blocks( do { local $base{page_url} = ''; render( $L, [ { 'bio-hero' => { name => 'N' } } ] ) } ) )[0] );
        ok( !exists $nu->{url}, 'no url without page_url' );

        # No hero data: no block.
        is( scalar( () = blocks( render( $L, [] ) ) ), 0, 'no sections: no block' );
        is( scalar( () = blocks( render( $L, [ { 'bio-work' => {} } ] ) ) ), 0, 'no bio-hero: no block' );
        is( scalar( () = blocks( render( $L, [ { 'bio-hero' => { role => 'x' } } ] ) ) ), 0, 'hero without a name: no block' );
    };
}

done_testing();
