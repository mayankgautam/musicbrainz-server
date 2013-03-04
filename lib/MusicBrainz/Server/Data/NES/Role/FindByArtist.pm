package MusicBrainz::Server::Data::NES::Role::FindByArtist;
use Moose::Role;

requires 'map_core_entity', 'scoped_request';

sub find_by_artist {
    my ($self, $artist, undef, undef) = @_;
    return [
        map { $self->map_core_entity($_) }
            @{ $self->scoped_request('/find-by-artist', { 'artist' => $artist->gid }) }
    ];
}

1;
