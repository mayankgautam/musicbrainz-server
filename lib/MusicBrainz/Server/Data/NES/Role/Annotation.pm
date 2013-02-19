package MusicBrainz::Server::Data::NES::Role::Annotation;
use Moose::Role;

requires 'scoped_request';

sub get_annotation {
    my ($self, $revision) = @_;
    return $self->scoped_request(
        '/view-annotation',
        { revision => $revision->revision_id }
    )->{annotation};
}

sub load_annotation {
    my ($self, $e) = @_;
    $e->latest_annotation(
        MusicBrainz::Server::Entity::Annotation->new(
            text => $self->get_annotation($e)));
}

1;
