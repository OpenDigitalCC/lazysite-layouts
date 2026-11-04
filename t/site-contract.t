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
# and the template contract of docs/WORK-PLAN-2026-11-04.md (W1-A), from the
# 2026-09-11, 2026-10-01, 2026-10-12, 2026-10-18 and 2026-10-19 filings:
#
#   - every whole-value link target (layout and components) ends in | url_safe
#   - every stylesheet or script link into theme_assets carries ?v=theme_version
#   - canonical and og:url come from page_url, not site_url + request_uri
#   - RSS and Atom autodiscovery in <head> with distinct titles, plus a footer link
#   - odoo_signin_banner renders, and replaces the layout's own sign-out link
#   - layout.json states requires.lazysite (at least 0.15.11)
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
    theme_version     => 'fp12345',
    page_url          => 'https://canonical.example/docs/guide',
    odoo_signin_banner => '',
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

# The engine registers url_safe on every Template object (0.15.3): a value with
# no scheme, or http/https/mailto/tel, passes; any other scheme becomes '#'.
sub url_safe_filter {
    my ($v) = @_;
    return $v unless $v =~ m{^\s*[a-z][a-z0-9+.-]*:}i;
    return $v if $v =~ m{^\s*(?:https?|mailto|tel):}i;
    return '#';
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:utf8', $path or die "read $path: $!";
    local $/;
    return scalar <$fh>;
}

sub version_ge {
    my ( $have, $want ) = @_;
    my @h = split /\./, $have;
    my @w = split /\./, $want;
    for my $i ( 0 .. 2 ) {
        return 1 if ($h[$i] // 0) > ($w[$i] // 0);
        return 0 if ($h[$i] // 0) < ($w[$i] // 0);
    }
    return 1;
}

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

        my $tt = Template->new(
            { INCLUDE_PATH => "$ldir/$L", FILTERS => { url_safe => sub { url_safe_filter($_[0]) } } } );
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

        # -- template contract (all layouts, demonstration included) --
        my @tt_files = ("$ldir/$L/layout.tt");
        if ( opendir my $cd, "$ldir/$L/components" ) {
            push @tt_files, map {"$ldir/$L/components/$_"} sort grep { /\.tt$/ } readdir $cd;
            closedir $cd;
        }
        for my $tf (@tt_files) {
            my $text = slurp($tf);
            ( my $short = $tf ) =~ s{^\Q$ldir\E/}{};
            my @bad = $text =~ m{((?:href|src|action|formaction|poster)="\[%(?![^%]*\|\s*url_safe)[^%]*%\]")}g;
            @bad = grep { $_ !~ m{"\[%\s*(?:l\.url|languages\.0\.url|site_url|page_url)\s*%\]"} } @bad;
            is( scalar @bad, 0, "$short: every whole-value link target has | url_safe" )
                or diag( join "\n", @bad );
        }
        like( $src, qr{\[%\s*page_url\s*%\]}, 'page_url used' );
        unlike( $src, qr{site_url\s*\|\s*html\s*%\]\[%\s*request_uri}, 'no site_url + request_uri address' );
        unlike( $src, qr{<(?:link|script)[^>]*\[%\s*theme_assets\s*%\]/[\w.-]+\.(?:css|js)"}, 'no unversioned theme-asset link' );

        my ($head) = $out =~ m{^(.*?)</head>}s;
        my @assets = $head =~ m{(?:href|src)="(/lazysite-assets/fixture/fixture/[\w.-]+\.(?:css|js)[^"]*)"}g;
        ok( scalar @assets, 'head links theme assets' );
        is( scalar( grep { !/\?v=fp12345$/ } @assets ), 0, 'every theme-asset stylesheet/script carries ?v=theme_version' )
            or diag("@assets");
        like( $head, qr{<link rel="canonical" href="https://canonical\.example/docs/guide">}, 'canonical from page_url' );
        like( $head, qr{<meta property="og:url" content="https://canonical\.example/docs/guide">}, 'og:url from page_url' );
        unlike( $head, qr{fixture\.example/docs/guide}, 'site_url + request_uri not used for the address' );
        like(
            $head,
            qr{<link rel="alternate" type="application/rss\+xml" title="Fixture Site \(RSS\)" href="/feed\.rss">},
            'RSS autodiscovery in head'
        );
        like(
            $head,
            qr{<link rel="alternate" type="application/atom\+xml" title="Fixture Site \(Atom\)" href="/feed\.atom">},
            'Atom autodiscovery in head'
        );
        my ($foot) = $out =~ m{(<footer.*?</footer>)}s;
        ok( defined $foot && $foot =~ m{href="/feed\.rss"} && $foot =~ m{href="/feed\.atom"}, 'footer links to both feeds' );

        # -- Odoo sign-in banner: rendered, and the layout's own sign-out yields --
        {
            my $banner = '<span data-fixture-odoo-banner>Signed in as Fixture</span>';
            my $bout   = '';
            $tt->process( 'layout.tt', { %stash, odoo_signin_banner => $banner }, \$bout )
                or diag( $tt->error );
            like( $bout, qr{\Q$banner\E}, 'odoo_signin_banner renders when set' );
            unlike( $bout, qr{action=logout|data-ls-auth-out}, 'own sign-out link not shown beside the banner' );
            unlike( $out, qr{data-fixture-odoo-banner}, 'no banner markup when the variable is empty' );
        }

        # -- engine compatibility declared --
        my $req = ref $lj->{requires} eq 'HASH' ? $lj->{requires}{lazysite} : undef;
        ok( defined $req && $req =~ /^\d+\.\d+\.\d+$/ && version_ge( $req, '0.15.11' ),
            'layout.json requires.lazysite is 0.15.11 or later' );

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
        like( $out, qr{<link rel="canonical" href="https://canonical\.example/docs/guide">},
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
