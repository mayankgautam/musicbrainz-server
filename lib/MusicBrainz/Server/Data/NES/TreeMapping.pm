package MusicBrainz::Server::Data::NES::TreeMapping;
use strict;
use warnings;

use List::UtilsBy qw( partition_by );
use MusicBrainz::Server::Data::Utils qw( partial_date_to_hash );
use MusicBrainz::Server::WebService::Serializer::JSON::2::Utils qw( boolean );
use Sub::Exporter -setup => {
    exports => [qw(
        aliases_to_json
        annotation_to_json
        artist_credit_to_json
        relationships_to_json
        track_from_json
    )]
};

sub annotation_to_json {
    my $tree = shift;
    return (
        annotation => $tree->annotation
    );
}

sub aliases_to_json {
    my $tree = shift;
    return (
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

sub relationships_to_json {
    my $tree = shift;
    return (
        relationships => {
            partition_by { $_->{target_type} }
                map +{
                    target => $_->target->gid,
                    type => $_->link->type_id,
                    target_type => $_->target_type,
                    attributes => [ map { $_->id } $_->link->all_attributes ]
                }, @{ $tree->relationships }
        }
    );
}

sub artist_credit_to_json {
    my $artist_credit = shift;
    return (
        'artist-credits' => [
            map +{
                name => $_->name,
                artist => $_->artist->gid,
                'join-phrase' => $_->join_phrase
            }, $artist_credit->all_names
        ]
    );
}

sub track_from_json {
    my ($json) = @_;
    return MusicBrainz::Server::Entity::Track->new(
        name => $json->{name},
        number => $json->{number},
        length => $json->{length},
        artist_credit_id => $json->{'artist-credit'},
        recording_gid => $json->{recording}
    )
}

1;
