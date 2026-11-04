#!/usr/bin/perl
# base-css.t - assets/base.css, the shared sheet injected into every pack,
# must parse (balanced braces and comments), carry the sections the catalogue
# relies on, and load nothing from outside.
use strict;
use warnings;
use Test::More;
use FindBin ();

my $path = "$FindBin::Bin/../assets/base.css";
ok( -f $path, 'assets/base.css exists' ) or BAIL_OUT('no base.css');
open my $fh, '<:utf8', $path or die "read $path: $!";
my $css = do { local $/; <$fh> };
close $fh;

( my $bare = $css ) =~ s{/\*.*?\*/}{}gs;
unlike( $bare, qr{/\*}, 'every comment is closed' );
my ( $open, $close ) = ( scalar( () = $bare =~ /\{/g ), scalar( () = $bare =~ /\}/g ) );
is( $open, $close, "braces balance ($open open, $close close)" );
my $depth = 0;
my $neg   = 0;
for my $c ( split //, $bare ) {
    $depth++ if $c eq '{';
    $depth-- if $c eq '}';
    $neg = 1 if $depth < 0;
}
ok( !$neg && $depth == 0, 'braces never close before they open' );

unlike( $css, qr{(?:https?:)?//[\w.-]+\.[a-z]{2,}}i, 'no external URL' );
unlike( $css, qr{--theme-}, 'no --theme-* token (the design-kit check would demand it of theme.json)' );
unlike( $css, qr{\@import}, 'no @import' );
unlike( $bare, qr{(?<![\w&])#[0-9a-fA-F]{3,8}\b}, 'no literal hex colour' );

my %need = (
    'overflow-wrap'                  => qr{overflow-wrap:\s*anywhere},
    'embeds capped'                  => qr{max-width:\s*100%},
    'wide tables scroll'             => qr{table[^{]*\{[^}]*overflow-x:\s*auto}s,
    '.form-field'                    => qr{\.form-field\b},
    '.form-options'                  => qr{\.form-options\b},
    '.form-option'                   => qr{\.form-option\b},
    '.form-status'                   => qr{\.form-status\b},
    '.required'                      => qr{\.required\b},
    'stepped forms'                  => qr{\.lsf-step\b},
    'step progress'                  => qr{\.lsf-progress\b},
    'visited links'                  => qr{:visited},
    'button keyboard focus'          => qr{button:focus-visible},
    'invalid fields'                 => qr{:user-invalid},
    'placeholder'                    => qr{::placeholder},
    'checked boxes and radios'       => qr{accent-color},
    'reduced motion'                 => qr{prefers-reduced-motion},
    'Odoo sign-in banner'            => qr{\.ls-odoo-banner},
    'feed links'                     => qr{\.feed-links},
    'explorer auth wrapper'          => qr{\.ex-auth},
    'app banner slot'                => qr{\[data-ls-app-banner\]},
    'app signed-out slot'            => qr{\[data-ls-app-show-out\]},
    'app status slot'                => qr{\[data-ls-app-status\]},
);
like( $bare, $need{$_}, "covers $_" ) for sort keys %need;

done_testing;
