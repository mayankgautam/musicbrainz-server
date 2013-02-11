package MusicBrainz::Server::Entity::Tree::Recording;
use Moose;

has recording => (
    is => 'rw',
    predicate => 'recording_set',
);

has relationships => (
    is => 'rw',
    predicate => 'relationships_set'
);

sub merge {
    my ($self, $tree) = @_;

    $self->recording($tree->recording)
        if ($tree->recording_set);

    $self->relationships($tree->relationships)
        if ($tree->relationships_set);

    return $self;
}

sub complete {
    my $tree = shift;
    return $tree->recording_set && $tree->relationships_set;
}

1;
