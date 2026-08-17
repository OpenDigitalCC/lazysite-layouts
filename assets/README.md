# Repo-level shared assets

`favicon.svg` is the catalogue's default favicon, derived from the
lazysite.io mark (green rounded square, white bar, #16A34A). Every layout
declares `[% theme_assets %]/favicon.svg`, and `tools/package-themes.sh`
injects this file into each theme zip at packaging time - git carries it
once, and the declared icon always resolves ("ship an icon and declare
it"; a declaration pointing at a 404 is worse than none).

A theme that wants its own icon commits `assets/favicon.svg` inside the
theme directory - a theme-level file wins and the injection is skipped,
the same override rule as `fonts.list`. A live site can also replace the
installed theme's `favicon.svg` through the manager to carry the site's
own brand.
