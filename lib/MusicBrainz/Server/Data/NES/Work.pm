package MusicBrainz::Server::Data::NES::Work;
use Moose;

use MusicBrainz::Server::Entity::NES::Work;

with 'MusicBrainz::Server::Data::Role::NES';

sub create {
    my ($self, $edit, $editor, $work, $iswcs) = @_;

    my $response = $self->request('/work/create', {
        edit => $edit->id,
        editor => $editor->id,
        work => $work,
        iswcs => [
            map +{ iswc => $_ }, @$iswcs
        ]
    });

    return $self->get_revision($response->{ref});
}

sub get_revision {
    my ($self, $revision_id) = @_;

    my $response = $self->request('/work/view-revision', { revision => $revision_id });

    return MusicBrainz::Server::Entity::NES::Work->new(
        name => $response->{data}{name},
        gid => $response->{mbid}
    );
}

__PACKAGE__->meta->make_immutable;
1;
