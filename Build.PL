use strict;
use Module::Build;

Module::Build->new(
	module_name        => 'WWW::StreetMap',
	license            => 'perl',
	requires           => {
		'File::Temp'        => 0,
		'Image::Magick'     => 0,
		'IO::All'           => 0,
		'IO::All::LWP'      => 0,
		'OpenOffice::OODoc' => 0,
	},
	create_readme      => 1,
	scripts            => [ 'script/get_streetmap' ],
	sign               => 1,
	create_makefile_pl => 'passthrough',
	add_to_cleanup     => [ 'WWW-StreetMap-*' ],
)->create_build_script;
