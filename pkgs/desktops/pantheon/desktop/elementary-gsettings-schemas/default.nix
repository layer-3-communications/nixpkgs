{ stdenv
, runCommand
, mutter
, elementary-default-settings
, nixos-artwork
, glib
, gala
, epiphany
, elementary-settings-daemon
, gtk3
, plank
, gsettings-desktop-schemas
, extraGSettingsOverrides ? ""
, extraGSettingsOverridePackages ? []
}:

let

  gsettingsOverridePackages = [
    elementary-settings-daemon
    epiphany
    gala
    mutter
    gsettings-desktop-schemas
    gtk3
    plank
  ] ++ extraGSettingsOverridePackages;

in

with stdenv.lib;

# TODO: Having https://github.com/NixOS/nixpkgs/issues/54150 would supersede this
runCommand "elementary-gsettings-desktop-schemas" {}
  ''
     schema_dir=$out/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas

     mkdir -p $schema_dir
     cp -rf ${glib.getSchemaPath gsettings-desktop-schemas}/*.xml $schema_dir

     ${concatMapStrings (pkg: "cp -rf ${glib.getSchemaPath pkg}/*.xml $schema_dir\n") gsettingsOverridePackages}

     chmod -R a+w $out/share/gsettings-schemas/nixos-gsettings-overrides
     cp ${elementary-default-settings}/share/glib-2.0/schemas/20-io.elementary.desktop.gschema.override $schema_dir

     cat - > $schema_dir/nixos-defaults.gschema.override <<- EOF
     [org.gnome.desktop.background]
     picture-uri='file://${nixos-artwork.wallpapers.simple-dark-gray}/share/artwork/gnome/nix-wallpaper-simple-dark-gray.png'
     primary-color='#000000'

     ${extraGSettingsOverrides}
     EOF

     ${glib.dev}/bin/glib-compile-schemas $schema_dir
  ''
