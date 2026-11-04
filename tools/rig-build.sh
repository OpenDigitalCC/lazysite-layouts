#!/bin/bash
# rig-build.sh - build the local measurement site (see render-catalogue.sh).
#
#   rig-build.sh <rig-dir>
#
# Writes <rig-dir>/docroot (a lazysite site with every layout installed nested
# at lazysite/layouts/<L>/, the served asset mirror pre-filled at
# lazysite-assets/<L>/<T>/ the way tools/package-themes.sh materialises a pack,
# and two pages per theme pinned by front matter layout:/theme:), and
# <rig-dir>/check/<L>/<T>/ (the theme folder as a pack carries it, for
# lzs-design-kit.sh check). No network access.
set -eu

REPO="$(cd "$(dirname "$0")/.." && pwd)"
RIG="$1"
KIT=/srv/projects/lazysite-sites/bin/design-kit
DOC="$RIG/docroot"

rm -rf "$RIG/docroot" "$RIG/check"
mkdir -p "$DOC/lazysite/layouts" "$DOC/lazysite-assets" "$DOC/s" "$DOC/f" "$RIG/check"


cat > "$DOC/lazysite/lazysite.conf" <<CONF
site_name: Catalogue rig
site_url: http://127.0.0.1:${RIG_PORT:-8097}
manager: disabled
CONF

# Two levels, several groups, like the theme gallery's nav.
cat > "$DOC/lazysite/nav.conf" <<'NAV'
Home | /
Discover
  Authoring | /docs/authoring
  All features | /docs/features
  API and raw mode | /docs/api
Configure
  Configuration | /docs/configuration
  Reference | /docs/reference
  Themes and layouts | /docs/themes
Specimen | /s/default/default
Form in steps | /f/default/default
Develop
  Installing | /docs/install
  Contributing | /docs/development
Contact | /contact
NAV

cat > "$DOC/index.md" <<'IDX'
---
title: Catalogue rig
---
The measurement rig for the lazysite-layouts catalogue.
IDX

: > "$RIG/themes.tsv"

for LDIR in "$REPO"/layouts/*/; do
    L="$(basename "$LDIR")"
    cp -r "$LDIR" "$DOC/lazysite/layouts/$L"
    for TDIR in "$LDIR"themes/*/; do
        [ -f "$TDIR/theme.json" ] || continue
        T="$(basename "$TDIR")"
        printf '%s\t%s\n' "$L" "$T" >> "$RIG/themes.tsv"

        # The pack's content: theme.json + assets, fonts and favicon injected.
        PK="$RIG/check/$L/$T"
        mkdir -p "$PK/assets"
        cp "$TDIR/theme.json" "$PK/"
        [ -d "$TDIR/assets" ] && cp -r "$TDIR/assets/." "$PK/assets/"
        FL="$TDIR/fonts.list"
        [ -f "$FL" ] || FL="$LDIR/fonts.list"
        if [ -f "$FL" ]; then
            perl "$REPO/tools/gen-fonts-css.pl" "$FL" "$REPO/fonts" "$PK/assets" >/dev/null
        fi
        if [ ! -f "$TDIR/assets/favicon.svg" ]; then
            cp "$REPO/assets/favicon.svg" "$PK/assets/favicon.svg"
        fi
        if [ ! -f "$TDIR/assets/base.css" ]; then
            cp "$REPO/assets/base.css" "$PK/assets/base.css"
        fi

        # The served mirror is the pack's assets/.
        mkdir -p "$DOC/lazysite-assets/$L/$T"
        cp -r "$PK/assets/." "$DOC/lazysite-assets/$L/$T/"

        mkdir -p "$DOC/s/$L" "$DOC/f/$L"
        perl -e '
            my ($src, $dst, $l, $t) = @ARGV;
            open my $in, "<:utf8", $src or die "$src: $!";
            my $txt = do { local $/; <$in> };
            $txt =~ s/\A---\n/---\nlayout: $l\ntheme: $t\n/ or die "no front matter in $src";
            open my $out, ">:utf8", $dst or die "$dst: $!";
            print $out $txt;
        ' "$KIT/specimen.md" "$DOC/s/$L/$T.md" "$L" "$T"
        perl -e '
            my ($src, $dst, $l, $t) = @ARGV;
            open my $in, "<:utf8", $src or die "$src: $!";
            my $txt = do { local $/; <$in> };
            $txt =~ s/\A---\n/---\nlayout: $l\ntheme: $t\n/ or die "no front matter in $src";
            open my $out, ">:utf8", $dst or die "$dst: $!";
            print $out $txt;
        ' "$KIT/specimen-steps.md" "$DOC/f/$L/$T.md" "$L" "$T"
    done
done

echo "rig built: $(wc -l < "$RIG/themes.tsv") themes under $DOC"
