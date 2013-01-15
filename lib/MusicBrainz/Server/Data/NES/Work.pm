package MusicBrainz::Server::Data::NES::Work;
use Moose;

use MusicBrainz::Server::Entity::Work;

with 'MusicBrainz::Server::Data::Role::NES';

sub create {
    my ($self, $edit, $editor, $work, $iswcs) = @_;

    my $response = $self->request('/work/create', {
        edit => $edit->id,
        editor => $editor->id,
        _work_tree($work, $iswcs)
    });

    return $self->get_revision($response->{ref});
}

sub update {
    my ($self, $edit, $editor, $base_revision, $work, $iswcs) = @_;

    my $response = $self->request('/work/update', {
        edit => $edit->id,
        editor => $editor->id,
        revision => $base_revision,
        _work_tree($work, $iswcs)
    });

    return undef;
}

sub _work_tree {
    my ($work, $iswcs) = @_;
    return (
        work => $work,
        iswcs => [
            map +{ iswc => $_ }, @$iswcs
        ]
    );
}

sub get_revision {
    my ($self, $revision_id) = @_;
    return _new_from_response(
        $self->request('/work/view-revision', { revision => $revision_id }));
}

sub get_by_gid {
    my ($self, $gid) = @_;
    return _new_from_response(
        $self->request('/work/find-latest', { mbid => $gid }))
}

sub _new_from_response {
    my ($response) = @_;
    my %data = %{ $response->{data} };
    return MusicBrainz::Server::Entity::Work->new(
        name => $data{name},
        comment => $data{comment},
        type_id => $data{type},
        language_id => $data{language},

        gid => $response->{mbid},
        revision_id => $response->{revision}
    );
}

sub tags {
    my $self = shift;
    $self->c->model('Work')->tags;
}

sub get_aliases {
    my ($self, $work) = @_;
    my $response = $self->request('/work/view-aliases', {
        revision => $work->revision_id
    });
    return [
        map {
            MusicBrainz::Server::Entity::Alias->new(
                name => $_->{name},
                sort_name => $_->{'sort-name'},
                locale => $_->{locale},
                type_id => $_->{type},
                begin_date => MusicBrainz::Server::Entity::PartialDate->new($_->{begin_date}),
                end_date => MusicBrainz::Server::Entity::PartialDate->new($_->{end_date}),
                ended => $_->{ended}
            )
        } @$response
    ]
}

__PACKAGE__->meta->make_immutable;
1;
