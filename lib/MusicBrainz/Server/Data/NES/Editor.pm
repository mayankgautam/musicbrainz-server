package MusicBrainz::Server::Data::NES::Editor;
use Moose;
use namespace::autoclean;

use MusicBrainz::Server::Entity::Editor;
use MusicBrainz::Server::Data::NES::Utils qw( request );

extends 'MusicBrainz::Server::Data::NES::CoreEntity';

sub _entity_class
{
    return 'MusicBrainz::Server::Entity::Editor';
}

sub _field_mapping
{
    return { 'ref' => 'id' };
}

sub register
{
    my ($self, $editor) = @_;

    my $response = request ('/editor/register', $editor);

    return $self->new_from_response ($response);
}

__PACKAGE__->meta->make_immutable;
no Moose;
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
