#!/usr/bin/perl
# pwa-layout.t - the pocket-ops layout and its themes (lab, control, meadow, midnight).
#
# t/site-contract.t renders pocket-ops with every other layout. This file holds
# what is particular to an installable-app layout (docs/layouts/pocket-ops.md):
#
#   - the slots a page needs are in layout.tt (banner, signed-out notice, scheme
#     switch, menu button, skip link, footer status, the Odoo sign-in banner)
#   - the layout's scripts are linked through theme_assets and every theme ships
#     them; no offline kit is shipped (the engine's app-offline extension fills the slots)
#   - nothing is OOM Lab specific, and no file names an external address
#   - each theme's fonts are bundled with a licence (fonts.list -> the store)
#   - both themes declare the layout; layout.json and theme.json state requires
#   - both themes define every short name the patterns use
#   - no worker template is shipped: the engine keeps the pages (SM1197)
#
# The tree is walked with readdir, never a glob (upstream t/lint/46 lesson).
use strict;
use warnings;
use Test::More;
use FindBin  ();
use JSON::PP ();

my $root   = "$FindBin::Bin/..";
my $ldir   = "$root/layouts/pocket-ops";
my @themes = qw(lab control meadow midnight);

sub slurp {
    my ($path) = @_;
    open my $fh, '<:utf8', $path or return undef;
    local $/;
    my $t = <$fh>;
    close $fh;
    return $t;
}

sub read_json {
    my ($path) = @_;
    my $raw = slurp($path);
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

# Every file under a directory, by readdir.
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

ok( -f "$ldir/layout.tt", 'layouts/pocket-ops/layout.tt exists' );
my $tt = slurp("$ldir/layout.tt") // '';
my $lj = read_json("$ldir/layout.json") || {};

# -- slots in the layout --
for my $slot (
    [ 'data-po-banner',        'banner slot' ],
    [ 'data-po-show-out',      'signed-out notice' ],
    [ 'data-po-theme',         'colour-scheme switch' ],
    [ 'data-po-menu-toggle',   'menu button' ],
    [ 'data-po-app-status',    'footer app status' ],
    [ 'data-ls-app-banner',    'generic banner slot' ],
    [ 'data-ls-app-show-out',  'generic signed-out notice slot' ],
    [ 'data-ls-app-status',    'generic install and update status slot' ],
    [ 'class="po-skip"',       'skip link' ],
    [ 'class="po-page-head"',  'page head' ],
    [ 'class="po-subnav"',     'second-row nav' ],
    [ 'odoo_signin_banner',    'Odoo sign-in banner' ],
    [ 'auth_control',          'cache-safe auth control for sites without Odoo' ],
    [ 'viewport-fit=cover',    'viewport covers the notch' ],
  )
{
    like( $tt, qr/\Q$slot->[0]\E/, "layout.tt has the $slot->[1]" );
}
like( $tt, qr/aria-controls="po-nav"/, 'menu button controls the nav' );
like( $tt, qr/<time[^>]*datetime=/,     'last-updated <time>' );
unlike( $tt, qr/rel="manifest"/, 'layout adds no manifest link (the engine does)' );

# -- the kit, linked through theme_assets with the theme version --
my @kit = qw(theme-early.js pocket-ops.js);
for my $f ( @kit, 'patterns.css', 'main.css', 'fonts.css' ) {
    like( $tt, qr{\[%\s*theme_assets\s*%\]/\Q$f\E\?v=\[%\s*theme_version\s*%\]},
        "layout.tt links $f through theme_assets with ?v=theme_version" );
}
unlike( $tt, qr{<link rel="stylesheet"[^>]*href="/|<script[^>]*src="/}, 'no site-absolute script or stylesheet path' );
like( $tt, qr{theme-early\.js.*?</head>}s, 'theme-early.js is in <head>' );
unlike( $tt, qr/offline-kit/, 'the offline kit is not linked (the engine extension owns it)' );
like( $tt, qr{pocket-ops\.js.*</body>}s, 'pocket-ops.js is linked before the end of <body>' );

# -- no lab-specific names, no external address --
my @files = tree($ldir);
ok( scalar @files > 20, 'walked the layout tree (' . @files . ' files)' );
for my $p (@files) {
    next if $p =~ /\.(?:png|woff2?)$/;
    ( my $short = $p ) =~ s{^\Q$root\E/}{};
    my $t = slurp($p);
    next unless defined $t;
    unlike( $t, qr{/oom-core|oom-lab|OOM Lab|\bLabOffline\b|\bdata-lab-|\blab-(?:top|nav|main|banner)}i,
        "$short names nothing OOM Lab specific" );
    my @urls = $t =~ m{(https?://[^\s"'<>)]+)}g;
    @urls = grep { $_ ne 'https://lazysite.io' } @urls;
    is( scalar @urls, 0, "$short has no external address" ) or diag("@urls");
}

# -- layout.json --
is( $lj->{name}, 'pocket-ops', 'layout.json name' );
like( $lj->{version} // '', qr/^\d+\.\d+\.\d+$/, 'layout.json version is semver' );
is( $lj->{author}, 'OpenDigitalCC', 'layout.json author' );
is_deeply( $lj->{themes}, [@themes], 'layout.json lists the four themes' );
is( $lj->{default_theme}, 'lab', 'default theme is lab' );
my $lreq = ref $lj->{requires} eq 'HASH' ? $lj->{requires}{lazysite} : undef;
ok( defined $lreq && version_ge( $lreq, '0.15.11' ), 'layout.json requires lazysite 0.15.11 or later (page_url)' );

# -- the short names every theme defines for the patterns --
my @short = qw(
    --canvas --surface --sunken --ink --muted --line --line-strong
    --accent --accent-hover --accent-ink --accent-soft --accent-strong --focus-ring
    --ok --ok-soft --warn --warn-soft --bad --bad-soft --bad-ink --info --info-soft
    --star --scrim --data-1 --data-4 --shadow --shadow-raised
    --font --mono --radius-sm --radius --radius-lg --control --touch --scan --header --page
    --t-xs --t-3xl --s-1 --s-7
    --radius-pill --dot-radius --avatar-radius --label-case --label-track
    --button-case --button-track --figure-font --signal
);

my $store = read_json("$root/fonts/fonts.json") || {};

for my $T (@themes) {
    my $td = "$ldir/themes/$T";
    subtest "theme $T" => sub {
        my $tj = read_json("$td/theme.json") || {};
        is( $tj->{name}, $T, 'theme.json name matches its folder' );
        is_deeply( $tj->{layouts}, ['pocket-ops'], 'theme declares the pocket-ops layout' );
        my $treq = ref $tj->{requires} eq 'HASH' ? $tj->{requires}{lazysite} : undef;
        ok( defined $treq && version_ge( $treq, '0.15.10' ), 'theme.json requires lazysite 0.15.10 or later' );
        ok( ref $tj->{config}{dark} eq 'HASH', 'theme has a dark scheme (config.dark)' );
        my %listed = map { $_ => 1 } @{ $tj->{files} || [] };
        for my $f ( 'assets/main.css', 'assets/patterns.css', ( map {"assets/$_"} @kit ) ) {
            ok( -f "$td/$f", "$f exists" );
            ok( $listed{$f}, "$f is in theme.json files" );
        }
        for my $f ( keys %listed ) {
            ok( -f "$td/$f", "listed file $f exists" );
        }
        ok( !-e "$td/assets/offline-kit.js", 'theme ships no offline-kit.js' );
        my $mcss = slurp("$td/assets/main.css") // '';
        for my $slot (qw(data-ls-app-banner data-ls-app-show-out data-ls-app-status)) {
            like( $mcss, qr/\[\Q$slot\E\]/, "main.css styles [$slot]" );
        }
        for my $icon (qw(app-64 app-192 app-512 app-maskable)) {
            ok( -f "$td/assets/icons/$icon.png", "icon $icon.png shipped" );
        }

        # fonts: a fonts.list whose every family is in the store with a licence
        my $fl = slurp("$td/fonts.list");
        ok( defined $fl && length $fl, 'theme has a fonts.list' );
        my @fams = map { /^([^:#]+?)\s*:/ ? $1 : () } split /\n/, ( $fl // '' );
        ok( scalar @fams, 'fonts.list names at least one family' );
        for my $fam (@fams) {
            ( my $slug = lc $fam ) =~ s/\s+/-/g;
            ok( -f "$root/fonts/$slug/OFL.txt", "$fam has its OFL.txt in the fonts store" );
            my $lic = slurp("$root/fonts/$slug/OFL.txt") // '';
            like( $lic, qr/SIL OPEN FONT LICENSE/, "$fam licence is the OFL" );
            ok( $store->{$slug} && $store->{$slug}{faces}, "$fam is in fonts.json" );
            for my $face ( @{ $store->{$slug}{faces} || [] } ) {
                ok( -f "$root/fonts/$slug/$face->{file}", "$face->{file} exists" );
            }
        }
        unlike( slurp("$td/assets/main.css") // '', qr/\@font-face/, 'main.css leaves @font-face to the generated fonts.css' );

        # the short names
        my $css = slurp("$td/assets/main.css") // '';
        my @missing = grep { $css !~ /\Q$_\E\s*:/ } @short;
        is( scalar @missing, 0, 'main.css defines every short name' ) or diag("@missing");
    };
}

# -- KPI tiles and state chips: in every theme's sheet, and documented --
{
    my $pdoc = slurp("$root/docs/layouts/pocket-ops.md") // '';
    for my $th (@themes) {
        my $pc = slurp("$ldir/themes/$th/assets/patterns.css") // '';
        for my $c (qw(po-tiles po-tile po-figure po-trend)) {
            like( $pc, qr/\.\Q$c\E\b/, "$th patterns.css styles .$c" );
        }
        like( $pc, qr/\.po-figure\s*\{[^}]*font-family:\s*var\(--figure-font\)/, "$th: .po-figure is set in the figure font" );
        like( $pc, qr/\@media \(max-width: 30rem\) \{ \.po-tiles \{ grid-template-columns: repeat\(2,/, "$th: tiles go two to a row on a phone" );
        like( $pc, qr/a\.po-tile[^{]*\{|\.po-tile\s*\{[^}]*min-height:\s*var\(--touch/, "$th: a tile that is a link is a touch target" );
        for my $s (qw(ok attention pending off)) {
            like( $pc, qr/\.po-state\[data-state="\Q$s\E"\]\s*\{/,          "$th patterns.css colours data-state=$s" );
            like( $pc, qr/\.po-state\[data-state="\Q$s\E"\]::before\s*\{ content:/, "$th patterns.css gives data-state=$s its own mark" );
        }
        unlike( $pc, qr/\.po-(?:tile|state)[^{]*\{[^}]*#[0-9a-fA-F]{3,8}\b/, "$th: tiles and states use short names, no colour value" );
    }
    my %cp;
    for my $th (@themes) { $cp{ slurp("$ldir/themes/$th/assets/patterns.css") // '' }++ }
    is( scalar keys %cp, 1, 'the four patterns.css copies are identical' );
    for my $c (qw(po-tiles po-tile po-label po-figure po-trend)) {
        like( $pdoc, qr/`\.\Q$c\E`/, "docs name .$c" );
    }
    for my $s (qw(ok attention pending off)) {
        like( $pdoc, qr/^`\Q$s\E` \|/m, "docs describe data-state=$s" );
    }
    like( $pdoc, qr/data-state/, 'docs show the data-state attribute' );
}

# -- the worker is the engine's --
my @sw = grep {m{lazysite-sw|\.tmpl$}} @files;
is( scalar @sw, 0, 'no worker template shipped (the engine keeps the pages, SM1197)' ) or diag("@sw");
my $doc = slurp("$root/docs/layouts/pocket-ops.md") // '';
like( $doc, qr/app_offline_pages/, 'docs/layouts/pocket-ops.md says how the engine worker is set up' );
like( $doc, qr/app_update/,        'docs/layouts/pocket-ops.md names app_update' );

done_testing();
