package MusicBrainz::Server::Data::NES::Recording;
use feature 'switch';
use Moose;

use MusicBrainz::Server::Data::NES::TreeMapping ':all';
use MusicBrainz::Server::Data::Utils qw( load_subobjects_gid );
use MusicBrainz::Server::Entity::Recording;
use MusicBrainz::Server::Entity::Tree::Recording;

with 'MusicBrainz::Server::Data::Role::NES' => {
    root => '/recording'
};
with 'MusicBrainz::Server::Data::NES::CoreEntity';
with 'MusicBrainz::Server::Data::NES::Role::Annotation';
with 'MusicBrainz::Server::Data::NES::Role::Relationship';
with 'MusicBrainz::Server::Data::NES::Role::Tags' => {
    model => 'Recording'
};

with 'MusicBrainz::Server::Data::NES::Role::FindByArtist';

around create => sub {
    my ($orig, $self, $edit, $editor, $tree) = @_;

    $tree->relationships([]) unless $tree->relationships_set;

    $self->$orig($edit, $editor, $tree);
};

sub tree_class { 'MusicBrainz::Server::Entity::Tree::Recording' }

sub map_core_entity {
    my ($self, $response) = @_;
    my %data = %{ $response->{data} };
    return MusicBrainz::Server::Entity::Recording->new(
        name => $data{name},
        comment => $data{comment},
        artist_credit_id => $data{'artist-credit'},
        length => $data{duration},

        gid => $response->{mbid},
        revision_id => $response->{revision}
    );
}

sub tree_to_json {
    my ($self, $tree) = @_;

    return (
        'recording' => do {
            my $recording = $tree->recording;
            {
                name => $recording->name,
                comment => $recording->comment,
                artist_credit_to_json($recording->artist_credit)
            }
        },
        relationships_to_json($tree)
    );
}

sub view_tree {
    my ($self, $revision) = @_;

    return $self->tree_class->new(
        recording => $revision,
        annotation => $self->get_annotation($revision),
        relationships => $self->get_relationships($revision)
    );
}

sub view_isrcs {
    my ($self, $revision) = @_;

    return [
        map { MusicBrainz::Server::Entity::ISRC->new( isrc => $_ ) }
            @{ $self->scoped_request('/view-isrcs',
                                     { revision => $revision->revision_id })
            }
    ];
}

sub load {
    my $self = shift;
    load_subobjects_gid($self, 'recording', @_);
}

sub find_tracks {
    my ($self, $recording) = @_;
    return [
        map +{
            track => track_from_json($_->{track}),
            release => $self->c->model('NES::Release')->map_core_entity($_->{release}),
            total_tracks => $_->{'total-tracks'}
        },
          @{
            $self->scoped_request('/find-recording-tracks',
                                  { recording => $recording->gid })
          }
    ];
}

sub find_by_isrc {
    my ($self, $isrc, undef, undef) = @_;
    return [
        map { $self->map_core_entity($_) }
            @{ $self->scoped_request('/find-by-isrc', { isrc => $isrc }) }
    ];
}

sub load_isrcs {
    my ($self, @revisions) = @_;

    # NES - Convert from O(n) to O(1) queries
    for my $revision (@revisions) {
        $revision->isrcs($self->view_isrcs($revision));
    }
}

__PACKAGE__->meta->make_immutable;
1;
