package MusicBrainz::Server::Form::Label::Edit;
use HTML::FormHandler::Moose;

extends 'MusicBrainz::Server::Form::Label';

has_field 'revision_id' => (
    type => 'Integer',
    required => 1
);

__PACKAGE__->meta->make_immutable;
1;
