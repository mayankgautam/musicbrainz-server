package MusicBrainz::Server::Data::NES::Role::IPI;
use MooseX::Role::Parameterized;

use MusicBrainz::Server::Data::Utils qw( object_to_revision_ids );

parameter entity_class => (
    isa => 'Str',
    required => 1
);

role {
    my $params = shift;

    requires 'request';

    method get_ipi_codes => sub {
        my ($self, $revision) = @_;
        warn "Unimplemented";
        return [];
    };

    method load_ipis => sub {
        my ($self, @entities) = @_;
        my %entities_by_revision_id = object_to_revision_ids(@entities);
        my %ipi_map = %{
            $self->scoped_request('/view-ipi-codes', {
                revisions => [
                    map +{ revision => $_->revision_id }, @entities
                ]
            })
        };

        for my $key (keys %ipi_map) {
            for my $entity (@{ $entities_by_revision_id{$key} }) {
                $entity->ipi_codes([
                    map {
                        $params->entity_class->new( ipi => $_ )
                    } @{ $ipi_map{$key} }
                ]);
            }
        }

        return;
    };
};

1;
