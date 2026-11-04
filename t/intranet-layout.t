#!/usr/bin/perl
# intranet-layout.t - the intranet layout and its theme.
#
# t/site-contract.t renders intranet with every other layout. This file holds
# what is particular to a private working surface (docs/layouts/intranet.md):
#
#   - the gate bar, breadcrumbs built from the request path, a sidebar with
#     nested groups and the current page marked, the Menu button
#   - the Odoo banner replaces the sign-in links; without it, the cache-safe pair
#   - base.css, then fonts.css, then main.css, each versioned
#   - page_width reaches the page as a class
#   - the theme answers light and dark the catalogue way, and styles the
#     vocabulary the document names
#   - fonts come from the store with a licence; no external address anywhere
#   - layout.json and theme.json state requires; nothing is marked demonstration
#
# The tree is walked with readdir, never a glob (upstream t/lint/46 lesson).
use strict;
use warnings;
use Test::More;
use FindBin  ();
use JSON::PP ();
use Template ();

my $root = "$FindBin::Bin/..";
my $ldir = "$root/layouts/intranet";
my $tdir = "$ldir/themes/intranet";

sub slurp {
    my ($path) = @_;
    open my $fh, '<:utf8', $path or return undef;
    local $/;
    my $t = <$fh>;
    close $fh;
    return $t;
}

sub read_json {
    my $raw = slurp( $_[0] );
    return undef unless defined $raw;
    return eval { JSON::PP->new->decode($raw) };
}

sub version_ge {
    my ( $have, $want ) = @_;
    my @h = split /\./, $have;
    my @w = split /\./, $want;
    for my $i ( 0 .. 2 ) {
        return 1 if ( $h[$i] // 0 ) > ( $w[$i] // 0 );
        return 0 if ( $h[$i] // 0 ) < ( $w[$i] // 0 );
    }
    return 1;
}

sub tree {
    my ($dir) = @_;
    my @out;
    opendir my $dh, $dir or return @out;
    for my $e ( sort grep { !/^\./ } readdir $dh ) {
        my $p = "$dir/$e";
        if   ( -d $p ) { push @out, tree($p) }
        else           { push @out, $p }
    }
    closedir $dh;
    return @out;
}

sub url_safe_filter {
    my ($v) = @_;
    return $v unless $v =~ m{^\s*[a-z][a-z0-9+.-]*:}i;
    return $v if $v =~ m{^\s*(?:https?|mailto|tel):}i;
    return '#';
}

my %stash = (
    site_name    => 'Fixture Site',
    request_uri  => '/docs/guide/step',
    nav          => [
        { label => 'Home', url => '/', children => [] },
        {   label    => 'Docs',
            url      => '',
            children => [
                { label => 'Guide',  url => '/docs/guide' },
                { label => 'Step',   url => '/docs/guide/step' },
            ],
        },
        { label => 'Reports', url => '/reports', children => [ { label => 'March', url => '/reports/march' } ] },
    ],
    page_title        => 'Fixture Page Title',
    page_subtitle     => 'A subtitle',
    page_meta_title   => 'Fixture Meta Title',
    page_meta_desc    => 'A description',
    content           => '<p>UNIQUE-BODY-MARKER-71204</p>',
    page_modified     => '4 November 2026',
    page_modified_iso => '2026-11-04',
    theme_css         => '<style>:root { --theme-colours-ink: #000; }</style>',
    theme_assets      => '/lazysite-assets/intranet/intranet',
    theme_version     => 'fp12345',
    page_url          => 'https://intranet.example/docs/guide/step',
    odoo_signin_banner => '',
    auth_control      =>
        '<a href="/login" data-ls-auth-in class="ls-auth ls-auth-in" style="display:none">Sign in</a>'
        . '<a href="/cgi-bin/lazysite-auth.pl?action=logout" data-ls-auth-out class="ls-auth ls-auth-out" style="display:none">Sign out</a>',
    manager      => '',
    manager_path => '',
);

my $tt = Template->new(
    { INCLUDE_PATH => $ldir, FILTERS => { url_safe => sub { url_safe_filter( $_[0] ) } } } );
sub render {
    my (%over) = @_;
    my $out = '';
    $tt->process( 'layout.tt', { %stash, %over }, \$out ) or diag( $tt->error );
    return $out;
}

ok( -f "$ldir/layout.tt", 'layouts/intranet/layout.tt exists' );
my $src = slurp("$ldir/layout.tt") // '';
my $out = render();
my ($head) = $out =~ m{^(.*?)</head>}s;

# -- the gate bar --
like( $out, qr{<header class="in-bar">.*?<a class="in-home" href="/">Fixture Site</a>.*?data-ls-auth-in.*?</header>}s,
    'the gate bar carries the site name and the sign-in' );
unlike( $out, qr{>\s*Private\s*<}, 'the bar carries no PRIVATE label (the dark bar says it)' );
like( $out, qr{<button[^>]*data-in-menu[^>]*aria-expanded="false"[^>]*aria-controls="in-side"}, 'Menu button controls the section nav' );
like( $out, qr{<a class="in-skip" href="#main">}, 'skip link' );
like( $out, qr{<main class="in-main" id="main">}, 'main landmark' );

# -- breadcrumbs --
my ($crumbs) = $out =~ m{(<nav class="in-crumbs".*?</nav>)}s;
ok( defined $crumbs, 'breadcrumb nav present' );
like( $crumbs, qr{aria-label="Breadcrumb"}, 'breadcrumb is labelled' );
like( $crumbs, qr{<li><a href="/">Home</a></li>}, 'first crumb is home' );
like( $crumbs, qr{<li><a href="/docs/">Docs</a></li>}, 'a segment that is not in the nav is the segment, capitalised' );
like( $crumbs, qr{<li><a href="/docs/guide/">Guide</a></li>}, 'a segment that is a nav address takes the nav label' );
like( $crumbs, qr{<li aria-current="page">Fixture Page Title</li>}, 'the last crumb is the page, not a link' );
my $home = render( request_uri => '/' );
like( $home, qr{<li aria-current="page">Home</li>}, 'at the root the only crumb is Home, not a link' );
my $query = render( request_uri => '/docs/guide?x=1' );
like( $query, qr{<a href="/docs/">Docs</a></li>\s*<li aria-current="page">Fixture Page Title}, 'a query string is not part of the crumbs' );

# -- nested nav --
my ($side) = $out =~ m{(<nav class="in-side".*?</nav>)}s;
ok( defined $side, 'section nav present' );
like( $side, qr{<li class="in-group">\s*<span class="in-group-label">Docs</span>\s*<ul class="in-nav-children">}s,
    'a parent with no address is a group label over its children' );
like( $side, qr{<li class="in-group">\s*<a href="/reports">Reports</a>\s*<ul class="in-nav-children">}s,
    'a parent with an address is a link over its children' );
like( $side, qr{<a href="/docs/guide">Guide</a>}, 'a child renders' );
like( $side, qr{<a href="/docs/guide/step" class="active" aria-current="page">Step</a>}, 'the current page is active and aria-current' );
unlike( $side, qr{<a href="/docs/guide" class="active"}, 'only the current page is active' );
like( $side, qr{<a href="/">Home</a>}, 'a plain item renders' );

# -- sign-in: the Odoo banner replaces the links --
{
    my $banner = '<span data-fixture-odoo-banner>Signed in as Fixture</span>';
    my $b = render( odoo_signin_banner => $banner );
    like( $b, qr{<div class="in-tools">\s*\Q$banner\E}, 'the Odoo banner sits in the bar' );
    unlike( $b, qr{data-ls-auth|action=logout}, 'no sign-in or sign-out link of the layout\'s own beside the banner' );
    like( $out, qr{<div class="in-tools">\s*<a href="/login" data-ls-auth-in}, 'without the banner, the cache-safe pair' );
}

# -- stylesheets, in order, versioned --
like( $head, qr{base\.css\?v=fp12345.*fonts\.css\?v=fp12345.*main\.css\?v=fp12345}s, 'head links base.css, fonts.css, main.css, in that order, each with ?v=theme_version' );
like( $src, qr{\[%\s*IF theme_assets\s*%\].*base\.css.*main\.css.*\[%\s*END\s*%\]}s, 'the sheets are linked inside IF theme_assets' );
like( $head, qr{<script src="/lazysite-assets/intranet/intranet/intranet\.js\?v=fp12345">}, 'the menu script is versioned' );
unlike( $src, qr{kind"?\s*[:=]\s*"?demonstration}i, 'layout.tt is not marked as a demonstration' );

# -- the width key --
unlike( $out, qr{<body[^>]*class=}, 'no width class by default' );
like( render( page_width => 'narrow' ), qr{<body class="in-narrow">}, 'width: narrow reaches the body' );
like( render( page_width => 'full' ),   qr{<body class="in-full">},   'width: full reaches the body' );
unlike( render( page_width => 'x"><script>' ), qr{<body[^>]*class=}, 'any other width is ignored' );

# -- footer --
like( $out, qr{<footer class="in-foot">.*<time datetime="2026-11-04">.*href="/feed\.rss" title="Fixture Site \(RSS\)".*href="/feed\.atom" title="Fixture Site \(Atom\)"}s,
    'footer has the time stamp and both feeds with their own titles' );

# -- no external address, no demonstration marker, anywhere in the tree --
my @files = tree($ldir);
ok( scalar @files >= 5, 'walked the layout tree (' . @files . ' files)' );
for my $p (@files) {
    next if $p =~ /\.(?:png|woff2?)$/;
    ( my $short = $p ) =~ s{^\Q$root\E/}{};
    my $t = slurp($p);
    next unless defined $t;
    my @urls = $t =~ m{(https?://[^\s"'<>)]+)}g;
    @urls = grep { $_ ne 'https://lazysite.io' } @urls;
    is( scalar @urls, 0, "$short has no external address" ) or diag("@urls");
    unlike( $t, qr{sovereign|jpm-stock|Family HQ}i, "$short names no site it came from" );
}

# -- layout.json --
my $lj = read_json("$ldir/layout.json") || {};
is( $lj->{name},    'intranet', 'layout.json name' );
is( $lj->{author},  'OpenDigitalCC', 'layout.json author' );
like( $lj->{version} // '', qr/^\d+\.\d+\.\d+$/, 'layout.json version is semver' );
is_deeply( $lj->{themes}, ['intranet'], 'layout.json lists the theme' );
is( $lj->{default_theme}, 'intranet', 'default theme' );
ok( !exists $lj->{kind}, 'not marked as a demonstration' );
ok( scalar @{ $lj->{tags} || [] }, 'layout.json has tags' );
my $lreq = ref $lj->{requires} eq 'HASH' ? $lj->{requires}{lazysite} : undef;
ok( defined $lreq && version_ge( $lreq, '0.15.11' ), 'layout.json requires lazysite 0.15.11 or later' );
ok( scalar @{ $lj->{tokens}{colours} || [] }, 'layout.json declares the colour tokens it consumes' );

# -- the theme --
my $tj = read_json("$tdir/theme.json") || {};
is( $tj->{name}, 'intranet', 'theme.json name matches its folder' );
is_deeply( $tj->{layouts}, ['intranet'], 'theme declares the intranet layout' );
my $treq = ref $tj->{requires} eq 'HASH' ? $tj->{requires}{lazysite} : undef;
ok( defined $treq && version_ge( $treq, '0.15.10' ), 'theme.json requires lazysite 0.15.10 or later' );
ok( ref $tj->{config}{dark} eq 'HASH', 'theme has a dark scheme (config.dark)' );
is_deeply( [ sort keys %{ $tj->{config}{dark} } ], [ sort keys %{ $tj->{config}{colours} } ],
    'light and dark define the same colour tokens' );
my %listed = map { $_ => 1 } @{ $tj->{files} || [] };
for my $f ( 'assets/main.css', 'assets/intranet.js' ) {
    ok( -f "$tdir/$f", "$f exists" );
    ok( $listed{$f},   "$f is in theme.json files" );
}
my $css = slurp("$tdir/assets/main.css") // '';
unlike( $css, qr/\@font-face/, 'main.css leaves @font-face to the generated fonts.css' );
unlike( $css, qr/\banimation(?:-name)?\s*+:\s*+(?!none)|\@keyframes/, 'no animation (only the reduced-motion rule turns it off)' );
like( $css, qr/\@media \(prefers-color-scheme: dark\) \{\s*:root:not\(\[data-theme="light"\]\)/, 'dark follows the device unless light was chosen' );
like( $css, qr/:root\[data-theme="dark"\]/, 'dark when chosen' );
unlike( $css, qr/tr:hover|tbody tr:hover/, 'no hover highlight on table rows' );

# every token the CSS reads is in theme.json
{
    my %have;
    $have{"colours-$_"} = 1 for keys %{ $tj->{config}{colours} };
    $have{"dark-$_"}    = 1 for keys %{ $tj->{config}{dark} };
    $have{"fonts-$_"}   = 1 for keys %{ $tj->{config}{fonts} };
    $have{"shape-$_"}   = 1 for keys %{ $tj->{config}{shape} };
    my %want = map { $_ => 1 } $css =~ /var\(--theme-([a-z0-9-]+)\)/g;
    my @gone = grep { !$have{$_} } sort keys %want;
    is( scalar @gone, 0, 'every --theme-* the CSS reads is in theme.json' ) or diag("@gone");
}

# every vocabulary class the document names is styled
{
    my $doc = slurp("$root/docs/layouts/intranet.md") // '';
    ok( length $doc, 'docs/layouts/intranet.md exists' );
    my %named = map { $_ => 1 } $doc =~ /`(in-[a-z-]+)`/g;
    ok( scalar keys %named >= 14, 'the document names the vocabulary (' . scalar( keys %named ) . ' classes)' );
    for my $c ( sort keys %named ) {
        like( $css, qr/\.\Q$c\E\b/, ".$c is styled" );
    }
}

# -- fonts: a fonts.list whose every family is in the store with a licence --
my $store = read_json("$root/fonts/fonts.json") || {};
my $fl    = slurp("$tdir/fonts.list");
ok( defined $fl && length $fl, 'theme has a fonts.list' );
my @fams = map { /^([^:#]+?)\s*:/ ? $1 : () } split /\n/, ( $fl // '' );
ok( scalar @fams, 'fonts.list names at least one family' );
for my $fam (@fams) {
    ( my $slug = lc $fam ) =~ s/\s+/-/g;
    ok( -f "$root/fonts/$slug/OFL.txt", "$fam has its OFL.txt in the fonts store" );
    like( slurp("$root/fonts/$slug/OFL.txt") // '', qr/SIL OPEN FONT LICENSE/, "$fam licence is the OFL" );
    ok( $store->{$slug} && $store->{$slug}{faces}, "$fam is in fonts.json" );
    for my $face ( @{ $store->{$slug}{faces} || [] } ) {
        ok( -f "$root/fonts/$slug/$face->{file}", "$face->{file} exists" );
    }
}

done_testing();
