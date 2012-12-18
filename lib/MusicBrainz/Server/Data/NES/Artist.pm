package MusicBrainz::Server::Data::NES::Artist;

use utf8;
use Moose;
use namespace::autoclean;

use MusicBrainz::Server::Entity::Artist;
use MusicBrainz::Server::Data::NES::Utils qw( request );

extends 'MusicBrainz::Server::Data::NES::CoreEntity';

sub _entity_class
{
    return 'MusicBrainz::Server::Entity::Artist';
}

sub _field_mapping
{
    my $self = shift;

    my $pd = $self->c->model ('NES::PartialDate');

    return {
        'mbid' => 'gid',
        'country' => 'country_id',
        'type' => 'type_id',
        'gender' => 'gender_id',
        'sort-name' => 'sort_name',
        'begin-date' => undef,
        'end-date' => undef,
        'begin-date' => sub { return $pd->new_from_service (@_); },
        'end-date' => sub { return $pd->new_from_service (@_); },
    };
}

sub create
{
    my ($self, $editor_id, @artists) = @_;

    my $response = request ('/edit/open', {});
    my $edit_id = $response->{ref};

    my @created;
    for my $artist (@artists)
    {

        my $response = request ('/artist/create', {
            editor => 1, edit => $edit_id, artist => $artist });

        push @created, $response->{ref};
    }

    return @artists > 1 ? @created : $created[0];
}

sub get_by_revision
{
    my ($self, $revision_id) = @_;

    my $response = request ('/artist/view-revision', { revision => $revision_id });

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
