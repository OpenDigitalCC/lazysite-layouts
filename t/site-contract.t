#!/usr/bin/perl
# site-contract.t - every catalogue layout must be able to carry a real site.
#
# Renders each layouts/<L>/layout.tt with Template Toolkit against a stash
# shaped exactly as the lazysite engine builds it (page_title, page_subtitle,
# page_meta_title, page_meta_desc arrive HTML-escaped; site_name arrives raw;
# auth_control is the engine's SM099 cache-safe pair), then asserts the
# contract from inbox/2026-08-15-bringing-the-catalogue-up-to-date.md and
# inbox/2026-08-15-head-meta-contract.md:
#
#   - <title> and the meta description reflect page_meta_title/page_meta_desc
#   - nothing double-escapes (no | html on the engine-escaped five)
#   - the site's navigation renders from [% nav %]: labels, URLs, one level of
#     children, a group label, and an active class on the current page
#   - a mobile navigation control (aria-expanded) is present
#   - share cards (og:/twitter:) and a canonical link are emitted
#   - the cache-safe auth control is emitted (data-ls-auth-in)
#   - the last-updated <time> stamp renders
#   - the page body renders
#
# A layout whose layout.json declares "kind": "demonstration" is exempt from
# the site items (nav, toggle, cards, canonical, auth, time) but must still
# render the body and satisfy the head-meta contract.
#
# The tree is walked with readdir, never a glob (upstream t/lint/46 lesson).
use strict;
use warnings;
use Test::More;
use FindBin  ();
use JSON::PP ();
use Template ();

my $root = "$FindBin::Bin/..";
my $ldir = "$root/layouts";

# The stash mirrors the engine: the five page_* strings are pre-escaped by
# _esc_html at the single point they enter (so ' is already &#39;); emitting
# them through | html again is the double-escape the contract forbids.
my $ESC_SUBTITLE = 'Client&#39;s brief &amp; co';
my %stash        = (
    site_name    => 'Fixture Site',
    site_url     => 'https://fixture.example',
    request_uri  => '/docs/guide',
    nav          => [
        { label => 'Home', url => '/',  children => [] },
        {   label    => 'Docs',
            url      => '',
            children => [ { label => 'Guide', url => '/docs/guide' } ],
        },
    ],
    page_title        => 'Fixture Page Title',
    page_subtitle     => $ESC_SUBTITLE,
    page_meta_title   => 'Fixture Meta Title',
    page_meta_desc    => $ESC_SUBTITLE,
    page_author       => '',
    content           => '<p>UNIQUE-BODY-MARKER-93157</p>',
    page_modified     => '17 August 2026',
    page_modified_iso => '2026-08-17',
    theme_css         => "<style>:root { --theme-colours-text: #000; }</style>",
    theme_assets      => '/lazysite-assets/fixture/fixture',
    auth_control      =>
        '<a href="/login" data-ls-auth-in class="ls-auth ls-auth-in" style="display:none">Sign in</a>'
        . '<a href="/cgi-bin/lazysite-auth.pl?action=logout" data-ls-auth-out class="ls-auth ls-auth-out" style="display:none">Sign out</a>',
    sections       => [],
    year           => '2026',
    authenticated  => 0,
    auth_user      => '',
    auth_name      => '',
    auth_groups    => [],
    site_lang      => 'en',
    page_lang      => '',
    languages      => [],
    t              => {},
    nav_file       => 'nav.conf',
    layout_name    => 'fixture',
    theme_name     => 'fixture',
    manager        => '',
    manager_path   => '',
    search_enabled => 0,
    editor         => 0,
);

sub read_json {
    my ($path) = @_;
    open my $fh, '<:utf8', $path or return undef;
    my $raw = do { local $/; <$fh> };
    close $fh;
    return eval { JSON::PP->new->decode($raw) };
}

opendir my $dh, $ldir or die "read $ldir: $!\n";
my @layouts = sort grep { !/^\./ && -f "$ldir/$_/layout.tt" } readdir $dh;
closedir $dh;
ok( scalar @layouts >= 23, 'walked the layouts tree (' . @layouts . ' found)' );

for my $L (@layouts) {
    my $lj   = read_json("$ldir/$L/layout.json") || {};
    my $demo = ( $lj->{kind} // '' ) eq 'demonstration';

    subtest $L => sub {
        my $src = do {
            open my $fh, '<:utf8', "$ldir/$L/layout.tt" or die "read: $!";
            local $/;
            <$fh>;
        };
        unlike(
            $src,
            qr/page_(?:title|subtitle|author|meta_title|meta_desc)\s*\|\s*html/,
            'no | html on the engine-escaped page_* variables'
        );

        my $tt = Template->new( { INCLUDE_PATH => "$ldir/$L" } );
        my $out = '';
        my $ok = $tt->process( 'layout.tt', {%stash}, \$out );
        (ok( $ok, 'template renders' )) or diag( $tt->error ), return;

        # -- head-meta contract (all layouts, demonstration included) --
        like( $out, qr{<title>[^<]*Fixture Meta Title}, '<title> reflects page_meta_title' );
        like(
            $out,
            qr{<meta name="description" content="\Q$ESC_SUBTITLE\E">},
            'description reflects page_meta_desc, single-escaped'
        );
        unlike( $out, qr{&amp;#39;|&amp;amp;}, 'nothing double-escapes' );
        like( $out, qr{UNIQUE-BODY-MARKER-93157}, 'page body renders' );
        like(
            $out,
            qr{<link rel="icon" href="/lazysite-assets/fixture/fixture/favicon\.svg"},
            'default favicon declared from theme assets'
        );

        return if $demo;

        # -- a markdown page's heading renders (demo pages use sections) --
        like( $out, qr{>Fixture Page Title<}, 'page title renders as the page heading' );

        # -- navigation from [% nav %] --
        like( $out, qr{<a[^>]*href="/"[^>]*>Home</a>}, 'top-level nav item renders' );
        like( $out, qr{>Docs<},                        'parent group label renders' );
        like( $out, qr{<a[^>]*href="/docs/guide"[^>]*>Guide</a>}, 'child nav item renders' );
        like(
            $out,
            qr{<a(?=[^>]*href="/docs/guide")(?=[^>]*\bactive\b)[^>]*>},
            'current page carries the active class'
        );
        like( $out, qr{aria-expanded=}, 'mobile navigation control present' );

        # -- share cards + canonical --
        like( $out, qr{<link rel="canonical" href="https://fixture\.example/docs/guide">},
            'canonical link' );
        like( $out, qr{property="og:title" content="Fixture Meta Title"}, 'og:title' );
        like( $out, qr{property="og:description" content="\Q$ESC_SUBTITLE\E"},
            'og:description' );
        like( $out, qr{property="og:site_name" content="Fixture Site"}, 'og:site_name' );
        like( $out, qr{name="twitter:card"}, 'twitter:card' );

        # -- cache-safe auth + last-updated --
        like( $out, qr{data-ls-auth-in},  'cache-safe auth control emitted' );
        like( $out, qr{<time[^>]*datetime="2026-08-17"}, 'last-updated stamp' );
    };
}

done_testing();
