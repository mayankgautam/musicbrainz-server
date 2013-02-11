package MusicBrainz::Server::Entity::Tree::ReleaseGroup;
use Moose;

has release_group => (
    is => 'rw',
    predicate => 'release_group_set',
);

has annotation => (
    is => 'rw',
    predicate => 'annotation_set'
);

has relationships => (
    is => 'rw',
    predicate => 'relationships_set'
);

sub merge {
    my ($self, $tree) = @_;

    $self->release_group($tree->release_group)
        if ($tree->release_group_set);

    $self->annotation($tree->annotation)
        if ($tree->annotation_set);

    $self->relationships($tree->relationships)
        if ($tree->relationships_set);

    return $self;
}

sub complete {
    my $tree = shift;
    return $tree->release_group_set && $tree->annotation_set && $tree->relationships_set;
}

1;
