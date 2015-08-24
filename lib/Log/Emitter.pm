package Log::Emitter;

use Carp 'croak';
use Fcntl ':flock';
use Encode 'encode';
use IO::Handle ();

use Moo;
use namespace::clean;

with 'Role::EventEmitter';

our $VERSION = '0.001';

has format => (is => 'rw', lazy => 1, default => sub { \&_format });
has handle => (is => 'rw', lazy => 1, clearer => 1, default => sub {

  # STDERR
  return \*STDERR unless my $path = shift->path;

  # File
  croak qq{Can't open log file "$path": $!} unless open my $file, '>>', $path;
  return $file;
});
has history => (is => 'rw', lazy => 1, default => sub { [] });
has level => (is => 'rw', lazy => 1, default => 'debug');
has max_history_size => (is => 'rw', lazy => 1, default => 10);
has path => (is => 'rw', trigger => sub { shift->clear_handle });

# Supported log levels
my $LEVEL = {debug => 1, info => 2, warn => 3, error => 4, fatal => 5};

sub BUILD { shift->on(message => \&_message) }

sub append {
  my ($self, $msg) = @_;

  return unless my $handle = $self->handle;
  flock $handle, LOCK_EX;
  $handle->print(encode('UTF-8', $msg)) or croak "Can't write to log: $!";
  flock $handle, LOCK_UN;
}

sub debug { shift->_log(debug => @_) }
sub error { shift->_log(error => @_) }
sub fatal { shift->_log(fatal => @_) }
sub info  { shift->_log(info  => @_) }

sub is_debug { shift->_now('debug') }
sub is_error { shift->_now('error') }
# For Log::Contextual compatiblity
sub is_fatal { shift->_now('fatal') }
sub is_info  { shift->_now('info') }
sub is_warn  { shift->_now('warn') }

sub warn { shift->_log(warn => @_) }

sub _format {
  '[' . localtime(shift) . '] [' . shift() . '] ' . join "\n", @_, '';
}

sub _log { shift->emit('message', shift, @_) }

sub _message {
  my ($self, $level) = (shift, shift);

  return unless $self->_now($level);

  my $max     = $self->max_history_size;
  my $history = $self->history;
  push @$history, my $msg = [time, $level, @_];
  shift @$history while @$history > $max;

  $self->append($self->format->(@$msg));
}

sub _now { $LEVEL->{pop()} >= $LEVEL->{$ENV{LOG_EMITTER_LEVEL} || shift->level} }

1;

=encoding utf8

=head1 NAME

Log::Emitter - Simple logger

=head1 SYNOPSIS

  use Log::Emitter;

  # Log to STDERR
  my $log = Log::Emitter->new;

  # Customize log file location and minimum log level
  my $log = Log::Emitter->new(path => '/var/log/emitter.log', level => 'warn');

  # Log messages
  $log->debug('Not sure what is happening here');
  $log->info('FYI: it happened again');
  $log->warn('This might be a problem');
  $log->error('Garden variety error');
  $log->fatal('Boom');

=head1 DESCRIPTION

L<Log::Emitter> is a simple logger based on L<Mojo::Log>.

L<Log::Emitter> is compatible with L<Log::Contextual> for global logging.

  use Log::Emitter;
  use Log::Contextual ':log', 'set_logger', -levels => [qw(debug info warn error fatal)];
  set_logger(Log::Emitter->new);
  
  log_info { "Here's some info" };
  log_error { "Uh-oh, error occured" };

=head1 EVENTS

L<Log::Emitter> composes all events from L<Role::EventEmitter> in addition to
emitting the following.

=head2 message

  $log->on(message => sub {
    my ($log, $level, @lines) = @_;
    ...
  });

Emitted when a new message gets logged.

  $log->unsubscribe('message');
  $log->on(message => sub {
    my ($log, $level, @lines) = @_;
    say "$level: ", @lines;
  });

=head1 ATTRIBUTES

L<Log::Emitter> implements the following attributes.

=head2 format

  my $cb = $log->format;
  $log   = $log->format(sub {...});

A callback for formatting log messages.

  $log->format(sub {
    my ($time, $level, @lines) = @_;
    return "[Thu May 15 17:47:04 2014] [info] I ♥ Logging\n";
  });

=head2 handle

  my $handle = $log->handle;
  $log       = $log->handle(IO::Handle->new);

Log filehandle used by default L</"message"> event, defaults to opening
L</"path"> or C<STDERR>. Reset when L</"path"> is set.

=head2 history

  my $history = $log->history;
  $log        = $log->history([[time, 'debug', 'That went wrong']]);

The last few logged messages.

=head2 level

  my $level = $log->level;
  $log      = $log->level('debug');

Active log level, defaults to C<debug>. Available log levels are C<debug>,
C<info>, C<warn>, C<error> and C<fatal>, in that order. Note that the
C<LOG_EMITTER_LEVEL> environment variable can override this value.

=head2 max_history_size

  my $size = $log->max_history_size;
  $log     = $log->max_history_size(5);

Maximum number of logged messages to store in L</"history">, defaults to C<10>.

=head2 path

  my $path = $log->path
  $log     = $log->path('/var/log/emitter.log');

Log file path used by L</"handle">. Setting this attribute will reset
L</"handle">.

=head1 METHODS

L<Log::Emitter> composes all methods from L<Role::EventEmitter> in addition to
the following.

=head2 new

  my $log = Log::Emitter->new;

Construct a new L<Log::Emitter> object and subscribe to L</"message"> event
with default logger.

=head2 append

  $log->append("[Thu May 15 17:47:04 2014] [info] I ♥ Logging\n");

Append message to L</"handle">.

=head2 debug

  $log = $log->debug('You screwed up, but that is ok');
  $log = $log->debug('All', 'cool');

Emit L</"message"> event and log debug message.

=head2 error

  $log = $log->error('You really screwed up this time');
  $log = $log->error('Wow', 'seriously');

Emit L</"message"> event and log error message.

=head2 fatal

  $log = $log->fatal('Its over...');
  $log = $log->fatal('Bye', 'bye');

Emit L</"message"> event and log fatal message.

=head2 info

  $log = $log->info('You are bad, but you prolly know already');
  $log = $log->info('Ok', 'then');

Emit L</"message"> event and log info message.

=head2 is_debug

  my $bool = $log->is_debug;

Check for debug log level.

=head2 is_error

  my $bool = $log->is_error;

Check for error log level.

=head2 is_fatal

  my $bool = $log->is_fatal;

Check for fatal log level.

=head2 is_info

  my $bool = $log->is_info;

Check for info log level.

=head2 is_warn

  my $bool = $log->is_warn;

Check for warn log level.

=head2 warn

  $log = $log->warn('Dont do that Dave...');
  $log = $log->warn('No', 'really');

Emit L</"message"> event and log warn message.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::Log>, L<Log::Contextual>

=for Pod::Coverage BUILD
