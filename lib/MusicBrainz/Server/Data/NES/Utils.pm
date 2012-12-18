package MusicBrainz::Server::Data::NES::Utils;
use Moose;

use DBDefs;
use Encode;
use JSON;
use LWP::UserAgent;

use Sub::Exporter -setup => {
    exports => [qw( request )]
};

sub model
{
    my $model_class = shift;

    Class::MOP::load_class("MusicBrainz::Server::Data::NES::$model_class");
    return $model_class->new ();
}

sub request
{
    my ($path, $body) = @_;

    my $ua = LWP::UserAgent->new;

    my $uri = DBDefs->DATA_ACCESS_SERVICE.$path;
    my $content = to_json ($body, { pretty => 1, canonical => 1 });

    my $response = $ua->post ($uri, Content => encode ('utf8', $content));

    return decode_json ($response->content);
}

1;

=head1 COPYRIGHT

Copyright (C) 2012 MetaBrainz Foundation

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut
