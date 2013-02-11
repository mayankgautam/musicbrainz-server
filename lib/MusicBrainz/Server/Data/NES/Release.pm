package MusicBrainz::Server::Data::NES::Release;
use feature 'switch';
use Moose;

use MusicBrainz::Server::Data::NES::TreeMapping ':all';
use MusicBrainz::Server::Data::Utils qw( partial_date_to_hash );
use MusicBrainz::Server::Entity::Artist;
use MusicBrainz::Server::Entity::PartialDate;

with 'MusicBrainz::Server::Data::Role::NES';
with 'MusicBrainz::Server::Data::NES::CoreEntity' => {
    root => '/release'
};

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
        annotation_to_json($tree),
        relationships_to_json($tree)
    );
}

__PACKAGE__->meta->make_immutable;
1;
