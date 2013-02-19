package MusicBrainz::Server::Data::NES::Role::Relationship;
use feature 'switch';
use Moose::Role;

requires 'scoped_request';

my %rel_type_to_model = (
    work => 'NES::Work'
);

sub get_relationships {
    my ($self, $revision) = @_;
    my @rels =
        map {
            my $rel = $_;
            my $target;
            given ($rel->{'target-type'}) {
                when (/url/) {
                    $target = $self->c->model('NES::URL')->get_by_gid($rel->{target});
                }

                default {
                    $target = $self->c->model(
                        $rel_type_to_model{$_} // die 'Unknown relationship type'
                    )->get_by_gid($rel->{target});
                }
            }

            MusicBrainz::Server::Entity::NES::Relationship->new(
                target => $target,
                target_gid => $rel->{target},
                link => MusicBrainz::Server::Entity::Link->new(
                    type_id => $rel->{type},
                    direction => $MusicBrainz::Server::Entity::NES::Relationship::DIRECTION_BACKWARD,
                    attributes => [
                        values %{ $self->c->model('LinkAttributeType')->get_by_ids(@{ $rel->{attributes} }) }
                    ]
                ),
                target_type => $rel->{'target-type'},
            );
        } @{
            $self->scoped_request(
                '/view-relationships',
                { revision => $revision->revision_id }
            )
        };

    for my $attribute (map { $_->link->all_attributes } @rels) {
        $attribute->root($self->c->model('LinkAttributeType')->get_by_id($attribute->root_id));
    }

    $self->c->model('LinkType')->load(map { $_->link } @rels);

    return \@rels;
}

sub load_relationships {
    my ($self, @works) = @_;
    for my $work (@works) {
        $work->relationships($self->get_relationships($work));
    }
}

1;
