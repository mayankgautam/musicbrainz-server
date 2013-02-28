package MusicBrainz::Server::Data::NES::ReleaseGroup;
use feature 'switch';
use Moose;

use MusicBrainz::Server::Data::NES::TreeMapping ':all';
use MusicBrainz::Server::Data::Utils qw( partial_date_to_hash );
use MusicBrainz::Server::Entity::ReleaseGroup;
use MusicBrainz::Server::Entity::Tree::ReleaseGroup;

with 'MusicBrainz::Server::Data::Role::NES' => {
    root => '/release-group'
};
with 'MusicBrainz::Server::Data::NES::CoreEntity';

sub tree_class { 'MusicBrainz::Server::Entity::Tree::ReleaseGroup' }

around create => sub {
    my ($orig, $self, $edit, $editor, $tree) = @_;

    $tree->annotation('') unless $tree->annotation_set;
    $tree->relationships([]) unless $tree->relationships_set;

    $self->$orig($edit, $editor, $tree);
};

sub map_core_entity {
    my ($self, $response) = @_;
    my %data = %{ $response->{data} };
    return MusicBrainz::Server::Entity::ReleaseGroup->new(
        name => $data{name},
        comment => $data{comment},
        primary_type_id => $data{'primary-type'},
        artist_credit_id => $data{'artist-credit'},
        secondary_types => [
            map {
                MusicBrainz::Server::Entity::ReleaseGroupSecondaryType->new(
                    id => $_
                )
            } @{ $data{'secondary-types'} }
        ],

        gid => $response->{mbid},
        revision_id => $response->{revision}
    );
}

sub tree_to_json {
    my ($self, $tree) = @_;

    return (
        'release-group' => do {
            my $release_group = $tree->release_group;
            {
                name => $release_group->name,
                comment => $release_group->comment,
                'primary-type' => $release_group->primary_type_id,
                'artist-credits' => [
                    map +{
                        name => $_->name,
                        artist => $_->artist->gid,
                        'join-phrase' => $_->join_phrase
                    }, $release_group->artist_credit->all_names
                ]
            }
        },
        annotation_to_json($tree),
        relationships_to_json($tree)
    );
}

sub view_tree {
    my ($self, $revision) = @_;

    return $self->tree_class->new(
        release_group => $revision,
        annotation => $self->get_annotation($revision),
        relationships => $self->get_relationships($revision)
    );
}

sub find_by_artist {
    my ($self, $artist) = @_;

    return [
        map { $self->map_core_entity($_) }
            @{ $self->scoped_request('/find-by-artist',
                                     { artist => $artist->gid }) }
    ];
}

__PACKAGE__->meta->make_immutable;
1;
