package MT::Plugins::OMV::Demoize;

use vars qw( $MYNAME $VERSION );
$MYNAME = 'Demoize';
$VERSION = '0.01';

use base qw( MT::Plugin );
my $plugin = __PACKAGE__->new ({
    name => $MYNAME,
    version => $VERSION,
    author_name => 'Open MagicVox.net',
    author_link => 'http://www.magicvox.net/',
    doc_link => 'http://www.magicvox.net/archive/2010/10311453/',
    description => <<HTMLHEREDOC,
<__trans phrase="Allow only the specified commands in administration screen for each users.">
HTMLHEREDOC
    system_config_template => 'tmpl/config.tmpl',
    settings => new MT::PluginSettings ([
        ['allow', { Default => 'username,*,*' }],
    ]),
    registry => {
        callbacks => {
            'MT::App::CMS::pre_run' => \&post_init,
        },
    },
});
MT->add_plugin ($plugin);

sub instance { $plugin }

### Callbacks - MT::App::CMS::pre_run
sub post_init {
    my ($cb, $app) = @_;

    # Avoid redirect loop
    return if $app->param('__mode') eq 'dashboard' && !defined $app->param('blog_id');

    my $user = $app->user
        or return; # do nothing
    # Superuser can do anything
    return if $user->is_superuser;

    my $__mode = $app->param('__mode') || '';
    my $__blog_id = $app->param('blog_id') || '';
    my $config = &instance->get_config_value ('allow') || '';
    for (split /[\r\n]/, $config) {
        my ($username, $mode, $blog_id) = /^\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*/;
        return # Allow
            if ($username eq '*' || $username eq $user->name)
            && ($mode eq '*' || $mode eq $__mode)
            && ($blog_id eq '*' || $blog_id eq $__blog_id);
    }

    # Deny
    $app->redirect ($app->uri ( mode => 'dashboard' ));
}

1;