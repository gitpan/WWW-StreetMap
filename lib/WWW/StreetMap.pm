=head1 NAME

WWW::StreetMap - Interface to http://www.streetmap.co.uk/

=head1 SYNOPSIS

 use WWW::StreetMap;

=head1 DESCRIPTION

Interface to http://www.streetmap.co.uk/

Please respect the terms and conditions of the excellent streetmap website: 
http://www.streetmap.co.uk/disclaimer.htm

=head1 PUBLIC INTERFACE

=cut



package WWW::StreetMap;



# pragmata
use 5.006;
use strict;
use warnings;

# Standard Perl Library and CPAN modules
use English;
use File::Temp qw(tempfile);
use Image::Magick;
use IO::All;
use IO::All::LWP;
use OpenOffice::OODoc;


our $VERSION = '0.10';

=head2 METHODS

=head3 new

 new(url => $url)

=cut

sub new {
	my($class, %options) = @_;

	die "No URL specified\n" unless $options{url};

	my $self = {
		url => $options{url},
	};

	bless $self, $class;
	return $self;
}

=head2 build_map_jpg

 build_map_jpg

Download the map from streetmap and join it into a single jpeg image.

=cut

sub build_map_jpg {
	my($self, $filename) = @_;

	return unless $filename;

	# I guess could use WWW::Mechanize and its get_all_links instead of this....
	my @lines = io($self->{url})->slurp;

	my @image_urls = grep (/image.dll/, @lines);
	

	map {  s!  ^.*SRC="([^"]+)".*$ !$1!x } @image_urls;
	
	my @filenames = ();
	my $image = Image::Magick->new;
	foreach my $url (@image_urls) {
		my ($fh, $filename) = tempfile(SUFFIX=>'gif');
		chomp $url;
		io($url) > io($filename);
		$image->Read($filename);
		close $fh;  # auto deletes
	}
	
	my $map = $image->Montage(geometry=>'200x200', tile => '3x3');
	$map->Write($filename);
}

=head2 create_oo_doc {

 create_oo_doc($filename, $map_filename)

Create an OpenOffice Writer document containg the map.

If you do not specify a pre-existing map then a temporary image will be created
for insertion into the document.

=cut


sub create_oo_doc {
	my($self, $filename, $map_filename) = @_;

	return unless $filename;

	my $fh;
	unless($map_filename) {
		($fh, $map_filename) = tempfile(SUFFIX=>'gif');
		$self->build_map_jpg($map_filename);
	}

	# create the File object
	my $oofile = ooFile($filename, create => 'text') or die "Something was wrong !\n";

	# get the current local time in OpenOffice.org-compliant format
	my $oodate = ooLocaltime;
	# get access to its metadata
	my $metadata = ooMeta(archive => $oofile);

	# set the current time as the creation date
	$metadata->creation_date($oodate);
	# set the current time as modification date
	$metadata->date($oodate);
	# set the title, if provided
	$metadata->title("Map");
	# saving (before here, the file didn't exist)
	$oofile->save;


	my $document =  OpenOffice::OODoc::Document->new(file => $filename);

	$document->createImageElement(
		"Map",
		import  => $map_filename,
		size    => "10cm, 10cm",
	);

	# save the modified document
	$document->save;


	# Close/delete the temp file if we used one
	close $fh if($fh);
}

1;

=head1 INSTALLATION

This module uses Module::Build for its installation. To install this module type
the following:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install


If you do not have Module::Build type:

  perl Makefile.PL

to fetch it. Or use CPAN or CPANPLUS and fetch it "manually".

=head1 DEPENDENCIES

This  module works only  with  perl v5.6 and higher.  I   am more than happy  to
backport to an earlier perl 5.x if someone using an old  perl would like to make
use of  my module. Mail  me  and ask me to  do  the work  [or  even better do it
yourself and send in a patch! ;-)]

This module requires these other modules and libraries:

 Test::More

Test::More is only required for testing purposes

This module has these optional dependencies:

 Test::Distribution

This is just requried for testing purposes.

=head1 TODO

=over

=item *

Write it!

=back

=head1 BUGS

To report a bug or request an enhancement use CPAN's excellent Request Tracker,
either via the web:

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-StreetMap>

or via email:

bug-www-streetmap@rt.cpan.org

=head1 AUTHOR

Sagar R. Shah

=head1 COPYRIGHT

Copyright 2004-5, Sagar R. Shah, All rights reserved

This program  is free software; you can  redistribute it  and/or modify it under
the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this
module.

=cut

