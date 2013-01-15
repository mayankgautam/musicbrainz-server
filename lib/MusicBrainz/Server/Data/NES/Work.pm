package MusicBrainz::Server::Data::NES::Work;
use Moose;

use MusicBrainz::Server::Data::Utils qw( partial_date_to_hash );
use MusicBrainz::Server::Entity::Work;
use MusicBrainz::Server::WebService::Serializer::JSON::2::Utils qw( boolean );

with 'MusicBrainz::Server::Data::Role::NES';

sub create {
    my ($self, $edit, $editor, $tree) = @_;

    $tree->aliases([]) unless $tree->aliases_set;

    my $response = $self->request('/work/create', {
        edit => $edit->id,
        editor => $editor->id,
        _work_tree($tree)
    });

    return $self->get_revision($response->{ref});
}

sub update {
    my ($self, $edit, $editor, $base_revision, $tree) = @_;

    die 'Need a base revision' unless $base_revision;

    my $final_tree = do {
        if( $tree->work_set && $tree->aliases_set && $tree->iswcs_set ) {
            $tree
        }
        else {
            my $original_tree = $self->view_tree($base_revision);

            $original_tree->work($tree->work)
                if ($tree->work_set);

            $original_tree->aliases($tree->aliases)
                if ($tree->aliases_set);

            $original_tree->iswcs($tree->iswcs)
                if ($tree->iswcs_set);

            $original_tree;
        }
    };

    my $response = $self->request('/work/update', {
        edit => $edit->id,
        editor => $editor->id,
        revision => $base_revision->revision_id,
        _work_tree($final_tree)
    });

    return undef;
}

sub view_tree {
    my ($self, $revision) = @_;

    return MusicBrainz::Server::Entity::Tree::Work->new(
        work => $revision,
        iswcs => $self->get_iswcs($revision),
        aliases => $self->get_aliases($revision)
    );
}

sub _work_tree {
    my $tree = shift;

    return (
        work => do {
            my $work = $tree->work;
            {
                 type => $work->type_id,
                 language => $work->language_id,
                 name => $work->name,
                 comment => $work->comment
            }
        },
        iswcs => [
            map +{ iswc => $_ }, @{ $tree->iswcs }
        ],
        aliases => [
            map +{
                name => $_->name,
                'sort-name' => $_->sort_name,
                'begin-date' => partial_date_to_hash($_->begin_date),
                'end-date' => partial_date_to_hash($_->end_date),
                ended => $_->ended,
                'primary-for-locale' => boolean($_->primary_for_locale),
                type => $_->type_id,
                locale => $_->locale
            }, @{ $tree->aliases }
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

sub get_iswcs {
    my ($self, $revision) = @_;
    warn "Unimplemented";
    return [];
}

__PACKAGE__->meta->make_immutable;
1;
