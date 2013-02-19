package MusicBrainz::Server::Data::NES::Work;
use Moose;

use DateTime::Format::ISO8601;
use MusicBrainz::Server::Data::NES::TreeMapping ':all';
use MusicBrainz::Server::Data::Utils qw( object_to_revision_ids );
use MusicBrainz::Server::Entity::NES::Relationship;
use MusicBrainz::Server::Entity::NES::Revision;
use MusicBrainz::Server::Entity::Tree::Work;
use MusicBrainz::Server::Entity::Work;

with 'MusicBrainz::Server::Data::Role::NES' => {
    root => '/work'
};
with 'MusicBrainz::Server::Data::NES::CoreEntity';
with 'MusicBrainz::Server::Data::NES::Role::Alias';
with 'MusicBrainz::Server::Data::NES::Role::Annotation';
with 'MusicBrainz::Server::Data::NES::Role::Relationship';
with 'MusicBrainz::Server::Data::NES::Role::Tags' => {
    model => 'Work'
};

sub tree_class { 'MusicBrainz::Server::Entity::Tree::Work' }

around create => sub {
    my ($orig, $self, $edit, $editor, $tree) = @_;

    $tree->annotation('') unless $tree->annotation_set;
    $tree->aliases([]) unless $tree->aliases_set;
    $tree->relationships([]) unless $tree->relationships_set;

    $self->$orig($edit, $editor, $tree);
};

sub view_tree {
    my ($self, $revision) = @_;

    return $self->tree_class->new(
        work => $revision,
        iswcs => $self->get_iswcs($revision),
        annotation => $self->get_annotation($revision),
        aliases => $self->get_aliases($revision),
        relationships => $self->get_relationships($revision)
    );
}

sub tree_to_json {
    my ($self, $tree) = @_;

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
            map +{ iswc => $_->iswc }, @{ $tree->iswcs }
        ],
        annotation_to_json($tree),
        aliases_to_json($tree),
        relationships_to_json($tree)
    );
}

sub map_core_entity {
    my ($self, $response) = @_;
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

sub get_iswcs {
    my ($self, $revision) = @_;
    warn "Unimplemented";
    return [];
}

sub is_empty {
    my ($self, $work) = @_;
    return $self->request(
        '/work/eligible-for-cleanup',
        { revision => $work->revision_id }
    )->{eligible};
}

sub merge {
    my ($self, $edit, $editor, %opts) = @_;
    my @source = @{ $opts{source} };
    my $target = $opts{target};

    die 'NES: I cannot merge more than one entity at a time!' if @source > 1;

    $self->request(
        '/work/merge',
        {
            edit => $edit->id,
            editor => $editor->id,
            source => $source[0]->revision_id,
            target => $target->gid
        }
    );
}

sub load_revision {
    my ($self, $revision) = @_;
    my $res = $self->request(
        '/work/get-revision',
        { revision => $revision->revision_id }
    )->{data};

    $revision->revision(
        MusicBrainz::Server::Entity::NES::Revision->new(
            created_at => DateTime::Format::ISO8601->parse_datetime($res->{'created-at'})
        )
    );
}

sub load_iswcs {
    my ($self, @works) = @_;
    my %works_by_revision_id = object_to_revision_ids(@works);
    my %iswc_map = %{
        $self->request('/iswc/find-by-works', {
            revisions => [
                map +{ revision => $_->revision_id }, @works
            ]
        })
    };

    for my $key (keys %iswc_map) {
        for my $work (@{ $works_by_revision_id{$key} }) {
            $work->iswcs([
                map {
                    MusicBrainz::Server::Entity::ISWC->new( iswc => $_ )
                  } @{ $iswc_map{$key} }
            ]);
        }
    }

    return;
}


__PACKAGE__->meta->make_immutable;
1;
