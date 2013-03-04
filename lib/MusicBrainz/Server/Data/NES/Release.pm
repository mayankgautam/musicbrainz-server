package MusicBrainz::Server::Data::NES::Release;
use feature 'switch';
use Moose;

use MusicBrainz::Server::Data::NES::TreeMapping ':all';
use MusicBrainz::Server::Data::Utils qw( partial_date_to_hash );
use MusicBrainz::Server::Entity::Barcode;
use MusicBrainz::Server::Entity::Release;
use MusicBrainz::Server::Entity::Tree::Release;

with 'MusicBrainz::Server::Data::Role::NES' => {
    root => '/release'
};
with 'MusicBrainz::Server::Data::NES::Role::Annotation';
with 'MusicBrainz::Server::Data::NES::CoreEntity';
with 'MusicBrainz::Server::Data::NES::Role::Relationship';
with 'MusicBrainz::Server::Data::NES::Role::Tags' => {
    model => 'Release'
};

with 'MusicBrainz::Server::Data::NES::Role::FindByArtist';

sub tree_class { 'MusicBrainz::Server::Entity::Tree::Release' }

around create => sub {
    my ($orig, $self, $edit, $editor, $tree) = @_;

    $tree->annotation('') unless $tree->annotation_set;
    $tree->relationships([]) unless $tree->relationships_set;

    $self->$orig($edit, $editor, $tree);
};

sub map_core_entity {
    my ($self, $response) = @_;
    my %data = %{ $response->{data} };
    return MusicBrainz::Server::Entity::Release->new(
        name => $data{name},
        comment => $data{comment},
        primary_type_id => $data{'primary-type'},
        artist_credit_id => $data{'artist-credit'},
        country_id => $data{country},
        date => MusicBrainz::Server::Entity::PartialDate->new($data{date}),
        barcode => defined $data{barcode}
            ? MusicBrainz::Server::Entity::Barcode->new($data{barcode})
            : undef,
        status_id => $data{status},
        packaging_id => $data{packaging},
        language_id => $data{language},
        script_id => $data{script},
        release_group_gid => $data{'release-group'},

        gid => $response->{mbid},
        revision_id => $response->{revision}
    );
}

sub tree_to_json {
    my ($self, $tree) = @_;
    my $release = $tree->release;
    return (
        'release' => {
            name => $release->name,
            comment => $release->comment,
            'release-group' => $release->release_group->gid,
            artist_credit_to_json($release->artist_credit),
            date => partial_date_to_hash($release->date),
            country => $release->country_id,
            script => $release->script_id,
            language => $release->language_id,
            status => $release->status_id,
            packaging => $release->packaging_id
        },
        mediums => [
            map +{
                name => $_->name,
                format => $_->format_id,
                position => 1,
                tracks => [
                    map +{
                        recording => $_->recording_gid,
                        name => $_->name,
                        artist_credit_to_json($_->artist_credit),
                        number => $_->number,
                        duration => $_->length,
                    }, $_->tracklist->all_tracks
                ]
            }, $release->all_mediums
        ],
        labels => [
            map +{
                label => $_->label_gid,
                'catalog-number' => $_->catalog_number
            }, $release->all_labels
        ],
        annotation_to_json($tree),
        relationships_to_json($tree)
    );
}

sub view_tree {
    my ($self, $revision) = @_;

    return $self->tree_class->new(
        release => $revision,
        annotation => $self->get_annotation($revision),
        relationships => $self->get_relationships($revision)
    );
}

sub find_by_label {
    my ($self, $label, undef, undef) = @_;
    return [
        map { $self->map_core_entity($_) }
            @{ $self->scoped_request('/find-by-label', { label => $label->gid }) }
    ];
}

sub find_by_release_group {
    my ($self, $release_group, undef, undef) = @_;
    return [
        map { $self->map_core_entity($_) }
            @{ $self->scoped_request('/find-by-release-group', { 'release-group' => $release_group->gid }) }
    ];
}

__PACKAGE__->meta->make_immutable;
1;
